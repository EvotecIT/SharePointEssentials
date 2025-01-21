function Sync-FilesFromSharePoint {
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
}