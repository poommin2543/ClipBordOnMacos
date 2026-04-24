#!/usr/bin/env bash
set -euo pipefail

APP_NAME="ClipBord"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLIPBORD_VERSION="${CLIPBORD_VERSION:-$("$ROOT_DIR/script/clipbord_version.sh")}"
APP_VERSION="$CLIPBORD_VERSION"
CLIPBORD_SWIFT_CONFIGURATION="${CLIPBORD_SWIFT_CONFIGURATION:-release}"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
STAMP="$(/bin/date +%Y%m%d-%H%M%S)"
STAGING_DIR="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/clipbord-dmg-stage.XXXXXX")"
STAGING_APP="$STAGING_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME $APP_VERSION.dmg"

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

  if [[ -n "$signing_identity" ]]; then
    /usr/bin/codesign --force --deep --sign "$signing_identity" "$bundle_path" >/dev/null
  else
    /usr/bin/codesign --force --deep --sign - "$bundle_path" >/dev/null
  fi
}

verify_bundle() {
  local bundle_path="$1"

  for _ in 1 2 3; do
    clear_bundle_xattrs "$bundle_path"
    if /usr/bin/codesign --verify --deep --strict --verbose=2 "$bundle_path" >/dev/null 2>&1; then
      return 0
    fi
    /bin/sleep 0.2
  done

  /usr/bin/codesign --verify --deep --strict --verbose=2 "$bundle_path"
}

CLIPBORD_SKIP_SIGNING=1 \
CLIPBORD_VERSION="$APP_VERSION" \
CLIPBORD_SWIFT_CONFIGURATION="$CLIPBORD_SWIFT_CONFIGURATION" \
"$ROOT_DIR/script/build_and_run.sh" --build-only
clear_bundle_xattrs "$APP_BUNDLE"

mkdir -p "$STAGING_DIR"
/usr/bin/ditto --norsrc --noextattr "$APP_BUNDLE" "$STAGING_APP"
clear_bundle_xattrs "$STAGING_APP"
sign_bundle "$STAGING_APP"
verify_bundle "$STAGING_APP"
/bin/ln -s /Applications "$STAGING_DIR/Applications"

/usr/bin/hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -format UDZO \
  -ov \
  "$DMG_PATH"

echo "$DMG_PATH"
