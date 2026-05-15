# Vertical Widget — Feature Summary

## Overview

A new floating window that shows today's workday as a vertical linear timeline. Complements the existing Circular Widget — both can be open simultaneously.

## Design

**Visual reference:** `vertical-desktip-widget.png`

| Element | Description |
|---------|-------------|
| Shape | Tall narrow pill (white rounded rect, soft drop shadow) |
| Dimensions | 64px wide × 400px tall (default; configurable) |
| Track | Centered 28px-wide rounded bar representing the full workday |
| Top of track | Workday start (`workdayStartHour`) |
| Bottom of track | Workday end (`workdayEndHour`) |
| Event Pills | Rounded rectangles; height proportional to event duration |
| Past events | Calendar color at 35% opacity |
| Future/current events | Calendar color at 85% opacity |
| Free time | Empty track space between pills |
| Now Pointer | Red dot to the left of track + horizontal line pointing at current-time Y position |
| Text | None |

## Interaction

- **Drag:** Click anywhere on the widget body to reposition. Position persists across launches.
- **Right-click menu:** "Float on Top" toggle (independent from Circular Widget) + "Close Widget"

## New Settings Fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `showVerticalWidget` | Bool | false | Visibility toggle |
| `verticalWidgetFloatsOnTop` | Bool | true | Independent float-on-top setting |
| `verticalWidgetX` | Double | -1 | Saved X position |
| `verticalWidgetY` | Double | -1 | Saved Y position |
| `verticalWidgetHeight` | Double | 400 | Bar height in points |

## Files

| File | Role |
|------|------|
| `BmoCal/VerticalWidgetView.swift` | CoreGraphics NSView — draws track, event pills, now pointer, background pill |
| `BmoCal/VerticalWidgetWindowController.swift` | Borderless 64×400px NSWindow; tick/refresh interface |
| `BmoCal/Settings.swift` | Added 5 new `verticalWidget*` fields to `Settings.Data` |
| `BmoCal/AppDelegate.swift` | `showVerticalWidget`, `hideVerticalWidget`, `toggleVerticalWidget`, `refreshVerticalWidgetEvents`; "Show Vertical Widget" menu item |

## Key Geometry

```swift
// Maps decimal hour to NSView Y coordinate (Y-up: workday start = top)
timeToY(t) = trackTop - (t - workStart) / (workEnd - workStart) * trackHeight
```

## Design Decisions

1. **Coexists with Circular Widget** — both can be open at the same time; separate menu toggles
2. **No text** — pure visual timeline; event identity from color only
3. **Fixed height** — avoids tiny pills on short events; adjustable in preferences
4. **Independent float-on-top** — each widget has its own `floatsOnTop` setting
5. **Same drag + context menu pattern** as Circular Widget
