import Foundation
import EventKit
import Cocoa

protocol EventStoreProtocol {
    func getTopN(n: Int, calendars: [EKCalendar], reminders: [EKCalendar]) -> [EKCalendarItem]
    func getTodayAll(calendars: [EKCalendar], reminders: [EKCalendar]) -> [EKCalendarItem]
    func get24Hours(calendars: [EKCalendar], reminders: [EKCalendar]) -> [EKCalendarItem]
    func getTodayEvents(calendars: [EKCalendar]) -> [EKEvent]
    func getCalendarByNames(names: [String]) -> [EKCalendar]
    func getReminderListByNames(names: [String]) -> [EKCalendar]
    func getAllCalendars() -> [EKCalendar]
    func getAllReminderLists() -> [EKCalendar]
    func requestAccess() -> Bool
}

class CalendarTools: NSObject, EventStoreProtocol {

    let eventStore = EKEventStore()

    func getEventsAndReminderOnDay(day: Date, calendars: [EKCalendar], reminders: [EKCalendar]) -> [EKCalendarItem] {
        var all: [EKCalendarItem:Date] = [:]

        guard let dayEnd = day.endOfDay else { return [] }
        for item in getReminders(start: day.startOfDay, end: dayEnd, calendars: reminders) {
            guard let reminder = item as? EKReminder,
                  let dc = reminder.dueDateComponents,
                  let date = Calendar.current.date(from: dc),
                  date >= day.startOfDay && date < dayEnd else { continue }
            all[item] = date
        }
        for item in getEvents(start: day.startOfDay, end: dayEnd, calendars: calendars) {
            guard let event = item as? EKEvent,
                  let date = event.startDate,
                  date >= day.startOfDay && date <= dayEnd else { continue }
            all[item] = date
        }

        let sortedKeys = Array(all.keys).sorted{all[$0]! < all[$1]!}

        return sortedKeys
    }

