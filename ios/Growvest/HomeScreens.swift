import SwiftUI

/// The screens pushed from the Home dashboard: a business's page (Figma 1087:1322),
/// Explore (1094:8536) and Notifications (1074:23082).
enum HomeRoute: Hashable {
    case company(String)
    case explore
    case notifications
}

// MARK: - Data

/// A business listed on Growvest: what its page, Explore and the watchlist show.
struct Company: Identifiable {
    let name: String
    let logo: ImageResource
    let tags: [String]
    /// The sector the Explore and watchlist filters group it under.
    let sector: String
    let tagline: String
    let price: Double
    /// Percent change over the past week.
    let change: Double
    let pricePerShare: Double
    var holding: Stake?
    let about: String
    let useOfFunds: [String]
    let team: [String]

    var id: String { name }

    /// The user's stake, for businesses they've invested in.
    struct Stake {
        let invested: Double
        let currentValue: Double
        let paidOut: Double
        let monthsElapsed: Int
        let monthsTotal: Int
        let shares: Int
        let sharePrice: Double

        var gainPercent: Int { Int(((currentValue - invested) / invested * 100).rounded()) }
        var isActive: Bool { monthsElapsed < monthsTotal }
    }

    /// What the buy and sell flows need. SwiftHarvest keeps the flows' original data.
    var tradeBusiness: Business {
        name == Business.swiftHarvest.name ? .swiftHarvest
            : Business(name: name, tags: tags, currentValue: price, pricePerShare: pricePerShare, logo: logo)
    }

    var tradeHolding: Holding {
        holding.map { Holding(shares: $0.shares, pricePerShare: $0.sharePrice) } ?? Holding(shares: 0, pricePerShare: pricePerShare)
    }

    static func named(_ name: String) -> Company? { all.first { $0.name == name } }

    static let swiftHarvest = Company(
        name: "SwiftHarvest Ventures", logo: .logoSwiftHarvest40, tags: ["AgriTech", "Farming", "AI"], sector: "Agriculture",
        tagline: "Precision agritech boosting crop yields with AI-driven irrigation.",
        price: 45_162.77, change: 12, pricePerShare: 62.99,
        holding: Stake(invested: 38_500, currentValue: 45_162.77, paidOut: 2_500, monthsElapsed: 7, monthsTotal: 12,
                       shares: 40, sharePrice: 2_500),
        about: "SwiftHarvest deploys sensor-driven irrigation and yield analytics for mid-size farms, improving water efficiency and output.",
        useOfFunds: ["45% Infrastructure (Greenhouses, sensors)", "25% Working Capital (inputs, logistics)",
                     "20% R&D (AI irrigation models)", "10% Market Expansion (new farm clusters)"],
        team: ["Aisha Bello — CEO: 10+ yrs agronomy, ex-AgriCo Ops Lead", "Tunde Okeke — CTO: IoT/ML engineer, ex-GreenSense",
               "Amara Obi — COO: supply & distribution specialist"]
    )

