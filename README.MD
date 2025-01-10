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

#### Creating SharePoint Sites

```powershell
New-SPOSite -Url "https://site.sharepoint.com/sites/TheDashboard" -Owner admin@microsoft.com -Title TRest -Template "BLANKINTERNETCONTAINER#0" -StorageQuota 50000
```

#### Permissions required

For this script to work, you need to have the following permissions on the application (as a minimum):

- Sharepoint / Sites.Selected
- Microsoft Graph / Sites.Selected

Of course you could run around with full control over all sites but that is not recommended.

#### Permissions assigned

Once you created application with minimal permissions you need to choose which sites should be covered under it.

```powershell
$ClientID = '438511c4' # Temp SharePoint App
$Url = 'https://site.sharepoint.com/sites/TheDashboard'

# Lets connect to SharePoint Online
Connect-PnPOnline -Url $Url -Interactive
#First create a Read or Write permission entry for the app to the site. Currently unable to Set as FullControl
$WritePermissions = Grant-PnPAzureADAppSitePermission -Permissions "Write" -Site $Url -AppId $ClientID -DisplayName "Temp SharePoint App"
# Get the Permission ID for the app using App Id
$PermissionId = Get-PnPAzureADAppSitePermission -AppIdentity $ClientID
# Change the newly created Read/Write app site permission entry to FullControl
Set-PnPAzureADAppSitePermission -Site $Url -PermissionId $(($PermissionId).Id) -Permissions "FullControl"
```

#### Verify that it worked

Lets verify things worked as expected. You can do it by running the following command:

```powershell
$ClientID = '438511c4' # Temp SharePoint App
$TenantID = 'ceb371f6'

#Connect-PnPOnline -Url $Url -ClientId $ClientID -ClientSecret $ClientSecret
Connect-PnPOnline -Url $Url -ClientId $ClientID -Thumbprint '2EC' -Tenant $TenantID

$FolderSiteRelativeUrl = "/Shared Documents" #Folder's Site Relative Path
$FolderItems = Get-PnPFolderItem -FolderSiteRelativeUrl $FolderSiteRelativeUrl -ItemType File -Recursive
$FolderItems | Format-Table
```

#### Example

If everything works you can run the following command to synchronize files from local folder to SharePoint Online.

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