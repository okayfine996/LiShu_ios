# LiShu Architecture Context

LiShu is a SwiftUI + SwiftData iOS app with an MVVM-oriented structure and a broad test suite. The project uses an Xcode project with one shared scheme: `LiShu`.

## Stack

- Swift, SwiftUI, SwiftData
- iOS 18+ target assumptions, Xcode 26-era project settings
- Swift Testing and XCTest-based UI tests
- Package dependencies include Pulse, TelemetryDeck, swift-log, XLSX libraries, ZIP/XML helpers
- fastlane for screenshots, IPA/archive, frameit, and App Store upload workflows

## App Shell

- App entry is `LiShu/App/LiShuApp.swift`.
- The app creates a `ModelContainer` for `Contact`, `Record`, `Event`, and `RecordPhoto`.
- `--uitesting` skips onboarding and guide tours.
- fastlane snapshot mode uses an in-memory demo container and seeded data.
- Startup normalizers run for record type storage and event host mode.

## Data Model

- `Contact`: person metadata, relationship/circle, birthday/lunar flags, records, hosted events, monetary totals, non-financial count.
- `Event`: event type, host/guest mode, date/location/note, cover image, records, primary contact, host ledger helpers.
- `Record`: contact/event relationships, direction, record type, relationship weight, context tag, `kvData` JSON for type-specific data, returned gift logic, photos.
- `RecordPhoto`: external photo data tied to records.

SwiftData compatibility is a release risk. For model changes:
- Prefer additive optional/defaulted fields.
- Add normalizers/migration helpers when legacy columns or raw values exist.
- Add unit tests for old-data fallback and import/export compatibility.

## Navigation

- Routes live in `LiShu/Navigation/AppRouter.swift`.
- Main tabs live in `LiShu/Navigation/MainTabView.swift`: home, records, contacts, events, settings.
- Each tab owns a `NavigationStack` and registers `navigationDestination(for: AppRoute.self)`.
- Sheets use `SheetRoute` and centralized sheet construction in `MainTabView`.
- Avoid adding nested app-level `NavigationStack` inside feature views except for preview wrappers or modal-local navigation.

## View Architecture

- Views live under `LiShu/Views/<Module>/`.
- Reusable components live under `LiShu/Components/`.
- ViewModels live under `LiShu/ViewModels/` and use `@Observable`.
- ViewModels should not import SwiftUI. Use Foundation, SwiftData, and service dependencies.
- Shared utilities live under `LiShu/Utilities/`; design tokens live under `LiShu/DesignSystem/`.

## Service Layer

- Export/import logic is under `LiShu/Services/ExportService*` and XLSX helpers.
- Subscription and diagnostics services are app-level dependencies.
- AI/OCR and import preview flows have dedicated view models and tests.
- Keep service APIs deterministic and unit-testable; avoid burying business rules in SwiftUI views.

## Testing Surface

- `LiShuTests/` covers models, view models, import/export, diagnostics, OCR, relationship health, lunar calendar, subscriptions, statistics, and dashboard snapshots.
- `LiShuUITests/` covers major flows and App Store screenshots.
- `LiShuTests/TestHelpers.swift` provides in-memory SwiftData containers and sample records.
- UI tests use localized labels/constants in `LiShuUITests/UITestConstants.swift`.

## Architecture Risks

- SwiftData schema changes can break existing stores or CloudKit assumptions.
- `Record.kvData` is the source of truth for type-specific record data; old scalar columns remain fallback compatibility.
- Localization rules are strict. Hard-coded user-visible strings create product and UI-test drift.
- Design token rules are strict. Hard-coded UI styling makes light/dark and Stitch compliance regress.
- fastlane screenshot flows are sensitive to simulator naming and snapshot setup order.
