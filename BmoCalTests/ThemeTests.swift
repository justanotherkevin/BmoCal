import Testing
import Foundation
@testable import BmoCal

private let checkedFiles = [
    "AppDelegate.swift", "NextEventViewController.swift", "WorkdayWidgetView.swift",
    "VerticalWidgetView.swift", "VerticalWidgetWindowController.swift",
    "WorkdayWidgetWindowController.swift", "SettingsWindow.swift",
]
private let banned = ["NSColor.white", "NSColor.black", "NSColor.lightGray", "NSColor.gray",
                      "NSFont(name:", "calibratedWhite", "calibratedRed"]

@Test("views use system colors and Theme fonts, no hardcoded ones", arguments: checkedFiles)
func noHardcodedColorsOrFonts(file: String) throws {
    let url = URL(fileURLWithPath: #filePath).appendingPathComponent("../../BmoCal/\(file)").standardized
    let source = try String(contentsOf: url, encoding: .utf8)
    for token in banned { #expect(!source.contains(token), "\(file) contains \(token)") }
}

@Test("Theme.number clamps to the minimum font size")
func fontClamp() {
    #expect(Theme.number(6).pointSize == Theme.minFontSize)
}
