import SwiftUI
import UIKit

struct BossImageView: View {
    var boss: Boss?
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [.orange.opacity(0.18), .blue.opacity(0.16), .mint.opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

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
                Image(systemName: iconName)
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.75))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var iconName: String {
        guard let category = boss?.category else { return "shippingbox" }
        if category.contains("イベント") { return "ticket" }
        if category.contains("大型") { return "airplane" }
        if category.contains("共有") { return "link" }
        return "shoeprints.fill"
    }
}
