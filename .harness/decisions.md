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

## 2026-05-18: CI/CD 职责分工

- Decision: GitHub Actions 只负责 SwiftFormat + SwiftLint（快速 PR 反馈，< 2 min）；Xcode Cloud 负责编译、测试、TestFlight 发布。
- Consequence:
  - `.github/workflows/ci.yml` 不再运行 xcodebuild；去掉了 xcodebuild build/test 步骤。
  - `ci_scripts/` 目录提供 Xcode Cloud 生命周期 hook：`ci_post_clone.sh`（安装工具）、`ci_pre_xcodebuild.sh`（预留扩展）、`ci_post_xcodebuild.sh`（归档后 Periphery 扫描）。
  - Xcode Cloud 三个 workflow：`CI-PR`（PR 触发，Test LiShuTests）、`CI-Main`（main push，Test 全量）、`Release-TestFlight`（tag `v*` 触发，Archive + TestFlight）。
  - UISnapshotTests 不在 Xcode Cloud 中运行（固定设备 iPhone 17 Pro / iOS 26.1，CI 环境不保证可用）。
