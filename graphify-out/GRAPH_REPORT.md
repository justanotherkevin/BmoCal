# Graph Report - .  (2026-05-10)

## Corpus Check
- 49 files · ~358,729 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 219 nodes · 298 edges · 21 communities detected
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 15 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Cross-Cutting Concepts & Docs|Cross-Cutting Concepts & Docs]]
- [[_COMMUNITY_NextEventViewController Methods|NextEventViewController Methods]]
- [[_COMMUNITY_AppDelegate Methods|AppDelegate Methods]]
- [[_COMMUNITY_CalendarTools EventKit Methods|CalendarTools EventKit Methods]]
- [[_COMMUNITY_Glow Effect Menu Bar Icons|Glow Effect Menu Bar Icons]]
- [[_COMMUNITY_Time Formatting Utilities|Time Formatting Utilities]]
- [[_COMMUNITY_Alert Box Controller|Alert Box Controller]]
- [[_COMMUNITY_Preferences View Controller|Preferences View Controller]]
- [[_COMMUNITY_About Box Controller|About Box Controller]]
- [[_COMMUNITY_App Icon Resolution Set|App Icon Resolution Set]]
- [[_COMMUNITY_Settings Persistence|Settings Persistence]]
- [[_COMMUNITY_Default Menu Bar Icons|Default Menu Bar Icons]]
- [[_COMMUNITY_Mazookie Brand Logos|Mazookie Brand Logos]]
- [[_COMMUNITY_Reminder Button Icon|Reminder Button Icon]]
- [[_COMMUNITY_Calendar Button Icon|Calendar Button Icon]]
- [[_COMMUNITY_Settings Button Icon|Settings Button Icon]]
- [[_COMMUNITY_Bridging Header|Bridging Header]]
- [[_COMMUNITY_Calendar Access Request|Calendar Access Request]]
- [[_COMMUNITY_App Screenshot|App Screenshot]]
- [[_COMMUNITY_Help Menu Bar Widget|Help: Menu Bar Widget]]
- [[_COMMUNITY_Help Preferences Window|Help: Preferences Window]]

## God Nodes (most connected - your core abstractions)
1. `NextEventViewController` - 25 edges
2. `AppDelegate` - 25 edges
3. `CalendarTools` - 22 edges
4. `NextEventPreferencesViewController` - 13 edges
5. `TimeStringTools` - 13 edges
6. `AppDelegate - Application Entry Point & Coordinator` - 13 edges
7. `Date` - 11 edges
8. `MZAboutBoxViewController` - 11 edges
9. `NextEvent Application Icon Set` - 11 edges
10. `MZAlertBoxViewController` - 10 edges

## Surprising Connections (you probably didn't know these)
- `AppDelegate - Application Entry Point & Coordinator` --conceptually_related_to--> `macOS Menu Bar Widget Pattern`  [INFERRED]
  NextEvent/AppDelegate.swift → README.md
- `Menu Bar Icon Glow Effect` --conceptually_related_to--> `15-Minute Flash Warning for Upcoming Events`  [INFERRED]
  NextEvent/AppDelegate.swift → README.md
- `AppDelegate - Application Entry Point & Coordinator` --conceptually_related_to--> `15-Minute Flash Warning for Upcoming Events`  [INFERRED]
  NextEvent/AppDelegate.swift → README.md
- `AppDelegate - Application Entry Point & Coordinator` --conceptually_related_to--> `NextEvent Application (macOS Menu Bar Countdown Widget)`  [INFERRED]
  NextEvent/AppDelegate.swift → README.md
- `Event Notification System (Blocking + System Alerts)` --conceptually_related_to--> `Blocking Alert on Event Start`  [INFERRED]
  NextEvent/NextEventViewController.swift → README.md

