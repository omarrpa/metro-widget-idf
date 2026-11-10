# Metro Widget IDF - installation et lancement Android (Windows)
# Créé par : Omar Pérez - 2026-11-09 08:10
# Usage : .\setup.ps1 -ApiKey "VOTRE_CLE_PRIM"   [-Build]
param([string]$ApiKey = "", [switch]$Build)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
New-Item -ItemType Directory -Force -Path output | Out-Null
Start-Transcript -Path "output\setup_$(Get-Date -Format yyyyMMdd_HHmm).log"

try {
    flutter create --org com.omarperez --project-name metro_widget --platforms android,ios .
    flutter pub get
    dart format lib
    flutter analyze
    $extra = @()
    if ($ApiKey) { $extra += "--dart-define=PRIM_API_KEY=$ApiKey" }
    if ($Build) {
        flutter build apk --release @extra
        Copy-Item build\app\outputs\flutter-apk\app-release.apk output\metro_widget.apk -Force
        Write-Host "APK : $PSScriptRoot\output\metro_widget.apk"
    } else {
        flutter run --release @extra
    }
    if (Test-Path "D:\") {
        $dst = "D:\Code\metro_widget_idf"
        New-Item -ItemType Directory -Force -Path $dst | Out-Null
        robocopy $PSScriptRoot $dst /E /XD build .dart_tool | Out-Null
        Write-Host "Copie sur $dst"
    }
} finally {
    Stop-Transcript
}
