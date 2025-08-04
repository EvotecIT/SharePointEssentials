Function Remove-FilesFromLocal {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Array] $Source,
        [Parameter(Mandatory)][Array] $Target,
        [string[]] $ExcludeFromRemoval
    )

    if ($Target.Count -eq 0) {
        Write-Color -Text "[i] ", "No items found in the Target. Skipping removal." -Color Yellow, White, Green
        return
    }

    if ($Source.Count -gt 0) {
        $FilesDiff = Compare-Object -ReferenceObject $Source -DifferenceObject $Target -Property FullName, PSIsContainer, TargetItemURL
        [Array] $TargetDelta = foreach ($File in $FilesDiff) {
            if ($File.SideIndicator -eq "=>") { $File }
        }
    } else {
        $TargetDelta = $Target
    }

    if ($TargetDelta.Count -gt 0) {
        Write-Color -Text "[information] ", "Found ", "$($TargetDelta.Count)", " differences in the Target. Removal is required." -Color Yellow, White, Yellow, White, Yellow, Red

        $Counter = 1
        :topLoop foreach ($TargetFile in $TargetDelta | Sort-Object TargetItemURL -Descending) {
            if ($TargetFile.PSIsContainer) {
                if (Test-Path -LiteralPath $TargetFile.FullName -PathType Container) {
                    if ($ExcludeFromRemoval) {
                        foreach ($Exclude in $ExcludeFromRemoval) {
                            if ($TargetFile.TargetItemURL -like $Exclude) {
                                Write-Color -Text "[!] ", "Folder ", "'$($TargetFile.TargetItemURL)'", " is excluded from removal." -Color Yellow, White, Yellow, Red
                                continue topLoop
                            }
                        }
                    }
                    if ((Get-ChildItem -LiteralPath $TargetFile.FullName -Force | Measure-Object).Count -eq 0) {
                        if ($PSCmdlet.ShouldProcess($TargetFile.FullName, "Removing folder from disk")) {
                            Write-Color -Text "[-] ", "Removing Item ", "($Counter of $($TargetDelta.Count)) ", "'$($TargetFile.TargetItemURL)'" -Color Red, White, Yellow, Red
                            try {
                                Remove-Item -LiteralPath $TargetFile.FullName -Force -ErrorAction Stop
                            } catch {
                                Write-Color -Text "[!] ", "Failed to remove folder ", "'$($TargetFile.TargetItemURL)'", ". Error: ", $_.Exception.Message -Color Yellow, White, Yellow, Red
                            }
                        }
                    } else {
                        Write-Color -Text "[!] ", "Folder ", "'$($TargetFile.TargetItemURL)'", " is not empty. Skipping." -Color Yellow, White, Yellow, Red
                    }
                }
            } else {
                if (Test-Path -LiteralPath $TargetFile.FullName) {
                    if ($ExcludeFromRemoval) {
                        foreach ($Exclude in $ExcludeFromRemoval) {
                            if ($TargetFile.TargetItemURL -like $Exclude) {
                                Write-Color -Text "[!] ", "File ", "'$($TargetFile.TargetItemURL)'", " is excluded from removal." -Color Yellow, White, Yellow, Red
                                continue topLoop
                            }
                        }
                    }
                    if ($PSCmdlet.ShouldProcess($TargetFile.FullName, "Removing file from disk")) {
                        Write-Color -Text "[-] ", "Removing Item ", "($Counter of $($TargetDelta.Count)) ", "'$($TargetFile.TargetItemURL)'" -Color Red, White, Yellow, Red
                        try {
                            Remove-Item -LiteralPath $TargetFile.FullName -Force -ErrorAction Stop
                        } catch {
                            Write-Color -Text "[!] ", "Failed to remove file ", "'$($TargetFile.TargetItemURL)'", ". Error: ", $_.Exception.Message -Color Yellow, White, Yellow, Red
                        }
                    }
                }
            }
            $Counter++
        }
    }
}

