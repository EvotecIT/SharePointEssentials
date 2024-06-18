Function Sync-FilesToSharePoint {
    <#
    .SYNOPSIS
    Synchronizes files from local folder to SharePoint Online library

    .DESCRIPTION
    Synchronizes files from local folder to SharePoint Online library
    Provides an easy way to keep local folder in sync with SharePoint Online library
    - Deleting content on local folder will delete it on SharePoint Online
    - Adding content to local folder will add it to SharePoint Online
    - Updating content on local folder will update it on SharePoint Online
    - Deleting content on SharePoint Online will trigger reupload from local folder

    .PARAMETER SiteURL
    Site URL where the library is located

    .PARAMETER SourceFolderPath
    Local folder path to synchronize

    .PARAMETER TargetLibraryName
    Name of the library to synchronize to without site url

    .PARAMETER LogPath
    Path to log file where all actions will be logged

    .PARAMETER LogMaximum
    Maximum number of log files to keep. If 0 then unlimited. Default unlimited.
    Please keep in mind that this will only work if the logs are in the dedicated folder.
    If you use the same folder as the script, then logging deletion will be disabled.

    .PARAMETER LogShowTime
    Show time in console output. Default $false. Logs will always have time.

    .PARAMETER LogTimeFormat
    Time format to use in log file. Default "yyyy-MM-dd HH:mm:ss"

    .PARAMETER Include
    Include filter for files. Default "*.*"

    .PARAMETER ExcludeFromRemoval
    List of files/folders to exclude from removal. Default $null

    .EXAMPLE
    $Url = 'https://yoursharepoint.sharepoint.com/sites/TheDashboard'
    $ClientID = '438511c4' # Temp SharePoint App
    $TenantID = 'ceb371f6'

    Connect-PnPOnline -Url $Url -ClientId $ClientID -Thumbprint '2EC7C86E1AF0E434E93DE3EAC' -Tenant $TenantID

    $syncFiles = @{
        SiteURL           = 'https://yoursharepoint.sharepoint.com/sites/TheDashboard'
        SourceFolderPath  = "C:\Support\GitHub\TheDashboard\Examples\Reports"
        TargetLibraryName = "Shared Documents"
        LogPath           = "$PSScriptRoot\Logs\Sync-FilesToSharePoint-$($(Get-Date).ToString('yyyy-MM-dd_HH_mm_ss')).log"
        LogMaximum        = 5
        Include           = "*.aspx"
    }

    Sync-FilesToSharePoint @syncFiles -WhatIf

    .NOTES
    General notes
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)][string] $SiteURL,
        [Parameter(Mandatory)][string] $SourceFolderPath,
        [Parameter(Mandatory)][string] $TargetLibraryName,
        [string] $LogPath,
        [int] $LogMaximum,
        [switch] $LogShowTime,
        [string] $LogTimeFormat,
        [string] $Include,
        [string[]] $ExcludeFromRemoval
    )

    Set-LoggingCapabilities -LogPath $LogPath -LogMaximum $LogMaximum -ShowTime:$LogShowTime -TimeFormat $LogTimeFormat -ScriptPath $MyInvocation.ScriptName

    Write-Color -Text "[i] ", "Starting synchronization of files from ", $SourceFolderPath, " to ", $SiteUrl -Color Yellow, White, Yellow, White, Green
    Write-Color -Text "[i] ", "Target library: ", $TargetLibraryName -Color Yellow, White, Green

    # Connect to SharePoint Online
    try {
        $Web = Get-PnPWeb -ErrorAction Stop
    } catch {
        Write-Color -Text "[e] ", "Unable to connect to SharePoint Online. Please make sure you are connected to the Internet and that you have permissions to the site." -Color Yellow, Red
        Write-Color -Text "[e] ", "Error: ", $_.Exception.Message -Color Yellow, Red
        return
    }
    try {
        $Library = Get-PnPList -Identity $TargetLibraryName -Includes RootFolder -ErrorAction Stop
    } catch {
        Write-Color -Text "[e] ", "Unable to get list of libraries on SharePoint Online. Make sure that you have permissions to the site." -Color Yellow, Red
        Write-Color -Text "[e] ", "Error: ", $_.Exception.Message -Color Yellow, Red
        return
    }
    $TargetFolder = $Library.RootFolder

    # Get the site relative path of the target folder
    If ($web.ServerRelativeURL -eq "/") {
        $TargetFolderSiteRelativeURL = $TargetFolder.ServerRelativeUrl
    } Else {
        $TargetFolderSiteRelativeURL = $TargetFolder.ServerRelativeURL.Replace($Web.ServerRelativeUrl, [string]::Empty)
    }

    # Lets get all files from the source folder
    $getChildItemSplat = @{
        Path    = $SourceFolderPath
        Recurse = $true

    }
    if ($Include) {
        $getChildItemSplat["Include"] = $Include
    }
    try {
        $SourceItems = @(
            Get-ChildItem -Directory -Path $SourceFolderPath -Recurse -ErrorAction Stop
            Get-ChildItem @getChildItemSplat -ErrorAction Stop
        )
    } catch {
        Write-Color -Text "[e] ", "Unable to get files from the source folder. Make sure the path is correct and you have permissions to access it." -Color Yellow, Red
        Write-Color -Text "[e] ", "Error: ", $_.Exception.Message -Color Yellow, Red
        return
    }
    [Array] $Source = foreach ($File in $SourceItems | Sort-Object -Unique -Property FullName) {
        # Dates are not the same as in SharePoint, so we need to convert them to UTC
        # And make sure we don't add miliseconds, as it will cause issues with comparisonS
        $Date = $File.LastWriteTimeUtc
        [PSCustomObject] @{
            FullName      = $File.FullName
            PSIsContainer = $File.PSIsContainer
            TargetItemURL = $File.FullName.Replace($SourceFolderPath, $TargetFolderSiteRelativeURL).Replace("\", "/")
            LastUpdated   = [datetime]::new($Date.Year, $Date.Month, $Date.Day, $Date.Hour, $Date.Minute, $Date.Second)
        }
    }

    Write-Color -Text "[i] ", "Total items in source: ", "$($Source.Count)" -Color Yellow, White, Green
    Write-Color -Text "[i] ", "Total items in target: ", "$($Library.Itemcount)" -Color Yellow, White, Green

    Write-Color -Text "[i] ", "Starting processing files/folders to SharePoint ", $SiteUrl -Color Yellow, White, Green

    # Upload files to SharePoint
    $exportFilesToSharePointSplat = @{
        Source            = $Source
        SourceFolderPath  = $SourceFolderPath
        TargetLibraryName = $TargetLibraryName
        TargetFolder      = $TargetFolder
        WhatIf            = $WhatIfPreference
    }
    Export-FilesToSharePoint @exportFilesToSharePointSplat

    Write-Color -Text "[i] ", "Starting removal of files/folders from SharePoint ", $SiteUrl -Color Yellow, White, Green

    # Remove files from SharePoint that are no longer in the source folder
    $removeFileShareDeltaInSPOSplat = @{
        Source             = $Source
        SiteURL            = $SiteURL
        SourceFolderPath   = $SourceFolderPath
        TargetLibraryName  = $TargetLibraryName
        TargetFolder       = $TargetFolder
        WhatIf             = $WhatIfPreference
        ExcludeFromRemoval = $ExcludeFromRemoval
    }

    Remove-FilesFromSharePoint @removeFileShareDeltaInSPOSplat

    Write-Color -Text "[i] ", "Finished synchronization of files from ", $SourceFolderPath, " to ", $SiteUrl -Color Yellow, White, Yellow, White, Green
}