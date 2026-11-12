import Foundation

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

func date(_ text: String) -> Date {
    ISO8601DateFormatter().date(from: text)!
}

let catalogue = try WordCatalogue(data: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
check(catalogue.words.count == 14, "Demo catalogue must have 14 words")
check(catalogue.words.filter { $0.register == "slang" }.count == 7, "Seven slang words")
check(catalogue.words.allSatisfy { $0.examples.count == 2 }, "Two examples per word")
check(catalogue.words.allSatisfy { !$0.translation.isEmpty && !$0.definition.isEmpty }, "Bilingual content required")

let moscow = TimeZone(identifier: "Europe/Moscow")!
check(catalogue.word(on: date("2026-11-13T09:00:00Z"), timeZone: moscow).id == "euphoria", "Anchor day")
check(catalogue.word(on: date("2026-11-13T20:59:59Z"), timeZone: moscow).id == "euphoria", "Before local midnight")
check(catalogue.word(on: date("2026-11-13T21:00:00Z"), timeZone: moscow).id == "lowkey", "At local midnight")
check(catalogue.word(on: date("2026-11-27T09:00:00Z"), timeZone: moscow).id == "euphoria", "Cycle wraps")
check(catalogue.word(on: date("2026-11-12T09:00:00Z"), timeZone: moscow).id == "cooked", "Dates before anchor")

for zone in ["Europe/Moscow", "America/New_York", "Pacific/Auckland", "Asia/Kathmandu"] {
    let timeZone = TimeZone(identifier: zone)!
    let calendar = DailySchedule.calendar(in: timeZone)
    for instant in ["2026-03-07T18:00:00Z", "2026-10-31T18:00:00Z", "2026-12-31T18:00:00Z"] {
        let now = date(instant)
        let dates = DailySchedule.timelineDates(from: now, timeZone: timeZone)
        check(dates.count == 8 && dates[0] == now, "Current entry and seven future entries")
        for index in 1..<dates.count {
            check(dates[index] > dates[index-1], "Timeline must be chronological")
            check(calendar.component(.hour, from: dates[index]) == 0, "Local midnight")
            check(calendar.component(.minute, from: dates[index]) == 0, "No stray minutes")
            let previous = DailySchedule.dayIndex(on: dates[index-1], timeZone: timeZone, count: 14)
            let next = DailySchedule.dayIndex(on: dates[index], timeZone: timeZone, count: 14)
            check(next == (previous + 1) % 14, "One word per civil day, including DST")
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
print("PASS: catalogue, Russian content, daily rotation, 4 time zones, DST, year boundary, deep links, invalid data")
