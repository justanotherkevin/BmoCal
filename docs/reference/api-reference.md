# API Reference

## CalendarTools (`CalendarTools.swift`)

Wraps `EKEventStore`. All query methods are synchronous — `DispatchGroup` is used internally to block on async reminder fetches.

| Method | Returns | Description |
|--------|---------|-------------|
| `getTopN(n:calendars:reminders:)` | `[EKCalendarItem]` | Next N events/reminders from now, up to 1 year |
| `getTodayAll(calendars:reminders:)` | `[EKCalendarItem]` | All events/reminders for today |
| `get24Hours(calendars:reminders:)` | `[EKCalendarItem]` | Events/reminders in the next 24 hours |
| `getTodayEvents(calendars:)` | `[EKEvent]` | Today's calendar events sorted by start time (widget use) |
| `getCalendarByNames(names:)` | `[EKCalendar]` | Filter calendars by display name |
| `getReminderListByNames(names:)` | `[EKCalendar]` | Filter reminder lists by display name |
| `requestAccess()` | Bool | Request Calendar + Reminders permission (always returns true — see quirks) |

Returns a placeholder `EKEvent` with title `"N/A"` when results are empty (guards against empty table views).

---

## TimeStringTools (`TimeStringTools.swift`)

Pure stateless formatting utilities — no stored state, safe to call from any context.

| Method | Description |
|--------|-------------|
| `getTimeString(_:showSeconds:leadingZeros:)` | "2 days 3 hours 15 minutes" from DateComponents |
| `getTimeStringFromSeconds(_:showSeconds:leadingZeros:)` | Same but from raw seconds |
| `getLeadTime(_:) -> (String, String)` | Dominant unit value + label, e.g. ("15", "MINUTES") |
| `getFuzzyTimeString(_:)` | Natural language: "one hour", "tomorrow", "next week" |
| `getFuzzyStatusString(_:)` | Compact fuzzy: "2 hours", "3 days" |
| `workdayProgressBar(startHour:endHour:)` | `[████░░░░░░]` — 10-char block progress bar |
| `workdayRemainingString(endHour:)` | "4h32m" or "47m" remaining in workday |
| `getShortTimeString(_:endDate:)` | "9:00 AM" or "9:00 AM - 5:00 PM" |
| `getStatusString(_:showSeconds:)` | "D:HH:MM[:SS]" compact format |

---

## DateExtensions (`DateExtensions.swift`)

Extensions on `Date` for day boundary and timezone conversion.

| Method/Property | Description |
|-----------------|-------------|
| `startOfDay` | Midnight at the start of the current day (local time) |
| `endOfDay` | 23:59:59 at the end of the current day (local time) |
| `toLocalTime()` | Convert UTC date to local timezone |
| `toGlobalTime()` | Convert local date to UTC |
