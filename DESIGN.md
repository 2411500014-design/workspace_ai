---
name: Purnara
description: A calm project workspace that turns a thesis into a living plan, in Indonesian and English.
colors:
  supervisor-teal: "#0F766E"
  teal-container: "#D7F1EC"
  on-teal-container: "#0B4A45"
  sage-wash: "#EAF2F0"
  on-sage-wash: "#1E3D3A"
  critical-orange: "#C2410C"
  critical-container: "#FDECDF"
  on-critical-container: "#7C2D12"
  late-red: "#B91C1C"
  late-container: "#FDE8E8"
  on-late-container: "#7F1D1D"
  on-track-green: "#15803D"
  on-track-container: "#E2F6E8"
  on-on-track-container: "#14532D"
  attention-amber: "#B45309"
  attention-container: "#FDF1D6"
  on-attention-container: "#713F12"
  morning-mist: "#F6F8F7"
  clean-sheet: "#FFFFFF"
  deep-ink: "#0F1B1A"
  quiet-ink: "#53625F"
  field-stroke: "#7F8C89"
  hairline-sage: "#E2E8E6"
  mist-shade: "#E1E7E5"
  night-panel: "#1A2624"
  night-panel-text: "#F2F5F4"
  brand-tile-top: "#128C82"
  brand-tile-bottom: "#0B5C56"
  supervisor-teal-dark: "#4FC7B5"
  on-supervisor-teal-dark: "#032A26"
  teal-container-dark: "#15403B"
  night-desk: "#0C1110"
  night-sheet: "#131A19"
  night-ink: "#E8EEED"
  night-quiet-ink: "#9DABA8"
  night-hairline: "#243030"
typography:
  display:
    fontFamily: "Plus Jakarta Sans, system-ui, sans-serif"
    fontSize: "32px"
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: "-0.8px"
  headline:
    fontFamily: "Plus Jakarta Sans, system-ui, sans-serif"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: "-0.5px"
  title:
    fontFamily: "Plus Jakarta Sans, system-ui, sans-serif"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: "-0.25px"
  title-small:
    fontFamily: "Plus Jakarta Sans, system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: "-0.1px"
  body:
    fontFamily: "Plus Jakarta Sans, system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.55
  body-small:
    fontFamily: "Plus Jakarta Sans, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "Plus Jakarta Sans, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.3
  data:
    fontFamily: "Plus Jakarta Sans, system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: 1.45
    fontFeature: "tnum"
rounded:
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "20px"
  pill: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  2xl: "32px"
  3xl: "48px"
components:
  button-primary:
    backgroundColor: "{colors.supervisor-teal}"
    textColor: "{colors.clean-sheet}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "0 22px"
    height: "48px"
  button-outlined:
    backgroundColor: "{colors.clean-sheet}"
    textColor: "{colors.deep-ink}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "0 22px"
    height: "48px"
  button-text:
    textColor: "{colors.supervisor-teal}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "0 12px"
    height: "48px"
  card:
    backgroundColor: "{colors.clean-sheet}"
    rounded: "{rounded.lg}"
    padding: "16px"
  input:
    backgroundColor: "{colors.clean-sheet}"
    textColor: "{colors.deep-ink}"
    typography: "{typography.body-small}"
    rounded: "{rounded.md}"
    padding: "14px 16px"
  pill-on-track:
    backgroundColor: "{colors.on-track-container}"
    textColor: "{colors.on-on-track-container}"
    typography: "{typography.data}"
    rounded: "{rounded.pill}"
    padding: "3px 10px 3px 8px"
    height: "26px"
  pill-critical:
    backgroundColor: "{colors.critical-container}"
    textColor: "{colors.on-critical-container}"
    typography: "{typography.data}"
    rounded: "{rounded.pill}"
    padding: "3px 10px 3px 8px"
    height: "26px"
  pill-late:
    backgroundColor: "{colors.late-container}"
    textColor: "{colors.on-late-container}"
    typography: "{typography.data}"
    rounded: "{rounded.pill}"
    padding: "3px 10px 3px 8px"
    height: "26px"
  banner-info:
    backgroundColor: "{colors.sage-wash}"
    textColor: "{colors.on-sage-wash}"
    typography: "{typography.body-small}"
    rounded: "{rounded.md}"
    padding: "10px 14px"
  banner-attention:
    backgroundColor: "{colors.attention-container}"
    textColor: "{colors.on-attention-container}"
    typography: "{typography.body-small}"
    rounded: "{rounded.md}"
    padding: "10px 14px"
  segment-selected:
    backgroundColor: "{colors.teal-container}"
    textColor: "{colors.on-teal-container}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    height: "44px"
  nav-bar:
    backgroundColor: "{colors.clean-sheet}"
    height: "68px"
  nav-indicator:
    backgroundColor: "{colors.teal-container}"
    rounded: "{rounded.pill}"
  snackbar:
    backgroundColor: "{colors.night-panel}"
    textColor: "{colors.night-panel-text}"
    typography: "{typography.body-small}"
    rounded: "{rounded.md}"
    width: "440px"
  skeleton-block:
    backgroundColor: "{colors.mist-shade}"
    rounded: "{rounded.sm}"
