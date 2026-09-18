import SwiftUI
import UIKit

/// The server returns a finished image, not progress events. The animation and
/// rotating tips are ambience; elapsed time is the only measured progress here.
struct BossSummoningView: View {
    let sourceImage: UIImage?
    let bossName: String
    let onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var startedAt = Date()
    @State private var tipIndex = 0

    private let tips = [
        ("欲しいものが、冒険の相手に。", "商品の特徴をもとに、あなただけのボスを描きます。"),
        ("小さな我慢も、大きな一撃。", "今日使わなかったお金をPOWERにしてみよう。"),
        ("倒す順番は、あなた次第。", "貯めたPOWERは、好きなボスに分配できます。"),
        ("図鑑は、がんばった証。", "撃破したボスを振り返って、次の冒険へ。")
    ]

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    header
                    summoningCircle
                        .frame(width: 220, height: 220)
                    VStack(spacing: 12) {
                        Text("ボスを召喚中")
                            .font(QuestStyle.heading(30))
                            .foregroundStyle(QuestStyle.parchment)
                        Text(bossName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(QuestStyle.gold)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        Text("その「欲しい」に、姿を与えています。")
                            .font(.subheadline)
                            .foregroundStyle(QuestStyle.parchment.opacity(0.75))
                    }

                    status
                    tipCard

                }
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("生成をキャンセル", action: onCancel)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(QuestStyle.parchment.opacity(0.75))
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color(red: 0.025, green: 0.04, blue: 0.075))
        }
        .background {
            ZStack {
                Color(red: 0.025, green: 0.04, blue: 0.075)
                RadialGradient(colors: [QuestStyle.gold.opacity(0.12), .clear],
                               center: UnitPoint(x: 0.5, y: 0.32), startRadius: 10, endRadius: 330)
            }.ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled()
        .task {
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(9)) }
                catch { return }
                guard scenePhase == .active else { continue }
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.4)) {
                    tipIndex = (tipIndex + 1) % tips.count
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 7) {
            Text("THRIFTQUEST").font(QuestStyle.inscription(12)).tracking(4)
            HStack(spacing: 10) {
                Rectangle().frame(width: 28, height: 1)
                Text("SUMMONING CHAMBER").font(QuestStyle.inscription(9)).tracking(2)
                Rectangle().frame(width: 28, height: 1)
            }.opacity(0.65)
        }
        .foregroundStyle(QuestStyle.gold)
        .accessibilityHidden(true)
    }

    private var summoningCircle: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion || scenePhase != .active)) { timeline in
            let elapsed = reduceMotion ? 0 : timeline.date.timeIntervalSince(startedAt)
            let pulse = (sin(elapsed * 1.4) + 1) / 2
            ZStack {
                Circle().fill(QuestStyle.gold.opacity(0.04 + pulse * 0.04))
                    .blur(radius: 16).padding(12)
                Circle().stroke(QuestStyle.gold.opacity(0.25), lineWidth: 1)
                Circle().stroke(QuestStyle.gold.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [1, 14]))
                    .padding(7).rotationEffect(.degrees(elapsed * 5))
                Circle().trim(from: 0.05, to: 0.8)
                    .stroke(AngularGradient(colors: [.clear, QuestStyle.gold.opacity(0.3), QuestStyle.gold], center: .center),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .padding(18).rotationEffect(.degrees(elapsed * -18))
                ForEach(0..<8) { index in
                    Rectangle().fill(QuestStyle.gold.opacity(index.isMultiple(of: 2) ? 0.9 : 0.35))
                        .frame(width: 5, height: 5).rotationEffect(.degrees(45))
                        .offset(y: -109)
                        .rotationEffect(.degrees(Double(index) * 45 + elapsed * 5))
                }
                VStack(spacing: 10) {
                    if let sourceImage {
                        Image(uiImage: sourceImage)
                            .resizable().scaledToFill()
                            .frame(width: 94, height: 94)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(QuestStyle.gold.opacity(0.65), lineWidth: 1))
                            .shadow(color: QuestStyle.gold.opacity(0.12 + pulse * 0.18), radius: 20)
                    } else {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 60, weight: .ultraLight))
                            .foregroundStyle(QuestStyle.gold)
                    }
                    Image(systemName: "sparkles")
                        .font(.system(size: 20)).foregroundStyle(QuestStyle.gold)
                        .opacity(0.5 + pulse * 0.5)
                }
            }
        }
        .accessibilityLabel("ボスの召喚をイメージしたアニメーション")
    }

    private var status: some View {
        TimelineView(.periodic(from: startedAt, by: 1)) { timeline in
            let seconds = max(0, Int(timeline.date.timeIntervalSince(startedAt)))
            VStack(spacing: 12) {
                HStack(spacing: 9) {
                    ProgressView().tint(QuestStyle.gold)
                    Text("イラスト生成中").font(.subheadline.weight(.medium))
                    Spacer()
                    Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(QuestStyle.gold)
                        .accessibilityLabel("経過時間 \(seconds)秒")
                }
                Text(seconds >= 45
                     ? "少し時間がかかっています。完成すると自動で表示します。"
                     : "生成には時間がかかることがあります。このままお待ちください。")
                    .font(.footnote)
                    .foregroundStyle(QuestStyle.parchment.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18).questPanel()
        }
    }

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("冒険のヒント", systemImage: "book.closed")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(tipIndex + 1) / \(tips.count)").font(.caption.monospacedDigit())
            }.foregroundStyle(QuestStyle.gold)
            VStack(alignment: .leading, spacing: 8) {
                Text(tips[tipIndex].0).font(QuestStyle.heading(18))
                Text(tips[tipIndex].1).font(.footnote)
                    .foregroundStyle(QuestStyle.parchment.opacity(0.65))
            }
            .id(tipIndex)
            .transition(.opacity)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                    tipIndex = (tipIndex + 1) % tips.count
                }
            } label: {
                HStack { Text("次のヒント"); Image(systemName: "arrow.right") }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(QuestStyle.gold)
                    .frame(minHeight: 44)
            }
        }
        .foregroundStyle(QuestStyle.parchment)
        .padding(.horizontal, 6)
    }
}

#Preview("ボス召喚中") {
    BossSummoningView(sourceImage: nil, bossName: "スニーカードラゴン", onCancel: {})
}
