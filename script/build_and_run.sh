#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="ClipBord"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLIPBORD_VERSION="${CLIPBORD_VERSION:-$("$ROOT_DIR/script/clipbord_version.sh")}"
APP_VERSION="$CLIPBORD_VERSION"
CLIPBORD_SWIFT_CONFIGURATION="${CLIPBORD_SWIFT_CONFIGURATION:-debug}"
BUNDLE_ID="com.sittinonthanonklang.ClipBord"
MIN_SYSTEM_VERSION="14.0"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON="$ROOT_DIR/Resources/AppIcon.icns"

clear_bundle_xattrs() {
  local bundle_path="$1"
  /usr/bin/xattr -cr "$bundle_path" >/dev/null 2>&1 || true
  /usr/bin/find "$bundle_path" -exec /usr/bin/xattr -d com.apple.FinderInfo {} \; >/dev/null 2>&1 || true
  /usr/bin/find "$bundle_path" -exec /usr/bin/xattr -d 'com.apple.fileprovider.fpfs#P' {} \; >/dev/null 2>&1 || true
}

sign_bundle() {
  local bundle_path="$1"
  local signing_identity
  signing_identity="$(/usr/bin/security find-identity -v -p codesigning 2>/dev/null | /usr/bin/awk -F '\"' '/Apple Development|Developer ID Application/ { print $2; exit }')"

  for _ in 1 2 3; do
    clear_bundle_xattrs "$bundle_path"

    if [[ -n "$signing_identity" ]]; then
      /usr/bin/codesign --force --deep --sign "$signing_identity" "$bundle_path" >/dev/null 2>&1 && return 0
    else
      /usr/bin/codesign --force --deep --sign - "$bundle_path" >/dev/null 2>&1 && return 0
    fi

    /bin/sleep 0.2
  done

  clear_bundle_xattrs "$bundle_path"
  if [[ -n "$signing_identity" ]]; then
    /usr/bin/codesign --force --deep --sign "$signing_identity" "$bundle_path" >/dev/null
  else
    /usr/bin/codesign --force --deep --sign - "$bundle_path" >/dev/null
  fi
}

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

"$ROOT_DIR/script/make_app_icon.sh" >/dev/null

swift build -c "$CLIPBORD_SWIFT_CONFIGURATION"
BUILD_BINARY="$(swift build -c "$CLIPBORD_SWIFT_CONFIGURATION" --show-bin-path)/$APP_NAME"

mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp "$APP_ICON" "$APP_RESOURCES/AppIcon.icns"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

if [[ "${CLIPBORD_SKIP_SIGNING:-0}" != "1" ]]; then
  sign_bundle "$APP_BUNDLE"
fi
clear_bundle_xattrs "$APP_BUNDLE"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  --build-only|build-only)
    ;;
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--build-only|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
