# BmoCal

A macOS menu bar app that shows workday progress and upcoming calendar events.

## Language

**Workday**:
The configured time span from `workdayStartHour` to `workdayEndHour` within which events and progress are tracked.
_Avoid_: work hours, business hours

**Circular Widget**:
The existing floating window showing a clock-face timeline of today's events as arcs on a circle.
_Avoid_: widget (ambiguous now that two exist), clock widget

**Vertical Widget**:
A tall narrow floating window showing the workday as a vertical linear timeline — top = workday start, bottom = workday end.
_Avoid_: bar widget, sidebar widget

**Event Pill**:
A rounded rectangle segment in the Vertical Widget representing one calendar event. Height is proportional to the event's duration. Lighter opacity = past event; full opacity = future event.
_Avoid_: event block, event bar, event segment

**Now Pointer**:
The red dot and horizontal line in the Vertical Widget indicating the current time position on the timeline. The dot floats to the left of the track; the line connects it to the bar.
_Avoid_: current time indicator, time dot

**Free Time**:
Empty vertical space between Event Pills in the Vertical Widget, representing a calendar gap with no scheduled events.
_Avoid_: gap, empty time, idle time

**Track**:
The narrow rounded rectangle forming the background of the Vertical Widget's timeline, inside which Event Pills are drawn.
_Avoid_: bar, column, timeline bar

## Relationships

- A **Workday** contains zero or more **Event Pills** separated by **Free Time**
- The **Now Pointer** always sits at the current time position along the **Track**
- The **Circular Widget** and **Vertical Widget** show the same underlying event data independently

## Flagged ambiguities

- "widget" alone is ambiguous — resolved: always say **Circular Widget** or **Vertical Widget**