    static let all: [Company] = [
        swiftHarvest,
        Company(
            name: "CoreMedix Labs", logo: .logoCoreMedix, tags: ["HealthTech", "Diagnostics"], sector: "Tech",
            tagline: "Affordable lab diagnostics for clinics across West Africa.",
            price: 38_420.10, change: -4, pricePerShare: 48.20,
            holding: Stake(invested: 40_000, currentValue: 38_420.10, paidOut: 0, monthsElapsed: 4, monthsTotal: 18,
                           shares: 25, sharePrice: 1_536),
            about: "CoreMedix runs shared diagnostic labs that let small clinics offer blood work and imaging without buying the equipment.",
            useOfFunds: ["50% Equipment (analysers, imaging)", "30% New lab sites", "20% Working Capital"],
            team: ["Ngozi Eze — CEO: physician, ex-Lagos University Teaching Hospital",
                   "Kofi Mensah — COO: healthcare operations, 12 yrs"]
        ),
        Company(
            name: "TroveMart", logo: .logoTroveMart, tags: ["E-commerce", "Retail"], sector: "Tech",
            tagline: "An online marketplace connecting local makers to shoppers nationwide.",
            price: 45_162.77, change: 1.4, pricePerShare: 35.10,
            holding: Stake(invested: 55_000, currentValue: 72_310.40, paidOut: 4_000, monthsElapsed: 10, monthsTotal: 24,
                           shares: 60, sharePrice: 1_205),
            about: "TroveMart lists products from independent makers and handles payments, delivery and returns for them.",
            useOfFunds: ["40% Logistics (fulfilment hubs)", "35% Marketing", "25% Product & engineering"],
            team: ["Chidi Nwosu — CEO: ex-Jumia category lead", "Halima Musa — CTO: payments engineer"]
        ),
        Company(
            name: "Suji’s Fashion House", logo: .logoSuji, tags: ["Fashion", "Retail"], sector: "Fashion",
            tagline: "Contemporary African tailoring, made to order in Lagos.",
            price: 28_904.50, change: -2.9, pricePerShare: 22.40,
            holding: Stake(invested: 48_000, currentValue: 59_167.53, paidOut: 0, monthsElapsed: 3, monthsTotal: 12,
                           shares: 50, sharePrice: 1_183),
            about: "Suji’s designs and tailors ready-to-wear and made-to-measure clothing, sold in its Lagos studio and online.",
            useOfFunds: ["50% Production (machines, fabric)", "30% Second studio", "20% E-commerce"],
            team: ["Suji Adeyemi — Founder & Creative Director", "Bola Ajayi — Head of Operations"]
        ),
        Company(
            name: "StitchWorks Atelier", logo: .logoSewing52, tags: ["Fashion", "Manufacturing"], sector: "Fashion",
            tagline: "Contract garment production for independent fashion labels.",
            price: 12_310.00, change: 1.4, pricePerShare: 9.80,
            about: "StitchWorks produces small garment runs for independent labels that are too small for large factories.",
            useOfFunds: ["60% Machinery", "25% Staff training", "15% Working Capital"],
            team: ["Ifeoma Okafor — CEO: 15 yrs garment production"]
        ),
        Company(
            name: "SafeBond Finance", logo: .logoSafeBond, tags: ["Fintech", "Savings"], sector: "Tech",
            tagline: "Fixed-income savings products for small businesses.",
            price: 8_450.00, change: 2.1, pricePerShare: 12.50,
            about: "SafeBond pools small businesses’ idle cash into short-term government bonds, with withdrawals in one day.",
            useOfFunds: ["40% Licensing & compliance", "35% Product", "25% Customer acquisition"],
            team: ["Emeka Obi — CEO: ex-investment banker", "Zainab Lawal — CRO: risk & compliance"]
        ),
        Company(
            name: "CapitalSpring Ltd.", logo: .logoCapitalSpring, tags: ["Energy", "Cold Storage"], sector: "Agriculture",
            tagline: "Geothermal-powered cold storage for fresh produce.",
            price: 15_720.40, change: 0.8, pricePerShare: 18.75,
            about: "CapitalSpring builds cold rooms near farms, run on geothermal energy, so produce lasts long enough to reach market.",
            useOfFunds: ["55% Cold rooms", "30% Energy systems", "15% Working Capital"],
            team: ["Yusuf Bello — CEO: renewable energy engineer"]
        ),
    ]

    /// Businesses on the user's watchlist, for the star on a business's page.
    static let watchlistNames: Set<String> = ["TroveMart", "Suji’s Fashion House", "StitchWorks Atelier", "SwiftHarvest Ventures"]
}

// MARK: - Business page

/// A business's page: price chart with time ranges, the user's stake, an overview of
/// the business, and Buy / Sell pinned to the bottom (Sell only when the user holds shares).
struct CompanyDetailView: View {
    let company: Company
    @State private var range: ChartRange = .week
    @State private var isWatched: Bool
    @State private var trade: TradeKind?
    @Environment(\.dismiss) private var dismiss

    init(company: Company) {
        self.company = company
        _isWatched = State(initialValue: Company.watchlistNames.contains(company.name))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    HStack(spacing: 8) {
                        Text(company.price.naira)
                            .font(AppFont.interTight(36, .semibold, relativeTo: .largeTitle))
                            .tracking(-0.72)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        ChangeBadge(text: company.change.magnitudeText, isUp: company.change >= 0, size: .small)
                    }
                }

                PriceChart(source: company.chartSource, range: $range)

