# Graph Report - .  (2026-05-13)

## Corpus Check
- 14 files · ~499,985 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 241 nodes · 317 edges · 28 communities detected
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 4 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]

## God Nodes (most connected - your core abstractions)
1. `AppDelegate` - 29 edges
2. `NextEventViewController` - 25 edges
3. `CalendarTools` - 23 edges
4. `NextEventPreferencesViewController` - 13 edges
5. `TimeStringTools` - 13 edges
6. `WorkdayWidgetView` - 13 edges
7. `WorkdayWidgetView` - 13 edges
8. `Date` - 11 edges
9. `MZAboutBoxViewController` - 11 edges
10. `NextEvent Application Icon Set` - 11 edges

## Surprising Connections (you probably didn't know these)
- `Mazookie Full Logo (300x88, help document)` --semantically_similar_to--> `Mazookie Name Logo Sticker Asset`  [INFERRED] [semantically similar]
  NextEvent/help.rtfd/Mazookie_full_logo_small.png → NextEvent/Assets.xcassets/mazookie_name_logo_sticker_small.imageset
- `NextEvent Application (macOS Menu Bar Countdown Widget)` --conceptually_related_to--> `NextEvent Application Icon Set`  [INFERRED]
  README.md → NextEvent/Assets.xcassets/AppIcon.appiconset
- `NextEvent Application Icon Set` --conceptually_related_to--> `App Icon @1x (16×16)`  [EXTRACTED]
  NextEvent/Assets.xcassets/AppIcon.appiconset → NextEvent/Assets.xcassets/AppIcon.appiconset/icon_16x16.png
- `NextEvent Application Icon Set` --conceptually_related_to--> `App Icon @2x (32×32)`  [EXTRACTED]
  NextEvent/Assets.xcassets/AppIcon.appiconset → NextEvent/Assets.xcassets/AppIcon.appiconset/icon_16x16@2x.png
- `NextEvent Application Icon Set` --conceptually_related_to--> `App Icon @1x (32×32)`  [EXTRACTED]
  NextEvent/Assets.xcassets/AppIcon.appiconset → NextEvent/Assets.xcassets/AppIcon.appiconset/icon_32x32.png

## Hyperedges (group relationships)
- **Event Notification Pipeline** — appdelegate_main, nexteventviewcontroller_notification, alertboxvc_main, concept_blocking_alert, concept_flash_alert [INFERRED 0.85]
- **Settings & Configuration Flow** — settings_persistence, settings_struct, preferencesvc_main, preferencesvc_calendar_selector [INFERRED 0.90]
- **Core App Architecture (MVC + Coordinator)** — appdelegate_main, nexteventviewcontroller_main, calendartools_main, timestringtools_main, settings_persistence [INFERRED 0.90]
- **macOS App Icon Resolution Set (1x, 2x)** — appicon_16, appicon_32, appicon_32_base, appicon_64, appicon_128, appicon_256, appicon_256_base, appicon_512, appicon_512_base, appicon_1024 [EXTRACTED 1.00]
- **Menu Bar Icon Style Variants (Default + Orange + Blue)** — menubar_icon_nextevent_mb, menubar_icon_nextevent_mb_orange, menubar_icon_nextevent_mb_blue, menubar_icon_mazookie_mb, menubar_icon_mazookie_mb_orange, menubar_icon_mazookie_mb_blue [EXTRACTED 1.00]
- **Glow Effect Icons (Orange & Blue Variants)** — menubar_icon_nextevent_orange_glow, menubar_icon_nextevent_orange_glow2x, menubar_icon_nextevent_blue_glow, menubar_icon_nextevent_blue_glow2x [EXTRACTED 1.00]
- **Toolbar UI Button Controls** — reminders_16_png, reminders_32_png, calendar_16_png, calendar_32_png, gear16_png, gear32_png [INFERRED 0.80]

## Communities

### Community 0 - "Community 0"
Cohesion: 0.13
Nodes (5): Date, KSTableCellView, NextEventViewController, NSTableCellView, NSTableViewDataSource

### Community 1 - "Community 1"
Cohesion: 0.13
Nodes (2): AppDelegate, NSApplicationDelegate

### Community 2 - "Community 2"
Cohesion: 0.14
Nodes (2): CalendarTools, Date

### Community 3 - "Community 3"
Cohesion: 0.09
Nodes (22): App Icon @2x (1024×1024), App Icon @1x (128×128), App Icon @1x (16×16), App Icon @2x (256×256), App Icon @1x (256×256), App Icon @2x (32×32), App Icon @1x (32×32), App Icon @2x (512×512) (+14 more)

### Community 4 - "Community 4"
Cohesion: 0.12
Nodes (4): MZAlertBoxWindowController, NSWindowController, WorkdayWidgetWindowController, WorkdayWidgetWindowController

### Community 5 - "Community 5"
Cohesion: 0.16
Nodes (2): NSObject, TimeStringTools

### Community 6 - "Community 6"
Cohesion: 0.19
Nodes (2): NSView, WorkdayWidgetView

### Community 7 - "Community 7"
Cohesion: 0.21
Nodes (1): WorkdayWidgetView

### Community 8 - "Community 8"
Cohesion: 0.26
Nodes (2): NextEventPreferencesViewController, NSTableViewDelegate

