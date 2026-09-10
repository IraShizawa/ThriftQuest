import Foundation

enum Formatters {
    static let yen: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static func yenText(_ amount: Int) -> String {
        "\(yen.string(from: NSNumber(value: amount)) ?? "\(amount)")円"
    }

    static func hpText(_ amount: Int) -> String {
        "\(yen.string(from: NSNumber(value: amount)) ?? "\(amount)") HP"
    }
}
