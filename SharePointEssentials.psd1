@{
    AliasesToExport      = @()
    Author               = 'Przemyslaw Klys'
    CmdletsToExport      = @()
    CompanyName          = 'Evotec'
    CompatiblePSEditions = @('Desktop', 'Core')
    Copyright            = '(c) 2011 - 2023 Przemyslaw Klys @ Evotec. All rights reserved.'
    Description          = 'Simple project SharePointEssentials'
    FunctionsToExport    = 'Sync-FilesToSharePoint'
    GUID                 = 'e9e31850-6388-4aa5-8e2b-897f6ac1866a'
    ModuleVersion        = '1.0.0'
    PowerShellVersion    = '5.1'
    PrivateData          = @{
        PSData = @{
            ExternalModuleDependencies = @('Microsoft.PowerShell.Management', 'Microsoft.PowerShell.Utility')
            Tags                       = @('SharePoint', 'SPO', 'Windows')
        }
    }
    RequiredModules      = @(@{
            Guid          = '0b0430ce-d799-4f3b-a565-f0dca1f31e17'
            ModuleName    = 'PnP.PowerShell'
            ModuleVersion = '2.2.0'
        }, @{
            Guid          = '0b0ba5c5-ec85-4c2b-a718-874e55a8bc3f'
            ModuleName    = 'PSWriteColor'
            ModuleVersion = '1.0.1'
        }, 'Microsoft.PowerShell.Management', 'Microsoft.PowerShell.Utility')
    RootModule           = 'SharePointEssentials.psm1'
}