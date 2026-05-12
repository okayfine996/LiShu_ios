# LiShu Harness Progress

## Current Focus

- Active feature: none.
- Last completed feature: `harness-001` Agent harness foundation.
- Goal completed: establish Codex + Claude shared harness files, state tracking, verification entrypoints, and lifecycle workflow.

## Recent Changes

- Created `docs/harness/PRODUCT.md`.
- Created `docs/harness/ARCHITECTURE.md`.
- Created `docs/harness/ENGINEERING_RULES.md`.
- Created `docs/harness/VERIFICATION.md`.
- Created `docs/harness/WORKFLOW.md`.
- Created `.harness/feature_list.json`.
- Created `.harness/progress.md`.
- Created `.harness/session-handoff.md`.
- Created `.harness/decisions.md`.
- Created `init.sh`.
- Created `scripts/harness/verify.sh`.
- Rewrote `AGENTS.md` and `CLAUDE.md` as short routing files.
- Updated default verification simulator to `iPhone 17 Pro Max` because local `iPhone 17 Pro` has duplicate simulator entries.
- Disabled Xcode parallel testing for harness unit/UI test modes.
- Deleted `LiShuTests/StatisticsViewModelTests.swift` per request.
- Updated `LiShuTests/TestHelpers.swift` so the shared in-memory test container uses `cloudKitDatabase: .none`.
- Fixed `LiShu/Utilities/LunarCalendarHelper.swift` lunar day naming by replacing formatter-dependent day output with an explicit Chinese lunar day map.

## Verification Evidence

- `./init.sh`: passed. It reported all required harness files present and all tools (`swiftformat`, `swiftlint`, `fastlane`) available. Xcode also reported a missing iOS 26.1 runtime bundle warning while still listing the project.
- `scripts/harness/verify.sh quick`: first run passed SwiftFormat and SwiftLint, then failed at `xcodebuild build` because the default `iPhone 17 Pro` destination matched two duplicate simulators. Updated the harness default destination to `iPhone 17 Pro Max`, which is unique on this machine.
- `scripts/harness/verify.sh quick`: passed after changing default destination to `iPhone 17 Pro Max`.
- `scripts/harness/verify.sh full`: first run passed SwiftFormat, SwiftLint, and build, then failed in `LiShuTests` with many 0-second failures on a cloned simulator. Updated unit/UI test commands to disable parallel testing.
- `scripts/harness/verify.sh full`: second run passed SwiftFormat, SwiftLint, and build, then failed in `LiShuTests`. The visible failing area was `StatisticsViewModelTests`, where the app repeatedly logged CloudKit setup failure `Unable to initialize without an iCloud account (CKAccountStatusNoAccount)` and the tests timed out waiting for `.loaded`. The run was interrupted after repeated restart/failure cycles.
- After deleting `StatisticsViewModelTests` and disabling CloudKit in `TestDB`, `scripts/harness/verify.sh full` no longer hits the Statistics/CloudKit failure path.
- `xcodebuild -project LiShu.xcodeproj -scheme LiShu -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -parallel-testing-enabled NO test -only-testing:LiShuTests/LunarCalendarHelperTests`: passed, 31 tests in 1 suite.
- `scripts/harness/verify.sh full`: passed SwiftFormat lint, SwiftLint, build, and 362 tests in 39 suites.

## Open Risks

- Xcode still prints a simulator runtime bundle warning for iOS 26.1, but build and tests pass on `iPhone 17 Pro Max`.

## Next Session Start

1. Read `AGENTS.md`.
2. Run `./init.sh`.
3. Pick or create the next active feature in `.harness/feature_list.json`.
4. Run the appropriate `scripts/harness/verify.sh` mode before changing app code.
