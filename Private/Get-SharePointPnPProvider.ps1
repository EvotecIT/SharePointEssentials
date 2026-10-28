function Get-SharePointPnPProvider {
    <#
    .SYNOPSIS
    Gets the PnP PowerShell provider supported by the current PowerShell host.

    .DESCRIPTION
    Windows PowerShell uses PnP.PowerShell 1.12.0, the final 1.x release that
    includes both .NET Framework and .NET Core assemblies. PowerShell Core uses
    the maintained PnP.PowerShell 3.x line.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Desktop', 'Core')]
        [string] $Edition = $PSVersionTable.PSEdition,

        [Parameter()]
        [version] $PowerShellVersion = $PSVersionTable.PSVersion
    )

    if ($Edition -eq 'Core') {
        if ($PowerShellVersion -lt [version] '7.4.0') {
            throw "SharePointEssentials requires PowerShell 7.4.0 or newer when using PnP.PowerShell 3.x. The current version is $PowerShellVersion."
        }

        return [pscustomobject] @{
            Name                = 'PnP.PowerShell'
            RequiredVersion     = $null
            MinimumVersion      = [version] '3.2.0'
            ConflictingName     = 'SharePointPnPPowerShellOnline'
            InstallCommand      = 'Install-Module PnP.PowerShell -MinimumVersion 3.2.0 -Scope CurrentUser'
            PowerShellTarget    = 'PowerShell 7.4 or newer'
            VersionRequirement  = '3.2.0 or newer'
        }
    }

    [pscustomobject] @{
        Name                = 'PnP.PowerShell'
        RequiredVersion     = [version] '1.12.0'
        MinimumVersion      = $null
        ConflictingName     = 'SharePointPnPPowerShellOnline'
        InstallCommand      = 'Install-Module PnP.PowerShell -RequiredVersion 1.12.0 -Scope CurrentUser'
        PowerShellTarget    = 'Windows PowerShell 5.1'
        VersionRequirement  = 'exactly 1.12.0'
    }
}
