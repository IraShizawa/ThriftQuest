import SwiftUI

struct AddBossView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GameStore

    @State private var name = ""
    @State private var category = "欲しいもの"
    @State private var targetAmountText = ""
    @State private var urlText = ""
    @State private var isShowingBossGenerator = false

    private var targetAmount: Int {
        Int(targetAmountText.filter(\.isNumber)) ?? 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        isShowingBossGenerator = true
                    } label: {
                        Label("商品画像からAIボスを生成", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                }

                Section("ボス情報") {
                    TextField("例）スニーカー", text: $name)
                    TextField("例）ファッションボス", text: $category)
                    TextField("目標金額", text: $targetAmountText)
                        .keyboardType(.numberPad)
                    TextField("商品URL（任意）", text: $urlText)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }

                Section {
                    Button {
                        store.addBoss(
                            name: name.isEmpty ? "欲しいもの" : name,
                            category: category.isEmpty ? "欲しいもの" : category,
                            targetAmount: targetAmount,
                            productURL: URL(string: urlText)
                        )
                        dismiss()
                    } label: {
                        Label("ボスとして登録", systemImage: "shield.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(targetAmount <= 0)
                }
            }
            .navigationTitle("ボス追加")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $isShowingBossGenerator) {
                BossGenerateView()
            }
        }
    }
}
