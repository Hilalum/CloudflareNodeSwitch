#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Cloudflare Node Switch"
BUNDLE_ID="com.local.cloudflare-node-switch"
APP_VERSION="${APP_VERSION:-2026.6.27}"
BUILD_DIR=".build/arm64-apple-macosx/release"
DIST_DIR="dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_FILE="AppIcon.icns"
SING_BOX_SOURCE="${SING_BOX_SOURCE:-}"

swift build -c release

python3 script/generate_icon.py >/dev/null
iconutil -c icns Resources/AppIcon.iconset -o "Resources/$ICON_FILE"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/CloudflareNodeSwitch" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"
cp "Resources/$ICON_FILE" "$RESOURCES_DIR/$ICON_FILE"

if [[ -z "$SING_BOX_SOURCE" ]]; then
  if command -v sing-box >/dev/null 2>&1; then
    SING_BOX_SOURCE="$(command -v sing-box)"
  elif [[ -x /opt/homebrew/bin/sing-box ]]; then
    SING_BOX_SOURCE="/opt/homebrew/bin/sing-box"
  elif [[ -x /usr/local/bin/sing-box ]]; then
    SING_BOX_SOURCE="/usr/local/bin/sing-box"
  fi
fi

if [[ -n "$SING_BOX_SOURCE" && -x "$SING_BOX_SOURCE" ]]; then
  cp "$SING_BOX_SOURCE" "$RESOURCES_DIR/sing-box"
  chmod +x "$RESOURCES_DIR/sing-box"
else
  echo "warning: sing-box not found; app will require sing-box installed separately" >&2
fi

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>${APP_VERSION//./}</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSSupportsAutomaticGraphicsSwitching</key>
  <true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP_DIR"

mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/$APP_NAME.app"
cp -R "$APP_DIR" "$HOME/Applications/$APP_NAME.app"

echo "$PWD/$APP_DIR"
echo "$HOME/Applications/$APP_NAME.app"
