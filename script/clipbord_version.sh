#!/usr/bin/env bash
# Prints SemVer without leading "v" from the nearest reachable tag matching v*.
# Used when CLIPBORD_VERSION is not already set by the caller environment.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tag="$(git -C "$ROOT" describe --tags --match='v*' --abbrev=0 2>/dev/null || true)"
if [[ -n "$tag" ]]; then
  printf '%s\n' "${tag#v}"
  exit 0
fi

printf '%s\n' "0.0.0"