---

# Design System: Purnara

## Overview

**Creative North Star: "The Steady Supervisor"**

Purnara looks and behaves like a good thesis supervisor: steady, clear about the next step, never loud, and on the student's side when things slip. The interface is quiet so that the student's own work can be heard. Pages are mostly calm neutrals. Colour appears only when it means something: teal marks what the student can act on or owns, and a small set of status colours says how the project is doing, always alongside words and an icon.

The system is quiet, precise and encouraging. Precision shows in the details a student relies on: dates and hours set in tabular figures, a checkbox that lines up with its title, a plan that moves only when they accept a change. Encouragement comes from tone rather than decoration. There are no alarms and no scoreboards. Falling behind produces calm options, and finishing a task produces a small confirmation, never a celebration.

It is one system in two themes. Light mode is a sheet of paper in morning light; dark mode is a desk at night, where lighter surfaces take over the job of shadows. It is also one system in two languages: every layout must hold Indonesian and English copy of different lengths. The explicit anti-references are gamification (streaks, points, confetti, badges), corporate dashboards (dense charts and big KPI numbers), flashy AI chrome (purple gradients, sparkle effects, AI everywhere), and a judgemental tone (red everywhere, frightening countdowns).

**Key Characteristics:**
- Cool, near-neutral surfaces with a single teal accent.
- Hairline borders plus a soft, ink-tinted lift in light mode; tonal layers in dark mode.
- One typeface, Plus Jakarta Sans, with tightened headings and tabular figures for data.
- Status is always text, icon and colour together.
- Restrained, fast motion that honours the operating system's reduced-motion setting.

## Colors

A cool mist of neutrals carries almost every pixel, and one deep teal carries every action.

### Primary
- **Supervisor Teal** (light `supervisor-teal`, dark `supervisor-teal-dark`): filled buttons, the selected navigation item, links and text buttons, focus rings, progress fills, the text cursor and selection, and a card's selected state. White text on it passes WCAG AA. Its soft form, **Teal Container**, backs the selected navigation pill, selected segments and empty-state badges.

### Tertiary
- **Critical Orange** (`critical-orange`, container `critical-container`): only the critical-path badge (*Jalur kritis*) and the notification count. It flags importance, not danger.

### Status
- **On-Track Green** (`on-track-green`, container `on-track-container`): the *Sesuai jadwal* health pill, ready documents, and completed milestones.
- **Attention Amber** (`attention-amber`, container `attention-container`): the *Perlu perhatian* health pill and warning banners, such as "the plan needs adjusting".
- **Late Red** (`late-red`, container `late-container`): the *Tertinggal* health pill, "late by N days" badges, failed documents, and destructive confirmations. Nothing else.

