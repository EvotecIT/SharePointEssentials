﻿Function Remove-FilesFromSharePoint {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Array] $Source,
        [Parameter(Mandatory)] [string] $SiteURL,
        [Parameter(Mandatory)] [string] $SourceFolderPath,
        [Parameter(Mandatory)] [string] $TargetLibraryName,
        $TargetFolder
    )

    # Get all files on SharePoint Online
    $TargetFiles = Get-PnPListItem -List $TargetLibraryName -PageSize 2000

    $Target = foreach ($File in $TargetFiles) {
        $Date = $File.FieldValues.Modified.ToUniversalTime()
        [PSCustomObject] @{
            FullName      = $File.FieldValues.FileRef.Replace($TargetFolder.ServerRelativeURL, $SourceFolderPath).Replace("/", "\")
            PSIsContainer = $File.FileSystemObjectType -eq "Folder"
            TargetItemURL = $File.FieldValues.FileRef.Replace($Web.ServerRelativeUrl, [string]::Empty)
            LastUpdated   = [datetime]::new($Date.Year, $Date.Month, $Date.Day, $Date.Hour, $Date.Minute, $Date.Second)
        }
    }

    # Compare source/target and remove files that are not in the source
    # Ignore LastUpdated as it doesn't matter - the file either exists or it doesn't
    $FilesDiff = Compare-Object -ReferenceObject $Source -DifferenceObject $Target -Property FullName, PSIsContainer, TargetItemURL #, LastUpdated
    [Array] $TargetDelta = foreach ($File in $FilesDiff) {
        If ($File.SideIndicator -eq "=>") {
            $File
        }
    }

    If ($TargetDelta.Count -gt 0) {
        Write-Color -Text "[information] ", "Found ", "$($TargetDelta.Count)", " differences in the Target. Removal is required." -Color Yellow, White, Yellow, White, Yellow, Red

        $Counter = 1
        foreach ($TargetFile in $TargetDelta | Sort-Object TargetItemURL -Descending) {
            If ($TargetFile.PSIsContainer) {
                $Folder = Get-PnPFolder -Url $TargetFile.TargetItemURL -ErrorAction SilentlyContinue
                If ($Null -ne $Folder -and $Folder.Items.Count -eq 0) {
                    If ($PSCmdlet.ShouldProcess($TargetFile.TargetItemURL, "Removing folder from SharePoint")) {
                        Write-Color -Text "[-] ", "Removing Item ", "($($Counter) of $($TargetDelta.Count)) ", "'$($TargetFile.TargetItemURL)'" -Color Red, White, Yellow, Red
                        $null = $Folder.Recycle()
                        Invoke-PnPQuery
                    }
                } else {
                    Write-Color -Text "[!] ", "Folder ", "'$($TargetFile.TargetItemURL)'", " is not empty. Skipping." -Color Yellow, White, Yellow, Red
                }
            } else {
                $File = Get-PnPFile -Url $TargetFile.TargetItemURL -ErrorAction SilentlyContinue
                If ($Null -ne $File) {
                    If ($PSCmdlet.ShouldProcess($TargetFile.TargetItemURL, "Removing file from SharePoint")) {
                        Write-Color -Text "[-] ", "Removing Item ", "($($Counter) of $($TargetDelta.Count)) ", "'$($TargetFile.TargetItemURL)'" -Color Red, White, Yellow, Red
                        Remove-PnPFile -SiteRelativeUrl $TargetFile.TargetItemURL -Force
                    }
                }
            }
            $Counter++
        }
    }
}