                if let stake = company.holding {
                    InfoSection(title: "Investment Snapshot") {
                        InfoRow(label: "Your Capital Invested") { value(stake.invested.wholeNaira) }
                        InfoRow(label: "Current Value") {
                            HStack(spacing: 12) {
                                value(stake.currentValue.wholeNaira)
                                ChangeBadge(text: stake.gainPercent >= 0 ? "+\(stake.gainPercent)" : "\(stake.gainPercent)",
                                            isUp: stake.gainPercent >= 0, size: .small)
                            }
                        }
                        InfoRow(label: "Cash Paid Out") { value(stake.paidOut.wholeNaira) }
                        InfoRow(label: "Holding Period") { value("\(stake.monthsElapsed) of \(stake.monthsTotal) months elapsed") }
                    }
                }

                InfoSection(title: "Business Overview") {
                    OverviewBlock(label: "What they do:", lines: [company.about])
                    OverviewBlock(label: "Use of Funds (Allocated)", lines: company.useOfFunds)
                    OverviewBlock(label: "Team", lines: company.team)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)
            .padding(.bottom, 24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) { tradeBar }
        .background(Color(.systemBackground))
        .homeScreenChrome(onBack: { dismiss() }) {
            Button {
                withAnimation(Motion.select) { isWatched.toggle() }
            } label: {
                // Outlined when off; filled cyan once it's on the watchlist.
                Image(isWatched ? .starFilled : .star)
                    .contentTransition(.opacity)
                    .scaleEffect(isWatched ? 1.1 : 1)
            }
            .buttonStyle(CircleIconButtonStyle())
            .sensoryFeedback(.selection, trigger: isWatched)
            .accessibilityLabel(isWatched ? "Remove from watchlist" : "Add to watchlist")
        }
        .fullScreenCover(item: $trade) { kind in
            TradeView(kind: kind, business: company.tradeBusiness, holding: company.tradeHolding)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(company.logo)
                    .resizable()
                    .frame(width: 48, height: 48)
                Text(company.name)
                    .font(AppFont.interTight(20, relativeTo: .title3))
                    .foregroundStyle(.white)
            }
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

    private func value(_ text: String) -> some View {
        Text(text)
            .font(AppFont.interTight(14, relativeTo: .subheadline))
            .foregroundStyle(.white)
    }

    private var tradeBar: some View {
        HStack(spacing: 12) {
            Button { trade = .buy } label: {
                Label { Text("Buy") } icon: { Image(.tradePlus) }
            }
            .buttonStyle(TradeButtonStyle(fill: .success100, text: .success50))
            if company.holding != nil {
                Button { trade = .sell } label: {
                    Label { Text("Sell") } icon: { Image(.tradeMinus) }
                }
                .buttonStyle(TradeButtonStyle(fill: .error100, text: .error50))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 8)
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .overlay(alignment: .top) { Rectangle().fill(Color.grey80).frame(height: 1) }
    }
}

/// The tinted Buy (green) and Sell (red) pills.
private struct TradeButtonStyle: ButtonStyle {
    let fill: Color
    let text: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(TradeLabelStyle())
            .font(AppFont.interTight(16, relativeTo: .callout))
            .foregroundStyle(text)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Capsule().fill(fill))
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

private struct TradeLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
            configuration.title
        }
    }
}

// MARK: Chart

enum ChartRange: String, CaseIterable, Identifiable {
    case day = "1D", week = "1W", month = "1M", year = "1Y", max = "Max"
    var id: Self { self }

    /// How many of the chart's bars light up for the range: one for a day, one per day
    /// for a week, all of them for the whole history (Figma 1121-5853, 1121-5789, 1121-5725).
    var litBars: Int {
        switch self {
        case .day: 1
        case .week: 7
        case .month: 16
        case .year: 32
        case .max: PriceChart.barCount
        }
    }

    /// Where the range starts, for the date under the chart's left edge.
    var start: Date {
        let calendar = Calendar.current
        let date: Date? = switch self {
        case .day: calendar.date(byAdding: .day, value: -1, to: .now)
        case .week: calendar.date(byAdding: .day, value: -8, to: .now)
        case .month: calendar.date(byAdding: .month, value: -1, to: .now)
        case .year: calendar.date(byAdding: .year, value: -1, to: .now)
        case .max: calendar.date(from: DateComponents(year: 2025, month: 2, day: 14))   // listing date
        }
        return date ?? .now
    }
}

/// What a bar chart plots: sample prices ending at `price`, trending with `change`.
/// `history` overrides the Max range with the design's own bar heights.
struct ChartSource {
    let seed: String
    let price: Double
    let change: Double
    var history: [Double]?
}

