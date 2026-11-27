<div align="center">

# BmoCal

**A macOS menu bar calendar with a next meeting countdown, a workday progress bar, and meeting reminders from Apple Calendar.**

[![Star this repo](https://img.shields.io/github/stars/justanotherkevin/BmoCal-menu-bar-calendar?style=for-the-badge&logo=github&label=%E2%AD%90%20Star%20this%20repo&color=yellow)](https://github.com/justanotherkevin/BmoCal-menu-bar-calendar/stargazers)

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-000000?style=for-the-badge&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-native-F05138?style=for-the-badge&logo=swift&logoColor=white)
![License MIT](https://img.shields.io/github/license/justanotherkevin/BmoCal-menu-bar-calendar?style=for-the-badge)
![Latest release](https://img.shields.io/github/v/release/justanotherkevin/BmoCal-menu-bar-calendar?style=for-the-badge)

</div>

## Why BmoCal

It is easy to lose track of time when you work at a desk all day. You look up and the meeting started five minutes ago. BmoCal sits in your menu bar, counts down to your next meeting, and shows how much of your workday is left.

## Demo

The round workday clock and the vertical timeline bar, two desktop calendar widgets, in light and dark mode.

| Light                                                                                                                                | Dark                                                                                                                               |
| ------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| <img src="docs/images/round-light.png" alt="BmoCal round workday clock desktop widget in light mode on macOS" width="220">           | <img src="docs/images/round-dark.png" alt="BmoCal round workday clock desktop widget in dark mode on macOS" width="220">           |
| <img src="docs/images/vertical-light.png" alt="BmoCal vertical timeline bar desktop calendar widget in light mode on macOS" width="95"> | <img src="docs/images/vertical-dark.png" alt="BmoCal vertical timeline bar desktop calendar widget in dark mode on macOS" width="95"> |

## Features

| Feature                    | What you get                                                                                                        |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Workday progress bar       | See the time left in your day, right in the menu bar.                                                               |
| Next meeting countdown     | Count down to your next calendar event or reminder.                                                                 |
| Workday hours              | Set your own start and end hours.                                                                                   |
| Meeting reminder           | A dot appears in the menu bar 5 minutes before your next meeting.                                                   |
| Alert styles               | Pick full screen, banner, or chime. Full screen stays until you close it, in a Ring, Card, or Edge design.          |
| Many calendars             | Use multiple calendars and reminder lists.                                                                          |
| Desktop calendar widgets   | Add a round workday clock or a vertical timeline bar. Drag them anywhere and reset them from the menu bar.          |
| Update check               | The app checks GitHub releases once a day and shows an update menu item when a newer version is out.                |

BmoCal works with any calendar account added to macOS Calendar, such as iCloud, Google, and Exchange or Outlook. It is a native Swift app built with AppKit, SwiftUI, and EventKit. It has no external dependencies.

## Full screen meeting alert

The full screen alert covers your screen before a meeting starts and stays until you close it, so you can't miss the meeting. It counts down to the start time, and if the event has a meeting link, you can press Return to join or Esc to close.

To turn it on, open Preferences, go to the Notifications tab, and set Alert style to Full screen. Then pick when the alert shows (0, 1, 3, or 5 minutes early) and pick one of three designs. The Preview button shows the design you picked.

| Ring | Card | Edge |
| ---- | ---- | ---- |
| <img src="docs/images/alert-ring.png" alt="BmoCal full screen meeting alert, Ring design, with a countdown ring in the calendar color" width="260"> | <img src="docs/images/alert-card.png" alt="BmoCal full screen meeting alert, Card design, with a centered card over a dimmed screen" width="260"> | <img src="docs/images/alert-edge.png" alt="BmoCal full screen meeting alert, Edge design, with a large countdown and a progress bar along the top" width="260"> |

## Install

BmoCal needs macOS 13 Ventura or later.

1. Download `BmoCal.zip` from the [latest release](https://github.com/justanotherkevin/BmoCal-menu-bar-calendar/releases/latest).
2. Unzip it and move `BmoCal.app` to the `/Applications` folder.
3. Open `BmoCal.app`.
4. macOS will block it because the app is not notarized. Open System Settings, go to Privacy & Security, scroll down, click "Open Anyway", and confirm.
5. Grant calendar access when asked.

If you prefer the terminal, you can run this command instead of step 4:

```
xattr -cr /Applications/BmoCal.app
```

## Building from source

Open `BmoCal.xcodeproj` in Xcode and build (⌘B) or run (⌘R).

You need macOS and Xcode. There are no external dependencies and no package manager.

## Making a release

1. In Xcode, choose Product > Archive. Then choose Distribute App > Custom > Copy App. You can also build the Release configuration with `xcodebuild`.
2. Zip the app with `ditto`, which keeps the signature intact:

```
ditto -c -k --keepParent BmoCal.app BmoCal.zip
```

3. Create a GitHub release with a tag that matches the app version, for example `v2.2.4`, and attach `BmoCal.zip`. The app checks this page once a day and shows an update menu item when a newer release exists, so the tag must match the version format.

Do not commit the zip file to the repository.

## FAQ

### Does BmoCal work with Google Calendar or Outlook?

Yes. It works with any calendar account added to macOS Calendar. That includes iCloud, Google, and Exchange or Outlook accounts you add in System Settings.

### Is BmoCal free?

Yes. It is free and open source under the MIT license.

### Which macOS versions does it support?

macOS 13 Ventura or later.

### Why does macOS block it the first time I open it?

The app is not notarized. Open System Settings, go to Privacy & Security, and click "Open Anyway". Or run `xattr -cr /Applications/BmoCal.app` in the terminal.

### Does BmoCal collect my data?

No. It reads your calendars on your Mac through EventKit. The only network request it makes is to GitHub, once a day, to check for a new release.

## Alternatives and similar apps

Other macOS menu bar calendar and meeting apps include MeetingBar, Calendr, and NextEvent.

## Credits

BmoCal is inspired by NextEvent, a macOS menu bar app made by Mazookie.

## License

Released under the [MIT License](LICENSE).

<div align="center">

Built by [Kevin Hu](https://github.com/justanotherkevin)

[![Star this repo](https://img.shields.io/github/stars/justanotherkevin/BmoCal-menu-bar-calendar?style=for-the-badge&logo=github&label=%E2%AD%90%20Star%20this%20repo&color=yellow)](https://github.com/justanotherkevin/BmoCal-menu-bar-calendar/stargazers)

</div>
