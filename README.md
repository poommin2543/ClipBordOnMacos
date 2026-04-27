# ClipBord

<p align="center">
  <img src="Resources/AppIcon-readme.png" alt="ClipBord app icon" width="128" height="128">
</p>

> A minimal macOS clipboard history manager — live in your menu bar, always one shortcut away.

<p align="center">
  <img src="Resources/screenshot.png" alt="ClipBord Preview" width="600">
</p>

ClipBord is inspired by the Windows clipboard history feature. It captures copied text and images in the background, stores a scrollable history, and lets you restore any past entry into the active application with a single click. Everything is accessible from a keyboard shortcut that pops up a small, native-looking window right next to your cursor.

Current version: `0.2.2`

---

## Features

### 🚀 Quick Access & Efficiency
- **Menu Bar App**: Runs silently in the menu bar, keeping your Dock clean.
- **Global Shortcut**: Default `Option + V` pops up the history window instantly. Fully customizable to fit your workflow.
- **Cursor-Relative Popup**: The history window appears right next to your mouse pointer, so you don't have to move your eyes across the screen.
- **One-Click Paste**: Click any item to copy it back to the clipboard and paste it immediately into your active app.

### 📋 Smart History
- **Text & Image Capture**: Seamlessly stores both plain text and image clipboard entries.
- **Persistent History**: Your clipboard history is saved to disk and persists across system restarts.
- **Pinned Items**: "Pin" important snippets to keep them forever. Pinned items are exempt from automatic cleanup.
- **Searchable History**: Quickly filter through your saved clips using the built-in search bar.

### 🎨 Modern macOS Experience
- **Native SwiftUI UI**: Built with native components for a sleek, premium feel that matches macOS perfectly.
- **Appearance Modes**: Supports Light, Dark, and System modes.
- **Rich Previews**: See full text or larger image previews without losing your place.
- **Automatic Updates**: Stay up to date with built-in version checking and easy installation from GitHub.

### 🛠 Control & Customization
- **Retention Controls**: Configurable limits on how many items to keep or how long to store unpinned entries.
- **Accessibility Integration**: Uses macOS Accessibility features to provide a smooth "paste-on-click" experience.
- **Privacy First**: Everything is stored locally on your machine.

---

## Requirements

- **macOS 14 Sonoma** or newer
- **Swift 6.1** or newer (only required for building from source)
- **Accessibility permission** — needed for automatic paste after clicking a history item

---

## Install from DMG

1. Download **`ClipBord 0.2.2.dmg`** from the [Releases](../../releases) page.
2. Open the DMG file.
3. Drag **ClipBord.app** into the **Applications** folder shortcut.
4. Eject the DMG and launch **ClipBord** from Applications.
5. When macOS prompts for **Accessibility** permission, click **Open System Settings** and enable it.

> **Gatekeeper notice** — If macOS blocks the app because it is not notarised, right-click `ClipBord.app`, choose **Open**, then confirm in the dialog. Distributing without this warning requires signing with an Apple Developer ID certificate and running Apple's notarisation service.

---

## Build from Source

### 1. Clone the repository

```bash
git clone https://github.com/poommin2543/ClipBordOnMacos.git
cd ClipBordOnMacos
```

### 2. Compile (Swift Package Manager)

This produces the raw binary under `.build/`:

```bash
swift build
```

For an optimised release binary:

```bash
swift build -c release
```

### 3. Run as a macOS app bundle

The helper script assembles a proper `.app` bundle, signs it ad-hoc, and launches it:

```bash
./script/build_and_run.sh
```

Available run modes:

| Command | What it does |
|---------|-------------|
| `./script/build_and_run.sh` | Build, bundle, sign, and **launch** ClipBord |
| `./script/build_and_run.sh run` | Same as above (explicit) |
| `./script/build_and_run.sh --build-only` | Build and bundle **without** launching |
| `./script/build_and_run.sh --debug` | Launch under `lldb` for interactive debugging |
| `./script/build_and_run.sh --logs` | Launch and stream `os_log` output to the terminal |
| `./script/build_and_run.sh --telemetry` | Launch and stream subsystem telemetry logs |
| `./script/build_and_run.sh --verify` | Launch, wait 2 s, then verify the process is running |

> The script automatically regenerates the app icon (via `script/make_app_icon.sh`) before every build, so you always get the latest icon.

### 4. Package a distributable DMG

```bash
./script/package_dmg.sh
```

This command:
1. Builds the app in `--build-only` mode.
2. Copies the `.app` bundle to a temporary staging directory.
3. Clears extended attributes and signs the bundle.
4. Creates a compressed DMG in `dist/`.
5. Notarises and staples the DMG when Developer ID and Apple notarisation credentials are configured.

Output file:

```
dist/ClipBord 0.2.2.dmg
```

### 5. Developer ID signing and notarisation

Local builds and CI releases fall back to ad-hoc signing when Developer ID credentials are not present. To produce a notarised GitHub release, add these repository secrets:

