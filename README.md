# GymFlow

Fast, minimal iOS gym-logging app. Start a workout in one tap, log a set in five seconds, see what you did last time auto-filled. No social, no coach, no diet — just training.

## Tech

SwiftUI + `@Observable` (iOS 17+) · GRDB/SQLite · Local-only · 5 languages (zh-Hant primary, zh-Hans, en, ja, ko).

## Develop

```bash
# Core unit tests (GRDB layer)
cd GymFlowCore && swift test

# App build
xcodebuild -project GymFlow.xcodeproj -scheme GymFlow \
    -destination 'platform=iOS Simulator,name=iPhone 16e' build

# UI golden-path test
xcodebuild -project GymFlow.xcodeproj -scheme GymFlow \
    -destination 'platform=iOS Simulator,name=iPhone 16e' \
    -only-testing:GymFlowUITests test

# Codex review (local plugin)
node "$HOME/.claude/plugins/cache/openai-codex/codex/1.0.3/scripts/codex-companion.mjs" review ""
```

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
