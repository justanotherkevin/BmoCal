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
        var useAltIcon: Bool = false
        var useFlashBlue: Bool = false
        var useFlash: Bool = false
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
    }

    var data: Data = Data()
    var needsDisplay: Bool = true

    override init() {
        super.init()
        unarchive()
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

    func archivePath() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return URL(
            fileURLWithPath: paths[0].path + "/"
                + (Bundle.main.infoDictionary!["CFBundleName"] as! String) + ".cfg")
    }

    func reset() {
        data.floatRight = false
        data.useAltIcon = false
        data.useFlashBlue = false
        data.useFlash = true
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
