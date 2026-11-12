import SwiftUI
import WidgetKit

@main
struct WordDailyApp: App {
    private let catalogue = try? WordCatalogue()

    var body: some Scene {
        WindowGroup {
            if let catalogue {
                DailyWordScreen(catalogue: catalogue)
            } else {
                ContentUnavailableView("Не удалось загрузить слова", systemImage: "book.closed",
                    description: Text("Проверь, что words.json добавлен в ресурсы приложения."))
            }
        }
    }
}

struct DailyWordScreen: View {
    let catalogue: WordCatalogue
    @Environment(\.scenePhase) private var scenePhase
    @State private var openedWordID: String?
    @State private var showingWidgetHelp = false
    @State private var showingCollection = false
    @StateObject private var speech = WordSpeech()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let today = catalogue.word(on: context.date)
            let word = openedWordID.flatMap { catalogue[$0] } ?? today
            NavigationStack {
                WordDetailView(word: word, speech: speech)
                    .safeAreaInset(edge: .bottom) {
                        if word.id != today.id {
                            Button("К слову дня") {
                                speech.stop()
                                openedWordID = nil
                            }
                            .buttonStyle(.borderedProminent)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(EditorialStyle.paper)
                        }
                    }
                    .navigationTitle("word.")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showingCollection = true
                            } label: {
                                Label("Подборка", systemImage: "books.vertical")
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showingWidgetHelp = true
                            } label: {
                                Label("Добавить виджет", systemImage: "square.grid.2x2")
                            }
                        }
                    }
            }
            .tint(EditorialStyle.blue)
        }
        .onOpenURL { url in
            if let id = WordLink.wordID(from: url, catalogue: catalogue) {
                speech.stop()
                showingCollection = false
                showingWidgetHelp = false
                openedWordID = id
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                WidgetCenter.shared.reloadAllTimelines()
            } else {
                speech.stop()
            }
        }
        .sheet(isPresented: $showingWidgetHelp) { WidgetHelpView() }
        .sheet(isPresented: $showingCollection) {
            NavigationStack {
                List {
                    Section {
                        ForEach(catalogue.words) { word in
                            Button {
                                speech.stop()
                                openedWordID = word.id
                                showingCollection = false
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(word.word).font(EditorialStyle.serif(24))
                                        if word.register == "slang" {
                                            Text("сленг").font(.caption).foregroundStyle(EditorialStyle.blue)
                                        }
                                    }
                                    Text(word.translation).font(.subheadline).foregroundStyle(.secondary)
                                }.padding(.vertical, 6)
                            }.foregroundStyle(EditorialStyle.ink)
                        }
                    } footer: {
                        Text("Пробная подборка: 14 слов, по одному в день. Затем цикл повторяется. Определения, примеры и переводы подготовлены для прототипа.")
                    }
                }
                .navigationTitle("Подборка")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Готово") { showingCollection = false }
                    }
                }
            }.tint(EditorialStyle.blue)
        }
    }
}
