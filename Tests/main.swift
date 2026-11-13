import Foundation

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

func date(_ text: String) -> Date {
    ISO8601DateFormatter().date(from: text)!
}

let catalogue = try WordCatalogue(data: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
check(catalogue.words.count == 1000, "The offline bank must have exactly 1000 cards")
check(Set(catalogue.words.map { $0.word.lowercased() }).count == 1000, "1000 distinct headwords")
check(catalogue.words.filter { $0.register != "standard" }.count >= 100, "Ordinary vocabulary and informal/slang cards")
check(catalogue.words.allSatisfy { $0.examples.count == 2 }, "Two examples per word")
check(catalogue.words.allSatisfy { !$0.translation.isEmpty && !$0.definition.isEmpty }, "Bilingual content required")

let moscow = TimeZone(identifier: "Europe/Moscow")!
check(catalogue.word(on: date("2026-11-13T09:00:00Z"), timeZone: moscow)?.id == "euphoria", "Anchor day")
check(catalogue.word(on: date("2026-11-13T20:59:59Z"), timeZone: moscow)?.id == "euphoria", "Before local midnight")
check(catalogue.word(on: date("2026-11-13T21:00:00Z"), timeZone: moscow)?.id == "lowkey", "At local midnight")
check(catalogue.word(on: date("2026-11-27T09:00:00Z"), timeZone: moscow)?.id == catalogue.words[14].id, "Day 15 continues without repeating the first word")
check(catalogue.word(on: date("2026-11-12T09:00:00Z"), timeZone: moscow) == nil, "No word before the start")

let queueCalendar = DailySchedule.calendar(in: moscow)
let queueStart = queueCalendar.date(from: DateComponents(year: 2026, month: 11, day: 13))!
var publishedIDs = Set<String>()
for offset in 0..<1000 {
    let day = queueCalendar.date(byAdding: .day, value: offset, to: queueStart)!
    let word = catalogue.word(on: day, timeZone: moscow)!
    check(publishedIDs.insert(word.id).inserted, "No repeat during the entire 1000-day schedule")
    check(word == catalogue.words[offset], "Appending the bank preserves date-to-card order")
    check(catalogue.remainingWords(after: day, timeZone: moscow) == 999-offset, "Remaining queue shrinks by one per civil day")
}
let afterLast = queueCalendar.date(byAdding: .day, value: 1000, to: queueStart)!
check(catalogue.word(on: afterLast, timeZone: moscow) == nil, "End of the queue never wraps")
check(catalogue.remainingWords(after: afterLast, timeZone: moscow) == 0, "Remaining count never becomes negative")
check(catalogue.remainingWords(after: date("2026-11-12T09:00:00Z"), timeZone: moscow) == 1000, "Full queue before the start")
check(catalogue.recentWeek(endingOn: queueStart, timeZone: moscow).count == 1, "Only one day of history at the start")
check(catalogue.recentWeek(endingOn: afterLast, timeZone: moscow).count == 6, "Past cards remain after exhaustion")
check(catalogue.recentWeek(endingOn: queueCalendar.date(byAdding: .day, value: 7, to: afterLast)!, timeZone: moscow).isEmpty,
      "No fabricated history once all seven days are outside the schedule")

for zone in ["Europe/Moscow", "America/New_York", "Pacific/Auckland", "Asia/Kathmandu"] {
    let timeZone = TimeZone(identifier: zone)!
    let calendar = DailySchedule.calendar(in: timeZone)
    for instant in ["2027-03-13T18:00:00Z", "2027-11-06T18:00:00Z", "2026-12-31T18:00:00Z"] {
        let now = date(instant)
        let dates = DailySchedule.timelineDates(from: now, timeZone: timeZone)
        check(dates.count == 8 && dates[0] == now, "Current entry and seven future entries")
        for index in 1..<dates.count {
            check(dates[index] > dates[index-1], "Timeline must be chronological")
            check(calendar.component(.hour, from: dates[index]) == 0, "Local midnight")
            check(calendar.component(.minute, from: dates[index]) == 0, "No stray minutes")
            let previous = DailySchedule.dayIndex(on: dates[index-1], timeZone: timeZone, count: 1000)!
            let next = DailySchedule.dayIndex(on: dates[index], timeZone: timeZone, count: 1000)!
            check(next == previous + 1, "One word per civil day, including DST")
        }
    }
}

for word in catalogue.words {
    check(WordLink.wordID(from: WordLink.url(for: word), catalogue: catalogue) == word.id, "Deep link round trip")
}
for link in ["https://word/euphoria", "worddaily://other/euphoria", "worddaily://word/unknown",
             "worddaily://word/euphoria/extra", "worddaily://word/euphoria?x=1", "worddaily://word/"] {
    check(WordLink.wordID(from: URL(string: link)!, catalogue: catalogue) == nil, "Reject invalid route")
}

let empty = Data("[]".utf8)
check((try? WordCatalogue(data: empty)) == nil, "Empty catalogues are rejected")
let duplicate = try JSONEncoder().encode([catalogue.words[0], catalogue.words[0]])
check((try? WordCatalogue(data: duplicate)) == nil, "Duplicate identifiers are rejected")
print("PASS: 1000 complete cards, 1000 unique daily releases, decreasing queue, exhaustion, 4 time zones, DST, deep links")

// The history must contain civil dates, including when crossing DST and midnight.
for zone in ["Europe/Moscow", "America/New_York", "Pacific/Auckland", "Asia/Kathmandu"] {
    let timeZone = TimeZone(identifier: zone)!
    let calendar = DailySchedule.calendar(in: timeZone)
    for instant in ["2026-11-20T21:00:00Z", "2027-03-16T18:00:00Z", "2027-11-09T18:00:00Z", "2027-01-02T18:00:00Z"] {
        let now = date(instant)
        let week = catalogue.recentWeek(endingOn: now, timeZone: timeZone)
        check(week.count == 7 && Set(week.map(\.id)).count == 7, "Exactly seven distinct days")
        check(week[0].word == catalogue.word(on: now, timeZone: timeZone), "History starts with today's widget word")
        for (offset, day) in week.enumerated() {
            check(day.date <= now, "No future words in history")
            check(calendar.startOfDay(for: day.date) == day.date, "History dates are local midnights")
            check(calendar.dateComponents([.day], from: day.date, to: calendar.startOfDay(for: now)).day == offset,
                  "Newest first, with no missing calendar days")
            check(day.word == catalogue.word(on: day.date, timeZone: timeZone), "History matches daily schedule")
        }
    }
}

func verifySavedWords() throws {
    let suiteName = "WordDailyTests." + UUID().uuidString
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = SavedWordsStore(defaults: defaults)
    let first = catalogue.words[0]
    let second = catalogue.words[1]
    check(store.words.isEmpty, "A new dictionary is empty")
    store.save(first)
    store.save(second)
    store.save(first)
    check(store.words.map(\.id) == [second.id, first.id], "Newest first and no duplicates")
    let reopened = SavedWordsStore(defaults: UserDefaults(suiteName: suiteName)!)
    check(reopened.words == store.words, "Complete saved cards reload from persistent storage")
    check(reopened.words[1].examples == first.examples, "Translations and examples survive reload")
    reopened.toggle(second)
    check(!reopened.contains(second) && reopened.contains(first), "Toggle removes only the selected word")
    reopened.toggle(second)
    check(reopened.words.first == second, "Toggle saves the word again")
    reopened.save(catalogue.words[2])
    reopened.remove(ids: [first.id, second.id])
    check(reopened.words == [catalogue.words[2]], "Batch removal preserves unselected words")
    reopened.remove(catalogue.words[2])
    check(SavedWordsStore(defaults: defaults).words.isEmpty, "Deletion persists across reload")
    defaults.set(try JSONEncoder().encode([first, first, second]), forKey: "savedWordCards.v1")
    check(SavedWordsStore(defaults: defaults).words == [first, second], "Duplicate stored IDs are normalized")
    defaults.set(Data("invalid json".utf8), forKey: "savedWordCards.v1")
    let recovered = SavedWordsStore(defaults: defaults)
    check(recovered.words.isEmpty, "Invalid stored data does not crash")
    recovered.save(first)
    check(SavedWordsStore(defaults: defaults).words == [first], "Saving recovers from invalid storage")
}
try verifySavedWords()
print("PASS: seven-day history across time zones and DST; saved cards, reload, duplicates, removal, invalid storage")
