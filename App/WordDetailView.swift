import SwiftUI

struct WordDetailView: View {
    let word: WordEntry
    @ObservedObject var speech: WordSpeech
    @ObservedObject var savedWords: SavedWordsStore
    @State private var showingDataLicenses = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("ОДНО СЛОВО. КАЖДЫЙ ДЕНЬ.")
                        .font(.caption2.monospaced()).tracking(2)
                        .foregroundStyle(.secondary)
                    Text(word.word)
                        .font(EditorialStyle.headline(56))
                        .minimumScaleFactor(0.5).lineLimit(1)
                        .accessibilityAddTraits(.isHeader)
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(word.partOfSpeech).font(EditorialStyle.serif(19)).italic()
                        if let register = word.registerLabel {
                            Text(register).font(.caption.monospaced())
                        }
                    }.foregroundStyle(EditorialStyle.blue)
                    Button {
                        speech.speak(word.word)
                    } label: {
                        HStack(spacing: 10) {
                            Text(word.phonetic).font(.subheadline)
                            Image(systemName: "speaker.wave.2")
                        }
                        .padding(.vertical, 10).padding(.horizontal, 14)
                        .overlay(Capsule().strokeBorder(EditorialStyle.blue.opacity(0.35)))
                    }
                    .buttonStyle(.plain).foregroundStyle(EditorialStyle.blue)
                    .accessibilityLabel("Произнести \(word.word) по-английски")
                    .accessibilityHint("Системный синтез речи, голос English US")
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text(": " + word.definition)
                        .font(EditorialStyle.serif(25)).lineSpacing(5)
                        .environment(\.locale, Locale(identifier: "en_US"))
                    Text(word.translation)
                        .font(.title3).foregroundStyle(EditorialStyle.blue)
                    Text(word.explanation)
                        .font(.body).foregroundStyle(.secondary).lineSpacing(5)
                }

                Divider()
                VStack(alignment: .leading, spacing: 22) {
                    sectionLabel("В КОНТЕКСТЕ")
                    ForEach(word.examples, id: \.self) { example in
                        HStack(alignment: .top, spacing: 16) {
                            Rectangle().fill(EditorialStyle.blue.opacity(0.3)).frame(width: 2)
                            VStack(alignment: .leading, spacing: 10) {
                                Text(example.english)
                                    .font(EditorialStyle.serif(21)).lineSpacing(5)
                                    .environment(\.locale, Locale(identifier: "en_US"))
                                Text(example.russian)
                                    .font(.subheadline).foregroundStyle(.secondary).lineSpacing(4)
                                if let source = example.sourceURL {
                                    HStack(spacing: 12) {
                                        Text("Tatoeba · CC BY 2.0 FR")
                                        Link("EN", destination: source)
                                        if let translationSource = example.translationSourceURL {
                                            Link("RU", destination: translationSource)
                                        }
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .accessibilityElement(children: .contain)
                                }
                            }
                        }.fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    sectionLabel("КАК ИСПОЛЬЗОВАТЬ")
                    Text(word.usage).font(.body).lineSpacing(5)
                }
                if !word.synonyms.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("БЛИЗКИЕ ПО СМЫСЛУ")
                        Text(word.synonyms.joined(separator: "  ·  "))
                            .font(EditorialStyle.serif(19)).italic()
                            .foregroundStyle(EditorialStyle.blue)
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    if let source = word.source, let sourceURL = word.sourceURL {
                        Link(source, destination: sourceURL)
                    }
                    Text("Произношение: синтез речи iOS")
                    Button("Источники и лицензии") { showingDataLicenses = true }
                }
                .font(.caption).foregroundStyle(.secondary).padding(.top, 8)
            }
            .frame(maxWidth: 540, alignment: .leading)
            .padding(.horizontal, 28).padding(.top, 30).padding(.bottom, 36)
            .frame(maxWidth: .infinity)
        }
        .background(EditorialStyle.paper)
        .textSelection(.enabled)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SaveWordButton(word: word, savedWords: savedWords)
            }
        }
        .onDisappear { speech.stop() }
        .sheet(isPresented: $showingDataLicenses) { DataLicensesView() }
        .id(word.id)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title).font(.caption2.monospaced()).tracking(2)
            .foregroundStyle(.secondary).accessibilityAddTraits(.isHeader)
    }
}

private struct DataLicensesView: View {
    @Environment(\.dismiss) private var dismiss
    private var licenseText: String {
        guard let url = Bundle.main.url(forResource: "DataLicenses", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "Источники: Open English Wordnet (CC BY 4.0), Tatoeba (CC BY 2.0 FR), ipa-dict (MIT)."
        }
        return text
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(licenseText).font(.footnote).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(24)
            }
            .background(EditorialStyle.paper)
            .navigationTitle("Источники").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }.tint(EditorialStyle.blue)
    }
}
