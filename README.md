# ClipBord

ClipBord is a minimal macOS clipboard history app inspired by Windows clipboard history. It runs from the menu bar, keeps copied text and images, and opens a small popup from a customizable keyboard shortcut.

Current version: `0.1.0`

## Features

- Menu bar clipboard history for macOS.
- Text and image clipboard capture.
- Custom global shortcut, default `Option + V`.
- Popup opens near the mouse cursor.
- Click an item to restore it to the pasteboard and paste into the active app.
- Light, dark, and system appearance modes.
- Minimal macOS-style interface with a custom app icon.
- DMG packaging script for distribution.

## Requirements

- macOS 14 or newer.
- Swift 6.2 or newer for local builds.
- Accessibility permission for automatic paste.

## Install From DMG

1. Download `ClipBord 0.1.0.dmg`.
2. Open the DMG.
3. Drag `ClipBord.app` into `Applications`.
4. Launch ClipBord.
5. Allow Accessibility permission when macOS asks.

If macOS blocks the app because it is not notarized, right-click `ClipBord.app`, choose `Open`, then confirm. Public distribution without that warning requires signing with an Apple Developer ID certificate and notarization.

## Build From Source

```bash
swift build
```

Run as a macOS app bundle:

```bash
./script/build_and_run.sh
```

Create a distributable DMG:

```bash
./script/package_dmg.sh
```

The DMG output is:

```text
dist/ClipBord 0.1.0.dmg
```

## Permissions

ClipBord can read clipboard changes without extra setup, but automatic paste needs Accessibility access.

To enable it:

1. Open System Settings.
2. Go to Privacy & Security.
3. Open Accessibility.
4. Enable ClipBord.

If automatic paste stops working after rebuilding the app, remove ClipBord from Accessibility and add the newly built app again. Ad-hoc signed builds can receive a new code identity after each build.

## Project Structure

```text
Sources/ClipBord/       App source code
Resources/              App icon assets
script/                 Build, icon, and DMG scripts
dist/                   Local build artifacts, ignored by git
```

## Versioning

This project uses semantic versioning. The first public package is `0.1.0`.

## License

MIT License. See [LICENSE](LICENSE).
