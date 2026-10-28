function Get-CommonDirectoryPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]] $Path
    )

    $FullPaths = @($Path | ForEach-Object { [System.IO.Path]::GetFullPath($_) } | Select-Object -Unique)
    if ($FullPaths.Count -eq 0) {
        return
    }

    $Comparison = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') {
        [System.StringComparison]::OrdinalIgnoreCase
    } else {
        [System.StringComparison]::Ordinal
    }
    $Separator = [System.IO.Path]::DirectorySeparatorChar
    $CommonPath = $FullPaths[0]

    foreach ($Candidate in $FullPaths | Select-Object -Skip 1) {
        while ($true) {
            $CommonPrefix = if ($CommonPath.EndsWith([string] $Separator)) { $CommonPath } else { $CommonPath + $Separator }
            if ($Candidate.Equals($CommonPath, $Comparison) -or $Candidate.StartsWith($CommonPrefix, $Comparison)) {
                break
            }

            $Parent = [System.IO.Directory]::GetParent($CommonPath)
            if ($null -eq $Parent) {
                throw "Paths do not share a common directory: $($FullPaths -join ', ')"
            }
            $CommonPath = $Parent.FullName
        }
    }

    $CommonPath
}
