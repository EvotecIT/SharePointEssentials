BeforeAll {
    . "$PSScriptRoot/../Private/Get-SharePointPnPProvider.ps1"
    . "$PSScriptRoot/../Private/Initialize-SharePointPnPProvider.ps1"
    . "$PSScriptRoot/../Private/Test-SharePointPnPProvider.ps1"
}

Describe 'SharePointEssentials PnP provider selection' {
    It 'selects the final PnP.PowerShell 1.x release for Windows PowerShell 5.1' {
        $Provider = Get-SharePointPnPProvider -Edition Desktop -PowerShellVersion 5.1

        $Provider.Name | Should -Be 'PnP.PowerShell'
        $Provider.RequiredVersion | Should -Be ([version] '1.12.0')
        $Provider.MinimumVersion | Should -BeNullOrEmpty
    }

    It 'selects the maintained provider for PowerShell 7.4 and newer' {
        $Provider = Get-SharePointPnPProvider -Edition Core -PowerShellVersion 7.4.0

        $Provider.Name | Should -Be 'PnP.PowerShell'
        $Provider.MinimumVersion | Should -Be ([version] '3.2.0')
        $Provider.RequiredVersion | Should -BeNullOrEmpty
    }

    It 'rejects PowerShell Core versions unsupported by PnP.PowerShell 3.x' {
        { Get-SharePointPnPProvider -Edition Core -PowerShellVersion 7.3 } |
            Should -Throw '*requires PowerShell 7.4.0 or newer*'
    }

    It 'keeps the runtime-selected PnP provider out of RequiredModules' {
        $Manifest = Import-PowerShellDataFile "$PSScriptRoot/../SharePointEssentials.psd1"
        $RequiredModuleNames = @($Manifest.RequiredModules | ForEach-Object {
                if ($_ -is [hashtable]) { $_.ModuleName } else { $_ }
            })

        $RequiredModuleNames | Should -Not -Contain 'PnP.PowerShell'
        $RequiredModuleNames | Should -Not -Contain 'SharePointPnPPowerShellOnline'
        $Manifest.PrivateData.PSData.ExternalModuleDependencies | Should -Contain 'PnP.PowerShell'
        $Manifest.PrivateData.PSData.ExternalModuleDependencies | Should -Not -Contain 'SharePointPnPPowerShellOnline'
    }

    It 'rejects an older loaded Core provider when a newer supported version is installed' {
        Mock Get-SharePointPnPProvider {
            [pscustomobject] @{
                Name               = 'PnP.PowerShell'
                RequiredVersion    = $null
                MinimumVersion     = [version] '3.2.0'
                ConflictingName    = 'SharePointPnPPowerShellOnline'
                InstallCommand     = 'Install-Module PnP.PowerShell'
                PowerShellTarget   = 'PowerShell 7.4 or newer'
                VersionRequirement = '3.2.0 or newer'
            }
        }
        Mock Get-Module { $null } -ParameterFilter { $Name -eq 'SharePointPnPPowerShellOnline' }
        Mock Get-Module {
            [pscustomobject] @{ Version = [version] '3.3.0'; Path = 'PnP.PowerShell-3.3.0.psd1' }
        } -ParameterFilter { $Name -eq 'PnP.PowerShell' -and $ListAvailable }
        Mock Get-Module {
            [pscustomobject] @{ Version = [version] '3.2.0'; Path = 'PnP.PowerShell-3.2.0.psd1' }
        } -ParameterFilter { $Name -eq 'PnP.PowerShell' -and -not $ListAvailable }

        { Initialize-SharePointPnPProvider } | Should -Throw '*highest installed supported version is 3.3.0*'
    }

    It 'rejects parameters that exist only across incompatible parameter sets' {
        Mock Get-Command {
            [pscustomobject] @{
                ModuleName    = 'PnPContractFixture'
                Parameters    = @{
                    Url        = $true
                    ClientId   = $true
                    Thumbprint = $true
                    Tenant     = $true
                }
                ParameterSets = @(
                    [pscustomobject] @{ Parameters = @(
                            [pscustomobject] @{ Name = 'Url' }
                            [pscustomobject] @{ Name = 'ClientId' }
                        ) },
                    [pscustomobject] @{ Parameters = @(
                            [pscustomobject] @{ Name = 'Thumbprint' }
                            [pscustomobject] @{ Name = 'Tenant' }
                        ) }
                )
            }
        }

        { Test-SharePointPnPProvider -ModuleName PnPContractFixture } |
            Should -Throw '*does not expose a parameter set supporting*'
    }

    It 'fails source import when a conflicting provider is already loaded' {
        $ConflictingModule = New-Module -Name SharePointPnPPowerShellOnline -ScriptBlock { }
        Import-Module $ConflictingModule -Global

        try {
            { Import-Module "$PSScriptRoot/../SharePointEssentials.psd1" -Force -ErrorAction Stop } |
                Should -Throw '*already loaded*'
        } finally {
            Remove-Module SharePointPnPPowerShellOnline -Force -ErrorAction SilentlyContinue
        }
    }
}
