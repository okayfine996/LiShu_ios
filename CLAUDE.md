# CLAUDE.md

LiShu is an iPhone SwiftUI + SwiftData relationship-ledger app for Chinese gift, favor, event, and reciprocity tracking.

This file is the Claude routing layer. Keep it short; shared rules live under `docs/harness/`.

## Startup Workflow

Before writing code:

1. Run `./init.sh` unless the task is read-only and obviously small.
2. Read `.harness/feature_list.json` and identify `active_feature_id`.
3. Read `.harness/progress.md` and `.harness/session-handoff.md`.
4. Load the minimum relevant shared docs:
   - Product context: `docs/harness/PRODUCT.md`
   - Architecture context: `docs/harness/ARCHITECTURE.md`
   - Engineering rules: `docs/harness/ENGINEERING_RULES.md`
   - Verification guide: `docs/harness/VERIFICATION.md`
   - Workflow: `docs/harness/WORKFLOW.md`

## Non-Negotiable Rules

- Follow `docs/harness/ENGINEERING_RULES.md`.
- All UI styling must use `DesignSystem` tokens from `LiShu/DesignSystem/DesignTokens.swift`.
- All user-visible strings must be localized in `LiShu/Localizable.xcstrings` and accessed with `String(localized:)`.
- Every View file should include a `#Preview`.
- Use MVVM: SwiftUI views render and bind interactions; `@Observable` ViewModels own state and business logic.
- Treat SwiftData schema, import/export formats, and route identities as compatibility-sensitive.
- Work on one feature at a time and keep `.harness/feature_list.json` current.
- Do not revert or overwrite unrelated user changes.

## Required Artifacts

- `.harness/feature_list.json`: feature state and active feature.
- `.harness/progress.md`: current progress and verification evidence.
- `.harness/session-handoff.md`: restart instructions for the next session.
- `.harness/decisions.md`: durable product/architecture decisions not derivable from code.
- `docs/harness/`: shared product, architecture, rules, verification, and workflow context.

## Verification

Default policy is full verification before claiming a feature is done.

Preferred wrapper commands:

```bash
scripts/harness/verify.sh quick
scripts/harness/verify.sh full
scripts/harness/verify.sh ui
scripts/harness/verify.sh release
```

If full verification cannot be run, record the reason and substitute evidence in `.harness/progress.md` and `.harness/session-handoff.md`.

## Definition of Done

A non-trivial task is done when:

- Requested behavior is implemented.
- Relevant tests are added or updated.
- Localization and DesignSystem rules are satisfied.
- Verification evidence is recorded.
- `.harness/progress.md`, `.harness/feature_list.json`, and `.harness/session-handoff.md` are updated when feature state changed.

## End of Session

Before ending non-trivial work:

1. Update `.harness/progress.md`.
2. Update `.harness/feature_list.json` if status or verification changed.
3. Update `.harness/session-handoff.md` with touched files, verification run, blockers, and resume steps.
4. Leave the repository restartable.
