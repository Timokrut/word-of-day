import Foundation

struct WordExample: Codable, Hashable {
    let english: String
    let russian: String
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

    func word(on date: Date, timeZone: TimeZone = .current) -> WordEntry {
        words[DailySchedule.dayIndex(on: date, timeZone: timeZone, count: words.count)]
    }

    enum CatalogueError: Error { case missingResource, invalidContents }
}

enum WordLink {
    static func url(for word: WordEntry) -> URL {
        var components = URLComponents()
        components.scheme = "worddaily"
        components.host = "word"
        components.path = "/" + word.id
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
