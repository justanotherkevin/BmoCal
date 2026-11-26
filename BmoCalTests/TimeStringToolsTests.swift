import Testing
import Foundation
@testable import BmoCal

private func at(_ hour: Int, _ minute: Int = 0) -> Date {
    Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 5, hour: hour, minute: minute))!
}

@Test("workdayFraction is 0 before, proportional during, 1 after the workday")
func workdayFractionRange() {
    let tools = TimeStringTools()
    #expect(tools.workdayFraction(startHour: 9, endHour: 17, now: at(7)) == 0)
    #expect(tools.workdayFraction(startHour: 9, endHour: 17, now: at(13)) == 0.5)
    #expect(tools.workdayFraction(startHour: 9, endHour: 17, now: at(19)) == 1)
}

@Test("durationString formats seconds", arguments: [
    (0.0, "now"), (59.0, "now"), (60.0, "1m"), (725.0, "12m"), (16320.0, "4h 32m"), (-5.0, "now"), (3900.0, "1h 05m")
])
func durationStringFormats(seconds: Double, expected: String) {
    #expect(TimeStringTools().durationString(seconds) == expected)
}
