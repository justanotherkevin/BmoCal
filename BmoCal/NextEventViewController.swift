import Cocoa
import EventKit

enum MenuBarImage { case appIcon, capsule(fraction: Double), urgentDot, done }
struct MenuBarStatus { let image: MenuBarImage; let text: String }

private func label(_ size: CGFloat, weight: NSFont.Weight = .regular, mono: Bool = false,
                   color: NSColor = .labelColor, align: NSTextAlignment = .left) -> NSTextField {
    let f = NSTextField(labelWithString: "")
    f.font = mono ? Theme.number(size, weight) : Theme.text(size, weight)
    f.textColor = color
    f.alignment = align
    f.lineBreakMode = .byTruncatingTail
    return f
}

private let meetingHosts = ["zoom.us", "meet.google.com", "teams.microsoft.com", "webex.com"]

private let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

func meetingURL(_ item: EKCalendarItem) -> URL? {
    guard let event = item as? EKEvent else { return nil }
    if let url = event.url { return url }
    for text in [event.location, event.notes] {
        guard let text = text else { continue }
        let range = NSRange(text.startIndex..., in: text)
        for m in linkDetector?.matches(in: text, options: [], range: range) ?? [] {
            if let url = m.url, let host = url.host, meetingHosts.contains(where: { host == $0 || host.hasSuffix("." + $0) }) { return url }
        }
    }
    return nil
}

/// Start/end of an all day item (all day event, or reminder due on a date with no time).
func allDayRange(_ item: EKCalendarItem) -> (start: Date, end: Date)? {
    let cal = Calendar.current
    if let e = item as? EKEvent { return e.isAllDay ? (e.startDate, e.endDate) : nil }
    if let r = item as? EKReminder, let dc = r.dueDateComponents, dc.hour == nil,
       let d = cal.date(from: dc), let next = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: d)) {
        return (cal.startOfDay(for: d), next)
    }
    return nil
}

/// Workday as a thin track with event segments and a "now" line.
class DayStripView: NSView {
    var workStart = Date(), workEnd = Date(), now = Date()
    var events: [EKEvent] = []

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            let total = workEnd.timeIntervalSince(workStart)
            guard total > 0 else { return }
            let track = NSBezierPath(roundedRect: bounds, xRadius: bounds.height / 2, yRadius: bounds.height / 2)
            NSColor.separatorColor.setFill()
            track.fill()

            NSGraphicsContext.saveGraphicsState()
            track.addClip()
            func x(_ d: Date) -> CGFloat {
                bounds.width * CGFloat(max(0, min(1, d.timeIntervalSince(workStart) / total)))
            }
            for e in events {
                guard let s = e.startDate, let end = e.endDate, end > workStart, s < workEnd else { continue }
                let color = e.calendar?.color ?? .systemGray
                color.withAlphaComponent(end < now ? Theme.Alpha.past : 0.85).setFill()
                NSRect(x: x(s), y: 0, width: max(1, x(end) - x(s)), height: bounds.height).fill()
            }
            if now >= workStart && now < workEnd {
                Theme.nowColor.setFill()
                NSRect(x: x(now) - 0.75, y: 0, width: 1.5, height: bounds.height).fill()
            }
            NSGraphicsContext.restoreGraphicsState()
        }
    }
}

class KSTableCellView: NSTableCellView {

    private let timeLabel = label(13, mono: true)
    private let bar = NSView()
    private let titleLabel = label(13)
    private let relLabel = label(11, mono: true, color: .secondaryLabelColor, align: .right)
    private let joinButton = NSButton()
    private var joinURL: URL?

