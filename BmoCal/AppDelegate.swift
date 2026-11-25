import Cocoa
import EventKit

struct StatusStringBuilder {
    let settings: Settings.Data
    let events: [EKCalendarItem]
    let timeTools: TimeStringTools

    func build(now: Date = Date()) -> (status: String, shouldGlow: Bool) {
        let startHour = settings.workdayStartHour
        let endHour = settings.workdayEndHour
        let cal = Calendar.current
        let currentHour = cal.component(.hour, from: now)

        // Before workday
        if currentHour < startHour {
            var comps = cal.dateComponents([.year, .month, .day], from: now)
            comps.hour = startHour; comps.minute = 0; comps.second = 0
            let startTime = cal.date(from: comps)!
            let secs = max(0, startTime.timeIntervalSince(now))
            let h = Int(secs) / 3600
            let m = (Int(secs) % 3600) / 60
            let status = h > 0 ? "Work in \(h)h\(m)m" : "Work in \(m)m"
            return (status, false)
        }

        // Minimal implementation - just return default for other states
        return ("Workday in progress", false)
    }
}

struct AppDependencies {
    let settings: SettingsProviding
    let eventStore: EventStoreProtocol
    let timeTools: TimeStringTools
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    let GLOW_INTERVAL   = 0.1

    @IBOutlet weak var mainMenu: NSMenu!

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)

    var timer: Timer!
    var preferenceController: NSWindowController!
    var aboutBoxController: NSWindowController!
    var aboutBoxView: AboutPanelViewController!
    var settings: Settings!
    var viewController: NextEventViewController!

    var icon: NSImage!
    var glowIcon: NSImage!
    var isGlowing: Bool = false
    var yesterday: Date?

    var glowTimer: Timer!
    var imageTrans: CGFloat!
    var glowSpeed: CGFloat = 0.05
    var fadeOut: Bool = false

    var widgetController: WorkdayWidgetWindowController?
    var verticalWidgetController: VerticalWidgetWindowController?
    var dependencies: AppDependencies?


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

        // load settings and create DI container
        settings = Settings()
        self.processCommandLine()

        // Assemble dependencies
        dependencies = AppDependencies(
            settings: settings,
            eventStore: CalendarTools(),
            timeTools: TimeStringTools()
        )

        viewController = NextEventViewController.freshController()
        // The view is never shown; load it so settings and the IBOutlets are set up.
        _ = viewController.view

        self.setIcons()
        yesterday = getMidnight(date: Date())

        if let button = statusItem.button {
            button.action = #selector(self.onClickStatusItem)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem.button?.menu = mainMenu
        mainMenu.delegate = self

        // check for access and request notification
        if CalendarTools().requestAccess() == false {
            self.accessErrorDialog()
            exit(0)
        }
        self.registerNotification()
        //CalendarTools().registerNotification(#selector(itemsChanged(_:)))

        // Widget menu items — inserted at top of the status-item menu
        let verticalWidgetItem = NSMenuItem(title: "Show Vertical Widget",
                                            action: #selector(toggleVerticalWidget(_:)),
                                            keyEquivalent: "")
        verticalWidgetItem.target = self
        mainMenu.insertItem(verticalWidgetItem, at: 0)

        let widgetItem = NSMenuItem(title: "Show Workday Widget",
                                    action: #selector(toggleWidget(_:)),
                                    keyEquivalent: "")
        widgetItem.target = self
        mainMenu.insertItem(widgetItem, at: 1)
        let resetItem = NSMenuItem(title: "Reset Widget Positions",
                                   action: #selector(resetWidgetPositions(_:)),
                                   keyEquivalent: "")
        resetItem.target = self
        mainMenu.insertItem(resetItem, at: 2)
        mainMenu.insertItem(.separator(), at: 3)

        let calendarItem = NSMenuItem(title: "Open Calendar",
                                      action: #selector(NextEventViewController.launchCalendar(_:)),
                                      keyEquivalent: "")
        calendarItem.target = viewController
        mainMenu.insertItem(calendarItem, at: 4)
        let remindersItem = NSMenuItem(title: "Open Reminders",
                                       action: #selector(NextEventViewController.launchReminders(_:)),
                                       keyEquivalent: "")
        remindersItem.target = viewController
        mainMenu.insertItem(remindersItem, at: 5)
        mainMenu.insertItem(.separator(), at: 6)

        if settings.data.showWidget {
            showWidget()
        }
        if settings.data.showVerticalWidget {
            showVerticalWidget()
        }

        // Last things to do
        timer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(fireTimer(_:)),
            userInfo: nil,
            repeats: true
        )
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc func fireTimer(_ sender: Any?) {
        self.update()
    }

    func setIcons() {
        icon = NSImage(named:"next_event_mb")!

        if settings.data.useFlashBlue {
            glowIcon = NSImage(named:"next_event_mb_blue")!
        } else {
            glowIcon = NSImage(named:"next_event_mb_orange")!
        }
    }

    func getMidnight(date: Date) -> Date {
        let today = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month, .day], from: date)
        )
        return today!
    }

    func update() {

        let now = getMidnight(date: Date())
        if yesterday != now {
            yesterday = now
            viewController.refreshAll(self)
        }

        if viewController.update() == true {
            self.setIcons()
            statusItem.button?.image = icon
        }
        statusItem.button?.attributedTitle = NSAttributedString(
            string: viewController.getNextEventStatus(),
            attributes: [NSAttributedString.Key.font:  NSFont(name: "Helvetica Neue", size: 13)!]
        )
        if viewController.shouldGlow {
            if !isGlowing {
                self.startGlow()
            }
        } else if isGlowing {
            self.stopGlow()
        }

        widgetController?.tick()
        verticalWidgetController?.tick()
    }

    @objc func onClickStatusItem(sender: NSButton) {
        NSMenu.popUpContextMenu(sender.menu!, with: NSApp.currentEvent!, for: sender)
    }

    // MARK: - Event list (top of the status-item menu)

    static let eventItemTag = 9001

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === mainMenu else { return }
        for item in menu.items.reversed() where item.tag == AppDelegate.eventItemTag {
            menu.removeItem(item)
        }
        var items: [NSMenuItem] = []
        let tools = TimeStringTools()
        let cal = Calendar.current
        let next = viewController.getNextEvent()
        var lastDay: Date?
        var first = true

        for (i, item) in viewController.calendarItems.enumerated() {
            let date = viewController.getDateFromEventItem(item)
            let day = date.map { cal.startOfDay(for: $0) }
            if first || day != lastDay {
                let header = NSMenuItem(title: date.map { tools.dayHeader(for: $0) } ?? "No date:",
                                        action: nil, keyEquivalent: "")
                header.isEnabled = false
                items.append(header)
                lastDay = day
                first = false
            }

            var time = ""
            if viewController.isAllDay(item) {
                time = "All day"
            } else if let date = date {
                time = tools.getShortTimeString(date)
            }
            let title = time.isEmpty ? (item.title ?? "") : "\(time)   \(item.title ?? "")"
            let row = NSMenuItem(title: title, action: #selector(openEventItem(_:)), keyEquivalent: "")
            row.target = self
            row.representedObject = item
            var attrs: [NSAttributedString.Key: Any] = [.font: NSFont.menuFont(ofSize: 0)]
            if i == next {
                attrs[.font] = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
                attrs[.foregroundColor] = NSColor.controlAccentColor
            }
            if viewController.isDeclined(item) {
                attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            }
            row.attributedTitle = NSAttributedString(string: title, attributes: attrs)
            items.append(row)
        }

        if items.isEmpty {
            let none = NSMenuItem(title: "No upcoming events", action: nil, keyEquivalent: "")
            none.isEnabled = false
            items.append(none)
        }
        items.append(.separator())
        for (i, item) in items.enumerated() {
            item.tag = AppDelegate.eventItemTag
            menu.insertItem(item, at: i)
        }
    }

    @objc func openEventItem(_ sender: NSMenuItem) {
        if let event = sender.representedObject as? EKEvent,
           let id = event.eventIdentifier,
           let url = URL(string: "ical://ekevent/\(id)?method=show&options=more"),
           NSWorkspace.shared.open(url) {
            return
        }
        if sender.representedObject is EKReminder {
            viewController.launchReminders(sender)
        } else {
            viewController.launchCalendar(sender)
        }
    }

    @IBAction func refreshAll(_ sender: Any?) {
        viewController.refreshAll(self)
        refreshWidgetEvents()
        refreshVerticalWidgetEvents()
    }

    @objc func itemsChanged(_ notification: Notification) {
        viewController.refreshAll(self)
        refreshWidgetEvents()
        refreshVerticalWidgetEvents()
    }

    @objc func resetWidgetPositions(_ sender: Any?) {
        settings.data.widgetX = -1
        settings.data.widgetY = -1
        settings.data.verticalWidgetX = -1
        settings.data.verticalWidgetY = -1
        settings.archive()
        guard let sf = NSScreen.main?.visibleFrame else { return }
        widgetController?.window?.setFrameOrigin(WorkdayWidgetWindowController.defaultOrigin(in: sf))
        verticalWidgetController?.window?.setFrameOrigin(
            VerticalWidgetWindowController.defaultOrigin(in: sf, height: CGFloat(settings.data.verticalWidgetHeight)))
    }

    // MARK: - Workday Widget

    @objc func toggleWidget(_ sender: Any?) {
        if widgetController != nil {
            hideWidget()
        } else {
            showWidget()
        }
    }

    func showWidget() {
        if widgetController == nil {
            let s = settings.data
            let size = WorkdayWidgetWindowController.windowSize
            let savedOrigin = validSavedOrigin(
                x: s.widgetX, y: s.widgetY,
                size: CGSize(width: size, height: size),
                screens: NSScreen.screens.map { $0.frame })
            widgetController = WorkdayWidgetWindowController(
                floatOnTop: s.widgetFloatsOnTop,
                savedOrigin: savedOrigin
            )
        }
        widgetController?.showWindow(self)
        settings.data.showWidget = true
        settings.archive()
        refreshWidgetEvents()
    }

    func hideWidget() {
        widgetController?.close()
        widgetController = nil
        settings.data.showWidget = false
        settings.archive()
    }

    func refreshWidgetEvents() {
        guard let wc = widgetController else { return }
        let calNames = settings.data.calendarNames
        let tools = CalendarTools()
        let calendars = calNames.isEmpty
            ? tools.getAllCalendars()
            : tools.getCalendarByNames(names: calNames)
        wc.refreshEvents(
            events: tools.getTodayEvents(calendars: calendars),
            workStart: settings.data.workdayStartHour,
            workEnd: settings.data.workdayEndHour
        )
    }

    // MARK: - Vertical Widget

    @objc func toggleVerticalWidget(_ sender: Any?) {
        if verticalWidgetController != nil {
            hideVerticalWidget()
        } else {
            showVerticalWidget()
        }
    }

    func showVerticalWidget() {
        if verticalWidgetController == nil {
            let s = settings.data
            let savedOrigin = validSavedOrigin(
                x: s.verticalWidgetX, y: s.verticalWidgetY,
                size: CGSize(width: VerticalWidgetWindowController.windowWidth,
                             height: CGFloat(s.verticalWidgetHeight)),
                screens: NSScreen.screens.map { $0.frame })
            verticalWidgetController = VerticalWidgetWindowController(
                floatOnTop: s.verticalWidgetFloatsOnTop,
                savedOrigin: savedOrigin,
                height: CGFloat(s.verticalWidgetHeight)
            )
        }
        verticalWidgetController?.showWindow(self)
        settings.data.showVerticalWidget = true
        settings.archive()
        refreshVerticalWidgetEvents()
    }

    func hideVerticalWidget() {
        verticalWidgetController?.close()
        verticalWidgetController = nil
        settings.data.showVerticalWidget = false
        settings.archive()
    }

    func refreshVerticalWidgetEvents() {
        guard let wc = verticalWidgetController else { return }
        let calNames = settings.data.calendarNames
        let tools = CalendarTools()
        let calendars = calNames.isEmpty
            ? tools.getAllCalendars()
            : tools.getCalendarByNames(names: calNames)
        wc.refreshEvents(
            events: tools.getTodayEvents(calendars: calendars),
            workStart: settings.data.workdayStartHour,
            workEnd: settings.data.workdayEndHour
        )
    }

    @IBAction func openAbout(_ sender: Any?) {
        openAboutBox(forceHelp: false)
    }

    @IBAction func openHelp(_ sender: Any?) {
        openAboutBox(forceHelp: true)
    }

    private func openAboutBox(forceHelp: Bool) {
        if aboutBoxController == nil {
            let mainStoryboard = NSStoryboard.init(name: "AboutPanel", bundle: nil)
            aboutBoxController = mainStoryboard.instantiateController(
                withIdentifier: "AboutPanel") as? NSWindowController
            aboutBoxView = mainStoryboard.instantiateController(
                withIdentifier: "AboutPanelViewController"
                ) as? AboutPanelViewController
            aboutBoxController.contentViewController = aboutBoxView
        }
        aboutBoxController.showWindow(self)
        aboutBoxController.window?.makeKeyAndOrderFront(self)
        aboutBoxView.forceHelp(force: forceHelp)
        NSApp.activate(ignoringOtherApps: true)
    }

    @IBAction func openNextEventPreferencePanel(_ sender: Any?) {
        if preferenceController == nil {
            let mainStoryboard = NSStoryboard.init(name: "NextEventPreferences", bundle: nil)
            preferenceController = mainStoryboard.instantiateController(withIdentifier: "Preference Panel") as? NSWindowController
        }
        preferenceController.showWindow(self)
        preferenceController.window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    func registerNotification() {
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: .event, completion: {
            (_ granted: Bool, _ error: Error?) -> Void in
            if granted {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(self.itemsChanged(_:)),
                    name: .EKEventStoreChanged,
                    object: nil
                )
            }
        })
        eventStore.requestAccess(to: .reminder, completion: {
            (_ granted: Bool, _ error: Error?) -> Void in
            if granted {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(self.itemsChanged(_:)),
                    name: .EKEventStoreChanged,
                    object: nil
                )
            }
        })
    }

    func accessErrorDialog() {
        let alert = NSAlert()
        alert.informativeText = "Please enable access in System Preferences - Security and Privacy, then restart."
        alert.messageText = "Access to calendar or reminder data has been denied!"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func processCommandLine() {
        let arguments = ProcessInfo.processInfo.arguments
        // reset takes takes priority
        for i in 0..<arguments.count {
            if (arguments[i] == "-R") {
                settings.reset()
            }
        }
        // now handle the rest
        for i in 0..<arguments.count {
            if (arguments[i] == "-F:1") {
                settings.data.floatRight = true
            }
            else if (arguments[i] == "-F:0") {
                settings.data.floatRight = false
            }
        }
    }

    func combineImages(base: NSImage, overlay: NSImage, fraction: CGFloat) -> NSImage {

        let aImage: NSImage = NSImage(size: base.size)
        aImage.lockFocus()

        base.draw(in: CGRect(origin: CGPoint.zero, size: base.size))
        overlay.draw(
            in: CGRect(origin: CGPoint.zero, size: overlay.size),
            from: CGRect(origin: CGPoint.zero, size: overlay.size),
            operation: NSCompositingOperation.overlay,
            fraction: fraction
        )

        aImage.unlockFocus()
        return aImage
    }

    func startGlow() {
        if glowTimer == nil {
            isGlowing = true
            // Set up our timer to periodically call the glow: method.
            glowTimer = Timer.scheduledTimer(
                timeInterval: GLOW_INTERVAL,
                target: self,
                selector: #selector(glow(_:)),
                userInfo: nil,
                repeats: true
            )
            RunLoop.current.add(glowTimer, forMode: RunLoop.Mode.common)
            fadeOut = false
            imageTrans = 1.0
        }
    }

    func stopGlow() {
        // kill timer
        if glowTimer != nil {
            isGlowing = false
            glowTimer.invalidate()
            glowTimer = nil
            statusItem.button?.image = icon
        }
    }

    @objc func glow(_ sender: Any?) {
        if fadeOut && imageTrans >= glowSpeed {
            // If window is still partially opaque, reduce its opacity.
            imageTrans = imageTrans - glowSpeed
        }
        else if !fadeOut && (imageTrans < (1.0 - glowSpeed)) {
            // If window is still partially opaque, increase its opacity.
            imageTrans = imageTrans + glowSpeed
        }
        else {
            fadeOut = !fadeOut
        }

        // redraw icon
        statusItem.button?.image = self.combineImages(base: icon, overlay: glowIcon, fraction: imageTrans)
    }

}
