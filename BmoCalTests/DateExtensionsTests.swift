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

@Test("dayHeader labels today, tomorrow and later days")
func dayHeader() {
    let cal = Calendar.current
    let now = cal.date(from: DateComponents(year: 2026, month: 2, day: 12, hour: 10))!
    let tools = TimeStringTools()
    #expect(tools.dayHeader(for: now, now: now) == "Today (Thu, 12 Feb):")
    #expect(tools.dayHeader(for: now.addingTimeInterval(86400), now: now) == "Tomorrow (Fri, 13 Feb):")
    #expect(tools.dayHeader(for: now.addingTimeInterval(3 * 86400), now: now) == "Sun, 15 Feb:")
}

// MARK: - wasCrossed

private let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)

@Test("wasCrossed fires on an exact hit of now")
func wasCrossedExactHit() {
    #expect(t0.wasCrossed(since: t0.addingTimeInterval(-1), now: t0))
}

@Test("wasCrossed still fires when a tick was skipped")
func wasCrossedSkippedTick() {
    let target = t0.addingTimeInterval(-2)
    #expect(target.wasCrossed(since: t0.addingTimeInterval(-3), now: t0))
}

@Test("wasCrossed does not fire for a target before the window")
func wasCrossedBeforeWindow() {
    #expect(!t0.addingTimeInterval(-5).wasCrossed(since: t0.addingTimeInterval(-1), now: t0))
}

@Test("wasCrossed does not fire for a future target")
func wasCrossedFuture() {
    #expect(!t0.addingTimeInterval(1).wasCrossed(since: t0.addingTimeInterval(-1), now: t0))
}

@Test("wasCrossed caps catch up after a long gap")
func wasCrossedLongGap() {
    let previous = t0.addingTimeInterval(-600)
    #expect(!t0.addingTimeInterval(-120).wasCrossed(since: previous, now: t0))
    #expect(t0.addingTimeInterval(-30).wasCrossed(since: previous, now: t0))
}

@Test("early warning fires exactly once across 1 second ticks", arguments: [1, 3, 5])
func earlyWarningFiresOnce(minutes: Int) {
    let start = t0.addingTimeInterval(3600)
    let target = start.addingTimeInterval(-TimeInterval(minutes * 60))
    var fires = 0
    var previous = target.addingTimeInterval(-30.5)
    for i in -30...30 {
        let now = target.addingTimeInterval(Double(i) + 0.3)
        if target.wasCrossed(since: previous, now: now) { fires += 1 }
        previous = now
    }
    #expect(fires == 1)
}
