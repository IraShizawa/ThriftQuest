import Foundation

enum BackendConfig {
    static let baseURLString = "https://thrift-quest.vercel.app/"

    static var generateBossImageURL: URL? {
        guard !baseURLString.isEmpty,
              let baseURL = URL(string: baseURLString)
        else { return nil }
        return baseURL.appendingPathComponent("api/generate-boss-image")
    }
}
