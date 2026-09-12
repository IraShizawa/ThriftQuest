import SwiftUI

struct AddFundView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GameStore
    let preselectedBossID: UUID?
    @State private var kind: AttackFundKind = .earned
    @State private var amountText = ""
    @State private var memo = ""
    @State private var date = Date()
    @State private var saved = false
    private var amount: Int { Int(amountText) ?? 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Picker("POWERの種類", selection: $kind) {
                        Text("稼いだPOWER").tag(AttackFundKind.earned)
                        Text("守ったPOWER").tag(AttackFundKind.resisted)
                    }.pickerStyle(.segmented)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 78)).foregroundStyle(.yellow)
                        .shadow(color: .orange.opacity(0.4), radius: 5)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                    HStack {
                        Text("POWER").font(.title3)
                        Text("+").foregroundStyle(QuestStyle.gold)
                        TextField("0000", text: $amountText)
                            .keyboardType(.numberPad).foregroundStyle(QuestStyle.gold)
                            .font(.title2).monospacedDigit()
                            .accessibilityLabel("新しく確保した金額、円")
                            .onChange(of: amountText) { _, text in
                                amountText = String(text.filter { $0.isASCII && $0.isNumber }.prefix(7))
                            }
                    }.questField()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("メモ").font(.subheadline)
                        TextField("例：コンビニで使わずに済んだ分", text: $memo, axis: .vertical)
                            .lineLimit(4...6).questField()
                    }
                    DatePicker("日付", selection: $date, in: ...Date(), displayedComponents: .date)
                        .font(.subheadline)
                    Text("今回、新しく目標用に確保した金額を記録。同じお金は一度だけ。")
                        .font(.caption).foregroundStyle(.secondary)
                    Button {
                        guard !saved, amount > 0 else { return }
                        saved = true
                        store.recordPower(kind: kind, amount: amount, memo: memo, date: date)
                        dismiss()
                    } label: {
                        Label("追加する", systemImage: "dollarsign.circle")
                    }.buttonStyle(QuestButtonStyle())
                        .disabled(amount <= 0 || saved).opacity(amount > 0 ? 1 : 0.5)
                }.padding(28)
            }.background(QuestBackdrop())
                .navigationTitle("POWER追加").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("閉じる") { dismiss() } } }
        }
    }
}
