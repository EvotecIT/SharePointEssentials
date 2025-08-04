BeforeAll {
    function Write-Color {}
    function Add-PnPFile {}
    function Get-PnPListItem {}
    Add-Type 'namespace Microsoft.SharePoint.Client { public class ClientObject { public string ServerRelativeUrl {get;set;} } }'
    Add-Type 'namespace Microsoft.SharePoint.Client { public class Web { public string ServerRelativeUrl {get;set;} } }'
    . "$PSScriptRoot/../Private/Export-FilesToSharepoint.ps1"
}

Describe 'Export-FilesToSharePoint' {
    It 'uploads only when files differ from target' {
        $Web = [Microsoft.SharePoint.Client.Web]::new()
        $Web.ServerRelativeUrl = '/'
        $targetFolder = [Microsoft.SharePoint.Client.ClientObject]::new()
        $targetFolder.ServerRelativeUrl = '/Shared Documents'
        $source = @(
            [pscustomobject]@{
                FullName      = 'C:\\local\\match.txt'
                PSIsContainer = $false
                TargetItemURL = '/Shared Documents/match.txt'
                LastUpdated   = [datetime]'2024-01-01'
            },
            [pscustomobject]@{
                FullName      = 'C:\\local\\update.txt'
                PSIsContainer = $false
                TargetItemURL = '/Shared Documents/update.txt'
                LastUpdated   = [datetime]'2024-01-01'
            }
        )
        Mock Get-PnPListItem {
            @(
                [pscustomobject]@{
                    FieldValues = @{ Modified = [datetime]'2024-01-01'; FileRef = '/Shared Documents/match.txt' }
                    FileSystemObjectType = 'File'
                },
                [pscustomobject]@{
                    FieldValues = @{ Modified = [datetime]'2023-01-01'; FileRef = '/Shared Documents/update.txt' }
                    FileSystemObjectType = 'File'
                }
            )
        }
        Mock Add-PnPFile {}

        Export-FilesToSharePoint -Source $source -SourceFolderPath 'C:\\local' -TargetLibraryName 'Shared Documents' -TargetFolder $targetFolder -Web $Web

        Assert-MockCalled Add-PnPFile -Times 1
    }
}
