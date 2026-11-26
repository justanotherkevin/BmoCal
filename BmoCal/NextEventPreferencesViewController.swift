import Cocoa
import EventKit


class NextEventPreferencesViewController: NSViewController {

    @IBOutlet weak var alertStyle: NSPopUpButton!
    @IBOutlet weak var earlyWarning: NSPopUpButton!
    @IBOutlet weak var travelTime: NSButton!
    @IBOutlet weak var numberEvents: NSPopUpButton!
    @IBOutlet weak var startHour: NSPopUpButton!
    @IBOutlet weak var endHour: NSPopUpButton!
    @IBOutlet weak var showRoundWidget: NSButton!
    @IBOutlet weak var showVerticalWidget: NSButton!

    @IBOutlet weak var tableView: NSTableView!

    var allCalendars: [EKCalendar] = []
    var calendars: [String] = []

    var settings: Settings!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        let appDelegate = NSApp.delegate as? AppDelegate
        settings = appDelegate?.settings

        self.tableView.delegate = self
        self.tableView.dataSource = self

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let hours = (0..<24).map { h -> String in
            formatter.string(from: Calendar.current.date(bySettingHour: h, minute: 0, second: 0, of: Date())!)
        }
        for popup in [startHour!, endHour!] {
            popup.removeAllItems()
            popup.addItems(withTitles: hours)
        }
    }

    override func viewDidAppear() {
        self.refresh()
    }

    func refresh() {
        allCalendars = CalendarTools().getAllCalendars() + CalendarTools().getAllReminderLists()

        let d = settings.data
        alertStyle.selectItem(withTag: d.useBlockingAlert ? 2 : d.useSystemAlert ? 1 : d.useSound ? 3 : 0)
        earlyWarning.selectItem(withTitle: String(settings.data.earlyWarning))
        travelTime.state = getState(value: settings.data.notifyTravelTime)
        startHour.selectItem(at: min(max(settings.data.workdayStartHour, 0), 23))
        endHour.selectItem(at: min(max(settings.data.workdayEndHour, 0), 23))
        showRoundWidget.state = getState(value: settings.data.showWidget)
        showVerticalWidget.state = getState(value: settings.data.showVerticalWidget)
        if settings.data.showNumber == 0 {
            numberEvents.selectItem(withTitle: "Today only")
        } else if settings.data.showNumber == -1 {
            numberEvents.selectItem(withTitle: "24 Hours")
        } else {
            numberEvents.selectItem(withTitle: String(settings.data.showNumber))
        }
        calendars = settings.data.calendarNames

        self.tableView.reloadData()

        enableButtons()
    }

    func enableButtons() {
        // early warning only applies to the full screen alert
        earlyWarning.isEnabled = settings.data.useBlockingAlert
    }

    func getState(value: Bool) -> NSControl.StateValue {
        if value == true {
            return .on
        }
        return .off
    }

    func getState(value: NSControl.StateValue) -> Bool {
        if value == .on {
            return true
        }
        return false
    }

    @IBAction func updateSettings(_ sender: Any) {
        settings.data.earlyWarning = Int((earlyWarning.selectedItem?.title)!)!
        settings.data.notifyTravelTime = getState(value: travelTime.state)
        if numberEvents.selectedItem?.title == "Today only" {
            settings.data.showNumber = 0
        } else if numberEvents.selectedItem?.title == "24 Hours" {
            settings.data.showNumber = -1
        } else {
             settings.data.showNumber = Int((numberEvents.selectedItem?.title)!)!
        }
        settings.data.calendarNames = calendars

        enableButtons()

        settings.needsDisplay = true
        settings.archive()
    }

    @IBAction func alertStyleChanged(_ sender: Any) {
        let tag = alertStyle.selectedTag()
        settings.data.useSystemAlert = tag == 1
        settings.data.useBlockingAlert = tag == 2
        settings.data.useSound = tag == 3
        enableButtons()
        settings.needsDisplay = true
        settings.archive()
    }

    @IBAction func hourChanged(_ sender: Any) {
        if endHour.indexOfSelectedItem <= startHour.indexOfSelectedItem {
            NSSound.beep()
            startHour.selectItem(at: settings.data.workdayStartHour)
            endHour.selectItem(at: settings.data.workdayEndHour)
            return
        }
        settings.data.workdayStartHour = startHour.indexOfSelectedItem
        settings.data.workdayEndHour = endHour.indexOfSelectedItem
        settings.needsDisplay = true
        settings.archive()
        (NSApp.delegate as? AppDelegate)?.refreshAll(nil)
    }

    @IBAction func toggleRoundWidget(_ sender: Any) {
        let on = (sender as? NSButton)?.state == .on
        let app = NSApp.delegate as? AppDelegate
        if on { app?.showWidget() } else { app?.hideWidget() }
    }

    @IBAction func toggleVerticalWidget(_ sender: Any) {
        let on = (sender as? NSButton)?.state == .on
        let app = NSApp.delegate as? AppDelegate
        if on { app?.showVerticalWidget() } else { app?.hideVerticalWidget() }
    }

    @IBAction func buttonClicked(_ sender: Any) {
        let checkButton: NSButton = (sender as! NSButton)
        let selectedRow = tableView.row(for: sender as! NSView)
        if checkButton.state == .on {
            calendars.append(allCalendars[selectedRow].title)
        } else {
            while let idx = calendars.firstIndex(of: allCalendars[selectedRow].title) {
                calendars.remove(at: idx)
            }
        }
        self.updateSettings(sender)
    }
}

extension NextEventPreferencesViewController: NSTableViewDataSource, NSTableViewDelegate {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return allCalendars.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if (tableColumn?.identifier)!.rawValue == "Check" {
            let result:NSButton = tableView.makeView(
                withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Check")
                , owner: self
            ) as! NSButton
            (result.cell as! NSButtonCell).backgroundColor = allCalendars[row].color
            if calendars.contains(allCalendars[row].title) {
                result.state = .on
            } else {
                result.state = .off
            }
            return result
        } else if (tableColumn?.identifier)!.rawValue == "Name" {
            let result = tableView.makeView(
                withIdentifier:(tableColumn?.identifier)!,
                owner: self
            ) as! NSTableCellView
            result.textField?.stringValue = allCalendars[row].title
            return result
        }
        return nil
    }

}