### Neutral
- **Morning Mist** (`morning-mist`): the page background in light mode. A faint cool green-grey, never pure white.
- **Clean Sheet** (`clean-sheet`): cards, sheets, dialogs, inputs, and the bottom navigation bar.
- **Deep Ink** (`deep-ink`): all primary text. It is a near-black with a trace of teal, so text never looks harsh against Morning Mist.
- **Quiet Ink** (`quiet-ink`): secondary text, metadata lines, and icons at rest. It passes 4.5:1 on both Morning Mist and Clean Sheet.
- **Field Stroke** (`field-stroke`): input borders and the unchecked checkbox, softened to about 70 % at rest.
- **Hairline Sage** (`hairline-sage`): card borders, dividers, and the top edge of the navigation bar.
- **Mist Shade** (`mist-shade`): progress-bar tracks and skeleton blocks.
- **Sage Wash** (`sage-wash`): informational banners and source labels ("Tanpa AI", "Usulan AI").
- **Night Panel** (`night-panel`): snackbars and tooltips, the only inverted surfaces.
- **Night Desk, Night Sheet, Night Ink, Night Quiet Ink, Night Hairline**: the dark-mode page, cards, text, secondary text and hairlines.

### Named Rules
**The One Voice Rule.** Teal means "act here" or "this is yours". It is never used for decoration, section backgrounds, or illustration.

**The Never Colour Alone Rule.** Every status carries an icon and a word as well as a colour, so it survives colour blindness, greyscale screenshots, and both languages.

**The Calm Before Red Rule.** Amber and orange come before red. Red is reserved for a task that is actually late, a failure, or a destructive action.

## Typography

**Display Font:** Plus Jakarta Sans (with system-ui, sans-serif)
**Body Font:** Plus Jakarta Sans (with system-ui, sans-serif)

**Character:** a single friendly geometric sans, bundled with the app so it works offline and never calls a font CDN. Its warmth stops the precision from feeling clinical, and tightening the letter spacing as sizes grow keeps headings firm.

### Hierarchy
- **Display** (700, 32px, 1.15): rare. It is used for the welcome headline, which grows to 40px with -1.2px tracking on wide screens.
- **Headline** (700, 24px, 1.25): page titles such as "Fokus hari ini", step titles in setup, and project names.
- **Title** (600, 20px, 1.35): section headings, the app bar title, and dialog titles. **Title Small** (600, 16px, 1.4) is for card titles and focus-task titles.
- **Body** (400, 16px, 1.55): brief text, assistant answers, and empty-state messages. Keep the measure near 65–75 characters. **Body Small** (400, 14px, 1.5) is for banners, list content and inputs.
- **Label** (600, 14px, 1.3): buttons, segments and tabs.
- **Data** (500, 12px, 1.45, tabular figures): metadata such as "T1 · 6 jam · 24 Sep – 28 Sep", pills, dates and hours. Nothing is ever set smaller than 12px.

### Named Rules
**The No Kicker Rule.** A heading never has a small label above it. Its context, such as the date or "Langkah 1 dari 6", goes underneath it or in the app bar.

**The Aligned Numbers Rule.** Dates, hours, percentages and counts use tabular figures, so columns and lists of numbers line up.

## Layout

Content sits in a centred column: 960px maximum for overview screens such as Project, Plan and Documents, and 760px for focused, mostly single-column screens such as Today, task detail, suggestions, settings, brief, supervision and review. Setup uses a 720px column with a fixed action bar at the bottom.

Pages have 16px side padding and 24px top padding, and bottom padding sized to clear a floating action button. Spacing follows a 4px base scale (4, 8, 12, 16, 24, 32, 48). Related items sit 8–12px apart, cards are 16px apart, and sections 24–32px apart, with more space above a heading than below it.

The main breakpoint is at 840px. Below it, the five destinations (Hari Ini, Project, Rencana, Dokumen, Asisten) sit in a bottom navigation bar; above it, they move to a navigation rail on the left, which extends with labels beside the icons at 1200px. The welcome screen splits into copy and a live product preview at 920px and stacks on narrower screens. Every multi-column arrangement collapses to one column on phones.

