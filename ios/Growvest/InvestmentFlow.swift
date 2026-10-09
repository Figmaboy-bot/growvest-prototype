import Foundation
import Observation
import SwiftUI

struct Business {
    let name: String
    let tags: [String]
    let currentValue: Double
    let pricePerShare: Double
    var logo: ImageResource = .businessLogo

    static let swiftHarvest = Business(
        name: "SwiftHarvest Ventures",
        tags: ["AgriTech", "Farming", "AI"],
        currentValue: 45_162.77,
        pricePerShare: 62.99
    )
}

/// The shares the user already holds, which the sell flow sells from.
struct Holding {
    let shares: Int
    let pricePerShare: Double

    static let swiftHarvest = Holding(shares: 40, pricePerShare: 2_500)
}

/// Which way the trade goes. Both share one flow; only copy, pricing and limits differ.
enum TradeKind {
    case buy, sell
}

enum PaymentMethod: String, CaseIterable, Identifiable {
    case bank, card

    var id: String { rawValue }

    var name: String {
        switch self {
        case .bank: "Bank Account"
        case .card: "Master Card"
        }
    }

    var maskedNumber: String {
        switch self {
        case .bank: "**** **** 4821"
        case .card: "**** **** **** 4821"
        }
    }

    var icon: ImageResource {
        switch self {
        case .bank: .bank
        case .card: .creditCard
        }
    }
}

/// State for the whole buy or sell flow: amount entry → payment method (or destination)
/// → review → PIN → success.
@Observable
final class InvestmentFlow {
    let kind: TradeKind

    init(kind: TradeKind = .buy, business: Business = .swiftHarvest, holding: Holding = .swiftHarvest) {
        self.kind = kind
        self.business = business
        self.holding = holding
    }

    enum Step: Hashable {
        case payment, review, pin, success
    }

    static let quickAmounts: [(label: String, value: Double)] = [
        ("₦10K", 10_000), ("₦50K", 50_000), ("₦100K", 100_000), ("₦500K", 500_000),
    ]
    /// Quick picks while entering shares (Figma "Frame 1618874416").
    static let quickShares = [5, 10, 50, 100]

    let business: Business
    let holding: Holding

    var isSelling: Bool { kind == .sell }
    var pricePerShare: Double { isSelling ? holding.pricePerShare : business.pricePerShare }

    /// What the keypad is entering: a naira amount, or a number of shares.
    /// Tapping the pill under the big number switches between the two.
    enum InputMode {
        case amount, shares
    }

    private(set) var inputMode: InputMode = .amount
    /// The amount exactly as typed on the keypad, e.g. "4500.5" (amount mode).
    private(set) var typedAmount = ""
    /// Whole shares as typed on the keypad, e.g. "120" (shares mode).
    private(set) var typedShares = ""
    var paymentMethod: PaymentMethod? = .card
    /// Sell review: "I understand that selling these shares may affect my investment returns."
    var hasAcknowledgedSaleRisk = false
    var sheetStep: Step?
    /// 0 while the sheet is at rest, rising towards 1 as it is dragged down to dismiss.
    /// Drives the backdrop so it fades with the finger.
    var sheetDragProgress: Double = 0
    private(set) var completedAt = Date()

    /// The text currently being typed, whichever mode is active.
    var typedInput: String { inputMode == .amount ? typedAmount : typedShares }

    var amount: Double {
        switch inputMode {
        case .amount: Double(typedAmount) ?? 0
        case .shares: Double(shares) * pricePerShare
        }
    }

    /// What the sale pays out: only whole shares can be sold, so it's shares × price.
    var saleValue: Double { Double(shares) * pricePerShare }

    /// Selling more shares than the user holds.
    var exceedsHolding: Bool { isSelling && shares > holding.shares }

    var shares: Int {
        switch inputMode {
        case .amount: wholeShares(for: amount)
        case .shares: Int(typedShares) ?? 0
        }
    }

    var canContinue: Bool {
        isSelling ? (shares > 0 && !exceedsHolding) : amount > 0
    }

    func press(_ key: String) {
        switch inputMode {
        case .amount: typedAmount = Self.apply(key, to: typedAmount)
        case .shares:
            // Whole shares only, up to 99,999,999,999 (keeps the cost within the amount limit).
            if key == "." { return }
            if key != "back", typedShares.count >= 11 { return }
            typedShares = key == "back" ? String(typedShares.dropLast())
                : (typedShares == "0" ? key : typedShares + key)
        }
    }

    private static func apply(_ key: String, to typed: String) -> String {
        switch key {
        case "back":
            return String(typed.dropLast())
        case ".":
            return typed.contains(".") ? typed : (typed.isEmpty ? "0" : typed) + "."
        default:
            let parts = typed.split(separator: ".", omittingEmptySubsequences: false)
            if parts.count > 1, parts[1].count >= 2 { return typed }        // max 2 decimals
            // Up to ₦9,999,999,999,999 — beyond 13 digits Double arithmetic starts losing the kobo.
            if parts.count == 1, parts[0].count >= 13 { return typed }
            return typed == "0" ? key : typed + key
        }
    }

    /// Whole shares an amount buys. The tiny epsilon stops floating-point error
    /// (e.g. 45,100.84 / 62.99 = 715.9999…) from dropping a share.
    private func wholeShares(for value: Double) -> Int {
        Int((value / pricePerShare + 1e-9).rounded(.down))
    }

    /// Labels for the four quick-pick chips in the current mode.
    var quickPickLabels: [String] {
        switch inputMode {
        case .amount: Self.quickAmounts.map(\.label)
        case .shares: Self.quickShares.map(String.init)
        }
    }

    /// Quick-pick chips: a naira amount, or a number of shares in shares mode.
    func selectQuickPick(_ index: Int) {
        switch inputMode {
        case .amount: typedAmount = String(Int(Self.quickAmounts[index].value))
        case .shares: typedShares = String(Self.quickShares[index])
        }
    }

    func isQuickPickSelected(_ index: Int) -> Bool {
        switch inputMode {
        case .amount: amount == Self.quickAmounts[index].value
        case .shares: shares == Self.quickShares[index]
        }
    }

    /// Switches between entering naira and entering shares, carrying the value across.
    func toggleInputMode() {
        switch inputMode {
        case .amount:
            typedShares = shares > 0 ? String(shares) : ""
            inputMode = .shares
        case .shares:
            let cost = amount
            typedAmount = cost > 0 ? String(format: "%.2f", cost) : ""
            inputMode = .amount
        }
    }

    func complete() {
        completedAt = Date()
        sheetStep = .success
    }

    func reset() {
        sheetStep = nil
        typedAmount = ""
        typedShares = ""
        inputMode = .amount
        hasAcknowledgedSaleRisk = false
    }
}

extension Double {
    /// "₦45,162.77"
    var naira: String {
        "₦" + formatted(.number.precision(.fractionLength(2)).locale(Locale(identifier: "en_US")))
    }
}

extension Double {
    /// "₦2,500" — no kobo, for round prices like the sell flow's share price.
    var wholeNaira: String {
        "₦" + formatted(.number.precision(.fractionLength(0)).locale(Locale(identifier: "en_US")))
    }
}

extension Date {
    /// "12:21 PM · 04 Oct 2026"
    var investmentTimestamp: String {
        let time = formatted(.dateTime.hour().minute().locale(Locale(identifier: "en_US")))
        let day = formatted(.dateTime.day(.twoDigits).month(.abbreviated).year().locale(Locale(identifier: "en_GB")))
        return "\(time) · \(day)"
    }
}
