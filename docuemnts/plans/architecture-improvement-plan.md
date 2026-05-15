# BmoCal Architecture Improvement Plan

**Goal:** Elevate codebase architecture from ~5/10 to 8+/10

**Date:** 2026-05-14

---

## Completed

### Phase 1

| Item | Description | Evidence |
|------|-------------|----------|
| ✅ 1.1 Settings naming collision | Renamed inner `struct Settings` → `struct Data`; `settings.settings.xxx` → `settings.data.xxx` | `Settings.swift:6` — `struct Data: Codable` confirmed |
| ✅ 1.2 Consolidate Date extensions | All `Date` helpers moved to `DateExtensions.swift`; duplicates removed from `NextEventViewController.swift` and `CalendarTools.swift` | `DateExtensions.swift` exists; no `extension Date` found in the other files |
| ✅ 1.3 String-based type checking | Replaced `String(describing: type(of: item)) == "EKEvent"` with `item as? EKEvent` | No occurrences of `String(describing: type(of:` found in codebase |
| ✅ 1.4 Fix known bugs | `requestAccess()` now uses `DispatchGroup` and returns the real `Bool`; `getReminderListNames()` queries `.reminder` correctly | `CalendarTools.swift:341-359` |
| ✅ 1.5 Clean up force-unwraps | Resolved — remaining `!` are in string literals/comments, not unsafe optional unwraps | `guard let` pattern used throughout |
| ✅ 1.6 Replace N/A sentinel | Removed — `CalendarTools` returns real (possibly empty) arrays; empty state handled in view layer | No fake `EKEvent(title: "N/A")` found |

### Phase 2

| Item | Description | Evidence | Status |
|------|-------------|----------|--------|
| 🔲 2.1 Extract MenuBarManager | Requires adding files to Xcode project; scope: statusItem, popover, click handlers | Design complete, implementation blocked by pbxproj | Deferred to Phase 3 with protocol refactor |
| 🔲 2.2 Extract NotificationManager | Tightly coupled to view controller; requires careful separation of concerns | Design reviewed | Deferred to Phase 3 after MenuBarManager |
| ⏳ 2.3 Extract StatusStringBuilder | Pure struct design created; logic extracted from `getNextEventStatus()`; reverted pending pbxproj changes | Functional spec complete | Pending project file setup |
| ✅ 2.4 Deduplicate CalendarTools queries | **DONE** — Extracted `private func queryAndSortItems()` shared by getTopN, getTodayAll, get24Hours; wrappers now 2-4 lines | `CalendarTools.swift:32-82` | Builds, tested |
| ✅ 2.5 Deduplicate about/help methods | **DONE** — Extracted `private func openAboutBox(forceHelp:)` called by both `openAbout()` and `openHelp()` | `AppDelegate.swift:216-237` | Builds, tested |

**Phase 2 Impact:** 2/5 items fully complete (40%). CalendarTools code reduced from 102 lines across 3 methods → 51 lines across 1 helper + 3 wrappers. AppDelegate about/help reduced from 34 lines → 8 lines. Built and tested successfully. Items 2.1–2.3 require Xcode project file modifications.

### Phase 3

| Item | Description | Evidence | Status |
|------|-------------|----------|--------|
| ✅ 3.1 Protocol-ize CalendarTools | Created `EventStoreProtocol` with all public methods; `CalendarTools` conforms | `CalendarTools.swift:5-17` | Builds, compiles |
| ✅ 3.2 Protocol-ize Settings access | Created `SettingsProviding` protocol (data property, archive(), reset()); `Settings` conforms | `Settings.swift:3-9` | Builds, compiles |
| ✅ 3.3 DI container | Created `AppDependencies` struct; holds settings, eventStore (EventStoreProtocol), timeTools | `AppDependencies.swift` — lightweight struct, zero boilerplate | Builds, compiles |
| ✅ 3.4 Add unit tests | Incremental TDD: wrote 2 new Settings tests (reset, archive/unarchive). All 7 tests pass. | `SettingsTests.swift:20-53` + existing Date/Smoke tests. Created `TimeStringToolsTests.swift` (blocked by pbxproj) | 7/7 passing locally |

**Phase 3 Impact:** 4/5 items fully complete (80% of core work). Protocols in place, DI container ready, test foundation established. TimeStringTools tests exist but blocked by project file setup. Ready for next phase: Dependency Injection into view controllers.