    override init(frame: NSRect) {
        super.init(frame: frame)
        bar.wantsLayer = true
        bar.layer?.cornerRadius = 1.5
        joinButton.image = NSImage(systemSymbolName: "video", accessibilityDescription: "Join meeting")
        joinButton.isBordered = false
        joinButton.contentTintColor = .secondaryLabelColor
        joinButton.setAccessibilityLabel("Join meeting")
        joinButton.target = self
        joinButton.action = #selector(join)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        relLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stack = NSStackView(views: [timeLabel, bar, titleLabel, relLabel, joinButton])
        stack.spacing = 8
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.Space.l),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.Space.l),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            timeLabel.widthAnchor.constraint(equalToConstant: 64),
            bar.widthAnchor.constraint(equalToConstant: 3),
            bar.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    @objc private func join() { if let u = joinURL { NSWorkspace.shared.open(u) } }

    func configure(item: EKCalendarItem, start: Date?, now: Date, joinURL url: URL?) {
        let event = item as? EKEvent
        let range = allDayRange(item)
        let allDay = range != nil
        let end = range?.end ?? event?.endDate ?? start
        let isPast = (end ?? start).map { $0 < now } ?? false
        let isCurrent = !allDay && event != nil && (start.map { $0 <= now } ?? false) && (end.map { now < $0 } ?? false)
        let tools = TimeStringTools()

        if allDay {
            timeLabel.stringValue = "All day"
        } else if let start = start {
            timeLabel.stringValue = DateFormatter.localizedString(from: start, dateStyle: .none, timeStyle: .short)
        } else {
            timeLabel.stringValue = ""
        }
        titleLabel.stringValue = item.title ?? ""

        func span(_ prefix: String, _ secs: TimeInterval) -> String {
            let d = tools.durationString(secs)
            return d == "now" ? d : prefix + d
        }
        if allDay || isPast { relLabel.stringValue = "" }
        else if isCurrent, let end = end { relLabel.stringValue = span("ends ", end.timeIntervalSince(now)) }
        else if let start = start { relLabel.stringValue = span("in ", start.timeIntervalSince(now)) }
        else { relLabel.stringValue = "" }

        let textColor: NSColor = isPast ? .secondaryLabelColor : .labelColor
        timeLabel.textColor = textColor
        titleLabel.textColor = textColor
        bar.layer?.backgroundColor = (item.calendar?.color ?? .systemGray)
            .withAlphaComponent(isPast ? Theme.Alpha.past : 1).cgColor

        joinURL = url
        joinButton.isHidden = joinURL == nil
    }
}

class GroupCellView: NSTableCellView {
    let title = label(10, weight: .semibold, color: .secondaryLabelColor)

    override init(frame: NSRect) {
        super.init(frame: frame)
        title.translatesAutoresizingMaskIntoConstraints = false
        addSubview(title)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.Space.l),
            title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.Space.l),
            title.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }
}

class NextEventViewController: NSViewController {

    @IBOutlet var controllerView: NSView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var tableView: NSTableView!
    var calendarItems: [EKCalendarItem] = []
    var settings: Settings!

    enum ListRow { case group(String), item(EKCalendarItem, URL?) }
    private var rows: [ListRow] = []
    private var todayEvents: [EKEvent] = []

    private let headerStack = NSStackView()
    private let dateLabel = label(13, weight: .semibold)
    private let remainingLabel = label(13, mono: true)
    private let percentLabel = label(11, mono: true, color: .secondaryLabelColor, align: .right)
    private let strip = DayStripView()
    private let freeLabel = label(11, color: .secondaryLabelColor)
    private let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEEdMMM")
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = NSApp.delegate as? AppDelegate
        settings = appDelegate?.settings

