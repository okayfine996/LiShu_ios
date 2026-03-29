# Tasks: Traditional Festival Reminders

**Input**: Design documents from `/specs/001-festival-reminders/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Include test tasks because this feature changes date calculations, notification scheduling, and a cross-screen entry flow.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the shared runtime and test scaffolding required by this feature.

- [x] T001 Create festival domain scaffolding in `LiShu/Models/TraditionalFestival.swift`, `LiShu/Services/FestivalCalendarService.swift`, and `LiShu/Services/FestivalReminderService.swift`
- [x] T002 [P] Add baseline festival localization keys in `LiShu/Localizable.xcstrings`
- [x] T003 [P] Add deterministic festival date test helpers in `LiShuTests/TestHelpers.swift`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build shared festival calculation and reminder infrastructure that all user stories depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Implement `TraditionalFestivalDefinition`, `TraditionalFestivalOccurrence`, and `FestivalEventPrefill` in `LiShu/Models/TraditionalFestival.swift`
- [x] T005 Implement built-in 7-festival catalog and next-occurrence calculation in `LiShu/Services/FestivalCalendarService.swift`
- [x] T006 Implement close-contact filtering, 3-name summarization, and reminder body composition in `LiShu/Services/FestivalReminderService.swift`
- [x] T007 Extend `NotificationManager.Category` and add festival reminder scheduling/cancellation hooks in `LiShu/Utilities/NotificationManager.swift`
- [x] T008 Wire festival reminder rescheduling into existing notification settings and app-wide refresh flow in `LiShu/Utilities/NotificationManager.swift` and `LiShu/Views/Settings/NotificationSettingsView.swift`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - View Upcoming Festivals (Priority: P1) 🎯 MVP

**Goal**: Show the nearest 3 traditional festivals on the home screen in stable chronological order.

**Independent Test**: Launch the home screen and verify that exactly 3 upcoming traditional festival cards appear in chronological order with name, date, and remaining days.

### Tests for User Story 1 ⚠️

> **NOTE**: Write these tests first, ensure they fail before implementation

- [x] T009 [P] [US1] Add next-occurrence calculation coverage in `LiShuTests/FestivalCalendarServiceTests.swift`
- [x] T010 [P] [US1] Add home festival ordering and fallback coverage in `LiShuTests/HomeViewModelTests.swift`

### Implementation for User Story 1

- [x] T011 [US1] Add home-facing festival loading APIs and derived state in `LiShu/ViewModels/HomeViewModel.swift`
- [x] T012 [P] [US1] Create festival card UI with `#Preview` in `LiShu/Components/FestivalReminderCard.swift`
- [x] T013 [US1] Integrate the festival section into `LiShu/Views/Home/HomeView.swift`
- [x] T014 [US1] Add home festival section strings and festival name strings in `LiShu/Localizable.xcstrings`
- [x] T015 [US1] Add empty-state fallback and preview validation in `LiShu/Views/Home/HomeView.swift` and `LiShu/Components/FestivalReminderCard.swift`

**Checkpoint**: User Story 1 should render independently on the home screen without affecting existing upcoming events

---

## Phase 4: User Story 2 - Receive Festival Reminders (Priority: P2)

**Goal**: Send one aggregated reminder per festival occurrence, using close contacts only and compact contact-name formatting.

**Independent Test**: Enable notifications, simulate the day before a supported festival, and verify one reminder is scheduled with the correct festival name and up to 3 contact names plus summary text.

### Tests for User Story 2 ⚠️

- [x] T016 [P] [US2] Add reminder payload formatting and name summarization coverage in `LiShuTests/FestivalReminderServiceTests.swift`
- [x] T017 [P] [US2] Add festival reminder scheduling coverage in `LiShuTests/FestivalReminderNotificationTests.swift`

### Implementation for User Story 2

- [x] T018 [US2] Add festival reminder request building and one-notification-per-festival enforcement in `LiShu/Utilities/NotificationManager.swift`
- [x] T019 [US2] Connect `FestivalReminderService` outputs to notification scheduling and rescheduling in `LiShu/Utilities/NotificationManager.swift`
- [x] T020 [US2] Update notification settings wording and manual validation affordances in `LiShu/Views/Settings/NotificationSettingsView.swift` and `LiShu/Localizable.xcstrings`
- [x] T021 [US2] Add zero-contact fallback copy and localization coverage in `LiShu/Services/FestivalReminderService.swift` and `LiShu/Localizable.xcstrings`
- [x] T022 [US2] Add debug/manual test support for festival reminders in `LiShu/Utilities/NotificationManager.swift` and `LiShu/Views/Settings/NotificationSettingsView.swift`

**Checkpoint**: User Story 2 should schedule readable, deduplicated festival reminders without breaking existing event, birthday, or return-gift notifications

---

## Phase 5: User Story 3 - Start a Festival Event Quickly (Priority: P3)

**Goal**: Let users tap a home festival card and enter the existing add-event flow with name, type, and date prefilled.

**Independent Test**: Tap a festival card on the home screen and verify the app opens the existing add-event flow with festival name, `EventType.festival`, and festival date already filled.

### Tests for User Story 3 ⚠️

- [x] T023 [P] [US3] Add festival prefill mapping tests in `LiShuTests/AddEventViewModelTests.swift`
- [x] T024 [P] [US3] Add home-to-add-event flow coverage in `LiShuUITests/EventFlowTests.swift`

### Implementation for User Story 3

