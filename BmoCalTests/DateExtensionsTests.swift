import Testing
import Foundation
@testable import BmoCal

@Test("Date.startOfDay returns midnight of the same day")
func startOfDay() {
    let cal = Calendar.current
    var comps = DateComponents()
    comps.year = 2026; comps.month = 5; comps.day = 15
    comps.hour = 14; comps.minute = 30; comps.second = 45
    let date = cal.date(from: comps)!
    
    let result = date.startOfDay
    let expectedComps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: result)
    #expect(expectedComps.year == 2026)
    #expect(expectedComps.month == 5)
    #expect(expectedComps.day == 15)
    #expect(expectedComps.hour == 0)
    #expect(expectedComps.minute == 0)
    #expect(expectedComps.second == 0)
}

@Test("Date.endOfDay returns 23:59:59 of the same day")
func endOfDay() {
    let cal = Calendar.current
    var comps = DateComponents()
    comps.year = 2026; comps.month = 5; comps.day = 15
    let date = cal.date(from: comps)!
    
    let result = date.endOfDay!
    let expectedComps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: result)
    #expect(expectedComps.year == 2026)
    #expect(expectedComps.month == 5)
    #expect(expectedComps.day == 15)
    #expect(expectedComps.hour == 23)
    #expect(expectedComps.minute == 59)
    #expect(expectedComps.second == 59)
}

@Test("Date.toLocalTime and toGlobalTime are inverses")
func localGlobalRoundTrip() {
    let cal = Calendar.current
    var comps = DateComponents()
    comps.year = 2026; comps.month = 5; comps.day = 15
    comps.hour = 12; comps.minute = 0; comps.second = 0
    let date = cal.date(from: comps)!
    
    let local = date.toLocalTime()
    let global = local.toGlobalTime()
    let diff = abs(date.timeIntervalSince(global))
    #expect(diff < 1.0)  // should round-trip within 1 second
}
