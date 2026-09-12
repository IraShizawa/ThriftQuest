import SwiftUI

struct BossCardView: View {
    let boss: Boss
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                BossImageView(boss: boss, size: 58)

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(boss.name)
                            .font(.headline)
                        Spacer()
                        Text(boss.category)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                    }

                    Text("目標金額 \(Formatters.yenText(boss.targetAmount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ProgressBarsView(boss: boss)

            HStack {
                Text("残りHP \(Formatters.yenText(boss.remainingHP))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: action) {
                    Label("攻撃する", systemImage: "figure.fencing")
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
            }
        }
        .padding()
        .background(Color(red: 0.16, green: 0.15, blue: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.secondary.opacity(0.18))
        }
    }
}
