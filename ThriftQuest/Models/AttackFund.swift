import Foundation

enum AttackFundKind: String, Codable, CaseIterable, Identifiable {
    case earned
    case resisted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .earned:
            return "稼いだ金額"
        case .resisted:
            return "我慢した金額"
        }
    }
}

struct AttackFund: Identifiable, Codable, Equatable {
    let id: UUID
    var kind: AttackFundKind
    var amount: Int
    var memo: String
    var date: Date
    var sourceURL: URL?

    init(
        id: UUID = UUID(),
        kind: AttackFundKind,
        amount: Int,
        memo: String = "",
        date: Date = Date(),
        sourceURL: URL? = nil
    ) {
        self.id = id
        self.kind = kind
        self.amount = max(amount, 0)
        self.memo = memo
        self.date = date
        self.sourceURL = sourceURL
    }
}

struct BossAllocation: Identifiable, Codable, Equatable {
    let id: UUID
    var bossID: UUID
    var amount: Int

    init(id: UUID = UUID(), bossID: UUID, amount: Int) {
        self.id = id
        self.bossID = bossID
        self.amount = max(amount, 0)
    }
}

struct AttackResult: Identifiable, Codable, Equatable {
    let id: UUID
    var fund: AttackFund
    var allocations: [BossAllocation]
    var createdAt: Date

    init(id: UUID = UUID(), fund: AttackFund, allocations: [BossAllocation], createdAt: Date = Date()) {
        self.id = id
        self.fund = fund
        self.allocations = allocations
        self.createdAt = createdAt
    }

    var totalDamage: Int {
        allocations.reduce(0) { $0 + $1.amount }
    }
}
