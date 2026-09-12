import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var store: GameStore
    var onRecord: () -> Void = {}
    @State private var selectedBossID: UUID?
    @State private var showingSource = false
    @State private var showingCamera = false
    @State private var showingLibrary = false
    @State private var sourceImage: UIImage?
    @State private var showingRegistration = false
    @State private var showingManual = false
    @State private var showingAttack = false
    @State private var showingSettings = false
    @State private var sourceChoice: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(spacing: 7) {
                        Text("T H R I F T  Q U E S T").font(QuestStyle.inscription(10)).foregroundStyle(QuestStyle.gold)
                        Text("貯金RPG").font(QuestStyle.heading(27)).foregroundStyle(QuestStyle.parchment)
                        HStack(spacing: 10) {
                            Rectangle().fill(QuestStyle.gold.opacity(0.4)).frame(width: 34, height: 1)
                            Text("欲しいものへ、冒険を。").font(.caption2).foregroundStyle(QuestStyle.parchment.opacity(0.7))
                            Rectangle().fill(QuestStyle.gold.opacity(0.4)).frame(width: 34, height: 1)
                        }
                    }.frame(maxWidth: .infinity).shadow(color: .black.opacity(0.7), radius: 8)
                    powerCard
                    QuestSectionHeading(title: "攻略中のボス", subtitle: "ACTIVE QUESTS")
                    ForEach(store.activeBosses) { boss in
                        Button { selectedBossID = boss.id } label: {
                            HStack(spacing: 12) {
                                BossImageView(boss: boss, size: 82)
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(boss.name).font(QuestStyle.heading(17)).foregroundStyle(QuestStyle.parchment).lineLimit(1)
                                    HStack {
                                        Text("残りHP")
                                        Spacer(minLength: 4)
                                        Text("\(QuestStyle.number(boss.remainingHP)) / \(QuestStyle.number(boss.targetAmount))")
                                            .monospacedDigit().minimumScaleFactor(0.65).lineLimit(1)
                                    }.font(.caption)
                                    QuestHPBar(boss: boss)
                                }.padding(.trailing, 10)
                            }.questPanel()
                        }.buttonStyle(.plain)
                    }
                    if store.activeBosses.isEmpty {
                        Text("欲しいものをボスにして、攻略を始めよう。")
                            .foregroundStyle(.secondary).padding(.vertical, 24)
                    }
                }.padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 150)
            }
            .scrollIndicators(.hidden)
            .background(QuestBackdrop())
            .overlay(alignment: .bottomTrailing) {
                Button { showingSource = true } label: {
                    VStack(spacing: 3) {
                        Text("ボス出現！").font(QuestStyle.heading(14)).foregroundStyle(QuestStyle.panel)
                            .padding(.horizontal, 13).padding(.vertical, 5)
                            .background(QuestStyle.gold, in: Capsule())
                        Image(systemName: "plus").font(.system(size: 34, weight: .light))
                            .frame(width: 66, height: 66)
                            .background(QuestStyle.panel.opacity(0.95), in: Circle())
                            .overlay(Circle().stroke(QuestStyle.gold, lineWidth: 2))
                            .overlay(Circle().stroke(QuestStyle.gold.opacity(0.35), lineWidth: 0.7).padding(5))
                            .shadow(color: QuestStyle.gold.opacity(0.25), radius: 12)
                    }.foregroundStyle(QuestStyle.gold)
                }.buttonStyle(.plain).padding(.trailing, 22).padding(.bottom, 38)
                    .accessibilityLabel("ボスを追加")
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedBossID) { id in
                if let boss = store.boss(for: id) { BossDetailView(boss: boss) }
            }
            .sheet(isPresented: $showingSource, onDismiss: presentSourceChoice) {
                VStack(spacing: 22) {
                    Button { sourceChoice = "camera"; showingSource = false } label: {
                        Label("カメラで撮影", systemImage: "camera")
                    }.buttonStyle(QuestButtonStyle())
                        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                    Button { sourceChoice = "library"; showingSource = false } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle").foregroundStyle(.black)
                            Text("写真から選ぶ")
                        }
                    }.buttonStyle(QuestButtonStyle())
                    HStack {
                        Button("画像なしで登録") { sourceChoice = "manual"; showingSource = false }
                        Spacer()
                        Button { sourceChoice = "settings"; showingSource = false } label: {
                            Image(systemName: "gearshape")
                        }.accessibilityLabel("設定")
                    }.font(.footnote).foregroundStyle(.black)
                }.padding(30).presentationDetents([.height(290)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color(red: 1, green: 0.92, blue: 0.68))
            }
            .sheet(isPresented: $showingCamera, onDismiss: openRegistration) {
                ImagePicker(source: .camera, image: $sourceImage)
            }
            .sheet(isPresented: $showingLibrary, onDismiss: openRegistration) {
                ImagePicker(source: .photoLibrary, image: $sourceImage)
            }
            .sheet(isPresented: $showingRegistration, onDismiss: { sourceImage = nil }) {
                NavigationStack {
                    BossRegistrationView(image: sourceImage, onRegister: { showingRegistration = false })
                }
            }
            .sheet(isPresented: $showingManual) { AddBossView() }
            .sheet(isPresented: $showingSettings) { NavigationStack { MyPageView() } }
            .navigationDestination(isPresented: $showingAttack) {
                AllocationView(kind: .earned, amount: store.availablePower, memo: "",
                               preselectedBossID: nil, usesExistingPower: true,
                               onFinish: { showingAttack = false })
            }
        }
    }

    private var powerCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                Text("POWER").font(QuestStyle.inscription(14)).tracking(2).foregroundStyle(QuestStyle.parchment)
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill").font(.system(size: 32))
                    Text(QuestStyle.number(store.availablePower)).font(.system(.title, design: .monospaced, weight: .medium))
                        .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
                }.foregroundStyle(QuestStyle.gold).shadow(color: QuestStyle.gold.opacity(0.25), radius: 8)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Button {
                if store.activeBosses.isEmpty { showingSource = true }
                else { showingAttack = true }
            } label: {
                HStack(spacing: 6) {
                    QuestSword().frame(width: 28, height: 28)
                    Text("攻撃する！").font(QuestStyle.heading(18)).lineLimit(1).minimumScaleFactor(0.75)
                }.foregroundStyle(QuestStyle.parchment).frame(maxWidth: .infinity).frame(height: 94)
                    .background(LinearGradient(colors: [QuestStyle.attack, Color(red: 0.65, green: 0.025, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(QuestStyle.gold.opacity(0.8), lineWidth: 1))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(QuestStyle.parchment.opacity(0.25), lineWidth: 0.7).padding(5))
                    .shadow(color: QuestStyle.attack.opacity(0.22), radius: 10, y: 4)
            }.buttonStyle(.plain)
                .accessibilityHint("使うPOWERを決めます")
        }.padding(16).questPanel()
    }

    private func openRegistration() {
        if sourceImage != nil { showingRegistration = true }
    }

    private func presentSourceChoice() {
        switch sourceChoice {
        case "camera": showingCamera = true
        case "library": showingLibrary = true
        case "manual": showingManual = true
        case "settings": showingSettings = true
        default: break
        }
        sourceChoice = nil
    }
}
