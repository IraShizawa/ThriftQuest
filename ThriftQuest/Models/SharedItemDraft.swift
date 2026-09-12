import Foundation

struct SharedItemDraft: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var url: URL?
    var imageFilename: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        url: URL? = nil,
        imageFilename: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.imageFilename = imageFilename
        self.createdAt = createdAt
    }
}
