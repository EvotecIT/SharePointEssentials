BeforeAll {
    function Write-Color {}
    function Set-LoggingCapabilities {}
    function Get-PnPWeb {}
    function Get-PnPList {}
    function Get-FilesLocal {}
    function Find-TargetFolder {}
    function Export-FilesToSharePoint { param($Source,$SourceFolderPath,$TargetLibraryName,$TargetFolder,[switch]$WhatIf) }
    function Remove-FilesFromSharePoint { param($Source,$SiteURL,$SourceFolderPath,$TargetLibraryName,$TargetFolder,[switch]$WhatIf,$ExcludeFromRemoval) }
    Add-Type 'namespace Microsoft.SharePoint.Client { public class ClientObject { public string ServerRelativeUrl {get;set;} } }'
    . "$PSScriptRoot/../Public/Sync-FilesToSharePoint.ps1"
}

Describe 'Sync-FilesToSharePoint' {
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
            $WhatIf
        }

        Assert-MockCalled Remove-FilesFromSharePoint -Times 1 -ParameterFilter {
            $SiteURL -eq $siteUrl -and
            $SourceFolderPath -eq '/tmp' -and
            $TargetLibraryName -eq 'Shared Documents' -and
            $WhatIf -and
            $null -eq $ExcludeFromRemoval
        }
    }
}
