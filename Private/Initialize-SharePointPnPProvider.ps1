function Initialize-SharePointPnPProvider {
    <#
    .SYNOPSIS
    Loads the PnP PowerShell provider appropriate for the current host.
    #>
    [CmdletBinding()]
    param()

    $Provider = Get-SharePointPnPProvider
    $ConflictingProvider = Get-Module -Name $Provider.ConflictingName -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if ($ConflictingProvider) {
        throw "PnP provider '$($Provider.ConflictingName)' $($ConflictingProvider.Version) is already loaded, but SharePointEssentials uses '$($Provider.Name)' $($Provider.VersionRequirement) on $($Provider.PowerShellTarget). Start a clean PowerShell session and import SharePointEssentials again."
    }

    $LoadedProvider = Get-Module -Name $Provider.Name -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1
    $AvailableProviders = Get-Module -ListAvailable -Name $Provider.Name -ErrorAction SilentlyContinue

    if ($Provider.RequiredVersion) {
        $PreferredProvider = $AvailableProviders |
            Where-Object { $_.Version -eq $Provider.RequiredVersion } |
            Select-Object -First 1
    } else {
        $PreferredProvider = $AvailableProviders |
            Where-Object { $_.Version -ge $Provider.MinimumVersion } |
            Sort-Object Version -Descending |
            Select-Object -First 1
    }

    if ($LoadedProvider -and $Provider.RequiredVersion -and $LoadedProvider.Version -ne $Provider.RequiredVersion) {
        throw "PnP provider '$($Provider.Name)' $($LoadedProvider.Version) is already loaded, but SharePointEssentials requires $($Provider.VersionRequirement) on $($Provider.PowerShellTarget). Start a clean session after running: $($Provider.InstallCommand)"
    }

    if ($LoadedProvider -and $Provider.MinimumVersion -and $LoadedProvider.Version -lt $Provider.MinimumVersion) {
        throw "PnP provider '$($Provider.Name)' $($LoadedProvider.Version) is already loaded, but SharePointEssentials requires $($Provider.VersionRequirement) on $($Provider.PowerShellTarget). Start a clean session after running: $($Provider.InstallCommand)"
    }

    if ($LoadedProvider -and -not $Provider.RequiredVersion -and $PreferredProvider -and $LoadedProvider.Version -lt $PreferredProvider.Version) {
        throw "PnP provider '$($Provider.Name)' $($LoadedProvider.Version) is already loaded, but the highest installed supported version is $($PreferredProvider.Version). Start a clean PowerShell session and import SharePointEssentials again."
    }

    if (-not $LoadedProvider) {
        if (-not $PreferredProvider) {
            throw "PnP provider '$($Provider.Name)' $($Provider.VersionRequirement) is required for $($Provider.PowerShellTarget). Install it with: $($Provider.InstallCommand)"
        }

        Import-Module -Name $PreferredProvider.Path -Global -DisableNameChecking -ErrorAction Stop
        $LoadedProvider = Get-Module -Name $Provider.Name -ErrorAction SilentlyContinue |
            Sort-Object Version -Descending |
            Select-Object -First 1
    }

    if (-not $LoadedProvider) {
        throw "PnP provider '$($Provider.Name)' could not be loaded."
    }

    $null = Test-SharePointPnPProvider -ModuleName $Provider.Name
}
