import Foundation
import Combine

@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var bosses: [Boss]
    @Published private(set) var attackResults: [AttackResult]
    @Published private(set) var pendingDrafts: [SharedItemDraft]
    @Published var latestResult: AttackResult?

    private let persistence: PersistenceStoring

    init(persistence: PersistenceStoring = UserDefaultsPersistenceStore()) {
        self.persistence = persistence

        if let state = persistence.loadGameState() {
            bosses = state.bosses
            attackResults = state.attackResults
            pendingDrafts = state.pendingDrafts
        } else {
            bosses = Boss.sampleData
            attackResults = []
            pendingDrafts = []
        }
    }

    var activeBosses: [Boss] {
        bosses.filter { !$0.isDefeated }
    }

    /// まだボスに割り当てていないPOWER。既存データから再計算するため、
    /// アプリ更新後も表示が壊れない。
    var availablePower: Int {
        max(attackResults.reduce(0) { $0 + $1.fund.amount } -
            attackResults.reduce(0) { $0 + $1.totalDamage }, 0)
    }

    var todayAttackTotal: Int {
        let calendar = Calendar.current
        return attackResults
            .filter { calendar.isDateInToday($0.createdAt) }
            .reduce(0) { $0 + $1.totalDamage }
    }

    func addBoss(
        name: String,
        category: String,
        targetAmount: Int,
        imageData: Data? = nil,
        imageURL: URL? = nil,
        productURL: URL? = nil
    ) {
        let boss = Boss(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            targetAmount: targetAmount,
            imageData: imageData,
            imageURL: imageURL,
            productURL: productURL
        )
        bosses.insert(boss, at: 0)
        persist()
    }

    func addDraft(_ draft: SharedItemDraft) {
        pendingDrafts.insert(draft, at: 0)
        persist()
    }

    func recordPower(kind: AttackFundKind, amount: Int, memo: String, date: Date = Date()) {
        guard amount > 0 else { return }
        let fund = AttackFund(kind: kind, amount: amount, memo: memo, date: date)
        let result = AttackResult(fund: fund, allocations: [])
        attackResults.insert(result, at: 0)
        persist()
    }

    func registerDraftAsBoss(_ draft: SharedItemDraft, price: Int) {
        addBoss(
            name: draft.title.isEmpty ? "欲しいもの" : draft.title,
            category: "共有から追加",
            targetAmount: price,
            imageData: draft.imageData,
            imageURL: draft.imageURL,
            productURL: draft.pageURL
        )
        removeDraft(draft)
    }

    func resistDraftAndCreateFund(_ draft: SharedItemDraft, price: Int) -> AttackFund {
        removeDraft(draft)
        return AttackFund(kind: .resisted, amount: price, memo: draft.title, sourceURL: draft.pageURL)
    }

    func removeDraft(_ draft: SharedItemDraft) {
        pendingDrafts.removeAll { $0.id == draft.id }
        persist()
    }

    func applyAttackFund(kind: AttackFundKind, amount: Int, memo: String, allocations: [BossAllocation]) -> AttackResult? {
        let validAllocations = allocations.filter { $0.amount > 0 }
        let totalAllocated = validAllocations.reduce(0) { $0 + $1.amount }

        guard amount > 0, totalAllocated > 0, totalAllocated <= amount else {
            return nil
        }

        let fund = AttackFund(kind: kind, amount: amount, memo: memo)
        let cappedAllocations = validAllocations.map { allocation in
            var copy = allocation
            if let boss = bosses.first(where: { $0.id == allocation.bossID }) {
                copy.amount = min(allocation.amount, boss.remainingHP)
            }
            return copy
        }

        for allocation in cappedAllocations {
            guard let index = bosses.firstIndex(where: { $0.id == allocation.bossID }) else { continue }
            bosses[index].savedAmount = min(bosses[index].savedAmount + allocation.amount, bosses[index].targetAmount)
        }

        let result = AttackResult(fund: fund, allocations: cappedAllocations)
        attackResults.insert(result, at: 0)
        latestResult = result
        persist()
        return result
    }

    /// 既に記録済みで未使用のPOWERを、後からボスへ割り当てる。
    /// fund.amountを0にすることで、獲得記録を二重計上しない。
    func applyExistingPower(amount: Int, allocations: [BossAllocation]) -> AttackResult? {
        let validAllocations = allocations.filter { $0.amount > 0 }
        let totalAllocated = validAllocations.reduce(0) { $0 + $1.amount }
        guard amount > 0, totalAllocated > 0, totalAllocated <= availablePower else { return nil }

        let cappedAllocations = validAllocations.map { allocation in
            var copy = allocation
            if let boss = bosses.first(where: { $0.id == allocation.bossID }) {
                copy.amount = min(allocation.amount, boss.remainingHP)
            }
            return copy
        }
        let actualDamage = cappedAllocations.reduce(0) { $0 + $1.amount }
        guard actualDamage > 0 else { return nil }

        for allocation in cappedAllocations {
            guard let index = bosses.firstIndex(where: { $0.id == allocation.bossID }) else { continue }
            bosses[index].savedAmount = min(bosses[index].savedAmount + allocation.amount, bosses[index].targetAmount)
        }

        let fund = AttackFund(kind: .earned, amount: 0, memo: "記録済みPOWERから攻撃")
        let result = AttackResult(fund: fund, allocations: cappedAllocations)
        attackResults.insert(result, at: 0)
        latestResult = result
        persist()
        return result
    }

    func bossName(for id: UUID) -> String {
        bosses.first(where: { $0.id == id })?.name ?? "ボス"
    }

    func boss(for id: UUID) -> Boss? {
        bosses.first(where: { $0.id == id })
    }

    func replacePendingDrafts(_ drafts: [SharedItemDraft]) {
        pendingDrafts = drafts
        persist()
    }

    func importSharedDrafts() {
        let sharedStore = SharedDraftStore()
        let drafts = sharedStore.load()
        guard !drafts.isEmpty else { return }
        for draft in drafts where !pendingDrafts.contains(where: { $0.id == draft.id }) {
            pendingDrafts.insert(draft, at: 0)
        }
        sharedStore.clear()
        persist()
    }

    private func persist() {
        persistence.saveGameState(
            GameState(
                bosses: bosses,
                attackResults: attackResults,
                pendingDrafts: pendingDrafts
            )
        )
    }
}

extension Boss {
    static let sampleData: [Boss] = [
        Boss(name: "スニーカー", category: "ファッションボス", targetAmount: 30_000, savedAmount: 18_000),
        Boss(name: "ライブ", category: "イベントボス", targetAmount: 15_000, savedAmount: 5_000),
        Boss(name: "旅行", category: "大型ボス", targetAmount: 100_000, savedAmount: 20_000)
    ]
}
