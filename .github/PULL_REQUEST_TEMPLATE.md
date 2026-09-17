## What this changes

<!-- One or two sentences. If it closes an issue, write "Closes #123". -->

## How I verified it

<!-- Delete what does not apply. -->

- [ ] `cd GymFlowCore && swift test` passes
- [ ] App builds for the simulator
- [ ] Checked on screen in the simulator
- [ ] Checked the affected strings in a second language

## Screenshots

<!-- Required for anything that changes the UI. Before/after if you can. -->

## Checklist

- [ ] User-visible strings go through `Localizable.xcstrings` (no hard-coded literals)
- [ ] Weights are formatted through `WeightFormatter`, not by hand
- [ ] Schema changes are a new GRDB migration (no edits to shipped migrations)
- [ ] I agree my contribution is licensed under GPL-3.0
