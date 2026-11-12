import SwiftUI
import WidgetKit

struct DailyEntry: TimelineEntry {
    let date: Date
    let word: WordEntry?
}

struct DailyProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyEntry {
        entry(at: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyEntry) -> Void) {
        completion(entry(at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyEntry>) -> Void) {
        let dates = DailySchedule.timelineDates(from: .now)
        let catalogue = try? WordCatalogue()
        let entries = dates.map { date in
            DailyEntry(date: date, word: catalogue?.word(on: date))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(at date: Date) -> DailyEntry {
        DailyEntry(date: date, word: (try? WordCatalogue())?.word(on: date))
    }
}

struct DailyWidgetView: View {
    let entry: DailyEntry
    @Environment(\.widgetFamily) private var family
    private var isSmall: Bool { family == .systemSmall }

    var body: some View {
        Group {
            if let word = entry.word {
                VStack(alignment: .leading, spacing: isSmall ? 6 : 8) {
                    HStack {
                        Text("WORD OF THE DAY").tracking(1.5)
                        Spacer(minLength: 4)
                        if !isSmall { Text("word.") }
                    }
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    if isSmall {
                        title(word.word, size: 33)
                        Text(word.partOfSpeech)
                            .font(.custom("Georgia-Italic", size: 12))
                            .foregroundStyle(EditorialStyle.blue).widgetAccentable()
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            title(word.word, size: 40)
                            Text(word.partOfSpeech)
                                .font(.custom("Georgia-Bold", size: 18))
                                .foregroundStyle(EditorialStyle.blue).widgetAccentable()
                        }
                        Text(word.phonetic).font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    Text(": " + word.definition)
                        .font(.system(size: isSmall ? 11 : 13))
                        .lineLimit(isSmall ? 3 : 2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    if !isSmall && word.register == "slang" {
                        Text("slang").font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(EditorialStyle.blue)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .widgetURL(WordLink.url(for: word))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(word.word), \(word.partOfSpeech). \(word.definition). Открыть перевод и примеры.")
            } else {
                Text("Открой word., чтобы проверить подборку.").font(.footnote)
            }
        }
        .containerBackground(EditorialStyle.paper, for: .widget)
    }

    private func title(_ word: String, size: CGFloat) -> some View {
        Text(word).font(.custom("Georgia-Bold", size: size))
            .lineLimit(1).minimumScaleFactor(0.5)
            .foregroundStyle(EditorialStyle.ink)
    }
}

@main
struct WordDailyWidget: Widget {
    let kind = "WordDailyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyProvider()) { entry in
            DailyWidgetView(entry: entry)
        }
        .configurationDisplayName("word. — слово дня")
        .description("Английские слова и сленг. Нажми, чтобы открыть перевод и примеры.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
