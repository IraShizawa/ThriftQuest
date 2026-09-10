import SwiftUI

struct BossDetailView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var liveActivityManager: LiveActivityManager
    let boss: Boss

    private var currentBoss: Boss {
        store.boss(for: boss.id) ?? boss
    }

    private var latestAllocations: [AttackResult] {
        store.attackResults.filter { result in
            result.allocations.contains { $0.bossID == boss.id }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BossImageView(boss: boss, size: 180)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 6) {
                    Text(boss.name)
                        .font(.largeTitle.bold())
                    Text(boss.category)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    ProgressBarsView(boss: currentBoss)
                }
                .padding()
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(spacing: 10) {
                    Button {
                        Task {
                            await liveActivityManager.start(for: currentBoss)
                        }
                    } label: {
                        Label("Live Activityで表示", systemImage: "dot.radiowaves.left.and.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        Task {
                            await liveActivityManager.endAll()
                        }
                    } label: {
                        Label("Live Activityを終了", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("攻略履歴")
                        .font(.headline)

                    if latestAllocations.isEmpty {
                        ContentUnavailableView("まだ攻撃履歴がありません", systemImage: "clock")
                    } else {
                        ForEach(latestAllocations) { result in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(result.fund.memo.isEmpty ? result.fund.kind.title : result.fund.memo)
                                        .font(.subheadline)
                                    Text(result.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("+\(Formatters.yenText(damage(in: result)))")
                                    .fontWeight(.semibold)
                            }
                            Divider()
                        }
                    }
                }
                .padding()
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("ボス詳細")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func damage(in result: AttackResult) -> Int {
        result.allocations
            .filter { $0.bossID == boss.id }
            .reduce(0) { $0 + $1.amount }
    }
}