extension Company {
    var chartSource: ChartSource {
        ChartSource(seed: name, price: price, change: change,
                    history: name == Company.swiftHarvest.name ? PriceChart.designHistory : nil)
    }
}

/// The price chart as a row of thin bars (Figma 1121-5725). The bars in the selected range
/// rise in cyan to trace the price; the rest sit as short grey ticks. Switching range sends
/// a left-to-right wave through the bars. Press and hold, then drag, to read any lit bar:
/// it turns cyan under a price bubble while the others go grey (Figma 1122-5922).
struct PriceChart: View {
    let source: ChartSource
    @Binding var range: ChartRange
    @Namespace private var pill
    /// The lit bar under the finger while reading the chart.
    @State private var scrubbed: Int?
    /// The bar the reading started from or last sat on: colour changes ripple out from it.
    @State private var anchor = PriceChart.barCount - 1
    @State private var isHolding = false
    /// Measured on first show; starts near a typical price's width so the bubble doesn't jump.
    @State private var bubbleWidth: CGFloat = 92

    static let barCount = 48
    private static let chartHeight: CGFloat = 196
    private static let tickHeight: CGFloat = 28
    private static let lowestBar: CGFloat = 44

    var body: some View {
        let heights = Self.barHeights(for: source, range: range)
        let firstLit = Self.barCount - range.litBars

        VStack(spacing: 16) {
            GeometryReader { proxy in
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(0..<Self.barCount, id: \.self) { index in
                        let isLit = index >= firstLit
                        // While reading, only the bar under the finger stays cyan.
                        let isCyan = isLit && (scrubbed == nil || scrubbed == index)
                        Capsule()
                            .fill(isCyan ? Color.primary50 : Color.grey50)
                            .frame(width: 2, height: isLit ? heights[index - firstLit] : Self.tickHeight)
                            // Each bar starts a beat after its left neighbour: a wave across the chart.
                            .animation(.spring(duration: 0.5, bounce: 0.22).delay(Double(index) * 0.007), value: range)
                            // Going grey when a reading starts, and cyan again when it ends,
                            // spreads outward from the finger instead of flashing all at once.
                            .animation(.easeOut(duration: 0.2).delay(Double(abs(index - anchor)) * 0.006), value: scrubbed)
                        if index < Self.barCount - 1 { Spacer(minLength: 0) }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .contentShape(.rect)
                .gesture(scrub(width: proxy.size.width, firstLit: firstLit))
                .overlay(alignment: .topLeading) {
                    if let scrubbed {
                        priceBubble(for: scrubbed, heights: heights, firstLit: firstLit, width: proxy.size.width)
                    }
                }
            }
            .frame(height: Self.chartHeight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Price chart, \(range.rawValue)")
            .accessibilityValue("\(Self.dateFormat.string(from: range.start)) to today")

            HStack {
                Text(Self.dateFormat.string(from: range.start))
                Spacer()
                Text(Self.dateFormat.string(from: .now))
            }
            .font(AppFont.interTight(14, relativeTo: .subheadline))
            .foregroundStyle(Color.grey50)
            .contentTransition(.numericText())
            .animation(.snappy(duration: 0.2), value: range)

            HStack(spacing: 8) {
                ForEach(ChartRange.allCases) { option in
                    let isSelected = option == range
                    Button {
                        withAnimation(Motion.select) { range = option }
                    } label: {
                        Text(option.rawValue)
                            .font(AppFont.interTight(12, relativeTo: .caption))
                            .foregroundStyle(isSelected ? .black : Color.grey50)
                            .padding(.vertical, 12)
                            .frame(maxWidth: 72)
                            .frame(maxWidth: .infinity)
                            .background {
                                Capsule().fill(Color.grey80)
                                if isSelected {
                                    Capsule().fill(Color.primary50)
                                        .matchedGeometryEffect(id: "range", in: pill)
                                }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .sensoryFeedback(.selection, trigger: range)
        }
        .sensoryFeedback(.selection, trigger: scrubbed) { old, new in old != nil && new != nil }
        .sensoryFeedback(.impact(weight: .light), trigger: isHolding) { _, holding in holding }
        .hapticSound(trigger: scrubbed)
        #if DEBUG
        .onAppear {
            // -demoChart scrub: Max range with bar 25 held, as in Figma 1122-5922.
            if UserDefaults.standard.string(forKey: "demoChart") == "scrub" {
                range = .max
                anchor = 25
                scrubbed = 25
            }
        }
        #endif
    }

    /// A short hold, then drag: a plain swipe stays free to scroll the page. The reading
    /// starts on the bar under the finger the moment the hold registers, with a light tap.
    private func scrub(width: CGFloat, firstLit: Int) -> some Gesture {
        LongPressGesture(minimumDuration: 0.15)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                guard case .second(true, let drag) = value else { return }
                isHolding = true
                guard let drag else { return }
                // The nearest bar's centre, not the slot the finger is in, so it never lags a bar behind.
                let spacing = (width - 2) / CGFloat(Self.barCount - 1)
                let bar = Int(((drag.location.x - 1) / spacing).rounded())
                let clamped = min(max(bar, firstLit), Self.barCount - 1)
                guard clamped != scrubbed else { return }
                anchor = clamped
                if scrubbed == nil {
                    withAnimation(.spring(duration: 0.3, bounce: 0.25)) { scrubbed = clamped }
                } else {
                    scrubbed = clamped
                }
            }
            .onEnded { _ in
                isHolding = false
                withAnimation(.easeOut(duration: 0.22)) { scrubbed = nil }
            }
    }

    /// The dark price bubble, its pointer just above the bar's tip. It follows the finger
    /// sideways but stays inside the chart, and never rises above the chart's top.
    private func priceBubble(for bar: Int, heights: [CGFloat], firstLit: Int, width: CGFloat) -> some View {
        let barX = 1 + CGFloat(bar) * (width - 2) / CGFloat(Self.barCount - 1)
        let tipY = max(Self.chartHeight - heights[bar - firstLit] - 3, Self.bubbleHeight)
        let half = bubbleWidth / 2
        let centerX = min(max(barX, half), width - half)
        return VStack(spacing: 0) {
            Text(price(ofBar: bar, firstLit: firstLit).naira)
                .font(AppFont.interTight(10, relativeTo: .caption2))
                .foregroundStyle(.white)
                .monospacedDigit()
                .contentTransition(.numericText())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.grey80))
            DownPointer()
                .fill(Color.grey80)
                .frame(width: 13.856, height: 12)
                // The pointer stays over the bar when the bubble is held inside the edges.
                .offset(x: barX - centerX)
        }
        .fixedSize()
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { bubbleWidth = $0 }
        .position(x: centerX, y: tipY - Self.bubbleHeight / 2)
        // A tight, critically damped spring: the bubble glides between bars without wobbling.
        .animation(.interactiveSpring(response: 0.22, dampingFraction: 0.9), value: bar)
        .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .bottom)))
        .allowsHitTesting(false)
    }

