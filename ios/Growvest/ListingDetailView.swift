import SwiftUI

/// A business owner's own listing ("About Listing"), opened from Your Listings on the
/// business dashboard. Everything is in shares: while the offer is open the top card shows
/// shares sold; once it's sold out the shares trade between investors through Growvest, so
/// the card shows the share price instead.
///
/// Investors are anonymous to the business: the Investors tab only ever shows totals, and
/// hides any holding-size group with fewer than five investors so no one can be singled out.
///
/// Every month end the business uploads a monthly report (accounts, bank statement, tax
/// returns, sales and payroll). Growvest works out investors' payouts from these reports
/// and holds payouts while one is missing.

// MARK: - Data

struct OwnerListing: Identifiable {
    struct Market {
        let price: Double
        /// Percent change over the past week.
        let change: Double
        /// Shares that changed hands between investors this month.
        let resoldThisMonth: Int
    }

    struct Investors {
        let count: Int
        let newThisWeek: Int
        let sharesBoughtThisWeek: Int
        let largestHolding: Int
        /// Investors per holding size: "1–10 shares", "11–50 shares", …
        let bands: [(label: String, count: Int)]
    }

    struct Payout: Identifiable {
        let date: String
        let perShare: Double
        var id: String { date }
    }

    struct Update: Identifiable {
        let category: String
        let date: String
        let title: String
        let message: String
        var id: String { title }
    }

    struct Document: Identifiable {
        let name: String
        let size: String
        var id: String { name }
    }

    let name: String
    let logo: ImageResource
    let pricePerShare: Double
    let sharesOffered: Int
    let sharesSold: Int
    /// Percent of the company the offer sells.
    let equityOffered: Double
    let closing: String
    /// Set once the offer has sold out and the shares trade.
    var market: Market?
    let investors: Investors
    var nextPayout: Payout?
    var pastPayouts: [Payout] = []
    let useOfFunds: [(label: String, percent: Int)]
    let updates: [Update]
    let documents: [Document]

    var id: String { name }
    var raised: Double { Double(sharesSold) * pricePerShare }
    var goal: Double { Double(sharesOffered) * pricePerShare }
    var progress: Double { min(Double(sharesSold) / Double(sharesOffered), 1) }
    var isFullyRaised: Bool { sharesSold >= sharesOffered }
    var valuation: Double { goal / (equityOffered / 100) }
    var company: Company? { Company.named(name) }

    static func named(_ name: String) -> OwnerListing? { all.first { $0.name == name } }

    private static let bands = ["1–50 shares", "51–250 shares", "251–1,000 shares", "1,000+ shares"]

