# Kintore — a local-only workout logger for iOS

[![Download on the App Store](https://img.shields.io/badge/App%20Store-Download-0D96F6?logo=apple&logoColor=white)](https://apps.apple.com/app/id6762633868)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-lightgrey.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)

**Log a set in about five seconds. No account, no cloud, no subscription — your training data never leaves your iPhone.**

Most gym apps want you to sign up, sync, follow a coach and scroll a feed. Kintore does one thing: it records what you lifted as fast as you can tap it, and shows you what you did last time so you know what to beat.

[**Download on the App Store**](https://apps.apple.com/app/id6762633868) · [Privacy policy](https://keihong0213.github.io/GymFlow/privacy.html) · Free, no ads, no in-app purchases.

| Home | Workout detail | History |
|---|---|---|
| ![Home screen showing the last 7 days, a last-workout summary and the Start Workout button](docs/screenshots/shot1.png) | ![Workout detail showing duration, total volume, and sets and reps for each exercise](docs/screenshots/shot3.png) | ![History list grouping sessions by month with duration and volume](docs/screenshots/shot4.png) |

## What it does

- **Fast set entry** — last session's weight and reps are pre-filled; repeat a set with one tap.
- **Templates** — built-in Push / Pull / Legs / Upper / Lower / Full Body, plus your own.
- **Exercise library** — ~60–80 seeded exercises (barbell / dumbbell / machine / bodyweight / cardio), each localized.
- **Session summary** — total sets, total volume, duration, and which personal records you hit.
- **Rest timer** — per-exercise default, counts down in the background.
- **kg / lb** — stored in kg, converted for display; the step size follows the unit.
- **Five languages** — 繁體中文 (primary), 简体中文, English, 日本語, 한국어.

## What it deliberately does not do

No accounts. No server. No social feed, coach, diet tracking or streak guilt. The database is a local SQLite file on your device — which also means **your own device backup is what protects your history**.

## Status

v1.0 has been on the App Store since April 2026. The repo is open for issues and pull requests — see [good first issues](https://github.com/keihong0213/GymFlow/labels/good%20first%20issue) if you want somewhere to start.

## Tech

SwiftUI + `@Observable` (iOS 17+) · GRDB/SQLite · Swift 6 · local-only · String Catalog i18n.
65 tests across `GymFlowCore` (15 test files), plus an XCUITest golden path.

Architecture is View ↔ `@Observable` ViewModel ↔ Repository ↔ GRDB, with constructor injection.

## Build it yourself

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

## Design targets (from `PLAN.md §17`)

- App open → first set logged ≤ 15 sec
- Single set record ≤ 5 sec (3 taps + Return)
- Crash-free rate ≥ 99.5%
- 100% UI coverage across 5 languages

## Structure

- `GymFlow/` — app (SwiftUI). Features under `Features/` (Home, Session, Routines, ExerciseDetail, History, Onboarding, Settings).
- `GymFlowCore/` — local Swift package: GRDB models, repositories, migrations, seed data, PR calculator, formatters.
- `GymFlowUITests/` — XCUITest golden path.
- `PLAN.md` — product + architecture spec (zh-Hant, authoritative).
- `docs/` — GitHub Pages site and privacy policy.

## Contributing

Contributions are welcome — bug fixes, translation fixes, accessibility improvements and small features all help. See [`CONTRIBUTING.md`](CONTRIBUTING.md) for setup, conventions and the review flow.

> Naming note: the user-facing name is **Kintore**; `GymFlow` is the internal name, preserved in the bundle ID `com.softplanet.GymFlow`, the repo name, Swift modules and Xcode schemes.

## License

Copyright © 2026 Keihong.

Licensed under the **MIT License** — see [`LICENSE`](LICENSE). Use it, fork it, ship it; keeping the copyright notice is all that is asked.

> Everything up to and including the [`v1.0.0`](https://github.com/keihong0213/GymFlow/releases/tag/v1.0.0) tag was published under GPL-3.0, and that release remains available under those terms. Everything from the relicensing commit onward is MIT.
