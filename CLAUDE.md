# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## BmoCal — Workday Countdown Menu Bar App

macOS menu bar agent (`LSUIElement = true`, no Dock icon) showing a workday progress bar, countdown to the next calendar event, and an optional floating circular clock widget.

## Build & Test

```bash
# Build
xcodebuild build \
  -project BmoCal.xcodeproj \
  -scheme BmoCal \
  -configuration Debug

# Test (two-step — xcodebuild test has sandbox restrictions)
xcodebuild build-for-testing \
  -project BmoCal.xcodeproj \
  -scheme BmoCal \
  -configuration Debug \
  -derivedDataPath ./DerivedData \
  -destination 'platform=macOS,arch=arm64'

xcrun xctest ./DerivedData/Build/Products/Debug/BmoCal.app/Contents/PlugIns/BmoCalTests.xctest
```

In Xcode: ⌘B to build, ⌘U to run tests. No external dependencies or package manager.

## Architecture

**Update loop:** `AppDelegate` owns a 1-second `Timer` → `update()` → refreshes menu bar title and calls `NextEventViewController.update()`.

**Data flow:**
```
EKEventStore (OS)
    └→ CalendarTools (sync query wrapper, DispatchGroup for reminders)
         └→ NextEventViewController (status string + event table)
              └→ AppDelegate (sets NSStatusItem title, triggers widget refresh)
                   └→ WorkdayWidgetWindowController → WorkdayWidgetView (CoreGraphics)
```

**Menu bar status** (`NextEventViewController.getMenuBarStatus(now:) -> MenuBarStatus`, rendered by `AppDelegate.renderStatus`). `MenuBarStatus` is an image (`appIcon`, `capsule(fraction)`, `urgentDot`, `done`) plus text:
- Before workday: app icon + `"in 1h 05m"` (`"starting"` under 60s)
- During workday: 28x6 template capsule + `"4h 32m"`
- Event within 60 min: adds `"   Standup 12m"`
- Event within 5 min: accent dot + `"Standup 4m"`
- After workday: `checkmark.circle` with empty title, or app icon + event if one is within 60 min

UI rules: `docuemnts/reference/style-guide.md`.

**Widget geometry:** full circle = workday span. `timeToAngle(t) = π/2 − (t−workStart)/(workEnd−workStart) × 2π` — 12 o'clock = workday start, clockwise. All CoreGraphics arcs use `clockwise: true` (Y-up coordinate system).

## File Glossary

| File | Role |
|------|------|
| `AppDelegate.swift` | Entry point; owns StatusItem, Popover, update timer, status rendering, widget lifecycle |
| `NextEventViewController.swift` | Popover view + status string generation + event notifications |
| `Settings.swift` | Persistent config — `Data` struct (Codable JSON → `~/Documents/BmoCal.cfg`) |
| `CalendarTools.swift` | EKEventStore wrapper; synchronous query interface |
| `TimeStringTools.swift` | Pure stateless formatting: progress bar, fuzzy time, countdown strings |
| `DateExtensions.swift` | `startOfDay`, `endOfDay`, local/UTC timezone helpers |
| `WorkdayWidgetView.swift` | CoreGraphics NSView — circular clock drawing + mouse drag |
| `WorkdayWidgetWindowController.swift` | Borderless transparent NSWindow; persists widget position |
| `NextEventPreferencesViewController.swift` | Preferences panel (calendar/reminder selector, notification settings) |
| `MZAlertBoxViewController.swift` | Modal blocking alert for event notifications |

## Feature Locations (Cross-File)

**Menu bar progress bar:** `Settings.workdayStartHour/workdayEndHour` → `TimeStringTools.workdayFraction()` / `durationString()` / `workdayRemainingString()` → `NextEventViewController.getMenuBarStatus(now:)` → `AppDelegate.renderStatus`

**Floating widget:** `WorkdayWidgetView.swift` + `WorkdayWidgetWindowController.swift` + `Settings.showWidget/widgetX/widgetY` + `CalendarTools.getTodayEvents()` + `AppDelegate.showWidget()` / `refreshWidgetEvents()`

**Notifications:** `NextEventViewController.notify()` — fires at the exact second using system alerts, blocking modal, travel time warnings, or chime.

## Known Quirks

- **`CalendarTools.swift` print statement** — `print` at line ~79 is intentional. Removing it causes `event.calendar` to return nil (EKEventStore timing/retain issue).
- **`requestAccess()` always returns `true`** — async completion block; actual denial is caught by the exit dialog in `AppDelegate`.
- **Reminder list color bug** — `getReminderListNames()` queries `.event` calendars instead of `.reminder` (upstream bug, unfixed).
- **`NSUserNotification` deprecated** — still works; eventual migration to `UserNotifications` framework needed.
- **Unused settings fields**: `useFlash`, `useFlashBlue`, `showSeconds`, `leadingZeros`, `useFuzzyTime`, `showTitle`, `useTitleLimit`, `showTime` are kept only for config file compatibility and have no effect.
- **`showNumber` semantics** — `> 0` = top N events, `0` = today only, `-1` = next 24 hours.

## Development Notes

- Settings persist via `Codable` JSON; adding a field with a default is enough to persist it.
- Settings changes set `needsDisplay = true`; the next `update()` tick calls `refreshAll()`.
- Day rollover detected in `AppDelegate.update()` by comparing midnight dates — triggers full calendar refresh.
- `BmoCalTests/` uses Swift Testing (`@Test` macro, `@testable import BmoCal`). Test files: `SmokeTest.swift`, `DateExtensionsTests.swift`, `SettingsTests.swift`, `TimeStringToolsTests.swift`.
- `widget/` subdirectory contains unused duplicate files (`WorkdayWidgetView 2.swift`, etc.) — ignore them.
- Storyboard `customModule` must stay `"BmoCal"` — the old value `"NextEvent"` causes a launch crash.

## Reference Documents

Pull these in when you need detail beyond the glossary:

| Doc | When to use |
|-----|-------------|
| `docuemnts/reference/settings-reference.md` | Adding/changing settings; understanding all 19 config fields with defaults |
| `docuemnts/reference/api-reference.md` | CalendarTools query methods, TimeStringTools formatting methods |
| `docuemnts/plans/architecture-improvement-plan.md` | Refactoring work; Phase 1 mostly done, Phase 2 partially done |
| `docuemnts/reference/style-guide.md` | Any UI change: fonts, colors, spacing, menu bar states, widget and popover rules |

## Context Navigation (Graphify)

1. **First:** query `graphify-out/graph.json` or `graphify-out/wiki/index.md` for code structure
2. **Second:** raw source files only when editing or when the graph lacks the answer
3. Rebuild graph after structural changes: `graphify . --update`
4. Never modify files inside `graphify-out/`
