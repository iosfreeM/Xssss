import WidgetKit
import SwiftUI

private let contentURLString = "https://raw.githubusercontent.com/iosfreeM/MtechApp/main/content.json"

private struct WLatest: Codable {
    let title: String
    let text: String
}

private struct WContent: Codable {
    let latest: WLatest?
}

struct MtechEntry: TimelineEntry {
    let date: Date
    let title: String
    let text: String
}

struct MtechProvider: TimelineProvider {
    func placeholder(in context: Context) -> MtechEntry {
        MtechEntry(date: Date(), title: "Mtech", text: "Последний тутор или новость")
    }

    func getSnapshot(in context: Context, completion: @escaping (MtechEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MtechEntry>) -> Void) {
        let next = Date().addingTimeInterval(3600)
        guard let url = URL(string: contentURLString) else {
            completion(Timeline(entries: [placeholder(in: context)], policy: .after(next)))
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            var title = "Mtech"
            var text = "Открой приложение, чтобы посмотреть туторы."
            if let data = data,
               let content = try? JSONDecoder().decode(WContent.self, from: data),
               let latest = content.latest {
                title = latest.title
                text = latest.text
            }
            let entry = MtechEntry(date: Date(), title: title, text: text)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }.resume()
    }
}

extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(Color.black, for: .widget)
        } else {
            self.background(Color.black)
        }
    }
}

struct MtechWidgetView: View {
    let entry: MtechEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MTECH")
                .font(.caption2.bold())
                .foregroundColor(.green)
            Text(entry.title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)
            Text(entry.text)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(4)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .widgetBackground()
    }
}

@main
struct MtechInfoWidget: Widget {
    let kind = "MtechInfoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MtechProvider()) { entry in
            MtechWidgetView(entry: entry)
        }
        .configurationDisplayName("Mtech")
        .description("Последний тутор или новость.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
