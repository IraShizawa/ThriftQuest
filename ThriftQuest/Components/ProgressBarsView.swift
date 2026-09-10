import SwiftUI

struct ProgressBarsView: View {
    let boss: Boss

    var body: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("貯金額")
                    Spacer()
                    Text("\(Formatters.yenText(boss.savedAmount)) / \(Formatters.yenText(boss.targetAmount))")
                        .fontWeight(.semibold)
                }
                ProgressView(value: boss.progress)
                    .tint(.mint)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("BOSS HP（残り）")
                    Spacer()
                    Text(Formatters.hpText(boss.remainingHP))
                        .fontWeight(.semibold)
                }
                ProgressView(value: 1 - boss.progress)
                    .tint(.red)
            }
        }
        .font(.caption)
    }
}
