import Foundation

struct Boss: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: String
    var targetAmount: Int
    var savedAmount: Int
    var imageName: String?
    var imageData: Data?
    var imageURL: URL?
    var productURL: URL?
    var deadline: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        category: String = "欲しいもの",
        targetAmount: Int,
        savedAmount: Int = 0,
        imageName: String? = nil,
        imageData: Data? = nil,
        imageURL: URL? = nil,
        productURL: URL? = nil,
        deadline: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.targetAmount = max(targetAmount, 0)
        self.savedAmount = min(max(savedAmount, 0), max(targetAmount, 0))
        self.imageName = imageName
        self.imageData = imageData
        self.imageURL = imageURL
        self.productURL = productURL
        self.deadline = deadline
        self.createdAt = createdAt
    }

    var remainingHP: Int {
        max(targetAmount - savedAmount, 0)
    }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(Double(savedAmount) / Double(targetAmount), 1)
    }

    var isDefeated: Bool {
        remainingHP == 0
    }
}
