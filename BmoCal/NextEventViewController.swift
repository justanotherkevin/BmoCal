import Cocoa
import EventKit

class KSTableCellView: NSTableCellView {

    @IBOutlet weak var eventTitle: NSTextField!
    @IBOutlet weak var eventDate: NSTextField!
    @IBOutlet weak var eventLocation: NSTextField!
    @IBOutlet weak var eventTime: NSTextField!
    @IBOutlet weak var calendarColor: NSTextField!
    @IBOutlet weak var leadTime: NSTextField!
    @IBOutlet weak var leadTimeUnit: NSTextField!
}

class NextEventViewController: NSViewController {

    @IBOutlet var controllerView: NSView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var tableView: NSTableView!
    var calendarItems: [EKCalendarItem] = []
    var settings: Settings!
    var shouldGlow: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        let appDelegate = NSApp.delegate as? AppDelegate
        settings = appDelegate?.settings

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.refreshAll(self)
    }

    //override func viewWillAppear() {
    //    super.viewWillAppear()
    //    self.refreshAll(self)
    //}

    func setControllerViewSize(_ count: Int) {
        var final_count = count

        if final_count < 1 {
            final_count = 10
        }

        DispatchQueue.main.async { [weak self] in
            let defaultHeight = CGFloat(82 * final_count + 38)
            var cf = self?.controllerView?.frame
                ?? NSRect(x: 0, y: 0, width: 386, height: defaultHeight)
            cf.size.height = defaultHeight
            self?.controllerView?.frame = cf
            self?.view.window?.setContentSize(cf.size)
            let appDelegate = NSApp.delegate as? AppDelegate
            appDelegate?.popover.contentSize = cf.size
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

    func isAllDay(_ item: EKCalendarItem) -> Bool {
        return (item as? EKEvent)?.isAllDay ?? false
    }


    func getTimeString(_ itemDate: Date?) -> String {
        var fullTime: String = ""
        if itemDate != nil {
            let now = Date()
            // Get conversion to months, days, hours, minutes
            let unitFlags = Set<Calendar.Component>([.day, .hour, .minute, .second])
            let breakdownInfo: DateComponents? = Calendar.current.dateComponents(unitFlags, from: now,  to: itemDate!)
            fullTime = TimeStringTools().getTimeString(
                breakdownInfo!,
                showSeconds: settings.data.showSeconds,
                leadingZeros: settings.data.leadingZeros
            )
        }
        return fullTime
    }

    func getLeadTimeStrings(_ itemDate: Date?) -> (leadTime: String, leadTimeUnit: String) {
        var leadTime: String = ""
        var leadTimeUnit: String = ""
        if itemDate != nil {
            let now = Date()
            // Get conversion to months, days, hours, minutes
            let unitFlags = Set<Calendar.Component>([.day, .hour, .minute, .second])
            let breakdownInfo: DateComponents? = Calendar.current.dateComponents(unitFlags, from: now,  to: itemDate!)
            (leadTime, leadTimeUnit) = TimeStringTools().getLeadTime(
                breakdownInfo!
            )
        }
        return (leadTime, leadTimeUnit)
    }

    func getTimeString(_ item: EKCalendarItem) -> String {
        var fullTime: String = ""
        let itemDate: Date? = getDateFromEventItem(item)
        if itemDate != nil {
            let now = Date()
            // Get conversion to months, days, hours, minutes
            let unitFlags = Set<Calendar.Component>([.day, .hour, .minute, .second])
            let breakdownInfo: DateComponents? = Calendar.current.dateComponents(unitFlags, from: now,  to: itemDate!)
            fullTime = TimeStringTools().getTimeString(
                breakdownInfo!,
                showSeconds: settings.data.showSeconds,
                leadingZeros: settings.data.leadingZeros
            )
        }
        return fullTime
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

    func getNextEventStatus() -> String {
        let startHour = settings.data.workdayStartHour
        let endHour = settings.data.workdayEndHour
        let now = Date()
        let cal = Calendar.current
        let currentHour = cal.component(.hour, from: now)
        let tools = TimeStringTools()

        // Before workday
        if currentHour < startHour {
            var comps = cal.dateComponents([.year, .month, .day], from: now)
            comps.hour = startHour; comps.minute = 0; comps.second = 0
            let startTime = cal.date(from: comps)!
            let secs = max(0, startTime.timeIntervalSince(now))
            let h = Int(secs) / 3600
            let m = (Int(secs) % 3600) / 60
            return h > 0 ? "Work in \(h)h\(m)m" : "Work in \(m)m"
        }

        // After workday
        if currentHour >= endHour {
            let n = getNextEvent()
            if n >= 0 {
                let item = calendarItems[n]
                if let itemDate = getDateFromEventItem(item) {
                    let secs = itemDate.timeIntervalSince(now)
                    if secs > 0 {
                        let h = Int(secs) / 3600
                        let m = (Int(secs) % 3600) / 60
                        var title = item.title ?? "Event"
                        if title.count > 12 { title = String(title.prefix(12)) + "…" }
                        let countdown = h > 0 ? "\(h)h\(m)m" : (m > 0 ? "\(m)m" : "now")
                        return "Done · \(title) \(countdown)"
                    }
                }
            }
            return "Workday done"
        }

        // During workday: [█████░░░░░] 4h32m · Next Event 12m
        let bar = tools.workdayProgressBar(startHour: startHour, endHour: endHour)
        let remaining = tools.workdayRemainingString(endHour: endHour)
        var status = "\(bar) \(remaining)"

        let n = getNextEvent()
        if n >= 0 {
            let item = calendarItems[n]
            if let itemDate = getDateFromEventItem(item) {
                let secs = itemDate.timeIntervalSince(now)
                if secs > 0 {
                    if settings.data.useFlash && !shouldGlow && secs <= 900 {
                        shouldGlow = true
                    }
                    let h = Int(secs) / 3600
                    let m = (Int(secs) % 3600) / 60
                    var title = item.title ?? "Event"
                    if title.count > 12 { title = String(title.prefix(12)) + "…" }
                    let countdown = h > 0 ? "\(h)h\(m)m" : (m > 0 ? "\(m)m" : "now")
                    status += " · \(title) \(countdown)"
                }
            }
        } else {
            shouldGlow = false
        }

        return status
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
                tableView.reloadData()
            }
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

        if settings.data.useSystemAlert || settings.data.useBlockingAlert {

            for item in calendarItems {

                let now: Date = Date()
                let itemDate:Date? = getDateFromEventItem(item)
                let itemLocation: String = getLocationFromEventItem(item)
                var color: NSColor = NSColor.white
                if item.calendar != nil && item.calendar!.color != nil{
                    color = item.calendar!.color
                }

                guard let itemDate = itemDate, !item.title.isEmpty, itemDate >= now else {
                    shouldGlow = false
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

                            shouldGlow = true
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

                    shouldGlow = false
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
        shouldGlow = false
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

        self.setControllerViewSize(calendarItems.count)
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }

    @IBAction func launchCalendar(_ sender: Any) {
        NSWorkspace.shared.launchApplication("iCal")
    }

    @IBAction func launchReminders(_ sender: Any) {
        NSWorkspace.shared.launchApplication("Reminders")
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
        return calendarItems.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let result:KSTableCellView = tableView.makeView(
            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "defaultColumn"),
            owner: self
        ) as! KSTableCellView

        let copyCalendarItems = calendarItems
        if copyCalendarItems.count - 1 < row {
            return result
        }

        let now = Date()
        let itemDate: Date? = getDateFromEventItem(copyCalendarItems[row])
        let travelTime = getTravelTimeFromEventItem(copyCalendarItems[row])
        let itemLocation: String = getLocationFromEventItem(copyCalendarItems[row])
        let allDay = isAllDay(copyCalendarItems[row])

        if itemDate == nil || itemDate! < now {
            result.eventTitle.textColor = NSColor.lightGray
            result.eventLocation.textColor = NSColor.lightGray
            result.eventDate.textColor = NSColor.lightGray
            result.eventTime.textColor = NSColor.lightGray
            result.leadTime.textColor = NSColor.lightGray
            result.leadTimeUnit.textColor = NSColor.lightGray
        } else {
            result.eventTitle.textColor = result.calendarColor.textColor
            result.eventLocation.textColor = result.calendarColor.textColor
            result.eventDate.textColor = result.calendarColor.textColor
            result.eventTime.textColor = result.calendarColor.textColor
            result.leadTime.textColor = result.calendarColor.textColor
            result.leadTimeUnit.textColor = result.calendarColor.textColor
        }
        result.eventTitle.stringValue = copyCalendarItems[row].title!
        result.eventLocation.stringValue = itemLocation
        if (itemDate == nil) {
            result.eventTime.stringValue = "   "
            result.eventDate.stringValue = "   "
            result.leadTime.stringValue = "   "
            result.leadTimeUnit.stringValue = "   "
        } else {
            result.eventTime.stringValue = getTimeString(itemDate)
            if allDay {
                result.eventDate.stringValue = DateFormatter.localizedString(
                    from: itemDate!,
                    dateStyle: .short,
                    timeStyle: .none
                ) + ", All Day"
            } else {
                result.eventDate.stringValue = DateFormatter.localizedString(
                    from: itemDate!,
                    dateStyle: .short,
                    timeStyle: .short
                )
            }
            if travelTime != 0 {
                result.eventDate.stringValue =
                    result.eventDate.stringValue +
                    ", TT +" +
                    TimeStringTools().getTimeStringFromSeconds(
                        travelTime,
                        showSeconds: false,
                        leadingZeros: false
                    )
            }
            (result.leadTime.stringValue, result.leadTimeUnit.stringValue) = getLeadTimeStrings(itemDate)
        }

        //print(copyCalendarItems[row])

        if copyCalendarItems[row].calendar != nil {
            result.calendarColor.backgroundColor = copyCalendarItems[row].calendar.color
        } else {
            result.calendarColor.backgroundColor = NSColor.white
        }

        return result;
    }
}
