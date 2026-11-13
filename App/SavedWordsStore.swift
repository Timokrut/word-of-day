import Combine
import Foundation

/// Stores complete cards so saved words survive later changes to the catalogue.
final class SavedWordsStore: ObservableObject {
    @Published private(set) var words: [WordEntry]
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "savedWordCards.v1") {
        self.defaults = defaults
        self.key = key
        let decoded = defaults.data(forKey: key).flatMap {
            try? JSONDecoder().decode([WordEntry].self, from: $0)
        } ?? []
        var seen = Set<String>()
        words = decoded.filter { seen.insert($0.id).inserted }
    }

    func contains(_ word: WordEntry) -> Bool {
        words.contains { $0.id == word.id }
    }

    func save(_ word: WordEntry) {
        guard !contains(word) else { return }
        persist([word] + words)
    }

    func remove(_ word: WordEntry) {
        remove(ids: [word.id])
    }

    func remove(ids: Set<String>) {
        persist(words.filter { !ids.contains($0.id) })
    }

    func toggle(_ word: WordEntry) {
        if contains(word) { remove(word) } else { save(word) }
    }

    private func persist(_ updated: [WordEntry]) {
        guard let data = try? JSONEncoder().encode(updated) else { return }
        defaults.set(data, forKey: key)
        words = updated
    }
}
