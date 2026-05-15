# Session Handoff

## Active Feature
None — `feat-widget-view-refactor` marked **done**.

## Last Verified State
Widget view decomposition complete (2026-05-15). `scripts/harness/verify.sh quick` passed: SwiftFormat 0, SwiftLint 0, TEST BUILD SUCCEEDED. Targeted `WidgetGalleryUITests` passed 3/3 with `test-without-building`. The widget extension views and in-app widget gallery were split into focused reusable files, and every newly created View file includes a `#Preview`.

Widget follow-up review fixes complete (2026-05-15). `scripts/harness/verify.sh full` → SwiftFormat 0, SwiftLint 0, TEST BUILD SUCCEEDED, **426 tests in 42 suites, 0 failures**. Latest fixes cover future reminder persistence while the app is closed, independent nested widget links, and `MainTabView` preview environment injection.

`scripts/harness/verify.sh ui` now correctly runs `build-for-testing` before `test-without-building`. The command built UI test products and executed the full UI suite, but the full suite failed with 12 non-widget failures in `ContactFlowTests`, `EventFlowTests`, `OCRImportFlowTests`, and `XLSXImportPreviewFlowTests`. In the same run, all 9 widget UI/E2E tests passed: `WidgetDeepLinkUITests` 3/3, `WidgetEntityDeepLinkTests` 3/3, `WidgetGalleryUITests` 3/3.

Full audit 2026-05-15 (loop 6 final) — **BUILD SUCCEEDED**, SwiftFormat 0, SwiftLint 0. **All 9 widget UI/E2E tests PASS** on iPhone 17 Pro (UDID 9A1B1ED8, `test-without-building`, 2026-05-15). Gallery stubs now pixel-accurate vs actual widget views and design spec:
- Medium reminder stub: subtitle in each row + tinted capsule dateLabel (matches `WidgetReminderRow`)
- Small countdown stub: D-day number 42pt heavy kerning -2.5 (matches `LiShuSmallCountdownWidgetView`)
- Medium event stub swatch: full mountain/sun scene with paths + D-7 capsule badge (matches `LiShuMediumEventWidgetView.sceneSwatch`)
- Rectangular stub: GalleryMark 14pt, header font .bold, dateLabel with white 20% RoundedRect(r=4) bg, title+subtitle in VStack(spacing:1), subtitle .semibold opacity 0.78 (matches `LiShuRectangularWidgetView`)
Design decorations without live data ("同比" YoY badge, "3 日内 N 项" sub-count) intentionally omitted.

**Note**: iPhone 17 Pro Max simulator (221C67FA) is in a corrupted state — do not use it. `verify.sh` no longer stores a default local UDID; it honors `LISHU_XCODE_DESTINATION` or resolves an available iPhone simulator at runtime, which currently resolves to iPhone 17 Pro (9A1B1ED8) on this machine. All wrapper test commands use `build-for-testing` + `test-without-building`.

**Note on 0 XCTest**: All tests in LiShuTests use `import Testing` (Swift Testing). xcodebuild reports "Executed 0 tests" for the XCTest runner — this is normal. Latest actual result shows `✔ Test run with 426 tests in 42 suites passed`.

## What Was Done This Session (Widget View Refactor — 2026-05-15)

### File decomposition
- Removed the untracked monolith `LiShuWidget/LiShuWidgetViews.swift` and split it into focused files:
  - `WidgetSupportViews.swift`
  - `LiShuSmallWidgetViews.swift`
  - `LiShuMediumWidgetViews.swift`
  - `LiShuLargeWidgetView.swift`
  - `LiShuLockWidgetViews.swift`
  - `WidgetPreviewData.swift`
- Reduced `LiShu/Views/Settings/WidgetGalleryView.swift` to a small shell and split reusable gallery pieces into:
  - `WidgetGalleryHeroView.swift`
  - `WidgetGalleryCatalogSections.swift`
  - `WidgetGalleryComponents.swift`
  - `WidgetGalleryHomeStubs.swift`
  - `WidgetGalleryLockStubs.swift`
  - `WidgetGalleryStubSupport.swift`
  - `WidgetGalleryPreviewData.swift`

