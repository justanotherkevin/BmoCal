import Testing
import SwiftUI
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

    @Test func earlyWarningChoices() {
        #expect(AlertStyle.earlyWarningChoices == [0, 1, 3, 5])
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

    @Test func alertDesignTitles() {
        #expect(AlertDesign.allCases.map(\.title) == ["Ring", "Card", "Edge"])
    }

    @Test func countdownText() {
        #expect(EventAlertView.countdownText(179.2) == "3:00")
        #expect(EventAlertView.countdownText(59) == "0:59")
        #expect(EventAlertView.countdownText(0) == "Started")
        #expect(EventAlertView.countdownText(-5) == "Started")
        #expect(EventAlertView.countdownText(3725) == "1:02:05")
    }

    @MainActor @Test(arguments: AlertDesign.allCases)
    func snapshot(design: AlertDesign) throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("BmoCalAlertSnapshots")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let view = EventAlertView(design: design, title: "Design review", start: Date().addingTimeInterval(180),
                                  link: URL(string: "https://meet.google.com/x"), color: .systemOrange,
                                  onJoin: {}, onDismiss: {})
            .frame(width: 1440, height: 900)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        let cg = try #require(renderer.cgImage)
        let png = try #require(NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]))
        let url = dir.appendingPathComponent("\(design.title.lowercased()).png")
        try png.write(to: url)
        print("Snapshots: \(dir.path)")
        #expect(!png.isEmpty)
    }
}