### Final Phase 3 Status (End of Session)

✅ **Completed:**
- 3.1 EventStoreProtocol + CalendarTools conformance
- 3.2 SettingsProviding protocol + Settings conformance  
- 3.3 AppDependencies DI container (inlined into AppDelegate)
- 3.4 Unit tests with incremental TDD:
  - 8 tests passing (Settings, Date extensions, StatusStringBuilder)
  - StatusStringBuilder testable design: injected time parameter
  - All tests use /incremental-tdd workflow (ONE test at a time)

**Test Results:** 8/8 passing
- 3 Date extension tests
- 3 Settings tests (defaults, reset, archive/unarchive)
- 1 StatusStringBuilder test (before-workday scenario)
- 1 Smoke test

---

## Current Score: 5/10

### What's Good (retain these)

| Area | Why It Works |
|------|-------------|
| File-level separation | `Settings`, `CalendarTools`, `TimeStringTools`, views — each has a clear domain. The boundaries are mostly right; the internals need work. |
| `TimeStringTools` | Pure formatting utility with no state, no side effects, no AppKit coupling. The cleanest file in the project. |
| Widget architecture | `WorkdayWidgetView` (drawing) + `WorkdayWidgetWindowController` (window management) is the best separation in the codebase. The view draws; the controller manages the window. Close to MVC done right. |
| `Codable` persistence | Simple, no external dependencies, human-readable JSON config. Good choice for a single-user desktop app. |
| `CLAUDE.md` documentation | Thorough project documentation covering architecture, quirks, build steps. Rare and valuable. |
| Core Graphics drawing | `WorkdayWidgetView.draw(_:)` is well-structured, commented in sections, uses `saveGState`/`restoreGState` properly. |

### What's Holding It Back (critical)

| Issue | Severity | File(s) |
|-------|----------|---------|
| God-class AppDelegate | High | `AppDelegate.swift` — 15+ responsibilities in ~300 lines |
| Massive View Controller | High | `NextEventViewController.swift` — data, formatting, notifications, alerts, table delegate all in one |
| CalendarTools code duplication | High | `getTopN` / `getTodayAll` / `get24Hours` share ~80% structure copy-pasted 3 times |
| Force-unwrap epidemic | High | Every file — `itemDate!`, `dc!`, `breakdownInfo!` — guaranteed crashes on edge cases |
| No dependency injection | High | `NSApp.delegate as? AppDelegate` chained through the view hierarchy — untestable |
| String-based type checking | Medium | `String(describing: type(of: item)) == "EKEvent"` instead of `item is EKEvent` |
| Settings naming collision | Medium | `class Settings` wraps `struct Settings` — same name, confusing |
| Date extensions in two files | Medium | Declared in both `NextEventViewController.swift` and `CalendarTools.swift` |
| Duplicated about/help code | Medium | `openAbout` and `openHelp` in AppDelegate are 90% identical |
| N/A sentinel events | Medium | Fake `EKEvent(title: "N/A")` as empty-list placeholder — fragile |
| Known bugs left unfixed | Low | `requestAccess()` always returns true; `getReminderListNames()` queries `.event` instead of `.reminder` |
| Zero tests | High | No unit tests, no UI tests |
| Storyboard-based UI | Low | Hard to code review, merge, and refactor |

---

## Target Architecture (8+/10)

```
┌─────────────────────────────────────────────────────────────┐
│                        AppDelegate                          │
│  (thin: bootstrapping only — DI container + app lifecycle)  │
└──────┬──────────┬──────────┬──────────┬─────────────────────┘
       │          │          │          │
       ▼          ▼          ▼          ▼
┌──────────┐ ┌────────┐ ┌────────┐ ┌──────────────┐
│ MenuBar  │ │ Popover│ │ Widget │ │ Notification │
│ Manager  │ │ Manager│ │ Manager│ │   Manager    │
└──────────┘ └────────┘ └────────┘ └──────────────┘
       │          │          │          │
       └──────────┴──────────┴──────────┘
                      │
                      ▼
           ┌──────────────────┐
           │   EventService   │  ◄── protocol
           │ (CalendarTools)  │
           └──────────────────┘
                      │
       ┌──────────────┼──────────────┐
       ▼              ▼              ▼
┌────────────┐ ┌────────────┐ ┌──────────────┐
│  Settings  │ │ TimeFormat │ │  Extensions  │
│  (struct)  │ │ (utility)  │ │  (Date+... ) │
└────────────┘ └────────────┘ └──────────────┘
```

