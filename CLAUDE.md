# BmoCal — Workday Countdown Menu Bar App

macOS menu bar app showing a workday progress bar and countdown alongside upcoming calendar events.

## Project Structure

```
BmoCal/
├── AppDelegate.swift                  # App lifecycle, menu bar status item, glow animation
├── NextEventViewController.swift      # Main popover view, event list, menu bar status string
├── Settings.swift                     # Persistent settings (JSON, ~/Documents/BmoCal.cfg)
├── CalendarTools.swift                # EKEventStore queries for events and reminders
├── TimeStringTools.swift              # Time formatting: fuzzy, exact, progress bar, remaining
├── NextEventPreferencesViewController.swift  # Preferences panel
├── MZAboutBoxViewController.swift     # About / help window
├── MZAlertBoxViewController.swift     # Blocking alert window for event notifications
├── Main.storyboard                    # Main UI layout
├── NextEventPreferences.storyboard    # Preferences panel layout
├── Assets.xcassets/                   # App icons (normal, glow variants in blue/orange)
└── Info.plist                         # Bundle metadata, Calendar/Reminders permissions
BmoCal.xcodeproj/                      # Xcode project
builds/                                # Pre-built zip releases
```

## Building

Open `BmoCal.xcodeproj` in Xcode and build (⌘B) or run (⌘R). Requires macOS and Xcode — no external dependencies or package manager.

The app is a menu bar agent (`LSUIElement = true`), so it has no Dock icon.

## Architecture

### AppDelegate (`AppDelegate.swift`)

Entry point. Owns:

- `NSStatusItem` — the menu bar button with attributed title (the status string)
- `NSPopover` — the event list that appears on left-click
- 1-second repeating `Timer` that calls `update()` every tick
- Glow animation timer (`GLOW_INTERVAL = 0.1s`) that pulses the icon image

Key methods:

- `update()` — called every second; refreshes the menu bar title, triggers `shouldGlow`, detects day rollover
- `startGlow()` / `stopGlow()` / `glow()` — fade-in/out overlay animation on the status icon
- `processCommandLine()` — handles `-R` (reset settings) and `-F:1`/`-F:0` (float right) launch args

### NextEventViewController (`NextEventViewController.swift`)

The popover's view controller. Also computes the menu bar status string.

Key methods:

- `getNextEventStatus() -> String` — **the main status string shown in the menu bar**:
  - Before workday: `"Work in Xh Ym"`
  - During workday: `"[████░░░░░░] 4h32m · EventTitle Xm"`
  - After workday: `"Workday done"` or `"Done · EventTitle Xm"`
- `refreshAll()` — re-queries the calendar store and reloads the table
- `update() -> Bool` — called by AppDelegate each tick; reloads table or triggers full refresh
- `notify()` — fires system/blocking alerts and travel time warnings at the exact second

### Settings (`Settings.swift`)

Persists to `~/Documents/BmoCal.cfg` as JSON.

| Setting            | Type     | Default | Description                                        |
| ------------------ | -------- | ------- | -------------------------------------------------- |
| `workdayStartHour` | Int      | 9       | Hour (0–23) when workday begins                    |
| `workdayEndHour`   | Int      | 18      | Hour (0–23) when workday ends                      |
| `showNumber`       | Int      | 10      | Events to show: N > 0 = top N, 0 = today, -1 = 24h |
| `useFlash`         | Bool     | true    | Flash icon when next event is ≤15 min away         |
| `useFlashBlue`     | Bool     | false   | Blue glow (true) vs orange glow (false)            |
| `useAltIcon`       | Bool     | false   | Mazookie icon instead of BmoCal icon            |
| `useSystemAlert`   | Bool     | false   | macOS notification center alerts                   |
| `useBlockingAlert` | Bool     | false   | Modal blocking alert window                        |
| `earlyWarning`     | Int      | 1       | Minutes before event to show blocking alert        |
| `notifyTravelTime` | Bool     | false   | Alert when travel time starts                      |
| `useSound`         | Bool     | false   | Chime on notifications                             |
| `showSeconds`      | Bool     | false   | Show seconds in countdown                          |
| `leadingZeros`     | Bool     | false   | Show leading zeros in time strings                 |
| `useFuzzyTime`     | Bool     | false   | Natural-language time ("one hour", "tomorrow")     |
| `showTime`         | Bool     | true    | Show countdown time in popover rows                |
| `showTitle`        | Bool     | false   | Show app title in menu bar                         |
| `useTitleLimit`    | Bool     | false   | Truncate long titles                               |
| `calendarNames`    | [String] | []      | Names of calendars/reminder lists to include       |
| `floatRight`       | Bool     | false   | Float popover to right (set via `-F:1` launch arg) |

