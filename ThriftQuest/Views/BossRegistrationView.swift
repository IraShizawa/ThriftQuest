import SwiftUI
import UIKit

struct BossRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GameStore

    let generatedImage: UIImage
    let onRegister: (() -> Void)?

    @State private var name: String
    @State private var category = "AI生成ボス"
    @State private var targetAmountText: String

    init(
        generatedImage: UIImage,
        initialName: String = "",
        initialAmount: Int? = nil,
        onRegister: (() -> Void)? = nil
    ) {
        self.generatedImage = generatedImage
        self.onRegister = onRegister
        _name = State(initialValue: initialName)
        _targetAmountText = State(initialValue: initialAmount.map(String.init) ?? "")
    }

    private var targetAmount: Int {
        Int(targetAmountText.filter(\.isNumber)) ?? 0
    }

    var body: some View {
        Form {
            Section("ボス画像") {
                Image(uiImage: generatedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Section("ボス情報") {
                TextField("例）スニーカードラゴン", text: $name)
                TextField("カテゴリ", text: $category)
                TextField("MAX HP（商品の価格）", text: $targetAmountText)
                    .keyboardType(.numberPad)
            }

            Section {
                Button {
                    registerBoss()
                } label: {
                    Label("ボスを登録", systemImage: "shield.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(targetAmount <= 0)
            }
        }
        .navigationTitle("ボス登録")
    }

    private func registerBoss() {
        // 生成画像は既存のBoss.imageDataに保存するため、他の画面の表示処理をそのまま使えます。
        store.addBoss(
            name: name.isEmpty ? "AI生成ボス" : name,
            category: category.isEmpty ? "AI生成ボス" : category,
            targetAmount: targetAmount,
            imageData: generatedImage.pngData()
        )
        onRegister?()
        dismiss()
    }
}