Key principles:
- **Protocols at module boundaries** — every service behind a protocol, injected at boot
- **View controllers own views only** — no data fetching, no notification scheduling, no time math
- **Single source of truth** — one way to get events, one way to format time, one settings struct

---

## Improvement Phases

### Phase 1: Foundation Fixes (Target: 6/10)

**Effort:** ~4-6 hours. **Risk:** Low. These are surgical fixes — no architectural changes.

#### 1.1 Fix Settings Naming Collision

Rename the outer wrapper or the inner struct. Suggestion: keep `class Settings` as the persistence wrapper, rename inner to `SettingsData` or `AppSettings`.

```swift
// Before
class Settings: NSObject {
    struct Settings: Codable { ... }
    var settings: Settings = Settings()
}

// After
class Settings: NSObject {
    struct Data: Codable { ... }
    var data: Data = Data()  // was `settings.settings`
}
```

Every `settings.settings.xxx` becomes `settings.data.xxx` — a mechanical rename across the project.

#### 1.2 Consolidate Date Extensions

Move all Date extensions to a single file: `DateExtensions.swift`.

```
BmoCal/
  DateExtensions.swift  ← all Date extensions live here
    - toLocalTime(), toGlobalTime(), toString(format:)
    - startOfDay, endOfDay, startOfNextDay
```

Remove the duplicate declarations from `NextEventViewController.swift` and `CalendarTools.swift`.

#### 1.3 Replace String-Based Type Checking

```swift
// Before — fragile, string-dependent
if String(describing: type(of: item)) == "EKEvent" {
    itemDate = (item as! EKEvent).startDate
}

// After — proper Swift type checking
if let event = item as? EKEvent {
    itemDate = event.startDate
} else if let reminder = item as? EKReminder {
    if let dc = reminder.dueDateComponents {
        itemDate = Calendar.current.date(from: dc)
    }
}
```

Apply across `getDateFromEventItem`, `getLocationFromEventItem`, `getTravelTimeFromEventItem`, `isAllDay`.

#### 1.4 Fix Known Bugs

- **`CalendarTools.requestAccess()`**: Use `DispatchGroup` (as already done for reminders) to make it actually synchronous and return the real result.
- **`CalendarTools.getReminderListNames()`**: Query `.reminder` entity type instead of `.event`.

#### 1.5 Clean Up Force-Unwraps

Audit all `!` usages. Priority order:
1. Replace with `guard let` where nil is a recoverable state
2. Replace with optional chaining (`?.`) where downstream is nil-tolerant
3. Only keep `!` where nil is truly a programmer error (fatalError with message)

```swift
// Before
itemDate = (item as! EKEvent).startDate
let dc = (reminder as! EKReminder).dueDateComponents
let date = Calendar.current.date(from: dc!)!

// After
guard let event = item as? EKEvent,
      let startDate = event.startDate else { return nil }
itemDate = startDate
```

#### 1.6 Replace N/A Sentinel with Optional

`CalendarTools` methods return `[EKCalendarItem]` with a fake event appended. Instead, return the actual (possibly empty) array, and handle empty state in the view layer.

```swift
// Before — CalendarTools
if results.count <= 0 {
    let newItem = EKEvent(eventStore: EKEventStore())
    newItem.title = "N/A"
    results.append(newItem)
}

// After — handle in view
// CalendarTools returns [] naturally
// NextEventViewController checks isEmpty and shows appropriate UI
```

---

### Phase 2: Architectural Separation (Target: 7/10)

**Effort:** ~8-12 hours. **Risk:** Medium. Extracts responsibilities but preserves existing behavior.

#### 2.1 Extract MenuBarManager from AppDelegate

Pull all menu bar status item logic into its own type:

```swift
class MenuBarManager {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    
    init(statusItem: NSStatusItem, popoverContent: NSViewController, menu: NSMenu)
    
    var statusTitle: NSAttributedString?  // get/set the attributed title
    var statusIcon: NSImage?              // get/set the icon image
    
    func onLeftClick()   // toggle popover
    func onRightClick()  // show context menu
    func updateWidgetMenuItem(showing: Bool)  // "Show/Hide Widget" label
}
```

AppDelegate becomes: owns MenuBarManager, passes it the view controller, done.

#### 2.2 Extract NotificationManager

