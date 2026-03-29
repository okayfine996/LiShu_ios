# Feature Specification: Traditional Festival Reminders

**Feature Branch**: `001-festival-reminders`  
**Created**: 2026-03-29  
**Status**: Draft  
**Input**: User description: "实现这个功能@PRD-v1.1.md (40-45)"

## Clarifications

### Session 2026-03-29

- Q: 点击节日卡片后应如何进入创建流程？ → A: 进入新建事件页，并预填节日名称、事件类型和日期
- Q: 节日提醒通知中应显示多少联系人？ → A: 最多显示前 3 个联系人，其余显示为“等 X 人”
- Q: 首页应展示多少个即将到来的传统节日？ → A: 展示最近 3 个节日
- Q: 节日提醒应按什么粒度发送通知？ → A: 每个节日发送 1 条汇总通知，里面带联系人名单

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Upcoming Festivals (Priority: P1)

As a user, I want to see the nearest upcoming traditional festivals on the home screen so I
can prepare greetings and social obligations ahead of time.

**Why this priority**: This is the most visible part of the feature and delivers immediate value
even before reminders are enabled.

**Independent Test**: Open the home screen with calendar data available and verify that upcoming
traditional festivals are shown in chronological order with the remaining time until each festival.

**Acceptance Scenarios**:

1. **Given** the app has built-in traditional festival data, **When** the user opens the home
   screen, **Then** the user sees the nearest 3 upcoming festivals rather than a generic placeholder.
2. **Given** multiple festivals are upcoming, **When** the home screen is displayed, **Then**
   festivals are ordered from nearest to farthest.
3. **Given** a festival has already passed for the current year, **When** the user views the home
   screen, **Then** the next occurrence of that festival is used instead of the past date.

---

### User Story 2 - Receive Festival Reminders (Priority: P2)

As a user, I want to receive a reminder before a traditional festival with the names of close
contacts I should greet so I can maintain important relationships on time.

**Why this priority**: Reminders turn passive information into actionable follow-up and directly
support the product's relationship-management value.

**Independent Test**: Enable reminders, set up close contacts, simulate a date one day before a
supported festival, and verify that the reminder references the festival and relevant contacts.

**Acceptance Scenarios**:

1. **Given** reminders are enabled and at least one close contact exists, **When** the day before
   a supported traditional festival arrives, **Then** the user receives a reminder naming the
   festival and up to 3 relevant contacts to greet, with any remaining matches summarized.
2. **Given** reminders are enabled but no close contacts match the reminder scope, **When** the day
   before a supported traditional festival arrives, **Then** the user still receives a festival
   reminder without misleading or empty contact names.

---

### User Story 3 - Start a Festival Event Quickly (Priority: P3)

As a user, I want to tap an upcoming festival card and start creating a related event quickly so
I can capture plans or upcoming interactions without re-entering obvious festival details.

**Why this priority**: Quick entry reduces friction and ties reminders back into the core record
and event workflows.

**Independent Test**: Tap an upcoming festival card from the home screen and verify that the user
is taken directly into a festival-related event creation flow with relevant festival context.

**Acceptance Scenarios**:

1. **Given** an upcoming traditional festival is shown on the home screen, **When** the user taps
   the festival card, **Then** the user is taken to create a new related event with the selected
   festival name, event type, and event date already applied.

---

### Edge Cases

- What happens when there are fewer than three upcoming built-in festivals in the current calendar
  window? The system must continue searching into the next valid festival occurrences so the home
  screen still shows 3 nearest available entries.
- How does the system handle users who disable notifications? Festival cards remain visible on the
  home screen, but reminder delivery is skipped.
- What happens when there are many close contacts? The reminder must stay readable and prioritize a
  concise, representative list instead of overwhelming the user by naming at most 3 contacts and
  summarizing the remainder.
- What happens when a supported festival falls very close to year boundaries? The displayed and
  reminder dates must resolve to the next real occurrence, not the prior year's occurrence.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST maintain a built-in list of supported traditional festivals:
  Spring Festival, Lantern Festival, Dragon Boat Festival, Qixi Festival, Mid-Autumn Festival,
  Double Ninth Festival, and Lunar New Year's Eve.
