# LiShu Harness Progress

## Current Focus

- Active feature: None — `feat-widget-view-refactor` completed (2026-05-15)
- Last completed: widget view decomposition and preview coverage — Widget extension and in-app gallery split into focused files
- Pending: `scripts/harness/verify.sh ui` has 12 pre-existing non-widget failures in ContactFlowTests/EventFlowTests/OCR/XLSX — unrelated to widget work

### 2026-05-16 — Widget review fixes

**Review issues fixed:**
- `MainTabView.widgetDataSignature` now includes `Event.coverImage` count and data hash so editing/removing a hosting event cover image triggers `WidgetDataWriter.write(...)` while the app is active.
- Added `WidgetDataWriterTests.nextHostingEventCoverImagePathIsWritten` to verify hosting event cover data is written to an App Group file path for widget rendering.
- Replaced direct `Color(red:)`, `Color.white`/`Color.black`, and `.font(.system(...))` usage in main-app `WidgetGallery*.swift` files with existing `DesignSystem` color/typography tokens.
- Localized Widget Gallery size/spec labels (`Small`, `Medium`, `systemSmall · 158×158`, etc.) via new `widget.gallery.size.*` and `widget.gallery.spec.*` keys.

**Verification:**
- `jq empty LiShu/Localizable.xcstrings` — passed.
- `scripts/harness/verify.sh quick` — SwiftFormat 0, SwiftLint 0, TEST BUILD SUCCEEDED.
- `xcodebuild -project LiShu.xcodeproj -scheme LiShu -destination 'platform=iOS Simulator,id=9A1B1ED8-40F1-4A44-BED4-6D3CAD8FF45B' -parallel-testing-enabled NO test-without-building -only-testing:LiShuTests/WidgetDataWriterTests` — passed, 49 Swift Testing tests.

---

### 2026-05-15 — Widget view decomposition + preview coverage

**Widget extension split:**
- Removed the monolithic `LiShuWidget/LiShuWidgetViews.swift` file.
- Split it into focused files: `WidgetSupportViews.swift`, `LiShuSmallWidgetViews.swift`, `LiShuMediumWidgetViews.swift`, `LiShuLargeWidgetView.swift`, `LiShuLockWidgetViews.swift`, and `WidgetPreviewData.swift`.
- Shared support components (`WidgetBackground`, `LiShuMark`, `WidgetHeader`, `WidgetReminderRow`, `WidgetEmptyState`, URL helpers, palette/date helpers) now live in one reusable support file.

**In-app Widget Gallery split:**
- Reduced `LiShu/Views/Settings/WidgetGalleryView.swift` to a page shell.
- Moved gallery sections/components/stubs into `WidgetGalleryHeroView.swift`, `WidgetGalleryCatalogSections.swift`, `WidgetGalleryComponents.swift`, `WidgetGalleryStubSupport.swift`, `WidgetGalleryHomeStubs.swift`, `WidgetGalleryLockStubs.swift`, and `WidgetGalleryPreviewData.swift`.
- Added/kept representative `#Preview` blocks for every newly created View file; added a `SettingsSections.swift` preview because that file now owns the widget-gallery settings row.

**Verification:**
- Baseline before refactor: `scripts/harness/verify.sh quick` passed.
- During iteration: `swiftformat ... --config .swiftformat` formatted split files; `swiftlint lint --strict` passed; `xcodebuild -quiet ... build-for-testing` passed.
- Final: `scripts/harness/verify.sh quick` passed — SwiftFormat 0, SwiftLint 0, TEST BUILD SUCCEEDED.
- Targeted UI: `xcodebuild -project LiShu.xcodeproj -scheme LiShu -destination 'platform=iOS Simulator,id=9A1B1ED8-40F1-4A44-BED4-6D3CAD8FF45B' -parallel-testing-enabled NO test-without-building -only-testing:LiShuUITests/WidgetGalleryUITests` passed — 3 tests, 0 failures.

---

### 2026-05-15 — Widget follow-up review fixes: future reminders + nested links + preview env

**Future reminders stored before entering the display window:**
- Root cause: `WidgetDataWriter.buildSnapshot` only wrote reminders already within the 3-day display window. If the app was opened when an event/birthday was 4+ days away and then stayed closed, `WidgetSnapshot.refreshed(at:)` had no stored item to reveal later.
- Fix (`LiShu/Widget/WidgetDataWriter.swift`): birthday, event, and pending-return reminders are now persisted for future dates; `WidgetSnapshot.refreshed(at:)` remains the 3-day display filter used by the widget provider.
- Tests (`LiShuTests/WidgetDataWriterTests.swift`): updated 4/5-day event tests to assert future storage plus later refresh reveal; added `birthdayFiveDaysOutStoredForFutureRefresh`.

**Multi-action widget deep links:**
- Fix (`LiShuWidget/LiShuWidgetViews.swift`): removed outer `Link` wrappers from `LiShuMediumWidgetView`, `LiShuLargeWidgetView`, and `LiShuMediumEventWidgetView`; each now uses root `.widgetURL(...)` while child reminder-row/quick-add/registration `Link`s remain independent.

