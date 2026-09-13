import Foundation
import UIKit

enum BossImageGeneratorError: LocalizedError {
    case backendNotConfigured
    case invalidImage
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .backendNotConfigured:
            return "AI生成サーバーのURLが設定されていません。"
        case .invalidImage:
            return "画像を読み込めませんでした。"
        case .invalidResponse:
            return "生成された画像を読み込めませんでした。"
        case .apiError(let message):
            return message
        }
    }
}

final class BossImageGenerator {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func generateBossImage(from image: UIImage, bossName: String) async throws -> UIImage {
        guard let endpointURL = BackendConfig.generateBossImageURL else {
            throw BossImageGeneratorError.backendNotConfigured
        }

        guard let imageData = normalizedJPEGData(from: image) else {
            throw BossImageGeneratorError.invalidImage
        }

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            GenerateBossImageRequest(
                bossName: bossName,
                imageBase64: imageData.base64EncodedString()
            )
        )

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BossImageGeneratorError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw BossImageGeneratorError.apiError(apiErrorMessage(from: data) ?? "AI生成サーバーで画像生成に失敗しました。")
        }

        let decoded = try JSONDecoder().decode(GenerateBossImageResponse.self, from: data)
        guard let base64 = decoded.imageBase64,
              let outputData = Data(base64Encoded: base64),
              let outputImage = UIImage(data: outputData)
        else {
            throw BossImageGeneratorError.invalidResponse
        }

        return outputImage
    }

    private func normalizedJPEGData(from image: UIImage) -> Data? {
        let maxSide: CGFloat = 1024
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return rendered.jpegData(compressionQuality: 0.82)
    }

    private func apiErrorMessage(from data: Data) -> String? {
        guard let response = try? JSONDecoder().decode(APIErrorResponse.self, from: data) else {
            return nil
        }
        return response.error
    }
}

private struct GenerateBossImageRequest: Encodable {
    let bossName: String
    let imageBase64: String
}

private struct GenerateBossImageResponse: Decodable {
    let imageBase64: String?
}

private struct APIErrorResponse: Decodable {
    let error: String
}
