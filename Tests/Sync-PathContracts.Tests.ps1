BeforeAll {
    Add-Type 'namespace Microsoft.SharePoint.Client { public class ClientObject { public string ServerRelativeUrl {get;set;} } }'
    Add-Type 'namespace Microsoft.SharePoint.Client { public class Web { public string ServerRelativeUrl {get;set;} } }'
    function Write-Color {}
    function Set-LoggingCapabilities {}
    function Get-PnPWeb {}
    function Get-PnPList { param($Identity, $Includes) }
    function Get-PnPListItem { param($List, $PageSize) }
    function Get-PnPFile { param($Url, $Path, $FileName, [switch]$AsFile, [switch]$Force) }
    function Get-PnPFolder { param($Url) }
    function Remove-PnPFile { param($SiteRelativeUrl, [switch]$Force) }
    function Find-TargetFolder { param($TargetLibraryName, $Library, $Web) }
    . "$PSScriptRoot/../Private/Get-SharePointSyncPath.ps1"
    . "$PSScriptRoot/../Private/Get-CommonDirectoryPath.ps1"
    . "$PSScriptRoot/../Private/Get-FilesLocal.ps1"
    . "$PSScriptRoot/../Private/Get-SharePointListIdentity.ps1"
    . "$PSScriptRoot/../Private/Export-FilesFromSharePoint.ps1"
    . "$PSScriptRoot/../Private/Remove-FilesFromLocal.ps1"
    . "$PSScriptRoot/../Private/Remove-FilesFromSharePoint.ps1"
    . "$PSScriptRoot/../Public/Sync-FilesFromSharePoint.ps1"
}
Describe 'Sync path and retention contracts' {
    It 'updates and retains a selected local file at root and site webs' -TestCases @(
        @{ WebPath = '/' }
        @{ WebPath = '/sites/test' }
    ) {
        param($WebPath)
        $root=Join-Path $TestDrive 'local'
        [void][IO.Directory]::CreateDirectory($root)
        $file=Join-Path $root 'Report.html'
        [IO.File]::WriteAllText($file,'old')
        $folder=$WebPath.TrimEnd('/') + '/Shared Documents/Reports[1]'
        Mock Get-PnPWeb { @{ ServerRelativeUrl=$WebPath } }
        Mock Get-PnPList { @{} }
        Mock Find-TargetFolder { @{ ServerRelativeUrl=$folder } }
        Mock Get-PnPListItem {
            @(
                [pscustomobject]@{ FieldValues=@{ Modified=[datetime]'2026-01-01'; FileRef="$folder/Report.html" }; FileSystemObjectType='File' }
                [pscustomobject]@{ FieldValues=@{ Modified=[datetime]'2026-01-01'; FileRef=$folder.Replace('Reports[1]','Reports1') + '/Other.html' }; FileSystemObjectType='File' }
            )
        }
        Mock Get-PnPFile { [IO.File]::WriteAllText((Join-Path $Path $FileName),'downloaded') }
        Sync-FilesFromSharePoint -SiteURL 'https://contoso.sharepoint.com' -SourceLibraryName 'Shared Documents/Reports[1]' -TargetFolderPath $root
        Test-Path -LiteralPath $file | Should -BeTrue
        [IO.File]::ReadAllText($file) | Should -Be 'downloaded'
        Test-Path -LiteralPath (Join-Path $root 'Other.html') | Should -BeFalse
        Assert-MockCalled Get-PnPFile -Times 1 -Exactly -ParameterFilter { $Url -eq '/Shared Documents/Reports[1]/Report.html' }
    }

    It 'retains the selected upload from a drive root and excludes wildcard-like sibling folders' {
        $file=Join-Path $TestDrive 'Retained.html'
        [IO.File]::WriteAllText($file,'retained')
        $driveRoot=[IO.Path]::GetPathRoot($file)
        $folder='/sites/test/Shared Documents/Reports[1]'
        $relative=$file.Substring($driveRoot.Length).Replace('\','/')
        $source=Get-FilesLocal -SourceFileList $file -SourceRootPath $driveRoot -TargetFolderSiteRelativeURL '/Shared Documents/Reports[1]'
        $web=[Microsoft.SharePoint.Client.Web]::new()
        $web.ServerRelativeUrl='/sites/test'
        $targetFolder=[Microsoft.SharePoint.Client.ClientObject]::new()
        $targetFolder.ServerRelativeUrl=$folder
        Mock Get-PnPListItem {
            @(
                [pscustomobject]@{ FieldValues=@{ Modified=[datetime]'2026-01-01'; FileRef="$folder/$relative" }; FileSystemObjectType='File' }
                [pscustomobject]@{ FieldValues=@{ Modified=[datetime]'2026-01-01'; FileRef='/sites/test/Shared Documents/Reports1/Other.html' }; FileSystemObjectType='File' }
            )
        }
        Mock Get-PnPFile { @{} }
        Mock Get-PnPFolder { $null }
        Mock Remove-PnPFile {}
        Remove-FilesFromSharePoint -Source $source.Source -SiteURL 'https://contoso.sharepoint.com/sites/test' -SourceFolderPath $driveRoot -TargetLibraryName 'Shared Documents' -TargetFolder $targetFolder -Web $web
        Assert-MockCalled Remove-PnPFile -Times 0
        Assert-MockCalled Get-PnPFile -Times 0
    }
}
