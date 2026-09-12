import SwiftUI
import UIKit

struct BossImageView: View {
    var boss: Boss?
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [Color(red: 0.22, green: 0.29, blue: 0.32), QuestStyle.panel], startPoint: .topLeading, endPoint: .bottomTrailing))

            if let imageData = boss?.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let imageURL = boss?.imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "shippingbox")
                        .font(.system(size: size * 0.34, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            } else {
                Circle().stroke(QuestStyle.gold.opacity(0.20), lineWidth: 0.7).padding(size * 0.15)
                Circle().stroke(QuestStyle.gold.opacity(0.12), lineWidth: 0.5).padding(size * 0.22)
                Image(systemName: iconName)
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundStyle(QuestStyle.gold.opacity(0.85))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(QuestStyle.gold.opacity(0.4), lineWidth: 0.8))
    }

    private var iconName: String {
        guard let category = boss?.category else { return "shippingbox" }
        if category.contains("イベント") { return "ticket" }
        if category.contains("大型") { return "airplane" }
        if category.contains("共有") { return "link" }
        return "shoeprints.fill"
    }
}
