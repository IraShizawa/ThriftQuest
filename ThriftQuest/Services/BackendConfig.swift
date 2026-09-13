import Foundation

enum BackendConfig {
    static let baseURLString = ""

    static var generateBossImageURL: URL? {
        guard !baseURLString.isEmpty,
              let baseURL = URL(string: baseURLString)
        else { return nil }
        return baseURL.appendingPathComponent("api/generate-boss-image")
    }
}
