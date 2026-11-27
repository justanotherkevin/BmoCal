import Foundation

protocol SettingsProviding {
    var data: Settings.Data { get set }
    var needsDisplay: Bool { get set }
    func archive()
    func reset()
}

class Settings: NSObject, SettingsProviding {

    struct Data: Codable {
        // persistant
        var floatRight: Bool = false
        var useSystemAlert: Bool = false
        var useBlockingAlert: Bool = false
        var earlyWarning: Int = 1
        var notifyTravelTime: Bool = false
        var useSound: Bool = false
        var useFuzzyTime: Bool = false
        var showSeconds: Bool = false
        var leadingZeros: Bool = false
        var showNumber: Int = 10
        var showTime: Bool = true
        var showTitle: Bool = false
        var useTitleLimit: Bool = false
        var calendarNames: [String] = []
        var workdayStartHour: Int = 9
        var workdayEndHour: Int = 18
        var showWidget: Bool = false
        var widgetFloatsOnTop: Bool = true
        var widgetX: Double = -1
        var widgetY: Double = -1
        var showVerticalWidget: Bool = false
        var verticalWidgetFloatsOnTop: Bool = true
        var verticalWidgetX: Double = -1
        var verticalWidgetY: Double = -1
        var verticalWidgetHeight: Double = 400

        // Missing keys fall back to the defaults above, so adding a field never wipes saved settings.
        // New fields MUST be added here too.
        init() {}

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            let d = Data()
            floatRight = try c.decodeIfPresent(type(of: d.floatRight), forKey: .floatRight) ?? d.floatRight
            useSystemAlert = try c.decodeIfPresent(type(of: d.useSystemAlert), forKey: .useSystemAlert) ?? d.useSystemAlert
            useBlockingAlert = try c.decodeIfPresent(type(of: d.useBlockingAlert), forKey: .useBlockingAlert) ?? d.useBlockingAlert
            earlyWarning = try c.decodeIfPresent(type(of: d.earlyWarning), forKey: .earlyWarning) ?? d.earlyWarning
            notifyTravelTime = try c.decodeIfPresent(type(of: d.notifyTravelTime), forKey: .notifyTravelTime) ?? d.notifyTravelTime
            useSound = try c.decodeIfPresent(type(of: d.useSound), forKey: .useSound) ?? d.useSound
            useFuzzyTime = try c.decodeIfPresent(type(of: d.useFuzzyTime), forKey: .useFuzzyTime) ?? d.useFuzzyTime
            showSeconds = try c.decodeIfPresent(type(of: d.showSeconds), forKey: .showSeconds) ?? d.showSeconds
            leadingZeros = try c.decodeIfPresent(type(of: d.leadingZeros), forKey: .leadingZeros) ?? d.leadingZeros
            showNumber = try c.decodeIfPresent(type(of: d.showNumber), forKey: .showNumber) ?? d.showNumber
            showTime = try c.decodeIfPresent(type(of: d.showTime), forKey: .showTime) ?? d.showTime
            showTitle = try c.decodeIfPresent(type(of: d.showTitle), forKey: .showTitle) ?? d.showTitle
            useTitleLimit = try c.decodeIfPresent(type(of: d.useTitleLimit), forKey: .useTitleLimit) ?? d.useTitleLimit
            calendarNames = try c.decodeIfPresent(type(of: d.calendarNames), forKey: .calendarNames) ?? d.calendarNames
            workdayStartHour = try c.decodeIfPresent(type(of: d.workdayStartHour), forKey: .workdayStartHour) ?? d.workdayStartHour
            workdayEndHour = try c.decodeIfPresent(type(of: d.workdayEndHour), forKey: .workdayEndHour) ?? d.workdayEndHour
            showWidget = try c.decodeIfPresent(type(of: d.showWidget), forKey: .showWidget) ?? d.showWidget
            widgetFloatsOnTop = try c.decodeIfPresent(type(of: d.widgetFloatsOnTop), forKey: .widgetFloatsOnTop) ?? d.widgetFloatsOnTop
            widgetX = try c.decodeIfPresent(type(of: d.widgetX), forKey: .widgetX) ?? d.widgetX
            widgetY = try c.decodeIfPresent(type(of: d.widgetY), forKey: .widgetY) ?? d.widgetY
            showVerticalWidget = try c.decodeIfPresent(type(of: d.showVerticalWidget), forKey: .showVerticalWidget) ?? d.showVerticalWidget
            verticalWidgetFloatsOnTop = try c.decodeIfPresent(type(of: d.verticalWidgetFloatsOnTop), forKey: .verticalWidgetFloatsOnTop) ?? d.verticalWidgetFloatsOnTop
            verticalWidgetX = try c.decodeIfPresent(type(of: d.verticalWidgetX), forKey: .verticalWidgetX) ?? d.verticalWidgetX
            verticalWidgetY = try c.decodeIfPresent(type(of: d.verticalWidgetY), forKey: .verticalWidgetY) ?? d.verticalWidgetY
            verticalWidgetHeight = try c.decodeIfPresent(type(of: d.verticalWidgetHeight), forKey: .verticalWidgetHeight) ?? d.verticalWidgetHeight
        }
    }

    var data: Data = Data()
    var needsDisplay: Bool = true

    let archiveURL: URL

    init(archiveURL: URL = Settings.defaultArchiveURL()) {
        self.archiveURL = archiveURL
        super.init()
        unarchive()
    }

    override convenience init() {
        self.init(archiveURL: Settings.defaultArchiveURL())
    }

    static func defaultArchiveURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return URL(
            fileURLWithPath: paths[0].path + "/"
                + (Bundle.main.infoDictionary!["CFBundleName"] as! String) + ".cfg")
    }

    func unarchive() {
        do {
            let readData = try Foundation.Data(contentsOf: archivePath())
            self.data = try JSONDecoder().decode(Data.self, from: readData)
        } catch {
            reset()
        }
    }

    func archive() {
        let jsonData = try! JSONEncoder().encode(self.data)
        try! jsonData.write(to: archivePath())
    }

    func archivePath() -> URL { archiveURL }

    func reset() {
        data.floatRight = false
        data.useSystemAlert = false
        data.useBlockingAlert = false
        data.earlyWarning = 1
        data.notifyTravelTime = false
        data.useSound = false
        data.useFuzzyTime = false
        data.showSeconds = false
        data.leadingZeros = false
        data.showNumber = 10
        data.showTime = true
        data.showTitle = false
        data.useTitleLimit = false
        data.calendarNames = []
        data.workdayStartHour = 9
        data.workdayEndHour = 18
        data.showWidget = false
        data.widgetFloatsOnTop = true
        data.widgetX = -1
        data.widgetY = -1
        self.archive()
    }
}
