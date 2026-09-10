import Foundation

protocol PersistenceStoring {
    func loadGameState() -> GameState?
    func saveGameState(_ state: GameState)
}

struct GameState: Codable, Equatable {
    var bosses: [Boss]
    var attackResults: [AttackResult]
    var pendingDrafts: [SharedItemDraft]
}

final class UserDefaultsPersistenceStore: PersistenceStoring {
    private let key = "savings-rpg-game-state-v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadGameState() -> GameState? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(GameState.self, from: data)
    }

    func saveGameState(_ state: GameState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: key)
    }
}
