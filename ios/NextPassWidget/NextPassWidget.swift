// Metro Widget IDF - widget iOS (WidgetKit) alimenté par home_widget via App Group
// Créé par : Omar Pérez - 2026-11-09 08:10
import SwiftUI
import WidgetKit

private let appGroup = "group.com.omarperez.metrowidget"
private let navy = Color(red: 0.043, green: 0.078, blue: 0.259)
private let navyRow = Color(red: 0.086, green: 0.125, blue: 0.353)
private let amber = Color(red: 1.0, green: 0.78, blue: 0.17)

struct Row: Decodable, Hashable {
    let line: String
    let mode: String
    let bg: String
    let fg: String
    let dest: String
    let stop: String
    let t: [Int64]
}

struct BoardData: Decodable {
    let station: String
    let dist: Int
    let updated: Int64
    let rows: [Row]
    let error: String?
}

struct PassEntry: TimelineEntry {
    let date: Date
    let board: BoardData?
}

struct Provider: TimelineProvider {
    func load() -> BoardData? {
        guard let s = UserDefaults(suiteName: appGroup)?.string(forKey: "board_json"),
              let d = s.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(BoardData.self, from: d)
    }

    func placeholder(in context: Context) -> PassEntry { PassEntry(date: Date(), board: nil) }

    func getSnapshot(in context: Context, completion: @escaping (PassEntry) -> Void) {
        completion(PassEntry(date: Date(), board: load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PassEntry>) -> Void) {
        let b = load()
        let now = Date()
        let entries = (0..<15).map { i in
            PassEntry(date: now.addingTimeInterval(Double(i) * 60), board: b)
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(15 * 60))))
    }
}

extension Color {
    init(hex: String) {
        var v: UInt64 = 0x5A5A5A
        Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&v)
        self.init(
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }
}

struct NextPassView: View {
    let entry: PassEntry
    @Environment(\.widgetFamily) var family

    func minutes(_ t: Int64) -> String {
        let m = Int((Double(t) / 1000 - entry.date.timeIntervalSince1970) / 60)
        return m <= 0 ? "0" : "\(m)'"
    }

    var body: some View {
        VStack(spacing: 3) {
            HStack {
                Text(entry.board?.station ?? "Prochains passages")
                    .font(.system(size: 14, weight: .heavy)).lineLimit(1)
                Spacer()
                if let u = entry.board?.updated {
                    Text(Date(timeIntervalSince1970: Double(u) / 1000), style: .time)
                        .font(.system(size: 10))
                }
            }
            .foregroundColor(navy)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(Color.white)

            if let b = entry.board, !b.rows.isEmpty {
                ForEach(b.rows.prefix(family == .systemLarge ? 6 : 3), id: \.self) { r in
                    HStack(spacing: 6) {
                        Text(r.line)
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(Color(hex: r.fg))
                            .frame(width: 34, height: 20)
                            .background(Color(hex: r.bg))
                            .clipShape(RoundedRectangle(cornerRadius: r.mode.contains("metro") ? 10 : 3))
                        Text(r.dest).font(.system(size: 13, weight: .bold)).lineLimit(1)
                            .foregroundColor(.white)
                        Spacer(minLength: 2)
                        ForEach(0..<2, id: \.self) { i in
                            Text(i < r.t.count ? minutes(r.t[i]) : "")
                                .font(.system(size: 15, weight: .heavy).monospacedDigit())
                                .foregroundColor(amber).frame(width: 34, alignment: .trailing)
                        }
                    }
                    .padding(.horizontal, 5).padding(.vertical, 3)
                    .background(navyRow)
                }
            } else {
                Text(entry.board?.error ?? "Ouvrez l'appli une première fois")
                    .font(.system(size: 12)).foregroundColor(amber)
            }
            Spacer(minLength: 0)
        }
        .containerBackground(navy, for: .widget)
    }
}

@main
struct NextPassWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextPassWidget", provider: Provider()) { e in
            NextPassView(entry: e)
        }
        .configurationDisplayName("Prochains passages")
        .description("Deux prochains passages autour de vous")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