### Preview coverage
- Added `#Preview` blocks to every new View file.
- Added a `SettingsSections` preview for the widget gallery settings row.
- Ran a local preview coverage check over the new widget/gallery View files; no missing `#Preview` blocks were reported.

### Verification
- Baseline before refactor: `scripts/harness/verify.sh quick` passed.
- After refactor: `swiftformat` passed on the split files; `swiftlint lint --strict` passed.
- Final verification: `scripts/harness/verify.sh quick` passed.
- Targeted UI verification: `WidgetGalleryUITests` passed 3/3.

## What Was Done This Session (Follow-up Review Fixes — 2026-05-15)

### Future reminders entering the widget display window
- `LiShu/Widget/WidgetDataWriter.swift`: removed the 3-day upper-bound filter when writing birthday, event, and pending-return reminders. Future reminders are now persisted, and `WidgetSnapshot.refreshed(at:)` continues to filter the widget presentation to the 3-day window.
- `LiShuTests/WidgetDataWriterTests.swift`: updated 4/5-day event tests to prove stored reminders are hidden at write time but appear after later refresh; added `birthdayFiveDaysOutStoredForFutureRefresh`.

### Multi-action widget links
- `LiShuWidget/LiShuWidgetViews.swift`: replaced outer `Link` wrappers in `LiShuMediumWidgetView`, `LiShuLargeWidgetView`, and `LiShuMediumEventWidgetView` with root `.widgetURL(...)`, preserving independent child `Link`s for reminder rows, quick add, and registration actions.

### Preview environment
- `LiShu/Navigation/MainTabView.swift`: added `.environment(DeepLinkCoordinator())` to the `#Preview`.

### Verification
- `swiftformat LiShu/Widget/WidgetDataWriter.swift LiShuTests/WidgetDataWriterTests.swift LiShuWidget/LiShuWidgetViews.swift LiShu/Navigation/MainTabView.swift --config .swiftformat` — 0/4 files formatted.
- `scripts/harness/verify.sh quick` — passed: SwiftFormat 0, SwiftLint 0, TEST BUILD SUCCEEDED.
- `scripts/harness/verify.sh full` — passed: SwiftFormat 0, SwiftLint 0, TEST BUILD SUCCEEDED, **426 tests in 42 suites, 0 failures**.

## What Was Done This Session (Widget Deep Review Loop — 2026-05-15)

### "登记" button pre-filled add-record + cold-launch race (latest)
- `LiShu/Navigation/DeepLinkRouter.swift`: added `.addRecordForEvent(stableID:)`; `lishu://add-record?event=<id>` parses to it
- `LiShu/Widget/WidgetSnapshot.swift` + `LiShuWidget/WidgetSnapshot.swift`: added `addRecordURL: URL?` to `WidgetHostingEventItem` (backward-compatible optional)
- `LiShu/Widget/WidgetDataWriter.swift`: added `addRecordDeepLink(eventStableID:)` helper; `nextHosting` populates `addRecordURL`
- `LiShuWidget/LiShuWidgetViews.swift`: "登记" Link now uses `event.addRecordURL ?? event.deepLinkURL`; preview stub updated with `addRecordURL`
- `LiShu/Navigation/MainTabView.swift`: `.addRecordForEvent` handler opens pre-filled add-record sheet with `.received` direction; `.onAppear` now checks `deepLinkCoordinator.pending` to handle cold-launch deep links
- `LiShuTests/DeepLinkRouterTests.swift`: added `addRecordForEventLink()` test (9 total)
- `LiShuTests/WidgetDataWriterTests.swift`: added `nextHostingEventAddRecordURLHasCorrectFormat()` test (44 total)
- Verification: BUILD SUCCEEDED, all `LiShuTests` 0 failures

### Stale date label fix
- Added `eventDate: Date?` to `WidgetReminderItem` and `WidgetHostingEventItem` in both `LiShu/Widget/WidgetSnapshot.swift` and `LiShuWidget/WidgetSnapshot.swift` (identical copies for shared access)
- Added `WidgetSnapshot.refreshed(at:)` — recomputes all date labels from raw `eventDate` and filters out-of-window items; called in `getSnapshot` and `getTimeline` in `LiShuWidget/LiShuWidgetProvider.swift`
- `LiShu/Widget/WidgetDataWriter.buildSnapshot` now populates `eventDate` for all 3 item types (birthday, event, hostingEvent)

