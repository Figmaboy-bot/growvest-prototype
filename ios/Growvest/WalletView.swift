import SwiftUI

/// The investor's Wallet tab (Figma 1124-8152): available balance with the same hide
/// toggle as Home, Deposit / Withdraw, and recent transactions filtered by type.
struct WalletView: View {
    @Binding var isBalanceHidden: Bool
    @State private var filter = "All transactions"
    @State private var showsAll = false

    private static let filters = ["All transactions", "Deposits", "Withdrawals", "Investments"]
    /// How many transactions show before "See All".
    private static let previewCount = 6
    private static let balance = 215_060.80

    private var matching: [Transaction] {
        Transaction.recent.filter { filter == "All transactions" || $0.kind.filter == filter }
    }

    private var visible: [Transaction] { showsAll ? matching : Array(matching.prefix(Self.previewCount)) }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Wallet")
                    .font(AppFont.interTight(16, relativeTo: .headline))
                    .foregroundStyle(.white)
                    .frame(height: 40)
                    .accessibilityAddTraits(.isHeader)

                VStack(alignment: .leading, spacing: 28) {
                    VStack(spacing: 24) {
                        balance
                        HStack(spacing: 12) {
                            Button {} label: {
                                Label { Text("Deposit") } icon: { Image(.walletPlus) }
                            }
                            Button {} label: {
                                Label { Text("Withdraw") } icon: { Image(.walletMinus) }
                            }
                        }
                        .buttonStyle(WalletActionStyle())
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Transactions")
                                .font(AppFont.interTight(16, relativeTo: .headline))
                                .foregroundStyle(.white)
                            Spacer()
                            if matching.count > Self.previewCount {
                                Button(showsAll ? "Show Less" : "See All") {
                                    withAnimation(Motion.step) { showsAll.toggle() }
                                }
                                .font(AppFont.interTight(12, relativeTo: .caption))
                                .foregroundStyle(Color.primary50)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color.primary20))
                                .contentTransition(.opacity)
                                .transition(.opacity)
                            }
                        }

                        FilterBar(options: Self.filters, selection: $filter)

                        VStack(spacing: 8) {
                            if visible.isEmpty {
                                Text("No \(filter.lowercased()) yet.")
                                    .font(AppFont.interTight(14, relativeTo: .subheadline))
                                    .foregroundStyle(Color.grey50)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 32)
                                    .transition(.opacity)
                            }
                            ForEach(Array(visible.enumerated()), id: \.element.id) { index, transaction in
                                TransactionRow(transaction: transaction, isHidden: isBalanceHidden)
                                    .reloadEntrance(order: index)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .animation(Motion.step, value: filter)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 120)          // room to scroll past the floating tab bar
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .pullToRefresh()
        .onChange(of: filter) { showsAll = false }
    }

    private var balance: some View {
        VStack(spacing: 12) {
            Text("Available Balance")
                .font(AppFont.interTight(14, relativeTo: .subheadline))
                .foregroundStyle(Color.grey40)
            HStack(spacing: 12) {
                Text(isBalanceHidden ? "₦••••••" : Self.balance.naira)
                    .font(AppFont.interTight(40, .semibold, relativeTo: .largeTitle))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Button {
                    withAnimation(.snappy) { isBalanceHidden.toggle() }
                } label: {
                    Group {
                        if isBalanceHidden {
                            Image(.eyeOpen).resizable().frame(width: 24, height: 24)
                        } else {
                            Image(.viewOff)
                        }
                    }
                    .frame(width: 24, height: 24)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isBalanceHidden ? "Show balance" : "Hide balance")
            }
        }
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.selection, trigger: isBalanceHidden)
    }
}

/// Deposit / Withdraw: grey pills with a white icon and light grey label.
private struct WalletActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(IconTitleLabelStyle())
        .font(AppFont.interTight(16, relativeTo: .callout))
        .foregroundStyle(Color.grey20)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(Capsule().fill(Color.grey80))
        .contentShape(Capsule())
        .scaleEffect(configuration.isPressed ? 0.97 : 1)
        .opacity(configuration.isPressed ? 0.85 : 1)
        .animation(Motion.press, value: configuration.isPressed)
    }
}

private struct IconTitleLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
            configuration.title
        }
    }
}

// MARK: - Transactions

private struct Transaction: Identifiable {
    enum Kind {
        case deposit, withdrawal, investment

        /// The filter pill that shows it.
        var filter: String {
            switch self {
            case .deposit: "Deposits"
            case .withdrawal: "Withdrawals"
            case .investment: "Investments"
            }
        }

        /// Money in is green, withdrawals red, investments plain white.
        var amountColor: Color {
            switch self {
            case .deposit: .success50
            case .withdrawal: .error50
            case .investment: .white
            }
        }
    }

    let title: String
    let date: String
    let amount: Double
    let kind: Kind
    var id: String { "\(date)-\(title)" }

    var isIncoming: Bool { amount > 0 }

    /// "+₦50,000", "-₦25,000"
    var amountText: String { (isIncoming ? "+" : "-") + abs(amount).wholeNaira }

    static let recent: [Transaction] = [
        Transaction(title: "Wallet Deposit", date: "08 Oct 2026 · 10:42 AM", amount: 50_000, kind: .deposit),
        Transaction(title: "Investment in SwiftHarvest", date: "07 Oct 2026 · 02:15 PM", amount: -25_000, kind: .investment),
        Transaction(title: "Withdrawal", date: "05 Oct 2026 · 11:20 AM", amount: -10_000, kind: .withdrawal),
        Transaction(title: "Salary Payment", date: "04 Oct 2026 · 09:00 AM", amount: 100_000, kind: .deposit),
        Transaction(title: "Investment in TroveMart", date: "03 Oct 2026 · 05:30 PM", amount: -15_000, kind: .investment),
        Transaction(title: "Withdrawal", date: "02 Oct 2026 · 10:00 AM", amount: -8_000, kind: .withdrawal),
        Transaction(title: "Payout from SwiftHarvest", date: "30 Sept 2026 · 12:00 PM", amount: 2_500, kind: .deposit),
        Transaction(title: "Investment in Suji’s Fashion House", date: "26 Sept 2026 · 04:10 PM", amount: -48_000, kind: .investment),
        Transaction(title: "Wallet Deposit", date: "25 Sept 2026 · 08:55 AM", amount: 60_000, kind: .deposit),
        Transaction(title: "Investment in CoreMedix Labs", date: "18 Sept 2026 · 01:40 PM", amount: -40_000, kind: .investment),
    ]
}

private struct TransactionRow: View {
    let transaction: Transaction
    let isHidden: Bool

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(transaction.isIncoming ? .transactionIn : .transactionOut)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Color.grey80))
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.title)
                        .font(AppFont.interTight(16, relativeTo: .callout))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(transaction.date)
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        .foregroundStyle(Color.grey50)
                }
            }
            Spacer(minLength: 8)
            Text(isHidden ? "₦••••" : transaction.amountText)
                .font(AppFont.interTight(16, .semibold, relativeTo: .callout))
                .foregroundStyle(transaction.kind.amountColor)
                .contentTransition(.numericText())
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}