**Preview environment:**
- Fix (`LiShu/Navigation/MainTabView.swift`): `#Preview` now injects `.environment(DeepLinkCoordinator())`.

**Verification:**
- `swiftformat LiShu/Widget/WidgetDataWriter.swift LiShuTests/WidgetDataWriterTests.swift LiShuWidget/LiShuWidgetViews.swift LiShu/Navigation/MainTabView.swift --config .swiftformat` — 0/4 files formatted.
- `scripts/harness/verify.sh quick` — SwiftFormat 0, SwiftLint 0, TEST BUILD SUCCEEDED.
- `scripts/harness/verify.sh full` — SwiftFormat 0, SwiftLint 0, TEST BUILD SUCCEEDED, `✔ Test run with 426 tests in 42 suites passed`.

---

### 2026-05-15 — Widget deep review: reminderCount badge accuracy + backward-compat decode

**`reminderCount` badge accuracy fix:**
- Root cause: `buildSnapshot` stored only `items.prefix(5)` but `refreshed(at:)` computed `reminderCount` from those stored 5. If some expired overnight, the badge count shrank to ≤5 while the true uncapped total could be higher; items beyond position 5 were invisible to the refresh.
- Fix (`LiShu/Widget/WidgetDataWriter.swift`): removed `let totalCount` / `let capped = items.prefix(5)`; now stores `reminders: items` (all items, uncapped). Widget views already cap display with `.prefix(3)` and `.prefix(5)`.
- Fix (`LiShu/Widget/WidgetSnapshot.swift`, `LiShuWidget/WidgetSnapshot.swift`): `refreshed(at:)` now returns `reminders: updated` (no prefix cap); `reminderCount: updated.count` is now accurate because it reflects the full filtered list, not just the sub-set stored from a prior cap.
- Updated `WidgetDataWriterTests.capsAtFiveReminders` → `allRemindersStoredUnderNewPolicy`: asserts `reminders.count == reminderCount == 10`.

**Backward-compat decode test:**
- Added `WidgetSnapshotStoreTests.backwardCompatibleDecodeHostingEventWithoutAddRecordURL` (5 total): old JSON with `nextHostingEvent` but no `addRecordURL` decodes with `addRecordURL == nil`. All 5 pass.

**Verification:** BUILD SUCCEEDED, `WidgetDataWriterTests` 0 failures, `WidgetSnapshotStoreTests` 5/5 passed, full `LiShuTests` 0 failures

---

### 2026-05-15 — Widget deep review: "登记" button and cold-launch deep link race

**"登记" button incorrect destination (business correctness fix):**
- `LiShuMediumEventWidgetView.statsRow()` — "登记礼金" button previously linked to `event.deepLinkURL` (event detail), requiring 2 manual taps to add a record. Now routes directly to pre-filled add-record sheet.
- Added `addRecordURL: URL?` to `WidgetHostingEventItem` in both `LiShu/Widget/WidgetSnapshot.swift` and `LiShuWidget/WidgetSnapshot.swift` (backward-compatible optional; `refreshed(at:)` preserves it)
- `LiShu/Widget/WidgetDataWriter.swift` — added `addRecordDeepLink(eventStableID:)` helper; `nextHosting` now populates `addRecordURL: addRecordDeepLink(eventStableID: sid)`
- `LiShuWidget/LiShuWidgetViews.swift` — "登记" Link now uses `event.addRecordURL ?? event.deepLinkURL`
- `LiShu/Navigation/DeepLinkRouter.swift` — added `.addRecordForEvent(stableID:)` case; `lishu://add-record?event=<id>` parses to it; plain `lishu://add-record` still returns `.addRecord`
- `LiShu/Navigation/MainTabView.swift` — `handleDeepLink(.addRecordForEvent)` switches to events tab and opens `.addRecord(direction: .received, contactID: nil, eventID: event.persistentModelID)` sheet
- `LiShuTests/DeepLinkRouterTests.swift` — added `addRecordForEventLink()` test (9 total, all pass)

**Cold-launch deep link race fix:**
- `LiShu/Navigation/MainTabView.swift` `.onAppear` — added pending deep link check at top; if `deepLinkCoordinator.pending` is set when `MainTabView` first appears (e.g., after 1.5s splash), it is handled immediately rather than waiting for `@Query` count changes

