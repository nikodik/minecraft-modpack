# Скрипт для генерации manifest.json из папки mods
param(
    [string]$ModsDir = ".\mods",
    [string]$OutputFile = ".\manifest.json",
    [string]$BaseUrl = "https://raw.githubusercontent.com/nikodik/minecraft-modpack/main/mods"
)

$manifest = @{
    version = "1.0.0"
    minecraft = "1.21.1"
    forge = "52.0.16"
    mods = @()
}

Write-Host "Сканирование модов в $ModsDir..." -ForegroundColor Cyan

Get-ChildItem -Path $ModsDir -Filter "*.jar" | ForEach-Object {
    $file = $_
    Write-Host "  Обработка: $($file.Name)" -ForegroundColor Gray

    # Вычисляем SHA256
    $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash.ToLower()

    $modEntry = @{
        name = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        filename = $file.Name
        url = "$BaseUrl/$($file.Name)"
        sha256 = $hash
        required = $true
    }

    $manifest.mods += $modEntry
    Write-Host "    SHA256: $hash" -ForegroundColor Green
}

# Сохраняем manifest.json
$json = $manifest | ConvertTo-Json -Depth 10
$json | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "`nManifest сгенерирован: $OutputFile" -ForegroundColor Green
Write-Host "Модов добавлено: $($manifest.mods.Count)" -ForegroundColor Green
