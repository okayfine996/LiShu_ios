# LiShu Product Context

LiShu is an iPhone-first relationship ledger for Chinese gift, favor, event, and social obligation tracking. It is built for users who need to remember what was given, received, returned, and maintained across weddings, birthdays, funerals, festivals, visits, favors, introductions, and daily relationship upkeep.

## Core Users

- 25-45 year old Chinese urban users managing family, relatives, friends, colleagues, and event-based social obligations.
- Users who need both financial memory and relationship memory, not only accounting totals.
- Pro users who benefit from OCR/import/export, reminders, smart return-gift suggestions, diagnostics, and richer analysis.

## Product Pillars

- **Relationship ledger**: Contacts, records, and events form the core loop.
- **Scenario memory**: Events encode context such as weddings, birthdays, festivals, visits, host/guest mode, and ledger receipt flows.
- **Reciprocity intelligence**: Net value, returned gifts, relationship health, smart return suggestions, and active/stale contacts help users decide what to do next.
- **Import/export trust**: OCR, XLSX import/export, screenshots, diagnostics, and App Store assets are part of the product quality surface.
- **Chinese cultural fit**: Lunar birthdays, traditional festivals, warm visual language, Chinese localization, and printable ledger scenarios matter.

## Current Business Modules

- **Home**: Dashboard snapshot, yearly income/expense, active contacts, recent records, upcoming events, stale contacts, host ledger events.
- **Contacts**: Contact CRUD, relationship category/circle, birthday/lunar support, detail timeline, import preview, exchange summary, cascade deletion.
- **Records**: Monetary, gift, favor, and banquet records; direction; returned gift logic; context tags; photos; daily interactions; OCR/import flows.
- **Events**: Event CRUD, event types, host/guest mode, host ledger receiving mode, smart return gift entry points, primary contact.
- **Statistics**: Overview, rankings, period/month/event-type/circle/record-type/heatmap details.
- **Import/Export**: XLSX/CSV-style selection previews, ledger import preview, contact import preview, export service, diagnostics archive.
- **Settings/Pro**: Subscription, appearance, notifications, data management, legal pages, diagnostic console.
- **Onboarding/Guide**: Splash, onboarding, guide mask tours, UI-test launch arguments.

## Active Roadmap Sources

- `PRD-v1.1.md`: P0 product requirements and acceptance criteria.
- `IMPLEMENTATION_PLAN.md`: staged engineering roadmap and proposed version sequencing.
- `.harness/feature_list.json`: active execution state. This is the source of truth for current feature status, not the PRD.

## Product Guardrails

- Do not change business semantics only to simplify implementation.
- Preserve backward compatibility for stored SwiftData records, import/export formats, and user defaults.
- Treat user-visible Chinese strings as localized product copy, not incidental implementation text.
- When product docs and code disagree, inspect current code first, then record any intended product decision in `.harness/decisions.md`.
