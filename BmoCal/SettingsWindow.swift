import Cocoa
import EventKit
import SwiftUI

// MARK: - Pure logic

enum AlertDesign: Int, CaseIterable {
    case ring, card, edge

    var title: String {
        switch self {
        case .ring: return "Ring"
        case .card: return "Card"
        case .edge: return "Edge"
        }
    }
}

enum AlertStyle: Int, CaseIterable {
    case none, banner, fullScreen, chime

    static let earlyWarningChoices = [0, 1, 3, 5]

    /// Legacy bools can overlap in old config files: Full screen wins, then Banner, then Chime.
    init(_ d: BmoCal.Settings.Data) {
        self = d.useBlockingAlert ? .fullScreen : d.useSystemAlert ? .banner : d.useSound ? .chime : .none
    }

    func apply(to d: inout BmoCal.Settings.Data) {
        d.useSystemAlert = self == .banner
        d.useBlockingAlert = self == .fullScreen
        d.useSound = self == .chime
    }

    var title: String {
        switch self {
        case .none: return "None"
        case .banner: return "Banner"
        case .fullScreen: return "Full screen"
        case .chime: return "Chime"
        }
    }

    static func isValidWorkday(start: Int, end: Int) -> Bool { end > start }
}

// MARK: - State

final class SettingsStore: ObservableObject {
    private let settings: BmoCal.Settings?
    private var app: AppDelegate? { NSApp.delegate as? AppDelegate }
    @Published var data: BmoCal.Settings.Data

    init() {
        settings = (NSApp.delegate as? AppDelegate)?.settings
        data = settings?.data ?? BmoCal.Settings.Data()
    }

    func reload() {
        if let d = settings?.data { data = d }
    }

    func update(_ change: (inout BmoCal.Settings.Data) -> Void) {
        var d = data
        change(&d)
        data = d
        settings?.data = d
        settings?.needsDisplay = true
        settings?.archive()
    }

    func setWorkday(start: Int, end: Int) {
        guard AlertStyle.isValidWorkday(start: start, end: end) else {
            NSSound.beep()
            objectWillChange.send() // snaps the pickers back to the stored values
            return
        }
        update { $0.workdayStartHour = start; $0.workdayEndHour = end }
        app?.refreshAll(nil)
    }

    func setRoundWidget(_ on: Bool) {
        if on { app?.showWidget() } else { app?.hideWidget() }
        reload()
    }

    func setVerticalWidget(_ on: Bool) {
        if on { app?.showVerticalWidget() } else { app?.hideVerticalWidget() }
        reload()
    }

    func setRoundFloat(_ on: Bool) {
        update { $0.widgetFloatsOnTop = on }
        app?.widgetController?.setFloating(on)
    }

    func setVerticalFloat(_ on: Bool) {
        update { $0.verticalWidgetFloatsOnTop = on }
        app?.verticalWidgetController?.setFloating(on)
    }

    /// The window is sized at creation, so a new height needs a re-show.
    func setVerticalHeight(_ h: Double) {
        update { $0.verticalWidgetHeight = h }
        guard app?.verticalWidgetController != nil else { return }
        app?.hideVerticalWidget()
        app?.showVerticalWidget()
        reload()
    }

    func resetPositions() { app?.resetWidgetPositions(nil) }

    func calendarBinding(_ title: String) -> Binding<Bool> {
        Binding(
            get: { self.data.calendarNames.contains(title) },
            set: { on in
                self.update { d in
                    if on { d.calendarNames.append(title) } else { d.calendarNames.removeAll { $0 == title } }
                }
            })
    }
}

// MARK: - Views

private let hourLabels: [String] = {
    let f = DateFormatter()
    f.timeStyle = .short
    f.dateStyle = .none
    return (0..<24).map { h in
        f.string(from: Calendar.current.date(bySettingHour: h, minute: 0, second: 0, of: Date()) ?? Date())
    }
}()

private extension View {
    func reloadOnShow(_ store: SettingsStore) -> some View {
        onAppear { store.reload() }
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
                store.reload()
            }
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        Form {
            Section {
                Picker("Starts", selection: Binding(
                    get: { store.data.workdayStartHour },
                    set: { store.setWorkday(start: $0, end: store.data.workdayEndHour) })) {
                    ForEach(0..<24, id: \.self) { Text(hourLabels[$0]).tag($0) }
                }
                Picker("Ends", selection: Binding(
                    get: { store.data.workdayEndHour },
                    set: { store.setWorkday(start: store.data.workdayStartHour, end: $0) })) {
                    ForEach(0..<24, id: \.self) { Text(hourLabels[$0]).tag($0) }
                }
            } header: {
                Text("Workday")
            } footer: {
                Text("Used by the menu bar progress bar and the widgets.").foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .reloadOnShow(store)
    }
}

struct CalendarsSettingsView: View {
    @ObservedObject var store: SettingsStore
    @State private var calendars: [EKCalendar] = []
    @State private var reminders: [EKCalendar] = []
    private let showOptions: [(Int, String)] = [(1, "1"), (3, "3"), (5, "5"), (10, "10"),
                                                (0, "Today only"), (-1, "24 Hours")]

