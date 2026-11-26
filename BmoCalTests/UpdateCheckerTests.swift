import Testing
import Foundation
@testable import BmoCal

@Test("isNewer detects newer versions")
func updateCheckerNewer() {
    #expect(UpdateChecker.isNewer("2.2.5", than: "2.2.4"))
    #expect(UpdateChecker.isNewer("2.10.0", than: "2.9.0"))
    #expect(UpdateChecker.isNewer("v3.0.0", than: "2.9.9"))
}

@Test("isNewer is false for equal or older versions")
func updateCheckerNotNewer() {
    #expect(!UpdateChecker.isNewer("v2.2.4", than: "2.2.4"))
    #expect(!UpdateChecker.isNewer("2.2.3", than: "2.2.4"))
    #expect(!UpdateChecker.isNewer("2.9.0", than: "2.10.0"))
}

@Test("isNewer handles different component counts")
func updateCheckerComponentCounts() {
    #expect(UpdateChecker.isNewer("2.3", than: "2.2.4"))
    #expect(!UpdateChecker.isNewer("2.2", than: "2.2.0"))
    #expect(UpdateChecker.isNewer("2.2.1", than: "2.2"))
}

@Test("isNewer returns false for junk input")
func updateCheckerJunk() {
    #expect(!UpdateChecker.isNewer("latest", than: "2.2.4"))
    #expect(!UpdateChecker.isNewer("2.x.1", than: "2.2.4"))
    #expect(!UpdateChecker.isNewer("", than: "2.2.4"))
    #expect(!UpdateChecker.isNewer("3.0.0", than: "junk"))
}
