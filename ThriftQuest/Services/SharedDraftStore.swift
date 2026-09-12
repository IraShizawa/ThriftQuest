import Foundation
import UIKit

final class SharedDraftStore {
    private let defaults: UserDefaults?
    private let fileManager: FileManager

    init(
        defaults: UserDefaults? = UserDefaults(suiteName: AppGroupConfig.identifier),
        fileManager: FileManager = .default
    ) {
        self.defaults = defaults
        self.fileManager = fileManager
    }

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
        saveDrafts(drafts)
    }

    func removeDraft(id: UUID) {
        saveDrafts(loadDrafts().filter { $0.id != id })
    }

    func image(for draft: SharedItemDraft) -> UIImage? {
        guard let imageFilename = draft.imageFilename,
              let url = sharedImagesDirectory()?.appendingPathComponent(imageFilename),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return UIImage(data: data)
    }

    func saveImageData(_ data: Data, preferredExtension: String = "jpg") -> String? {
        guard let directory = sharedImagesDirectory() else { return nil }
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let filename = "\(UUID().uuidString).\(preferredExtension)"
        let url = directory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: [.atomic])
            return filename
        } catch {
            return nil
        }
    }

    private func saveDrafts(_ drafts: [SharedItemDraft]) {
        guard let data = try? JSONEncoder().encode(drafts) else { return }
        defaults?.set(data, forKey: AppGroupConfig.sharedDraftsKey)
    }

    private func sharedImagesDirectory() -> URL? {
        fileManager
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroupConfig.identifier)?
            .appendingPathComponent("SharedImages", isDirectory: true)
    }
}
