function Get-FilesLocal {
    [CmdletBinding()]
    param(
        [Array] $SourceFileList,
        [string] $SourceFolderPath,
        [string] $Include,
        [string] $TargetFolderSiteRelativeURL
    )
    if ($SourceFileList) {
        $SourceDirectoryPath = $null
        # Lets get all files from the source folder
        [Array] $SourceItems = foreach ($Item in $SourceFileList) {
            # We need to find the shortest path to the files
            $TempSourceDirectoryPath = [io.path]::GetDirectoryName($Item)
            if ($null -eq $SourceDirectoryPath) {
                $SourceDirectoryPath = $TempSourceDirectoryPath
            } elseif ($SourceDirectoryPath -ne $TempSourceDirectoryPath) {
                if ($TempSourceDirectoryPath.Length -lt $SourceDirectoryPath.Length) {
                    $SourceDirectoryPath = $TempSourceDirectoryPath
                }
            }
            try {
                Get-Item -Path $Item -ErrorAction Stop
                Get-Item -Path $TempSourceDirectoryPath -ErrorAction Stop
            } catch {
                Write-Color -Text "[e] ", "Unable to get file '$Item' from the source file list. Make sure the path is correct and you have permissions to access it." -Color Yellow, Red
                Write-Color -Text "[e] ", "Error: ", $_.Exception.Message -Color Yellow, Red
                return
            }
        }
        if ($SourceItems.Count -eq 0) {
            Write-Color -Text "[e] ", "No files found in the source file list. Please make sure the list is not empty." -Color Yellow, Red
            return
        }
    } else {
        $SourceDirectoryPath = $SourceFolderPath
        # Lets get all files from the source folder
        $getChildItemSplat = @{
            Path    = $SourceFolderPath
            Recurse = $true
        }
        try {
            $SourceItems = Get-ChildItem @getChildItemSplat -ErrorAction Stop
            if ($Include) {
                $SourceItems = $SourceItems.Where({ $_.PSIsContainer -or $_.Name -like $Include })
            }
        } catch {
            Write-Color -Text "[e] ", "Unable to get files from the source folder. Make sure the path is correct and you have permissions to access it." -Color Yellow, Red
            Write-Color -Text "[e] ", "Error: ", $_.Exception.Message -Color Yellow, Red
            return
        }
    }
    $SourceFilesCount = 0
    $SourceDirectoryCount = 0
    [Array] $Source = foreach ($File in $SourceItems | Sort-Object -Unique -Property FullName) {
        # Dates are not the same as in SharePoint, so we need to convert them to UTC
        # And make sure we don't add miliseconds, as it will cause issues with comparison
        $Date = $File.LastWriteTimeUtc
        [PSCustomObject] @{
            FullName      = $File.FullName
            PSIsContainer = $File.PSIsContainer
            TargetItemURL = $File.FullName.Replace($SourceDirectoryPath, $TargetFolderSiteRelativeURL).Replace("\", "/")
            LastUpdated   = [datetime]::new($Date.Year, $Date.Month, $Date.Day, $Date.Hour, $Date.Minute, $Date.Second)
        }
        if (-not $File.PSIsContainer) {
            $SourceFilesCount++
        } else {
            $SourceDirectoryCount++
        }
    }
    [ordered] @{
        Source               = $Source
        SourceFilesCount     = $SourceFilesCount
        SourceDirectoryCount = $SourceDirectoryCount
        SourceDirectoryPath  = $SourceDirectoryPath
    }
}