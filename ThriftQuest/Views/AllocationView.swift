import SwiftUI

struct AllocationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var store: GameStore
    let kind: AttackFundKind
    let amount: Int
    let memo: String
    let preselectedBossID: UUID?
    var usesExistingPower: Bool = false
    var onFinish: () -> Void = {}
    @State private var allocationTexts: [UUID: String] = [:]
    @State private var result: AttackResult?
    @State private var showingResult = false
    @State private var striking = false
    @State private var error: String?
    @FocusState private var focusedBoss: UUID?

    private var power: Int { usesExistingPower ? store.availablePower : amount }
    private var total: Int { allocationTexts.values.reduce(0) { $0 + (Int($1) ?? 0) } }
    private var valid: Bool {
        total > 0 && total <= power && store.activeBosses.allSatisfy {
            (Int(allocationTexts[$0.id] ?? "") ?? 0) <= $0.remainingHP
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text("使用できる攻撃力").font(.subheadline)
                    Spacer()
                    Image(systemName: "bolt.fill").foregroundStyle(.yellow)
                    Text(QuestStyle.number(power)).foregroundStyle(QuestStyle.gold).monospacedDigit()
                }.padding(14).background(QuestStyle.field, in: RoundedRectangle(cornerRadius: 14))
                ForEach(store.activeBosses) { boss in
                    HStack(spacing: 12) {
                        BossImageView(boss: boss, size: 74)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(boss.name).lineLimit(1)
                            Text("残りHP").font(.caption)
                            Text(QuestStyle.number(boss.remainingHP)).font(.caption).monospacedDigit()
                        }
                        Spacer(minLength: 0)
                        TextField("0000", text: binding(boss.id))
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                            .foregroundStyle(QuestStyle.gold).monospacedDigit()
                            .frame(width: 85).padding(.trailing, 12)
                            .focused($focusedBoss, equals: boss.id)
                            .accessibilityLabel(boss.name + "への使用POWER")
                    }.questPanel()
                }
                HStack {
                    Text("使用後のPOWER")
                    Spacer()
                    Text(QuestStyle.number(power - total)).monospacedDigit()
                }.font(.caption).foregroundStyle(.secondary)
                if total > power {
                    Text("使えるPOWERを超えています。").font(.caption).foregroundStyle(QuestStyle.hp)
                } else if !valid && total > 0 {
                    Text("残りHPを超える攻撃はできません。").font(.caption).foregroundStyle(QuestStyle.hp)
                }
                if let error { Text(error).foregroundStyle(QuestStyle.hp) }
            }.padding(24)
        }
        .background(QuestBackdrop())
        .safeAreaInset(edge: .bottom) {
            Button(action: attack) {
                HStack {
                    QuestSword().frame(width: 30, height: 30)
                    Text("攻撃する！")
                }
            }.buttonStyle(QuestButtonStyle(color: QuestStyle.attack))
                .disabled(!valid || result != nil).opacity(valid ? 1 : 0.5)
                .padding(24).background(QuestStyle.background)
        }
        .overlay {
            if striking {
                ZStack {
                    QuestStyle.background.opacity(0.9).ignoresSafeArea()
                    VStack(spacing: 20) {
                        QuestSword().frame(width: 110, height: 110).foregroundStyle(QuestStyle.gold)
                        Text("ATTACK!").font(.largeTitle.bold()).foregroundStyle(QuestStyle.gold)
                    }
                }.allowsHitTesting(false)
            }
        }
        .navigationTitle("作戦を立てる").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("完了") { focusedBoss = nil } }
        }
        .onAppear {
            if allocationTexts.isEmpty, let id = preselectedBossID, let boss = store.boss(for: id) {
                allocationTexts[id] = String(min(power, boss.remainingHP))
            }
        }
        .navigationDestination(isPresented: $showingResult) {
            if let result { AttackResultView(result: result, onFinish: onFinish) }
        }
    }

    private func binding(_ id: UUID) -> Binding<String> {
        Binding(get: { allocationTexts[id, default: ""] }, set: {
            allocationTexts[id] = String($0.filter { $0.isASCII && $0.isNumber }.prefix(7))
        })
    }

    private func attack() {
        guard valid, result == nil else { return }
        focusedBoss = nil
        let allocations = store.activeBosses.compactMap { boss -> BossAllocation? in
            let value = Int(allocationTexts[boss.id] ?? "") ?? 0
            return value > 0 ? BossAllocation(bossID: boss.id, amount: value) : nil
        }
        result = usesExistingPower
            ? store.applyExistingPower(amount: power, allocations: allocations)
            : store.applyAttackFund(kind: kind, amount: amount, memo: memo, allocations: allocations)
        guard result != nil else { error = "POWERが変更されました。入力を確認してください。"; return }
        striking = !reduceMotion
        Task { @MainActor in
            if !reduceMotion { try? await Task.sleep(for: .milliseconds(650)) }
            striking = false
            showingResult = true
        }
    }
}