    /// Bubble (14pt line + 16pt padding) plus its 12pt pointer.
    private static let bubbleHeight: CGFloat = 42

    private func price(ofBar bar: Int, firstLit: Int) -> Double {
        Self.series(for: source, range: range)[bar - firstLit]
    }

    /// "24 Sept 2026", "02 Oct 2026"
    private static let dateFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }()

    /// The lit bars' heights: the range's prices scaled between 44pt and the full chart.
    /// A single bar (1D) stands at 180pt, as in the design.
    private static func barHeights(for source: ChartSource, range: ChartRange) -> [CGFloat] {
        let values = series(for: source, range: range)
        guard values.count > 1, let low = values.min(), let high = values.max(), high > low else { return [180] }
        return values.map { lowestBar + CGFloat(($0 - low) / (high - low)) * (chartHeight - lowestBar) }
    }

    /// The whole history drawn in the designs (SwiftHarvest's page and the portfolio),
    /// read off the bars in points, 44–196.
    static let designHistory: [Double] = [
        64, 64, 64, 64, 64, 54, 44, 44, 44, 44, 52, 56, 70, 78, 88, 96, 104, 112, 120, 126, 128, 130, 134, 136,
        138, 140, 143, 140, 138, 135, 133, 131, 128, 126, 129, 136, 143, 152, 161, 167, 175, 181, 190, 196, 196, 196, 196, 196,
    ]

    /// Sample prices for the range's lit bars, ending at today's price and trending the way
    /// the business's weekly change does. Stable per business and range.
    private static func series(for source: ChartSource, range: ChartRange) -> [Double] {
        let count = range.litBars
        guard count > 1 else { return [source.price] }
        if let history = source.history, range == .max {
            let top = history.max() ?? 1
            return history.map { source.price * (0.7 + 0.3 * $0 / top) }
        }
        var seed = source.seed.unicodeScalars.reduce(UInt64(count)) { $0 &* 31 &+ UInt64($1.value) }
        func random() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(seed >> 33) / Double(1 << 31)
        }
        let trend = source.change / 100 * (range == .week ? 1 : range == .month ? 1.5 : 3)
        var values: [Double] = []
        var value = source.price / (1 + trend)
        for i in 0..<count {
            values.append(value)
            let drift = (source.price - value) / Double(max(count - i, 1))
            value += drift + (random() - 0.5) * source.price * 0.03
        }
        values[count - 1] = source.price
        return values
    }
}

