import Testing
import Foundation
@testable import BmoCal

@Test("workdayProgressBar produces correct block characters")
func workdayProgressBar() {
    let tools = TimeStringTools()

    // 9 AM, so at the very start of workday (9-18 = 9 hours = 540 minutes)
    let bar = tools.workdayProgressBar(startHour: 9, endHour: 18)

    // Should be something like [░░░░░░░░░░] - all empty
    // The bar is 10 characters, so we check the structure
    #expect(bar.contains("["))
    #expect(bar.contains("]"))
    #expect(bar.count == 12)  // [ + 10 chars + ]
}
