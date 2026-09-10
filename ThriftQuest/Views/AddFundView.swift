import SwiftUI

struct AddFundView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GameStore

    let preselectedBossID: UUID?

    @State private var kind: AttackFundKind = .earned
    @State private var amountText = "6000"
    @State private var memo = ""
    @State private var date = Date()
    @State private var isShowingAllocation = false

    private var amount: Int {
        Int(amountText.filter(\.isNumber)) ?? 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("種類", selection: $kind) {
                        ForEach(AttackFundKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("金額") {
                    TextField("0", text: $amountText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 34, weight: .bold))
                    HStack {
                        quickAmountButton(1_000)
                        quickAmountButton(5_000)
                        quickAmountButton(10_000)
                    }
                }

                Section("メモ") {
                    TextField("例）バイト代、コンビニを我慢 など", text: $memo, axis: .vertical)
                    DatePicker("日付", selection: $date, displayedComponents: .date)
                }

                Section {
                    Button {
                        store.recordPower(kind: kind, amount: amount, memo: memo, date: date)
                        dismiss()
                    } label: {
                        Label("POWERだけ記録する", systemImage: "bolt.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(amount <= 0)

                    Button {
                        isShowingAllocation = true
                    } label: {
                        Text("攻略資金に追加")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(amount <= 0 || store.activeBosses.isEmpty)
                }
            }
            .navigationTitle("攻略資金を追加")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $isShowingAllocation) {
                AllocationView(
                    kind: kind,
                    amount: amount,
                    memo: memo,
                    preselectedBossID: preselectedBossID,
                    onFinish: {
                        dismiss()
                    }
                )
            }
        }
    }

    private func quickAmountButton(_ value: Int) -> some View {
        Button("+\(Formatters.yenText(value))") {
            amountText = "\(amount + value)"
        }
        .buttonStyle(.bordered)
    }
}