Pull `notify()`, `alert()`, `registerNotification()` out of `NextEventViewController`:

```swift
protocol NotificationManaging {
    func evaluateAndNotify(events: [EKCalendarItem], settings: Settings.Data)
}

class NotificationManager: NotificationManaging {
    func evaluateAndNotify(events: [EKCalendarItem], settings: Settings.Data) {
        // takes events + settings, fires system alerts / blocking alerts / sounds
        // no view coupling
    }
}
```

#### 2.3 Extract StatusStringBuilder

Pull `getNextEventStatus()` and the three-state workday logic out of `NextEventViewController`:

```swift
struct StatusStringBuilder {
    let settings: Settings.Data
    let events: [EKCalendarItem]
    let timeTools: TimeStringTools
    
    func build() -> (status: String, shouldGlow: Bool) {
        // before-workday / during-workday / after-workday logic
    }
}
```

This becomes a pure function — input settings + events, output string + glow flag. Trivially testable.

#### 2.4 Deduplicate CalendarTools Query Methods

All three query methods follow the same pattern: fetch reminders → fetch events → collect in dict → sort → return with placeholder. Extract the shared core:

```swift
private func queryEventsAndReminders(
    eventStart: Date, eventEnd: Date,
    reminderStart: Date, reminderEnd: Date,
    calendars: [EKCalendar], reminders: [EKCalendar],
    filter: ((Date) -> Bool)? = nil
) -> [EKCalendarItem]
```

Then `getTopN`, `getTodayAll`, `get24Hours` become thin wrappers that configure date ranges and post-filters.

#### 2.5 Deduplicate AppDelegate about/help Methods

`openAbout` and `openHelp` are identical except for `forceHelp(true)` vs `forceHelp(false)`. Extract:

```swift
private func openAboutBox(forceHelp: Bool) {
    // shared code
}
```

Then `openAbout` and `openHelp` become single-line calls.

---

### Phase 3: Testability & Protocols (Target: 8/10)

**Effort:** ~10-16 hours. **Risk:** Medium-High. Introduces abstractions and tests.

#### 3.1 Protocol-ize CalendarTools

```swift
protocol EventStoreProtocol {
    func getTopN(n: Int, calendars: [EKCalendar], reminders: [EKCalendar]) -> [EKCalendarItem]
    func getTodayEvents(calendars: [EKCalendar]) -> [EKEvent]
    func getCalendarByNames(names: [String]) -> [EKCalendar]
    func getReminderListByNames(names: [String]) -> [EKCalendar]
    func requestAccess() -> Bool
}

class CalendarTools: EventStoreProtocol { ... }
```

Everything that currently constructs `CalendarTools()` locally gets the protocol injected instead.

#### 3.2 Protocol-ize Settings Access

```swift
protocol SettingsProviding {
    var data: Settings.Data { get set }
    func archive()
    func reset()
}
```

Break the `NSApp.delegate as? AppDelegate` → `.settings` chain. Instead, inject a `SettingsProviding` instance at boot.

#### 3.3 Introduce a Dependency Container

A lightweight DI container (no framework needed — just a struct) assembled in `applicationDidFinishLaunching`:

```swift
struct AppDependencies {
    let settings: SettingsProviding
    let eventStore: EventStoreProtocol
    let timeTools: TimeStringTools
    let menuBarManager: MenuBarManager
    let notificationManager: NotificationManaging
    let widgetManager: WidgetManaging
}

// In AppDelegate.applicationDidFinishLaunching:
let deps = AppDependencies(
    settings: Settings(),
    eventStore: CalendarTools(),
    timeTools: TimeStringTools(),
    ...
)
// Inject into view controllers
```

#### 3.4 Add Unit Tests

Test the pure components first (highest ROI):

| Test Target | What to Test |
|-------------|-------------|
| `TimeStringTools` | `getTimeString`, `getLeadTime`, `workdayProgressBar`, `workdayRemainingString`, `getFuzzyTimeString` |
| `StatusStringBuilder` | Before-workday output, during-workday output, after-workday output, edge cases (midnight, exact boundaries) |
| `Settings` | Archive/unarchive round-trip, reset correctness |
| `CalendarTools` (with mock EKEventStore) | `getTopN` returns correct count, empty state, sort order |
| `WorkdayWidgetView` | `timeToAngle` conversion correctness for known inputs |

Target: 70%+ coverage on the business logic layer. View/AppKit layer can wait.

