import SwiftUI

struct SaveWordButton: View {
    let word: WordEntry
    @ObservedObject var savedWords: SavedWordsStore
    private var isSaved: Bool { savedWords.contains(word) }

    var body: some View {
        Button {
            savedWords.toggle(word)
        } label: {
            Label(isSaved ? "Удалить из моего словаря" : "Сохранить в свой словарь",
                  systemImage: isSaved ? "bookmark.fill" : "bookmark")
                .symbolEffect(.bounce, value: isSaved)
        }
        .accessibilityValue(isSaved ? "Сохранено" : "Не сохранено")
    }
}

struct WeekWordsView: View {
    let catalogue: WordCatalogue
    @ObservedObject var savedWords: SavedWordsStore
    @ObservedObject var speech: WordSpeech

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                let week = catalogue.recentWeek(endingOn: context.date)
                List {
                    Section {
                        ForEach(week) { day in
                            NavigationLink(value: day.word) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(day.date.formatted(.dateTime.weekday(.wide)
                                            .locale(Locale(identifier: "ru_RU"))))
                                            .textCase(.uppercase)
                                        Spacer()
                                        Text(day.date, format: .dateTime.day().month(.abbreviated)
                                            .locale(Locale(identifier: "ru_RU")))
                                    }
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    WordLibraryRow(word: day.word, isSaved: savedWords.contains(day.word))
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    } header: {
                        if !week.isEmpty {
                            Text("Опубликованные слова за последние семь дней")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(EditorialStyle.paper)
                .overlay {
                    if week.isEmpty {
                        ContentUnavailableView("Нет слов за эту неделю", systemImage: "calendar",
                            description: Text("За последние семь дней в подборке не было новых слов."))
                    }
                }
            }
            .navigationTitle("Последняя неделя")
            .navigationDestination(for: WordEntry.self) { word in
                WordDetailView(word: word, speech: speech, savedWords: savedWords)
                    .navigationTitle(word.word)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct SavedWordsView: View {
    @ObservedObject var savedWords: SavedWordsStore
    @ObservedObject var speech: WordSpeech

    var body: some View {
        NavigationStack {
            Group {
                if savedWords.words.isEmpty {
                    ContentUnavailableView("Пока нет сохранённых слов", systemImage: "bookmark",
                        description: Text("Открой слово дня или слово из истории и нажми на закладку справа вверху."))
                } else {
                    List {
                        ForEach(savedWords.words) { word in
                            NavigationLink(value: word) {
                                WordLibraryRow(word: word, isSaved: true)
                                    .padding(.vertical, 6)
                            }
                        }
                        .onDelete { offsets in
                            let ids = Set(offsets.map { savedWords.words[$0].id })
                            savedWords.remove(ids: ids)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(EditorialStyle.paper)
            .navigationTitle("Мой словарь")
            .navigationDestination(for: WordEntry.self) { word in
                WordDetailView(word: word, speech: speech, savedWords: savedWords)
                    .navigationTitle(word.word)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

private struct WordLibraryRow: View {
    let word: WordEntry
    let isSaved: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(word.word).font(EditorialStyle.serif(24))
                    .foregroundStyle(EditorialStyle.ink)
                if let register = word.registerLabel {
                    Text(register).font(.caption).foregroundStyle(EditorialStyle.blue)
                }
                Spacer(minLength: 0)
                if isSaved {
                    Image(systemName: "bookmark.fill")
                        .font(.caption).foregroundStyle(EditorialStyle.blue)
                        .accessibilityLabel("В моём словаре")
                }
            }
            Text(word.translation).font(.subheadline).foregroundStyle(.secondary)
        }
    }
}
