import Foundation

enum DailySchedule {
    /// Uses civil days, not elapsed 24-hour intervals: DST cannot skip a word.
    static func calendar(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func dayIndex(on date: Date, timeZone: TimeZone = .current, count: Int) -> Int {
        precondition(count > 0)
        let calendar = calendar(in: timeZone)
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 11, day: 13))!
        let days = calendar.dateComponents([.day], from: anchor, to: calendar.startOfDay(for: date)).day!
        return ((days % count) + count) % count
    }

    /// The current entry plus seven scheduled local midnights for offline widgets.
    static func timelineDates(from now: Date, timeZone: TimeZone = .current) -> [Date] {
        let calendar = calendar(in: timeZone)
        let start = calendar.startOfDay(for: now)
        return [now] + (1...7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
}