        buildLayout()
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.refreshAll(self)
    }

    private func buildHeader() {
        let gear = NSButton(image: NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Options")!,
                            target: self, action: #selector(showOptionsMenu(_:)))
        gear.isBordered = false
        gear.contentTintColor = .secondaryLabelColor
        gear.setAccessibilityLabel("Options")
        gear.setContentHuggingPriority(.required, for: .horizontal)

        func row(_ views: [NSView]) -> NSStackView {
            let r = NSStackView(views: views)
            r.spacing = 8
            r.alignment = .centerY
            return r
        }
        dateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        remainingLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        percentLabel.setContentHuggingPriority(.required, for: .horizontal)
        strip.translatesAutoresizingMaskIntoConstraints = false
        strip.heightAnchor.constraint(equalToConstant: 6).isActive = true

        headerStack.setViews([row([dateLabel, gear]), row([remainingLabel, percentLabel]), strip, freeLabel], in: .top)
        headerStack.orientation = .vertical
        headerStack.alignment = .leading
        headerStack.spacing = 4
        headerStack.edgeInsets = NSEdgeInsets(top: Theme.Space.m, left: Theme.Space.l, bottom: Theme.Space.m, right: Theme.Space.l)
        headerStack.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureTable() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.drawsBackground = false
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.intercellSpacing = .zero
        tableView.gridStyleMask = []
        tableView.floatsGroupRows = false
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        tableView.tableColumns.first?.resizingMask = .autoresizingMask
    }

    private func buildLayout() {
        buildHeader()
        configureTable()

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerStack)
        view.addSubview(separator)
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.topAnchor),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // rows fill the stack width minus insets
            strip.widthAnchor.constraint(equalTo: headerStack.widthAnchor, constant: -32),
            headerStack.arrangedSubviews[0].widthAnchor.constraint(equalTo: strip.widthAnchor),
            headerStack.arrangedSubviews[1].widthAnchor.constraint(equalTo: strip.widthAnchor),
            separator.topAnchor.constraint(equalTo: headerStack.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
            scrollView.topAnchor.constraint(equalTo: separator.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func showOptionsMenu(_ sender: NSButton) {
        let menu = NSMenu()
        menu.addItem(withTitle: "Preferences…", action: #selector(openNextEventPreferencePanel(_:)), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Refresh", action: #selector(refreshFromMenu(_:)), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Help", action: #selector(openHelp(_:)), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit BmoCal", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "").target = NSApp
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + Theme.Space.xs), in: sender)
    }

    @objc private func refreshFromMenu(_ sender: Any?) {
        (NSApp.delegate as? AppDelegate)?.refreshAll(sender)
    }

    private func rowHeight(_ r: ListRow) -> CGFloat {
        if case .group = r { return 22 }
        return 28
    }

    func setControllerViewSize() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let list = self.rows.reduce(CGFloat(0)) { $0 + self.rowHeight($1) }
            let height = min(520, max(120, self.headerStack.fittingSize.height + 1 + list))
            var cf = self.controllerView?.frame ?? NSRect(x: 0, y: 0, width: 386, height: height)
            cf.size.height = height
            self.controllerView?.frame = cf
            self.view.window?.setContentSize(cf.size)
            let appDelegate = NSApp.delegate as? AppDelegate
            appDelegate?.popover.contentSize = cf.size
        }
    }

    private func workdayBounds(_ now: Date) -> (Date, Date) {
        let t = TimeStringTools()
        return (t.hourToday(settings.data.workdayStartHour, now: now), t.hourToday(settings.data.workdayEndHour, now: now))
    }

    func updateHeader(now: Date = Date()) {
        guard settings != nil else { return }
        let tools = TimeStringTools()
        let (ws, we) = workdayBounds(now)
        dateLabel.stringValue = dateFormatter.string(from: now)

        let inside = now >= ws && now < we
        if now < ws {
            remainingLabel.stringValue = "Starts at " + DateFormatter.localizedString(from: ws, dateStyle: .none, timeStyle: .short)
        } else if inside {
            remainingLabel.stringValue = tools.workdayRemainingString(endHour: settings.data.workdayEndHour, now: now) + " left"
        } else {
            remainingLabel.stringValue = "Workday done"
        }
        percentLabel.isHidden = !inside
        percentLabel.stringValue = "\(Int(tools.workdayFraction(startHour: settings.data.workdayStartHour, endHour: settings.data.workdayEndHour, now: now) * 100))% of day"

        strip.workStart = ws; strip.workEnd = we; strip.now = now; strip.events = todayEvents
        strip.needsDisplay = true

        freeLabel.isHidden = !inside
        guard inside else { return }
        let meetings = todayEvents.filter { !$0.isAllDay && $0.endDate > now && $0.startDate < we }
        var free = we.timeIntervalSince(now)
        var cursor = now
        for e in meetings.sorted(by: { $0.startDate < $1.startDate }) {
            let s = max(e.startDate, cursor), end = min(e.endDate, we)
            if end > s { free -= end.timeIntervalSince(s); cursor = end }
        }
        let n = meetings.count
        let freeText = free < 60 ? "0m" : tools.durationString(free)
        freeLabel.stringValue = "\(n) meeting\(n == 1 ? "" : "s"), \(freeText) free"
    }

    private func buildRows(now: Date = Date()) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        func dayBucket(_ start: Date) -> (Int, String) {
            let days = cal.dateComponents([.day], from: today, to: cal.startOfDay(for: start)).day ?? 0
            if days == 1 { return (3, "TOMORROW") }
            return (2 + days, weekdayFormatter.string(from: start).uppercased())
        }
        func bucket(_ item: EKCalendarItem) -> (Int, String) {
            if let r = allDayRange(item) {
                if r.end <= now { return (0, "EARLIER") }
                if r.start < cal.date(byAdding: .day, value: 1, to: today)! { return (-1, "ALL DAY") }
                return dayBucket(r.start)
            }
            guard let start = getDateFromEventItem(item) else { return (2, "LATER") }
            let end = (item as? EKEvent)?.endDate ?? start
            if start <= now && now < end { return (1, "NOW") }
            let days = cal.dateComponents([.day], from: today, to: cal.startOfDay(for: start)).day ?? 0
            if days < 0 || (days == 0 && start < now) { return (0, "EARLIER") }
            if days == 0 { return (2, "LATER") }
            return dayBucket(start)
        }
        let sorted = calendarItems.enumerated()
            .map { (i: $0.offset, b: bucket($0.element), item: $0.element) }
            .sorted { ($0.b.0, $0.i) < ($1.b.0, $1.i) }
        rows = []
        var last: Int?
        for e in sorted {
            if e.b.0 != last { rows.append(.group(e.b.1)); last = e.b.0 }
            rows.append(.item(e.item, meetingURL(e.item)))
        }
    }

    func getDateFromEventItem(_ item: EKCalendarItem) -> Date? {
        if let event = item as? EKEvent {
            return event.startDate
        } else if let reminder = item as? EKReminder,
                  let dc = reminder.dueDateComponents {
            return Calendar.current.date(from: dc)
        }
        return nil
    }

    func getLocationFromEventItem(_ item: EKCalendarItem) -> String {
        if let event = item as? EKEvent {
            return event.location ?? "   "
        } else if let reminder = item as? EKReminder {
            if reminder.hasAlarms, let alarms = reminder.alarms {
                for alarm in alarms {
                    if let loc = alarm.structuredLocation?.title {
                        return loc
                    }
                }
            }
            return reminder.location ?? "   "
        }
        return "   "
    }

    func getTravelTimeFromEventItem(_ item: EKCalendarItem) -> TimeInterval {
        if let event = item as? EKEvent {
            return event.value(forKey: "travelTime") as? TimeInterval ?? 0
        }
        return 0
    }

    func getNextEvent() -> Int {
        for i in 0 ..< calendarItems.count {
            let itemDate: Date? = getDateFromEventItem(calendarItems[i])

            if (itemDate != nil) && itemDate! > Date() {
                return i
            }
        }
        return -1
    }

    private func eventLabel(_ item: EKCalendarItem, secs: TimeInterval) -> String {
        var title = item.title ?? "Event"
        if title.count > 16 { title = String(title.prefix(16)) + "…" }
        return "\(title) \(TimeStringTools().durationString(secs))"
    }

    func getMenuBarStatus(now: Date = Date()) -> MenuBarStatus {
        let tools = TimeStringTools()
        let startHour = settings.data.workdayStartHour
        let endHour = settings.data.workdayEndHour
        let cal = Calendar.current
        let hour = cal.component(.hour, from: now)

        var label: String?
        var eventSecs = TimeInterval.infinity
        let n = getNextEvent()
        if n >= 0, let date = getDateFromEventItem(calendarItems[n]) {
            eventSecs = date.timeIntervalSince(now)
            if eventSecs > 0 && eventSecs <= 3600 { label = eventLabel(calendarItems[n], secs: eventSecs) }
        }

        if let label = label, eventSecs <= 300 {
            return MenuBarStatus(image: .urgentDot, text: label)
        }

        if hour < startHour {
            let start = cal.date(bySettingHour: startHour, minute: 0, second: 0, of: now) ?? now
            let secs = start.timeIntervalSince(now)
            return MenuBarStatus(image: .appIcon, text: secs < 60 ? "starting" : "in " + tools.durationString(secs))
        }

        if hour >= endHour {
            if let label = label { return MenuBarStatus(image: .appIcon, text: label) }
            return MenuBarStatus(image: .done, text: "")
        }

        var text = tools.workdayRemainingString(endHour: endHour, now: now)
        if let label = label { text += "   " + label }
        return MenuBarStatus(
            image: .capsule(fraction: tools.workdayFraction(startHour: startHour, endHour: endHour, now: now)),
            text: text
        )
    }

    @IBAction func openHelp(_ sender: Any?) {
        let appDelegate = NSApp.delegate as? AppDelegate
        appDelegate?.openHelp(Any?.self)
    }

    @IBAction func openNextEventPreferencePanel(_ sender: Any?) {
        let appDelegate = NSApp.delegate as? AppDelegate
        appDelegate?.openNextEventPreferencePanel(Any?.self)
    }

    func update() -> Bool {
        var has_changed: Bool = false

        if self.view.window?.occlusionState.contains(.visible) ?? false  {
            if settings.needsDisplay == true {

                self.refreshAll(self)

                settings.needsDisplay = false
                has_changed = true
            } else {
                buildRows()
                tableView.reloadData()
            }
            updateHeader()
        }
        if settings.needsDisplay == true {

            self.refreshAll(self)

            settings.needsDisplay = false
            has_changed = true
        }

        self.notify()
        return has_changed
    }

    func alert(title: String, date: Date, location: String, color: NSColor, playSound: Bool = false) {
        DispatchQueue.main.async {

            var alertBoxWindow: MZAlertBoxWindowController!
            var alertBoxView: MZAlertBoxViewController!

            let mainStoryboard = NSStoryboard.init(name: "MZAlertBox", bundle: nil)

            alertBoxWindow = mainStoryboard.instantiateController(
                withIdentifier: "MZ Alert Box Window Controller"
            ) as? MZAlertBoxWindowController

            alertBoxView = mainStoryboard.instantiateController(
                withIdentifier: "MZ Alert Box Controller"
            ) as? MZAlertBoxViewController

            alertBoxWindow!.contentViewController = alertBoxView

            alertBoxView!.eventTitleString = title
            alertBoxView!.eventDate = date
            alertBoxView!.playSound = playSound
            alertBoxView!.eventDateTextField.stringValue = "\(date.description(with: .current))"
            let fixLocation = location.replacingOccurrences(
                of: "\n",
                with: ", ",
                options: .regularExpression
            )
            alertBoxView!.eventLocationButton.title = fixLocation
            if (URL(string: fixLocation) == nil) {
                alertBoxView!.eventLocationButton.isEnabled = false
                if let cell = alertBoxView!.eventLocationButton.cell as? NSButtonCell {
                    cell.imageDimsWhenDisabled = false
                }
            }
            alertBoxView!.calendarColorTextField.backgroundColor = color

            alertBoxWindow!.window?.collectionBehavior = .moveToActiveSpace
            alertBoxWindow!.window?.makeKeyAndOrderFront(self)
            alertBoxWindow!.window?.collectionBehavior = .canJoinAllSpaces
            alertBoxWindow!.showWindow(self)

            NSApp.activate(ignoringOtherApps: true)
        }

    }

    func notify() {
        var notification: NSUserNotification?

        if settings.data.useSystemAlert || settings.data.useBlockingAlert || settings.data.useSound {

            for item in calendarItems {

                let now: Date = Date()
                let itemDate:Date? = getDateFromEventItem(item)
                let itemLocation: String = getLocationFromEventItem(item)
                var color: NSColor = .labelColor
                if item.calendar != nil && item.calendar!.color != nil{
                    color = item.calendar!.color
                }

                guard let itemDate = itemDate, !item.title.isEmpty, itemDate >= now else {
                    continue
                }

                // notify travel
                if settings.data.notifyTravelTime {
                    let travelTime = getTravelTimeFromEventItem(item)

                    if travelTime > 0 {
                        let tt = ceil((itemDate.addingTimeInterval(0-travelTime)).timeIntervalSinceReferenceDate)
                        if ceil(now.timeIntervalSinceReferenceDate) == tt {
                            if settings.data.useSystemAlert {
                                notification = NSUserNotification()
                                notification?.title = "Time to leave for \(item.title ?? "Next Event")"
                                notification?.informativeText = "\(itemDate.description(with: .current))"
                                notification?.deliveryDate = now
                                // play sound
                                if settings.data.useSound {
                                    notification?.soundName = NSUserNotificationDefaultSoundName
                                } else {
                                    notification?.soundName = nil
                                }
                                let center = NSUserNotificationCenter.default
                                center.scheduleNotification(notification!)
                            } else if settings.data.useSound {
                                NSSound.beep()
                            }

                            if settings.data.useBlockingAlert {
                                self.alert(title: "Time to leave for \(item.title ?? "Next Event")", date: itemDate, location: itemLocation, color: color)
                            }
                        }
                    }
                }

                // notify event
                //print("\(ceil(now.timeIntervalSinceReferenceDate)) == \(ceil(itemDate.timeIntervalSinceReferenceDate)), \(item.title ?? "No title")")
                if ceil(now.timeIntervalSinceReferenceDate) == ceil(itemDate.timeIntervalSinceReferenceDate) {

                    if settings.data.useSystemAlert {
                        notification = NSUserNotification()
                        notification?.title = item.title
                        notification?.informativeText = "\(itemDate.description(with: .current))"
                        notification?.deliveryDate = now
                        // play sound
                        if settings.data.useSound {
                            notification?.soundName = NSUserNotificationDefaultSoundName
                        } else {
                            notification?.soundName = nil
                        }
                        let center = NSUserNotificationCenter.default
                        center.scheduleNotification(notification!)
                    } else if settings.data.useSound {
                        NSSound.beep()
                    }

                    if settings.data.useBlockingAlert && settings.data.earlyWarning == 0 {
                        self.alert(title: item.title, date: itemDate, location: itemLocation, color: color)
                    }

                    self.refreshAll(self)
                }

                // notify early warning
                if settings.data.earlyWarning > 0 && settings.data.useBlockingAlert {
                    let tt = ceil((itemDate.addingTimeInterval(0-TimeInterval(settings.data.earlyWarning*60) )).timeIntervalSinceReferenceDate)
                    if ceil(now.timeIntervalSinceReferenceDate) == tt {
                        self.alert(title: item.title, date: itemDate, location: itemLocation, color: color, playSound: settings.data.useSound)
                    }
                }
            }
        }
    }

    @IBAction func refreshAll(_ sender: Any?) {
        if settings == nil {
            let appDelegate = NSApp.delegate as? AppDelegate
            settings = appDelegate?.settings
        }

        let calendars = CalendarTools().getCalendarByNames(names: settings.data.calendarNames)
        let reminderLists = CalendarTools().getReminderListByNames(names: settings.data.calendarNames)
        if settings.data.showNumber > 0 {
            calendarItems = CalendarTools().getTopN(
                n: settings.data.showNumber,
                calendars: calendars,
                reminders: reminderLists
            )
        } else if settings.data.showNumber == 0 {
            calendarItems = CalendarTools().getTodayAll(
                calendars: calendars,
                reminders: reminderLists
            )
        } else {
            calendarItems = CalendarTools().get24Hours(
                calendars: calendars,
                reminders: reminderLists
            )
        }

        todayEvents = CalendarTools().getTodayEvents(calendars: calendars)
        buildRows()
        updateHeader()
        self.setControllerViewSize()
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
}

extension NextEventViewController {
    static func freshController() -> NextEventViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = "NextEventViewController"

        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? NextEventViewController else {
            fatalError("Why can't i find NextEventViewController? - Check Main.storyboard")
        }
        return viewcontroller
    }
}

extension NextEventViewController: NSTableViewDataSource, NSTableViewDelegate {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return rows.count
    }

    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        guard row < rows.count, case .group = rows[row] else { return false }
        return true
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        row < rows.count ? rowHeight(rows[row]) : 28
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < rows.count else { return nil }
        switch rows[row] {
        case .group(let name):
            let id = NSUserInterfaceItemIdentifier("groupCell")
            let cell = tableView.makeView(withIdentifier: id, owner: self) as? GroupCellView ?? GroupCellView()
            cell.identifier = id
            cell.title.stringValue = name
            return cell
        case .item(let item, let url):
            let id = NSUserInterfaceItemIdentifier("eventCell")
            let cell = tableView.makeView(withIdentifier: id, owner: self) as? KSTableCellView ?? KSTableCellView()
            cell.identifier = id
            cell.configure(item: item, start: getDateFromEventItem(item), now: Date(), joinURL: url)
            return cell
        }
    }
}
