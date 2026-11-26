import Testing
@testable import BmoCal

struct SettingsWindowTests {
    @Test(arguments: AlertStyle.allCases)
    func roundTrip(style: AlertStyle) {
        var d = BmoCal.Settings.Data()
        d.useSystemAlert = true; d.useSound = true; d.useBlockingAlert = true // stale values must be cleared
        style.apply(to: &d)
        #expect(AlertStyle(d) == style)
        #expect([d.useSystemAlert, d.useBlockingAlert, d.useSound].filter { $0 }.count == (style == .none ? 0 : 1))
    }

    @Test func priority() {
        var d = BmoCal.Settings.Data()
        d.useSound = true
        #expect(AlertStyle(d) == .chime)
        d.useSystemAlert = true
        #expect(AlertStyle(d) == .banner)
        d.useBlockingAlert = true
        #expect(AlertStyle(d) == .fullScreen)
    }

    @Test func workday() {
        #expect(!AlertStyle.isValidWorkday(start: 9, end: 9))
        #expect(!AlertStyle.isValidWorkday(start: 10, end: 9))
        #expect(AlertStyle.isValidWorkday(start: 9, end: 17))
        #expect(AlertStyle.isValidWorkday(start: 0, end: 23))
    }
}
