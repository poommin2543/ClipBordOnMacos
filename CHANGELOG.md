# Changelog

All notable changes to ClipBord are documented here.

## 0.1.1 - 2026-04-24

- Fixed panel header title wrapping so the app name displays as **ClipBord** on one line.
- Build and DMG packaging take the app version from the latest reachable Git tag `v*` unless `CLIPBORD_VERSION` is set; GitHub Actions uses a full clone so tags resolve in CI and release workflows.

## 0.1.0 - 2026-04-22

Initial public version.

- Added macOS menu bar clipboard history app.
- Added text and image clipboard history.
- Added customizable global shortcut with `Option + V` default.
- Added popup near mouse position.
- Added click-to-paste behavior for selected clipboard items.
- Added light, dark, and system theme modes.
- Added custom ClipBord app icon.
- Added DMG packaging output as `ClipBord 0.1.0.dmg`.
