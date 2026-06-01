# Kintore

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-lightgrey.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)

Fast, minimal iOS gym-logging app. Start a workout in one tap, log a set in five seconds, see what you did last time auto-filled. No social, no coach, no diet — just training.

> Internal project name: GymFlow (preserved in bundle ID `com.softplanet.GymFlow`, repo name, Swift modules, and Xcode schemes). User-facing name: **Kintore**.

## Tech

SwiftUI + `@Observable` (iOS 17+) · GRDB/SQLite · Local-only · 5 languages (zh-Hant primary, zh-Hans, en, ja, ko).

## Develop

**Prerequisites:** macOS with Xcode 16+ (Swift 6 toolchain), iOS 17+ simulator. No third-party package manager or network setup needed — dependencies resolve through Swift Package Manager and the app is fully local-only.

```bash
# 1. Clone
git clone https://github.com/keihong0213/GymFlow.git
cd GymFlow

# 2. Core unit tests (GRDB layer)
cd GymFlowCore && swift test && cd ..

# 3. App build (simulator)
xcodebuild -project GymFlow.xcodeproj -scheme GymFlow \
    -destination 'platform=iOS Simulator,name=iPhone 16e' build

# 4. UI golden-path test
xcodebuild -project GymFlow.xcodeproj -scheme GymFlow \
    -destination 'platform=iOS Simulator,name=iPhone 16e' \
    -only-testing:GymFlowUITests test
```

Or just open `GymFlow.xcodeproj` in Xcode and press ⌘R.

## Ship to TestFlight

```bash
./scripts/archive.sh
```

Produces `build/GymFlow.xcarchive` and `build/export/GymFlow.ipa`. Upload via Xcode Organizer, or:

```bash
xcrun altool --upload-app -f build/export/GymFlow.ipa -t ios \
    --apiKey <KEY> --apiIssuer <ISSUER>
```

**Before the first real submission**: replace the placeholder files in `GymFlow/Assets.xcassets/AppIcon.appiconset/` with real 1024×1024 PNGs (universal / dark / tinted).

## MVP success criteria (from `PLAN.md §17`)

- App open → first set logged ≤ 15 sec
- Single set record ≤ 5 sec (3 taps + Return)
- Crash-free rate ≥ 99.5%
- 100% UI coverage across 5 languages

## Structure

- `GymFlow/` — app (SwiftUI)
- `GymFlowCore/` — local Swift package with GRDB models, repositories, seed data
- `GymFlowUITests/` — XCUITest golden-path
- `PLAN.md` — product + architecture spec (Chinese, authoritative)

## Contributing

Contributions are welcome — bug fixes, new translations, accessibility improvements, and small features all help.

- **Found a bug or have an idea?** Open an [issue](https://github.com/keihong0213/GymFlow/issues) first so we can discuss scope before you write code.
- **Pull requests:** branch off `main`, keep changes focused, and make sure `swift test` (core) and the build both pass before opening the PR.
- **Conventions** (see [`CLAUDE.md`](CLAUDE.md) for the full list):
  - Every user-visible string goes through `Localizable.xcstrings` — no hard-coded zh/en/ja/ko literals in views.
  - Weights are stored in kg (`Double`) and displayed via `WeightFormatter`, respecting the user's unit setting.
  - Architecture is View ↔ `@Observable` ViewModel ↔ Repository ↔ GRDB, with constructor injection.
- **Translations:** the primary language is zh-Hant; zh-Hans, en, ja, and ko are also maintained. Improvements to any locale are appreciated.
- By contributing, you agree your contributions are licensed under the project's GPL-3.0 license.

`PLAN.md` (zh-Hant) is the authoritative product and architecture spec — worth a read before larger changes.

## License

Copyright © 2026 Keihong.

This project is licensed under the **GNU General Public License v3.0** — see [`LICENSE`](LICENSE) for the full text. In short: you are free to use, study, modify, and redistribute the source, but any distributed derivative work must also be released under the GPL-3.0 and provide its source code.
