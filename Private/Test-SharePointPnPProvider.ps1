function Test-SharePointPnPProvider {
    <#
    .SYNOPSIS
    Verifies that a loaded PnP provider supports the SharePointEssentials contract.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ModuleName
    )

    $CommandContract = [ordered] @{
        'Connect-PnPOnline' = @('Url', 'ClientId', 'Thumbprint', 'Tenant')
        'Get-PnPWeb'        = @()
        'Get-PnPList'       = @('Identity', 'Includes')
        'Get-PnPListItem'   = @('List', 'PageSize')
        'Get-PnPFile'       = @('Url', 'Path', 'FileName', 'AsFile', 'Force')
        'Get-PnPFolderItem' = @('FolderSiteRelativeUrl', 'ItemType', 'Recursive')
        'Get-PnPFolder'     = @('Url')
        'Add-PnPFile'       = @('Path', 'Folder', 'Values')
        'Remove-PnPFile'    = @('SiteRelativeUrl', 'Force')
        'Invoke-PnPQuery'   = @()
    }

    foreach ($CommandName in $CommandContract.Keys) {
        $Command = Get-Command -Name $CommandName -ErrorAction SilentlyContinue |
            Where-Object { $_.ModuleName -eq $ModuleName } |
            Select-Object -First 1

        if (-not $Command) {
            throw "PnP provider '$ModuleName' does not expose required command '$CommandName'."
        }

        $RequiredParameters = $CommandContract[$CommandName]
        if ($RequiredParameters.Count -eq 0) {
            continue
        }

        $CompatibleParameterSet = $Command.ParameterSets | Where-Object {
            $ParameterNames = $_.Parameters.Name
            @($RequiredParameters | Where-Object { $ParameterNames -notcontains $_ }).Count -eq 0
        } | Select-Object -First 1

        if (-not $CompatibleParameterSet) {
            throw "PnP provider '$ModuleName' command '$CommandName' does not expose a parameter set supporting: $($RequiredParameters -join ', ')."
        }
    }

    $true
}
