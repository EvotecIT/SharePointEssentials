Function Sync-FilesFromSharePoint {
    <#
    .SYNOPSIS
    Synchronizes files from SharePoint Online library to local folder

    .DESCRIPTION
    Synchronizes files from SharePoint Online library to local folder.
    Provides an easy way to keep local folder in sync with SharePoint Online library
    - Deleting content on SharePoint Online will delete it locally
    - Adding content to SharePoint Online will add it locally
    - Updating content on SharePoint Online will update it locally

    .PARAMETER SiteURL
    Site URL where the library is located

    .PARAMETER TargetFolderPath
    Local folder path to synchronize to

    .PARAMETER SourceLibraryName
    Name of the library on SharePoint Online to synchronize from

    .PARAMETER LogPath
    Path to log file where all actions will be logged

    .PARAMETER LogMaximum
    Maximum number of log files to keep

    .PARAMETER LogShowTime
    Show time in console output. Default $false. Logs will always have time

    .PARAMETER LogTimeFormat
    Time format to use in log file. Default "yyyy-MM-dd HH:mm:ss"

    .PARAMETER Include
    Include filter for files. Default "*.*"

    .PARAMETER ExcludeFromRemoval
    List of files/folders to exclude from removal. Default $null

    .PARAMETER SkipRemoval
    Skip removal of files/folders from local folder. Default $false
    
    .EXAMPLE
    $Url = 'https://yoursharepoint.sharepoint.com/sites/TheDashboard'
    $ClientID = '438511c4' # Temp SharePoint App
    $TenantID = 'ceb371f6'

    Connect-PnPOnline -Url $Url -ClientId $ClientID -Thumbprint '2EC7C86E1AF0E434E93DE3EAC' -Tenant $TenantID

    $syncFiles = @{
        SiteURL          = 'https://yoursharepoint.sharepoint.com/sites/TheDashboard'
        TargetFolderPath = "C:\\Support\\GitHub\\TheDashboard\\Examples\\Reports"
        SourceLibraryName = "Shared Documents"
        LogPath          = "$PSScriptRoot\\Logs\\Sync-FilesFromSharePoint-$($(Get-Date).ToString('yyyy-MM-dd_HH_mm_ss')).log"
        LogMaximum       = 5
        Include          = "*.aspx"
    }

    Sync-FilesFromSharePoint @syncFiles -WhatIf

    .NOTES
    General notes
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $SiteURL,
        [Parameter(Mandatory)][string] $TargetFolderPath,
        [Parameter(Mandatory)][string] $SourceLibraryName,
        [string] $LogPath,
        [int] $LogMaximum,
        [switch] $LogShowTime,
        [string] $LogTimeFormat,
        [string] $Include,
        [string[]] $ExcludeFromRemoval,
        [switch] $SkipRemoval
    )

    Set-LoggingCapabilities -LogPath $LogPath -LogMaximum $LogMaximum -ShowTime:$LogShowTime -TimeFormat $LogTimeFormat -ScriptPath $MyInvocation.ScriptName

    Write-Color -Text "[i] ", "Starting synchronization of files from ", $SiteURL, " to ", $TargetFolderPath -Color Yellow, White, Yellow, White, Green
    Write-Color -Text "[i] ", "Source library: ", $SourceLibraryName -Color Yellow, White, Green

    if (-not (Test-Path -Path $TargetFolderPath)) {
        New-Item -ItemType Directory -Path $TargetFolderPath -Force | Out-Null
    }

    # Connect to SharePoint Online
    try {
        $Web = Get-PnPWeb -ErrorAction Stop
    } catch {
        Write-Color -Text "[e] ", "Unable to connect to SharePoint Online. Please make sure you are connected to the Internet and that you have permissions to the site." -Color Yellow, Red
        Write-Color -Text "[e] ", "Error: ", $_.Exception.Message -Color Yellow, Red
        return
    }
    try {
        $Library = Get-PnPList -Identity $SourceLibraryName -Includes RootFolder -ErrorAction Stop
    } catch {
        Write-Color -Text "[e] ", "Unable to get list of libraries on SharePoint Online. Make sure that you have permissions to the site." -Color Yellow, Red
        Write-Color -Text "[e] ", "Error: ", $_.Exception.Message -Color Yellow, Red
        return
    }

    $TargetFolder = Find-TargetFolder -TargetLibraryName $SourceLibraryName -Library $Library -Web $Web
    if (-not $TargetFolder) {
        return
    }

    if ($web.ServerRelativeURL -eq "/") {
        $TargetFolderSiteRelativeURL = $TargetFolder.ServerRelativeUrl
    } else {
        $TargetFolderSiteRelativeURL = $TargetFolder.ServerRelativeURL.Replace($Web.ServerRelativeUrl, [string]::Empty)
    }

    # Get files from SharePoint Online
    $TargetFilesCount = 0
    $TargetDirectoryCount = 0
    $TargetFiles = Get-PnPListItem -List $SourceLibraryName -PageSize 2000
    [Array] $Source = foreach ($File in $TargetFiles) {
        $Date = $File.FieldValues.Modified.ToUniversalTime()
        if ($File.FieldValues.FileRef -like "$($TargetFolder.ServerRelativeUrl)/*") {
            [PSCustomObject]@{
                FullName      = $File.FieldValues.FileRef.Replace($TargetFolder.ServerRelativeURL, $TargetFolderPath).Replace("/", "\\")
                PSIsContainer = $File.FileSystemObjectType -eq "Folder"
                TargetItemURL = $File.FieldValues.FileRef.Replace($Web.ServerRelativeUrl, [string]::Empty)
                LastUpdated   = [datetime]::new($Date.Year, $Date.Month, $Date.Day, $Date.Hour, $Date.Minute, $Date.Second)
            }
            if (-not $File.FileSystemObjectType -eq "Folder") {
                $TargetFilesCount++
            } else {
                $TargetDirectoryCount++
            }
        }
    }
    Write-Color -Text "[i] ", "Total items (files) in source: ", "$TargetFilesCount" -Color Yellow, White, Green
    Write-Color -Text "[i] ", "Total items (folders) in source: ", "$TargetDirectoryCount" -Color Yellow, White, Green

    $FilesLocalOutput = Get-FilesLocal -SourceFolderPath $TargetFolderPath -Include $Include -TargetFolderSiteRelativeURL $TargetFolderSiteRelativeURL
    [Array] $Target = $FilesLocalOutput.Source

    Write-Color -Text "[i] ", "Total items (files) in target: ", "$($FilesLocalOutput.SourceFilesCount)" -Color Yellow, White, Green
    Write-Color -Text "[i] ", "Total items (folders) in target: ", "$($FilesLocalOutput.SourceDirectoryCount)" -Color Yellow, White, Green

    Write-Color -Text "[i] ", "Starting processing files/folders from SharePoint ", $SiteUrl -Color Yellow, White, Green

    $exportFilesFromSharePointSplat = @{
        Source           = $Source
        Target           = $Target
        TargetFolderPath = $TargetFolderPath
        WhatIf           = $WhatIfPreference
    }
    Export-FilesFromSharePoint @exportFilesFromSharePointSplat

    if (-not $SkipRemoval) {
        Write-Color -Text "[i] ", "Starting removal of files/folders from local path ", $TargetFolderPath -Color Yellow, White, Green
        $removeFilesFromLocalSplat = @{
            Source             = $Source
            Target             = $Target
            WhatIf             = $WhatIfPreference
            ExcludeFromRemoval = $ExcludeFromRemoval
        }
        Remove-FilesFromLocal @removeFilesFromLocalSplat
    } else {
        Write-Color -Text "[i] ", "Skipping removal of files/folders from local path as requested", $TargetFolderPath -Color Yellow, White, Green
    }
    Write-Color -Text "[i] ", "Finished synchronization of files from ", $SiteURL, " to ", $TargetFolderPath -Color Yellow, White, Yellow, White, Green
}

