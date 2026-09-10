import UIKit
import Vision

enum ReceiptTextScanner {
    static func detectPriceCandidate(in image: UIImage) async -> Int? {
        guard let cgImage = image.cgImage else { return nil }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                continuation.resume(returning: extractLargestYenAmount(from: text))
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ja-JP", "en-US"]
            request.usesLanguageCorrection = false

            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }

    static func extractLargestYenAmount(from text: String) -> Int? {
        let pattern = #"¥?\s?([0-9０-９][0-9０-９,，\.．]{1,8})\s?円?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let amounts = regex.matches(in: text, range: range).compactMap { match -> Int? in
            guard let valueRange = Range(match.range(at: 1), in: text) else { return nil }
            let normalized = String(text[valueRange])
                .applyingTransform(.fullwidthToHalfwidth, reverse: false)?
                .filter(\.isNumber)
            return normalized.flatMap(Int.init)
        }

        return amounts.max()
    }
}
