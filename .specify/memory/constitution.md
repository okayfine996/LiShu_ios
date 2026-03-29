<!--
Sync Impact Report
Version change: none -> 1.0.0
Modified principles:
- Initial adoption
Added sections:
- Core Principles
- Engineering Standards
- Delivery Workflow
- Governance
Removed sections:
- None
Templates requiring updates:
- ✅ .specify/templates/plan-template.md
- ✅ .specify/templates/spec-template.md
- ✅ .specify/templates/tasks-template.md
- ✅ .specify/memory/constitution.md
- ⚠ pending: .specify/templates/commands/*.md (directory currently has no command files)
Follow-up TODOs:
- None
-->

# LiShu Constitution

## Core Principles

### I. Performance Budgets Are Product Requirements
All feature work MUST preserve a fast, stable iPhone experience. Plans and specs MUST
state the expected impact on cold start, list rendering, write latency, export time, and
animation smoothness whenever a change touches those areas. For LiShu, primary budgets
are: cold start under 2 seconds, single-record write under 500 ms, 1000-record list render
under 1 second, and primary interactions at 60 fps on supported devices. Work that risks
these budgets MUST include measurement, mitigation, and rollback notes before implementation.
Rationale: a bookkeeping app loses trust immediately when entry, browsing, or export feels slow.

### II. SwiftUI Views Stay Declarative and Maintainable
SwiftUI views MUST remain focused on rendering and user interaction binding only. Business
rules, derived workflows, complex queries, and side effects MUST live in `@Observable`
ViewModels, repositories, or services. ViewModels MUST NOT import SwiftUI. Reusable UI MUST
be extracted into components when duplicated, stateful, or body complexity grows beyond a
small screen-sized block. New navigation flows MUST integrate with the app's routing model
instead of introducing nested ad hoc stacks. Rationale: maintainability depends on clear
separation of concerns and predictable ownership of state.

### III. Design Tokens and Localization Are Mandatory
All user-facing UI MUST use `DesignSystem` tokens for colors, typography, spacing, radius,
and component styling. Hardcoded visual constants in views are forbidden unless a token
already exists and is reused through the design system. All user-visible strings MUST be
defined in `Localizable.xcstrings` and accessed through `String(localized:)`. New screens and
components MUST include `#Preview`, using in-memory model containers where data is required.
Rationale: consistent visuals, dark-mode safety, and localization discipline are core product
quality requirements, not cleanup work.

### IV. State and Data Must Have a Single Source of Truth
Persistent data MUST be modeled in SwiftData `@Model` types without UI logic. Derived values
must be computed from canonical data instead of duplicated mutable state. Any schema change
MUST document default values, migration behavior, and iCloud sync implications before coding.
Views MUST observe data through a single authoritative path and MUST NOT manually mirror the
same business state across multiple layers without justification. Recoverable failures MUST be
represented in state and surfaced to the user; `try!` and `fatalError` are forbidden outside
unrecoverable app bootstrapping. Rationale: bookkeeping, sync, and analytics features depend on
data integrity and deterministic updates.

### V. Verification Must Match User Risk
Every change MUST include verification evidence appropriate to its risk. New or changed UI
MUST have previews and a manual verification path. Changes to calculations, exports, imports,
migrations, reminders, or synchronization MUST add or update focused automated tests unless a
documented reason shows lower-cost verification is sufficient. Edited files MUST be checked for
linter or compiler issues when applicable. Performance-sensitive changes MUST be measured, not
assumed. Rationale: LiShu handles money-like records and relationship history, so silent
regressions are more expensive than small upfront verification effort.

## Engineering Standards

- The primary stack for this repository is `SwiftUI + SwiftData + StoreKit + UserNotifications`
  on `iOS 18+`.
- App architecture MUST follow `View -> ViewModel -> Model/Repository -> SwiftData/Service`.
- Complex fetches, aggregations, export formatting, OCR post-processing, and suggestion logic
  MUST live in services or repositories, not in view bodies.
- Asynchronous or heavy work MUST avoid blocking the main actor. Long-running work such as OCR,
  export generation, analytics aggregation, and report rendering MUST execute off the main UI
  path and publish results back safely.
- New feature flags, analytics events, and settings keys MUST use explicit naming and default
  values so rollout behavior is deterministic.
- Schema-affecting features MUST document migration path, empty-state behavior, and compatibility
  with existing exported data formats.
- New screens MUST define their loading, error, empty, and loaded states explicitly.
- Security- and privacy-sensitive changes MUST preserve local-first behavior and MUST not
  introduce remote data dependencies for core record entry without explicit approval.

## Delivery Workflow

- Every feature spec MUST define user stories, acceptance scenarios, edge cases, functional
  requirements, success criteria, and non-functional requirements tied to performance,
  maintainability, localization, and data integrity.
- Every implementation plan MUST pass a constitution check that covers:
  performance budget impact, MVVM ownership, design token usage, localization, migration/sync
  impact, verification strategy, and rollback or feature-flag strategy where relevant.
- Every task list MUST include work for previews/localization updates, migration handling when
  schemas change, and verification tasks proportional to user risk.
- Code review MUST reject changes that move business logic into views, introduce hardcoded
  strings or design constants, duplicate state, or skip validation of high-risk flows.
- When a principle must be violated, the plan MUST record the exception, why it is necessary,
  and which simpler alternative was rejected.

## Governance

This constitution supersedes conflicting local habits and applies to specs, plans, tasks, and
implementation work in this repository.

- Amendments MUST be made in writing and MUST include the changed principle or section, the
  reason for the change, and any template or workflow updates needed to keep the repository
  consistent.
- Versioning follows semantic versioning:
  - MAJOR for removing or redefining a principle in a backward-incompatible way.
  - MINOR for adding a principle, adding a mandatory section, or materially expanding
    enforcement.
  - PATCH for clarifications, wording improvements, and non-semantic template sync.
- Compliance review is mandatory for every feature plan and code review. Reviewers MUST confirm
  that constitution gates were addressed or explicitly waived with justification.
- The governing runtime guidance files for day-to-day development are `CLAUDE.md` and this
  constitution. When they diverge, the stricter rule applies until both are reconciled.

**Version**: 1.0.0 | **Ratified**: 2026-03-25 | **Last Amended**: 2026-03-25