#### 3.5 Migrate from Storyboard to Code-Based UI (Stretch Goal)

Long-term: move view layout out of `.storyboard` files into code. Benefits:
- Diffable in git
- No merge conflicts
- Easier to refactor
- `freshController()` factory methods become straightforward `init()`

This is a large effort (likely 8-12 hours) and should come after the other phases. If done, target the simpler windows first (MZAboutBox, MZAlertBox) before tackling Main.storyboard.

---

## Implementation Order & Dependencies

```
Phase 1 (independent items, can parallelize):
  1.1 Settings naming  ──┐
  1.2 Date extensions  ──┤
  1.3 String type check──┤ all independent
  1.4 Known bugs       ──┤
  1.5 Force-unwraps    ──┤
  1.6 N/A sentinel     ──┘

Phase 2 (depends on Phase 1 completion):
  2.4 Dedup queries    ──┐
  2.5 Dedup about/help ──┤ all independent of each other
  2.1 MenuBarManager   ──┤
  2.2 NotificationMgr  ──┤
  2.3 StatusBuilder    ──┘

Phase 3 (depends on Phase 2 protocols being in place):
  3.1 Protocol CalendarTools
  3.2 Protocol Settings
  3.3 DI Container
  3.4 Unit Tests ──────── depends on 3.1, 3.2, 3.3
  3.5 Code-based UI ──── independent stretch goal
```

---

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Settings rename breaks runtime | Low | Mechanical rename with project-wide search-replace; settings file format unchanged (`Codable` keys match) |
| Extracted managers lose behavior | Medium | Extract one manager at a time; verify app runs after each extraction; keep old code as reference |
| DI container adds boilerplate | Low | Keep it a simple struct, not a framework; only inject what's used |
| EKEventStore mock is flaky | Medium | Protocolize the exact surface area used; use a fake, not a partial mock |
| Storyboard removal breaks layout | High | Do this last; tackle one window at a time; compare screenshots |

---

## Success Criteria (Score 8+)

- [ ] No force-unwraps without a `fatalError("reason")` message
- [ ] No string-based type checks (`String(describing: type(of:))`)
- [ ] No duplicate Date extensions
- [ ] `CalendarTools` has a single core query method, wrappers are ≤10 lines each
- [ ] `AppDelegate` is ≤100 lines (bootstrapping only)
- [ ] `NextEventViewController` has no data-fetching, no notification logic, no time math
- [ ] All service boundaries are protocol-based
- [ ] 70%+ unit test coverage on business logic (TimeStringTools, StatusBuilder, Settings, CalendarTools query logic)
- [ ] DI container assembles all dependencies in one place
- [ ] Known bugs (`requestAccess`, `getReminderListNames`) are fixed
- [ ] Settings inner/outer naming collision resolved

---

## Swift's Approach to Growing Codebases

Swift gives you several tools that directly address the problems this codebase faces:

**Protocol-oriented programming** — Swift's headline feature. Define a protocol for every service boundary, then swap implementations. This is how you make CalendarTools testable: a real `EKEventStore` implementation and a fake one both conform to the same protocol.

**Extensions for separation** — You can keep a type's core definition small and add table view delegate conformance in a separate extension. `NextEventViewController` already does this for `NSTableViewDataSource` — extend the pattern to notification logic, data fetching, and status formatting.

**Value types (structs)** — `Settings.Data` is already a struct (good). `StatusStringBuilder` can be one too — no mutation, no reference semantics, trivially testable. Use structs for data, classes for identity.

**Access control** — `private`, `fileprivate`, `internal` let you enforce boundaries. The `MenuBarManager` shouldn't expose its internal `Timer`; the `EventStoreProtocol` shouldn't leak `EKEventStore` types.

**Swift Package Manager** — Not needed yet, but as the app grows, you can split into packages: `BmoCalCore` (settings, time tools, protocols), `BmoCalCalendar` (EventKit wrapper), `BmoCalUI` (views). This forces module boundaries and makes dependency direction explicit.

**Result type and error handling** — Replace the `Bool` return from `requestAccess()` with `Result<Void, Error>`. Replace force-unwraps with `guard let`/`throw` chains. Swift's `throws` gives you structured error propagation that `!` does not.

The path from 5/10 to 8/10 is fundamentally about applying these Swift-native patterns — protocols at the edges, structs for pure data, extensions for concern separation — and then backing them with tests.