    var body: some View {
        Form {
            Section("Calendars") { ForEach(calendars, id: \.calendarIdentifier) { row($0) } }
            Section("Reminders") { ForEach(reminders, id: \.calendarIdentifier) { row($0) } }
            Section("Menu") {
                Picker("Show", selection: Binding(
                    get: { store.data.showNumber }, set: { v in store.update { $0.showNumber = v } })) {
                    ForEach(showOptions, id: \.0) { Text($0.1).tag($0.0) }
                }
            }
        }
        .formStyle(.grouped)
        .reloadOnShow(store)
        .onAppear {
            let tools = CalendarTools()
            calendars = tools.getAllCalendars()
            reminders = tools.getAllReminderLists()
        }
    }

    private func row(_ cal: EKCalendar) -> some View {
        Toggle(isOn: store.calendarBinding(cal.title)) {
            HStack {
                Circle().fill(Color(nsColor: cal.color)).frame(width: 10, height: 10).accessibilityHidden(true)
                Text(cal.title)
            }
        }
    }
}

struct NotificationsSettingsView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        Form {
            Section("Alerts") {
                Picker("Alert style", selection: Binding(
                    get: { AlertStyle(store.data) }, set: { s in store.update { s.apply(to: &$0) } })) {
                    ForEach(AlertStyle.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                if AlertStyle(store.data) == .fullScreen {
                    Picker("Early warning", selection: Binding(
                        get: { store.data.earlyWarning }, set: { v in store.update { $0.earlyWarning = v } })) {
                        ForEach(AlertStyle.earlyWarningChoices, id: \.self) { Text(String($0)).tag($0) }
                    }
                    Picker("Alert design", selection: Binding(
                        get: { AlertDesign(rawValue: store.data.alertDesign) ?? .ring },
                        set: { v in store.update { $0.alertDesign = v.rawValue } })) {
                        ForEach(AlertDesign.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    Button("Preview") {
                        EventAlertWindowController.show(
                            design: AlertDesign(rawValue: store.data.alertDesign) ?? .ring,
                            title: "Preview meeting", start: Date().addingTimeInterval(180),
                            location: "https://meet.google.com/abc-defg-hij", color: .systemOrange, playSound: false)
                    }
                }
                Toggle("Warn when it's time to leave", isOn: Binding(
                    get: { store.data.notifyTravelTime }, set: { v in store.update { $0.notifyTravelTime = v } }))
            }
        }
        .formStyle(.grouped)
        .reloadOnShow(store)
    }
}

struct WidgetsSettingsView: View {
    @ObservedObject var store: SettingsStore
    @State private var height: Double = 400

    var body: some View {
        Form {
            Section("Round widget") {
                Toggle("Show", isOn: Binding(get: { store.data.showWidget }, set: store.setRoundWidget))
                Toggle("Float above other windows",
                       isOn: Binding(get: { store.data.widgetFloatsOnTop }, set: store.setRoundFloat))
            }
            Section("Vertical widget") {
                Toggle("Show", isOn: Binding(get: { store.data.showVerticalWidget }, set: store.setVerticalWidget))
                Toggle("Float above other windows",
                       isOn: Binding(get: { store.data.verticalWidgetFloatsOnTop }, set: store.setVerticalFloat))
                HStack {
                    Slider(value: $height, in: 200...800, step: 50) { Text("Height") }
                        onEditingChanged: { editing in if !editing { store.setVerticalHeight(height) } }
                    Text("\(Int(height)) pt").monospacedDigit()
                }
                HStack {
                    Spacer()
                    Button("Reset Positions") { store.resetPositions() }
                }
            }
        }
        .formStyle(.grouped)
        .reloadOnShow(store)
        .onAppear { height = store.data.verticalWidgetHeight }
    }
}

// MARK: - Window

final class SettingsWindowController: NSWindowController {
    convenience init() {
        let store = SettingsStore()
        let tabs = NSTabViewController()
        tabs.tabStyle = .toolbar
        let items: [(String, String, AnyView)] = [
            ("General", "gearshape", AnyView(GeneralSettingsView(store: store))),
            ("Calendars", "calendar", AnyView(CalendarsSettingsView(store: store).frame(maxHeight: 560))),
            ("Notifications", "bell", AnyView(NotificationsSettingsView(store: store))),
            ("Widgets", "rectangle.on.rectangle", AnyView(WidgetsSettingsView(store: store))),
        ]
        for (title, symbol, view) in items {
            let host = NSHostingController(rootView: view.frame(width: 460).fixedSize(horizontal: false, vertical: true))
            host.sizingOptions = [.preferredContentSize]
            host.title = title
            let item = NSTabViewItem(viewController: host)
            item.label = title
            item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
            tabs.addTabViewItem(item)
        }
        let window = NSWindow(contentViewController: tabs)
        window.title = "BmoCal Settings"
        window.setContentSize(NSSize(width: 460, height: 200))
        window.styleMask = [.titled, .closable, .miniaturizable]
        self.init(window: window)
    }
}