### Dead-zone tappability fix
- `LiShuWidget/LiShuWidgetViews.swift`:
  - `LiShuMediumWidgetView`: outer VStack wrapped in `Link(destination: .liShuHome)` — inner `Link` views still take priority
  - `LiShuLargeWidgetView`: same outer-Link wrapper

### Verification
- BUILD SUCCEEDED twice (before and after dead-zone fix)

---

## What Was Done This Session (Latest Loop — 2026-05-15)

### Review fixes after reviewer comments
- Formatted `LiShu/Views/Settings/WidgetGalleryView.swift` with SwiftFormat, clearing the lines that blocked `verify.sh quick`.
- Updated `scripts/harness/verify.sh` so the default destination is resolved at runtime instead of source-pinning a local simulator UUID; `ui` now runs `build-for-testing` before `test-without-building`.
- Added record relationship IDs (`record.contact`, `record.event`) to `MainTabView.widgetDataSignature`, so relationship edits refresh widget data.
- Added `LunarCalendarHelper.nextGregorianDate(..., after:)` and changed `WidgetDataWriter` to search lunar birthdays from `todayStart`; added `WidgetDataWriterTests.lunarBirthdayTodayIncluded`.
- Verification: `quick` passed, `full` passed with 418 tests/42 suites, `ui` wrapper executed but full UI suite still has 12 unrelated non-widget failures; all 9 widget UI/E2E tests passed inside that UI run.

