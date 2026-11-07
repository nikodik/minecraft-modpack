# Скрипт для генерации manifest.json из папок mods и configs
param(
    [string]$ModsDir = ".\mods",
    [string]$ConfigsDir = ".\configs",
    [string]$OutputFile = ".\manifest.json",
    [string]$BaseUrl = "https://raw.githubusercontent.com/nikodik/minecraft-modpack/main"
)

$manifest = [ordered]@{
    version  = "1.1.0"
    minecraft = "1.21.1"
    forge    = "21.1.265"
    mods     = @()
    configs  = @()
}

Write-Host "Сканирование модов в $ModsDir..." -ForegroundColor Cyan

if (Test-Path $ModsDir) {
    Get-ChildItem -Path $ModsDir -Filter "*.jar" | ForEach-Object {
        $file = $_
        Write-Host "  Обработка: $($file.Name)" -ForegroundColor Gray

        $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash.ToLower()

        $manifest.mods += [ordered]@{
            name     = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            filename = $file.Name
            url      = "$BaseUrl/mods/$($file.Name)"
            sha256   = $hash
            size     = $file.Length
            required = $true
        }

        Write-Host "    SHA256: $hash" -ForegroundColor Green
    }
}

Write-Host "Сканирование конфигов в $ConfigsDir..." -ForegroundColor Cyan

if (Test-Path $ConfigsDir) {
    Get-ChildItem -Path $ConfigsDir -File -Recurse | ForEach-Object {
        $file = $_
        # Путь относительно папки configs, с прямыми слэшами (example: config/fml.toml)
        $rel = [System.IO.Path]::GetRelativePath($ConfigsDir, $file.FullName).Replace('\', '/')
        Write-Host "  Обработка: $rel" -ForegroundColor Gray

        $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash.ToLower()

        $manifest.configs += [ordered]@{
            path     = $rel
            url      = "$BaseUrl/configs/$rel"
            sha256   = $hash
            size     = $file.Length
            required = $true
        }

        Write-Host "    SHA256: $hash" -ForegroundColor Green
    }
}

# Сохраняем manifest.json (UTF-8 без BOM, отступ 2)
$json = $manifest | ConvertTo-Json -Depth 10
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Resolve-Path $OutputFile -ErrorAction SilentlyContinue ?? "$PWD\$OutputFile"), $json, $utf8NoBom)

Write-Host "`nManifest сгенерирован: $OutputFile" -ForegroundColor Green
Write-Host "Модов: $($manifest.mods.Count), конфигов: $($manifest.configs.Count)" -ForegroundColor Green
