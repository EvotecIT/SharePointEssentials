<p align="center">
  <a href="https://www.powershellgallery.com/packages/SharePointEssentials"><img src="https://img.shields.io/powershellgallery/v/SharePointEssentials.svg"></a>
  <a href="https://www.powershellgallery.com/packages/SharePointEssentials"><img src="https://img.shields.io/powershellgallery/vpre/SharePointEssentials.svg?label=powershell%20gallery%20preview&colorB=yellow"></a>
  <a href="https://github.com/EvotecIT/SharePointEssentials"><img src="https://img.shields.io/github/license/EvotecIT/SharePointEssentials.svg"></a>
</p>

<p align="center">
  <a href="https://www.powershellgallery.com/packages/SharePointEssentials"><img src="https://img.shields.io/powershellgallery/p/SharePointEssentials.svg"></a>
  <a href="https://github.com/EvotecIT/SharePointEssentials"><img src="https://img.shields.io/github/languages/top/evotecit/SharePointEssentials.svg"></a>
  <a href="https://github.com/EvotecIT/SharePointEssentials"><img src="https://img.shields.io/github/languages/code-size/evotecit/SharePointEssentials.svg"></a>
  <a href="https://www.powershellgallery.com/packages/SharePointEssentials"><img src="https://img.shields.io/powershellgallery/dt/SharePointEssentials.svg"></a>
</p>

<p align="center">
  <a href="https://twitter.com/PrzemyslawKlys"><img src="https://img.shields.io/twitter/follow/PrzemyslawKlys.svg?label=Twitter%20%40PrzemyslawKlys&style=social"></a>
  <a href="https://evotec.xyz/hub"><img src="https://img.shields.io/badge/Blog-evotec.xyz-2A6496.svg"></a>
  <a href="https://www.linkedin.com/in/pklys"><img src="https://img.shields.io/badge/LinkedIn-pklys-0077B5.svg?logo=LinkedIn"></a>
</p>

# SharePointEssentials
SharePointEssentials is a PowerShell module that covers my basic usage of SharePoint. My goal is to keep my SharePoint commands in it.
So far the only thing it can do is to synchronize files from local folder to SharePoint Online.

### Installation

```powershell
Install-Module SharePointEssentials -Force -Verbose
```

### Usage Synchronization

#### Permissions required

For this script to work, you need to have the following permissions on the application (as a minimum):

- Sharepoint / Sites.Selected
- Microsoft Graph / Sites.Selected

Of course you could run around with full control over all sites but that is not recommended.

#### Example

```powershell
$Url = 'https://site.sharepoint.com/sites/SharePointEssentials'
$ClientID = '438511c4' # Temp SharePoint App
$TenantID = 'ceb371f6'

# Using certificate is not only recommended but required for this script to work, it seems ClientSecret is not working
Connect-PnPOnline -Url $Url -ClientId $ClientID -Thumbprint 'dfdfdf' -Tenant $TenantID

$SyncFiles = @{
    SiteURL           = 'https://site.sharepoint.com/sites/SharePointEssentials'
    SourceFolderPath  = "C:\Support\GitHub\SharePointEssentials\Examples\Reports"
    TargetLibraryName = "Shared Documents"
    LogPath           = "$PSScriptRoot\Logs\Sync-FilesToSharePoint-$($(Get-Date).ToString('yyyy-MM-dd_HH_mm_ss')).log"
    LogMaximum        = 5
    #Include           = "*.aspx"
}

Sync-FilesToSharePoint @SyncFiles -WhatIf
```

### Credits

- Salaudeen Rajack - https://www.sharepointdiary.com/2020/07/sync-file-share-to-sharepoint-online-using-powershell.html