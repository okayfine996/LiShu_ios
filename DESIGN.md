# LiShu (礼数) — Design System

> iOS gift-ledger app. Warm terracotta + parchment palette. Clean, intimate, and trustworthy.  
> All tokens live in `LiShu/DesignSystem/DesignTokens.swift` under the `DesignSystem` namespace.

---

## 1. Visual Theme & Atmosphere

LiShu is a personal relationship ledger — it handles intimate financial records tied to human connections, so the visual language is **warm, calm, and trustworthy**. The palette is parchment-based (warm off-whites and tans) accented with terracotta (`#B76E5A`) and antique gold (`#C5A065`), evoking traditional Chinese bookkeeping aesthetics with modern mobile clarity.

The design density is **medium-low**: generous whitespace, rounded cards, subtle borders, and no harsh contrasts. Dark mode inverts to warm near-blacks rather than cool grays, maintaining the same intimate atmosphere. Interactions are restrained — scale animations on press only, no gratuitous motion.

---

## 2. Color Palette & Roles

All colors auto-adapt Light/Dark via `Color(hexLight:hexDark:)`. **Never hard-code hex values in view code.**

### Accent

| Token | Light | Dark | Role |
|-------|-------|------|------|
| `DesignSystem.Colors.primary` | `#B76E5A` | `#B76E5A` | Primary brand — terracotta. Buttons, active states, key icons |
| `DesignSystem.Colors.accentGold` | `#C5A065` | `#C5A065` | Gold accent — income amounts, secondary highlights |

### Backgrounds (layered, light → dark)

| Token | Light | Dark | Role |
|-------|-------|------|------|
| `DesignSystem.Colors.bgPage` | `#F5EFE6` | `#1C1B19` | Full-screen page background |
| `DesignSystem.Colors.bgCard` | `#E8DDD1` | `#262422` | Card / surface L1 |
| `DesignSystem.Colors.bgInput` | `#ECE3D7` | `#2E2B29` | Input fields, list item rows, subtle surface |
| `DesignSystem.Colors.bgTag` | `#D9CFC4` | `#363330` | Tags, chips, secondary button background (dark) |
| `DesignSystem.Colors.bgSurface` | `#FFFFFF` | `#2A2220` | Pure surface — modal sheets, overlay cards |
| `DesignSystem.Colors.bgIconSubtle` | `#F5F0EB` | `#2E2B29` | Icon tray background (circle behind SF Symbol) |

### Pro Gradient

| Token | Light | Dark |
|-------|-------|------|
| `DesignSystem.Colors.proGradientStart` | `#FFFCF5` | `#2A2220` |
| `DesignSystem.Colors.proGradientEnd` | `#FFF7E6` | `#3A2E25` |

Usage: `LinearGradient(colors: [DesignSystem.Colors.proGradientStart, DesignSystem.Colors.proGradientEnd], ...)`

### Borders & Separators

| Token | Light | Dark | Role |
|-------|-------|------|------|
| `DesignSystem.Colors.border` | `#D9CFC4` | `#3D3935` | Card strokes, field outlines |
| `DesignSystem.Colors.separator` | same as border | same | List dividers |

Use at `opacity(0.3)` for subtle strokes, full opacity for prominent dividers.

### Text

| Token | Light | Dark | Role |
|-------|-------|------|------|
| `DesignSystem.Colors.textPrimary` | `#2C2C2C` | `#E6E1DC` | Body copy, headings, primary content |
| `DesignSystem.Colors.textSecondary` | `#7A746E` | `#ABA59F` | Labels, metadata, captions |
| `DesignSystem.Colors.textTertiary` | `#ABA59F` | `#7A746E` | Timestamps, placeholder-like hints |
| `DesignSystem.Colors.textOnPrimary` | `#FFFFFF` | `#FFFFFF` | Text on terracotta backgrounds |

### Semantic

| Token | Role |
|-------|------|
| `DesignSystem.Colors.income` | Alias for `accentGold` — income/inflow amounts |
| `DesignSystem.Colors.destructive` | `#E53935` / `#EF5350` — delete, warning actions |
| `DesignSystem.Colors.overlayDark` | Full-screen overlays (image viewer, etc.) |

---

## 3. Typography Rules

Font: **SF Pro** (system default). No custom typeface. All tokens in `DesignSystem.Typography`.

| Token | Size | Weight | Role |
|-------|------|--------|------|
| `DesignSystem.Typography.display` | 48pt | Bold | Large hero numerics (summary totals) |
| `DesignSystem.Typography.title1` | 28pt | Bold | Page main title |
| `DesignSystem.Typography.title2` | 22pt | Bold | Section headers |
| `DesignSystem.Typography.title3` | 20pt | Semibold | Card titles, sub-section headers |
| `DesignSystem.Typography.body` | 16pt | Regular | Body copy, list item primary text |
| `DesignSystem.Typography.caption` | 14pt | Medium | Captions, button labels, field text |
| `DesignSystem.Typography.small` | 11pt | Medium | Timestamps, tags, metadata |

