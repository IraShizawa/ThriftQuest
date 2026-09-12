import SwiftUI

struct RecordsView: View {
    @EnvironmentObject private var store: GameStore
    @State private var showingAdd = false
    private var groups: [(day: Date, records: [AttackResult])] {
        let records = store.attackResults.filter { $0.fund.amount > 0 }
        let grouped = Dictionary(grouping: records) { Calendar.current.startOfDay(for: $0.fund.date) }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0]!.sorted { $0.fund.date > $1.fund.date }) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if groups.isEmpty {
                        ContentUnavailableView("まだ記録がありません", systemImage: "doc.text",
                                               description: Text("右下の⚡＋から、確保したお金を記録しよう。"))
                    }
                    ForEach(groups, id: \.day) { group in
                        VStack(alignment: .leading, spacing: 9) {
                            Text(QuestStyle.dateText(group.day) + "の記録").font(QuestStyle.heading(17))
                            VStack(spacing: 0) {
                                ForEach(group.records) { result in
                                    HStack(alignment: .top, spacing: 10) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("+ " + QuestStyle.number(result.fund.amount) + " POWER")
                                                .font(.subheadline).monospacedDigit()
                                            Text(result.fund.kind == .earned ? "稼いだPOWER" : "守ったPOWER")
                                                .font(.caption2).foregroundStyle(QuestStyle.gold)
                                        }
                                        Spacer(minLength: 8)
                                        Text(result.fund.memo.isEmpty ? "メモなし" : result.fund.memo)
                                            .font(.caption).foregroundStyle(.secondary).lineLimit(3)
                                    }.padding(14)
                                    if result.id != group.records.last?.id {
                                        Divider().padding(.horizontal, 14)
                                    }
                                }
                            }.questPanel()
                        }
                    }
                }.padding(24).padding(.bottom, 100)
            }
            .background(QuestBackdrop())
            .overlay(alignment: .bottomTrailing) {
                Button { showingAdd = true } label: {
                    VStack(spacing: 4) {
                        Text("POWER追加")
                            .font(QuestStyle.heading(12))
                            .foregroundStyle(QuestStyle.panel)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 6)
                            .background(QuestStyle.gold, in: Capsule())
                        ZStack {
                            Circle().fill(QuestStyle.panel)
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 29, weight: .bold))
                                .foregroundStyle(QuestStyle.gold)
                        }
                        .frame(width: 66, height: 66)
                        .overlay(Circle().stroke(QuestStyle.gold, lineWidth: 3))
                        .overlay(Circle().stroke(QuestStyle.gold.opacity(0.35), lineWidth: 0.7).padding(5))
                    }
                }
                .buttonStyle(.plain)
                .padding(.trailing, 22)
                .padding(.bottom, 38)
                .accessibilityLabel("POWERを追加")
            }
            .navigationTitle("記録").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(QuestStyle.background, for: .navigationBar)
            .sheet(isPresented: $showingAdd) { AddFundView(preselectedBossID: nil) }
        }
    }
}
