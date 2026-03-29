# Implementation Plan: Traditional Festival Reminders

**Branch**: `001-festival-reminders` | **Date**: 2026-03-29 | **Spec**: `/Users/fine/Downloads/LiShu/specs/001-festival-reminders/spec.md`
**Input**: Feature specification from `/specs/001-festival-reminders/spec.md`

## Summary

为首页新增一个独立的“传统节日提醒”能力，展示最近 3 个即将到来的内置传统节日，
并在节日前 1 天向“家人/亲属”联系人发送 1 条节日汇总通知。点击节日卡片后，直接
进入现有新建事件流程，并预填节日名称、事件类型和日期。技术上优先复用现有
`HomeView`、`HomeViewModel`、`NotificationManager`、`AddEventViewModel` 和设置页通知开关，
避免新增 SwiftData 持久化模型。

## Technical Context

**Language/Version**: Swift 6 / iOS 18+  
**Primary Dependencies**: SwiftUI, SwiftData, UserNotifications, Foundation Calendar APIs  
**Storage**: SwiftData for existing contacts/events, in-memory built-in festival catalog for festival definitions  
**Testing**: XCTest (`LiShuTests`) + XCUITest (`LiShuUITests`)  
**Target Platform**: iPhone on iOS 18+  
**Project Type**: Mobile app (single iOS application)  
**Performance Goals**: Preserve <2s cold start, keep home screen rendering smooth at 60 fps, avoid noticeable delay when loading festival cards, keep notification rescheduling linear to 7 built-in festivals  
**Constraints**: Local-first, no mandatory network dependency, reuse existing notification preferences, summarize contact names to 3 max, 1 notification per festival occurrence, use `DesignSystem` and localized strings only  
**Scale/Scope**: 7 built-in festivals, 3 home cards shown, family/relative contacts only, one quick-create entry point from home, no custom festival authoring in v1

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] Performance impact is documented with expected effect on cold start, write latency,
      list rendering, export/report generation, or an explicit statement that budgets are
      unchanged.
      Home screen gains one additional lightweight section backed by 7 in-memory festival definitions;
      no export path or record write path changes.
- [x] Ownership follows MVVM: views stay declarative, business logic lives in ViewModels,
      repositories, or services, and any exception is justified in Complexity Tracking.
      Festival calculation and reminder composition will live in dedicated services / view-model helpers,
      not in `HomeView`.
- [x] UI changes use `DesignSystem` tokens, add required localization keys, and specify
      `#Preview` coverage for new screens/components.
      New home cards and any quick-create affordance will use existing tokens and add preview coverage.
- [x] Data changes document SwiftData migration defaults, derived-state ownership, and iCloud
      sync or import/export compatibility impact.
      No persistent schema change is planned; festival data is derived at runtime from a built-in catalog.
- [x] Verification covers previews, lint/compiler checks, manual validation, and focused
      automated tests where calculations, exports, imports, notifications, sync, or migration
      logic changes.
      Tests will target festival date calculation, reminder summarization, home ordering, and prefill behavior.
- [x] Rollout risk is addressed through feature flags, safe defaults, or a rollback approach
      when the feature changes schema, critical entry flows, or monetized behavior.
      Feature can ship behind a runtime flag if needed; safe default is “cards visible, reminders obey existing toggles”.

## Project Structure

### Documentation (this feature)

```text
specs/001-festival-reminders/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── festival-reminders.md
└── tasks.md
```

### Source Code (repository root)

```text
LiShu/
├── App/
├── Models/
│   └── Event.swift
├── Navigation/
│   └── AppRouter.swift
├── ViewModels/
│   ├── AddEventViewModel.swift
│   └── HomeViewModel.swift
├── Views/
│   ├── Events/
│   │   └── AddEventView.swift
│   ├── Home/
│   │   └── HomeView.swift
│   └── Settings/
│       └── NotificationSettingsView.swift
├── Components/
├── Utilities/
│   └── NotificationManager.swift
└── Localizable.xcstrings

LiShuTests/
├── HomeViewModelTests.swift
├── AddEventViewModelTests.swift
└── AppSettingsTests.swift

LiShuUITests/
├── EventFlowTests.swift
└── SettingsFlowTests.swift
```

**Structure Decision**: 继续沿用现有单体 iOS 应用结构。实现将集中在 `HomeView/HomeViewModel`
展示层、`NotificationManager` 调度层、`AddEventViewModel/AddEventView` 预填入口，以及少量
导航与本地化更新；不新增新的应用子工程。

## Complexity Tracking

本次设计没有违反 constitution 的事项，无需额外复杂度豁免。
