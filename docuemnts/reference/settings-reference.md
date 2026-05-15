# Settings Reference

All fields live in `Settings.Data` (`Settings.swift`). Persisted as JSON to `~/Documents/BmoCal.cfg`.

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `workdayStartHour` | Int | 9 | Hour (0–23) when workday begins |
| `workdayEndHour` | Int | 18 | Hour (0–23) when workday ends |
| `showNumber` | Int | 10 | Events to show: N > 0 = top N, 0 = today, -1 = 24h |
| `showWidget` | Bool | false | Whether the floating clock widget is visible |
| `widgetFloatsOnTop` | Bool | true | Widget window level: `.floating` vs `.normal` |
| `widgetX` | Double | -1 | Saved widget X position (-1 = default top-right) |
| `widgetY` | Double | -1 | Saved widget Y position |
| `useFlash` | Bool | true | Flash icon when next event is ≤15 min away |
| `useFlashBlue` | Bool | false | Blue glow (true) vs orange glow (false) |
| `useAltIcon` | Bool | false | Mazookie icon instead of BmoCal icon |
| `useSystemAlert` | Bool | false | macOS notification center alerts |
| `useBlockingAlert` | Bool | false | Modal blocking alert window |
| `earlyWarning` | Int | 1 | Minutes before event to show blocking alert |
| `notifyTravelTime` | Bool | false | Alert when travel time starts |
| `useSound` | Bool | false | Chime on notifications |
| `showSeconds` | Bool | false | Show seconds in countdown |
| `leadingZeros` | Bool | false | Show leading zeros in time strings |
| `useFuzzyTime` | Bool | false | Natural-language time ("one hour", "tomorrow") |
| `showTime` | Bool | true | Show countdown time in popover rows |
| `showTitle` | Bool | false | Show app title in menu bar |
| `useTitleLimit` | Bool | false | Truncate long titles |
| `calendarNames` | [String] | [] | Names of calendars/reminder lists to include |
| `floatRight` | Bool | false | Float popover to right (set via `-F:1` launch arg) |

## Runtime Behavior

- Adding a new field with a default value is sufficient — `Codable` handles persistence automatically.
- Changes propagate on the next `update()` tick (AppDelegate sets `needsDisplay = true`).
- `-R` launch arg resets all settings to defaults; `-F:1`/`-F:0` sets `floatRight` at launch.
