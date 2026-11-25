import Testing
import Foundation
@testable import BmoCal

@Test("Settings struct default values are correct")
func settingsDataDefaultValues() {
    let data = Settings.Data()

    #expect(data.workdayStartHour == 9)
    #expect(data.workdayEndHour == 18)
    #expect(data.showWidget == false)
    #expect(data.widgetFloatsOnTop == true)
    #expect(data.showNumber == 10)
    #expect(data.useFlash == false)
    #expect(data.showSeconds == false)
    #expect(data.useSound == false)
    #expect(data.calendarNames == [])
}

@Test("Settings reset() returns to default values")
func settingsReset() {
    let settings = Settings()

    // Modify some values
    settings.data.workdayStartHour = 8
    settings.data.useFlash = true
    settings.data.calendarNames = ["Calendar 1", "Calendar 2"]

    // Reset
    settings.reset()

    // Verify defaults are restored
    #expect(settings.data.workdayStartHour == 9)
    #expect(settings.data.useFlash == true)
    #expect(settings.data.calendarNames == [])
}

@Test("Settings archive stores and unarchive restores modified values")
func settingsArchiveUnarchive() {
    let settings1 = Settings()

    // Modify values
    settings1.data.workdayStartHour = 7
    settings1.data.workdayEndHour = 19
    settings1.data.calendarNames = ["Work", "Personal"]

    // Archive to disk
    settings1.archive()

    // Create new instance and unarchive
    let settings2 = Settings()

    // Verify values were restored from disk
    #expect(settings2.data.workdayStartHour == 7)
    #expect(settings2.data.workdayEndHour == 19)
    #expect(settings2.data.calendarNames == ["Work", "Personal"])
}

@Test("StatusStringBuilder returns 'Work in Xh Ym' before workday")
func statusStringBuilderBeforeWorkday() {
    var settings = Settings.Data()
    settings.workdayStartHour = 9
    settings.workdayEndHour = 18

    // Create a time at 8:00 AM
    let cal = Calendar.current
    var comps = DateComponents()
    comps.year = 2026; comps.month = 5; comps.day = 15
    comps.hour = 8; comps.minute = 0; comps.second = 0
    let time8am = cal.date(from: comps)!

    let builder = StatusStringBuilder(settings: settings, events: [], timeTools: TimeStringTools())
    let (status, _) = builder.build(now: time8am)

    // Before 9am, should show "Work in Xh Ym" format
    #expect(status.contains("Work in"))
    #expect(status.contains("1h"))
}

@Test("validSavedOrigin accepts on-screen and left-monitor origins, rejects off-screen and unset")
func validSavedOriginCases() {
    let main = NSRect(x: 0, y: 0, width: 1920, height: 1080)
    let left = NSRect(x: -1920, y: 0, width: 1920, height: 1080)
    let size = CGSize(width: 200, height: 200)
    #expect(validSavedOrigin(x: 100, y: 100, size: size, screens: [main]) == CGPoint(x: 100, y: 100))
    #expect(validSavedOrigin(x: 4405, y: 100, size: size, screens: [main]) == nil)
    #expect(validSavedOrigin(x: -500, y: 100, size: size, screens: [left, main]) == CGPoint(x: -500, y: 100))
    #expect(validSavedOrigin(x: -1, y: -1, size: size, screens: [main]) == nil)
}

@Test("Old cfg JSON containing removed keys (useAltIcon) still decodes")
func settingsDecodeIgnoresUnknownKeys() throws {
    var dict = try JSONSerialization.jsonObject(with: JSONEncoder().encode(Settings.Data())) as! [String: Any]
    dict["useAltIcon"] = true
    dict["workdayStartHour"] = 7
    let json = try JSONSerialization.data(withJSONObject: dict)
    let data = try JSONDecoder().decode(Settings.Data.self, from: json)
    #expect(data.workdayStartHour == 7)
}
