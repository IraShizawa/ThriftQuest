import SwiftUI
import UIKit

struct CameraBossView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GameStore

    @State private var selectedImage: UIImage?
    @State private var isShowingCamera = false
    @State private var isShowingLibrary = false
    @State private var name = ""
    @State private var priceText = ""
    @State private var isScanning = false

    private var price: Int {
        Int(priceText.filter(\.isNumber)) ?? 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 12) {
                        imagePreview
                            .frame(maxWidth: .infinity)

                        HStack {
                            Button {
                                isShowingCamera = true
                            } label: {
                                Label("撮影", systemImage: "camera.fill")
                            }
                            .buttonStyle(.bordered)

                            Button {
                                isShowingLibrary = true
                            } label: {
                                Label("写真", systemImage: "photo")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                Section("商品・値札") {
                    TextField("名前", text: $name)
                    HStack {
                        TextField("金額", text: $priceText)
                            .keyboardType(.numberPad)
                        if isScanning {
                            ProgressView()
                        }
                    }
                }

                Section {
                    Button {
                        store.addBoss(
                            name: name.isEmpty ? "店舗で見つけたもの" : name,
                            category: "店舗ボス",
                            targetAmount: price,
                            imageData: selectedImage?.jpegData(compressionQuality: 0.82)
                        )
                        dismiss()
                    } label: {
                        Label("ボス登録", systemImage: "shield.fill")
                    }
                    .disabled(price <= 0)

                    Button {
                        store.addDraft(
                            SharedItemDraft(
                                title: name.isEmpty ? "店舗で我慢したもの" : name,
                                price: price,
                                pageURL: nil,
                                imageURL: nil
                            )
                        )
                        dismiss()
                    } label: {
                        Label("我慢記録の下書きにする", systemImage: "bolt.fill")
                    }
                    .disabled(price <= 0)
                }
            }
            .navigationTitle("カメラで登録")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingCamera) {
                ImagePicker(source: .camera, image: $selectedImage)
            }
            .sheet(isPresented: $isShowingLibrary) {
                ImagePicker(source: .photoLibrary, image: $selectedImage)
            }
            .onChange(of: selectedImage) { _, newValue in
                guard let newValue else { return }
                scanPrice(in: newValue)
            }
        }
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let selectedImage {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFit()
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
                .frame(height: 180)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.viewfinder")
                            .font(.largeTitle)
                        Text("商品や値札を撮影")
                            .font(.headline)
                    }
                    .foregroundStyle(.secondary)
                }
        }
    }

    private func scanPrice(in image: UIImage) {
        isScanning = true
        Task {
            if let amount = await ReceiptTextScanner.detectPriceCandidate(in: image) {
                priceText = "\(amount)"
            }
            isScanning = false
        }
    }
}
