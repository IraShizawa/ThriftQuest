import SwiftUI
import UIKit

struct BossRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GameStore

    let image: UIImage?
    let onRegister: (() -> Void)?

    @State private var name: String
    @State private var category = "欲しいもの"
    @State private var targetAmountText: String
    @State private var hasRegistered = false

    init(
        image: UIImage? = nil,
        initialName: String = "",
        initialAmount: Int? = nil,
        onRegister: (() -> Void)? = nil
    ) {
        self.image = image
        self.onRegister = onRegister
        _name = State(initialValue: initialName)
        _targetAmountText = State(initialValue: initialAmount.map(String.init) ?? "")
    }

    private var targetAmount: Int {
        Int(targetAmountText.filter(\.isNumber)) ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("ボス情報を設定").font(QuestStyle.heading()).frame(maxWidth: .infinity)
                if let image {
                    Image(uiImage: image)
                        .resizable().scaledToFit().frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 80)).foregroundStyle(QuestStyle.gold)
                        .frame(maxWidth: .infinity).frame(height: 180).questPanel()
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("ボス名").font(.subheadline)
                    TextField("例）スニーカードラゴン", text: $name).questField()
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("MAX HP").font(.subheadline)
                    TextField("用意したい金額（円）", text: $targetAmountText)
                        .keyboardType(.numberPad).questField()
                        .onChange(of: targetAmountText) { _, text in
                            targetAmountText = String(text.filter { $0.isASCII && $0.isNumber }.prefix(7))
                        }
                }
                Button("出現させる！", action: registerBoss)
                    .buttonStyle(QuestButtonStyle())
                    .disabled(targetAmount <= 0)
                    .opacity(targetAmount > 0 ? 1 : 0.5)
            }.padding(32)
        }
        .background(QuestBackdrop())
        .navigationTitle("ボス登録").navigationBarTitleDisplayMode(.inline)
    }

    private func registerBoss() {
        guard targetAmount > 0, !hasRegistered else { return }
        hasRegistered = true
        store.addBoss(
            name: name.isEmpty ? "欲しいもの" : name,
            category: category.isEmpty ? "欲しいもの" : category,
            targetAmount: targetAmount,
            imageData: image?.jpegData(compressionQuality: 0.85)
        )
        onRegister?()
        dismiss()
    }
}
