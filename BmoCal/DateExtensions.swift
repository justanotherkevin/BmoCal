import Foundation

extension Date {

    /// True when `self` falls in the window since the last check. Catch up is capped so a long sleep does not fire stale alerts.
    func wasCrossed(since previous: Date, now: Date, maxCatchUp: TimeInterval = 60) -> Bool {
        let from = max(previous, now.addingTimeInterval(-maxCatchUp))
        return self > from && self <= now
    }

    // MARK: - Timezone conversion

    /// Convert UTC (or GMT) to local time
    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }

    /// Convert local time to UTC (or GMT)
    func toGlobalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = -TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }

    /// Format date to string with given format
    func toString(dateFormat format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }

    // MARK: - Day boundaries

    /// Midnight at the start of this date
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    /// 23:59:59 at the end of this date
    var endOfDay: Date? {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)
    }

    /// Midnight at the start of the next day
    var startOfNextDay: Date? {
        var components = DateComponents()
        components.day = 1
        return Calendar.current.date(byAdding: components, to: startOfDay)
    }
}
