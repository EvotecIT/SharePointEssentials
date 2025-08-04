@{
    AliasesToExport      = @()
    Author               = 'Przemyslaw Klys'
    CmdletsToExport      = @()
    CompanyName          = 'Evotec'
    CompatiblePSEditions = @('Desktop', 'Core')
    Copyright            = '(c) 2011 - 2025 Przemyslaw Klys @ Evotec. All rights reserved.'
    Description          = 'Project to help with SharePoint synchronnization of files'
    FunctionsToExport    = 'Sync-FilesToSharePoint', 'Sync-FilesFromSharePoint'
    GUID                 = 'e9e31850-6388-4aa5-8e2b-897f6ac1866a'
    ModuleVersion        = '1.0.9'
    PowerShellVersion    = '5.1'
    PrivateData          = @{
        PSData = @{
            ExternalModuleDependencies = @('Microsoft.PowerShell.Management', 'Microsoft.PowerShell.Utility')
            Tags                       = @('SharePoint', 'SPO', 'Windows')
        }
    }
    RequiredModules      = @(@{
            Guid          = '0b0ba5c5-ec85-4c2b-a718-874e55a8bc3f'
            ModuleName    = 'PSWriteColor'
            ModuleVersion = '1.0.1'
        }, @{
            Guid          = 'ee272aa8-baaa-4edf-9f45-b6d6f7d844fe'
            ModuleName    = 'PSSharedGoods'
            ModuleVersion = '0.0.303'
        }, @{
            Guid          = '0b0430ce-d799-4f3b-a565-f0dca1f31e17'
            ModuleName    = 'Pnp.PowerShell'
            ModuleVersion = '1.12.0'
        }, 'Microsoft.PowerShell.Management', 'Microsoft.PowerShell.Utility')
    RootModule           = 'SharePointEssentials.psm1'
}