**Additional:** Added `WidgetDataWriterTests.nextHostingEventAddRecordURLHasCorrectFormat` (test #44); updated preview stub in `LiShuWidgetViews.swift` with `addRecordURL`; full `LiShuTests` suite 0 failures.

**Verification:** BUILD SUCCEEDED, `DeepLinkRouterTests` 9/9 passed, `WidgetDataWriterTests` 44/44 passed, full `LiShuTests` 0 failures

---

### 2026-05-15 — Widget deep review round 6: currentYear label/data mismatch on year boundary

**Bug fixed: `refreshed(at:)` advanced `currentYear` without recomputing financial figures.**
- On New Year's morning, `getTimeline` would call `refreshed(at: Jan1_2027)`, updating `currentYear` to 2027 while `yearlyIncome`/`yearlyExpense`/counts remained from 2026
- Financial widgets would display "丙午年 (2027) 净额: +¥12800" with stale 2026 data
- Fix: changed `currentYear: cal.component(.year, from: now)` → `currentYear: currentYear` in `refreshed(at:)`, locking the label to the data's generation year until the app opens and calls `WidgetDataWriter.write()`
- Both `LiShu/Widget/WidgetSnapshot.swift` and `LiShuWidget/WidgetSnapshot.swift` updated (copies in sync)
- Added `WidgetSnapshotStoreTests.refreshedPreservesCurrentYear` (test #5; total: 6 tests)

**Verification:** `scripts/harness/verify.sh full` — SwiftFormat 0, SwiftLint 0, BUILD SUCCEEDED, **425 tests in 42 suites 0 failures**

---

### 2026-05-15 — Widget deep review round 5: giveGiftForEvent UI test

**Added `WidgetEntityDeepLinkTests.testGiveGiftForEventDeepLink`:**
- Covers the full E2E path for `lishu://add-record?event=<stableID>&direction=given`
- Creates an event, reads stableID from debug probe, cold-launches with the URL
- Asserts: events tab selected (`tab.events`) AND add-record sheet open (`record.add.saveButton`)
- SwiftFormat 0, SwiftLint 0, build clean

**Verification:** `scripts/harness/verify.sh quick` — BUILD SUCCEEDED, 0 lint errors

---

### 2026-05-15 — Widget deep review rounds 3–4: pendingReturn give-gift link + polish

**pendingReturn → give-gift direct action (business correctness):**
- `pendingReturn` reminder rows previously linked to `lishu://event?id=<id>` (event detail), requiring 2 taps to log a return gift
- Added `DeepLink.giveGiftForEvent(stableID:)` — parses `lishu://add-record?event=<id>&direction=given`; `DeepLink.addRecordForEvent` still handles `lishu://add-record?event=<id>` (no direction param)
- `WidgetDataWriter.buildSnapshot` now generates `giveGiftDeepLink(eventStableID:)` for `pendingReturn` items
- `MainTabView.handleDeepLink(.giveGiftForEvent)` opens add-record sheet with `direction: .given` and event pre-filled; `applyPrimaryContactBinding` auto-fills primary contact
- Added tests: `giveGiftForEventLink`, `addRecordForEventIgnoresUnknownDirection`, `pendingReturnDeepLinkUsesGiveGiftURL`

**Preview accuracy:**
- `LiShuWidget/LiShuWidgetViews.swift` preview pendingReturn item URL corrected to `lishu://add-record?event=3&direction=given`
- `WidgetGalleryView.sampleSnapshot` pendingReturn URL corrected; hosting event now has `addRecordURL`; SwiftLint force-unwrap replaced with URLComponents static properties

**Infrastructure:**
- Redundant inner `Link(.liShuHome)` wrapping heroStrip in `LiShuLargeWidgetView` removed
- `shortDateFormatter` in `WidgetDataWriter` promoted to `private static let` (was re-allocated on every `buildSnapshot` call, including the second inline formatter in the hosting-event block)
- All 30 widget localization keys confirmed present; `WidgetSnapshot.swift` both copies confirmed in sync

**Verification:** `scripts/harness/verify.sh full` — SwiftFormat 0 errors, BUILD SUCCEEDED, 424 tests in 42 suites 0 failures

---

### 2026-05-15 — Widget deep review: stale date labels + tappability dead zones

**Stale date label fix (`LiShu/Widget/WidgetSnapshot.swift`, `LiShuWidget/WidgetSnapshot.swift`, `LiShu/Widget/WidgetDataWriter.swift`, `LiShuWidget/LiShuWidgetProvider.swift`):**
- Added `eventDate: Date?` to `WidgetReminderItem` and `WidgetHostingEventItem` (backward-compatible optional fields)
- Added `WidgetSnapshot.refreshed(at:)` — filters past/out-of-window items and recomputes date labels from raw `eventDate` each time the widget renders at midnight
- `WidgetDataWriter.buildSnapshot` now populates `eventDate` on all birthday, event, and hosting-event items
- `LiShuWidgetProvider.getSnapshot` and `getTimeline` now call `.refreshed(at: .now)` so cached snapshots never show stale "明天" labels

**Dead-zone tappability fix (`LiShuWidget/LiShuWidgetViews.swift`):**
- `LiShuMediumWidgetView`: wrapped outer VStack in `Link(destination: .liShuHome)` — header area and empty-state area are now tappable to open the app; inner `Link` views (individual reminder rows, quick-add bar) still route to their own destinations
- `LiShuLargeWidgetView`: same outer-Link wrapper — WidgetHeader and "近期提醒" section header dead zones are now tappable

**Verification:** BUILD SUCCEEDED (both times, compiler only — no test run this session)

---

### 2026-05-15 — Review fixes for widget verification and refresh edge cases

**Review items fixed:**
- `LiShu/Views/Settings/WidgetGalleryView.swift` formatted with SwiftFormat; full SwiftFormat lint now reports 0 files requiring formatting.
- `scripts/harness/verify.sh` no longer pins the default destination to a checked-in local simulator UUID. It now honors `LISHU_XCODE_DESTINATION`, otherwise resolves an available iPhone simulator at runtime with `simctl`; this avoids both source-pinned UUIDs and duplicate simulator-name ambiguity.
- `scripts/harness/verify.sh ui` now runs `build-for-testing` before `test-without-building`, making UI verification self-contained on clean DerivedData.
- `LiShu/Navigation/MainTabView.swift` now includes each record's `contact` and `event` persistent IDs in `widgetDataSignature`, so changing a record relationship refreshes widget snapshots.
- `LiShu/Widget/WidgetDataWriter.swift` now calculates lunar birthday reminders from `todayStart` via a new `LunarCalendarHelper.nextGregorianDate(..., after:)` overload, so today's lunar birthday stays inside the 3-day window.
- Added `WidgetDataWriterTests.lunarBirthdayTodayIncluded` to cover the lunar birthday edge case.

**Verification:**
- Baseline before fixes: `scripts/harness/verify.sh quick` failed at SwiftFormat on `WidgetGalleryView.swift` lines 1293, 1301, 1608, 1609.
- `bash -n scripts/harness/verify.sh` — passed.
- `scripts/harness/verify.sh quick` — passed after fixes: SwiftFormat 0, SwiftLint 0, `build-for-testing` succeeded.
- `scripts/harness/verify.sh full` — passed: SwiftFormat 0, SwiftLint 0, build succeeded, `✔ Test run with 418 tests in 42 suites passed`.
- `scripts/harness/verify.sh ui` — wrapper behavior verified: it ran `build-for-testing` successfully before `test-without-building`; the full UI suite then failed with 12 failures in non-widget suites (`ContactFlowTests`, `EventFlowTests`, `OCRImportFlowTests`, `XLSXImportPreviewFlowTests`). During that run all widget UI/E2E suites passed: `WidgetDeepLinkUITests` 3/3, `WidgetEntityDeepLinkTests` 3/3, `WidgetGalleryUITests` 3/3.

---

### 2026-05-14 — Widget data refresh business logic fix

**Problem:** `MainTabView` only observed `allEvents.count`, `allContacts.count`, `allRecords.count` — so `WidgetDataWriter.write()` was NOT called when existing items' properties changed (e.g., editing a record's amount, changing an event's date, changing a contact's birthday). The yearly income/expense and countdown widgets would show stale data until the next app foreground.

**Fix — `LiShu/Navigation/MainTabView.swift`:**
- Added `widgetDataSignature: Int` computed property that hashes all widget-relevant stored properties: `record.amount/directionRaw/date/recordTypeRaw`, `event.date/hostModeRaw/name/typeRaw/location`, `contact.birthday/birthdayIsLunar/birthdayReminderEnabled/name`
- Added `.onChange(of: widgetDataSignature) { WidgetDataWriter.write(...) }` — fires on any property edit, not just add/delete
- Existing count-based observers kept for `guideMask.notifyDataChanged()` and `retryPendingDeepLink()` — double write on add/delete is idempotent

**Verification:** `scripts/harness/verify.sh quick` — BUILD SUCCEEDED

---

### 2026-05-14 — Widget UI redesign per Pencil design spec

**What changed in `LiShuWidget/LiShuWidgetViews.swift`:**
- Added local `WidgetPalette` enum: terracotta #B76E5A, gold #C5A065, blue #5A8AB7, parchment #F5EFE6, ink #2C2C2C
- Added `WidgetBackground` adaptive parchment gradient (light/dark)
- Added `LiShuMark` sub-view: rounded-rect with terracotta gradient + white 礼 character
- Redesigned `WidgetHeader`: 礼 mark + "礼数" + count badge (colored capsule)
- Redesigned `WidgetReminderRow`: colored dot (kind-based) + title + subtitle + date label capsule pill
- `LiShuSmallWidgetView`: focal layout — kind label + large title + urgency badge + "+N 项待办"
- `LiShuMediumWidgetView`: 3 reminders + "记一笔" quick-add bar with + icon and chevron
- `LiShuLargeWidgetView`: hero strip (net amount + income/expense bars) + "近期提醒" section + 5 reminders + full-width CTA
- `LiShuRectangularWidgetView`: 礼 mark + "礼数" + date badge at top; title + subtitle below
- `LiShuInlineWidgetView`: "礼数 · {name} · {dateLabel}" label

**`LiShuWidget/LiShuWidget.swift`:** containerBackground changed to `WidgetBackground()` (parchment gradient)

**`LiShu/Localizable.xcstrings`:** 4 new keys (widget.small.nextItem, widget.more.items, widget.reminders.sectionTitle, widget.netAmount) + updated widget.quickAdd → "记一笔", widget.reminderCount → "%d 项"

**Verification:** SwiftFormat 0 violations, SwiftLint 0 violations, BUILD SUCCEEDED

### 2026-05-14 — Widget entity deep link E2E tests + stableID fix

**Bug found & fixed in WidgetDataWriter:**
- `WidgetDataWriter.stableID(for:)` was using `String(describing: PersistentIdentifier)` which includes session-specific model container state — making stableIDs unstable across app launches, breaking the production widget deep link feature.
- Fixed: now uses `Mirror(reflecting: persistentID.id)` to extract the stable `x-coredata://` URI from `PersistentIdentifier.ID.url` via reflection.

**Production fix: MainTabView.handleDeepLink retry:**
- Added `retryPendingDeepLink()` — if `@Query allEvents` is empty when the deep link fires (t≈2.5s), the retry fires when allEvents.count changes, fixing a race condition.
- `handleDeepLink` now returns `Bool`; `deepLinkCoordinator.pending` is only cleared on success.

**New E2E tests (3/3 pass):**
- `LiShuUITests/WidgetEntityDeepLinkTests.swift` — 3 tests: event deep link, contact deep link, invalid ID no crash
- `LiShuUITests/BaseUITestCase.swift` — added `readStableIDFromMainView`, `readStableID`, `navigateToEventDetail`, `navigateToContactDetail`, `terminateAndRelaunchWithURL`
- `LiShu/Navigation/MainTabView.swift` — debug probes (gated by `--uitesting`): `debug.tab.{tab}`, `debug.event.sid.{id}.{name}`, `debug.contact.sid.{id}.{name}`, `debug.deeplink.{status}.{count}`
- `LiShu/Views/Events/EventDetailView.swift` — `event.detail.stableID.*` probe
- `LiShu/Views/Contacts/ContactDetailView.swift` — `contact.detail.stableID.*` probe

**Regression status:** 3 new widget entity tests pass, existing WidgetDeepLinkUITests pass. Pre-existing flaky failures unrelated to this work: EventFlowTests (data accumulation after many test runs), XLSXImportPreviewFlowTests (system tmpdir issue).

---

### 2026-05-15 — pendingReturn business logic + 9 new unit tests

**`LiShu/Widget/WidgetDataWriter.swift` — pendingReturn reminders implemented:**
- Guest events within the 3-day window that have no given records → now produce `kind: .pendingReturn` items (same logic as `HomeDashboardSnapshot.pendingReturnCount`)
- Title uses `"回礼 · {contact.name}"` format via `widget.pendingReturn.title` key when `event.primaryContact` is present
- Host events and guest events with existing given records remain `.event` kind
- Fixed `$1.amount` → `$1.monetaryAmount` in gift total calculation for `nextHostingEvent`

**`LiShu/Localizable.xcstrings` — 1 new key:** `widget.pendingReturn.title` = `"回礼 · %@"`

**`LiShuTests/WidgetDataWriterTests.swift` — 9 new tests (16 → 25 total):**
- `pendingReturnGeneratedForGuestEventWithNoGivenRecord` (test 17)
- `guestEventWithGivenRecordIsEventNotPendingReturn` (test 18)
- `kindPrioritySort` — birthday < event < pendingReturn within same day (test 19)
- `yearlyRecordCountCalculated` (test 20)
- `yearlyContactCountMatchesContacts` (test 21)
- `nextHostingEventGiftTotalCalculated` (test 22) — also exposed and fixed `.amount` → `.monetaryAmount` bug
- `nextHostingEventGuestCountCalculated` (test 23)
- `nextHostingEventIsNearestFuture` (test 24)
- `nextHostingEventNilWhenNoneExist` (test 25)

**`makeEvent` helper default:** changed `hostMode` default from `.guest` → `.host` to reflect intended semantics

**Verification:** `scripts/harness/verify.sh full` — 398 tests in 42 suites, all passed (2026-05-15)

---

### 2026-05-15 — 3 new widget types + in-app Widget Gallery screen

**New widget implementations (`LiShuWidget/LiShuWidgetViews.swift`):**
- `LiShuMediumEventWidgetView` — hosting event dashboard: left warm-terracotta scene swatch (mountain path + D-N badge), right info panel (已收礼 total + 到场宾客 count + 登记 button)
- `LiShuMediumFinancialWidgetView` — annual overview: net amount hero + 2-col income/expense grid + 互动/人脉 stat row
- `LiShuCircularCountdownWidgetView` — accessoryCircular countdown ring using `Gauge` with `.accessoryCircular` style (ring fills as event approaches)

**New Widget types registered (`LiShuWidget/LiShuWidget.swift`, `LiShuWidgetBundle.swift`):**
- `LiShuMediumEventWidget` — systemMedium, display name "主办事件"
- `LiShuMediumFinancialWidget` — systemMedium, display name "年度总览"
- `LiShuCircularCountdownWidget` — accessoryCircular, display name "主办倒计时环"

**`WidgetSnapshot` extended (`LiShu/Widget/WidgetSnapshot.swift`, `LiShuWidget/WidgetSnapshot.swift`):**
- Added optional `giftReceivedTotal: Double?` and `guestCount: Int?` to `WidgetHostingEventItem` (backward-compatible JSON)

**`WidgetDataWriter` updated (`LiShu/Widget/WidgetDataWriter.swift`):**
- `nextHosting` computation now also sums event monetary records received and counts unique guest contacts

**New in-app Widget Gallery screen (`LiShu/Views/Settings/WidgetGalleryView.swift`):**
- Full gallery per Pencil design spec: heroCard + segmented control (桌面/锁屏) + widget cards + HowToAdd accordion
- All widget previews use local private stub views (`GallerySmallStub`, `GalleryMediumStub`, `GalleryLargeStub`, `GalleryCircularStub`, etc.) — no cross-target dependency on widget extension views
- 21 new localization keys added to `LiShu/Localizable.xcstrings`

**Navigation wired:**
- `AppRoute.widgetGallery` added to `LiShu/Navigation/AppRouter.swift`
- Widget Gallery row added to Settings preferences section in `LiShu/Views/Settings/SettingsSections.swift`
- Route handled in `LiShu/Navigation/MainTabView.swift`

**Verification:** `scripts/harness/verify.sh quick` — SwiftFormat 0 violations, SwiftLint 0 violations, BUILD SUCCEEDED (2026-05-15)

---

### 2026-05-15 — Design-spec alignment: kind labels, eventDateLabel, pendingReturnCount

**`LiShu/Widget/WidgetSnapshot.swift` + `LiShuWidget/WidgetSnapshot.swift` (synced):**
- Added `var pendingReturnCount: Int = 0` to `WidgetSnapshot` (backward-compatible default)
- Added `var eventDateLabel: String?` to `WidgetReminderItem` (optional, backward-compatible)

**`LiShu/Widget/WidgetDataWriter.swift`:**
- Birthday and event reminder items now populate `eventDateLabel` ("M月d日" format, e.g. "1月3日")
- Added `pendingReturnCount` computation: guest events in current year with no given records (all year, not just 3-day window)
- `WidgetSnapshot` returned with `pendingReturnCount`

**`LiShuWidget/LiShuWidgetViews.swift`:**
- Added `kindName(_ kind: ReminderKind) -> String` helper: `.event`→"事件", `.birthday`→"生日", `.pendingReturn`→"回礼"
- Fixed `LiShuSmallWidgetView` kind label: now shows "下一项 · 事件" (kind category) instead of the item's subtitle
- Added date+subtitle line below title in small widget: "{eventDateLabel} · {subtitle}" (only shown when eventDateLabel is set)
- Added 3rd stat "待回礼 N笔" (blue dot) to `LiShuMediumFinancialWidgetView` footer, shown only when `pendingReturnCount > 0`
- Reduced footer stat spacing from 14 to 10 to fit 3 items

**`LiShu/Localizable.xcstrings` — 4 new keys:**
- `widget.kind.event` → "事件"
- `widget.kind.birthday` → "生日"
- `widget.kind.pendingReturn` → "回礼"
- `widget.stat.pendingReturn` → "待回礼"

**`LiShuTests/WidgetDataWriterTests.swift` — 4 new tests (26–29, total 29):**
- `pendingReturnCountForGuestEventsThisYear` — guest+no gift→1, guest+gift→0, host→0
- `pendingReturnCountExcludesPriorYear` — prior-year guest events excluded
- `eventDateLabelPopulatedForBirthday` — birthday item has "1月1日" eventDateLabel
- `eventDateLabelPopulatedForEvent` — event item has "1月2日" eventDateLabel

**Verification:** `scripts/harness/verify.sh full` — 402 tests in 42 suites, all passed (2026-05-15)

---

### 2026-05-15 — Backward-compat decode fix for pendingReturnCount

**Bug:** Old `WidgetSnapshot` JSON (without `pendingReturnCount` key) failed to decode — auto-synthesized `Codable` `init(from:)` called `container.decode(Int.self, forKey: .pendingReturnCount)` which threw `KeyNotFound`; the `try?` in `WidgetSnapshotStore.read()` caught it and returned `.empty`.

**Fix (`LiShu/Widget/WidgetSnapshot.swift` + `LiShuWidget/WidgetSnapshot.swift`):**
- Removed `= 0` default from `var pendingReturnCount: Int`
- Added custom `init(from decoder:)` using `decodeIfPresent` with `?? 0` fallback
- Added explicit memberwise `init` with `pendingReturnCount: Int = 0` default for all call sites

**Test:** `WidgetSnapshotStoreTests.backwardCompatibleDecodeWithMissingNewFields` now passes — old JSON correctly decodes with `pendingReturnCount == 0` and correct `reminderCount`.

**Verification:** `scripts/harness/verify.sh full` — **406 tests in 42 suites, all passed** (2026-05-15)

---

### 2026-05-15 — Gallery stubs aligned with design + Widget Gallery UI tests

**`LiShu/Views/Settings/WidgetGalleryView.swift`:**
- Updated `sampleSnapshot` with realistic data: `eventDateLabel` on all 3 reminder items, `pendingReturnCount: 4`, realistic subtitles (event type names, not location strings), sorted by urgency (today/tomorrow/后天)
- Added `galleryKindName(_ kind: ReminderKind) -> String` free function (mirrors widget's `kindName()`)
- Fixed `GallerySmallStub.reminderContent`: kind label now shows category name ("回礼", "生日", "事件") not subtitle; added eventDateLabel+subtitle date line; badge row shows overflow count
- Fixed `GalleryMediumStub.financialLayout`: added divider + stat row (互动 N笔 · 人脉 N位 · 待回礼 N笔) matching actual `LiShuMediumFinancialWidgetView`
- Added `galleryStatBadge(dot:label:value:unit:)` helper method

**`LiShuUITests/WidgetGalleryUITests.swift` (NEW):**
- `testWidgetGalleryNavigation` — Settings → Widget 介绍 renders nav bar + 桌面/锁屏 tab control
- `testWidgetGalleryHomeWidgets` — home tab shows systemSmall section header
- `testWidgetGalleryLockWidgets` — lock tab loads and shows accessoryCircular section header

**Verification:** `scripts/harness/verify.sh full` — 402 tests in 42 suites, all passed (2026-05-15)

---

---

### 2026-05-15 — Design-spec alignment: Chinese zodiac year + medium widget quick-add subtitle

**`LiShuWidget/LiShuWidgetViews.swift`:**
- Added `chineseYear(_ gregorianYear: Int) -> String` helper: converts Gregorian year to Chinese 干支 year string (e.g. 2026 → "丙午年") using standard 10 Heavenly Stems + 12 Earthly Branches calculation
- `LiShuSmallFinancialWidgetView` label: "礼金净额 · 2026年" → "礼金净额 · 丙午年" (matches design spec)
- `LiShuLargeWidgetView` hero strip label: same fix
- `LiShuMediumWidgetView` quick-add bar: added "· OCR 扫红包 · 智能回礼" secondary text (10pt medium weight, secondary color) matching design spec

**`LiShu/Views/Settings/WidgetGalleryView.swift`:**
- Added same `chineseYear` helper
- `GallerySmallStub.financialContent` label: uses `chineseYear` instead of `snapshot.currentYear`
- `GalleryMediumStub.reminderLayout` quick-add bar: added `widget.quickAdd.subtitle` secondary text

**`LiShu/Localizable.xcstrings`:**
- Added `widget.quickAdd.subtitle` = "· OCR 扫红包 · 智能回礼"

**Verification:** `scripts/harness/verify.sh quick` + unit tests — BUILD SUCCEEDED, **417 tests in 42 suites — all passed** (2026-05-15)

---

### 2026-05-15 — Widget palette warm-sage fix + stableID bug fix

**Widget color: `WidgetPalette.blue` → `WidgetPalette.sage`**
- `LiShuWidget/WidgetSupportViews.swift` (line 23, 34): replaced `static let blue = Color(red: 0.353, green: 0.541, blue: 0.718)` (#5A8AB7, cool blue) with `static let sage = Color(red: 0.478, green: 0.620, blue: 0.541)` (#7A9E8A, warm sage green); updated `kindColor() case .pendingReturn` to use `WidgetPalette.sage`.
- `LiShuWidget/LiShuMediumWidgetViews.swift` (line 346): updated `dot: WidgetPalette.blue` → `dot: WidgetPalette.sage`.
- Rationale: `blue` was the sole cool color in an otherwise warm earthy palette (rust #B76E5A, gold #C5A065, parchment #F5EFE6). Warm sage green retains semantic distinctiveness from accent and gold while harmonizing with the app's tone; carries a subtle celadon/jade resonance fitting for a Chinese gift-tracking app.

**Widget deep link stableID bug fix (wrong event preselected on "登记" tap)**
- Root cause: `WidgetDataWriter.stableID(for:)` used `Mirror(reflecting: persistentID.id)` to extract the `url` field from `PersistentIdentifier.ID`. On iOS 26 / Xcode 26 SDK the internal field was renamed/removed; Mirror returned no children matching `url`, so the fallback `entityName + storeIdentifier` was used — identical for all events in the same store, collapsing all stableIDs to the same hash.
- Fix (`LiShu/Widget/WidgetDataWriter.swift`): replaced Mirror reflection with `JSONEncoder().encode(persistentID)`. Since `PersistentIdentifier` conforms to `Codable`, the JSON-encoded form is deterministic and unique (includes the x-coredata:// URI). FNV-1a hash is computed over the JSON string.
- Regression test (`LiShuTests/WidgetDataWriterTests.swift`): added `stableIDIsUniquePerEvent` — inserts 3 events (different name, type, hostMode), saves, fetches, and asserts all 3 stableIDs are distinct. Guarded with `@MainActor`.
- Self-healing: old snapshots with collapsed stableIDs are overwritten on app foreground via the `onChange(of: scenePhase)` trigger in `MainTabView`.

**Verification:** `scripts/harness/verify.sh full` — SwiftFormat 0, SwiftLint 0, BUILD SUCCEEDED, **430 tests in 42 suites, 0 failures** (iPhone 17 Pro simulator, 2026-05-15)

---

## Recent Changes

### 2026-05-16 — Widget review follow-up fixes

**Review findings fixed:**
- `WidgetDataWriter.saveEventCoverImage` now writes cover data to `widget_event_cover_<stableID>` instead of one global App Group file, so refreshes/tests for different events no longer delete each other's cover artifact.
- `WidgetDataWriterTests` is marked `@Suite(.serialized)` because it intentionally exercises App Group file side effects; `nextHostingEventCoverImagePathIsWritten` remains covered.
- `WidgetGalleryCatalogSections` now uses a private `GalleryPreviewSize` enum for preview dimensions; localized size labels are display-only and no longer drive layout.
- Added Widget Gallery-specific `DesignSystem` color/typography tokens and moved gallery preview backgrounds, hero/card hierarchy, lock stubs, and key home stubs off direct colors/fonts while preserving widget-preview scale.

**Verification:**
- `scripts/harness/verify.sh quick` — SwiftFormat 0, SwiftLint 0, TEST BUILD SUCCEEDED.
- `xcodebuild ... test-without-building -only-testing:LiShuTests/WidgetDataWriterTests` — 49 Swift Testing tests passed.

### feat-widget — 完整实现 + review 修复

**Core data layer:**
- Created `LiShu/Widget/WidgetSnapshot.swift` — shared data model (WidgetSnapshot, WidgetReminderItem, WidgetSnapshotStore); removed WidgetKit import (bug fix)
- Created `LiShu/Widget/WidgetDataWriter.swift` — main-app engine: computes reminders within 3-day window, sorts, caps at 5, writes to App Group UserDefaults, calls WidgetCenter.reloadAllTimelines; fixed record.monetaryAmount (was record.amount), birthday subtitle dedup, force unwrap URLs

**Deep link routing:**
- Created `LiShu/Navigation/DeepLinkRouter.swift` — DeepLink enum, `lishu://` URL parsing
- Created `LiShu/Navigation/DeepLinkCoordinator.swift` — @Observable coordinator bridging widget taps to MainTabView

**App wiring:**
- Modified `LiShu/Info.plist` — added CFBundleURLTypes with `lishu` scheme
- Modified `LiShu/App/LiShuApp.swift` — inject DeepLinkCoordinator, call WidgetDataWriter on scenePhase .active, handle .onOpenURL, added --open-url= launch arg for UI tests
- Modified `LiShu/Navigation/MainTabView.swift` — DeepLinkCoordinator env, eventsPath/contactsPath NavigationPath, handleDeepLink (home clears paths — bug fix), WidgetDataWriter.write in all onChange handlers
- Modified `LiShu/Localizable.xcstrings` — 14 widget localization keys

**Widget extension files (require Xcode target setup):**
- Created `LiShuWidget/LiShuWidgetProvider.swift` — TimelineProvider, entry type
- Created `LiShuWidget/LiShuWidget.swift` — Widget configuration, LiShuWidgetEntryView with 6 families
- Created `LiShuWidget/LiShuWidgetViews.swift` — Small/Medium/Large/Circular/Rectangular/Inline views + shared sub-components; replaced force-unwrap URLs with private URL extensions; WidgetReminderRow made private
- Created `LiShuWidget/LiShuWidgetBundle.swift` — WidgetBundle

**Tests:**
- Created `LiShuTests/WidgetDataWriterTests.swift` — 16 unit tests (birthday/event/pendingReturn filtering, host mode, given record exclusion, yearly income/expense, date labels)
- Created `LiShuTests/WidgetSnapshotStoreTests.swift` — 3 round-trip tests
- Created `LiShuTests/DeepLinkRouterTests.swift` — 8 URL parsing tests (all branches)
- Created `LiShuUITests/WidgetDeepLinkUITests.swift` — 3 UI tests (home, addRecord, unknown URL)

## Verification Evidence

- `scripts/harness/verify.sh full` (2026-05-14): **389 tests in 42 suites — all passed**
  - SwiftFormat lint: passed
  - SwiftLint: passed
  - Build: passed
  - Unit tests: 389/389 passed (includes 27 new widget-related tests)

## Pending User Actions (Xcode UI)

The widget Swift files are on disk but require the user to set up the Xcode target:

1. **App Group on LiShu target**: LiShu → Signing & Capabilities → + App Groups → `group.com.finefine.LiShu`
2. **Create Widget Extension target**: File > New > Target → Widget Extension, name `LiShuWidget`, Bundle ID `com.finefine.LiShu.widget`, deployment iOS 17.0, uncheck "Include Configuration App Intent"
3. **App Group on LiShuWidget target**: same as step 1
4. **File Inspector memberships** — add to LiShuWidget target:
   - `LiShu/DesignSystem/DesignTokens.swift`
   - `LiShu/Localizable.xcstrings`
   - `LiShu/Widget/WidgetSnapshot.swift`
5. After setup: `scripts/harness/verify.sh quick` to verify both targets build
6. Test widget gallery in simulator (golden path + all 6 families)

## Open Risks

- Widget Extension target is not yet created — `LiShuWidget/` files need Xcode target before they build.
- `WidgetSnapshot.swift` needs dual target membership (LiShu + LiShuWidget).
- Widget UI is not manually tested yet (requires simulator widget gallery).

## Next Session Start

1. Check if user has completed Xcode UI steps above.
2. If yes, run `scripts/harness/verify.sh quick` and update `feat-widget` evidence.
3. Test widget gallery in simulator (golden path + all 6 families).
4. Update `feature_list.json` status to `done` if all acceptance criteria are met.
