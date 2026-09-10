import SwiftUI

struct RecordsView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label("未使用POWER", systemImage: "bolt.fill")
                        Spacer()
                        Text(Formatters.yenText(store.availablePower))
                            .font(.headline)
                    }
                }
                if store.attackResults.isEmpty {
                    ContentUnavailableView("まだ記録がありません", systemImage: "list.bullet.rectangle")
                } else {
                    ForEach(store.attackResults) { result in
                        Section {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Label(result.fund.kind.title, systemImage: result.fund.kind == .earned ? "briefcase.fill" : "hand.raised.fill")
                                        .font(.headline)
                                    Spacer()
                                    Text("+\(Formatters.yenText(result.totalDamage))")
                                        .font(.headline)
                                        .foregroundStyle(.mint)
                                }

                                if !result.fund.memo.isEmpty {
                                    Text(result.fund.memo)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                ForEach(result.allocations) { allocation in
                                    HStack {
                                        Text(store.bossName(for: allocation.bossID))
                                        Spacer()
                                        Text("\(Formatters.yenText(allocation.amount)) DAMAGE")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        } header: {
                            Text(result.createdAt, style: .date)
                        }
                    }
                }
            }
            .navigationTitle("記録")
        }
    }
}