## Elevation & Depth

The system is a hybrid. In light mode, a 1px Hairline Sage border does the separating and a soft shadow tinted with the ink colour only lifts. Cards sit just above the page; they never float. In dark mode there are no card shadows: Night Sheet is one step lighter than Night Desk, and that tonal difference carries the elevation. Dialogs and menus use a single deeper Material elevation, and the app bar stays flat when content scrolls under it.

### Shadow Vocabulary
- **Card lift** (`0 1px 2px rgba(11,46,42,0.04), 0 6px 18px rgba(11,46,42,0.05)`): every card, section card and task card, in light mode only.
- **Menu** (Material elevation 4, shadow tinted to about 35 %): popup menus such as the project switcher and "move to".
- **Dialog** (Material elevation 6, shadow tinted to about 40 %): dialogs and date pickers.
- **Action button** (Material elevation 2 at rest, 3 on hover): the "add task" floating button.

### Named Rules
**The Lift, Not Float Rule.** Shadows stay at or below about 5 % opacity and are always tinted with the ink colour. If a shadow is noticeable as a shadow, it is too strong.

## Shapes

The corner language is gentle and consistent: 12px for controls (buttons, inputs, segments, banners, snackbars), 16px for cards, 20px for dialogs and bottom sheets, 8px for chips and skeleton blocks, 6px for checkboxes, and fully round for status pills and navigation indicators.

Borders are 1px hairlines. A selected card switches to a 1.5px Supervisor Teal border over a 5 % teal tint. The brand tile is the one non-rectangular form: a superellipse (exponent 5, continuous corners like platform icons) in a top-to-bottom gradient from Brand Tile Top to Brand Tile Bottom. It holds a white P whose bowl is a closed ring. That tile is reserved for the logo.

## Components

