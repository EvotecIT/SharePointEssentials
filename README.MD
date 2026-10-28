<p align="center">
  <a href="https://www.powershellgallery.com/packages/SharePointEssentials"><img src="https://img.shields.io/powershellgallery/v/SharePointEssentials.svg"></a>
  <a href="https://www.powershellgallery.com/packages/SharePointEssentials"><img src="https://img.shields.io/powershellgallery/v/SharePointEssentials.svg?label=powershell%20gallery%20preview&colorB=yellow&include_prereleases"></a>
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

Install the PnP provider that matches the PowerShell host. SharePointEssentials
selects and validates that provider when it is imported.

PowerShell 7.4 or newer uses the maintained PnP.PowerShell 3.x provider:

```powershell
Install-Module PnP.PowerShell -MinimumVersion 3.2.0 -Scope CurrentUser
Install-Module SharePointEssentials -Force
```

Windows PowerShell 5.1 uses PnP.PowerShell 1.12.0. This is the final 1.x
release and includes the .NET Framework assembly needed by Windows PowerShell.
The exact version is intentional: later PnP.PowerShell releases require
PowerShell 7. Use PowerShell 7 and the current 3.x line for maintained PnP
functionality and security updates.

```powershell
Install-Module PnP.PowerShell -RequiredVersion 1.12.0 -Scope CurrentUser
Install-Module SharePointEssentials -Force
```

### Usage Synchronization

When uploading selected files, use `SourceRootPath` to preserve their directory
structure even when every selected file is in one subfolder:

```powershell
Sync-FilesToSharePoint -SiteURL 'https://contoso.sharepoint.com/sites/reports' `
    -SourceFileList 'C:\Reports\Custom\Report.html' -SourceRootPath 'C:\Reports' `
    -TargetLibraryName 'Shared Documents' -SkipRemoval -WhatIf
```

This maps the file to `Shared Documents/Custom/Report.html`. Without an explicit
root, file lists use their common parent directory. `SourceRootPath` applies to
`SourceFileList`; folder synchronization uses `SourceFolderPath` as its root.
Unreadable inputs stop synchronization. Upload synchronization also refuses an
empty inventory. `SkipRemoval` preserves remote files absent from the selected
list; omit it only when that list defines the complete content to retain.

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