    static let all: [OwnerListing] = [
        OwnerListing(
            name: "SafeBond Finance", logo: .logoSafeBond, pricePerShare: 100, sharesOffered: 50_000, sharesSold: 30_000,
            equityOffered: 12.5, closing: "In 25 days",
            investors: Investors(count: 142, newThisWeek: 12, sharesBoughtThisWeek: 3_200, largestHolding: 1_200,
                                 bands: zip(bands, [58, 54, 27, 3]).map { ($0, $1) }),
            useOfFunds: [("Licensing & compliance", 40), ("Product", 35), ("Customer acquisition", 25)],
            updates: [
                Update(category: "Offer Progress", date: "8 Oct", title: "30,000 shares sold",
                       message: "We’re 60% of the way through the offer. Thank you to everyone who has invested."),
                Update(category: "Product Update", date: "1 Oct", title: "Same-day withdrawals launched",
                       message: "Businesses can now withdraw their savings the same day they ask."),
                Update(category: "Growth", date: "20 Sep", title: "200 businesses saving with SafeBond",
                       message: "We doubled our active savers this quarter."),
            ],
            documents: [Document(name: "Pitch Deck", size: "6.9 MB"),
                        Document(name: "Financial Statements 2025", size: "2.4 MB"),
                        Document(name: "Shareholder Agreement", size: "1.1 MB")]
        ),
        OwnerListing(
            name: "CapitalSpring Ltd.", logo: .logoCapitalSpring, pricePerShare: 50, sharesOffered: 100_000, sharesSold: 13_000,
            equityOffered: 10, closing: "In 41 days",
            investors: Investors(count: 31, newThisWeek: 3, sharesBoughtThisWeek: 900, largestHolding: 1_500,
                                 bands: zip(bands, [12, 9, 8, 2]).map { ($0, $1) }),
            useOfFunds: [("Cold rooms", 55), ("Energy systems", 30), ("Working capital", 15)],
            updates: [
                Update(category: "Milestone", date: "28 Sep", title: "First cold room running in Kano",
                       message: "Our first geothermal cold room is storing tomatoes for 40 farmers."),
            ],
            documents: [Document(name: "Pitch Deck", size: "5.2 MB"),
                        Document(name: "Shareholder Agreement", size: "1.1 MB")]
        ),
        OwnerListing(
            name: "StitchWorks Atelier", logo: .logoSewing52, pricePerShare: 200, sharesOffered: 25_000, sharesSold: 25_000,
            equityOffered: 20, closing: "Sold out 2 Aug 2026",
            market: Market(price: 224, change: 1.4, resoldThisMonth: 1_600),
            investors: Investors(count: 210, newThisWeek: 6, sharesBoughtThisWeek: 425, largestHolding: 750,
                                 bands: zip(bands, [96, 78, 33, 3]).map { ($0, $1) }),
            nextPayout: Payout(date: "15 Oct 2026", perShare: 3),
            pastPayouts: [Payout(date: "15 Jul 2026", perShare: 2.40), Payout(date: "15 Apr 2026", perShare: 2)],
            useOfFunds: [("Machinery", 60), ("Staff training", 25), ("Working capital", 15)],
            updates: [
                Update(category: "Payout", date: "15 Jul", title: "Q2 payout sent",
                       message: "₦2.40 per share went out to every shareholder."),
                Update(category: "Growth", date: "2 Jul", title: "Three new labels signed",
                       message: "Our order book is full until December."),
                Update(category: "Offer Progress", date: "2 Aug", title: "Offer sold out",
                       message: "All 25,000 shares are sold. Shares can now be bought and sold between investors."),
            ],
            documents: [Document(name: "Pitch Deck", size: "4.8 MB"),
                        Document(name: "Financial Statements 2025", size: "2.1 MB"),
                        Document(name: "Q2 2026 Report", size: "0.9 MB")]
        ),
    ]
}

// MARK: - Monthly report

/// The documents a listed business uploads at the end of every month.
enum ReportDocument: String, CaseIterable, Identifiable {
    case accounts, bankStatement, taxReturns, salesPayroll
    var id: Self { self }

    var title: String {
        switch self {
        case .accounts: "Profit & Loss Statement"
        case .bankStatement: "Bank Statements"
        case .taxReturns: "Tax Returns"
        case .salesPayroll: "Sales & Payroll Records"
        }
    }

    var about: String {
        switch self {
        case .accounts: "Income and expenses for the month"
        case .bankStatement: "Every business account, for the whole month"
        case .taxReturns: "VAT and PAYE returns filed for the month, with payment receipts"
        case .salesPayroll: "Invoices, sales records and the month’s payroll"
        }
    }
}

enum MonthlyReport {
    /// The month being reported on: the current one, due on its last day.
    static var month: String { Date.now.formatted(.dateTime.month(.wide).locale(Locale(identifier: "en_GB"))) }
    static var monthAndYear: String { Date.now.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "en_GB"))) }

    static var dueDate: Date {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .month, for: .now)?.end ?? .now
        return calendar.date(byAdding: .day, value: -1, to: start) ?? .now
    }

    static var dueText: String { dueDate.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "en_GB"))) }

    static var daysLeft: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: .now), to: calendar.startOfDay(for: dueDate)).day ?? 0
    }

    /// The last three months' reports, newest first.
    static var history: [String] {
        (1...3).compactMap { back in
            Calendar.current.date(byAdding: .month, value: -back, to: .now)?
                .formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "en_GB")))
        }
    }

    /// "Jul–Sep": the months the next payout is worked out from.
    static var payoutBasis: String {
        let months = (1...3).reversed().compactMap { Calendar.current.date(byAdding: .month, value: -$0, to: .now) }
        let format = Date.FormatStyle.dateTime.month(.abbreviated).locale(Locale(identifier: "en_GB"))
        guard let first = months.first, let last = months.last else { return "" }
        return "\(first.formatted(format))–\(last.formatted(format))"
    }
}

