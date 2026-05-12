# LiShu Harness Decisions

This file records durable decisions that cannot be reliably derived from the codebase alone.

## 2026-05-12: Harness Target

- Decision: The harness serves both Codex and Claude.
- Consequence: `AGENTS.md` and `CLAUDE.md` should be short tool-specific routing files that link to shared docs under `docs/harness/`.

## 2026-05-12: Harness Structure

- Decision: Use a complete five-subsystem harness: instructions, state, verification, scope, and lifecycle.
- Consequence: Add persistent `.harness` state files and lifecycle scripts instead of relying only on static project rules.

## 2026-05-12: Verification Default

- Decision: Full verification is preferred before claiming completion.
- Consequence: Skipped or partial verification must be recorded with reason and replacement evidence.
