import SwiftUI

struct AddBossView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            BossRegistrationView(onRegister: { dismiss() })
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる") { dismiss() }
                    }
                }
        }
    }
}