// MARK: - Screen

struct ListingDetailView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case overview = "Overview", investors = "Investors", updates = "Updates", documents = "Documents"
        var id: Self { self }
    }

    let listing: OwnerListing
    @State private var tab: Tab = .overview
    @State private var range: ChartRange = .month
    @State private var notice: String?
    @State private var report: [ReportDocument: DocumentUpload] = [:]
    @State private var isReportSubmitted = false
    @Namespace private var pill
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollViewReader { scroller in
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                if !isReportSubmitted {
                    ReportDueBanner {
                        // Once the Documents tab has swapped in, bring this month's report into view.
                        withAnimation(Motion.step) { tab = .documents } completion: {
                            withAnimation(Motion.step) { scroller.scrollTo(DocumentsTab.reportID, anchor: .top) }
                        }
                    }
                }
                if let market = listing.market {
                    marketCard(market)
                } else {
                    offeringCard
                }
                InfoSection(title: "Offer Terms") {
                    InfoRow(label: "Offer price") { value(listing.pricePerShare.wholeNaira + " / share") }
                    InfoRow(label: "Shares offered") { value(listing.sharesOffered.grouped) }
                    InfoRow(label: "Equity offered") { value(listing.equityOffered.percentText) }
                    InfoRow(label: "Valuation at offer") { value(listing.valuation.shortNaira) }
                    InfoRow(label: listing.isFullyRaised ? "Offer" : "Offer closes") { value(listing.closing) }
                    InfoRow(label: "Payouts") { value("Quarterly, from profit") }
                    InfoRow(label: "Reports") { value("Monthly, by month end") }
                }

                VStack(alignment: .leading, spacing: 24) {
                    tabPicker
                        .id("tabs")
                    Group {
                        switch tab {
                        case .overview: OverviewTab(listing: listing)
                        case .investors: InvestorsTab(listing: listing, notice: $notice)
                        case .updates: UpdatesTab(listing: listing, notice: $notice)
                        case .documents: DocumentsTab(listing: listing, report: $report,
                                                      isReportSubmitted: $isReportSubmitted, notice: $notice)
                        }
                    }
                    .id(tab)
                    // Swapped, not cross-faded: two tabs stacked mid-fade would throw off
                    // the scroll to this month's report.
                    .transition(.identity)
                }
                .animation(Motion.step, value: tab)
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)
            .padding(.bottom, 32)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        #if DEBUG
        .onAppear {
            let defaults = UserDefaults.standard
            // -demoReport uploaded | submitted: this month's report filled in, or already sent.
            switch defaults.string(forKey: "demoReport") {
            case "uploaded", "submitted":
                for kind in ReportDocument.allCases {
                    report[kind] = DocumentUpload(fileName: "\(kind.title).pdf", byteCount: 262_144, progress: 1)
                }
                isReportSubmitted = defaults.string(forKey: "demoReport") == "submitted"
            default: break
            }
            // -demoListingTab investors: opens that tab, scrolled to it (Documents: to the report).
            if let demo = defaults.string(forKey: "demoListingTab"), let match = Tab(rawValue: demo.capitalized) {
                tab = match
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(900))
                    withAnimation(Motion.step) {
                        scroller.scrollTo(match == .documents ? DocumentsTab.reportID : "tabs", anchor: .top)
                    }
                }
            }
        }
        #endif
        }
        .background(Color(.systemBackground))
        .homeScreenChrome(title: "About Listing", onBack: { dismiss() }) {
            Menu {
                Button("Edit Listing") { notice = "Editing listings is coming soon." }
                Button("Share Listing") { notice = "Sharing listings is coming soon." }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.grey80))
            }
            .accessibilityLabel("More")
        }
        .alert(notice ?? "", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
            Button("OK", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(listing.logo)
                    .resizable()
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 6) {
                    Text(listing.name)
                        .font(AppFont.interTight(20, relativeTo: .title3))
                        .foregroundStyle(.white)
                    StatusPill(isTrading: listing.market != nil)
                }
            }
            if let company = listing.company {
                Text(company.tagline)
                    .font(AppFont.interTight(14, relativeTo: .subheadline))
                    .foregroundStyle(Color.grey50)
                HStack(spacing: 4) {
                    ForEach(company.tags, id: \.self) { tag in
                        Text(tag)
                            .font(AppFont.interTight(12, relativeTo: .caption))
                            .foregroundStyle(Color.grey50)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.grey80))
                    }
                }
            }
        }
    }

    /// While the offer is open: shares sold out of shares offered.
    private var offeringCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share Offering")
                .font(AppFont.interTight(16, relativeTo: .headline))
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(listing.sharesSold.grouped)
                        .font(AppFont.interTight(28, .semibold, relativeTo: .title))
                        .foregroundStyle(.white)
                    + Text(" of \(listing.sharesOffered.grouped) shares sold")
                        .font(AppFont.interTight(14, relativeTo: .subheadline))
                        .foregroundStyle(Color.grey50)
                    Spacer(minLength: 8)
                    Text("\(Int((listing.progress * 100).rounded()))%")
                        .font(AppFont.interTight(16, .semibold, relativeTo: .callout))
                        .foregroundStyle(Color.primary50)
                }
                ProgressBar(progress: listing.progress, tint: .primary50)
                Text("\(listing.pricePerShare.wholeNaira) per share · \(listing.raised.shortNaira) of \(listing.goal.shortNaira) raised")
                    .font(AppFont.interTight(12, relativeTo: .caption))
                    .foregroundStyle(Color.grey50)
            }
            .padding(16)
            .background(Color.grey80, in: .rect(cornerRadius: 24))
            .accessibilityElement(children: .combine)
        }
    }

    /// Once sold out: what investors are paying for a share now.
    private func marketCard(_ market: OwnerListing.Market) -> some View {
        let sinceOffer = (market.price - listing.pricePerShare) / listing.pricePerShare * 100
        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Share Price")
                    .font(AppFont.interTight(14, relativeTo: .subheadline))
                    .foregroundStyle(Color.grey50)
                HStack(spacing: 8) {
                    Text(market.price.wholeNaira)
                        .font(AppFont.interTight(36, .semibold, relativeTo: .largeTitle))
                        .tracking(-0.72)
                        .foregroundStyle(.white)
                    ChangeBadge(text: market.change.magnitudeText, isUp: market.change >= 0, size: .small)
                }
                Text("\(sinceOffer >= 0 ? "Up" : "Down") \(abs(sinceOffer).percentText) from the \(listing.pricePerShare.wholeNaira) offer price · \(market.resoldThisMonth.grouped) shares changed hands this month")
                    .font(AppFont.interTight(12, relativeTo: .caption))
                    .foregroundStyle(Color.grey50)
            }
            PriceChart(source: ChartSource(seed: listing.name, price: market.price, change: market.change), range: $range)
        }
    }

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { option in
                let isSelected = option == tab
                Button {
                    withAnimation(Motion.step) { tab = option }
                } label: {
                    Text(option.rawValue)
                        .font(AppFont.interTight(13, relativeTo: .subheadline))
                        .foregroundStyle(isSelected ? .black : Color.grey50)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background {
                            if isSelected {
                                Capsule().fill(Color.primary50)
                                    .matchedGeometryEffect(id: "tab", in: pill)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Capsule().fill(Color.grey80))
        .sensoryFeedback(.selection, trigger: tab)
    }

    private func value(_ text: String) -> some View {
        Text(text)
            .font(AppFont.interTight(14, relativeTo: .subheadline))
            .foregroundStyle(.white)
    }
}

// MARK: - Tabs

private struct OverviewTab: View {
    let listing: OwnerListing

    private static let colors: [Color] = [.primary50, .success50, .warning50, .chartBlue]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let company = listing.company {
                OverviewBlock(label: "What they do", lines: [company.about])
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Use of Funds")
                    .font(AppFont.interTight(14, relativeTo: .subheadline))
                    .foregroundStyle(Color.grey50)
                // One bar split by share of the raise, then each line with its naira amount.
                GeometryReader { proxy in
                    HStack(spacing: 3) {
                        ForEach(Array(listing.useOfFunds.enumerated()), id: \.offset) { index, item in
                            Capsule()
                                .fill(Self.colors[index % Self.colors.count])
                                .frame(width: max((proxy.size.width - 3 * CGFloat(listing.useOfFunds.count - 1)) * CGFloat(item.percent) / 100, 0))
                        }
                    }
                }
                .frame(height: 10)
                .accessibilityHidden(true)

                VStack(spacing: 0) {
                    ForEach(Array(listing.useOfFunds.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: 10) {
                            Circle().fill(Self.colors[index % Self.colors.count]).frame(width: 8, height: 8)
                            Text(item.label).foregroundStyle(.white)
                            Spacer(minLength: 8)
                            Text((listing.goal * Double(item.percent) / 100).shortNaira).foregroundStyle(.white)
                            Text("\(item.percent)%")
                                .foregroundStyle(Color.grey50)
                                .frame(width: 40, alignment: .trailing)
                        }
                        .font(AppFont.interTight(14, relativeTo: .subheadline))
                        .padding(.vertical, 8)
                        .accessibilityElement(children: .combine)
                    }
                }
            }

            if let company = listing.company {
                OverviewBlock(label: "Team", lines: company.team)
            }
        }
    }
}

