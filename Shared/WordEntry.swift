import Foundation

struct WordExample: Codable, Hashable {
    let english: String
    let russian: String
    let sourceURL: URL?
    let translationSourceURL: URL?
}

struct WordEntry: Codable, Identifiable, Hashable {
    let id: String
    let word: String
    let partOfSpeech: String
    let phonetic: String
    let register: String
    let definition: String
    let translation: String
    let explanation: String
    let usage: String
    let synonyms: [String]
    let examples: [WordExample]
    let source: String?
    let sourceURL: URL?

    var registerLabel: String? {
        switch register {
        case "slang": return "сленг"
        case "informal": return "разговорное"
        default: return nil
        }
    }
}

struct WordCatalogue {
    let words: [WordEntry]

    init(data: Data) throws {
        let decoded = try JSONDecoder().decode([WordEntry].self, from: data)
        guard !decoded.isEmpty, Set(decoded.map(\.id)).count == decoded.count else {
            throw CatalogueError.invalidContents
        }
        guard decoded.allSatisfy({ !$0.id.isEmpty && !$0.word.isEmpty && !$0.examples.isEmpty }) else {
            throw CatalogueError.invalidContents
        }
        words = decoded
    }

    init(bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: "words", withExtension: "json") else {
            throw CatalogueError.missingResource
        }
        try self.init(data: Data(contentsOf: url))
    }

    subscript(id: String) -> WordEntry? { words.first { $0.id == id } }

    func word(on date: Date, timeZone: TimeZone = .current) -> WordEntry? {
        guard let index = DailySchedule.dayIndex(on: date, timeZone: timeZone, count: words.count) else { return nil }
        return words[index]
    }

    func remainingWords(after date: Date, timeZone: TimeZone = .current) -> Int {
        DailySchedule.remainingWords(after: date, timeZone: timeZone, count: words.count)
    }

    /// Today and six previous civil days, newest first. No future entries.
    func recentWeek(endingOn date: Date, timeZone: TimeZone = .current) -> [DatedWord] {
        let calendar = DailySchedule.calendar(in: timeZone)
        let today = calendar.startOfDay(for: date)
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            guard let word = word(on: day, timeZone: timeZone) else { return nil }
            return DatedWord(date: day, word: word)
        }
    }

    enum CatalogueError: Error { case missingResource, invalidContents }
}

struct DatedWord: Identifiable {
    let date: Date
    let word: WordEntry
    var id: Date { date }
}

enum WordLink {
    static func url(for word: WordEntry) -> URL {
        url(forID: word.id)
    }

    static func url(forID id: String) -> URL {
        var components = URLComponents()
        components.scheme = "worddaily"
        components.host = "word"
        components.path = "/" + id
        // IDs are local, validated catalogue identifiers, never arbitrary URLs.
        return components.url!
    }

    static func wordID(from url: URL, catalogue: WordCatalogue) -> String? {
        guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.scheme?.lowercased() == "worddaily", parts.host == "word",
              parts.user == nil, parts.password == nil, parts.port == nil,
              parts.query == nil, parts.fragment == nil else { return nil }
        let path = parts.path
        guard path.hasPrefix("/"), path.dropFirst().contains("/") == false else { return nil }
        let id = String(path.dropFirst())
        return catalogue[id] == nil ? nil : id
    }
}
