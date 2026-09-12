import UIKit
import UniformTypeIdentifiers

private enum AppGroupConfig {
    static let identifier = "group.app.shizawa.ira.ThriftQuest"
    static let sharedDraftsKey = "shared-item-drafts-v1"
}

private struct SharedItemDraft: Codable, Identifiable, Equatable {
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

private final class SharedDraftStore {
    private let defaults = UserDefaults(suiteName: AppGroupConfig.identifier)
    private let fileManager = FileManager.default

    func loadDrafts() -> [SharedItemDraft] {
        guard let data = defaults?.data(forKey: AppGroupConfig.sharedDraftsKey),
              let drafts = try? JSONDecoder().decode([SharedItemDraft].self, from: data)
        else { return [] }
        return drafts.sorted { $0.createdAt > $1.createdAt }
    }

    func saveDraft(_ draft: SharedItemDraft) {
        var drafts = loadDrafts()
        drafts.removeAll { $0.id == draft.id }
        drafts.insert(draft, at: 0)
        guard let data = try? JSONEncoder().encode(drafts) else { return }
        defaults?.set(data, forKey: AppGroupConfig.sharedDraftsKey)
    }

    func saveImageData(_ data: Data) -> String? {
        guard let directory = fileManager
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroupConfig.identifier)?
            .appendingPathComponent("SharedImages", isDirectory: true)
        else { return nil }
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let filename = "\(UUID().uuidString).jpg"
        let url = directory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: [.atomic])
            return filename
        } catch {
            return nil
        }
    }
}

private struct WebMetadata {
    var title: String?
    var imageURL: URL?
}

private final class WebMetadataFetcher {
    func fetch(from url: URL) async -> WebMetadata {
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode),
              let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .shiftJIS)
        else {
            return WebMetadata()
        }

        let metadata = HTMLMetadataParser(html: html, baseURL: url)
        let productMetadata = metadata.productJSONLD()
        return WebMetadata(
            title: productMetadata.title ?? metadata.content(for: ["og:title", "twitter:title"]) ?? metadata.title(),
            imageURL: productMetadata.imageURL ?? metadata.urlContent(for: ["og:image", "og:image:url", "twitter:image", "twitter:image:src"])
        )
    }

    func fetchImageData(from url: URL) async -> Data? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode),
              data.count > 0,
              UIImage(data: data) != nil
        else {
            return nil
        }
        return data
    }
}

private struct HTMLMetadataParser {
    let html: String
    let baseURL: URL

    func content(for keys: [String]) -> String? {
        let normalizedKeys = Set(keys.map { $0.lowercased() })
        for attributes in metaTagAttributes() {
            let property = attributes["property"]?.lowercased()
            let name = attributes["name"]?.lowercased()
            guard let key = property ?? name, normalizedKeys.contains(key),
                  let content = attributes["content"]?.decodedHTMLText,
                  !content.isEmpty
            else { continue }
            return content
        }
        return nil
    }

    func urlContent(for keys: [String]) -> URL? {
        guard let content = content(for: keys) else { return nil }
        return URL(string: content, relativeTo: baseURL)?.absoluteURL
    }

    func title() -> String? {
        guard let regex = try? NSRegularExpression(
            pattern: #"<title[^>]*>(.*?)</title>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return nil }

        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, range: range),
              let titleRange = Range(match.range(at: 1), in: html)
        else { return nil }

        let title = String(html[titleRange]).decodedHTMLText
        return title.isEmpty ? nil : title
    }

    func productJSONLD() -> WebMetadata {
        for object in jsonLDObjects() {
            if let product = findProduct(in: object) {
                return WebMetadata(
                    title: stringValue(for: "name", in: product),
                    imageURL: imageURL(in: product)
                )
            }
        }
        return WebMetadata()
    }

    private func metaTagAttributes() -> [[String: String]] {
        guard let regex = try? NSRegularExpression(
            pattern: #"<meta\b[^>]*>"#,
            options: [.caseInsensitive]
        ) else { return [] }

        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        return regex.matches(in: html, range: range).compactMap { match in
            guard let tagRange = Range(match.range, in: html) else { return nil }
            return attributes(in: String(html[tagRange]))
        }
    }

