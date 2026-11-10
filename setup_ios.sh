#!/usr/bin/env bash
# Metro Widget IDF - préparation iOS (macOS + Xcode requis)
# Créé par : Omar Pérez - 2026-11-09 08:10
# Usage : ./setup_ios.sh VOTRE_CLE_PRIM
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p output
exec > >(tee "output/setup_ios_$(date +%Y%m%d_%H%M).log") 2>&1

flutter create --org com.omarperez --project-name metro_widget --platforms android,ios .
flutter pub get

PL=ios/Runner/Info.plist
PB=/usr/libexec/PlistBuddy
$PB -c "Add :NSLocationWhenInUseUsageDescription string 'Trouver la station la plus proche'" "$PL" 2>/dev/null || true
$PB -c "Add :BGTaskSchedulerPermittedIdentifiers array" "$PL" 2>/dev/null || true
$PB -c "Add :BGTaskSchedulerPermittedIdentifiers:0 string metro-widget-refresh" "$PL" 2>/dev/null || true
$PB -c "Add :UIBackgroundModes array" "$PL" 2>/dev/null || true
$PB -c "Add :UIBackgroundModes:0 string fetch" "$PL" 2>/dev/null || true

cd ios && pod install && cd ..
echo "Étapes Xcode restantes : voir README.md section iOS"
open ios/Runner.xcworkspace
echo "Puis : flutter run --release --dart-define=PRIM_API_KEY=${1:-}"
