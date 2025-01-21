function Find-TargetFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $TargetLibraryName,
        [Microsoft.SharePoint.Client.List] $Library,
        [Microsoft.SharePoint.Client.Web] $Web
    )
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
    $TargetFolder
}