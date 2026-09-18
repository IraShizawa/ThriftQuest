import WidgetKit
import SwiftUI

struct WidgetBoss: Codable, Identifiable {
    let id: UUID
    let name: String
    let targetAmount: Int
    let savedAmount: Int

    var remaining: Int { max(targetAmount - savedAmount, 0) }
    var remainingFraction: Double {
        targetAmount > 0 ? min(max(Double(remaining) / Double(targetAmount), 0), 1) : 0
    }
}

struct WidgetFund: Codable { let amount: Int }
struct WidgetAllocation: Codable { let amount: Int }
struct WidgetAttack: Codable {
    let fund: WidgetFund
    let allocations: [WidgetAllocation]
}
struct WidgetState: Codable {
    let bosses: [WidgetBoss]
    let attackResults: [WidgetAttack]

    var availablePower: Int {
        let earned = attackResults.reduce(0) { $0 + $1.fund.amount }
        let used = attackResults.reduce(0) { $0 + $1.allocations.reduce(0) { $0 + $1.amount } }
        return max(earned - used, 0)
    }
}

struct Entry: TimelineEntry {
    let date: Date
    let power: Int
    let bosses: [WidgetBoss]
    var hasDefeatedBosses = false
    var isUnavailable = false

    static let preview = Entry(date: .now, power: 12800, bosses: [
        WidgetBoss(id: UUID(), name: "スニーカードラゴン", targetAmount: 30000, savedAmount: 18000),
        WidgetBoss(id: UUID(), name: "夏のライブ", targetAmount: 15000, savedAmount: 12000)
    ])
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { .preview }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(context.isPreview ? .preview : load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        completion(Timeline(entries: [load()], policy: .after(.now.addingTimeInterval(900))))
    }

    private func load() -> Entry {
        let defaults = UserDefaults(suiteName: "group.app.shizawa.ira.ThriftQuestShared")
        guard let data = defaults?.data(forKey: "savings-rpg-game-state-v1"),
              let state = try? JSONDecoder().decode(WidgetState.self, from: data) else {
            return Entry(date: .now, power: 0, bosses: [], isUnavailable: true)
        }
        return Entry(date: .now, power: state.availablePower,
                     bosses: Array(state.bosses.filter { $0.remaining > 0 }.prefix(2)),
                     hasDefeatedBosses: state.bosses.contains { $0.remaining == 0 })
    }
}

private enum WidgetPalette {
    static let gold = Color(red: 0.98, green: 0.85, blue: 0.49)
    static let ink = Color(red: 0.035, green: 0.055, blue: 0.095)
    static let text = Color(red: 0.96, green: 0.94, blue: 0.87)
    static let muted = Color(red: 0.67, green: 0.73, blue: 0.80)
    static let hp = Color(red: 1, green: 0.48, blue: 0.50)
}

struct WidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode
    let entry: Entry

    private var primary: Color { renderingMode == .fullColor ? WidgetPalette.text : .primary }
    private var secondary: Color { renderingMode == .fullColor ? WidgetPalette.muted : .secondary }
    private var accent: Color { renderingMode == .fullColor ? WidgetPalette.gold : .primary }

    var body: some View {
        Group {
            if family == .systemSmall {
                compactLayout
            } else {
                wideLayout
            }
        }
        .foregroundStyle(primary)
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color(red: 0.09, green: 0.14, blue: 0.20), WidgetPalette.ink],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(alignment: .topTrailing) {
                Circle().stroke(WidgetPalette.gold.opacity(0.08), lineWidth: 22)
                    .frame(width: 130, height: 130).offset(x: 45, y: -75)
            }
        }
    }

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            powerHeader
            powerAmount(size: 30)
            Rectangle().fill(accent.opacity(0.2)).frame(height: 1)
            if let boss = entry.bosses.first {
                bossRow(boss, compact: true)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var wideLayout: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                powerHeader
                powerAmount(size: 34)
                Spacer(minLength: 0)
                Label("冒険をつづける", systemImage: "arrow.up.right")
                    .font(.system(size: 10, weight: .semibold)).foregroundStyle(accent)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(width: 116, alignment: .leading)
            Rectangle().fill(accent.opacity(0.2)).frame(width: 1)
            VStack(alignment: .leading, spacing: 10) {
                Text("挑戦中のボス").font(.system(size: 11, weight: .semibold)).foregroundStyle(secondary)
                if entry.bosses.isEmpty {
                    emptyState
                } else {
                    ForEach(entry.bosses) { boss in bossRow(boss, compact: false) }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var powerHeader: some View {
        Label("使えるPOWER", systemImage: "bolt.fill")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(accent)
            .lineLimit(1).minimumScaleFactor(0.8)
            .widgetAccentable()
    }

    private func powerAmount(size: CGFloat) -> some View {
        Text(entry.isUnavailable ? "—" : entry.power.formatted(.number))
            .font(.system(size: size, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(accent)
            .lineLimit(1).minimumScaleFactor(0.55)
            .accessibilityLabel(entry.isUnavailable ? "アプリを開いてデータを読み込んでください" : "使えるPOWER \(entry.power)")
    }

    private func bossRow(_ boss: WidgetBoss, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(boss.name).font(.system(size: compact ? 12 : 13, weight: .semibold)).lineLimit(1)
            GeometryReader { proxy in
                Capsule().fill(primary.opacity(0.12))
                    .overlay(alignment: .leading) {
                        Capsule().fill(renderingMode == .fullColor ? WidgetPalette.hp : primary)
                            .frame(width: proxy.size.width * boss.remainingFraction)
                    }
            }.frame(height: 5)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("残りHP").foregroundStyle(secondary)
                Spacer(minLength: 0)
                Text(boss.remaining.formatted(.number)).fontWeight(.semibold).monospacedDigit()
            }
            .font(.system(size: 10))
            .lineLimit(1).minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(boss.name)、残りHP \(boss.remaining)、最大HP \(boss.targetAmount)")
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.isUnavailable ? "冒険の準備をしよう" : entry.hasDefeatedBosses ? "全ボス撃破！" : "最初のボスを登録")
                .font(.system(size: 12, weight: .semibold))
            Text(entry.isUnavailable ? "アプリを開いて確認" : "タップして次の冒険へ")
                .font(.system(size: 10)).foregroundStyle(secondary)
        }
    }
}

struct ThriftQuestWidget: Widget {
    let kind = "ThriftQuestWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { WidgetView(entry: $0) }
            .configurationDisplayName("ThriftQuest")
            .description("使えるPOWERと、挑戦中のボスの残りHPを確認。")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview("小サイズ", as: .systemSmall) { ThriftQuestWidget() } timeline: { Entry.preview }
#Preview("中サイズ", as: .systemMedium) { ThriftQuestWidget() } timeline: { Entry.preview }
