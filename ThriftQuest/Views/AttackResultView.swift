import SwiftUI

struct AttackResultView: View {
    @EnvironmentObject private var store: GameStore
    let result: AttackResult
    var onFinish: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(result.allocations) { allocation in
                    HStack(spacing: 14) {
                        BossImageView(boss: store.boss(for: allocation.bossID), size: 80)
                        VStack(alignment: .leading, spacing: 7) {
                            Text(store.bossName(for: allocation.bossID)).font(.subheadline)
                            Text(QuestStyle.number(allocation.amount) + " DAMAGE")
                                .font(.headline).foregroundStyle(QuestStyle.gold).monospacedDigit()
                            if let boss = store.boss(for: allocation.bossID) {
                                Text(boss.isDefeated ? "ボス撃破！" : "残りHP " + QuestStyle.number(boss.remainingHP))
                                    .font(.caption).foregroundStyle(boss.isDefeated ? QuestStyle.gold : .secondary)
                            }
                        }
                        Spacer(minLength: 0)
                    }.padding(10).questPanel()
                }
            }.padding(24)
        }
        .background(QuestBackdrop())
        .safeAreaInset(edge: .bottom) {
            Button("ホームに戻る", action: onFinish)
                .buttonStyle(QuestButtonStyle()).padding(24).background(QuestStyle.background)
        }
        .navigationTitle("BATTLE RESULT").navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
    }
}
