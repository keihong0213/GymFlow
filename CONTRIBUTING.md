# Contributing to Kintore

Thanks for taking a look. Bug fixes, translation corrections, accessibility improvements and small features are all welcome.

## Before you write code

**Open an [issue](https://github.com/keihong0213/GymFlow/issues) first** so we can agree on scope. For a one-line fix (typo, wrong string, obvious crash) just send the pull request.

If you want somewhere to start, see issues labelled [`good first issue`](https://github.com/keihong0213/GymFlow/labels/good%20first%20issue).

## Setup

**Prerequisites:** macOS with Xcode 16+ (Swift 6 toolchain) and an iOS 17+ simulator. There is no third-party package manager and no network setup — dependencies resolve through Swift Package Manager, and the app is local-only.

```bash
git clone https://github.com/keihong0213/GymFlow.git
cd GymFlow

# Core unit tests (GRDB layer) — the fast loop
cd GymFlowCore && swift test && cd ..

# App build (simulator)
xcodebuild -project GymFlow.xcodeproj -scheme GymFlow \
    -destination 'platform=iOS Simulator,name=iPhone 16e' build

# UI golden path
xcodebuild -project GymFlow.xcodeproj -scheme GymFlow \
    -destination 'platform=iOS Simulator,name=iPhone 16e' \
    -only-testing:GymFlowUITests test
```

Both the core tests and the app build must pass before you open a pull request.

## Conventions

These are the ones that get flagged most often in review (the full list lives in [`CLAUDE.md`](CLAUDE.md)):

- **Localization:** every user-visible string goes through `Localizable.xcstrings`. No hard-coded zh / en / ja / ko literals in views.
- **Weights:** stored in kg as `Double`, displayed through `WeightFormatter`, which respects the user's unit setting. Never format a weight by hand.
- **Architecture:** View ↔ `@Observable` ViewModel ↔ Repository ↔ GRDB, with constructor injection. Views do not talk to the database.
- **Database changes:** schema changes go through a GRDB migration — never edit an existing migration that has shipped.
- **Tests:** logic that lives in `GymFlowCore` should come with a test. That package is where the fast feedback loop is.

## Pull requests

- Branch off `main`, keep the change focused, and describe what you changed and how you verified it.
- Reference the issue it closes.
- Screenshots (or a short screen recording) are very welcome for anything that changes the UI.
- By contributing, you agree your contributions are licensed under the project's GPL-3.0 license.

## Translations

The primary language is **zh-Hant**; **zh-Hans**, **en**, **ja** and **ko** are also maintained. Improvements to any locale are appreciated — including exercise names in the seed data, which are localized separately from the UI strings.

When adding or fixing a translation:

1. Edit `Localizable.xcstrings` (UI strings) or the exercise seed data (exercise names) — not both in the same PR if you can avoid it.
2. Check the string in the simulator with that language selected; several screens are tight, and a long translation can break the layout.

## Product spec

[`PLAN.md`](PLAN.md) (zh-Hant) is the authoritative product and architecture spec. Worth reading before any larger change, so a PR does not get rejected for going against a decision that is already written down.