private struct InvestorsTab: View {
    let listing: OwnerListing
    @Binding var notice: String?

    /// Smaller groups than this are shown as "Fewer than 5" so no investor can be singled out.
    private static let minimumGroup = 5

    private var investors: OwnerListing.Investors { listing.investors }
    private var sharesHeld: Int { listing.sharesSold }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.primary50)
                Text("Your investors are anonymous. Growvest verifies every one of them; you see totals only.")
                    .font(AppFont.interTight(12, relativeTo: .caption))
                    .foregroundStyle(Color.grey40)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(Color.primary20.opacity(0.5), in: .rect(cornerRadius: 20))

            SummaryCard(rows: [
                ("Investors", investors.count.grouped),
                ("Shares held", sharesHeld.grouped),
                ("Average holding", "\(sharesHeld / max(investors.count, 1)) shares"),
                ("Largest single holding", "\((Double(investors.largestHolding) / Double(sharesHeld) * 100).percentText) of shares"),
                listing.market.map { ("Resold this month", "\($0.resoldThisMonth.grouped) shares") }
                    ?? ("This week", "+\(investors.newThisWeek) investors · +\(investors.sharesBoughtThisWeek.grouped) shares"),
            ])

            holdingSizes

            payouts
        }
    }

    private var holdingSizes: some View {
        let largest = investors.bands.map(\.count).max() ?? 1
        return LabeledSection(title: "Holding sizes") {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(investors.bands, id: \.label) { band in
                    let isHidden = band.count < Self.minimumGroup
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(band.label).foregroundStyle(.white)
                            Spacer()
                            Text(isHidden ? "Fewer than \(Self.minimumGroup)" : "\(band.count) investors")
                                .foregroundStyle(isHidden ? Color.grey50 : .white)
                        }
                        .font(AppFont.interTight(14, relativeTo: .subheadline))
                        ProgressBar(progress: isHidden ? 0.03 : Double(band.count) / Double(largest),
                                    tint: isHidden ? .grey60 : .primary50)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(16)
            .background(Color.grey80, in: .rect(cornerRadius: 24))
        }
    }

    @ViewBuilder
    private var payouts: some View {
        LabeledSection(title: "Payouts") {
            if let next = listing.nextPayout {
                let total = next.perShare * Double(sharesHeld)
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Next payout · \(next.date)")
                            .font(AppFont.interTight(12, relativeTo: .caption))
                            .foregroundStyle(Color.primary50)
                        Text(total.wholeNaira + " due")
                            .font(AppFont.interTight(24, .semibold, relativeTo: .title2))
                            .foregroundStyle(.white)
                        Text("\(next.perShare.naira) per share × \(sharesHeld.grouped) shares · worked out from your \(MonthlyReport.payoutBasis) reports")
                            .font(AppFont.interTight(12, relativeTo: .caption))
                            .foregroundStyle(Color.grey50)
                    }
                    Button("Pay into Growvest") {
                        notice = "Growvest splits the \(total.wholeNaira) among your investors, so you never need their account details."
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(16)
                .background(Color.grey80, in: .rect(cornerRadius: 24))

                if !listing.pastPayouts.isEmpty {
                    SummaryCard(rows: listing.pastPayouts.map { payout in
                        (payout.date, "\(payout.perShare.naira)/share · \((payout.perShare * Double(sharesHeld)).wholeNaira)")
                    })
                }
            } else {
                Text("Payouts start once the offer closes. Each quarter Growvest works out what investors are owed from your monthly reports; you pay one total into Growvest, and Growvest splits it among your investors.")
                    .font(AppFont.interTight(14, relativeTo: .subheadline))
                    .foregroundStyle(Color.grey50)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.grey80, in: .rect(cornerRadius: 24))
            }
        }
    }
}

