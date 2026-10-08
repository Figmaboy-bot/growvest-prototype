import SwiftUI

/// The home dashboard. One screen, two modes switched by the pill at the top:
///
/// - Investor: portfolio value, portfolio distribution and a filterable watchlist.
/// - Business owner: funds raised, stats and the owner's listings with funding progress.
///
/// Each mode has its own floating tab bar. SwiftHarvest is wired into the trade flows:
/// its portfolio card opens Sell, its watchlist row opens Buy.
struct HomeView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case investor = "Investor"
        case businessOwner = "Business Owner"
        var id: Self { self }
    }

    @State private var mode: Mode = .investor
    @State private var isBalanceHidden = false
    @State private var investorTab: InvestorTab = .home
    @State private var businessTab: BusinessTab = .home
    @State private var trade: TradeKind?
    @Namespace private var modePill
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if isOnHomeTab {
                    ScrollView {
                        VStack(spacing: 32) {
                            VStack(spacing: 24) {
                                header
                                modePicker
                            }
                            VStack(spacing: 28) {
                                BalanceSummary(mode: mode, isHidden: $isBalanceHidden)
                                Group {
                                    switch mode {
                                    case .investor: InvestorSections(trade: $trade)
                                    case .businessOwner: BusinessSections()
                                    }
                                }
                                .id(mode)
                                .transition(.asymmetric(
                                    insertion: .move(edge: mode == .investor ? .leading : .trailing).combined(with: .opacity),
                                    removal: .move(edge: mode == .investor ? .trailing : .leading).combined(with: .opacity)
                                ))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 120)          // room to scroll past the floating tab bar
                        .frame(maxWidth: 480)
                        .frame(maxWidth: .infinity)
                    }
                    .scrollIndicators(.hidden)
                } else {
                    TabPlaceholder(title: placeholderTitle) { dismiss() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            tabBar
                .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .animation(Motion.step, value: mode)
        .fullScreenCover(item: $trade) { kind in
            TradeView(kind: kind)
        }
        #if DEBUG
        .onAppear {
            let defaults = UserDefaults.standard
            if defaults.string(forKey: "demoHome") == "business" { mode = .businessOwner }
            if defaults.string(forKey: "demoHome") == "hidden" { isBalanceHidden = true }
        }
        #endif
    }

    private var isOnHomeTab: Bool {
        mode == .investor ? investorTab == .home : businessTab == .home
    }

    private var placeholderTitle: String {
        mode == .investor ? investorTab.title : businessTab.title
    }

    // MARK: Header

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                // The design has no back button, so the avatar leads back to the flow launcher.
                Button { dismiss() } label: {
                    Image(.avatarSulaimon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
                .buttonStyle(RowPressStyle())
                .accessibilityLabel("Back to flows")
                VStack(alignment: .leading, spacing: 2) {
                    Text(Self.greeting)
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        .foregroundStyle(mode == .investor ? Color.grey50 : Color.grey60)
                    Text("Odeniran Sulaimon")
                        .font(AppFont.interTight(16, relativeTo: .callout))
                        .foregroundStyle(.white)
                }
            }
            Spacer()
            HStack(spacing: 8) {
                if mode == .investor {
                    RoundIconButton(icon: .magnifyingGlass, label: "Search")
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
                RoundIconButton(icon: .bell, label: "Notifications")
            }
        }
    }

    /// "Good Morning" / "Good Afternoon" / "Good Evening", by the time of day.
    private static var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: "Good Morning,"
        case 12..<17: "Good Afternoon,"
        default: "Good Evening,"
        }
    }

    /// The Investor / Business Owner pill: the cyan selection slides between the two.
    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(Mode.allCases) { option in
                let isSelected = option == mode
                Button {
                    withAnimation(Motion.step) { mode = option }
                } label: {
                    Text(option.rawValue)
                        .font(AppFont.interTight(14, relativeTo: .subheadline))
                        .foregroundStyle(isSelected ? Color.ink : Color.grey50)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background {
                            if isSelected {
                                Capsule().fill(Color.primary50)
                                    .matchedGeometryEffect(id: "selection", in: modePill)
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
        .sensoryFeedback(.selection, trigger: mode)
    }

    // MARK: Tab bar

    @ViewBuilder
    private var tabBar: some View {
        switch mode {
        case .investor:
            FloatingTabBar(tabs: InvestorTab.allCases, selection: $investorTab)
                .transition(.opacity)
        case .businessOwner:
            FloatingTabBar(tabs: BusinessTab.allCases, selection: $businessTab)
                .transition(.opacity)
        }
    }
}

extension TradeKind: Identifiable {
    var id: Self { self }
}

// MARK: - Balance

private struct BalanceSummary: View {
    let mode: HomeView.Mode
    @Binding var isHidden: Bool

    private var title: String { mode == .investor ? "Total Portfolio Value" : "Total Funds Raised" }
    private var amount: Double { mode == .investor ? 215_060.80 : 3_215_060.80 }
    private var change: String {
        let figure = isHidden ? "₦••••" : (mode == .investor ? "₦5,161.46" : "₦32,762.46")
        return "+\(figure) " + (mode == .investor ? "Today’s Profit" : "Increase in funds")
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(AppFont.interTight(14, relativeTo: .subheadline))
                .foregroundStyle(Color.grey40)
                .contentTransition(.opacity)

            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Text(isHidden ? "₦••••••" : amount.naira)
                        .font(AppFont.interTight(36, .semibold, relativeTo: .largeTitle))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Button {
                        withAnimation(.snappy) { isHidden.toggle() }
                    } label: {
                        Group {
                            if isHidden {
                                Image(.eyeOpen).resizable().frame(width: 24, height: 24)
                            } else {
                                Image(.viewOff)
                            }
                        }
                        .frame(width: 24, height: 24)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isHidden ? "Show balance" : "Hide balance")
                }

                HStack(spacing: 4) {
                    Image(.trendUp)
                    Text(change)
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        .foregroundStyle(Color.success50)
                        .contentTransition(.opacity)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.success50.opacity(0.12)))
            }
        }
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .animation(Motion.step, value: mode)
        .sensoryFeedback(.selection, trigger: isHidden)
    }
}

