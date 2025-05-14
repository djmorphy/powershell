# Kimeneti kódolás beállítása UTF-8-ra a speciális karakterek helyes megjelenítéséhez
$OutputEncoding = [System.Text.Encoding]::UTF8

# --- Konfiguráció ---
# Add meg itt a keresendő fájlkiterjesztéseket, vesszővel elválasztva, idézőjelek között.
# Például: @(".config", ".json", ".xml")
$TargetExtensions = @(
						".config", 
						".json", 
						".yml", 
						".py"
					)

# A főmappa elérési útja, amit ellenőrizni szeretnél
$TargetFolder = "c:\Users\DJMor\OneDrive\Dev\powershell\configChecker\testing\pingnoo-develop\" # Módosítsd ezt a saját elérési utadra!

# --- Logolási Konfiguráció ---
$EnableLogging = $true # $true a logolás bekapcsolásához, $false a kikapcsolásához
$LogOutputFolder = "C:\Temp\CheckerLogs" # Módosítsd ezt a logok mentési helyére! Figyelem: A szkript megpróbálja létrehozni, ha nem létezik.
# --- Konfiguráció vége ---

# Logolási változók inicializálása
$logFilePath = $null
$currentDateTimeForLog = Get-Date -Format "yyyyMMddHHmmss" # Globális időbélyeg a log fájlnévhez és bejegyzésekhez

# Logolás előkészítése
if ($EnableLogging) {
    if (-not (Test-Path $LogOutputFolder -PathType Container)) {
        Write-Warning "A megadott log mappa nem létezik: $LogOutputFolder. Megpróbálom létrehozni."
        try {
            New-Item -ItemType Directory -Path $LogOutputFolder -Force -ErrorAction Stop | Out-Null
            Write-Host "Log mappa sikeresen létrehozva: $LogOutputFolder"
        } catch {
            Write-Error "Nem sikerült létrehozni a log mappát: $LogOutputFolder. A logolás ki lesz kapcsolva erre a futtatásra."
            Write-Error "Hibaüzenet: $($_.Exception.Message)"
            $EnableLogging = $false # Hiba esetén kikapcsoljuk a logolást
        }
    }

    if ($EnableLogging) {
        # Log fájlnév generálása
        $targetFolderNamePart = (Split-Path -Path $TargetFolder -Leaf)
        # Ha a $TargetFolder gyökérmappa (pl. C:\), akkor a Split-Path -Leaf "C:"-t ad vissza.
        # Ha üres vagy csak whitespace lenne valamiért:
        if ([string]::IsNullOrWhiteSpace($targetFolderNamePart)) {
            # Próbálunk egy tisztább nevet generálni a teljes elérési útból
            $targetFolderNamePart = $TargetFolder -replace '[\\/:]', '-' # Csere ':' és '\' vagy '/' karakterekre '-'
            $targetFolderNamePart = ($targetFolderNamePart -split '-')[-1] # Utolsó elem a kötőjelek mentén
            if ([string]::IsNullOrWhiteSpace($targetFolderNamePart)) {
                $targetFolderNamePart = "root_scan" # Végső fallback
            }
        }
        
        $logFileName = "{0}_{1}.log" -f $targetFolderNamePart, $currentDateTimeForLog
        $logFilePath = Join-Path -Path $LogOutputFolder -ChildPath $logFileName

        # Logfájl kezdeti feltöltése
        try {
            Set-Content -Path $logFilePath -Value "LOGFÁJL INDÍTVA: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Encoding UTF8 -ErrorAction Stop
            Add-Content -Path $logFilePath -Value "Parancsfájl futásának kezdete: $($currentDateTimeForLog)" -Encoding UTF8
            Add-Content -Path $logFilePath -Value "Célmappa az ellenőrzéshez: $TargetFolder" -Encoding UTF8
            Add-Content -Path $logFilePath -Value ("Keresett fájlkiterjesztések: " + ($TargetExtensions -join ", ")) -Encoding UTF8
            Add-Content -Path $logFilePath -Value "-----------------------------------------------------------------" -Encoding UTF8
        } catch {
            Write-Error "Hiba történt a logfájl írása közben ($logFilePath). A logolás ki lesz kapcsolva."
            Write-Error "Hibaüzenet: $($_.Exception.Message)"
            $EnableLogging = $false
            $logFilePath = $null # Hogy a további logolási kísérletek ne fussanak hibára
        }
    }
}