private struct UpdatesTab: View {
    let listing: OwnerListing
    @Binding var notice: String?

    var body: some View {
        VStack(spacing: 8) {
            ForEach(listing.updates) { update in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(update.category).foregroundStyle(Color.primary50)
                        Spacer()
                        Text(update.date).foregroundStyle(Color.grey50)
                    }
                    .font(AppFont.interTight(12, relativeTo: .caption))
                    Text(update.title)
                        .font(AppFont.interTight(16, relativeTo: .callout))
                        .foregroundStyle(.white)
                    Text(update.message)
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        .foregroundStyle(Color.grey50)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.grey80, in: .rect(cornerRadius: 24))
                .accessibilityElement(children: .combine)
            }

            Text("Updates go to every shareholder.")
                .font(AppFont.interTight(12, relativeTo: .caption))
                .foregroundStyle(Color.grey50)
                .padding(.top, 8)

            Button("Post New Update") { notice = "Posting updates is coming soon." }
                .buttonStyle(PrimaryButtonStyle())
        }
    }
}

private struct DocumentsTab: View {
    let listing: OwnerListing
    @Binding var report: [ReportDocument: DocumentUpload]
    @Binding var isReportSubmitted: Bool
    @Binding var notice: String?

    static let reportID = "monthlyReport"

