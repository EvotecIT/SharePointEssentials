BeforeAll {
    function Write-Color {}
    function Set-LoggingCapabilities {}
    function Get-PnPWeb {}
    function Get-PnPList {}
    function Get-PnPListItem {}
    function Get-PnPFile {}
    function Get-PnPFolderItem {}
    function Export-FilesFromSharePoint { param($Source,$Target,$TargetFolderPath,[switch]$WhatIf) }
    function Remove-FilesFromLocal { param($Source,$Target,$WhatIf,$ExcludeFromRemoval) }
    function Get-FilesLocal {}
    function Find-TargetFolder {}
    . "$PSScriptRoot/../Public/Sync-FilesFromSharePoint.ps1"
}

Describe 'Sync-FilesFromSharePoint' {
    It 'calls private functions to process files' {
        Mock Get-PnPWeb { @{ ServerRelativeUrl = '/' } }
        Mock Get-PnPList { @{ RootFolder = @{ ServerRelativeUrl = '/Shared Documents' } } }
        Mock Find-TargetFolder { @{ ServerRelativeUrl = '/Shared Documents' } }
        Mock Get-PnPListItem { @() }
        Mock Get-FilesLocal { @{ Source = @(); SourceDirectoryPath = '/tmp'; SourceFilesCount = 0; SourceDirectoryCount = 0 } }
        Mock Export-FilesFromSharePoint { }
        Mock Remove-FilesFromLocal { }

        Sync-FilesFromSharePoint -SiteURL 'https://contoso.sharepoint.com/sites/test' -TargetFolderPath '/tmp' -SourceLibraryName 'Shared Documents' -WhatIf

        Assert-MockCalled Export-FilesFromSharePoint -Times 1
        Assert-MockCalled Remove-FilesFromLocal -Times 1
    }

    It 'skips removal when SkipRemoval is specified' {
        Mock Get-PnPWeb { @{ ServerRelativeUrl = '/' } }
        Mock Get-PnPList { @{ RootFolder = @{ ServerRelativeUrl = '/Shared Documents' } } }
        Mock Find-TargetFolder { @{ ServerRelativeUrl = '/Shared Documents' } }
        Mock Get-PnPListItem { @() }
        Mock Get-FilesLocal { @{ Source = @(); SourceDirectoryPath = '/tmp'; SourceFilesCount = 0; SourceDirectoryCount = 0 } }
        Mock Export-FilesFromSharePoint { }
        Mock Remove-FilesFromLocal { }

        Sync-FilesFromSharePoint -SiteURL 'https://contoso.sharepoint.com/sites/test' -TargetFolderPath '/tmp' -SourceLibraryName 'Shared Documents' -SkipRemoval -WhatIf

        Assert-MockCalled Remove-FilesFromLocal -Times 0
    }

    It 'passes ExcludeFromRemoval to Remove-FilesFromLocal' {
        $exclude = @('keep.txt','stay/dir')
        Mock Get-PnPWeb { @{ ServerRelativeUrl = '/' } }
        Mock Get-PnPList { @{ RootFolder = @{ ServerRelativeUrl = '/Shared Documents' } } }
        Mock Find-TargetFolder { @{ ServerRelativeUrl = '/Shared Documents' } }
        Mock Get-PnPListItem { @() }
        Mock Get-FilesLocal { @{ Source = @(); SourceDirectoryPath = '/tmp'; SourceFilesCount = 0; SourceDirectoryCount = 0 } }
        Mock Export-FilesFromSharePoint { }
        $Global:received = $null
        Mock Remove-FilesFromLocal { param($Source,$Target,$WhatIf,$ExcludeFromRemoval); $Global:received = $ExcludeFromRemoval }

        Sync-FilesFromSharePoint -SiteURL 'https://contoso.sharepoint.com/sites/test' -TargetFolderPath '/tmp' -SourceLibraryName 'Shared Documents' -ExcludeFromRemoval $exclude -WhatIf

        Assert-MockCalled Remove-FilesFromLocal -Times 1
        $Global:received | Should -Be $exclude
    }
}