## Hyperedges (group relationships)
- **Event Notification Pipeline** — appdelegate_main, nexteventviewcontroller_notification, alertboxvc_main, concept_blocking_alert, concept_flash_alert [INFERRED 0.85]
- **Settings & Configuration Flow** — settings_persistence, settings_struct, preferencesvc_main, preferencesvc_calendar_selector [INFERRED 0.90]
- **Core App Architecture (MVC + Coordinator)** — appdelegate_main, nexteventviewcontroller_main, calendartools_main, timestringtools_main, settings_persistence [INFERRED 0.90]
- **macOS App Icon Resolution Set (1x, 2x)** — appicon_16, appicon_32, appicon_32_base, appicon_64, appicon_128, appicon_256, appicon_256_base, appicon_512, appicon_512_base, appicon_1024 [EXTRACTED 1.00]
- **Menu Bar Icon Style Variants (Default + Orange + Blue)** — menubar_icon_nextevent_mb, menubar_icon_nextevent_mb_orange, menubar_icon_nextevent_mb_blue, menubar_icon_mazookie_mb, menubar_icon_mazookie_mb_orange, menubar_icon_mazookie_mb_blue [EXTRACTED 1.00]
- **Glow Effect Icons (Orange & Blue Variants)** — menubar_icon_nextevent_orange_glow, menubar_icon_nextevent_orange_glow2x, menubar_icon_nextevent_blue_glow, menubar_icon_nextevent_blue_glow2x [EXTRACTED 1.00]
- **Toolbar UI Button Controls** — reminders_16_png, reminders_32_png, calendar_16_png, calendar_32_png, gear16_png, gear32_png [INFERRED 0.80]

## Communities

### Community 0 - "Cross-Cutting Concepts & Docs"
Cohesion: 0.08
Nodes (34): Help Document Viewer (RTFD), MZAboutBoxViewController - About/Help Dialog, Acknowledgments (MIT License), In-Alert Countdown Timer Display, MZAlertBoxViewController - Blocking Event Alert, AppDelegate - Application Entry Point & Coordinator, NSPopover (Event List Popup), 1-Second Timer Loop for UI Updates (+26 more)

### Community 1 - "NextEventViewController Methods"
Cohesion: 0.13
Nodes (4): Date, KSTableCellView, NextEventViewController, NSTableCellView

### Community 2 - "AppDelegate Methods"
Cohesion: 0.14
Nodes (2): AppDelegate, NSApplicationDelegate

### Community 3 - "CalendarTools EventKit Methods"
Cohesion: 0.14
Nodes (2): CalendarTools, Date

### Community 4 - "Glow Effect Menu Bar Icons"
Cohesion: 0.12
Nodes (17): Menu Bar Icon Glow Effect, Mazookie Blue Icon Black @1x (20×20), Mazookie Blue Icon Black @2x (40×40), Mazookie Blue Icon White @1x (20×20), Mazookie Blue Icon White @2x (40×40), Mazookie Menu Bar Icon (Blue Variant), Mazookie Menu Bar Icon (Orange Variant), Mazookie Orange Icon Black @1x (20×20) (+9 more)

### Community 5 - "Time Formatting Utilities"
Cohesion: 0.16
Nodes (2): NSObject, TimeStringTools

### Community 6 - "Alert Box Controller"
Cohesion: 0.18
Nodes (4): MZAlertBoxViewController, MZAlertBoxWindowController, NSViewController, NSWindowController

### Community 7 - "Preferences View Controller"
Cohesion: 0.23
Nodes (3): NextEventPreferencesViewController, NSTableViewDataSource, NSTableViewDelegate

### Community 8 - "About Box Controller"
Cohesion: 0.24
Nodes (1): MZAboutBoxViewController

### Community 9 - "App Icon Resolution Set"
Cohesion: 0.18
Nodes (11): App Icon @2x (1024×1024), App Icon @1x (128×128), App Icon @1x (16×16), App Icon @2x (256×256), App Icon @1x (256×256), App Icon @2x (32×32), App Icon @1x (32×32), App Icon @2x (512×512) (+3 more)

### Community 10 - "Settings Persistence"
Cohesion: 0.43
Nodes (2): Codable, Settings

### Community 11 - "Default Menu Bar Icons"
Cohesion: 0.29
Nodes (7): Status Item (Menu Bar Icon), Mazookie Menu Bar Icon (Default Black), Mazookie MB Icon Black @1x (20×20), Mazookie MB Icon Black @2x (40×40), NextEvent Menu Bar Icon (Default), NextEvent MB Glow Effect @1x, NextEvent MB Glow Effect @2x

