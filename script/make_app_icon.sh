#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESOURCES_DIR="$ROOT_DIR/Resources"
ICONSET_DIR="$RESOURCES_DIR/AppIcon.iconset"
ICNS_PATH="$RESOURCES_DIR/AppIcon.icns"

mkdir -p "$RESOURCES_DIR"
/usr/bin/swift "$ROOT_DIR/script/generate_app_icon.swift" "$ICONSET_DIR"
/usr/bin/iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"

tmp_readme_png="$(/usr/bin/mktemp /tmp/clipbord-readme-icon.XXXXXX.png)"
/usr/bin/sips -s format png "$ICNS_PATH" --out "$tmp_readme_png" >/dev/null
/usr/bin/sips -Z 256 "$tmp_readme_png" --out "$RESOURCES_DIR/AppIcon-readme.png" >/dev/null
/bin/rm -f "$tmp_readme_png"

echo "$ICNS_PATH"
