Function Export-FilesFromSharePoint {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)][Array] $Source,
        [Parameter(Mandatory)][Array] $Target,
        [Parameter(Mandatory)][string] $TargetFolderPath
    )

    $CacheFilesTarget = [ordered] @{}
    $ActionsToDo = [ordered] @{
        "Add"     = [System.Collections.Generic.List[Object]]::new()
        "Nothing" = [System.Collections.Generic.List[Object]]::new()
        "Update"  = [System.Collections.Generic.List[Object]]::new()
    }
    foreach ($File in $Target) {
        $CacheFilesTarget[$File.FullName] = $File
    }

    foreach ($File in $Source) {
        if ($CacheFilesTarget[$File.FullName]) {
            if (-not $File.PSIsContainer) {
                $TargetFile = $CacheFilesTarget[$File.FullName]
                if ($File.PSIsContainer -eq $TargetFile.PSiSContainer -and $File.TargetItemURL -eq $TargetFile.TargetItemURL -and $File.LastUpdated -eq $TargetFile.LastUpdated) {
                    $ActionsToDo["Nothing"].Add($File)
                } elseif ($File.PSIsContainer -eq $TargetFile.PSiSContainer -and $File.TargetItemURL -eq $TargetFile.TargetItemURL -and $File.LastUpdated -ne $TargetFile.LastUpdated) {
                    $ActionsToDo["Update"].Add($File)
                } elseif ($File.PSIsContainer -ne $TargetFile.PSiSContainer -or $File.TargetItemURL -ne $TargetFile.TargetItemURL) {
                    Write-Color -Text "This should never happen 1" -Color Red
                } else {
                    Write-Color -Text "This should never happen 2" -Color Red
                }
            }
        } else {
            $ActionsToDo["Add"].Add($File)
        }
    }

    Write-Color -Text "[i] ", "Total items to update: ", "$($ActionsToDo['Update'].Count)" -Color Yellow, White, Green
    Write-Color -Text "[i] ", "Total items to add: ", "$($ActionsToDo['Add'].Count)" -Color Yellow, White, Green
    Write-Color -Text "[i] ", "Total items matching: ", "$($ActionsToDo['Nothing'].Count)" -Color Yellow, White, Green

    $Counter = 1
    foreach ($SourceFile in $ActionsToDo["Add"] | Sort-Object TargetItemURL) {
        $LocalDirectory = Split-Path $SourceFile.FullName -Parent
        if ($SourceFile.PSIsContainer) {
            if ($PSCmdlet.ShouldProcess($SourceFile.FullName, "Creating folder")) {
                try {
                    New-Item -ItemType Directory -Path $SourceFile.FullName -Force | Out-Null
                } catch {
                    Write-Color -Text "[!] ", "Error creating folder ", "'$($SourceFile.FullName)'", ". Error: ", $_.Exception.Message -Color Yellow, White, Yellow, Red
                }
            }
        } else {
            if ($PSCmdlet.ShouldProcess($SourceFile.FullName, "Downloading new file from SharePoint")) {
                try {
                    New-Item -ItemType Directory -Path $LocalDirectory -Force | Out-Null
                    $null = Get-PnPFile -Url $SourceFile.TargetItemURL -Path $LocalDirectory -FileName (Split-Path $SourceFile.FullName -Leaf) -AsFile -Force -ErrorAction Stop
                    (Get-Item -LiteralPath $SourceFile.FullName).LastWriteTime = $SourceFile.LastUpdated.ToLocalTime()
                    Write-Color -Text "[+] ", "Downloading new file ", "($Counter of $($ActionsToDo['Add'].Count)) ", "'$($SourceFile.FullName)'" -Color Yellow, White, Yellow, White, Yellow, Cyan
                } catch {
                    Write-Color -Text "[!] ", "Error downloading file ", "'$($SourceFile.FullName)'", ". Error: ", $_.Exception.Message -Color Yellow, White, Yellow, Red
                }
            }
        }
        $Counter++
    }

    $Counter = 1
    foreach ($SourceFile in $ActionsToDo["Update"] | Sort-Object TargetItemURL) {
        $LocalDirectory = Split-Path $SourceFile.FullName -Parent
        if ($SourceFile.PSIsContainer) {
            # folders - nothing to update
        } else {
            if ($PSCmdlet.ShouldProcess($SourceFile.FullName, "Updating file from SharePoint")) {
                try {
                    $null = Get-PnPFile -Url $SourceFile.TargetItemURL -Path $LocalDirectory -FileName (Split-Path $SourceFile.FullName -Leaf) -AsFile -Force -ErrorAction Stop
                    (Get-Item -LiteralPath $SourceFile.FullName).LastWriteTime = $SourceFile.LastUpdated.ToLocalTime()
                    Write-Color -Text "[+] ", "Updating file ", "($Counter of $($ActionsToDo['Update'].Count)) ", "'$($SourceFile.FullName)'" -Color Yellow, White, Yellow, White, Yellow, Cyan
                } catch {
                    Write-Color -Text "[!] ", "Error updating file ", "'$($SourceFile.FullName)'", ". Error: ", $_.Exception.Message -Color Yellow, White, Yellow, Red
                }
            }
        }
        $Counter++
    }
}

