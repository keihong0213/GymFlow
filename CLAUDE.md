# CLAUDE.md

Guidance for Claude Code working in this repo. See `README.md` for human-facing intro and `PLAN.md` for the authoritative product/architecture spec (zh-Hant).

## Naming

- **User-facing name**: Kintore
- **Internal name**: GymFlow — preserved in bundle ID `com.softplanet.GymFlow`, repo name, Swift modules, Xcode scheme, folder paths. Do not rename these.

## Stack

SwiftUI · iOS 17+ · `@Observable` · GRDB/SQLite · local-only · String Catalog i18n (zh-Hant primary; zh-Hans / en / ja / ko).

## Commands

```bash
# Core unit tests (GRDB layer)
cd GymFlowCore && swift test

# App build (simulator)
xcodebuild -project GymFlow.xcodeproj -scheme GymFlow \
    -destination 'platform=iOS Simulator,name=iPhone 16e' build

# UI golden-path
xcodebuild -project GymFlow.xcodeproj -scheme GymFlow \
    -destination 'platform=iOS Simulator,name=iPhone 16e' \
    -only-testing:GymFlowUITests test

# TestFlight archive → build/export/GymFlow.ipa
./scripts/archive.sh
```

## Layout

- `GymFlow/` — SwiftUI app. Features under `Features/` (Home, Session, Routines, ExerciseDetail, History, Onboarding, Settings).
- `GymFlowCore/` — local Swift package: GRDB models, repositories, migrations, seed data, PR calculator, formatters.
- `GymFlowUITests/` — XCUITest golden path.
- `PLAN.md` — product + architecture spec (authoritative, zh-Hant).
- `PLAN_PRO.md` — post-launch monetization plan (Freemium + IAP, gated on metrics; no ads).
- `docs/` — privacy policy, public site stubs.
- `scripts/archive.sh` — TestFlight archive + export helper.

## Conventions

- **i18n**: every user-visible string goes through `Localizable.xcstrings`. No hard-coded zh/en/ja/ko literals in views. Self-defined custom exercise names live in `customName` (user owns the language).
- **Weights**: stored in kg (`Double`). Display via `WeightFormatter` / `Measurement<UnitMass>`; respect user's `WeightUnit` setting. Step sizes: kg → 2.5, lb → 5.
- **IDs**: `UUID`. **Timestamps**: `Date` in UTC.
- **Architecture**: View ↔ `@Observable` ViewModel ↔ Repository ↔ GRDB. Constructor injection; only `AppDatabase` is a singleton.
- **PR types**: Weight PR / Reps-at-weight (2.5 kg buckets) / e1RM (Epley). Recompute per-exercise on set save.

## Review workflow

Every change goes through `/codex:review` (user-invoked). Do not confuse with `codex:rescue` (only for stuck/diagnosis hand-offs).

## Current state (2026-05-09)

App Store submission in flight under the Kintore rename:
- Bundle/scheme stay `GymFlow`; user-facing strings/icons are Kintore.
- HealthKit `NSHealthShareUsageDescription` + `NSHealthUpdateUsageDescription` are wired in Info.plist (required by App Store validation).
- v1.0 ships as pure free; Pro plan in `PLAN_PRO.md` is post-launch and metric-gated (≥500 active users, ≥20 reviews, ≥3 months data).
