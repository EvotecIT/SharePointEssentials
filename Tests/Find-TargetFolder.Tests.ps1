BeforeAll {
    function Get-PnPFolderItem { param($ItemType, [switch] $Recursive, $FolderSiteRelativeUrl) }
    function Write-Color {}
    Add-Type 'namespace Microsoft.SharePoint.Client { public class List { } }'
    . "$PSScriptRoot/../Private/Find-TargetFolder.ps1"
}
Describe 'Nested SharePoint target folders' {
    It 'resolves a nested folder at a root web or a site web' -TestCases @(
        @{ WebPath = '/'; FolderPath = '/Shared Documents/Reports' }
        @{ WebPath = '/sites/test'; FolderPath = '/sites/test/Shared Documents/Reports' }
    ) {
        param($WebPath, $FolderPath)
        $web = [Microsoft.SharePoint.Client.Web]::new()
        $web.ServerRelativeUrl = $WebPath
        Mock Get-PnPFolderItem { [pscustomobject] @{ ServerRelativeUrl = $FolderPath } }
        $result = Find-TargetFolder -TargetLibraryName '/Shared Documents/Reports/' -Web $web
        $result.ServerRelativeUrl | Should -Be $FolderPath
    }
}