### Buttons
Calm and tactile: solid enough to trust, quiet enough not to shout.
- **Shape:** gently rounded (12px), 48px tall, 22px side padding, Label type.
- **Primary (filled):** Supervisor Teal with white text, used for the one main action on a screen ("Lanjut", "Terima rencana", "Mulai").
- **Tonal:** Sage Wash with On-Sage-Wash text (Material's tonal button), for strong secondary actions such as "Bantu saya mulai" on task detail.
- **Outlined:** Clean Sheet with Deep Ink text and a Field Stroke border at about 55 %, for secondary actions.
- **Text:** Supervisor Teal text with no container, for inline actions ("Tinjau", "Batalkan").
- **States:** Material state layers: a light overlay on hover, a stronger one on press and keyboard focus. Disabled buttons fall back to a neutral fill and muted text.

### Chips and Status Pills
- **Status pill:** a fully round, 26px-tall container with a 15px icon, 5px gap and Data-type label (600). Variants are *Sesuai jadwal* (On-Track), *Perlu perhatian* (Attention), *Tertinggal* (Late), *Jalur kritis* (Critical Orange) and *Terlambat N hari* (Late).
- **Source label:** the same pill on Sage Wash. It says where a proposal came from: "Usulan AI", "Dari template", "Dari penjadwal" or "Tanpa AI".
- **Chips:** 8px corners on Clean Sheet with a Hairline Sage border, used for dependencies, blocked dates and suggested questions.

### Cards / Containers
- **Corner Style:** 16px.
- **Background:** Clean Sheet (Night Sheet in dark mode).
- **Shadow Strategy:** the card lift in light mode, tonal only in dark mode (see Elevation & Depth).
- **Border:** 1px Hairline Sage; 1.5px Supervisor Teal plus a 5 % teal tint when selected.
- **Internal Padding:** 16px, or edge to edge for lists, whose rows carry their own 16px inset.
- **Tappable cards** ripple and scale to 0.985 while pressed (140ms), releasing as soon as the pointer drags away.

### Inputs / Fields
- **Style:** Clean Sheet fill, a 1px Field Stroke border at about 70 %, 12px corners, and 14px × 16px padding.
- **Focus:** the border becomes a 2px Supervisor Teal stroke, the floating label turns teal at weight 600, and the cursor and selection are teal.
- **Error:** a Late Red border (2px when focused), with the error text below the field.
- **Editable headings**, such as the task title, drop the box entirely and show only a teal underline while focused.

### Navigation
- **Phone:** a 68px bottom bar on Clean Sheet with a Hairline Sage top edge. The selected item gets a round Teal Container indicator with a bold label; the others use Quiet Ink labels at weight 500.
- **Tablet and desktop:** a navigation rail on Morning Mist, separated from the content by a hairline, with the brand tile at the top. Labels sit under the icons; at 1200px and above the rail extends to 216px with labels beside them.
- **App bar:** flat on Morning Mist, with the project switcher as its title, and notifications and settings on the right.
- **Page transitions:** the new page fades in and rises 2.5 % over the route's roughly 300ms, on the strong ease-out; the page underneath fades to 60 % opacity. Leaving reverses it. Tabs switch without a transition.

### Task Card (signature)
The core of the product, used on Today and in Plan:
- a 48px checkbox, with the title's first line aligned to its centre;
- the title in Title Small, and a Data-type metadata line (milestone · hours · date range);
- a row of badges and "Bantu saya mulai".
Ticking the checkbox greys and strikes the title (220ms), and a snackbar offers "Batalkan". The day's focus cards are the only staged entrance on Today: each fades and lifts 12px, 55ms apart.

### Suggestion Review (signature)
Every AI or scheduler proposal is shown as a list of changes the student can tick or untick, each with an icon and a plain sentence ("Tambah task: …", "Pindahkan target ke …"). It sits above a bottom decision bar with "Tolak" on the left and "Terima semua" or "Terima N yang dipilih" on the right. Changes in schedule appear as old date → new date.

### Loading and Empty States
- **Skeleton:** page loads show Mist Shade blocks in the shape of the page, gently pulsing (1.1s). They appear only after 160ms, so fast loads never flash.
- **Long operations:** a slim spinner with a sentence explaining the wait, such as "Menyusun rencana…".
- **Empty and error states:** a 56px round tinted badge with the icon (Teal Container for empty, a neutral container for errors), one sentence at most 440px wide, and at most one action.

## Do's and Don'ts

### Do:
- **Do** keep Supervisor Teal for actions, selection, focus and progress only (The One Voice Rule).
- **Do** pair every status colour with an icon and a word (The Never Colour Alone Rule).
- **Do** use Amber before Red; reserve Late Red for real lateness, failure and destruction.
- **Do** put a heading's context under it or in the app bar (The No Kicker Rule).
- **Do** set dates, hours and counts in tabular figures.
- **Do** separate cards with a 1px Hairline Sage border and, in light mode, the card lift. In dark mode, use Night Sheet on Night Desk instead of shadows.
- **Do** keep motion fast and ease-out (140–280ms, `cubic-bezier(0.23, 1, 0.32, 1)`), and stop movement when the system asks for reduced motion.
- **Do** show loading as a skeleton in the page's shape, and keep spinners for waits that need an explanation.
- **Do** test every screen in light and dark, on a phone and on a wide screen, in Indonesian and English.

### Don't:
- **Don't** add gamification: no streaks, points, confetti, badges or leaderboards.
- **Don't** build corporate dashboards: no dense chart walls or giant KPI numbers.
- **Don't** dress the AI up: no purple gradients, glow, sparkle effects or AI chrome on every surface. AI output carries one small source label.
- **Don't** use a judgemental tone: no red everywhere, frightening countdowns or all-caps warnings.
- **Don't** place small uppercase labels above headings, or use coloured left borders on cards, banners or quotes.
- **Don't** use gradient text, glassmorphism, or shadows darker than about 5 %.
- **Don't** recolour or reshape the brand tile: it stays teal and white in both themes and only appears as the logo.
