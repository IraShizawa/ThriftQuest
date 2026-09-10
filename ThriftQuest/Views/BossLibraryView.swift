import SwiftUI

struct BossLibraryView: View {
    @EnvironmentObject private var store: GameStore

    private var defeatedBosses: [Boss] {
        store.bosses.filter(\.isDefeated)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("挑戦中") {
                    if store.activeBosses.isEmpty {
                        Text("挑戦中のボスはいません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.activeBosses) { boss in
                            NavigationLink {
                                BossDetailView(boss: boss)
                            } label: {
                                libraryRow(for: boss)
                            }
                        }
                    }
                }

                Section("撃破済み") {
                    if defeatedBosses.isEmpty {
                        Text("まだ撃破済みのボスはいません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(defeatedBosses) { boss in
                            NavigationLink {
                                BossDetailView(boss: boss)
                            } label: {
                                libraryRow(for: boss)
                            }
                        }
                    }
                }
            }
            .navigationTitle("ボス図鑑")
        }
    }

    private func libraryRow(for boss: Boss) -> some View {
        HStack(spacing: 12) {
            BossImageView(boss: boss, size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(boss.name)
                    .fontWeight(.semibold)
                Text(boss.isDefeated ? "撃破済み" : "残りHP \(Formatters.yenText(boss.remainingHP))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(boss.progress * 100))%")
                .font(.caption.bold())
        }
    }
}