### CalendarTools (`CalendarTools.swift`)

Wraps `EKEventStore`. All queries are synchronous (uses `DispatchGroup` for reminder fetches).

| Method                              | Returns            | Description                                   |
| ----------------------------------- | ------------------ | --------------------------------------------- |
| `getTopN(n:calendars:reminders:)`   | `[EKCalendarItem]` | Next N events/reminders from now up to 1 year |
| `getTodayAll(calendars:reminders:)` | `[EKCalendarItem]` | All events/reminders for today                |
| `get24Hours(calendars:reminders:)`  | `[EKCalendarItem]` | Events/reminders in the next 24 hours         |
| `getCalendarByNames(names:)`        | `[EKCalendar]`     | Filter calendars by display name              |
| `getReminderListByNames(names:)`    | `[EKCalendar]`     | Filter reminder lists by display name         |
| `requestAccess()`                   | Bool               | Request Calendar + Reminders permission       |

Returns a placeholder `EKEvent` with title `"N/A"` when results are empty (guards against empty table).

### TimeStringTools (`TimeStringTools.swift`)

Pure formatting utilities — no state.

| Method                                                  | Description                                           |
| ------------------------------------------------------- | ----------------------------------------------------- |
| `getTimeString(_:showSeconds:leadingZeros:)`            | "2 days 3 hours 15 minutes" from DateComponents       |
| `getTimeStringFromSeconds(_:showSeconds:leadingZeros:)` | Same but from raw seconds                             |
| `getLeadTime(_:)` -> `(String, String)`                 | Dominant unit value + label ("15", "MINUTES")         |
| `getFuzzyTimeString(_:)`                                | Natural language: "one hour", "tomorrow", "next week" |
| `getFuzzyStatusString(_:)`                              | Compact fuzzy: "2 hours", "3 days"                    |
| `workdayProgressBar(startHour:endHour:)`                | `[████░░░░░░]` — 10-char block progress bar           |
| `workdayRemainingString(endHour:)`                      | "4h32m" or "47m" remaining in workday                 |
| `getShortTimeString(_:endDate:)`                        | "9:00 AM" or "9:00 AM - 5:00 PM"                      |
| `getStatusString(_:showSeconds:)`                       | "D:HH:MM[:SS]" compact format                         |

## Customizations vs Upstream

The workday progress bar feature lives in:

- `Settings.swift` — `workdayStartHour` and `workdayEndHour` fields
- `TimeStringTools.swift` — `workdayProgressBar(startHour:endHour:)` and `workdayRemainingString(endHour:)`
- `NextEventViewController.swift` — `getNextEventStatus()` implements the three-state logic (before/during/after workday)

`getNextEventStatus()` implements three-state logic: before workday, during workday (progress bar), and after workday.

## Permissions Required

Declared in `Info.plist`:

- `NSCalendarsUsageDescription` — Calendar read access
- `NSRemindersUsageDescription` — Reminders read access

The app exits at launch if `CalendarTools().requestAccess()` returns false.

## Known Quirks

- `CalendarTools.swift:79` — a `print` statement is left intentionally; removing it caused `event.calendar` to return nil (likely a timing/retain issue with EKEventStore).
- `requestAccess()` in `CalendarTools.swift` always returns `true` due to async completion blocks — actual denial is detected via the exit dialog in `AppDelegate`.
- `NSUserNotification` APIs are deprecated in newer macOS versions; they still work but may eventually need migration to `UserNotifications` framework.
- Reminder list color lookup in `getReminderListNames()` incorrectly queries `.event` calendars instead of `.reminder` — this is a bug in the upstream code.

## Development Notes

- No Swift Package Manager or CocoaPods — pure Xcode project.
- Storyboards are large; prefer editing UI in Xcode Interface Builder, not by hand.
- Settings changes set `needsDisplay = true`; the next `update()` tick picks this up and calls `refreshAll()`.
- Day rollover detection in `AppDelegate.update()` compares midnight dates to trigger a full calendar refresh at midnight.

## Context Navigation (Graphify)

### 3-Layer Query Rule

1. **First:** query `graphify-out/graph.json` or `graphify-out/wiki/index.md`
   to understand code structure and connections
2. **Second:** query the Obsidian vault for decisions, progress, and project context
3. **Third:** only read raw code files when editing
   or when the first two layers don't have the answer

### When to rebuild the graph

- After structural changes (new modules, major refactors)
- Command: `graphify . --update` (only processes modified files)
- The graph is persistent — NO need to rebuild every session

### Do NOT

- Don't manually modify files inside `graphify-out/`
- Don't re-read the entire codebase if the graph already has the information
