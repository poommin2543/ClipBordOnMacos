# Contributing

Thanks for considering a contribution to ClipBord.

## Development Setup

```bash
swift build
./script/build_and_run.sh
```

## Before Opening a Pull Request

- Keep changes focused and easy to review.
- Run `swift build`.
- If packaging changes are included, run `./script/package_dmg.sh`.
- Update `README.md` or `CHANGELOG.md` when behavior or installation steps change.

## Code Style

- Prefer small SwiftUI views and narrow AppKit bridges.
- Keep clipboard and permission behavior explicit.
- Avoid adding dependencies unless they clearly improve the app.

## Reporting Bugs

Please include:

- macOS version.
- ClipBord version.
- Steps to reproduce.
- Whether Accessibility permission is enabled.
- Any relevant terminal output or screenshots.