// MARK: - Investor

private struct PortfolioItem: Identifiable {
    let name: String
    let logo: ImageResource
    let value: Double
    let change: Int
    var id: String { name }
}

private struct WatchItem: Identifiable {
    let name: String
    let sector: String
    let filter: String
    let logo: ImageResource
    let price: Double
    let change: Double
    var id: String { name }
}

private struct InvestorSections: View {
    @Binding var trade: TradeKind?
    @State private var filter = "All watchlist"

    private let holdings = [
        PortfolioItem(name: "SwiftHarvest Ventures", logo: .logoSwiftHarvest40, value: 45_162.77, change: 12),
        PortfolioItem(name: "CoreMedix Labs", logo: .logoCoreMedix, value: 38_420.10, change: -4),
    ]

    private static let filters = ["All watchlist", "Agriculture", "Tech", "Fashion", "Gaming"]

    private let watchlist = [
        WatchItem(name: "TroveMart", sector: "E-commerce", filter: "Tech", logo: .logoTroveMart, price: 45_162.77, change: 1.4),
        WatchItem(name: "Suji’s Fashion House", sector: "Fashion", filter: "Fashion", logo: .logoSuji, price: 28_904.50, change: -2.9),
        WatchItem(name: "StitchWorks Atelier", sector: "Fashion", filter: "Fashion", logo: .logoSewing52, price: 12_310.00, change: 1.4),
        WatchItem(name: "SwiftHarvest Ventures", sector: "AgriTech", filter: "Agriculture", logo: .logoSwiftHarvest40, price: 62.99, change: 3.2),
    ]

