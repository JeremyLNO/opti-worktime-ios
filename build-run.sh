#!/bin/bash
# Compile Opti Worktime (iOS) pour le simulateur, l'installe et le lance.
set -e
cd "$(dirname "$0")"
SIM="${SIM:-iPhone 16 Pro}"

echo "▶︎ Compilation (simulateur iOS, non signé)…"
xcodebuild -project OptiWorktime.xcodeproj -target OptiWorktime -configuration Debug \
  -sdk iphonesimulator -derivedDataPath build CODE_SIGNING_ALLOWED=NO build

APP="build/Build/Products/Debug-iphonesimulator/OptiWorktime.app"
echo "▶︎ Démarrage du simulateur « $SIM »…"
xcrun simctl boot "$SIM" 2>/dev/null || true
open -a Simulator
xcrun simctl install booted "$APP"
echo "✅ Installé.  Lancer :  xcrun simctl launch booted company.lno.optiworktime"