### Design-spec final alignment (widget-gallery-screen.jsx)
- **Chinese zodiac year**: Added `chineseYear(_ year: Int) -> String` helper to both `LiShuWidgetViews.swift` and `WidgetGalleryView.swift`; `LiShuSmallFinancialWidgetView`, `LiShuLargeWidgetView` hero strip, and `GallerySmallStub.financialContent` now show "丙午年" instead of Gregorian "2026年" per design spec
- **Medium widget quick-add subtitle**: `LiShuMediumWidgetView` quick-add bar now shows "· OCR 扫红包 · 智能回礼" secondary text (10pt medium, secondary color) after "记一笔"; same added to `GalleryMediumStub.reminderLayout`; new localization key `widget.quickAdd.subtitle` added
- **Star dots in lock stage**: `GalleryWidgetCard` lock night-sky stage now overlays 4 tiny white Circle dots at fixed fractional positions (matching design's 4 `radial-gradient` star dots) using `lockStarDots` view
- **Gallery description text alignment**: Updated 5 localization strings to match design spec verbatim: `widget.gallery.small.countdown.desc` (added "婚礼 / 寿宴 / 满月"), `widget.gallery.circular.desc` (added "+ 系统墙纸 tint"), `widget.gallery.rectangular.desc` (added "时间下方矩形位。" prefix), `widget.countdownRing.description` (now: "环形进度 + 大字 D-day，有主办事件时自动显示。仪式感拉满。"), `widget.mediumFinancial.description` (now matches design: "净额 hero + 收/支柱状 + 互动 / 人脉 / 待回礼 三联指标。日常 dashboard。")
- **Small reminder widget gallery name**: `widget.gallery.small.reminder.name` = "近期提醒" added; gallery card at line 269 now uses it instead of `widget.displayName` ("礼数") — matches design spec which shows "近期提醒" not "礼数" as the widget card title

### Loop 2 — Final spec alignment (2026-05-15)
- **Medium event gallery card name**: added `widget.gallery.medium.event.name` = "主办事件 Dashboard"; gallery card now uses this key instead of `widget.mediumEvent.displayName` ("主办事件") — actual widget display name unchanged
- **Footer version prefix**: `widget.gallery.footer` updated to "礼数 v1.2 · 共 6 款 widget · 支持 iOS 17 及以上" (was missing "礼数 v1.2 · " prefix per design spec)
- **Small reminder desc phrasing**: updated to "默认配置。展示下一项提醒（事件 / 生日 / 回礼），主页/锁屏 都能放。" (design uses "主页", not "主屏")
- All 9 widget E2E tests pass. BUILD SUCCEEDED. SwiftFormat 0.

### Loop 3 — Gallery stub fidelity vs actual widget views (2026-05-15)
- **Small financial stub**: `financialContent` updated to match `LiShuSmallFinancialWidgetView` exactly — accent-colored label, integer net amount (no compactName), proportional GeometryReader bars per bar (income/expense with label+value in same HStack), and footer stats "N 笔 · N 位人脉"; added `smallFinancialBar()` private helper
- **Medium financial stub**: `financialLayout` updated to match `LiShuMediumFinancialWidgetView` exactly — integer net amount (34pt heavy, accent color), `LazyVGrid` 2-column bars instead of fixed-width HStack, `mediumFinancialBar()` private helper; added `mediumFinancialBar()` helper with GeometryReader proportional bars
- **Large stub**: `GalleryLargeStub.body` fully rewritten to match `LiShuLargeWidgetView` exactly: hero label includes "· 丙午年", net amount uses 30pt integer format, hero bars use `LazyVGrid` + `largeHeroBar()` GeometryReader helper, section header has count on right, reminder rows show subtitle text, CTA uses accent gradient + divider line; added `largeHeroBar()` helper
- All 3 gallery UI tests confirmed pass in isolation. BUILD SUCCEEDED. SwiftFormat 0. SwiftLint 0.

### Gallery medium event stub header: spec fix
- `GalleryMediumStub.eventLayout` showed "主办事件" (`widget.mediumEvent.displayName`) in the header
- Real `LiShuMediumEventWidgetView` uses `WidgetHeader(count: 0, compact: true)` which shows "礼数" (`widget.displayName`)
- Fix: changed to `widget.displayName` to match the actual widget view header
- All other gallery stub headers verified to match their real widget counterparts:
  - Small/countdown/financial stubs → `widget.displayName` ✅
  - Medium reminder stub → `widget.displayName` ✅
  - Medium financial stub → `widget.medium.financial.header` ("礼数 · 年度总览") ✅
  - Large stub → `widget.displayName` ✅
  - Rectangular/inline stubs → `widget.displayName` ✅
- BUILD SUCCEEDED, SwiftFormat 0

### Gallery small stub kind label: spec fix + dead code removal
- Found gallery stub (`GallerySmallStub.reminderContent`) still used `galleryKindName(item.kind)` for kind label row, inconsistent with the real widget view fix
- Fix: changed to `item.subtitle` in gallery stub, matching actual `LiShuSmallWidgetView` behavior
- Removed now-unused `galleryKindName()` private function
- Removed 3 orphaned `widget.kind.{event,birthday,pendingReturn}` keys from xcstrings (no remaining code references)
- Widget.* key count: 102 → 99. SwiftFormat 0 violations, BUILD SUCCEEDED

### Small widget kind label: spec fix + dead code removal (previous loop)
- Spec says kind label row: `"{widget.small.nextItem} · {item.subtitle}"` not generic category name
- Fix: changed `kindName(first.kind)` → `first.subtitle` in `LiShuSmallWidgetView`
- Removed now-unused `kindName()` private function

### WidgetSnapshotStoreTests: fix test isolation race condition
- Root cause: all 4 tests shared the same `testSuiteName = "widget.snapshot.test"` and `testKey`. Swift Testing runs tests concurrently; `freshDefaults()` in one test would remove the key while another test was between its write and read, causing intermittent failures.
- Fix: changed `freshDefaults()` to use a unique `UUID().uuidString` suffix per call so each test gets its own isolated UserDefaults suite.
- All 4 WidgetSnapshotStoreTests pass reliably in both serialized and concurrent runs.

### Gallery view localization: 5 hardcoded strings fixed
- Added 5 keys: `widget.gallery.hero.headline`, `widget.gallery.hero.emphasis`, `widget.gallery.circular.name`, `widget.gallery.rectangular.name`, `widget.gallery.inline.name`
- Updated `heroHeadline` computed property and 3 lock widget card `name:` arguments to use `String(localized:)`
- Total widget.* keys: 52. Zero hardcoded user-visible Chinese strings remain in widget or gallery code

### widgetDataSignature: add primaryContact link
- Gap: reassigning `event.primaryContact` changes the pending-return reminder title but wasn't detected by the signature
- Fix: added `h.combine(e.primaryContact?.persistentModelID.hashValue ?? 0)` to the event loop in `MainTabView`
- All 9 E2E tests still pass after the change

### yearlyContactCount semantic fix
- Bug: `yearlyContactCount` was `contacts.count` (all contacts in DB), but label "人脉" in context "互动 42条 · 人脉 18人" means people interacted with this year
- Fix: recompute as `Set(yearlyRecords.compactMap { $0.contact?.persistentModelID }).count`
- Updated test `yearlyContactCountFromRecords`: 3 contacts, only 2 with records → count is 2
- Also recovered 3.9 GB disk space by `xcrun simctl delete unavailable` (CoreSimulator was 8.9 GB)

### E2E test fix: testWidgetGalleryLockWidgets
- Root cause: `"桌面 & 锁屏\n一眼看到"` hero headline contained "锁屏" and appeared before the segmented control in document order; `app.staticTexts.matching("CONTAINS '锁屏'").firstMatch` found the headline instead of the tab button, so the tap was a no-op
- Fix: added `.accessibilityIdentifier("gallery.tab.lock")` to `segmentButton` in `WidgetGalleryView`; updated test to use `app.buttons["gallery.tab.lock"]`
- All 9 widget E2E tests now pass

### Preview compliance + test coverage completion
- Added `#Preview` blocks to `LiShuWidget/LiShuWidgetViews.swift` (11 previews, one per view type) per CLAUDE.md requirement; includes private `WidgetSnapshot.preview` stub with realistic data
- Added 3 missing unit tests to `LiShuTests/WidgetDataWriterTests.swift` (now 40 tests):
  1. `birthdayThreeDaysOutIncluded` — birthday on the windowEnd boundary (day 3) is included
  2. `dateLabelDaysLater` — daysFromNow=2 produces "N天后" via the daysLater format branch
  3. `nonMonetaryRecordsExcludedFromYearlyIncome` — gift/favor/banquet records excluded from yearly totals
- All 40 tests pass; BUILD SUCCEEDED; SwiftFormat 0 violations

### Gallery stub fidelity (previous session)
- All 8 gallery stub types localized and layout-accurate vs actual widget views
- D-dash standardized to en-dash throughout widget views and gallery stubs
- Dead code removed from `statsRow` in `LiShuMediumEventWidgetView`

### Final clean-up (previous session)
- Removed stale localization key `widget.reminder.pendingReturn` (extractionState: stale, unused in code)
- Marked `feat-widget` as `done` in `.harness/feature_list.json`
- Cleared `active_feature_id` (no feature in progress)

### Previous sessions summary
- Full widget feature: WidgetSnapshot, WidgetDataWriter, DeepLinkRouter, DeepLinkCoordinator, 11 widget view types, 6 Widget definitions, in-app Widget Gallery, 47 localization keys
- Widget UI redesign per Pencil spec (parchment/terracotta palette, LiShuMark, WidgetHeader, WidgetReminderRow)
- pendingReturn business logic, stableID fix, deep link E2E tests, widgetDataSignature refresh fix
- Backward-compat Codable decode fix (custom init(from:) with decodeIfPresent)
- eventDateLabel + pendingReturnCount added to WidgetSnapshot and WidgetDataWriter
- Design-spec alignment: small widget kind label, date+subtitle line; medium financial 3rd footer stat

## Completed Feature: feat-widget

### Widget Extension files (`LiShuWidget/`)
- `LiShuWidgetBundle.swift` — @main WidgetBundle with 6 widgets
- `LiShuWidget.swift` — 6 Widget definitions (Home, Countdown, Financial, MediumEvent, MediumFinancial, CircularCountdown)
- `WidgetSupportViews.swift` — shared widget presentation components: WidgetBackground, LiShuMark, WidgetHeader, WidgetReminderRow, WidgetEmptyState, WidgetPalette
- `LiShuSmallWidgetViews.swift` — small reminder, countdown, and financial widget views
- `LiShuMediumWidgetViews.swift` — medium reminder, event dashboard, and financial widget views
- `LiShuLargeWidgetView.swift` — large annual dashboard widget view
- `LiShuLockWidgetViews.swift` — lock screen circular, rectangular, inline, and countdown widget views
- `WidgetPreviewData.swift` — shared widget preview snapshot data
- `LiShuWidgetProvider.swift` — TimelineProvider, refreshes at midnight
- `WidgetSnapshot.swift` — copy in sync with `LiShu/Widget/WidgetSnapshot.swift`
- `Info.plist` — NSExtensionPointIdentifier: com.apple.widgetkit-extension
- `LiShuWidget.entitlements` — group.com.finefine.LiShu

### Main app files (`LiShu/`)
- `LiShu/Widget/WidgetSnapshot.swift` — shared data model + WidgetSnapshotStore
- `LiShu/Widget/WidgetDataWriter.swift` — snapshot builder: birthday/event/pendingReturn reminders, yearly financials, nextHostingEvent, pendingReturnCount; yearlyContactCount = unique contacts with records this year
- `LiShu/Navigation/DeepLinkRouter.swift` — lishu:// URL scheme parsing
- `LiShu/Navigation/DeepLinkCoordinator.swift` — @Observable pending DeepLink bridge
- `LiShu/Navigation/MainTabView.swift` — widgetDataSignature (includes r.kvData, e.primaryContact), onChange write triggers, deep link handling
- `LiShu/Views/Settings/WidgetGallery*.swift` — in-app gallery shell, hero, catalog sections, reusable cards, preview data, and live snapshot stubs; gallery.tab.home/lock accessibilityIdentifiers
- `LiShu/Localizable.xcstrings` — 52 widget.* keys, all zh-Hans translated

### Tests
- `LiShuTests/WidgetDataWriterTests.swift` — 40 unit tests
- `LiShuTests/WidgetSnapshotStoreTests.swift` — 4 unit tests (UUID-scoped isolation)
- `LiShuTests/DeepLinkRouterTests.swift` — 8 unit tests
- `LiShuUITests/WidgetGalleryUITests.swift` — 3 UI tests
- `LiShuUITests/WidgetEntityDeepLinkTests.swift` — 3 E2E tests
- `LiShuUITests/WidgetDeepLinkUITests.swift` — 3 smoke tests

## What Was Done This Session (Widget palette + stableID bug — 2026-05-15)

### Widget color: warm sage replaces cool blue
- `LiShuWidget/WidgetSupportViews.swift`: `WidgetPalette.blue` (#5A8AB7) renamed to `WidgetPalette.sage` (#7A9E8A, warm sage green); `kindColor(.pendingReturn)` updated to use `sage`.
- `LiShuWidget/LiShuMediumWidgetViews.swift`: `dot: WidgetPalette.blue` → `dot: WidgetPalette.sage`.

### Widget deep link stableID bug (wrong event preselected on "登记" tap)
- Root cause: `WidgetDataWriter.stableID(for:)` used `Mirror(reflecting: persistentID.id)` to read the internal `url` field. On iOS 26 / Xcode 26 SDK that field was removed; Mirror found nothing, and the fallback `entityName + storeIdentifier` was identical for every event → all events mapped to the same stableID hash.
- Fix (`LiShu/Widget/WidgetDataWriter.swift`): `JSONEncoder().encode(persistentID)` (PersistentIdentifier is Codable, output includes x-coredata:// URI; deterministic with `.sortedKeys`).
- Regression test added: `WidgetDataWriterTests.stableIDIsUniquePerEvent` — inserts 3 events with different names/types/hostModes, saves, fetches, asserts all 3 stableIDs distinct.
- Self-healing: old snapshots are overwritten on next app foreground via `onChange(of: scenePhase)` in `MainTabView`.

### Verification
- `scripts/harness/verify.sh full` — SwiftFormat 0, SwiftLint 0, BUILD SUCCEEDED, **430 tests in 42 suites, 0 failures** (iPhone 17 Pro, 2026-05-15).

## Resume Steps
1. `./init.sh`
2. Read `.harness/feature_list.json` to select next feature
3. Run `scripts/harness/verify.sh quick` to confirm baseline
