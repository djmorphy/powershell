# Folder path
$folder = "c:\!TMP\powershell\"

# Kizárandó kiterjesztések tömbje
$excludeExtensions = @("ps1", "docx")

# Dátum struktúrájú fájlok kiválasztása
$filesWithDate = Get-ChildItem -Path $folder -Exclude $excludeExtensions | Where-Object { $_.BaseName -match '(\d{4}[ _]\d{2}[ _]\d{2}[ _]\d{2}[ _]\d{2}|\d{14})' }

# Sorting by creation date and selecting the last N files
$numOfFilesToMove = 2  # Ezt módosíthatod a kívánt számra
$newestFiles = $filesWithDate | Sort-Object CreationTime -Descending | Select-Object -First $numOfFilesToMove

# Output folder path
$folder = "c:\!TMP\powershell\output\"

# Biztosítjuk, hogy az output mappa létezik, létrehozzuk, ha nem
if (-not (Test-Path -Path $outputFolderPath -PathType Container)) {
    New-Item -Path $outputFolderPath -ItemType Directory
}

# Az új fájlokat áthelyezzük az output mappába és egy változóba helyezzük
$movedFiles = foreach ($newestFile in $newestFiles) {
    $destinationPath = Join-Path -Path $outputFolderPath -ChildPath $newestFile.Name
    Move-Item -Path $newestFile.FullName -Destination $destinationPath -Force
    Write-Output "A legújabb fájl áthelyezve ide: $destinationPath"
    $newestFile.FullName
}

# Kimeneti kódolás beállítása UTF-8-ra
$OutputEncoding = [System.Text.Encoding]::UTF8

# Változó tartalmának megtekintése
$movedFiles
