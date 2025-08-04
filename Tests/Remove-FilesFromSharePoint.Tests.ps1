BeforeAll {
    function Write-Color {}
    function Get-PnPListItem {}
    function Get-PnPFolder {}
    function Remove-PnPFile {}
    function Get-PnPFile {}
    Add-Type 'namespace Microsoft.SharePoint.Client { public class ClientObject { public string ServerRelativeUrl {get;set;} } }'
    Add-Type 'namespace Microsoft.SharePoint.Client { public class Web { public string ServerRelativeUrl {get;set;} } }'
    . "$PSScriptRoot/../Private/Remove-FilesFromSharePoint.ps1"
}

Describe 'Remove-FilesFromSharePoint' {
    It 'aborts when Get-PnPListItem fails' {
        $Web = [Microsoft.SharePoint.Client.Web]::new()
        $targetFolder = [Microsoft.SharePoint.Client.ClientObject]::new()
        $targetFolder.ServerRelativeUrl = '/Shared Documents'
        Mock Get-PnPListItem { throw 'fail' }
        Mock Remove-PnPFile {}
        Mock Write-Color {}

        Remove-FilesFromSharePoint -Source @() -SiteURL 'https://contoso.sharepoint.com/sites/test' -SourceFolderPath 'C:\local' -TargetLibraryName 'Shared Documents' -TargetFolder $targetFolder -Web $Web

        Assert-MockCalled Write-Color -Times 1
        Assert-MockCalled Remove-PnPFile -Times 0
    }
}