- [x] T025 [US3] Add add-event prefill routing support in `LiShu/Navigation/AppRouter.swift`
- [x] T026 [US3] Update `AddEventViewModel` to accept festival prefills while preserving editability in `LiShu/ViewModels/AddEventViewModel.swift`
- [x] T027 [US3] Update `AddEventView` initialization and load behavior for festival prefills in `LiShu/Views/Events/AddEventView.swift`
- [x] T028 [US3] Wire `FestivalReminderCard` taps to the add-event sheet flow in `LiShu/Views/Home/HomeView.swift`
- [x] T029 [US3] Add quick-create related localized copy and preview validation in `LiShu/Localizable.xcstrings` and `LiShu/Views/Events/AddEventView.swift`

**Checkpoint**: All user stories are independently functional and quick-create works from the home festival section

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, regression safety, and constitution compliance across all stories

- [x] T030 [P] Run the manual validation flow and capture final notes in `specs/001-festival-reminders/quickstart.md`
- [x] T031 [P] Add regression coverage for existing home upcoming events and reminder categories in `LiShuTests/HomeViewModelTests.swift` and `LiShuTests/FestivalReminderNotificationTests.swift`
- [x] T032 [P] Audit `DesignSystem`, localization, and `#Preview` completeness in `LiShu/Views/Home/HomeView.swift`, `LiShu/Components/FestivalReminderCard.swift`, and `LiShu/Views/Events/AddEventView.swift`
- [ ] T033 Measure and document home-screen and reminder-reschedule performance validation in `specs/001-festival-reminders/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup**: No dependencies - can start immediately
- **Phase 2: Foundational**: Depends on Phase 1 - blocks all user stories
- **Phase 3: User Story 1**: Depends on Phase 2
- **Phase 4: User Story 2**: Depends on Phase 2 and benefits from US1 home wiring being present for end-to-end validation
- **Phase 5: User Story 3**: Depends on Phase 2 and integrates with US1 home cards
- **Phase 6: Polish**: Depends on completion of all targeted user stories

### User Story Dependencies

- **US1 (P1)**: Can start after Foundational - no dependency on US2 or US3
- **US2 (P2)**: Can start after Foundational - independent reminder behavior, but final UX validation shares home section with US1
- **US3 (P3)**: Can start after Foundational - depends on the existence of tappable festival cards from US1 for end-to-end testing

### Within Each User Story

- Tests MUST be written and fail before implementation
- Previews and localization updates MUST ship with the same story as the UI change
- Shared data/service changes before UI wiring
- UI wiring before end-to-end validation
- Story checkpoint before moving to the next dependent story

### Parallel Opportunities

- `T002` and `T003` can run in parallel after `T001`
- `T005` and `T006` can proceed in parallel once `T004` is complete
- `T009` and `T010` can run in parallel
- `T012` and `T014` can run in parallel once `T011` has defined home-facing state
- `T016` and `T017` can run in parallel
- `T023` and `T024` can run in parallel
- `T030` through `T033` can run in parallel after feature completion

---

## Parallel Example: User Story 1

```bash
# Tests first
Task: "T009 [US1] Add next-occurrence calculation coverage in LiShuTests/FestivalCalendarServiceTests.swift"
Task: "T010 [US1] Add home festival ordering and fallback coverage in LiShuTests/HomeViewModelTests.swift"

# Then parallel UI work
Task: "T012 [US1] Create festival card UI with #Preview in LiShu/Components/FestivalReminderCard.swift"
Task: "T014 [US1] Add home festival section strings and festival name strings in LiShu/Localizable.xcstrings"
```

## Parallel Example: User Story 2

```bash
# Reminder validation in parallel
Task: "T016 [US2] Add reminder payload formatting and name summarization coverage in LiShuTests/FestivalReminderServiceTests.swift"
Task: "T017 [US2] Add festival reminder scheduling coverage in LiShuTests/FestivalReminderNotificationTests.swift"

# Supporting copy + manual validation wiring
Task: "T020 [US2] Update notification settings wording and manual validation affordances in LiShu/Views/Settings/NotificationSettingsView.swift and LiShu/Localizable.xcstrings"
Task: "T021 [US2] Add zero-contact fallback copy and localization coverage in LiShu/Services/FestivalReminderService.swift and LiShu/Localizable.xcstrings"
```

## Parallel Example: User Story 3

```bash
# Prefill routing + tests
Task: "T023 [US3] Add festival prefill mapping tests in LiShuTests/AddEventViewModelTests.swift"
Task: "T025 [US3] Add add-event prefill routing support in LiShu/Navigation/AppRouter.swift"

# ViewModel + View updates
Task: "T026 [US3] Update AddEventViewModel to accept festival prefills in LiShu/ViewModels/AddEventViewModel.swift"
Task: "T029 [US3] Add quick-create related localized copy and preview validation in LiShu/Localizable.xcstrings and LiShu/Views/Events/AddEventView.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Verify the home screen shows exactly 3 ordered festival cards
5. Demo the home dashboard improvement before adding notifications

### Incremental Delivery

1. Setup + Foundational create the reusable festival domain and scheduling base
2. Add US1 to deliver visible value on the home screen
3. Add US2 to turn the feature into an actionable reminder system
4. Add US3 to connect the reminder surface back to event creation
5. Finish with regression, preview, localization, and performance validation

### Parallel Team Strategy

With multiple developers after Phase 2:

1. Developer A: US1 home screen cards
2. Developer B: US2 reminder scheduling and notification copy
3. Developer C: US3 quick-create event entry
4. Rejoin for Phase 6 regression and final validation

---

## Notes

- [P] tasks = different files, no dependencies on incomplete work
- [US1], [US2], [US3] labels map directly to spec user stories
- Every story remains independently testable
- No SwiftData migration work is required for this feature
- Avoid mixing traditional festival cards into the existing `upcomingEvents` feed
