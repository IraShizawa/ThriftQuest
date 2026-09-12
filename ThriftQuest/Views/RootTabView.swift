import SwiftUI

struct RootTabView: View {
    @State private var selection = 0
    @State private var keyboardVisible = false

    var body: some View {
        TabView(selection: $selection) {
            HomeView(onRecord: { selection = 1 }).tag(0)
            RecordsView().tag(1)
            BossLibraryView().tag(2)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !keyboardVisible {
                HStack(spacing: 0) {
                    tab("ホーム", icon: "house", index: 0)
                    tab("記録", icon: "doc.text", index: 1)
                    tab("図鑑", icon: "book", index: 2)
                }
                .padding(5)
                .background(QuestStyle.panel, in: Capsule())
                .overlay(Capsule().stroke(QuestStyle.gold.opacity(0.6), lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 12, y: -3)
                .padding(.horizontal, 22).padding(.top, 6).padding(.bottom, 3)
                .background(QuestStyle.background)
            }
        }
        .tint(QuestStyle.gold)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            keyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardVisible = false
        }
    }

    private func tab(_ title: String, icon: String, index: Int) -> some View {
        Button { selection = index } label: {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 26, weight: .semibold))
                    .symbolVariant(.none)
                Text(title).font(QuestStyle.heading(10))
            }
            .foregroundStyle(selection == index ? QuestStyle.gold : .white)
            .frame(maxWidth: .infinity).frame(height: 53)
            .background {
                if selection == index {
                    Capsule().fill(QuestStyle.field)
                        .overlay(Capsule().stroke(QuestStyle.gold.opacity(0.8), lineWidth: 0.7))
                        .padding(.horizontal, 14)
                }
            }
        }.buttonStyle(.plain)
            .accessibilityAddTraits(selection == index ? .isSelected : [])
    }
}
