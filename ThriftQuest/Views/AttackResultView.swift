import SwiftUI

struct AttackResultView: View {
    @EnvironmentObject private var store: GameStore
    let result: AttackResult
    var onFinish: () -> Void = {}

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "burst.fill")
                .font(.system(size: 72))
                .foregroundStyle(.yellow)

            VStack(spacing: 8) {
                Text("攻撃がヒットした！")
                    .font(.title.bold())
                Text("\(Formatters.yenText(result.totalDamage)) DAMAGE")
                    .font(.title2.bold())
                    .foregroundStyle(.red)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(result.allocations) { allocation in
                    HStack {
                        Text(store.bossName(for: allocation.bossID))
                        Spacer()
                        Text("+\(Formatters.yenText(allocation.amount))")
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Spacer()

            Button("ホームへ") {
                onFinish()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("攻撃結果")
        .navigationBarTitleDisplayMode(.inline)
    }
}
