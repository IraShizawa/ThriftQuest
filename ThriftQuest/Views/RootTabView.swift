import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var store: GameStore
    @State private var selection = 0
    @State private var isShowingSharedDraft = false

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(0)

            RecordsView()
                .tabItem {
                    Label("記録", systemImage: "list.bullet.rectangle")
                }
                .tag(1)

            BossLibraryView()
                .tabItem {
                    Label("図鑑", systemImage: "book.closed.fill")
                }
                .tag(3)
        }
        .tint(.red)
        .onOpenURL { url in
            guard url.scheme == "thriftquest" else { return }
            store.importSharedDrafts()
            selection = 0
            isShowingSharedDraft = true
        }
        .sheet(isPresented: $isShowingSharedDraft) {
            ShareDraftView()
        }
    }
}
