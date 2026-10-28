BeforeAll {
    function Write-Color {}
    . "$PSScriptRoot/../Private/Get-CommonDirectoryPath.ps1"
    . "$PSScriptRoot/../Private/Get-FilesLocal.ps1"
}

Describe 'Get-FilesLocal' {
    It 'includes directories when filtering by Include' {
        $root = Join-Path $TestDrive 'local'
        New-Item -ItemType Directory -Path $root | Out-Null
        $dir1 = Join-Path $root 'dir1'
        $dir2 = Join-Path $root 'dir2'
        $subdir = Join-Path $dir1 'subdir'
        foreach ($d in @($dir1, $dir2, $subdir)) { New-Item -ItemType Directory -Path $d | Out-Null }
        New-Item -ItemType File -Path (Join-Path $dir1 'a.txt') | Out-Null
        New-Item -ItemType File -Path (Join-Path $dir2 'b.txt') | Out-Null
        New-Item -ItemType File -Path (Join-Path $dir1 'c.log') | Out-Null

        $result = Get-FilesLocal -SourceFolderPath $root -Include '*.txt' -TargetFolderSiteRelativeURL '/target'

        $result.SourceFilesCount | Should -Be 2
        $result.SourceDirectoryCount | Should -Be 3
        ($result.Source.Where({ $_.PSIsContainer })).Count | Should -Be 3
    }

    It 'preserves the common root for files from sibling report folders' {
        $root = Join-Path $TestDrive 'reports'
        $global = Join-Path $root 'Global'
        $crew = Join-Path $root 'ITISC01'
        New-Item -ItemType Directory -Path $global, $crew | Out-Null
        $globalFile = New-Item -ItemType File -Path (Join-Path $global 'LegacyUsers.xlsx')
        $crewFile = New-Item -ItemType File -Path (Join-Path $crew 'LegacyUsers_ITISC01.aspx')

        $result = Get-FilesLocal -SourceFileList $globalFile.FullName, $crewFile.FullName -TargetFolderSiteRelativeURL '/Shared Documents/Reports'

        $result.SourceDirectoryPath | Should -Be $root
        $result.SourceFilesCount | Should -Be 2
        $result.SourceDirectoryCount | Should -Be 2
        $result.Source.TargetItemURL | Should -Contain '/Shared Documents/Reports/Global/LegacyUsers.xlsx'
        $result.Source.TargetItemURL | Should -Contain '/Shared Documents/Reports/ITISC01/LegacyUsers_ITISC01.aspx'
    }

    It 'preserves an explicit source root when selected files are all in one subfolder' {
        $root = Join-Path $TestDrive 'reports-explicit'
        $global = Join-Path $root 'Global'
        New-Item -ItemType Directory -Path $global | Out-Null
        $file = New-Item -ItemType File -Path (Join-Path $global 'LegacyUsers.xlsx')

        $result = Get-FilesLocal -SourceFileList $file.FullName -SourceRootPath $root -TargetFolderSiteRelativeURL '/Shared Documents/Reports'

        $result.SourceDirectoryPath | Should -Be $root
        $result.Source.TargetItemURL | Should -Contain '/Shared Documents/Reports/Global/LegacyUsers.xlsx'
    }

    It 'rejects files outside an explicit source root' {
        $root = Join-Path $TestDrive 'reports-contained'
        $outside = Join-Path $TestDrive 'outside.xlsx'
        New-Item -ItemType Directory -Path $root | Out-Null
        New-Item -ItemType File -Path $outside | Out-Null

        { Get-FilesLocal -SourceFileList $outside -SourceRootPath $root -TargetFolderSiteRelativeURL '/Shared Documents/Reports' } | Should -Throw '*outside SourceRootPath*'
    }

    It 'terminates when a selected source file cannot be read' {
        $file = New-Item -ItemType File -Path (Join-Path $TestDrive 'valid.html')
        { Get-FilesLocal -SourceFileList @($file.FullName, (Join-Path $TestDrive 'missing.html')) -TargetFolderSiteRelativeURL '/target' } | Should -Throw
    }

    It 'rejects an explicitly empty file list' {
        { Get-FilesLocal -SourceFileList @() -TargetFolderSiteRelativeURL '/target' } | Should -Throw '*at least one file*'
    }

    It 'maps a root with different casing and a trailing separator' {
        $root = Join-Path $TestDrive 'MixedRoot'
        $folder = Join-Path $root 'Nested'
        New-Item -ItemType Directory -Path $folder | Out-Null
        $file = New-Item -ItemType File -Path (Join-Path $folder 'Report.html')
        $result = Get-FilesLocal -SourceFileList $file.FullName -SourceRootPath ($root.ToLowerInvariant() + '\') -TargetFolderSiteRelativeURL '/target/'
        $result.Source.TargetItemURL | Should -Contain '/target/Nested/Report.html'
        @($result.Source | Where-Object { $_.TargetItemURL -match '^[A-Za-z]:' }).Count | Should -Be 0
    }
}