# Ellenőrizzük, hogy a célmappa létezik-e
if (-not (Test-Path $TargetFolder -PathType Container)) {
    $errorMessage = "A megadott célmappa nem létezik: $TargetFolder. A szkript leáll."
    Write-Error $errorMessage
    if ($EnableLogging -and $logFilePath) {
        Add-Content -Path $logFilePath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - [HIBA] - $errorMessage" -Encoding UTF8
        Add-Content -Path $logFilePath -Value "Parancsfájl leállt hibával." -Encoding UTF8
    }
    exit
}

# Felhasználó tájékoztatása a konzolon
$extensionsStringForHost = $TargetExtensions -join ", "
Write-Host "Ellenőrzés indul a következő mappában: $TargetFolder"
Write-Host "Keresett fájltípusok: $extensionsStringForHost (amik nem '.sample' végződésűek)"
Write-Host "-----------------------------------------------------------------"
if ($EnableLogging -and $logFilePath) {
    Add-Content -Path $logFilePath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - [INFO] - Ellenőrzés indul a konzol kimenet szerint." -Encoding UTF8
}

# Átvizsgált mappák és fájlok listázása a logba
if ($EnableLogging -and $logFilePath) {
    Add-Content -Path $logFilePath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - [INFO] - Mappa és fájl ellenőrzés ($TargetFolder) alatt..." -Encoding UTF8
    try {
        $allItems = Get-ChildItem -Path $TargetFolder -Recurse -ErrorAction SilentlyContinue
        Add-Content -Path $logFilePath -Value "    Átvizsgált elemek listája ($($allItems.Count) elem):" -Encoding UTF8
        foreach ($item in $allItems) {
            Add-Content -Path $logFilePath -Value "    - $($item.FullName)" -Encoding UTF8
        }
    } catch {
        Add-Content -Path $logFilePath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - [HIBA] - Hiba történt az elemek listázása közben: $($_.Exception.Message)" -Encoding UTF8
    }
    Add-Content -Path $logFilePath -Value "-----------------------------------------------------------------" -Encoding UTF8
}

# Fájlok keresése a megadott mappában és almappáiban
$FoundFiles = Get-ChildItem -Path $TargetFolder -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    ($TargetExtensions -contains $_.Extension) -and `
    ($_.Name -notlike "*.sample$($_.Extension)")
}

# Eredmények megjelenítése konzolon és logolása
if ($EnableLogging -and $logFilePath) {
    Add-Content -Path $logFilePath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - [INFO] - Keresés eredménye (összesítés):" -Encoding UTF8
}

if ($FoundFiles.Count -gt 0) {
    $WarningMessageHeader = "Figyelem! A következő konfigurációs fájlok lettek találva, amelyek nem '.sample' kiterjesztéssel érkeztek:"
    Write-Warning $WarningMessageHeader # Konzolra
    if ($EnableLogging -and $logFilePath) {
        Add-Content -Path $logFilePath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - [FIGYELMEZTETÉS] - $WarningMessageHeader" -Encoding UTF8
        Add-Content -Path $logFilePath -Value "    Részletek a talált fájlokról:" -Encoding UTF8
    }

    $FoundFiles | ForEach-Object {
        Write-Host "- $($_.FullName)" # Konzolra
        if ($EnableLogging -and $logFilePath) {
            Add-Content -Path $logFilePath -Value "    !!! TALÁLAT: $($_.FullName) !!!" -Encoding UTF8 # Kiemelés a logban
        }
    }

    $WarningMessageFooter = "Kérlek, ellenőrizd ezeket a fájlokat, és szükség esetén nevezd át őket '.sample' kiterjesztésre, mielőtt felülírnád a meglévő konfigurációidat!"
    Write-Warning $WarningMessageFooter # Konzolra
    if ($EnableLogging -and $logFilePath) {
        Add-Content -Path $logFilePath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - [FIGYELMEZTETÉS] - $WarningMessageFooter" -Encoding UTF8
    }
} else {
    $InfoMessage = "Minden rendben! Nem található nem megfelelő ($extensionsStringForHost) fájl."
    Write-Host $InfoMessage # Konzolra
    if ($EnableLogging -and $logFilePath) {
        Add-Content -Path $logFilePath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - [INFO] - $InfoMessage" -Encoding UTF8
    }
}

Write-Host "-----------------------------------------------------------------"
Write-Host "Ellenőrzés befejezve."

if ($EnableLogging -and $logFilePath) {
    Add-Content -Path $logFilePath -Value "-----------------------------------------------------------------" -Encoding UTF8
    Add-Content -Path $logFilePath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - [INFO] - Ellenőrzés befejezve." -Encoding UTF8
    Add-Content -Path $logFilePath -Value "LOGFÁJL BEFEJEZVE: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Encoding UTF8
    Write-Host "Logfájl mentve ide: $logFilePath"
}