/// The bubble's downward pointer.
private struct DownPointer: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

// MARK: Cards

/// A 16pt heading over a grey card whose rows are split by black hairlines.
private struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppFont.interTight(16, relativeTo: .headline))
                .foregroundStyle(.white)
            HairlineCard { content }
        }
    }
}

/// A grey card whose rows are split by black hairlines, each row padded as in the designs.
struct HairlineCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { rows in
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    row
                        .padding(.horizontal, 16)
                        .padding(.top, index == 0 ? 16 : 12)
                        .padding(.bottom, 16)
                    if index < rows.count - 1 {
                        Rectangle().fill(.black).frame(height: 1)
                    }
                }
            }
        }
        .background(Color.grey80, in: .rect(cornerRadius: 24))
    }
}

private struct InfoRow<Value: View>: View {
    let label: String
    @ViewBuilder var value: Value

    var body: some View {
        HStack {
            Text(label)
                .font(AppFont.interTight(14, relativeTo: .subheadline))
                .foregroundStyle(Color.grey50)
            Spacer(minLength: 12)
            value
        }
        .accessibilityElement(children: .combine)
    }
}

private struct OverviewBlock: View {
    let label: String
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .foregroundStyle(Color.grey50)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(lines, id: \.self) { Text($0).foregroundStyle(.white) }
            }
        }
        .font(AppFont.interTight(14, relativeTo: .subheadline))
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Explore

/// Search across businesses, filter by sector, with recent searches and top opportunities.
struct ExploreView: View {
    @Binding var recentNames: [String]
    @State private var query = ""
    @State private var sector = "All sectors"
    @FocusState private var isSearching: Bool
    @Environment(\.dismiss) private var dismiss

    private static let sectors = ["All sectors", "Agriculture", "Tech", "Fashion", "Gaming"]
    private static let topNames = ["CoreMedix Labs", "TroveMart", "Suji’s Fashion House", "StitchWorks Atelier"]

    private func inSector(_ company: Company) -> Bool {
        sector == "All sectors" || company.sector == sector
    }

    private var recents: [Company] { recentNames.compactMap(Company.named).filter(inSector) }
    private var top: [Company] { Self.topNames.compactMap(Company.named).filter(inSector) }

    private var results: [Company] {
        let term = query.trimmingCharacters(in: .whitespaces)
        return Company.all.filter { company in
            inSector(company) && ([company.name, company.sector] + company.tags).contains { $0.localizedCaseInsensitiveContains(term) }
        }
    }

    private var isFiltering: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        searchField
                        Button {} label: { Image(.filterHorizontal) }
                            .buttonStyle(CircleIconButtonStyle(size: 52))
                            .accessibilityLabel("Filters")
                    }
                    FilterBar(options: Self.sectors, selection: $sector)
                }

                VStack(alignment: .leading, spacing: 20) {
                    if isFiltering {
                        listSection("Results", results)
                        if results.isEmpty { emptyMessage("No businesses match “\(query)”.") }
                    } else {
                        if !recents.isEmpty { listSection("Recent searches", recents) }
                        if !top.isEmpty { listSection("Top investment opportunities", top) }
                        if recents.isEmpty && top.isEmpty { emptyMessage("No businesses in \(sector) yet.") }
                    }
                }
                .animation(Motion.step, value: sector)
                .animation(Motion.step, value: query)
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)
            .padding(.bottom, 24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemBackground))
        .homeScreenChrome(title: "Explore") { dismiss() }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(.magnifyingGlass)
            TextField("", text: $query, prompt: Text("Search for investment opportunities").foregroundStyle(Color.grey50))
                .font(AppFont.interTight(14, relativeTo: .subheadline))
                .foregroundStyle(.white)
                .tint(Color.primary50)
                .focused($isSearching)
                .submitLabel(.search)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button { query = "" } label: { Image(.closeX).resizable().frame(width: 16, height: 16) }
                    .buttonStyle(RowPressStyle())
                    .accessibilityLabel("Clear search")
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Capsule().fill(Color.grey80))
        .contentShape(Capsule())
        .onTapGesture { isSearching = true }
        .animation(Motion.select, value: query.isEmpty)
    }

    private func listSection(_ title: String, _ companies: [Company]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.interTight(14, relativeTo: .subheadline))
                .foregroundStyle(Color.grey50)
            ForEach(companies) { company in
                NavigationLink(value: HomeRoute.company(company.name)) {
                    CompanyRow(company: company)
                }
                .buttonStyle(RowPressStyle())
                .simultaneousGesture(TapGesture().onEnded { remember(company) })
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func emptyMessage(_ text: String) -> some View {
        Text(text)
            .font(AppFont.interTight(14, relativeTo: .subheadline))
            .foregroundStyle(Color.grey50)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .transition(.opacity)
    }

    /// Opening a business moves it to the top of recent searches (three at most).
    private func remember(_ company: Company) {
        recentNames.removeAll { $0 == company.name }
        recentNames.insert(company.name, at: 0)
        recentNames = Array(recentNames.prefix(3))
    }
}

