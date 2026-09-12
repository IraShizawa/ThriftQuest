import SwiftUI

struct BossLibraryView: View {
    @EnvironmentObject private var store: GameStore
    @State private var filter = 0
    private var filteredBosses: [Boss] {
        store.bosses.filter { filter == 0 || (filter == 1 ? !$0.isDefeated : $0.isDefeated) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    HStack {
                        ForEach(Array(["すべて", "攻略中", "撃破済"].enumerated()), id: \.offset) { index, title in
                            Button { filter = index } label: {
                                Text(title).font(.subheadline)
                                    .frame(maxWidth: .infinity).padding(.vertical, 7)
                                    .foregroundStyle(filter == index ? .black : .white)
                                    .background(filter == index ? QuestStyle.gold : QuestStyle.panel, in: Capsule())
                                    .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 0.6))
                            }.buttonStyle(.plain)
                        }
                    }
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 30) {
                        ForEach(filteredBosses) { boss in
                            NavigationLink {
                                BossDetailView(boss: boss)
                            } label: {
                                VStack(spacing: 10) {
                                    GeometryReader { proxy in
                                        BossImageView(boss: boss, size: proxy.size.width)
                                    }.aspectRatio(1, contentMode: .fit)
                                    Text(boss.name).font(QuestStyle.heading(16)).lineLimit(2)
                                    if boss.isDefeated {
                                        Text("撃破済").font(.caption2.bold()).foregroundStyle(QuestStyle.gold)
                                    }
                                }.foregroundStyle(.white)
                            }.buttonStyle(.plain)
                        }
                    }
                    if filteredBosses.isEmpty {
                        ContentUnavailableView("まだボスがいません", systemImage: "book")
                    }
                }.padding(24)
            }
            .background(QuestBackdrop())
            .navigationTitle("BOSS図鑑").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(QuestStyle.background, for: .navigationBar)
        }
    }
}
