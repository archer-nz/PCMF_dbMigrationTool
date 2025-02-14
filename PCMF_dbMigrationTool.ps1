# PaperCut MF Database Migration Tool

<#
    .SYNOPSIS
    Tool for updating PaperCut MF databases with versions prior to v23.0.0 for migration to later versions

    .DESCRIPTION
    Originally lodged with PaperCut as ticket 1294438 on 22/03/2024
    When using "db-tools import-db" command line utility to import PCMF database exports from v22.1.5 and eariler to v23.0.0+ the following error occurs:
        Error occured running db-tools, command: import-db.
        Liquidbase changelog list not found: C\Users\%username%\AppData\Local\Temp\changelogsXXXXXXXXXXXXXXXXXXX\db.changelog-list.yaml

    This error occurs simply due to db.changelog-master.yaml (v22.1.5 and eariler) being renamed to db.changelog-list.yaml in v23.0.0+
    Because of this, "db-tools import-db" now looks for db.changelog-list.yaml rather than db.changelog-master.yaml, causing a file not found error.

    This script simply checks the app-version-major property in db-data.xml file for versions prior to v23.
    If the version is eariler than v23 it updates updates the filename of db.changelog-master.yaml to db.changelog-list.yaml

    .LINK
    https://papercut.com/support/known-issues/?id=PO-2009#mf
#>

Write-Host "
#########################################
## PaperCut MF Database Migration Tool ##
#########################################

Tool for updating PaperCut MF databases with versions prior to v23.0.0 for migration to later versions
"

Add-Type -assembly "system.io.compression.filesystem"

# Ask user for file path
Add-Type -AssemblyName System.Windows.Forms

$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
$FileBrowser.Filter = "ZIP Files (*.zip)|*.zip"
$FileBrowser.Title = "Select a PCMF Database export to update"

if ($FileBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $exportPath = $FileBrowser.FileName
}
else {
    Write-Host "No file selected. Exiting..."
    exit
}

Write-Host "Selected PCMF Export:               $exportPath
"

# DB file inside the ZIP archive
$dbFile = "db-data.xml"

# Load the zip archive using System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($exportPath)

# Find the XML file within the zip
$xmlEntry = $zip.Entries | Where-Object { $_.FullName -eq $dbFile } | Select-Object -First 1

# Open the XML file stream
$reader = New-Object System.IO.StreamReader($xmlEntry.Open())

# Read the lines
$lineOfNumber = 2
$firstLines = @()
for ($i = 0; $i -lt $lineOfNumber; $i++) {
    if ($reader.EndOfStream) { break }
    $firstLines += $reader.ReadLine()
}

$reader.Close()
$zip.Dispose()

# Extract the app-version-major value using regex
$AppVersionMajor = ($firstLines -match 'app-version-major=\"(\d+)\"')[0] -replace '.*app-version-major=\"(\d+)\".*', '$1'

# Output the value to a variable
# $AppVersionMajor = $versionMajor

# Display the extracted value
Write-Output "Export Contains DB for version:   $AppVersionMajor
"

# Check PCMF DB version 
if ($AppVersionMajor -lt 23) {
    # Add-Type -AssemblyName System.IO.Compression.FileSystem

    # $exportPath = "C:\Users\au101002\OneDrive - FUJIFILM\Software\0-Coding_Projects\PCMF_DatabaseMigrationTool\export-2025-02-14T10-35-05.zip"
    $oldFileName = "changelogs/db.changelog-master.yaml"
    $newFileName = "changelogs/db.changelog-list.yaml"

    $zip = [System.IO.Compression.ZipFile]::Open($exportPath, 'Update')

    $entry = $zip.Entries | Where-Object { $_.FullName -eq $oldFileName }

    if ($entry) {
        $tempStream = New-Object System.IO.MemoryStream
        $entryStream = $entry.Open()
        $entryStream.CopyTo($tempStream)
        $entryStream.Close()   # Close the stream before deleting the entry
        $entry.Delete()        # Now it's safe to delete

        $tempStream.Seek(0, [System.IO.SeekOrigin]::Begin)
        $newEntry = $zip.CreateEntry($newFileName)
        $newStream = $newEntry.Open()
        $tempStream.CopyTo($newStream)

        $newStream.Close()
        $tempStream.Dispose()
    }

    $zip.Dispose()

Write-Output "
Update complete
db.changelog-master.yaml has been updated to db.changelog-list.yaml.
PCMF DB Export is now ready to be imported to v23+
Please note, this file is nolonger able to be imported to v22 and older"
}

else {
    Write-Output "DB version greater than v23, no change required, exiting"
}