    private func attributes(in tag: String) -> [String: String] {
        guard let regex = try? NSRegularExpression(
            pattern: #"([a-zA-Z_:][-a-zA-Z0-9_:.]*)\s*=\s*["']([^"']*)["']"#,
            options: []
        ) else { return [:] }

        let range = NSRange(tag.startIndex..<tag.endIndex, in: tag)
        var result: [String: String] = [:]
        for match in regex.matches(in: tag, range: range) {
            guard let nameRange = Range(match.range(at: 1), in: tag),
                  let valueRange = Range(match.range(at: 2), in: tag)
            else { continue }
            result[String(tag[nameRange]).lowercased()] = String(tag[valueRange])
        }
        return result
    }

    private func jsonLDObjects() -> [Any] {
        guard let regex = try? NSRegularExpression(
            pattern: #"<script\b[^>]*type\s*=\s*["']application/ld\+json["'][^>]*>(.*?)</script>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return [] }

        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        return regex.matches(in: html, range: range).compactMap { match in
            guard let scriptRange = Range(match.range(at: 1), in: html) else { return nil }
            let script = String(html[scriptRange]).decodedHTMLEntities
            guard let data = script.data(using: .utf8) else { return nil }
            return try? JSONSerialization.jsonObject(with: data)
        }
    }

    private func findProduct(in object: Any) -> [String: Any]? {
        if let dictionary = object as? [String: Any] {
            if isProduct(dictionary) {
                return dictionary
            }

            if let graph = dictionary["@graph"], let product = findProduct(in: graph) {
                return product
            }

            for value in dictionary.values {
                if let product = findProduct(in: value) {
                    return product
                }
            }
        }

        if let array = object as? [Any] {
            for item in array {
                if let product = findProduct(in: item) {
                    return product
                }
            }
        }

        return nil
    }

    private func isProduct(_ dictionary: [String: Any]) -> Bool {
        if let type = dictionary["@type"] as? String {
            return type.localizedCaseInsensitiveContains("Product")
        }

        if let types = dictionary["@type"] as? [Any] {
            return types.contains { item in
                guard let type = item as? String else { return false }
                return type.localizedCaseInsensitiveContains("Product")
            }
        }

        return false
    }

    private func stringValue(for key: String, in dictionary: [String: Any]) -> String? {
        guard let value = dictionary[key] else { return nil }
        if let string = value as? String {
            let decoded = string.decodedHTMLText
            return decoded.isEmpty ? nil : decoded
        }
        return nil
    }

    private func imageURL(in dictionary: [String: Any]) -> URL? {
        guard let image = dictionary["image"] else { return nil }

        if let string = image as? String {
            return URL(string: string, relativeTo: baseURL)?.absoluteURL
        }

        if let array = image as? [Any] {
            for item in array {
                if let string = item as? String,
                   let url = URL(string: string, relativeTo: baseURL)?.absoluteURL {
                    return url
                }

                if let dictionary = item as? [String: Any],
                   let url = imageURL(in: dictionary) {
                    return url
                }
            }
        }

        if let dictionary = image as? [String: Any] {
            for key in ["url", "contentUrl"] {
                if let string = dictionary[key] as? String,
                   let url = URL(string: string, relativeTo: baseURL)?.absoluteURL {
                    return url
                }
            }
        }

        return nil
    }
}

private extension String {
    var decodedHTMLText: String {
        let data = Data(self.utf8)
        if let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) {
            return attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var decodedHTMLEntities: String {
        replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#34;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

final class ShareViewController: UIViewController {
    private let draftStore = SharedDraftStore()
    private let metadataFetcher = WebMetadataFetcher()
    private var capturedTitle = ""
    private var capturedURL: URL?
    private var capturedImageData: Data?

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        loadSharedItems()
    }

    private func configureView() {
        view.backgroundColor = UIColor(red: 0.04, green: 0.035, blue: 0.035, alpha: 1)

        let heading = UILabel()
        heading.text = "ボスとして登録"
        heading.font = .systemFont(ofSize: 24, weight: .bold)
        heading.textColor = UIColor(red: 1.0, green: 0.85, blue: 0.34, alpha: 1)

        titleLabel.text = "共有されたアイテムを読み込み中..."
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        imageView.backgroundColor = UIColor(white: 0.88, alpha: 1)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 18
        imageView.clipsToBounds = true
        imageView.heightAnchor.constraint(equalToConstant: 220).isActive = true

        saveButton.setTitle("貯金RPGで開く", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        saveButton.tintColor = .black
        saveButton.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.34, alpha: 1)
        saveButton.layer.cornerRadius = 16
        saveButton.heightAnchor.constraint(equalToConstant: 54).isActive = true
        saveButton.addTarget(self, action: #selector(saveAndOpenApp), for: .touchUpInside)
        saveButton.isEnabled = false
        saveButton.alpha = 0.55

        cancelButton.setTitle("キャンセル", for: .normal)
        cancelButton.tintColor = .white
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [heading, imageView, titleLabel, saveButton, cancelButton])
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadSharedItems() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            updatePreview()
            return
        }

        let providers = extensionItems.flatMap { $0.attachments ?? [] }
        let group = DispatchGroup()

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.image.identifier) { [weak self] item, _ in
                    defer { group.leave() }
                    self?.captureImage(from: item)
                }
            }

            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, _ in
                    defer { group.leave() }
                    if let url = item as? URL {
                        self?.capturedURL = url
                        if self?.capturedTitle.isEmpty == true {
                            self?.capturedTitle = url.host ?? url.absoluteString
                        }
                    }
                }
            }

            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] item, _ in
                    defer { group.leave() }
                    if let text = item as? String, self?.capturedTitle.isEmpty == true {
                        self?.capturedTitle = text
                    }
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.loadWebMetadataIfNeeded()
        }
    }

    private func loadWebMetadataIfNeeded() {
        updatePreview(isLoading: capturedURL != nil)

        guard let capturedURL else {
            updatePreview()
            return
        }

        Task { [weak self] in
            guard let self else { return }
            let metadata = await metadataFetcher.fetch(from: capturedURL)

            await MainActor.run {
                if let title = metadata.title, !title.isEmpty {
                    capturedTitle = title
                }
            }

            if capturedImageData == nil, let imageURL = metadata.imageURL {
                let data = await metadataFetcher.fetchImageData(from: imageURL)
                await MainActor.run {
                    if let data {
                        capturedImageData = data
                    }
                    updatePreview()
                }
            } else {
                await MainActor.run {
                    updatePreview()
                }
            }
        }
    }

    private func captureImage(from item: NSSecureCoding?) {
        if let image = item as? UIImage {
            capturedImageData = image.jpegData(compressionQuality: 0.86)
            return
        }

        if let url = item as? URL {
            capturedImageData = try? Data(contentsOf: url)
            return
        }

        if let data = item as? Data {
            capturedImageData = data
        }
    }

    private func updatePreview(isLoading: Bool = false) {
        if let capturedImageData, let image = UIImage(data: capturedImageData) {
            imageView.image = image
        } else {
            imageView.image = UIImage(systemName: "shippingbox.fill")
            imageView.tintColor = UIColor(red: 1.0, green: 0.85, blue: 0.34, alpha: 1)
        }

        let trimmedTitle = capturedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if isLoading {
            titleLabel.text = trimmedTitle.isEmpty ? "商品情報を読み込み中..." : "\(trimmedTitle)\n商品画像を探しています..."
        } else {
            titleLabel.text = trimmedTitle.isEmpty ? "画像や商品ページをボスとして登録します。" : trimmedTitle
        }
        saveButton.isEnabled = !isLoading
        saveButton.alpha = saveButton.isEnabled ? 1 : 0.55
    }

    @objc private func saveAndOpenApp() {
        let imageFilename = capturedImageData.flatMap { draftStore.saveImageData($0) }
        let draft = SharedItemDraft(
            title: capturedTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            url: capturedURL,
            imageFilename: imageFilename
        )
        draftStore.saveDraft(draft)
        openContainingApp()
    }

    @objc private func cancel() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func openContainingApp() {
        guard let url = URL(string: "thriftquest://shared-draft") else {
            extensionContext?.completeRequest(returningItems: nil)
            return
        }

        var responder: UIResponder? = self
        while let current = responder {
            if let application = current as? UIApplication {
                application.open(url)
                extensionContext?.completeRequest(returningItems: nil)
                return
            }
            responder = current.next
        }

        extensionContext?.completeRequest(returningItems: nil)
    }
}
