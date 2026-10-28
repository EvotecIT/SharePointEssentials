function Get-FilesLocal {
    <#
    .SYNOPSIS
    Discovers local sync files and maps them beneath a SharePoint target.

    .DESCRIPTION
    File lists use their common directory unless SourceRootPath is supplied.
    Discovery failures terminate so an incomplete list cannot drive removals.
    #>
    [CmdletBinding()]
    param(
        [Array] $SourceFileList,
        [string] $SourceFolderPath,
        [string] $SourceRootPath,
        [string] $Include,
        [string] $TargetFolderSiteRelativeURL
    )
    if ($PSBoundParameters.ContainsKey('SourceFileList')) {
        if (-not $SourceFileList -or $SourceFileList.Count -eq 0) {
            throw 'SourceFileList must contain at least one file.'
        }
        $SourceFiles = @(
            foreach ($Item in $SourceFileList) {
                $SourceItem = Get-Item -LiteralPath $Item -ErrorAction Stop
                if ($SourceItem -isnot [IO.FileInfo]) {
                    throw "SourceFileList accepts files only: '$Item'."
                }
                $SourceItem
            }
        )
        $SourceFiles = @($SourceFiles | Sort-Object FullName -Unique)
        if ($SourceRootPath) {
            $SourceRoot = Get-Item -LiteralPath $SourceRootPath -ErrorAction Stop
            if ($SourceRoot -isnot [IO.DirectoryInfo]) {
                throw "SourceRootPath must identify a directory: '$SourceRootPath'."
            }
            $SourceDirectoryPath = $SourceRoot.FullName
            if ($SourceDirectoryPath.Length -gt [IO.Path]::GetPathRoot($SourceDirectoryPath).Length) {
                $SourceDirectoryPath = $SourceDirectoryPath.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
            }
            $Comparison = if ([IO.Path]::DirectorySeparatorChar -eq '\') {
                [StringComparison]::OrdinalIgnoreCase
            } else {
                [StringComparison]::Ordinal
            }
            $RootPrefix = $SourceDirectoryPath.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
            foreach ($SourceFile in $SourceFiles) {
                if (-not $SourceFile.FullName.StartsWith($RootPrefix, $Comparison)) {
                    throw "Source file '$($SourceFile.FullName)' is outside SourceRootPath '$SourceDirectoryPath'."
                }
            }
        } else {
            $SourceDirectoryPath = Get-CommonDirectoryPath -Path $SourceFiles.DirectoryName
        }
        $DirectoryCache = [ordered] @{}
        foreach ($SourceFile in $SourceFiles) {
            $Directory = $SourceFile.Directory
            while ($null -ne $Directory -and $Directory.FullName -ne $SourceDirectoryPath) {
                $DirectoryCache[$Directory.FullName] = $Directory
                $Directory = $Directory.Parent
            }
        }
        $SourceItems = @($DirectoryCache.Values) + @($SourceFiles)
    } else {
        $SourceDirectory = Get-Item -LiteralPath $SourceFolderPath -ErrorAction Stop
        if ($SourceDirectory -isnot [IO.DirectoryInfo]) {
            throw "SourceFolderPath must identify a directory: '$SourceFolderPath'."
        }
        $SourceDirectoryPath = $SourceDirectory.FullName
        $SourceItems = @(Get-ChildItem -LiteralPath $SourceDirectoryPath -Recurse -ErrorAction Stop)
        if ($Include) {
            $SourceItems = @($SourceItems | Where-Object { $_.PSIsContainer -or $_.Name -like $Include })
        }
    }
    $SourceFilesCount = 0
    $SourceDirectoryCount = 0
    $RootPrefix = $SourceDirectoryPath.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $Source = @(
        foreach ($File in $SourceItems | Sort-Object -Unique -Property FullName) {
            $Date = $File.LastWriteTimeUtc
            $IsDirectory = $File -is [IO.DirectoryInfo]
            [pscustomobject] @{
                FullName = $File.FullName
                PSIsContainer = $IsDirectory
                TargetItemURL = $TargetFolderSiteRelativeURL.TrimEnd('/') + '/' + $File.FullName.Substring($RootPrefix.Length).Replace('\', '/')
                LastUpdated = [datetime]::new($Date.Year, $Date.Month, $Date.Day, $Date.Hour, $Date.Minute, $Date.Second)
            }
            if ($IsDirectory) {
                $SourceDirectoryCount++
            } else {
                $SourceFilesCount++
            }
        }
    )
    [ordered] @{
        Source = $Source
        SourceFilesCount = $SourceFilesCount
        SourceDirectoryCount = $SourceDirectoryCount
        SourceDirectoryPath = $SourceDirectoryPath
    }
}
