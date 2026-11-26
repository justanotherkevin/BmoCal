# BmoCal style guide

## Purpose

BmoCal has a minimal look that puts the data first. The inspiration is Dato, the menu bar calendar app by Sindre Sorhus. Dato offers a title you can configure and a short "free time" summary. It never uses color as the only signal, and it uses native materials. BmoCal follows the same ideas.

## Design tokens

### Type

| Use | Rule |
|-----|------|
| Font | SF Pro, the system font |
| Numbers | Always `NSFont.monospacedDigitSystemFont`, so the text width does not change each second |
| Menu bar size | `NSFont.systemFontSize` (13) |
| Body size | 13 pt |
| Secondary size | 11 pt |
| Minimum size | 10 pt |

### Color

| Color | Use |
|-------|-----|
| `labelColor` | Main text and the elapsed ring |
| `secondaryLabelColor` | Secondary text and past event rows |
| `tertiaryLabelColor` | Hints and the weakest text |
| `separatorColor` | Lines and ring tracks |
| Calendar colors | Events only. Past events use alpha 0.35 |
| `systemRed` | The "now" marker only |
| `controlAccentColor` | The urgency dot only |

Do not hardcode white, black or gray.

### Appearance

- Follow light and dark mode.
- Widgets use an `NSVisualEffectView` with material `.popover`.
- Custom drawing happens inside `effectiveAppearance.performAsCurrentDrawingAppearance`.

### Spacing and shape

- Spacing steps are 4, 8, 12 and 16 pt.
- Corner radius is 12 for panels and 3 for event blocks.

### Motion

There is no pulsing and no glow. Urgency is shown with a static accent dot.

## Menu bar states

| State | Image | Title example |
|-------|-------|---------------|
| Before workday | App icon | "in 1h 05m" |
| Workday | Capsule, 28x6 pt template image showing the fraction of the day | "4h 32m" |
| Event within 60 min | Same capsule | "4h 32m   Standup 12m" |
| Event within 5 min | Accent dot | "Standup 4m" |
| After workday | `checkmark.circle` symbol | Empty. If an event is within 60 min, the app icon with "Standup 12m" |

Event titles are cut off at 16 characters.

## Event menu (popover)

The top of the popover shows:

- The date header.
- The remaining time and the percent of the day.
- A horizontal day strip.
- A summary such as "3 meetings, 1h 45m free".

Event rows are grouped under Now, Later and Tomorrow. Each row has:

- A time column with a fixed width.
- A 3 pt bar in the calendar color.
- A relative time, aligned to the right.
- A join button, only when the event has a meeting link.

Past rows use `secondaryLabelColor`.

## Round widget

- The elapsed ring is 4 pt wide, drawn in `labelColor` on a `separatorColor` track.
- Events are arcs in the calendar color, on an outer track.
- The face has 4 ticks and no hour labels.
- The "now" marker is a red radial tick.
- The center shows "4:32" and "Standup in 12m".

## Vertical widget

- The remaining time is at the top.
- Hour labels appear every 2 hours.
- Event blocks have a fill at 0.25 alpha and a solid 3 pt bar on the leading edge.
- The title goes inside the block when the block is at least 18 pt tall.
- The "now" line is red, runs the full width, and has a time label.

## Preferences

The tabs are General, Menu Bar, Calendars, Notifications and Widgets. One "Alert style" popup replaces the separate toggles. Its choices are None, Banner, Full screen and Chime.

## Rejected defaults

A design system search tool suggested web defaults. They were Fira fonts, an enterprise landing page pattern and a navy palette. They do not fit a native macOS app, so they are not used. Only the "Swiss minimal, dense" direction was kept.