    private var uploadedCount: Int { ReportDocument.allCases.filter { report[$0]?.isComplete == true }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            monthlyReport

            LabeledSection(title: "Past reports") {
                SummaryCard(rows: MonthlyReport.history.map { ($0, "Approved") })
            }

            LabeledSection(title: "Listing documents") {
                VStack(spacing: 8) {
                    ForEach(listing.documents) { document in
                        documentRow(document)
                    }
                    Button("Upload New Document") { notice = "Uploading documents is coming soon." }
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.top, 8)
                }
            }
        }
    }

    /// This month's report: one upload card per document, then Submit once all are in.
    @ViewBuilder
    private var monthlyReport: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(MonthlyReport.monthAndYear) Report")
                        .font(AppFont.interTight(16, relativeTo: .headline))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(isReportSubmitted ? "Submitted" : "\(uploadedCount) of \(ReportDocument.allCases.count) uploaded")
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        .foregroundStyle(isReportSubmitted ? Color.success50 : Color.grey50)
                        .contentTransition(.numericText())
                }
                Text("Upload these by \(MonthlyReport.dueText), the last day of the month. Growvest works out what your investors are paid from them, and holds payouts until they’re in.")
                    .font(AppFont.interTight(14, relativeTo: .subheadline))
                    .foregroundStyle(Color.grey50)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isReportSubmitted {
                HStack(spacing: 12) {
                    Image(.sealCheckSmall)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(MonthlyReport.month) report submitted")
                            .font(AppFont.interTight(16, relativeTo: .callout))
                            .foregroundStyle(.white)
                        Text("Growvest is reviewing it. We’ll let you know if anything’s missing.")
                            .font(AppFont.interTight(12, relativeTo: .caption))
                            .foregroundStyle(Color.grey50)
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
                .background(Color.grey80, in: .rect(cornerRadius: 20))
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            } else {
                VStack(spacing: 12) {
                    ForEach(ReportDocument.allCases) { kind in
                        UploadDocumentCard(title: kind.title, about: kind.about, upload: $report[kind])
                    }
                }
                .transition(.opacity)

                Button("Submit \(MonthlyReport.month) Report") {
                    withAnimation(Motion.step) { isReportSubmitted = true }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(uploadedCount < ReportDocument.allCases.count)
            }
        }
        .animation(Motion.step, value: uploadedCount)
        .sensoryFeedback(.success, trigger: isReportSubmitted) { _, done in done }
        .id(Self.reportID)
    }

    private func documentRow(_ document: OwnerListing.Document) -> some View {
        HStack(spacing: 12) {
            Image(.filePdf)
                .frame(width: 52, height: 52)
                .background(.black, in: .rect(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(AppFont.interTight(16, relativeTo: .callout))
                    .foregroundStyle(.white)
                Text("PDF · \(document.size)")
                    .font(AppFont.interTight(12, relativeTo: .caption))
                    .foregroundStyle(Color.grey50)
            }
            Spacer(minLength: 8)
            // Replace and delete sit behind a menu rather than on every row.
            Menu {
                Button("Replace") { notice = "Replacing documents is coming soon." }
                Button("Delete", role: .destructive) { notice = "Deleting documents is coming soon." }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.grey40)
                    .frame(width: 36, height: 36)
                    .contentShape(.rect)
            }
            .accessibilityLabel("\(document.name) options")
        }
        .padding(12)
        .background(Color.grey80, in: .rect(cornerRadius: 20))
    }
}

