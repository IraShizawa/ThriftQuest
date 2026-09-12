import SwiftUI

struct BossDetailView: View {
    @EnvironmentObject private var store: GameStore
    let boss: Boss
    private var current: Boss { store.boss(for: boss.id) ?? boss }
    private var history: [AttackResult] {
        store.attackResults.filter { $0.allocations.contains { $0.bossID == boss.id && $0.amount > 0 } }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 12) {
                    BossImageView(boss: current, size: 235)
                    Text(current.name).font(QuestStyle.heading(22))
                    if current.isDefeated { Text("ボス撃破！").foregroundStyle(QuestStyle.gold).font(.headline) }
                }.frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 8) {
                    Text("残りHP").font(.caption)
                    Text("\(QuestStyle.number(current.remainingHP)) / \(QuestStyle.number(current.targetAmount))")
                        .font(.title3).monospacedDigit()
                    QuestHPBar(boss: current)
                }.padding(18).questPanel()
                QuestSectionHeading(title: "攻略の記録", subtitle: "BATTLE HISTORY")
                VStack(spacing: 0) {
                    if history.isEmpty {
                        Text("まだ攻撃していません").foregroundStyle(.secondary).padding(20)
                    }
                    ForEach(history) { attack in
                        HStack {
                            Text(QuestStyle.dateText(attack.createdAt))
                            Spacer()
                            Text("- " + QuestStyle.number(attack.allocations.filter { $0.bossID == boss.id }.reduce(0) { $0 + $1.amount }) + " DAMAGE")
                                .monospacedDigit()
                        }.font(.caption).padding(16)
                        if attack.id != history.last?.id { Divider().padding(.horizontal) }
                    }
                }.questPanel()
            }.padding(28)
        }.background(QuestBackdrop())
            .navigationTitle("ボスの詳細").navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
    }
}
