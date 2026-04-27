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

resolve_signing_identity() {
  local signing_identity
  signing_identity="${CLIPBORD_SIGNING_IDENTITY:-}"

  if [[ -z "$signing_identity" ]]; then
    signing_identity="$(/usr/bin/security find-identity -v -p codesigning 2>/dev/null | /usr/bin/awk -F '"' '/Developer ID Application/ { print $2; exit }')"
  fi

  if [[ -z "$signing_identity" ]]; then
    signing_identity="$(/usr/bin/security find-identity -v -p codesigning 2>/dev/null | /usr/bin/awk -F '"' '/Apple Development/ { print $2; exit }')"
  fi

  printf '%s' "$signing_identity"
}

sign_bundle() {
  local bundle_path="$1"
  local signing_identity="$2"
  local codesign_args=(--force --deep)

  if [[ "$signing_identity" == Developer\ ID\ Application:* ]]; then
    codesign_args+=(--options runtime --timestamp)
  fi

  if [[ -n "$signing_identity" && "$signing_identity" != "-" ]]; then
    echo "Signing $APP_NAME.app with: $signing_identity" >&2
    /usr/bin/codesign "${codesign_args[@]}" --sign "$signing_identity" "$bundle_path" >/dev/null
  else
    echo "Signing $APP_NAME.app ad-hoc (set CLIPBORD_SIGNING_IDENTITY for Developer ID)." >&2
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

notarize_dmg_if_configured() {
  local dmg_path="$1"
  local signing_identity="$2"
  local enable="${CLIPBORD_ENABLE_NOTARIZATION:-auto}"
  local has_profile=0
  local has_apple_id=0

  if [[ -n "${CLIPBORD_NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
    has_profile=1
  fi

  if [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
    has_apple_id=1
  fi

  if [[ "$enable" == "0" ]]; then
    echo "Notarization disabled (CLIPBORD_ENABLE_NOTARIZATION=0)." >&2
    return 0
  fi

  if [[ "$signing_identity" != Developer\ ID\ Application:* ]]; then
    if [[ "$enable" == "1" ]]; then
      echo "Notarization requires a Developer ID Application signing identity." >&2
      return 1
    fi
    echo "Skipping notarization: no Developer ID Application signing identity." >&2
    return 0
  fi

  if [[ "$has_profile" != "1" && "$has_apple_id" != "1" ]]; then
    if [[ "$enable" == "1" ]]; then
      echo "Notarization requested, but no notary credentials were provided." >&2
      return 1
    fi
    echo "Skipping notarization: no notary credentials provided." >&2
    return 0
  fi

  echo "Submitting DMG for notarization..." >&2
  if [[ "$has_profile" == "1" ]]; then
    /usr/bin/xcrun notarytool submit "$dmg_path" --keychain-profile "$CLIPBORD_NOTARY_KEYCHAIN_PROFILE" --wait
  else
    /usr/bin/xcrun notarytool submit "$dmg_path" \
      --apple-id "$APPLE_ID" \
      --password "$APPLE_APP_SPECIFIC_PASSWORD" \
      --team-id "$APPLE_TEAM_ID" \
      --wait
  fi

  /usr/bin/xcrun stapler staple "$dmg_path"
}

CLIPBORD_SKIP_SIGNING=1 \
CLIPBORD_VERSION="$APP_VERSION" \
CLIPBORD_SWIFT_CONFIGURATION="$CLIPBORD_SWIFT_CONFIGURATION" \
"$ROOT_DIR/script/build_and_run.sh" --build-only
clear_bundle_xattrs "$APP_BUNDLE"

mkdir -p "$STAGING_DIR"
/usr/bin/ditto --norsrc --noextattr "$APP_BUNDLE" "$STAGING_APP"
clear_bundle_xattrs "$STAGING_APP"
SIGNING_IDENTITY="$(resolve_signing_identity)"
sign_bundle "$STAGING_APP" "$SIGNING_IDENTITY"
verify_bundle "$STAGING_APP"
/bin/ln -s /Applications "$STAGING_DIR/Applications"

/usr/bin/hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -format UDZO \
  -ov \
  "$DMG_PATH"

notarize_dmg_if_configured "$DMG_PATH" "$SIGNING_IDENTITY"

echo "$DMG_PATH"