private struct CompanyRow: View {
    let company: Company

    var body: some View {
        HStack(spacing: 10) {
            Image(company.logo)
                .resizable()
                .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(company.name)
                    .font(AppFont.interTight(16, relativeTo: .callout))
                    .foregroundStyle(.white)
                Text(company.tags.joined(separator: " · "))
                    .font(AppFont.interTight(12, relativeTo: .caption))
                    .foregroundStyle(Color.grey50)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.grey80, in: .rect(cornerRadius: 28))
        .contentShape(.rect(cornerRadius: 28))
    }
}

// MARK: - Notifications

private struct AppNotification: Identifiable {
    enum Audience { case investor, businessOwner }

    let category: String
    let audience: Audience
    let title: String
    let message: String
    let time: String
    /// Days ago: 0 is Today, 1 is Yesterday.
    let daysAgo: Int
    let icon: ImageResource
    /// Company logos fill more of the tile than the design's line icon.
    var isLogo = true

    var id: String { "\(daysAgo)-\(time)-\(title)" }
}

/// Notifications grouped by day, filtered by All / Investor / Business Owner.
struct NotificationsView: View {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "All", investor = "Investor", businessOwner = "Business Owner"
        var id: Self { self }
    }

    @State private var filter: Filter = .all
    @Namespace private var pill
    @Environment(\.dismiss) private var dismiss

    private static let notifications: [AppNotification] = [
        AppNotification(category: "Investor", audience: .investor, title: "Suji’s Fashion House",
                        message: "Suji’s Fashion House has reached 75% funding!", time: "Just now", daysAgo: 0,
                        icon: .notificationSewing, isLogo: false),
        AppNotification(category: "Alerts & Reminders", audience: .investor, title: "SwiftHarvest Ventures",
                        message: "Your quarterly payout of ₦25,000 lands on 15 October.", time: "2h ago", daysAgo: 0,
                        icon: .logoSwiftHarvest40),
        AppNotification(category: "Business Owner", audience: .businessOwner, title: "StitchWorks Atelier",
                        message: "StitchWorks Atelier is fully funded. You can now withdraw ₦5M.", time: "6:30 PM", daysAgo: 1,
                        icon: .logoSewing52),
        AppNotification(category: "Investment Updates", audience: .investor, title: "CoreMedix Labs",
                        message: "CoreMedix Labs shared its Q3 report: revenue is up 18%.", time: "1:15 PM", daysAgo: 1,
                        icon: .logoCoreMedix),
        AppNotification(category: "Business Owner", audience: .businessOwner, title: "CapitalSpring Ltd.",
                        message: "3 new investors backed CapitalSpring Ltd. today.", time: "10:02 AM", daysAgo: 1,
                        icon: .logoCapitalSpring),
        AppNotification(category: "Investment Updates", audience: .investor, title: "TroveMart",
                        message: "TroveMart’s share price rose 1.4% this week.", time: "4:45 PM", daysAgo: 8,
                        icon: .logoTroveMart),
        AppNotification(category: "Alerts & Reminders", audience: .businessOwner, title: "SafeBond Finance",
                        message: "Upload your tax documents to finish verifying SafeBond Finance.", time: "9:00 AM", daysAgo: 8,
                        icon: .logoSafeBond),
    ]

    private var groups: [(title: String, items: [AppNotification])] {
        let visible = Self.notifications.filter { note in
            switch filter {
            case .all: true
            case .investor: note.audience == .investor
            case .businessOwner: note.audience == .businessOwner
            }
        }
        let days = Array(Set(visible.map(\.daysAgo))).sorted()
        return days.map { day in (Self.dayTitle(day), visible.filter { $0.daysAgo == day }) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                filterPicker
                ForEach(groups, id: \.title) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(group.title)
                            .font(AppFont.interTight(14, relativeTo: .subheadline))
                            .foregroundStyle(Color.grey50)
                        VStack(spacing: 8) {
                            ForEach(group.items) { NotificationRow(note: $0) }
                        }
                    }
                    .transition(.opacity)
                }
            }
            .animation(Motion.step, value: filter)
            .padding(.horizontal, 24)
            .padding(.top, 6)
            .padding(.bottom, 24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemBackground))
        .homeScreenChrome(title: "Notification") { dismiss() }
    }

    private var filterPicker: some View {
        HStack(spacing: 0) {
            ForEach(Filter.allCases) { option in
                let isSelected = option == filter
                Button {
                    withAnimation(Motion.step) { filter = option }
                } label: {
                    Text(option.rawValue)
                        .font(AppFont.interTight(14, relativeTo: .subheadline))
                        .foregroundStyle(isSelected ? .black : Color.grey50)
                        .lineLimit(1)
                        .padding(.vertical, 12)
                        .frame(maxWidth: option == .all ? 80 : .infinity)
                        .background {
                            if isSelected {
                                Capsule().fill(Color.primary50)
                                    .matchedGeometryEffect(id: "filter", in: pill)
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
        .sensoryFeedback(.selection, trigger: filter)
    }

    /// "Today", "Yesterday", then "30 September 2026".
    private static func dayTitle(_ daysAgo: Int) -> String {
        switch daysAgo {
        case 0: return "Today"
        case 1: return "Yesterday"
        default:
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_GB")
            formatter.dateFormat = "d MMMM yyyy"
            return formatter.string(from: date)
        }
    }
}

private struct NotificationRow: View {
    let note: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if note.isLogo {
                    Image(note.icon).resizable().frame(width: 36, height: 36)
                } else {
                    Image(note.icon)
                }
            }
            .frame(width: 64, height: 64)
            .background(.black, in: .rect(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .top) {
                    Text(note.category)
                        .foregroundStyle(Color.primary50)
                    Spacer(minLength: 8)
                    Text(note.time)
                        .foregroundStyle(Color.grey50)
                }
                .font(AppFont.interTight(12, relativeTo: .caption))
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title)
                        .font(AppFont.interTight(16, relativeTo: .callout))
                        .foregroundStyle(.white)
                    Text(note.message)
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        .foregroundStyle(Color.grey50)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.grey80, in: .rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Shared chrome

/// The pinned header in place of the system navigation bar: round back button, an
/// optional centered title and trailing button. It's opaque, and keeps the same 24pt
/// below the buttons as at the sides, so scrolled content never crowds them.
private struct HomeScreenChrome<Trailing: View>: ViewModifier {
    let title: String?
    let onBack: () -> Void
    @ViewBuilder var trailing: Trailing

    func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    Button(action: onBack) { Image(.arrowLeft) }
                        .buttonStyle(CircleIconButtonStyle())
                        .accessibilityLabel("Back")
                    Spacer()
                    trailing
                }
                .overlay {
                    if let title {
                        Text(title)
                            .font(AppFont.interTight(16, relativeTo: .headline))
                            .foregroundStyle(.white)
                            .accessibilityAddTraits(.isHeader)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
            }
    }
}

private extension View {
    func homeScreenChrome<Trailing: View>(title: String? = nil, onBack: @escaping () -> Void,
                                          @ViewBuilder trailing: () -> Trailing = { EmptyView() }) -> some View {
        modifier(HomeScreenChrome(title: title, onBack: onBack, trailing: trailing))
    }
}

private extension Double {
    /// "12", "2.9": the size of a change, whose direction the badge's arrow shows.
    var magnitudeText: String {
        let size = abs(self)
        return size.rounded() == size ? String(Int(size)) : String(format: "%.1f", size)
    }
}
