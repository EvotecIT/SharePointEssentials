function Get-SharePointSyncPath {
    <#
    .SYNOPSIS
    Maps a server-relative SharePoint path to consistent local and site-relative keys.

    .DESCRIPTION
    Removes literal path prefixes once and combines local paths using filesystem
    separators. The selected remote folder and web must contain the supplied path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $ServerRelativePath,
        [Parameter(Mandatory)][string] $RemoteFolderPath,
        [Parameter(Mandatory)][string] $LocalFolderPath,
        [Parameter(Mandatory)][string] $WebPath
    )
    $FolderPrefix = $RemoteFolderPath.TrimEnd('/') + '/'
    $WebPrefix = $WebPath.TrimEnd('/')
    if (-not $ServerRelativePath.StartsWith($FolderPrefix, [StringComparison]::OrdinalIgnoreCase) -or
        -not $ServerRelativePath.StartsWith($WebPrefix + '/', [StringComparison]::OrdinalIgnoreCase)) {
        throw "SharePoint path '$ServerRelativePath' is outside the selected folder or web."
    }
    $RelativePath = $ServerRelativePath.Substring($FolderPrefix.Length).Replace('/', [IO.Path]::DirectorySeparatorChar)
    [pscustomobject] @{
        FullName = [IO.Path]::GetFullPath([IO.Path]::Combine($LocalFolderPath, $RelativePath))
        TargetItemURL = $ServerRelativePath.Substring($WebPrefix.Length)
    }
}
