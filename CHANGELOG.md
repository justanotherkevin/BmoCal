# Changelog

## Unreleased

- Clicking the menu bar item now opens a native menu instead of a popover. The menu lists events grouped by day, shows the next event in bold accent color, and strikes through events you declined.
- Clicking an event in the menu opens it in Calendar, and the menu has new "Open Calendar", "Open Reminders" and "Help..." items.
- The app no longer contains the original author's logo, icons, copyright line or App Store link, and the alternate "M" menu bar icon option is gone.
- The about box and the event alert were renamed from their old "MZ" names to AboutPanel and EventNotificationAlert.
- The Preferences window no longer has blank space at the top, and its title, the about text and the help file now say BmoCal.
- A settings file that is missing a setting now loads that setting's default. Before, one missing setting reset every setting.
- CLAUDE.md is no longer tracked by git.
- The README credits NextEvent by Mazookie as the app that inspired BmoCal.
- The round workday widget now opens at the top left of the main screen by default, and the vertical widget opens on the left edge below it.
- A widget whose saved position is off every connected screen now opens at its default position, so it no longer disappears after you change your monitor layout.
- Widgets can now keep a saved position on a monitor to the left of the main screen.
- The menu bar menu has a new "Reset Widget Positions" item that moves every widget back to its default position.
- The bundle ID changed to com.Bmocal.Workday, so settings saved under the old ID are not carried over.
- The storyboards use the current Xcode format, and git no longer tracks .DS_Store.
- The README has a demo screenshot of the widgets.