    private var visibleWatchlist: [WatchItem] {
        filter == "All watchlist" ? watchlist : watchlist.filter { $0.filter == filter }
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                SectionHeader(title: "Portfolio Distribution") { ViewAllButton() }
                HStack(spacing: 8) {
                    ForEach(holdings) { holding in
                        Button {
                            if holding.name == "SwiftHarvest Ventures" { trade = .sell }
                        } label: {
                            StatCard(name: holding.name, value: holding.value.naira, change: holding.change) {
                                Image(holding.logo)
                            }
                        }
                        .buttonStyle(RowPressStyle())
                    }
                }
            }

            VStack(spacing: 12) {
                SectionHeader(title: "My Watchlist") {
                    HStack(spacing: 8) {
                        Button {} label: { Image(.watchlistFilter) }
                            .buttonStyle(RowPressStyle())
                            .accessibilityLabel("Filter watchlist")
                        Button {} label: { Image(.watchlistAdd) }
                            .buttonStyle(RowPressStyle())
                            .accessibilityLabel("Add to watchlist")
                    }
                }

                FilterBar(options: Self.filters, selection: $filter)

                VStack(spacing: 8) {
                    if visibleWatchlist.isEmpty {
                        Text("Nothing on your watchlist in \(filter) yet.")
                            .font(AppFont.interTight(14, relativeTo: .subheadline))
                            .foregroundStyle(Color.grey50)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .transition(.opacity)
                    }
                    ForEach(visibleWatchlist) { item in
                        Button {
                            if item.name == "SwiftHarvest Ventures" { trade = .buy }
                        } label: {
                            WatchRow(item: item)
                        }
                        .buttonStyle(RowPressStyle())
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(Motion.step, value: filter)
            }
        }
    }
}

/// The grey pill of watchlist filters; the cyan selection slides between them.
private struct FilterBar: View {
    let options: [String]
    @Binding var selection: String
    @Namespace private var pill

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isSelected = option == selection
                    Button {
                        withAnimation(Motion.select) { selection = option }
                    } label: {
                        Text(option)
                            .font(AppFont.interTight(12, relativeTo: .caption))
                            .foregroundStyle(isSelected ? .black : Color.grey50)
                            .padding(.horizontal, isSelected ? 16 : 12)
                            .padding(.vertical, 8)
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
        }
        .scrollIndicators(.hidden)
        .background(Capsule().fill(Color.grey80))
        .clipShape(Capsule())
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct WatchRow: View {
    let item: WatchItem

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(item.logo)
                    .resizable()
                    .frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(AppFont.interTight(16, relativeTo: .callout))
                        .foregroundStyle(.white)
                    Text(item.sector)
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        .foregroundStyle(Color.grey50)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.price.naira)
                    .font(AppFont.interTight(16, .semibold, relativeTo: .callout))
                    .foregroundStyle(.white)
                ChangeBadge(text: String(format: "%@%.1f%%", item.change < 0 ? "" : "", item.change),
                            isUp: item.change >= 0, size: .tiny)
            }
        }
        .padding(.vertical, 8)
        .contentShape(.rect)
    }
}

// MARK: - Business owner

private struct Listing: Identifiable {
    let name: String
    let logo: ImageResource
    let raised: Double
    let goal: Double
    var id: String { name }
    var progress: Double { min(raised / goal, 1) }
    var isFullyRaised: Bool { raised >= goal }
}

private struct BusinessSections: View {
    private let listings = [
        Listing(name: "SafeBond Finance", logo: .logoSafeBond, raised: 3_000_000, goal: 5_000_000),
        Listing(name: "CapitalSpring Ltd.", logo: .logoCapitalSpring, raised: 650_000, goal: 5_000_000),
        Listing(name: "StitchWorks Atelier", logo: .logoSewing52, raised: 5_000_000, goal: 5_000_000),
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Stats")
                    .font(AppFont.interTight(16, relativeTo: .headline))
                    .foregroundStyle(.white)
                HStack(spacing: 8) {
                    StatCard(name: "Active Listings", value: "8", change: nil) { StatIcon(.statBriefcase) }
                    StatCard(name: "Active Investors", value: "49", change: 12) { StatIcon(.statUsers) }
                }
            }