// MARK: - Pieces

/// The reminder at the top of a listing until this month's report is submitted.
private struct ReportDueBanner: View {
    let onOpen: () -> Void

    private var isUrgent: Bool { MonthlyReport.daysLeft <= 5 }

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                Image(.fileArrowUp)
                    .frame(width: 40, height: 40)
                    .background(.black, in: .circle)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(MonthlyReport.month) report due \(MonthlyReport.dueText)")
                        .font(AppFont.interTight(14, relativeTo: .subheadline))
                        .foregroundStyle(.white)
                    Text(MonthlyReport.daysLeft == 0 ? "Due today. Payouts wait for it." : "\(MonthlyReport.daysLeft) days left. Payouts wait for it.")
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        .foregroundStyle(isUrgent ? Color.warning50 : Color.grey50)
                }
                Spacer(minLength: 8)
                Text("Upload")
                    .font(AppFont.interTight(12, relativeTo: .caption))
                    .foregroundStyle(Color.primary50)
            }
            .padding(12)
            .background(Color.grey80, in: .rect(cornerRadius: 20))
            .contentShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(RowPressStyle())
        .accessibilityHint("Opens Documents")
    }
}

/// "Raising" while the offer is open, "Trading" once it's sold out.
private struct StatusPill: View {
    let isTrading: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(isTrading ? Color.success50 : Color.primary50).frame(width: 6, height: 6)
            Text(isTrading ? "Trading" : "Raising")
                .font(AppFont.interTight(12, relativeTo: .caption))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.grey80))
    }
}

/// A rounded bar that fills to `progress` when it first appears.
private struct ProgressBar: View {
    let progress: Double
    let tint: Color
    @State private var shown: Double = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(tint.opacity(0.18))
                Capsule().fill(tint).frame(width: proxy.size.width * shown)
            }
        }
        .frame(height: 8)
        .onAppear {
            withAnimation(.spring(duration: 0.9, bounce: 0).delay(0.15)) { shown = progress }
        }
    }
}

extension Int {
    /// "6,000"
    var grouped: String { formatted(.number.locale(Locale(identifier: "en_US"))) }
}

extension Double {
    /// "₦2.5M", "₦650K", "₦500"
    var shortNaira: String {
        func trimmed(_ value: Double) -> String {
            value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
        }
        if self >= 1_000_000 { return "₦" + trimmed(self / 1_000_000) + "M" }
        if self >= 1_000 { return "₦" + trimmed(self / 1_000) + "K" }
        return wholeNaira
    }

    /// "12.5%", "20%"
    var percentText: String {
        let rounded = (self * 10).rounded() / 10
        return (rounded.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(rounded)) : String(format: "%.1f", rounded)) + "%"
    }
}

#Preview {
    NavigationStack { ListingDetailView(listing: OwnerListing.all[0]) }
        .preferredColorScheme(.dark)
}
