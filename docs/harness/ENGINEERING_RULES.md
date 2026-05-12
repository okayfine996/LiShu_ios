# LiShu Engineering Rules

This file contains the shared rules for Codex, Claude, and human reviewers. `AGENTS.md` and `CLAUDE.md` should point here instead of duplicating the full rule set.

## Design System

All UI code must use `DesignSystem` tokens from `LiShu/DesignSystem/DesignTokens.swift`.

- Colors: use `DesignSystem.Colors.*`. Do not use `Color.red`, `Color("...")`, direct hex, or `Color(hex:)` in views.
- Typography: use `DesignSystem.Typography.*`. Do not use direct `.font(.system(size:))` in views except where an existing component token explicitly wraps SF Symbols sizing.
- Radius: use `DesignSystem.Radius.*`. Do not hard-code `.cornerRadius(20)` or similar values.
- Buttons: use `PrimaryButtonStyle()`, `SecondaryButtonStyle()`, or `GhostButtonStyle()`.
- Inputs: use `StandardTextFieldStyle()`.
- Light/dark mode is handled by tokens. Do not branch on `colorScheme` just to pick design colors.
- `Color(hexLight:hexDark:)` and `UIColor(hex:)` are for `DesignTokens.swift` internals.

## Localization

All user-visible strings must be in `LiShu/Localizable.xcstrings` and accessed with `String(localized:)`.

Key format:
- Use short dot-form keys: `module.scene.semantic`.
- Examples: `contact.list.empty`, `record.add.title`, `common.cancel`.

Allowed:
```swift
Text(String(localized: "contact.list.title"))
Button(String(localized: "common.save")) { ... }
```

Not allowed:
```swift
Text("联系人")
Button("保存") { ... }
```

Test-only strings, debug log labels, and non-user-visible identifiers may stay as literals when appropriate.

## Preview Requirements

Every View file should include a `#Preview`.

- Page-level previews that need SwiftData should inject an in-memory `ModelContainer`.
- Component previews should provide representative sample values.
- Preview helpers may live beside module views when they are only used for previews.

## MVVM Rules

- View: UI rendering and interaction binding only.
- ViewModel: `@Observable class`, owns state and business logic.
- Model: SwiftData `@Model`, data definition and domain-derived properties only.
- Repository/service: use when queries, aggregation, import/export, or side effects become complex.
- ViewModel should be held in views with `@State`.
- ViewModel should not import SwiftUI.

## SwiftData Rules

- Put each `@Model` class in `LiShu/Models/`.
- Declare relationships explicitly and choose delete rules deliberately.
- Keep UI logic out of models.
- Use `@Query` for simple list queries; use ViewModels/services for complex aggregation or cross-entity logic.
- For stored enum values, keep raw-value fallback behavior and test unknown/legacy values.
- Never use `try!` or `fatalError` for recoverable data errors. App bootstrap fatal errors are exceptional and must log first.

## View Composition

- Split when a view body exceeds about 40 lines, an interaction state is independent, or the block is reused in more than one place.
- Local page-only sections can be private computed properties or private structs.
- Cross-page reusable UI belongs in `LiShu/Components/`.
- Components receive data through parameters. They should not own `@Query` or `modelContext` unless the component is explicitly a data-aware container.

## Navigation Rules

- Use `AppRoute` and `SheetRoute` for app navigation.
- Register route destinations centrally in tab navigation.
- Avoid deep nested `NavigationStack` in production views.
- Keep route log names stable because they are analytics/diagnostics surface.

## Error and Loading Rules

- Use `LoadingState<T>` for asynchronous state where applicable.
- Views should render idle/loading/error/empty/loaded states explicitly.
- Use `EmptyStateView` and existing error state patterns for empty or failed screens.
- User-action validation failures should surface through alerts or inline validation, not silent failure.

## Scope Rules

- One feature at a time. Update `.harness/feature_list.json` before broad work starts.
- Do not refactor unrelated modules while implementing a feature.
- If existing code violates a rule outside the active work area, record it in `.harness/progress.md` instead of fixing it opportunistically.
- Never rewrite generated or fastlane-managed files unless the task targets that workflow.