            VStack(spacing: 12) {
                SectionHeader(title: "Your Listings") { ViewAllButton() }
                VStack(spacing: 8) {
                    ForEach(listings) { ListingCard(listing: $0) }
                }
            }
        }
    }
}

private struct StatIcon: View {
    let icon: ImageResource
    init(_ icon: ImageResource) { self.icon = icon }

    var body: some View {
        Image(icon)
            .frame(width: 40, height: 40)
            .background(Circle().fill(Color.primary20))
    }
}

/// A listing's funding card. The bar's colour follows its progress: orange while it's
/// under a quarter funded, cyan while it's raising, and green ("Raised") once it's full.
private struct ListingCard: View {
    let listing: Listing
    @State private var shownProgress: Double = 0

    private var tint: Color {
        if listing.isFullyRaised { return .success50 }
        return listing.progress < 0.25 ? .warning50 : .primary50
    }

    private var raisedText: String {
        "\(Self.short(listing.raised)) raised of \(Self.short(listing.goal))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                HStack(spacing: 10) {
                    Image(listing.logo)
                        .resizable()
                        .frame(width: 40, height: 40)
                    Text(listing.name)
                        .font(AppFont.interTight(16, relativeTo: .callout))
                        .foregroundStyle(.white)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(tint).frame(width: 8, height: 8)
                    Text(listing.isFullyRaised ? "Raised" : "Active")
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                // A fully raised listing leads with its total, as in the design.
                if listing.isFullyRaised {
                    Text(raisedText)
                        .font(AppFont.interTight(16, relativeTo: .callout))
                        .foregroundStyle(.white)
                }
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(listing.isFullyRaised ? Color(white: 0.97) : tint.opacity(listing.progress < 0.25 ? 0.1 : 0.2))
                        Capsule().fill(tint)
                            .frame(width: proxy.size.width * shownProgress)
                    }
                }
                .frame(height: 8)
                if !listing.isFullyRaised {
                    Text(raisedText)
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        .foregroundStyle(Color.grey60)
                }
            }
        }
        .padding(16)
        .background(Color.grey80, in: .rect(cornerRadius: 24))
        .onAppear {
            withAnimation(.spring(duration: 0.9, bounce: 0).delay(0.15)) { shownProgress = listing.progress }
        }
        .accessibilityElement(children: .combine)
    }

    /// "₦2.5M", "₦650K"
    private static func short(_ value: Double) -> String {
        if value >= 1_000_000 {
            let m = value / 1_000_000
            return "₦" + (m.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(m)) : String(format: "%.1f", m)) + "M"
        }
        return "₦\(Int(value / 1000))K"
    }
}

// MARK: - Shared pieces

private struct SectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.interTight(16, relativeTo: .headline))
                .foregroundStyle(.white)
            Spacer()
            trailing
        }
    }
}

private struct ViewAllButton: View {
    var body: some View {
        Button("View All") {}
            .font(AppFont.interTight(14, relativeTo: .subheadline))
            .foregroundStyle(Color.grey50)
    }
}

/// Grey card used for portfolio holdings and for stats: icon, name, then a bold value
/// with an optional green/red change badge.
private struct StatCard<Icon: View>: View {
    let name: String
    let value: String
    let change: Int?
    @ViewBuilder var icon: Icon

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            icon
            VStack(alignment: .leading, spacing: 8) {
                Text(name)
                    .font(AppFont.interTight(14, relativeTo: .subheadline))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(value)
                        .font(AppFont.interTight(20, .semibold, relativeTo: .title3))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let change {
                        ChangeBadge(text: change >= 0 ? "+\(change)" : "\(change)", isUp: change >= 0, size: .small)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.grey80, in: .rect(cornerRadius: 24))
    }
}

