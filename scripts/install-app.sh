#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/xcode"
PRODUCT_DIR="$BUILD_DIR/Build/Products/Debug"
EXECUTABLE_PATH="$PRODUCT_DIR/Shotty"
STAGING_DIR="$ROOT_DIR/.build/install"
APP_BUNDLE="$STAGING_DIR/Shotty.app"
INSTALL_PATH="/Applications/Shotty.app"
VERSION="${SHOTTY_VERSION:-0.1.0}"
BUILD_NUMBER="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || date +%s)"
BUNDLE_ID="com.mishca.shotty"
REQUIREMENT="designated => identifier \"$BUNDLE_ID\""
SOURCE_LOGO_PATH="$ROOT_DIR/logo.png"
BUNDLED_LOGO_DIR="$ROOT_DIR/Sources/Shotty/Resources"
BUNDLED_LOGO_PATH="$BUNDLED_LOGO_DIR/logo.png"

mkdir -p "$BUNDLED_LOGO_DIR"
cp "$SOURCE_LOGO_PATH" "$BUNDLED_LOGO_PATH"

xcodebuild \
  -scheme Shotty \
  -destination 'platform=macOS' \
  -derivedDataPath "$BUILD_DIR" \
  build

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp "$EXECUTABLE_PATH" "$APP_BUNDLE/Contents/MacOS/Shotty"

find "$PRODUCT_DIR" -maxdepth 1 -name '*.bundle' -exec cp -R {} "$APP_BUNDLE/Contents/Resources/" \;

cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>Shotty</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Shotty</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${BUILD_NUMBER}</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
EOF

codesign \
  --force \
  --deep \
  --sign - \
  --identifier "$BUNDLE_ID" \
  --requirements "=${REQUIREMENT}" \
  "$APP_BUNDLE"

pkill -x Shotty || true
rm -rf "$INSTALL_PATH"
cp -R "$APP_BUNDLE" "$INSTALL_PATH"
open "$INSTALL_PATH"

echo "Installed Shotty to $INSTALL_PATH"
