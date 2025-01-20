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

    .PARAMETER SourceFileList
    List of files to synchronize. If this is used, then SourceFolderPath is ignored
    This is useful when you want to synchronize specific files only

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

    .PARAMETER SkipRemoval
    Skip removal of files/folders from SharePoint Online. Default $false

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
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'SourceFolder')]
    param (
        [Parameter(Mandatory)][string] $SiteURL,
        [Parameter(Mandatory, ParameterSetName = 'SourceFolder')][string] $SourceFolderPath,
        [Parameter(Mandatory, ParameterSetName = 'SourceFileList')][Array] $SourceFileList,
        [Parameter(Mandatory)][string] $TargetLibraryName,
        [string] $LogPath,
        [int] $LogMaximum,
        [switch] $LogShowTime,
        [string] $LogTimeFormat,
        [string] $Include,
        [string[]] $ExcludeFromRemoval,
        [switch] $SkipRemoval
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

    $TargetFolder = $null
    if ($TargetLibraryName -like "*/*") {
        $Path = $TargetLibraryName -split "/"
        $TargetLibraryPath = $Path[0]
        $ListOfSharePointFolders = Get-PnPFolderItem -ItemType Folder -Recursive -FolderSiteRelativeUrl $TargetLibraryPath #| Select-Object Name, ServerRelativeUrl, ItemCount
        foreach ($Folder in $ListOfSharePointFolders) {
            $FolderFound = $Folder.ServerRelativeUrl.Replace($Web.ServerRelativeURL, [string]::Empty)
            if ($FolderFound.TrimStart("/") -eq $TargetLibraryName.TrimStart("/")) {
                $TargetFolder = $Folder
                break
            }
        }
    } else {
        $TargetFolder = $Library.RootFolder
    }

    if (-not $TargetFolder) {
        Write-Color -Text "[e] ", "Unable to find folder ", $TargetLibraryName, " in the library. Please make sure the folder exists." -Color Yellow, Red
        return
    }

    # Get the site relative path of the target folder
    If ($web.ServerRelativeURL -eq "/") {
        $TargetFolderSiteRelativeURL = $TargetFolder.ServerRelativeUrl
    } Else {
        $TargetFolderSiteRelativeURL = $TargetFolder.ServerRelativeURL.Replace($Web.ServerRelativeUrl, [string]::Empty)
    }

    $FilesLocalOutput = Get-FilesLocal -SourceFileList $SourceFileList -SourceFolderPath $SourceFolderPath -Include $Include -TargetFolderSiteRelativeURL $TargetFolderSiteRelativeURL
    [Array] $Source = $FilesLocalOutput.Source
    [string] $SourceDirectoryPath = $FilesLocalOutput.SourceDirectoryPath

    Write-Color -Text "[i] ", "Total items in source: ", "$($Source.Count)" -Color Yellow, White, Green
    Write-Color -Text "[i] ", "Total items in target: ", "$($TargetFolder.Itemcount)" -Color Yellow, White, Green

    Write-Color -Text "[i] ", "Starting processing files/folders to SharePoint ", $SiteUrl -Color Yellow, White, Green

    # Upload files to SharePoint
    $exportFilesToSharePointSplat = @{
        Source            = $Source
        SourceFolderPath  = $SourceDirectoryPath
        TargetLibraryName = $TargetLibraryName
        TargetFolder      = $TargetFolder
        WhatIf            = $WhatIfPreference
    }
    Export-FilesToSharePoint @exportFilesToSharePointSplat

    if (-not $SkipRemoval) {
        Write-Color -Text "[i] ", "Starting removal of files/folders from SharePoint ", $SiteUrl -Color Yellow, White, Green

        # Remove files from SharePoint that are no longer in the source folder
        $removeFileShareDeltaInSPOSplat = @{
            Source             = $Source
            SiteURL            = $SiteURL
            SourceFolderPath   = $SourceDirectoryPath
            TargetLibraryName  = $TargetLibraryName
            TargetFolder       = $TargetFolder
            WhatIf             = $WhatIfPreference
            ExcludeFromRemoval = $ExcludeFromRemoval
        }

        Remove-FilesFromSharePoint @removeFileShareDeltaInSPOSplat
    } else {
        Write-Color -Text "[i] ", "Skipping removal of files/folders from SharePoint as requested", $SiteUrl -Color Yellow, White, Green
    }
    Write-Color -Text "[i] ", "Finished synchronization of files from ", $SourceFolderPath, " to ", $SiteUrl -Color Yellow, White, Yellow, White, Green
}