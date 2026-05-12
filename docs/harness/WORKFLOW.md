# LiShu Agent Workflow

This workflow applies to Codex, Claude, and any agent contributing to the repository.

## Startup

1. Read `AGENTS.md` or `CLAUDE.md`.
2. Run `./init.sh` unless the task is read-only and obviously small.
3. Read `.harness/feature_list.json` and identify `active_feature_id`.
4. Read `.harness/progress.md` and `.harness/session-handoff.md`.
5. Load only the docs needed for the task:
   - Product intent: `docs/harness/PRODUCT.md`
   - Technical shape: `docs/harness/ARCHITECTURE.md`
   - Coding rules: `docs/harness/ENGINEERING_RULES.md`
   - Verification: `docs/harness/VERIFICATION.md`

## Before Editing

- Inspect the relevant code first.
- Check `git status --short`.
- Identify the smallest implementation boundary that satisfies the task.
- If the work changes scope, update `.harness/feature_list.json` before broad edits.
- If the work reveals a durable product or architecture decision, add it to `.harness/decisions.md`.

## During Work

- Keep changes scoped to the active feature.
- Follow existing local patterns before introducing new abstractions.
- Keep UI aligned with DesignSystem and localization rules.
- Add or update tests proportional to risk.
- Do not undo user changes or unrelated work.

## Definition of Done

A task is done when:

- The requested behavior is implemented.
- Relevant tests are added or updated.
- Required localization keys exist.
- UI follows `DesignSystem` tokens and component styles.
- SwiftData compatibility is considered for model/storage changes.
- Verification has run according to `docs/harness/VERIFICATION.md`.
- `.harness/progress.md` and `.harness/session-handoff.md` are updated with evidence and restart instructions.

## End of Session

Before ending any non-trivial session:

1. Update `.harness/progress.md`.
2. Update `.harness/feature_list.json` status and verification fields if feature state changed.
3. Update `.harness/session-handoff.md` with touched files, verification evidence, blockers, and the next command to run.
4. Leave the repository restartable for the next agent.

## Scope Escalation

Ask or record an explicit decision before:

- Changing SwiftData schema in a non-additive way.
- Changing import/export wire formats without backward compatibility.
- Renaming localization keys used by UI tests.
- Changing fastlane screenshot flow or App Store release behavior.
- Reworking app navigation, route identity, or analytics log names.
- Introducing new dependencies.