| Secret | Purpose |
|--------|---------|
| `MACOS_CERTIFICATE_BASE64` | Base64-encoded `.p12` Developer ID Application certificate |
| `MACOS_CERTIFICATE_PASSWORD` | Password for the `.p12` certificate |
| `MACOS_KEYCHAIN_PASSWORD` | Temporary CI keychain password |
| `MACOS_SIGNING_IDENTITY` | Exact identity, e.g. `Developer ID Application: Your Name (TEAMID)` |
| `APPLE_ID` | Apple ID used for notarisation |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password for notarisation |
| `APPLE_TEAM_ID` | Apple Developer Team ID |
| `CLIPBORD_ENABLE_NOTARIZATION` | Optional; set to `1` to fail if notarisation cannot run, or leave empty for auto/fallback |

`script/package_dmg.sh` signs with `--options runtime --timestamp` for Developer ID identities. If the signing identity or notary credentials are missing, the script still creates an ad-hoc signed DMG for testing.

---

## Regenerate the App Icon

The icon is drawn programmatically with AppKit (no external assets required).

```bash
./script/make_app_icon.sh
```

This runs `script/generate_app_icon.swift` to render all required PNG sizes into `Resources/AppIcon.iconset/`, then converts the set to `Resources/AppIcon.icns` with `iconutil`. It also refreshes `Resources/AppIcon-readme.png` (256 px) for the README preview.

---

## Permissions

### Accessibility (required for auto-paste)

ClipBord can read clipboard changes without any extra setup. However, the **automatic paste** step — where clicking a history item types it into the active application — requires Accessibility access.

To grant it:

1. Open **System Settings**.
2. Go to **Privacy & Security → Accessibility**.
3. Toggle **ClipBord** on.

> **After rebuilding from source** — macOS ties the Accessibility grant to the code signature. An ad-hoc signed build may receive a new identity each time. If auto-paste stops working after a rebuild, remove ClipBord from the Accessibility list and add the newly built app again.

> **In-place updates** — The built-in updater replaces the `.app` at the same path. macOS is most likely to **keep Accessibility and other privacy toggles** when the new build is signed with the **same Apple Developer ID team** as before. **Ad-hoc (`codesign -`)** or a different team ID usually looks like a new app to the system, so you may need to enable Accessibility again. CI/DMG builds fall back to ad-hoc signing unless the Developer ID secrets above are configured.

---

## Project Structure

```
Sources/ClipBord/
  App/          Application entry point and lifecycle
  Models/       Data models (clipboard item, history)
  Services/     Clipboard monitoring, pasteboard interaction
  Stores/       Observable state stores
  Support/      Utilities and extensions
  Views/        SwiftUI views (popup, menu bar)

Resources/
  AppIcon.iconset/      PNG files for each icon resolution (generated; git-ignored)
  AppIcon.icns          Compiled icon used by the app bundle
  AppIcon-readme.png    App icon at README-friendly size (regenerated by make_app_icon.sh)

script/
  build_and_run.sh        Build, assemble bundle, and run
  clipbord_version.sh     Print SemVer from latest reachable `v*` tag (for packaging)
  package_dmg.sh          Build and package a distributable DMG
  generate_app_icon.swift Programmatic icon renderer (AppKit)
  make_app_icon.sh        Converts iconset → .icns

dist/                     Local build artefacts (git-ignored)
```

---

## Versioning

This project follows [Semantic Versioning](https://semver.org/). The current release is `0.2.2`.

**Build version** — `script/build_and_run.sh` and `script/package_dmg.sh` set `CFBundleShortVersionString` and the DMG file name from the **latest reachable Git tag** matching `v*` (for example `v0.1.1` → `0.1.1`), via `script/clipbord_version.sh`. If no such tag exists, the version falls back to `0.0.0`. Override anytime with `CLIPBORD_VERSION=1.2.3 ./script/package_dmg.sh`.

GitHub Actions checks out the full history (`fetch-depth: 0`) so tags are visible to that resolver.

**Update checks** — On **every launch**, `ClipBordAppController` calls GitHub’s latest-release API for `poommin2543/ClipBordOnMacos` with **no time throttle** (so a new tag is not missed). When the **menu bar panel opens**, `ClipboardPanelView` may check again, but at most about **once every three hours** (stored in `UserDefaults`). If a newer version exists, you see a **Download & install** dialog at launch (once per version per run), or **Update now** in the panel. After the DMG finishes downloading, ClipBord quits on its own, replaces **`ClipBord.app/Contents`** in place (same `.app` path as before), relaunches, and strips `com.apple.quarantine` on the bundle. That in-place update improves the odds macOS keeps **Accessibility** when the build is **Developer ID–signed** with the same team and bundle ID; **ad-hoc** CI builds or copying the app to a new folder can still require allowing the app again. When running from `swift run` or a loose binary, the in-app control opens the release page in your browser instead. To point at another fork, change `GitHubUpdateChecker.defaultRepository` in the source.

See [CHANGELOG.md](CHANGELOG.md) for the full history of changes.

---

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

---

## License

MIT License. See [LICENSE](LICENSE) for the full text.
