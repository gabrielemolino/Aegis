#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Aegis (v0.7) — macOS Standalone Application Packager
# Builds and packages Aegis.app into a distributable bundle and DMG / ZIP archive.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DIST_DIR="${PROJECT_ROOT}/dist"
APP_NAME="Aegis"
APP_BUNDLE="${DIST_DIR}/${APP_NAME}.app"
VERSION="0.7.0"
BUNDLE_ID="com.antigravity.aegis"

echo "========================================================================"
echo " Packaging ${APP_NAME} v${VERSION} for macOS Apple Silicon"
echo "========================================================================"

cd "${PROJECT_ROOT}"

# 1. Pulizia cartella di distribuzione
rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

# 2. Compilazione in modalità Release con Swift Package Manager
echo "[*] Compilazione release in corso..."
swift build -c release

RELEASE_BIN="${PROJECT_ROOT}/.build/release/SentinelAI"
if [ ! -f "${RELEASE_BIN}" ]; then
    echo "[-] Errore: Binario release non trovato in ${RELEASE_BIN}"
    exit 1
fi
echo "[+] Compilazione completata con successo."

# 3. Creazione della struttura bundle macOS (.app)
echo "[*] Generazione struttura bundle macOS: ${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# 4. Copia del binario eseguibile rinominato ad Aegis
cp "${RELEASE_BIN}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# 5. Generazione Info.plist conforme per macOS Sonoma (14.0+)
cat <<EOF > "${APP_BUNDLE}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>it</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.security</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Aegis Project. MIT License.</string>
</dict>
</plist>
EOF

# 6. Generazione PkgInfo
echo -n "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

# 7. Firma ad-hoc per esecuzione locale su Apple Silicon
echo "[*] Applicazione firma ad-hoc per Apple Silicon..."
codesign --force --deep --sign - "${APP_BUNDLE}"

# 8. Creazione Archivio ZIP per distribuzione
echo "[*] Creazione pacchetto compresso ZIP..."
ZIP_NAME="${APP_NAME}-v${VERSION}-macOS-arm64.zip"
(cd "${DIST_DIR}" && zip -r -q "${ZIP_NAME}" "${APP_NAME}.app")
echo "[+] Archivio ZIP generato: ${DIST_DIR}/${ZIP_NAME}"

# 9. Creazione immagine disco DMG (se hdiutil è disponibile)
if command -v hdiutil &>/dev/null; then
    echo "[*] Generazione immagine disco DMG..."
    DMG_NAME="${APP_NAME}-v${VERSION}-macOS-arm64.dmg"
    hdiutil create -volname "${APP_NAME}" -srcfolder "${APP_BUNDLE}" -ov -format UDZO "${DIST_DIR}/${DMG_NAME}" -quiet
    echo "[+] Immagine disco DMG generata: ${DIST_DIR}/${DMG_NAME}"
fi

echo "========================================================================"
echo " Packaging completato con successo per Aegis v${VERSION}!"
echo " Posizione applicazione: ${APP_BUNDLE}"
echo "========================================================================"