Rules:
- Button labels always use `caption` + `fontWeight(.semibold)`
- Amount/number emphasis: `display` or `title1` in `textPrimary` (expenses) or `accentGold` (income)
- Never use `.font(.system(size:))` directly in views

---

## 4. Component Stylings

### Buttons

**Primary** — `.buttonStyle(PrimaryButtonStyle())`
- Capsule shape, `primary` fill, white text (`caption` semibold)
- Padding: 12pt vertical / 24pt horizontal, `frame(maxWidth: .infinity)`
- Shadow: `primary.opacity(0.2)` light / `black.opacity(0.3)` dark, radius 8, y 4
- Press: scale 0.95, `easeOut(0.2s)`

**Secondary** — `.buttonStyle(SecondaryButtonStyle())`
- Capsule shape, `bgCard` fill (light) / `bgTag` fill (dark)
- `primary` text, 1pt stroke at `primary.opacity(0.2)`
- Same press animation as Primary

**Ghost** — `.buttonStyle(GhostButtonStyle())`
- No background, `textSecondary` text
- Press reveals `textSecondary.opacity(0.1)` fill

### Cards

**Standard Card**
```swift
.padding(DesignSystem.Spacing.cardPadding)         // 20pt
.background(DesignSystem.Colors.bgCard)
.cornerRadius(DesignSystem.Radius.card)            // 20pt
.overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
    .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1))
```

**Hero Card** (dashboard summary)
```swift
.padding(DesignSystem.Spacing.heroCardPadding)     // 24pt
.background(DesignSystem.Colors.bgCard)
.cornerRadius(DesignSystem.Radius.card)            // 20pt
```

**List Item Row**
```swift
.padding(DesignSystem.Spacing.cardPaddingSmall)    // 16pt
.background(DesignSystem.Colors.bgInput)
.cornerRadius(DesignSystem.Radius.smallCard)       // 14pt
.overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
    .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1))
```

### Inputs

**TextField** — `.textFieldStyle(StandardTextFieldStyle())`
- Padding: 12pt vertical / 16pt horizontal
- Background: `bgSurface`, radius `input` (12pt)
- Border: 1pt `border` stroke
- Font: `caption`

**Form Label** (above field)
- Font: 12pt medium, color `textSecondary`, padding-leading 4pt

### Icon Trays

```swift
ZStack {
    Circle()
        .fill(DesignSystem.Colors.primary.opacity(0.1))  // or bgIconSubtle
        .frame(width: 48, height: 48)
    Image(systemName: "...")
        .foregroundColor(DesignSystem.Colors.primary)
        .font(.system(size: 20))
}
```

### Tags / Chips

- Background: `bgTag`, radius `tag` (8pt)
- Text: `small`, `textSecondary`
- Selected: `primary.opacity(0.1)` bg + `primary.opacity(0.3)` border

### Selected Row State

```swift
.background(DesignSystem.Colors.primary.opacity(0.1))
.cornerRadius(DesignSystem.Radius.smallCard)
.overlay(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
    .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1))
```

### Avatar

- Size M: 56pt (`DesignSystem.Layout.avatarM`) — contact/event list rows
- Shape: Circle, background `bgInput`

### Charts

- Bar chart height: 160pt (`DesignSystem.Layout.statisticsBarChartHeight`)
- Bar corner radius: 2pt (`DesignSystem.Radius.chartBar`)
- Heatmap legend swatch: 14×8pt

---

## 5. Layout Principles

### Spacing Scale

| Token | Value | Role |
|-------|-------|------|
| `DesignSystem.Spacing.pageHorizontal` | 16pt | Horizontal screen edge padding |
| `DesignSystem.Spacing.section` | 28pt | Between major page sections |
| `DesignSystem.Spacing.stackLoose` | 20pt | Between blocks within a section |
| `DesignSystem.Spacing.block` | 12pt | Between items in a group |
| `DesignSystem.Spacing.inlineTight` | 8pt | Icon-to-label, inline pairs |
| `DesignSystem.Spacing.stackTight` | 4pt | Between label/subtitle lines |
| `DesignSystem.Spacing.dense` | 6pt | Heatmap cells, compact grids |
| `DesignSystem.Spacing.cardPadding` | 20pt | Standard card inner padding |
| `DesignSystem.Spacing.heroCardPadding` | 24pt | Hero/summary card padding |
| `DesignSystem.Spacing.cardPaddingSmall` | 16pt | Small / horizontal-scroll cards |
| `DesignSystem.Spacing.scrollBottom` | 24pt | Bottom padding in ScrollView |

### Grid

- Base device: 390pt wide (iPhone 15)
- Single-column for most content; 2-col grid for stat mini-cards
- Horizontal scroll carousels use `DesignSystem.Layout.homeLedgerCardWidth` (screen - 32 - 4pt)

### Whitespace Philosophy

