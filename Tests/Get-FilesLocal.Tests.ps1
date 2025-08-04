BeforeAll {
    function Write-Color {}
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
}
