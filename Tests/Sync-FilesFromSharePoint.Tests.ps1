BeforeAll {
    function Write-Color {}
    function Set-LoggingCapabilities {}
    function Get-PnPWeb {}
    function Get-PnPList {}
    function Get-PnPListItem {}
    function Get-PnPFile {}
    function Get-PnPFolderItem {}
    function Export-FilesFromSharePoint {}
    function Remove-FilesFromLocal {}
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
}