    func getTopN(n: Int, calendars: [EKCalendar], reminders: [EKCalendar]) -> [EKCalendarItem] {
        let now = Date()
        let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: now)!
        return queryAndSortItems(start: now, end: oneYearFromNow, calendars: calendars, reminders: reminders, limit: n)
    }

    func getTodayAll(calendars: [EKCalendar], reminders: [EKCalendar]) -> [EKCalendarItem] {
        let startDate = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month, .day], from: Date())
        )!.addingTimeInterval(-1)
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
        return queryAndSortItems(start: startDate, end: endDate, calendars: calendars, reminders: reminders)
    }

    func get24Hours(calendars: [EKCalendar], reminders: [EKCalendar]) -> [EKCalendarItem] {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .second, value: 86400, to: startDate)!
        return queryAndSortItems(start: startDate, end: endDate, calendars: calendars, reminders: reminders)
    }

    private func queryAndSortItems(start: Date, end: Date, calendars: [EKCalendar], reminders: [EKCalendar], limit: Int? = nil) -> [EKCalendarItem] {
        var all: [EKCalendarItem: Date] = [:]

        for item in getReminders(start: start, end: end, calendars: reminders) {
            guard let reminder = item as? EKReminder,
                  let dc = reminder.dueDateComponents,
                  let date = Calendar.current.date(from: dc),
                  date > start else { continue }
            all[item] = date
        }

        for item in getEvents(start: start, end: end, calendars: calendars) {
            guard let event = item as? EKEvent,
                  let date = event.startDate,
                  date > start else { continue }
            print("calendar color: \(String(describing: event.calendar.color))")
            all[item] = date
        }

        let sortedKeys = Array(all.keys).sorted { all[$0]! < all[$1]! }
        var results: [EKCalendarItem] = []

        for (index, item) in sortedKeys.enumerated() {
            results.append(item)
            if let limit = limit, index + 1 >= limit {
                break
            }
        }

        return results
    }

    func getReminders(start: Date, end: Date, calendars: [EKCalendar]) -> [EKCalendarItem] {
        var results: [EKReminder] = []
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: start,
            ending: end,
            calendars: calendars
        )
        let group = DispatchGroup()

        group.enter()
        eventStore.fetchReminders(matching: predicate, completion: { (reminders: [EKReminder]?) -> Void in
            DispatchQueue.global().sync {
                results = reminders ?? []
                group.leave()
            }
        })
        group.wait()

        return results
    }

    func getEvents(start: Date, end: Date, calendars: [EKCalendar]) -> [EKCalendarItem] {
        var results: [EKEvent] = []
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
        let events = eventStore.events(matching: predicate)

        for event in events {
            if !results.contains(event) {
                results.append(event)
            }
        }
        return results
    }

    func hasRemindersOnDay(day: Date) -> Bool {
        var retval = false
        var results: [EKReminder] = []
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: day.startOfDay,
            ending: day.endOfDay,
            calendars: nil
        )
        let group = DispatchGroup()

        group.enter()
        eventStore.fetchReminders(matching: predicate, completion: { (reminders: [EKReminder]?) -> Void in
            DispatchQueue.global().sync {
                results = reminders ?? []
                group.leave()
            }
        })
        group.wait()

        return !results.isEmpty
    }

    func hasEventsOnDay(day: Date, calendars: [EKCalendar]) -> Bool {
        var results = false
        let predicate = eventStore.predicateForEvents(
            withStart: day.startOfDay,
            end: day.endOfDay!,
            calendars: calendars
        )
        let events = eventStore.events(matching: predicate)

        if events.count > 0 {
            results = true
        }

        return results
    }

    // calendars and reminder lists

    func getAllCalendars() -> [EKCalendar] {
        let calendars = eventStore.calendars(for: EKEntityType.event)
        return calendars
    }

    func getAllReminderLists() -> [EKCalendar] {
        let list = eventStore.calendars(for: EKEntityType.reminder)
        return list
    }

    func getCalendarByNames(names: [String]) -> [EKCalendar] {
        var results: [EKCalendar] = []
        let calendars = eventStore.calendars(for: EKEntityType.event)
        for calendar in calendars {
            if names.contains(calendar.title) {
                results.append(calendar)
            }
        }
        return results
    }

    func getReminderListByNames(names: [String]) -> [EKCalendar] {
        var results: [EKCalendar] = []
        let calendars = eventStore.calendars(for: EKEntityType.reminder)
        for calendar in calendars {
            if names.contains(calendar.title) {
                results.append(calendar)
            }
        }
        return results
    }

    func getCalendarByIdentifier(identifiers: [String]) -> [EKCalendar] {
        var results: [EKCalendar] = []
        let calendars = eventStore.calendars(for: EKEntityType.event)
        for calendar in calendars {
            if identifiers.contains(calendar.calendarIdentifier) {
                results.append(calendar)
            }
        }
        return results
    }

    func getReminderListByIdentifier(identifiers: [String]) -> [EKCalendar] {
        var results: [EKCalendar] = []
        let calendars = eventStore.calendars(for: EKEntityType.reminder)
        for calendar in calendars {
            if identifiers.contains(calendar.calendarIdentifier) {
                results.append(calendar)
            }
        }
        return results
    }

    func getCalendarNames() -> [String] {
        var results: [String] = []
        let calendars = eventStore.calendars(for: EKEntityType.event)
        for calendar in calendars {
            if !results.contains(calendar.title) {
                results.append(calendar.title)
            }
        }
        return results
    }

    func getReminderListNames() -> [String] {
        var results: [String] = []
        let calendars = eventStore.calendars(for: EKEntityType.reminder)
        for calendar in calendars {
            if !results.contains(calendar.title) {
                results.append(calendar.title)
            }
        }
        return results
    }

    func getTodayEvents(calendars: [EKCalendar]) -> [EKEvent] {
        let today = Date()
        guard let endOfDay = today.endOfDay else { return [] }
        let items = getEvents(start: today.startOfDay, end: endOfDay, calendars: calendars)
        return items.compactMap { $0 as? EKEvent }
            .filter { $0.startDate != nil }
            .sorted { ($0.startDate ?? .distantFuture) < ($1.startDate ?? .distantFuture) }
    }

    func getCalendarColorByName(name: String) -> NSColor {
        let calendars = eventStore.calendars(for: EKEntityType.event)
        for calendar in calendars {
            if name == calendar.title {
                return calendar.color
            }
        }
        return NSColor.clear
    }

    func getReminderListColorByName(name: String) -> NSColor {
        let calendars = eventStore.calendars(for: EKEntityType.reminder)
        for calendar in calendars {
            if name == calendar.title {
                return calendar.color
            }
        }
        return NSColor.clear
    }

    // currently not working not sure why, moved to appDelegate
    func registerNotification(_ selector: Selector) {
        eventStore.requestAccess(to: .event, completion: {
            (_ granted: Bool, _ error: Error?) -> Void in
            if granted {
                NotificationCenter.default.addObserver(
                    self,
                    selector: selector,
                    name: .EKEventStoreChanged,
                    object: nil
                )
            }
        })
        eventStore.requestAccess(to: .reminder, completion: {
            (_ granted: Bool, _ error: Error?) -> Void in
            if granted {
                NotificationCenter.default.addObserver(
                    self,
                    selector: selector,
                    name: .EKEventStoreChanged,
                    object: nil
                )
            }
        })
    }

    func requestAccess() -> Bool {
        let group = DispatchGroup()
        var eventGranted = true
        var reminderGranted = true

        group.enter()
        eventStore.requestAccess(to: .event) { granted, _ in
            eventGranted = granted
            group.leave()
        }

        group.enter()
        eventStore.requestAccess(to: .reminder) { granted, _ in
            reminderGranted = granted
            group.leave()
        }

        group.wait()
        return eventGranted && reminderGranted
    }
}
