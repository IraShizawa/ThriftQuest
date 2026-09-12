import SwiftUI

enum QuestStyle {
    static let background = Color.black
    static let panel = Color(red: 0.055, green: 0.095, blue: 0.14)
    static let field = Color(red: 0.11, green: 0.15, blue: 0.19)
    static let gold = Color(red: 0.98, green: 0.85, blue: 0.49)
    static let attack = Color(red: 1, green: 0.02, blue: 0.32)
    static let hp = Color(red: 1, green: 0.48, blue: 0.50)
    static let parchment = Color(red: 0.96, green: 0.92, blue: 0.82)
    static func heading(_ size: CGFloat = 20) -> Font {
        .custom("HiraMinProN-W6", size: size, relativeTo: .headline)
    }
    static func inscription(_ size: CGFloat = 13) -> Font {
        .custom("Georgia-Bold", size: size, relativeTo: .subheadline)
    }
    static func number(_ value: Int) -> String { value.formatted(.number) }
    static func dateText(_ date: Date) -> String {
        date.formatted(.dateTime.year().month().day().locale(Locale(identifier: "ja_JP")))
    }
}

struct QuestButtonStyle: ButtonStyle {
    var color: Color = QuestStyle.gold
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(QuestStyle.heading(17)).foregroundStyle(.black)
            .frame(maxWidth: .infinity).padding(.vertical, 16).padding(.horizontal, 12)
            .background(LinearGradient(colors: [color, color.opacity(0.78)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(QuestStyle.parchment.opacity(0.55), lineWidth: 0.8))
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(.black.opacity(0.15), lineWidth: 0.6).padding(4))
            .shadow(color: color.opacity(0.16), radius: 10, y: 3)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

extension View {
    func questPanel() -> some View {
        background(LinearGradient(colors: [QuestStyle.field.opacity(0.97), QuestStyle.panel.opacity(0.97)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(LinearGradient(colors: [QuestStyle.gold.opacity(0.8), QuestStyle.gold.opacity(0.18), QuestStyle.gold.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
            .shadow(color: .black.opacity(0.3), radius: 8, y: 5)
    }
    func questField() -> some View {
        padding(14).background(QuestStyle.field, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(QuestStyle.gold.opacity(0.4), lineWidth: 0.6))
    }
}

/// Outline sword traced in normalized coordinates to match the supplied reference.
/// This is a vector drawing, not an SF Symbol with a different silhouette.
struct QuestSword: View {
    var body: some View {
        GeometryReader { geometry in
            Path { p in
                let w = geometry.size.width
                let h = geometry.size.height
                func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * w, y: y * h) }
                p.move(to: point(0.36, 0.58))
                p.addLine(to: point(0.75, 0.15))
                p.addLine(to: point(0.94, 0.06))
                p.addLine(to: point(0.86, 0.26))
                p.addLine(to: point(0.44, 0.67))
                p.closeSubpath()
                p.move(to: point(0.24, 0.56))
                p.addLine(to: point(0.53, 0.83))
                p.addLine(to: point(0.60, 0.76))
                p.addLine(to: point(0.31, 0.49))
                p.closeSubpath()
                p.move(to: point(0.29, 0.63))
                p.addLine(to: point(0.10, 0.83))
                p.addLine(to: point(0.18, 0.91))
                p.addLine(to: point(0.38, 0.72))
                p.move(to: point(0.15, 0.77))
                p.addLine(to: point(0.24, 0.86))
            }.stroke(style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
        }.accessibilityHidden(true)
    }
}

struct QuestHPBar: View {
    let boss: Boss
    var body: some View {
        GeometryReader { proxy in
            Capsule().fill(QuestStyle.field)
                .overlay(alignment: .leading) {
                    Capsule().fill(LinearGradient(colors: [Color(red: 0.78, green: 0.18, blue: 0.34), QuestStyle.hp], startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * (1 - boss.progress))
                        .overlay(alignment: .top) { Capsule().fill(.white.opacity(0.2)).frame(height: 2).padding(.horizontal, 3) }
                }
                .overlay(Capsule().stroke(QuestStyle.gold.opacity(0.28), lineWidth: 0.7))
        }.frame(height: 12)
            .accessibilityLabel("残りHP \(boss.remainingHP)、最大 \(boss.targetAmount)")
    }
}

struct QuestBackdrop: View {
    var body: some View {
        QuestStyle.background
            .ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct QuestSectionHeading: View {
    let title: String
    let subtitle: String
    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(QuestStyle.gold).frame(width: 5, height: 5).rotationEffect(.degrees(45))
            VStack(alignment: .leading, spacing: 4) {
                Text(subtitle).font(QuestStyle.inscription(9)).tracking(2.5).foregroundStyle(QuestStyle.gold)
                Text(title).font(QuestStyle.heading()).foregroundStyle(QuestStyle.parchment)
            }
            Rectangle().fill(LinearGradient(colors: [QuestStyle.gold.opacity(0.4), .clear], startPoint: .leading, endPoint: .trailing)).frame(height: 1)
        }.accessibilityElement(children: .combine)
    }
}
