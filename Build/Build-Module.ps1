<#
.SYNOPSIS
Builds or publishes SharePointEssentials through PSPublishModule.
.PARAMETER ConfigurationGateMode
Selects manifest refresh, local build, or publication.
.PARAMETER SignModule
Signs release files with the configured Evotec certificate.
.PARAMETER PowerShellGalleryApiKeyPath
Path to the Gallery publication credential.
.PARAMETER GitHubApiKeyPath
Path to the GitHub publication credential.
#>
param(
    [ValidateSet('Manifest', 'Build', 'Publish')]
    [string] $ConfigurationGateMode = 'Build',
    [bool] $SignModule = $true,
    [string] $PowerShellGalleryApiKeyPath = 'C:\Support\Important\PowerShellGalleryAPI.txt',
    [string] $GitHubApiKeyPath = 'C:\Support\Important\GitHubAPI.txt'
)
Import-Module PSPublishModule -ErrorAction Stop
Invoke-ModuleBuild -ModuleName 'SharePointEssentials' {
    # Usual defaults as per standard module
    $Manifest = [ordered] @{
        ModuleVersion        = '1.0.X'
        CompatiblePSEditions = @('Desktop', 'Core')
        GUID                 = 'e9e31850-6388-4aa5-8e2b-897f6ac1866a'
        Author               = 'Przemyslaw Klys'
        CompanyName          = 'Evotec'
        Copyright            = "(c) 2011 - $((Get-Date).Year) Przemyslaw Klys @ Evotec. All rights reserved."
        Description          = 'Project to help with SharePoint synchronnization of files'
        PowerShellVersion    = '5.1'
        Tags                 = @('SharePoint', 'SPO', 'Windows')
    }
    New-ConfigurationManifest @Manifest

    # Keep public dependency minimums deterministic. Do not resolve machine-local four-part builds.
    New-ConfigurationModule -Type RequiredModule -Name 'PSWriteColor' -Guid 'Auto' -Version '1.0.1'
    New-ConfigurationModule -Type RequiredModule -Name 'PSSharedGoods' -Guid 'Auto' -Version '0.0.303'

    # Add external module dependencies, using loop for simplicity
    New-ConfigurationModule -Type ExternalModule -Name @(
        'PnP.PowerShell'
        'Microsoft.PowerShell.Management'
        'Microsoft.PowerShell.Utility'
    )

    New-ConfigurationModule -Type ApprovedModule -Name 'PSSharedGoods', 'PSWriteColor', 'Connectimo', 'PSUnifi', 'PSWebToolbox', 'PSMyPassword'

    $ConfigurationFormat = [ordered] @{
        RemoveComments                              = $false

        PlaceOpenBraceEnable                        = $true
        PlaceOpenBraceOnSameLine                    = $true
        PlaceOpenBraceNewLineAfter                  = $true
        PlaceOpenBraceIgnoreOneLineBlock            = $false

        PlaceCloseBraceEnable                       = $true
        PlaceCloseBraceNewLineAfter                 = $true
        PlaceCloseBraceIgnoreOneLineBlock           = $false
        PlaceCloseBraceNoEmptyLineBefore            = $true

        UseConsistentIndentationEnable              = $true
        UseConsistentIndentationKind                = 'space'
        UseConsistentIndentationPipelineIndentation = 'IncreaseIndentationAfterEveryPipeline'
        UseConsistentIndentationIndentationSize     = 4

        UseConsistentWhitespaceEnable               = $true
        UseConsistentWhitespaceCheckInnerBrace      = $true
        UseConsistentWhitespaceCheckOpenBrace       = $true
        UseConsistentWhitespaceCheckOpenParen       = $true
        UseConsistentWhitespaceCheckOperator        = $true
        UseConsistentWhitespaceCheckPipe            = $true
        UseConsistentWhitespaceCheckSeparator       = $true

        AlignAssignmentStatementEnable              = $true
        AlignAssignmentStatementCheckHashtable      = $true

        UseCorrectCasingEnable                      = $true
    }
    # format PSD1 and PSM1 files when merging into a single file
    # enable formatting is not required as Configuration is provided
    New-ConfigurationFormat -ApplyTo 'OnMergePSM1', 'OnMergePSD1' -Sort None @ConfigurationFormat
    # format PSD1 and PSM1 files within the module
    # enable formatting is required to make sure that formatting is applied (with default settings)
    New-ConfigurationFormat -ApplyTo 'DefaultPSD1', 'DefaultPSM1' -EnableFormatting -Sort None
    # when creating PSD1 use special style without comments and with only required parameters
    New-ConfigurationFormat -ApplyTo 'DefaultPSD1', 'OnMergePSD1' -PSD1Style 'Minimal'
    # configuration for documentation, at the same time it enables documentation processing
    New-ConfigurationDocumentation -Enable:$false -PathReadme 'Docs\Readme.md' -Path 'Docs'

    New-ConfigurationImportModule -ImportSelf

    New-ConfigurationBuild -Enable:$true -SignModule:$SignModule -MergeModuleOnBuild -MergeFunctionsFromApprovedModules -CertificateThumbprint '92e95fb58effa6a4a75e77a33cdd6bfe6dd30f1a'

    New-ConfigurationArtefact -Type Unpacked -Enable -Path "$PSScriptRoot\..\Artefacts\Unpacked" -AddRequiredModules -RequiredModulesSource Download -RequiredModulesRepository PSGallery
    New-ConfigurationArtefact -Type Packed -Enable -Path "$PSScriptRoot\..\Artefacts\Packed" -ArtefactName '<ModuleName>.v<ModuleVersion>.zip'

    # options for publishing to github/psgallery
    New-ConfigurationPublish -Type PowerShellGallery -FilePath $PowerShellGalleryApiKeyPath -Enabled:$false
    New-ConfigurationPublish -Type GitHub -FilePath $GitHubApiKeyPath -UserName 'EvotecIT' -RepositoryName 'SharePointEssentials' -Enabled:$false
    New-ConfigurationGate -Mode $ConfigurationGateMode
} -ExitCode -IncludeAll @()
