import SwiftUI

struct AllocationView: View {
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var liveActivityManager: LiveActivityManager

    let kind: AttackFundKind
    let amount: Int
    let memo: String
    let preselectedBossID: UUID?
    var usesExistingPower: Bool = false
    var onFinish: () -> Void = {}

    @State private var allocationTexts: [UUID: String] = [:]
    @State private var result: AttackResult?
    @State private var isShowingResult = false

    private var totalAllocated: Int {
        allocationTexts.values
            .compactMap { Int($0.filter(\.isNumber)) }
            .reduce(0, +)
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 8) {
                    Text("今回の攻略資金")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(Formatters.yenText(amount))
                        .font(.system(size: 34, weight: .bold))
                }
                .frame(maxWidth: .infinity)
            }

            Section("どのボスを優先するか考える") {
                ForEach(store.activeBosses) { boss in
                    HStack(spacing: 12) {
                        BossImageView(boss: boss, size: 48)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(boss.name)
                                .fontWeight(.semibold)
                            ProgressView(value: boss.progress)
                                .tint(.mint)
                            Text("残りHP \(Formatters.yenText(boss.remainingHP))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        TextField("0", text: binding(for: boss.id))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 88)
                        Text("円")
                    }
                }
            }

            Section {
                HStack {
                    Text("合計")
                    Spacer()
                    Text(Formatters.yenText(totalAllocated))
                        .fontWeight(.bold)
                }

                Button {
                    attack()
                } label: {
                    Label("分配して攻撃", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(totalAllocated <= 0 || totalAllocated > amount)
            } footer: {
                if totalAllocated > amount {
                    Text("分配額が今回の攻略資金を超えています。")
                }
            }
        }
        .navigationTitle("分配")
        .onAppear(perform: applyInitialAllocation)
        .navigationDestination(isPresented: $isShowingResult) {
            if let result {
                AttackResultView(result: result, onFinish: onFinish)
            }
        }
    }

    private func binding(for bossID: UUID) -> Binding<String> {
        Binding(
            get: { allocationTexts[bossID, default: ""] },
            set: { allocationTexts[bossID] = $0 }
        )
    }

    private func applyInitialAllocation() {
        guard allocationTexts.isEmpty else { return }
        if let preselectedBossID {
            allocationTexts[preselectedBossID] = "\(amount)"
        }
    }

    private func attack() {
        let allocations = allocationTexts.map { bossID, text in
            BossAllocation(bossID: bossID, amount: Int(text.filter(\.isNumber)) ?? 0)
        }
        result = usesExistingPower
            ? store.applyExistingPower(amount: amount, allocations: allocations)
            : store.applyAttackFund(kind: kind, amount: amount, memo: memo, allocations: allocations)
        Task {
            for allocation in allocations {
                if let boss = store.boss(for: allocation.bossID) {
                    await liveActivityManager.update(with: boss)
                }
            }
        }
        isShowingResult = result != nil
    }
}