### Community 9 - "Community 9"
Cohesion: 0.24
Nodes (1): MZAboutBoxViewController

### Community 10 - "Community 10"
Cohesion: 0.27
Nodes (2): MZAlertBoxViewController, NSViewController

### Community 11 - "Community 11"
Cohesion: 0.43
Nodes (2): Codable, Settings

### Community 12 - "Community 12"
Cohesion: 0.4
Nodes (5): Mazookie Menu Bar Icon (Orange Variant), Mazookie Orange Icon Black @1x (20×20), Mazookie Orange Icon Black @2x (40×40), Mazookie Orange Icon White @1x (20×20), Mazookie Orange Icon White @2x (40×40)

### Community 13 - "Community 13"
Cohesion: 0.4
Nodes (5): Mazookie Blue Icon Black @1x (20×20), Mazookie Blue Icon Black @2x (40×40), Mazookie Blue Icon White @1x (20×20), Mazookie Blue Icon White @2x (40×40), Mazookie Menu Bar Icon (Blue Variant)

### Community 14 - "Community 14"
Cohesion: 0.67
Nodes (1): SampleEvent

### Community 15 - "Community 15"
Cohesion: 0.67
Nodes (3): Mazookie Menu Bar Icon (Default Black), Mazookie MB Icon Black @1x (20×20), Mazookie MB Icon Black @2x (40×40)

### Community 16 - "Community 16"
Cohesion: 0.67
Nodes (3): NextEvent Menu Bar Icon (Default), NextEvent MB Glow Effect @1x, NextEvent MB Glow Effect @2x

### Community 17 - "Community 17"
Cohesion: 0.67
Nodes (3): NextEvent Menu Bar Icon (Orange Glow Variant), NextEvent MB Orange Glow @1x, NextEvent MB Orange Glow @2x

### Community 18 - "Community 18"
Cohesion: 0.67
Nodes (3): NextEvent MB Blue Glow @1x, NextEvent MB Blue Glow @2x, NextEvent Menu Bar Icon (Blue Glow Variant)

### Community 19 - "Community 19"
Cohesion: 1.0
Nodes (2): Mazookie Full Logo (300x88, help document), Mazookie Name Logo Sticker Asset

### Community 20 - "Community 20"
Cohesion: 1.0
Nodes (2): Reminders Icon @1x (16x16), Reminders Icon @2x (32x32)

### Community 21 - "Community 21"
Cohesion: 1.0
Nodes (2): Calendar Icon @1x (16x16), Calendar Icon @2x (32x32)

### Community 22 - "Community 22"
Cohesion: 1.0
Nodes (2): Gear Icon @1x (16x16), Gear Icon @2x (32x32)

### Community 23 - "Community 23"
Cohesion: 1.0
Nodes (0): 

### Community 24 - "Community 24"
Cohesion: 1.0
Nodes (1): Acknowledgments (MIT License)

### Community 25 - "Community 25"
Cohesion: 1.0
Nodes (1): NextEvent App Screenshot (3840x2160)

### Community 26 - "Community 26"
Cohesion: 1.0
Nodes (1): Help Illustration - Menu Bar Countdown Widget (400x330)

### Community 27 - "Community 27"
Cohesion: 1.0
Nodes (1): Help Screenshot - Preferences Window (250x534)

## Knowledge Gaps
- **45 isolated node(s):** `SampleEvent`, `Version History (2.2.1, 2.2.3, 2.2.4)`, `Acknowledgments (MIT License)`, `macOS Menu Bar Widget Pattern`, `Apple EventKit Integration (Calendar + Reminders)` (+40 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 19`** (2 nodes): `Mazookie Full Logo (300x88, help document)`, `Mazookie Name Logo Sticker Asset`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 20`** (2 nodes): `Reminders Icon @1x (16x16)`, `Reminders Icon @2x (32x32)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 21`** (2 nodes): `Calendar Icon @1x (16x16)`, `Calendar Icon @2x (32x32)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 22`** (2 nodes): `Gear Icon @1x (16x16)`, `Gear Icon @2x (32x32)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 23`** (1 nodes): `NextEvent-Bridging-Header.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 24`** (1 nodes): `Acknowledgments (MIT License)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 25`** (1 nodes): `NextEvent App Screenshot (3840x2160)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 26`** (1 nodes): `Help Illustration - Menu Bar Countdown Widget (400x330)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 27`** (1 nodes): `Help Screenshot - Preferences Window (250x534)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `NextEventViewController` connect `Community 0` to `Community 8`, `Community 10`?**
  _High betweenness centrality (0.059) - this node is a cross-community bridge._
- **Why does `AppDelegate` connect `Community 1` to `Community 5`?**
  _High betweenness centrality (0.056) - this node is a cross-community bridge._
- **Why does `MZAlertBoxViewController` connect `Community 10` to `Community 4`?**
  _High betweenness centrality (0.051) - this node is a cross-community bridge._
- **What connects `SampleEvent`, `Version History (2.2.1, 2.2.3, 2.2.4)`, `Acknowledgments (MIT License)` to the rest of the system?**
  _45 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.13 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.13 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.14 - nodes in this community are weakly interconnected._