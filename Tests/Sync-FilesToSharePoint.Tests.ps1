BeforeAll {
    function Write-Color {}
    function Set-LoggingCapabilities {}
    function Get-PnPWeb {}
    function Get-PnPList { param($Identity, $Includes) }
    function Get-FilesLocal { param($SourceFileList, $SourceFolderPath, $SourceRootPath, $Include, $TargetFolderSiteRelativeURL) }
    function Find-TargetFolder { param($TargetLibraryName, $Library, $Web) }
    function Export-FilesToSharePoint { param($Source,$SourceFolderPath,$TargetLibraryName,$TargetFolder,$Web,[switch]$WhatIf) }
    function Remove-FilesFromSharePoint { param($Source,$SiteURL,$SourceFolderPath,$TargetLibraryName,$TargetFolder,$Web,[switch]$WhatIf,$ExcludeFromRemoval) }
    Add-Type 'namespace Microsoft.SharePoint.Client { public class ClientObject { public string ServerRelativeUrl {get;set;} } }'
    . "$PSScriptRoot/../Private/Get-SharePointListIdentity.ps1"
    . "$PSScriptRoot/../Public/Sync-FilesToSharePoint.ps1"
}

Describe 'Sync-FilesToSharePoint' {
    It 'stops before upload or removal when discovery fails' {
        $targetFolder = [Microsoft.SharePoint.Client.ClientObject]::new()
        $targetFolder.ServerRelativeUrl = '/Shared Documents'
        Mock Get-PnPWeb { @{ ServerRelativeUrl = '/' } }
        Mock Get-PnPList { @{ RootFolder = @{ ServerRelativeUrl = '/Shared Documents' } } }
        Mock Find-TargetFolder { $targetFolder }
        Mock Get-FilesLocal { throw 'Source unavailable' }
        Mock Export-FilesToSharePoint { }
        Mock Remove-FilesFromSharePoint { }
        { Sync-FilesToSharePoint -SiteURL 'https://contoso.sharepoint.com/sites/test' -SourceFolderPath '/tmp' -TargetLibraryName 'Shared Documents' } | Should -Throw '*Source unavailable*'
        Assert-MockCalled Export-FilesToSharePoint -Times 0
        Assert-MockCalled Remove-FilesFromSharePoint -Times 0
    }

    It 'refuses an empty discovery result before changing SharePoint' {
        $targetFolder = [Microsoft.SharePoint.Client.ClientObject]::new()
        $targetFolder.ServerRelativeUrl = '/Shared Documents'
        Mock Get-PnPWeb { @{ ServerRelativeUrl = '/' } }
        Mock Get-PnPList { @{ RootFolder = @{ ServerRelativeUrl = '/Shared Documents' } } }
        Mock Find-TargetFolder { $targetFolder }
        Mock Get-FilesLocal { @{ Source = @(); SourceDirectoryPath = '/tmp' } }
        Mock Export-FilesToSharePoint { }
        Mock Remove-FilesFromSharePoint { }
        { Sync-FilesToSharePoint -SiteURL 'https://contoso.sharepoint.com/sites/test' -SourceFolderPath '/tmp' -TargetLibraryName 'Shared Documents' } | Should -Throw '*No source items*'
        Assert-MockCalled Export-FilesToSharePoint -Times 0
        Assert-MockCalled Remove-FilesFromSharePoint -Times 0
    }
    It 'calls private functions to process files' {
        $dummySource = @('file1')
        $targetFolder = [Microsoft.SharePoint.Client.ClientObject]::new()
        $targetFolder.ServerRelativeUrl = '/Shared Documents'
        $siteUrl = 'https://contoso.sharepoint.com/sites/test'

        Mock Get-PnPWeb { @{ ServerRelativeUrl = '/' } }
        Mock Get-PnPList { @{ RootFolder = @{ ServerRelativeUrl = '/Shared Documents' } } }
        Mock Find-TargetFolder { $targetFolder }
        Mock Get-FilesLocal { @{ Source = $dummySource; SourceDirectoryPath = '/tmp'; SourceFilesCount = 0; SourceDirectoryCount = 0 } }
        Mock Export-FilesToSharePoint { }
        Mock Remove-FilesFromSharePoint { }

        Sync-FilesToSharePoint -SiteURL $siteUrl -SourceFolderPath '/tmp' -TargetLibraryName 'Shared Documents' -WhatIf

        Assert-MockCalled Export-FilesToSharePoint -Times 1 -ParameterFilter {
            $SourceFolderPath -eq '/tmp' -and
            $TargetLibraryName -eq 'Shared Documents' -and
            $Web.ServerRelativeUrl -eq '/' -and
            $WhatIf
        }

        Assert-MockCalled Remove-FilesFromSharePoint -Times 1 -ParameterFilter {
            $SiteURL -eq $siteUrl -and
            $SourceFolderPath -eq '/tmp' -and
            $TargetLibraryName -eq 'Shared Documents' -and
            $Web.ServerRelativeUrl -eq '/' -and
            $WhatIf -and
            $null -eq $ExcludeFromRemoval
        }
    }

    It 'skips removal when SkipRemoval is specified' {
        $dummySource = @('file1')
        $targetFolder = [Microsoft.SharePoint.Client.ClientObject]::new()
        $targetFolder.ServerRelativeUrl = '/Shared Documents'

        Mock Get-PnPWeb { @{ ServerRelativeUrl = '/' } }
        Mock Get-PnPList { @{ RootFolder = @{ ServerRelativeUrl = '/Shared Documents' } } }
        Mock Find-TargetFolder { $targetFolder }
        Mock Get-FilesLocal { @{ Source = $dummySource; SourceDirectoryPath = '/tmp'; SourceFilesCount = 0; SourceDirectoryCount = 0 } }
        Mock Export-FilesToSharePoint { }
        Mock Remove-FilesFromSharePoint { }

        Sync-FilesToSharePoint -SiteURL 'https://contoso.sharepoint.com/sites/test' -SourceFolderPath '/tmp' -TargetLibraryName 'Shared Documents' -SkipRemoval -WhatIf

        Assert-MockCalled Remove-FilesFromSharePoint -Times 0
    }

    It 'uses the library root for list operations when a nested target folder is selected' {
        $targetFolder = [Microsoft.SharePoint.Client.ClientObject]::new()
        $targetFolder.ServerRelativeUrl = '/Shared Documents/Reports'

        Mock Get-PnPWeb { @{ ServerRelativeUrl = '/' } }
        Mock Get-PnPList { @{ RootFolder = @{ ServerRelativeUrl = '/Shared Documents' } } }
        Mock Find-TargetFolder { $targetFolder }
        Mock Get-FilesLocal { @{ Source = @('file1'); SourceDirectoryPath = '/tmp'; SourceFilesCount = 1; SourceDirectoryCount = 0 } }
        Mock Export-FilesToSharePoint { }
        Mock Remove-FilesFromSharePoint { }

        Sync-FilesToSharePoint -SiteURL 'https://contoso.sharepoint.com/sites/test' -SourceFolderPath '/tmp' -TargetLibraryName 'Shared Documents/Reports' -WhatIf

        Assert-MockCalled Get-PnPList -Times 1 -ParameterFilter { $Identity -eq 'Shared Documents' }
        Assert-MockCalled Find-TargetFolder -Times 1 -ParameterFilter { $TargetLibraryName -eq 'Shared Documents/Reports' }
        Assert-MockCalled Export-FilesToSharePoint -Times 1 -ParameterFilter { $TargetLibraryName -eq 'Shared Documents' }
        Assert-MockCalled Remove-FilesFromSharePoint -Times 1 -ParameterFilter { $TargetLibraryName -eq 'Shared Documents' }
    }

    It 'passes an explicit source root through file-list synchronization' {
        $targetFolder = [Microsoft.SharePoint.Client.ClientObject]::new()
        $targetFolder.ServerRelativeUrl = '/Shared Documents/Reports'

        Mock Get-PnPWeb { @{ ServerRelativeUrl = '/' } }
        Mock Get-PnPList { @{ RootFolder = @{ ServerRelativeUrl = '/Shared Documents' } } }
        Mock Find-TargetFolder { $targetFolder }
        Mock Get-FilesLocal { @{ Source = @('file1'); SourceDirectoryPath = 'C:\Reports'; SourceFilesCount = 1; SourceDirectoryCount = 1 } }
        Mock Export-FilesToSharePoint { }
        Mock Remove-FilesFromSharePoint { }

        Sync-FilesToSharePoint -SiteURL 'https://contoso.sharepoint.com/sites/test' -SourceFileList 'C:\Reports\Global\LegacyUsers.xlsx' -SourceRootPath 'C:\Reports' -TargetLibraryName 'Shared Documents/Reports' -WhatIf

        Assert-MockCalled Get-FilesLocal -Times 1 -ParameterFilter { $SourceRootPath -eq 'C:\Reports' }
    }

    It 'passes ExcludeFromRemoval to Remove-FilesFromSharePoint' {
        $dummySource = @('file1')
        $targetFolder = [Microsoft.SharePoint.Client.ClientObject]::new()
        $targetFolder.ServerRelativeUrl = '/Shared Documents'
        $exclude = @('keep.txt','stay/dir')
        $siteUrl = 'https://contoso.sharepoint.com/sites/test'

        Mock Get-PnPWeb { @{ ServerRelativeUrl = '/' } }
        Mock Get-PnPList { @{ RootFolder = @{ ServerRelativeUrl = '/Shared Documents' } } }
        Mock Find-TargetFolder { $targetFolder }
        Mock Get-FilesLocal { @{ Source = $dummySource; SourceDirectoryPath = '/tmp'; SourceFilesCount = 0; SourceDirectoryCount = 0 } }
        Mock Export-FilesToSharePoint { }
        Mock Remove-FilesFromSharePoint { }

        Sync-FilesToSharePoint -SiteURL $siteUrl -SourceFolderPath '/tmp' -TargetLibraryName 'Shared Documents' -ExcludeFromRemoval $exclude -WhatIf

        Assert-MockCalled Remove-FilesFromSharePoint -Times 1 -ParameterFilter {
            $SiteURL -eq $siteUrl -and
            $ExcludeFromRemoval -and
            ($ExcludeFromRemoval -join ',') -eq ($exclude -join ',')
        }
    }
}
