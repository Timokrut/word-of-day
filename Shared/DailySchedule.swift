import Foundation

enum DailySchedule {
    /// Uses civil days, not elapsed 24-hour intervals: DST cannot skip a word.
    static func calendar(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func elapsedDays(on date: Date, timeZone: TimeZone = .current) -> Int {
        let calendar = calendar(in: timeZone)
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 11, day: 13))!
        return calendar.dateComponents([.day], from: anchor, to: calendar.startOfDay(for: date)).day!
    }

    /// A finite queue: dates outside the published range never wrap around.
    static func dayIndex(on date: Date, timeZone: TimeZone = .current, count: Int) -> Int? {
        let day = elapsedDays(on: date, timeZone: timeZone)
        return (0..<max(0, count)).contains(day) ? day : nil
    }

    /// Today's card is already published, so only later cards count as remaining.
    static func remainingWords(after date: Date, timeZone: TimeZone = .current, count: Int) -> Int {
        let published = max(0, elapsedDays(on: date, timeZone: timeZone) + 1)
        return max(0, count - published)
    }

    /// The current entry plus seven scheduled local midnights for offline widgets.
    static func timelineDates(from now: Date, timeZone: TimeZone = .current) -> [Date] {
        let calendar = calendar(in: timeZone)
        let start = calendar.startOfDay(for: now)
        return [now] + (1...7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
}