/// Green (up) or red (down) pill with the design's trend arrow.
private struct ChangeBadge: View {
    enum Size { case small, tiny }
    let text: String
    let isUp: Bool
    let size: Size

    var body: some View {
        let color: Color = isUp ? .success50 : .error50
        HStack(spacing: size == .small ? 4 : 2) {
            switch size {
            case .small: Image(isUp ? .trendUpSmall : .trendDownSmall)
            case .tiny: Image(isUp ? .trendUpTiny : .trendDownTiny)
            }
            Text(text)
                .font(AppFont.interTight(size == .small ? 12 : 8, relativeTo: .caption2))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, size == .small ? 4 : 2)
        .background(Capsule().fill(color.opacity(0.12)))
    }
}

private struct RoundIconButton: View {
    let icon: ImageResource
    let label: String

    var body: some View {
        Button {} label: { Image(icon) }
            .buttonStyle(CircleIconButtonStyle())
            .accessibilityLabel(label)
    }
}

// MARK: - Tab bar

private protocol HomeTab: Hashable, CaseIterable, Identifiable where AllCases == [Self] {
    var title: String { get }
    var icon: ImageResource { get }
}

private enum InvestorTab: String, HomeTab {
    case home, portfolio, wallet, profile
    var id: Self { self }
    var title: String {
        switch self {
        case .home: "Home"
        case .portfolio: "Portfolio"
        case .wallet: "Wallet"
        case .profile: "Profile"
        }
    }
    var icon: ImageResource {
        switch self {
        case .home: .tabHome
        case .portfolio: .tabChart
        case .wallet: .tabMoneyBag
        case .profile: .tabUser
        }
    }
}

private enum BusinessTab: String, HomeTab {
    case home, listings, profile
    var id: Self { self }
    var title: String {
        switch self {
        case .home: "Home"
        case .listings: "Listings"
        case .profile: "Profile"
        }
    }
    var icon: ImageResource {
        switch self {
        case .home: .tabHome
        case .listings: .tabBriefcase
        case .profile: .tabUser
        }
    }
}

/// The floating dark-teal tab bar: the selected tab is a cyan capsule with its icon and
/// name, which slides to whichever tab you tap; the others show just their icon.
private struct FloatingTabBar<Tab: HomeTab>: View {
    let tabs: [Tab]
    @Binding var selection: Tab
    @Namespace private var pill

    /// rgba(0,0,0,0.8) over the brand cyan, as in the design.
    private static var background: Color { Color(red: 0, green: 43 / 255, blue: 49 / 255) }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                let isSelected = tab == selection
                Button {
                    withAnimation(.spring(duration: 0.4, bounce: 0.2)) { selection = tab }
                } label: {
                    HStack(spacing: 4) {
                        Image(tab.icon)
                            .renderingMode(.template)
                            .foregroundStyle(isSelected ? .black : .white)
                        if isSelected {
                            Text(tab.title)
                                .font(AppFont.interTight(14, relativeTo: .subheadline))
                                .foregroundStyle(.black)
                                .fixedSize()
                                .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
                        }
                    }
                    .padding(.horizontal, isSelected ? 24 : 0)
                    .frame(maxWidth: isSelected ? nil : .infinity)
                    .frame(height: 48)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(Color.primary50)
                                .overlay(Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 1))
                                .matchedGeometryEffect(id: "tab", in: pill)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(8)
        .frame(width: 300)
        .background(Capsule().fill(Self.background.opacity(0.96)))
        .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// Stand-in for tabs that aren't designed yet.
private struct TabPlaceholder: View {
    let title: String
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(AppFont.interTight(24, relativeTo: .title2))
                .foregroundStyle(.white)
            Text("This tab isn't part of the prototype yet.")
                .font(AppFont.interTight(14, relativeTo: .subheadline))
                .foregroundStyle(Color.grey50)
            Button("Back to all flows", action: onExit)
                .buttonStyle(SecondaryButtonStyle())
                .frame(width: 200)
                .padding(.top, 16)
        }
        .transition(.opacity)
    }
}

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}