- **FR-002**: The system MUST show the nearest upcoming traditional festivals on the home screen,
  including the festival name and the remaining time until the festival.
- **FR-002a**: The home screen MUST display exactly the nearest 3 upcoming supported traditional
  festivals.
- **FR-003**: The home screen festival list MUST be ordered from nearest upcoming festival to
  farthest upcoming festival.
- **FR-004**: The system MUST calculate each festival based on its next upcoming occurrence rather
  than using a past occurrence in the current year.
- **FR-005**: The system MUST send a reminder one day before each supported traditional festival
  when reminders are enabled.
- **FR-005a**: For each supported traditional festival occurrence, the system MUST send at most
  one reminder notification for that festival occurrence.
- **FR-006**: Festival reminders MUST target close contacts only, where close contacts are limited
  to the intimate relationship groups of family and relatives.
- **FR-007**: Festival reminders MUST include the festival name and MUST include relevant contact
  names when matching close contacts exist.
- **FR-007a**: When more than 3 close contacts match a festival reminder, the reminder MUST show
  no more than 3 contact names and summarize any additional matches as “等 X 人”.
- **FR-008**: When no close contacts match a festival reminder, the system MUST still send a valid
  festival reminder without blank or broken contact content.
- **FR-009**: Users MUST be able to tap an upcoming festival card and begin creating a related
  event from that context.
- **FR-010**: When a user starts event creation from a festival card, the new event flow MUST be
  pre-filled with the selected festival name, event type, and event date so the user does not need
  to reselect them manually.
- **FR-011**: The feature MUST use the app's existing reminder preference controls so users can
  suppress reminder delivery without losing access to home screen festival information.

### Non-Functional Requirements

- **NFR-001**: The home screen MUST continue to feel responsive; adding festival cards must not
  introduce noticeable delay when the user opens or returns to the dashboard.
- **NFR-002**: All new user-facing labels, reminder text, and festival names MUST follow the
  existing localization and presentation standards used throughout the app.
- **NFR-003**: Festival visibility, reminder logic, and quick event creation behavior MUST stay
  consistent across year boundaries and repeated app launches.
- **NFR-004**: Any new festival-related data or user choices MUST preserve compatibility with
  existing contact, event, and reminder records.
- **NFR-005**: The feature MUST be verifiable through home screen review, reminder validation, and
  an end-to-end event creation check from a festival card.

### Key Entities *(include if feature involves data)*

- **Traditional Festival**: A built-in cultural date with a name, recurring annual occurrence,
  relative position in the year, and reminder eligibility.
- **Festival Reminder**: A scheduled user-facing prompt tied to a specific festival occurrence and
  optionally enriched with relevant close contacts.
- **Close Contact Group**: The subset of the user's contacts that qualify for festival reminders
  because they belong to the family or relatives relationship groups.
- **Festival Event Draft**: A newly started event entry that inherits context from a selected
  upcoming festival.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In validation scenarios covering all supported festivals, 100% of festival cards show
  the correct next upcoming occurrence rather than a past occurrence.
- **SC-002**: At least 95% of evaluated reminder scenarios identify the correct festival day and
  reminder day across the supported festival list.
- **SC-003**: In usability validation, at least 90% of users can identify the next upcoming
  festival from the home screen within 5 seconds.
- **SC-004**: In end-to-end validation, at least 95% of users can start a festival-related event
  from a home screen festival card in no more than 2 taps.

## Assumptions

- Traditional festival coverage for this feature is limited to the seven built-in festivals named
  in the source requirement.
- Close-contact scope is limited to the intimate relationship groups already represented in the
  product as family and relatives.
- Existing reminder preferences remain the single control point for whether festival reminders are
  delivered.
- The feature is limited to showing upcoming festivals, sending reminder prompts, and launching a
  festival-related event flow; it does not add new festival editing or custom festival creation.
- The feature ships with safe defaults so that users without reminder permission still see festival
  information on the home screen.