### Community 12 - "Mazookie Brand Logos"
Cohesion: 1.0
Nodes (2): Mazookie Full Logo (300x88, help document), Mazookie Name Logo Sticker Asset

### Community 13 - "Reminder Button Icon"
Cohesion: 1.0
Nodes (2): Reminders Icon @1x (16x16), Reminders Icon @2x (32x32)

### Community 14 - "Calendar Button Icon"
Cohesion: 1.0
Nodes (2): Calendar Icon @1x (16x16), Calendar Icon @2x (32x32)

### Community 15 - "Settings Button Icon"
Cohesion: 1.0
Nodes (2): Gear Icon @1x (16x16), Gear Icon @2x (32x32)

### Community 16 - "Bridging Header"
Cohesion: 1.0
Nodes (0): 

### Community 17 - "Calendar Access Request"
Cohesion: 1.0
Nodes (1): Calendar/Reminder Access Request

### Community 18 - "App Screenshot"
Cohesion: 1.0
Nodes (1): NextEvent App Screenshot (3840x2160)

### Community 19 - "Help: Menu Bar Widget"
Cohesion: 1.0
Nodes (1): Help Illustration - Menu Bar Countdown Widget (400x330)

### Community 20 - "Help: Preferences Window"
Cohesion: 1.0
Nodes (1): Help Screenshot - Preferences Window (250x534)

## Ambiguous Edges - Review These
- `AppDelegate - Application Entry Point & Coordinator` → `Bridging Header (CommonCrypto import)`  [AMBIGUOUS]
  NextEvent/NextEvent-Bridging-Header.h · relation: conceptually_related_to

## Knowledge Gaps
- **48 isolated node(s):** `NSPopover (Event List Popup)`, `Calendar/Reminder Access Request`, `Event Table View (KSTableCellView)`, `Settings Struct (All Config Flags)`, `Fuzzy Time Formatting (tomorrow, next week, etc)` (+43 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Mazookie Brand Logos`** (2 nodes): `Mazookie Full Logo (300x88, help document)`, `Mazookie Name Logo Sticker Asset`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Reminder Button Icon`** (2 nodes): `Reminders Icon @1x (16x16)`, `Reminders Icon @2x (32x32)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Calendar Button Icon`** (2 nodes): `Calendar Icon @1x (16x16)`, `Calendar Icon @2x (32x32)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Settings Button Icon`** (2 nodes): `Gear Icon @1x (16x16)`, `Gear Icon @2x (32x32)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Bridging Header`** (1 nodes): `NextEvent-Bridging-Header.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Calendar Access Request`** (1 nodes): `Calendar/Reminder Access Request`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `App Screenshot`** (1 nodes): `NextEvent App Screenshot (3840x2160)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Help: Menu Bar Widget`** (1 nodes): `Help Illustration - Menu Bar Countdown Widget (400x330)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Help: Preferences Window`** (1 nodes): `Help Screenshot - Preferences Window (250x534)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `AppDelegate - Application Entry Point & Coordinator` and `Bridging Header (CommonCrypto import)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `AppDelegate - Application Entry Point & Coordinator` connect `Cross-Cutting Concepts & Docs` to `Default Menu Bar Icons`, `Glow Effect Menu Bar Icons`?**
  _High betweenness centrality (0.070) - this node is a cross-community bridge._
- **Why does `NextEventViewController` connect `NextEventViewController Methods` to `Alert Box Controller`, `Preferences View Controller`?**
  _High betweenness centrality (0.057) - this node is a cross-community bridge._
- **Why does `AppDelegate` connect `AppDelegate Methods` to `Time Formatting Utilities`?**
  _High betweenness centrality (0.056) - this node is a cross-community bridge._
- **What connects `NSPopover (Event List Popup)`, `Calendar/Reminder Access Request`, `Event Table View (KSTableCellView)` to the rest of the system?**
  _48 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Cross-Cutting Concepts & Docs` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._
- **Should `NextEventViewController Methods` be split into smaller, more focused modules?**
  _Cohesion score 0.13 - nodes in this community are weakly interconnected._