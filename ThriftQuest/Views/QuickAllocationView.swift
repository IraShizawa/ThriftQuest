import SwiftUI

struct QuickAllocationView: View {
    @EnvironmentObject private var store: GameStore
    @State private var isShowingAddFund = false

    private var totalRemainingHP: Int {
        store.activeBosses.reduce(0) { $0 + $1.remainingHP }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    StatTileView(
                        title: "攻略待ちのHP",
                        value: Formatters.yenText(totalRemainingHP),
                        systemImage: "heart.text.square.fill"
                    )

                    Button {
                        isShowingAddFund = true
                    } label: {
                        Label("攻略資金を追加して分配", systemImage: "bolt.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    Text("分配先")
                        .font(.headline)

                    ForEach(store.activeBosses) { boss in
                        HStack(spacing: 12) {
                            BossImageView(boss: boss, size: 52)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(boss.name)
                                    .fontWeight(.semibold)
                                ProgressView(value: boss.progress)
                                    .tint(.mint)
                                Text("残りHP \(Formatters.yenText(boss.remainingHP))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("分配")
            .sheet(isPresented: $isShowingAddFund) {
                AddFundView(preselectedBossID: nil)
            }
        }
    }
}
