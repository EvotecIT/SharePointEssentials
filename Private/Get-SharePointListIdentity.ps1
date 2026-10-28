function Get-SharePointListIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $LibraryPath
    )

    $NormalizedPath = $LibraryPath.Trim().Trim('/')
    if ([string]::IsNullOrWhiteSpace($NormalizedPath)) {
        throw 'A SharePoint library name or library/folder path is required.'
    }

    ($NormalizedPath -split '/', 2)[0]
}
