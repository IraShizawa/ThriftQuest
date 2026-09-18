import SwiftUI
import UIKit

struct BossRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GameStore

    private let sourceImage: UIImage?
    let onRegister: (() -> Void)?
    private let imageGenerator = BossImageGenerator()

    @State private var name: String
    @State private var category = "欲しいもの"
    @State private var targetAmountText: String
    @State private var bossImage: UIImage?
    @State private var isGenerating = false
    @State private var hasGeneratedImage = false
    @State private var generationError: String?
    @State private var pendingGenerationError: String?
    @State private var hasRegistered = false
    @State private var generationTask: Task<Void, Never>?

    init(
        image: UIImage? = nil,
        initialName: String = "",
        initialAmount: Int? = nil,
        onRegister: (() -> Void)? = nil
    ) {
        self.sourceImage = image
        self.onRegister = onRegister
        _name = State(initialValue: initialName)
        _targetAmountText = State(initialValue: initialAmount.map(String.init) ?? "")
        _bossImage = State(initialValue: image)
    }

    private var targetAmount: Int {
        Int(targetAmountText.filter(\.isNumber)) ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("ボス情報を設定").font(QuestStyle.heading()).frame(maxWidth: .infinity)
                if let bossImage {
                    Image(uiImage: bossImage)
                        .resizable().scaledToFit().frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 80)).foregroundStyle(QuestStyle.gold)
                        .frame(maxWidth: .infinity).frame(height: 180).questPanel()
                }
                if sourceImage != nil {
                    Button {
                        generateBossImage()
                    } label: {
                        Label(hasGeneratedImage ? "もう一度ボス生成" : "AIでボス生成", systemImage: "sparkles")
                    }
                    .buttonStyle(QuestButtonStyle(color: Color(red: 0.98, green: 0.36, blue: 0.66)))
                    .disabled(isGenerating)
                    .opacity(isGenerating ? 0.55 : 1)
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
            }.padding(32).padding(.bottom, 280)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.clear.contentShape(Rectangle()).onTapGesture { hideKeyboard() })
        .background(QuestBackdrop())
        .fullScreenCover(isPresented: $isGenerating, onDismiss: {
            generationError = pendingGenerationError
            pendingGenerationError = nil
        }) {
            BossSummoningView(
                sourceImage: sourceImage,
                bossName: name.isEmpty ? "欲しいもの" : name,
                onCancel: cancelGeneration
            )
        }
        .navigationTitle("ボス登録").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") { hideKeyboard() }
            }
        }
        .alert("AIボス生成に失敗しました", isPresented: Binding(
            get: { generationError != nil },
            set: { if !$0 { generationError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(generationError ?? "")
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func registerBoss() {
        guard targetAmount > 0, !hasRegistered else { return }
        hasRegistered = true
        store.addBoss(
            name: name.isEmpty ? "欲しいもの" : name,
            category: category.isEmpty ? "欲しいもの" : category,
            targetAmount: targetAmount,
            imageData: bossImage?.jpegData(compressionQuality: 0.85)
        )
        onRegister?()
        dismiss()
    }

    private func generateBossImage() {
        guard let sourceImage, !isGenerating else { return }

        hideKeyboard()
        generationError = nil
        pendingGenerationError = nil
        isGenerating = true
        generationTask = Task { @MainActor in
            do {
                let generated = try await imageGenerator.generateBossImage(
                    from: sourceImage,
                    bossName: name.isEmpty ? "欲しいもの" : name
                )
                try Task.checkCancellation()
                bossImage = generated
                hasGeneratedImage = true
                isGenerating = false
                generationTask = nil
            } catch {
                guard !Task.isCancelled else { return }
                pendingGenerationError = error.localizedDescription
                isGenerating = false
                generationTask = nil
            }
        }
    }

    private func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        isGenerating = false
    }
}
