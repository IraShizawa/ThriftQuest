import SwiftUI
import UIKit

struct RootTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection = 0
    @State private var pendingSharedDraft: SharedItemDraft?

    private let sharedDraftStore = SharedDraftStore()

    var body: some View {
        TabView(selection: $selection) {
            HomeView(onRecord: { selection = 1 })
                .tabItem { Label("ホーム", systemImage: "house") }
                .tag(0)
            RecordsView()
                .tabItem { Label("記録", systemImage: "doc.text") }
                .tag(1)
            BossLibraryView()
                .tabItem { Label("図鑑", systemImage: "book") }
                .tag(2)
        }
        .tint(QuestStyle.gold)
        .onOpenURL { _ in
            loadLatestSharedDraft()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                loadLatestSharedDraft()
            }
        }
        .sheet(item: $pendingSharedDraft) { draft in
            NavigationStack {
                BossRegistrationView(
                    image: sharedDraftStore.image(for: draft),
                    initialName: draft.title,
                    onRegister: {
                        sharedDraftStore.removeDraft(id: draft.id)
                        pendingSharedDraft = nil
                    }
                )
            }
        }
    }

    private func loadLatestSharedDraft() {
        guard let draft = sharedDraftStore.loadDrafts().first,
              Date().timeIntervalSince(draft.createdAt) < 10 * 60 else {
            pendingSharedDraft = nil
            return
        }
        pendingSharedDraft = draft
    }
}