- Generous vertical breathing room between sections (`section` = 28pt)
- Never nest cards inside cards — max 1 surface elevation level visible at once
- Separate list items with either dividers OR card-row borders, never both

---

## 6. Depth & Elevation

Two effective elevation levels — no deep shadow stacks.

| Level | Visual Treatment | Usage |
|-------|-----------------|-------|
| **0 — Page** | `bgPage` fill, no shadow | Full-screen background |
| **1 — Card** | `bgCard` + 1pt `border.opacity(0.3)` stroke | Standard content cards |
| **2 — Surface** | `bgSurface` (white/warm dark) | Bottom sheets, modals |

**Primary button shadow:**
- Light: `primary.opacity(0.2)`, radius 8, y 4
- Dark: `black.opacity(0.3)`, radius 8, y 4

**Selected/Active effects** (`DesignSystem.Effects`):
- Fill opacity: 0.1
- Shadow opacity: 0.12, radius 4, y 2
- Disabled opacity: 0.6

---

## 7. Do's and Don'ts

**Do:**
- Use `DesignSystem.*` tokens exclusively — colors, fonts, radii, spacing
- Apply `.background(DesignSystem.Colors.bgPage.ignoresSafeArea())` on every screen root
- Use `primary.opacity(0.1)` for icon tray backgrounds and selected state fills
- Add `border.opacity(0.3)` strokes to all cards and inputs
- Bottom-pad all `ScrollView` content with `Spacing.scrollBottom` (24pt)
- All user-visible strings via `String(localized:)` with `module.scene.semantic` keys

**Don't:**
- Don't hard-code any color, font size, radius, or spacing value in view code
- Don't nest `NavigationStack` inside child views — one root stack per tab
- Don't put `@Query` or `modelContext` calls inside `Components/` views
- Don't mix card radius values — `card` (20pt) for cards, `smallCard` (14pt) for rows
- Don't check `colorScheme` to pick colors — all tokens are already adaptive
- Don't show both list dividers AND card-row borders on the same list

---

## 8. Responsive Behavior

- **Target**: iPhone only, portrait. Base 390×844pt.
- **Min touch target**: 44×44pt. Full-width buttons satisfy this automatically.
- **Dynamic Type**: All `DesignSystem.Typography` tokens use system fonts and scale with accessibility settings.
- **Safe areas**: `.ignoresSafeArea()` on page backgrounds only. Bottom action buttons use `.safeAreaInset(edge: .bottom)`.
- **Smaller iPhones**: `pageHorizontal` (16pt) holds; carousels adapt via `homeLedgerCardWidth` computed property.
- **Dark mode**: Handled by all tokens. Do not add `.preferredColorScheme()` to production views.

---

## 9. Agent Prompt Guide

### Quick Token Cheatsheet

```
primary: #B76E5A  |  accentGold: #C5A065 (income)
bgPage: #F5EFE6 / #1C1B19  |  bgCard: #E8DDD1 / #262422
bgInput: #ECE3D7 / #2E2B29  |  bgSurface: #FFFFFF / #2A2220
textPrimary: #2C2C2C / #E6E1DC  |  textSecondary: #7A746E / #ABA59F
border: #D9CFC4 / #3D3935

Fonts: display 48B | title1 28B | title2 22B | title3 20SB | body 16R | caption 14M | small 11M
Radii: card 20 | smallCard 14 | input 12 | button ∞ | tag 8 | chartBar 2
Spacing: pageH 16 | section 28 | stackLoose 20 | block 12 | inlineTight 8 | stackTight 4 | cardPadding 20
```

### Example Prompts

**New screen:**
> Build a SwiftUI view using DESIGN.md tokens. Background: `bgPage.ignoresSafeArea()`. Horizontal padding: `pageHorizontal` (16pt). Section spacing: `section` (28pt). Cards use `bgCard` + `card` radius (20pt) + `border.opacity(0.3)` stroke. All strings via `String(localized:)`.

**New card component:**
> Create a SwiftUI card component: `bgCard` background, `Radius.card` (20pt) corners, `Spacing.cardPadding` (20pt) inner padding, 1pt `border.opacity(0.3)` stroke overlay. Title in `title3` / `textPrimary`, subtitle in `caption` / `textSecondary`.

**List row:**
> Build a list row: `bgInput` background, `smallCard` radius (14pt), `cardPaddingSmall` (16pt) padding. Left: 56pt avatar circle in `bgInput`. Center: primary text in `body`/`textPrimary`, detail in `caption`/`textSecondary`. Right: amount in `caption`/`accentGold` + chevron in `textTertiary`.

**Form sheet:**
> Form sheet with `bgSurface` background. Each field: `caption`/`textSecondary` label above it, `StandardTextFieldStyle()` input. Field gap: `block` (12pt). Bottom: Primary CTA with `PrimaryButtonStyle()`, cancel with `GhostButtonStyle()`.

---

*Source: `LiShu/DesignSystem/DesignTokens.swift` + `LiShu/DesignSystem/DesignView.swift`*  
*Generated: 2026-04-18*
