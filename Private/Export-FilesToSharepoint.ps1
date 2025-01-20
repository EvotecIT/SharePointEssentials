Function Export-FilesToSharePoint {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)][Array] $Source,
        [Parameter(Mandatory)][string] $SourceFolderPath,
        [Parameter(Mandatory)][string] $TargetLibraryName,
        [Parameter(Mandatory)][Microsoft.SharePoint.Client.ClientObject] $TargetFolder
    )
    # Get all files from SharePoint Online
    $TargetFilesCount = 0
    $TargetDirectoryCount = 0
    $TargetFiles = Get-PnPListItem -List $TargetLibraryName -PageSize 2000
    $Target = foreach ($File in $TargetFiles) {
        # Dates are not the same as in SharePoint, so we need to convert them to UTC
        # And make sure we don't add miliseconds
        $Date = $File.FieldValues.Modified.ToUniversalTime()
        if ($File.FieldValues.FileRef -like "$($TargetFolder.ServerRelativeUrl)/*") {
            [PSCustomObject] @{
                FullName      = $File.FieldValues.FileRef.Replace($TargetFolder.ServerRelativeURL, $SourceFolderPath).Replace("/", "\")
                PSIsContainer = $File.FileSystemObjectType -eq "Folder"
                TargetItemURL = $File.FieldValues.FileRef.Replace($Web.ServerRelativeUrl, [string]::Empty)
                LastUpdated   = [datetime]::new($Date.Year, $Date.Month, $Date.Day, $Date.Hour, $Date.Minute, $Date.Second)
            }
            if (-not $File.FileSystemObjectType -eq "Folder") {
                $TargetFilesCount++
            } else {
                $TargetDirectoryCount++
            }
            #Write-Color -Text "[i] ", "File ", "'$($File.FieldValues.FileRef)'", " is in the target folder." -Color Yellow, White, Yellow
        } else {
            #Write-Color -Text "[!] ", "File ", "'$($File.FieldValues.FileRef)'", " is not in the target folder. Skipping." -Color Yellow, White, Yellow, Red
        }
    }

    Write-Color -Text "[i] ", "Total items (files) in target: ", "$($TargetFilesCount)" -Color Yellow, White, Green
    Write-Color -Text "[i] ", "Total items (folders) in target: ", "$($TargetDirectoryCount)" -Color Yellow, White, Green

    # Compare source/target and add files that are not in the target
    $CacheFilesTarget = [ordered] @{}
    $ActionsToDo = [ordered] @{
        "Add"     = [System.Collections.Generic.List[Object]]::new()
        "Nothing" = [System.Collections.Generic.List[Object]]::new()
        "Update"  = [System.Collections.Generic.List[Object]]::new()
        "Remove"  = [System.Collections.Generic.List[Object]]::new()
    }
    foreach ($File in $Target) {
        $CacheFilesTarget[$File.FullName] = $File
    }

    foreach ($File in $Source) {
        if ($CacheFilesTarget[$File.FullName]) {
            if (-not $File.PSIsContainer) {
                $TargetFile = $CacheFilesTarget[$File.FullName]
                if ($Source.PSIsContainer -eq $TargetFile.PSiSContainer -and $Source.TargetItemURL -eq $TargetFile.TargetItemURL -and $Source.LastUpdated -eq $TargetFile.LastUpdated) {
                    $ActionsToDo["Nothing"].Add($File)
                } elseif ($Source.PSIsContainer -eq $TargetFile.PSiSContainer -and $Source.TargetItemURL -eq $TargetFile.TargetItemURL -and $Source.LastUpdated -ne $TargetFile.LastUpdated) {
                    #Write-Color -Text "[>] Update ", $($File.FullName), " is required. Dates are different: ", "$($File.LastUpdated)", " vs ", "$($TargetFile.LastUpdated)" -Color Yellow, White, Yellow, White, Yellow, Red
                    $ActionsToDo["Update"].Add($File)
                } elseif ($Source.PSIsContainer -ne $TargetFile.PSiSContainer -or $Source.TargetItemURL -ne $TargetFile.TargetItemURL) {
                    # not really needed here
                    Write-Color -Text "This should never happen 1" -Color Red
                } else {
                    # this should never happen right?
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
        # Calculate Target Folder URL for the file
        $TargetFolderURL = (Split-Path $SourceFile.TargetItemURL -Parent).Replace("\", "/")
        If ($TargetFolderURL.StartsWith("/")) { $TargetFolderURL = $TargetFolderURL.Remove(0, 1) }
        $ItemName = Split-Path $SourceFile.FullName -Leaf
        # Replace Invalid Characters
        $ItemName = [RegEx]::Replace($ItemName, "[{0}]" -f ([RegEx]::Escape([String]'\*:<>?/\|')), '_')

        If ($SourceFile.PSIsContainer) {

        } else {
            If ($PSCmdlet.ShouldProcess($TargetFolderURL, "Adding new file '$($SourceFile.FullName)' to SharePoint folder")) {
                Write-Color -Text "[+] ", "Adding new file ", "($($Counter) of $($ActionsToDo["Add"].Count)) ", "'$($SourceFile.FullName)'", " to Folder ", "'$TargetFolderURL'" -Color Yellow, White, Yellow, White, Yellow, Cyan
                try {
                    $null = Add-PnPFile -Path $SourceFile.FullName -Folder $TargetFolderURL -Values @{"Modified" = $SourceFile.LastUpdated.ToLocalTime() } -ErrorAction Stop
                } catch {
                    Write-Color -Text "[!] ", "Error adding file ", "'$($SourceFile.FullName)'", " to Folder ", "'$TargetFolderURL'", ". Error: ", $_.Exception.Message -Color Yellow, White, Yellow, White, Yellow, Red
                }
            }
        }
        $Counter++
    }

    $Counter = 1
    foreach ($SourceFile in $ActionsToDo["Update"] | Sort-Object TargetItemURL) {
        # Calculate Target Folder URL for the file
        $TargetFolderURL = (Split-Path $SourceFile.TargetItemURL -Parent).Replace("\", "/")
        If ($TargetFolderURL.StartsWith("/")) { $TargetFolderURL = $TargetFolderURL.Remove(0, 1) }
        $ItemName = Split-Path $SourceFile.FullName -Leaf
        # Replace Invalid Characters
        $ItemName = [RegEx]::Replace($ItemName, "[{0}]" -f ([RegEx]::Escape([String]'\*:<>?/\|')), '_')

        If ($SourceFile.PSIsContainer) {

        } else {
            If ($PSCmdlet.ShouldProcess($TargetFolderURL, "Updating file '$($SourceFile.FullName)' to SharePoint folder")) {
                Write-Color -Text "[+] ", "Updating file ", "($($Counter) of $($ActionsToDo["Update"].Count)) ", "'$($SourceFile.FullName)'", " to Folder ", "'$TargetFolderURL'" -Color Yellow, White, Yellow, White, Yellow, Cyan
                try {
                    $null = Add-PnPFile -Path $SourceFile.FullName -Folder $TargetFolderURL -Values @{"Modified" = $SourceFile.LastUpdated.ToLocalTime() } -ErrorAction Stop
                } catch {
                    Write-Color -Text "[!] ", "Error updating file ", "'$($SourceFile.FullName)'", " to Folder ", "'$TargetFolderURL'", ". Error: ", $_.Exception.Message -Color Yellow, White, Yellow, White, Yellow, Red
                }
            }
        }
        $Counter++
    }
}