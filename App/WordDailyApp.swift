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

private enum LibraryTab: Hashable { case today, week, dictionary }

struct DailyWordScreen: View {
    let catalogue: WordCatalogue
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = LibraryTab.today
    @State private var openedWordID: String?
    @State private var showingWidgetHelp = false
    @StateObject private var speech = WordSpeech()
    @StateObject private var savedWords = SavedWordsStore()

    var body: some View {
        TabView(selection: $selectedTab) {
            todayScreen
                .tabItem { Label("Сегодня", systemImage: "sun.max") }
                .tag(LibraryTab.today)

            WeekWordsView(catalogue: catalogue, savedWords: savedWords, speech: speech)
                .tabItem { Label("Неделя", systemImage: "calendar") }
                .tag(LibraryTab.week)

            SavedWordsView(savedWords: savedWords, speech: speech)
                .tabItem { Label("Мой словарь", systemImage: "bookmark") }
                .tag(LibraryTab.dictionary)
        }
        .tint(EditorialStyle.blue)
        .onOpenURL { url in
            if let id = WordLink.wordID(from: url, catalogue: catalogue) {
                speech.stop()
                showingWidgetHelp = false
                openedWordID = id
                selectedTab = .today
            }
        }
        .onChange(of: selectedTab) { _, _ in speech.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                WidgetCenter.shared.reloadAllTimelines()
            } else {
                speech.stop()
            }
        }
        .sheet(isPresented: $showingWidgetHelp) { WidgetHelpView() }
    }

    private var todayScreen: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                let today = catalogue.word(on: context.date)
                let word = openedWordID.flatMap { catalogue[$0] } ?? today
                WordDetailView(word: word, speech: speech, savedWords: savedWords)
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
                                showingWidgetHelp = true
                            } label: {
                                Label("Добавить виджет", systemImage: "square.grid.2x2")
                            }
                        }
                    }
            }
        }
    }
}
