import SwiftUI

struct MyPageView: View {
    @EnvironmentObject private var store: GameStore

    private var totalSaved: Int {
        store.bosses.reduce(0) { $0 + $1.savedAmount }
    }

    private var totalTarget: Int {
        store.bosses.reduce(0) { $0 + $1.targetAmount }
    }

    private var totalDamage: Int {
        store.attackResults.reduce(0) { $0 + $1.totalDamage }
    }

    private var defeatedCount: Int {
        store.bosses.filter(\.isDefeated).count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(.red)
                        Text("冒険者")
                            .font(.title.bold())
                        Text("欲しいものを倒して、なりたい自分に近づく。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        smallStat(title: "総貯金", value: Formatters.yenText(totalSaved), icon: "banknote.fill")
                        smallStat(title: "総目標", value: Formatters.yenText(totalTarget), icon: "flag.fill")
                        smallStat(title: "総ダメージ", value: Formatters.yenText(totalDamage), icon: "bolt.fill")
                        smallStat(title: "撃破ボス", value: "\(defeatedCount)体", icon: "crown.fill")
                    }

                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("マイページ")
        }
    }

    private func smallStat(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.red)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
