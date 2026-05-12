# LiShu Verification Guide

Default policy: full verification is preferred before claiming a feature is done. If time or environment prevents full verification, record the exact reason and the strongest completed substitute in `.harness/progress.md` and `.harness/session-handoff.md`.

## Standard Commands

Use the harness wrapper:

```bash
./init.sh
scripts/harness/verify.sh quick
scripts/harness/verify.sh full
scripts/harness/verify.sh ui
scripts/harness/verify.sh release
```

Direct commands remain useful during debugging:

```bash
swiftformat --lint LiShu LiShuTests LiShuUITests --config .swiftformat
swiftlint lint --strict
xcodebuild -project LiShu.xcodeproj -scheme LiShu -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build
xcodebuild -project LiShu.xcodeproj -scheme LiShu -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -parallel-testing-enabled NO test -only-testing:LiShuTests
xcodebuild -project LiShu.xcodeproj -scheme LiShu -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -parallel-testing-enabled NO test -only-testing:LiShuUITests
```

## Verification Levels

### quick

Use while iterating or for narrow low-risk changes.

- SwiftFormat lint check
- SwiftLint strict
- Xcode build
- Relevant unit tests when obvious from touched files

### full

Default completion gate for most code changes.

- SwiftFormat lint check
- SwiftLint strict
- Xcode build
- All `LiShuTests`

### ui

Use for navigation, forms, accessibility identifiers, onboarding, import/export UI, screenshots, and user flow changes.

- All `LiShuUITests`
- For screenshot-specific work, use fastlane screenshot lane after UI tests pass.

### release

Use for release, App Store, screenshot, subscription, import/export, data migration, or broad UI work.

- `quick`
- `full`
- `ui`
- fastlane workflow as needed:
  - `fastlane ios screenshots`
  - `fastlane ios frameit`
  - `fastlane ios store_screenshots`
  - `fastlane ios ipa`

## Change-to-Test Mapping

- Models or SwiftData schema: unit tests for model behavior, old-data fallback, migration/normalizer behavior, import/export compatibility.
- ViewModels/services: targeted unit tests plus all affected module tests.
- Views/components: build, preview sanity where possible, UI tests for changed user flows.
- Navigation/sheets/routes: UI tests covering tab, push, sheet open/close, and deep flow.
- Localization: build plus manual key check in `Localizable.xcstrings`.
- Design system changes: build, affected screen UI tests, light/dark visual review where practical.
- OCR/XLSX/import/export: integration tests, fixture tests, round-trip tests.
- fastlane/screenshots: `fastlane ios screenshots` then `fastlane ios frameit` when asset output matters.

## Evidence Requirements

Record verification evidence with:

- Command run
- Result
- Date/time if relevant
- Failure summary or skipped reason
- Follow-up owner or next action

Do not claim "done" if verification is failing unless the failure is unrelated, documented, and accepted for the current task.
