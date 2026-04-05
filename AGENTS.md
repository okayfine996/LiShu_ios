# Repository Guidelines

## Project Structure & Module Organization
`LiShu/` contains the iOS app target. Core areas are organized by responsibility: `App/` for app entry and settings, `Models/` for SwiftData models, `Services/` and `Utilities/` for app logic, `ViewModels/` for presentation state, `Views/` for feature screens, `Components/` for reusable UI, and `DesignSystem/` for shared tokens and styling. Assets and localized strings live in `LiShu/Assets.xcassets` and `LiShu/Localizable.xcstrings`. Unit tests are in `LiShuTests/`; UI and screenshot flows are in `LiShuUITests/`. Release automation and screenshot tooling live under `fastlane/`.

## Build, Test, and Development Commands
Use the shared `LiShu` scheme from the repository root.

Install tooling (once per machine): `brew install swiftlint swiftformat` (optional: `brew install pre-commit` for git hooks).

- `xcodebuild -project LiShu.xcodeproj -scheme LiShu -configuration Debug build` builds the app locally.
- `xcodebuild test -project LiShu.xcodeproj -scheme LiShu -destination 'platform=iOS Simulator,name=iPhone 16'` runs unit and UI tests.
- `xcodebuild test -project LiShu.xcodeproj -scheme LiShu -only-testing:LiShuTests` runs unit tests only.
- `make format` runs SwiftFormat on `LiShu/`, `LiShuTests/`, and `LiShuUITests/` (see `.swiftformat`).
- `make lint` runs SwiftLint with `--strict` (see `.swiftlint.yml`).
- `pre-commit install` enables the pre-commit hook that formats and lints **staged** Swift files before each commit (see `.pre-commit-config.yaml`). If install fails with `core.hooksPath` set, run `git config --show-origin --get-all core.hooksPath`, then `git config --unset-all core.hooksPath` (and `--global` if needed) so pre-commit can write `.git/hooks/pre-commit`.
- `fastlane ios screenshots` generates App Store screenshots from `LiShuUITests/AppStoreScreenshotTests.swift`.
- `fastlane ios ipa` creates a release IPA in `fastlane/build/`.

GitHub Actions (`.github/workflows/ci.yml`) runs SwiftLint and an `xcodebuild` simulator build on pushes and pull requests to `main`. Run `xcodebuild test` locally before opening a PR when you change behavior covered by tests.

## Coding Style & Naming Conventions
Follow Swift conventions already used in the codebase: 4-space indentation, `UpperCamelCase` for types, `lowerCamelCase` for properties and functions, and one primary type per file named to match the type, such as `HomeViewModel.swift`. Keep SwiftUI views small and compose shared UI in `Components/`. Put feature-specific screens under `Views/<Feature>/`. Formatting and baseline lint rules live in `.swiftformat` and `.swiftlint.yml` at the repo root; match those when editing Swift.

## Testing Guidelines
This project uses Swift Testing (`import Testing`) with `@Test` for most unit coverage, plus XCTest-based UI tests. Name test files after the subject under test, such as `HomeViewModelTests.swift` or `SettingsFlowTests.swift`. Add or update tests whenever models, view models, import/export, or navigation behavior changes. Prefer focused simulator runs during development, then run the full `xcodebuild test` command before opening a PR.

## Commit & Pull Request Guidelines
Recent history favors short, imperative commit subjects like `Fix Pulse diagnostics logging bootstrap` or `Add Pulse release diagnostics and unified logging`. Keep commits scoped to one change. PRs should include a concise summary, linked issue or requirement when applicable, test coverage notes, and screenshots for visible UI changes. Mention any fastlane, localization, or store asset updates explicitly.
