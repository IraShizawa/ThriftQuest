import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: GameStore
    @State private var selectedBossID: UUID?
    @State private var isShowingAddFund = false
    @State private var isShowingShareDraft = false
    @State private var isShowingAddBoss = false
    @State private var isShowingCameraBoss = false
    @State private var isShowingAttack = false
    @State private var selectedDraftID: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Button {
                        isShowingAttack = true
                    } label: {
                        HStack {
                            Label("使えるPOWER", systemImage: "bolt.fill")
                            Spacer()
                            Text(Formatters.yenText(store.availablePower))
                                .font(.title2.bold())
                            Image(systemName: "sword")
                        }
                        .padding()
                        .foregroundStyle(.white)
                        .background(store.availablePower > 0 ? Color.orange : Color.gray,
                                    in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .disabled(store.availablePower == 0 || store.activeBosses.isEmpty)

                    Button {
                        isShowingAttack = store.availablePower > 0
                        if store.availablePower == 0 {
                            isShowingAddFund = true
                        }
                    } label: {
                        StatTileView(
                            title: "使えるPOWER",
                            value: Formatters.yenText(store.availablePower),
                            systemImage: "bolt.fill"
                        )
                    }
                    .buttonStyle(.plain)

                    HStack {
                        Text("挑戦中のボス")
                            .font(.headline)
                        Spacer()
                        Button {
                            isShowingAddBoss = true
                        } label: {
                            Label("ボス追加", systemImage: "plus")
                        }
                        .buttonStyle(.bordered)
                    }

                    if !store.pendingDrafts.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("共有・カメラの下書き")
                                .font(.headline)
                            ForEach(store.pendingDrafts) { draft in
                                Button {
                                    selectedDraftID = draft.id
                                    isShowingShareDraft = true
                                } label: {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                        VStack(alignment: .leading) {
                                            Text(draft.title.isEmpty ? "共有された商品" : draft.title)
                                                .fontWeight(.semibold)
                                            Text(draft.price.map(Formatters.yenText) ?? "金額未入力")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding()
                                    .background(.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    ForEach(store.activeBosses) { boss in
                        BossCardView(boss: boss) {
                            selectedBossID = boss.id
                            isShowingAddFund = true
                        }
                        .onTapGesture {
                            selectedBossID = boss.id
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("貯金RPG")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingCameraBoss = true
                    } label: {
                        Image(systemName: "camera")
                    }
                    .accessibilityLabel("カメラで登録")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectedDraftID = store.pendingDrafts.first?.id
                        isShowingShareDraft = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .accessibilityLabel("共有から追加")
                }
            }
            .navigationDestination(item: $selectedBossID) { bossID in
                if let boss = store.boss(for: bossID) {
                    BossDetailView(boss: boss)
                }
            }
            .sheet(isPresented: $isShowingAddFund) {
                AddFundView(preselectedBossID: selectedBossID)
            }
            .sheet(isPresented: $isShowingShareDraft) {
                ShareDraftView(initialDraftID: selectedDraftID)
            }
            .sheet(isPresented: $isShowingAddBoss) {
                AddBossView()
            }
            .sheet(isPresented: $isShowingCameraBoss) {
                CameraBossView()
            }
            .sheet(isPresented: $isShowingAttack) {
                NavigationStack {
                    AllocationView(kind: .earned,
                                   amount: store.availablePower,
                                   memo: "記録済みPOWERから攻撃",
                                   preselectedBossID: nil,
                                   usesExistingPower: true,
                                   onFinish: { isShowingAttack = false })
                }
            }
            .onAppear {
                store.importSharedDrafts()
            }
        }
    }
}
