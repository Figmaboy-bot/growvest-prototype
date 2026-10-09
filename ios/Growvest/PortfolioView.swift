import SwiftUI

/// The investor's Portfolio tab: Overview (Figma 1092-4222), with the allocation donut,
/// totals, asset allocation and the performance chart, and My Investments (1092-7987),
/// a card per holding that opens the business's page.
struct PortfolioView: View {
    enum Section: String, CaseIterable, Identifiable {
        case overview = "Overview", investments = "My Investments"
        var id: Self { self }
    }

    @State private var section: Section = .overview
    @Namespace private var pill
    private static let top = "PortfolioTop"

    /// The businesses the user holds shares in, in allocation order.
    static var holdings: [Company] { Company.all.filter { $0.holding != nil } }

    var body: some View {
        ScrollViewReader { scroller in
        ScrollView {
            VStack(spacing: 24) {
                Text("Portfolio")
                    .id(Self.top)
                    .font(AppFont.interTight(16, relativeTo: .headline))
                    .foregroundStyle(.white)
                    .frame(height: 40)
                    .accessibilityAddTraits(.isHeader)

                picker

                Group {
                    switch section {
                    case .overview: PortfolioOverview()
                    case .investments: InvestmentList()
                    }
                }
                .id(section)
                .transition(.asymmetric(
                    insertion: .move(edge: section == .overview ? .leading : .trailing).combined(with: .opacity),
                    removal: .move(edge: section == .overview ? .trailing : .leading).combined(with: .opacity)
                ))
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 120)          // room to scroll past the floating tab bar
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .animation(Motion.step, value: section)
        // Each view starts from the top, not wherever the other one was scrolled to.
        .onChange(of: section) { withAnimation(Motion.step) { scroller.scrollTo(Self.top, anchor: .top) } }
        }
        #if DEBUG
        .onAppear {
            if UserDefaults.standard.string(forKey: "demoPortfolio") == "investments" { section = .investments }
        }
        #endif
    }

    /// Overview / My Investments: the cyan selection slides between the two.
    private var picker: some View {
        HStack(spacing: 0) {
            ForEach(Section.allCases) { option in
                let isSelected = option == section
                Button {
                    withAnimation(Motion.step) { section = option }
                } label: {
                    Text(option.rawValue)
                        .font(AppFont.interTight(14, relativeTo: .subheadline))
                        .foregroundStyle(isSelected ? Color.ink : Color.grey50)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background {
                            if isSelected {
                                Capsule().fill(Color.primary50)
                                    .matchedGeometryEffect(id: "selection", in: pill)
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
        .sensoryFeedback(.selection, trigger: section)
    }
}

// MARK: - Overview

private struct Slice: Identifiable {
    let name: String
    let value: Double
    let color: Color
    var id: String { name }
}

private struct PortfolioOverview: View {
    /// The holding picked on the donut or in the allocation list.
    @State private var selected: String?
    @State private var range: ChartRange = .max

    private static let colors: [Color] = [.primary50, .chartBlue, .chartOrange, .chartAmber]

    private let holdings = PortfolioView.holdings

    private var slices: [Slice] {
        holdings.enumerated().map { index, company in
            Slice(name: company.name, value: company.holding?.currentValue ?? 0,
                  color: Self.colors[index % Self.colors.count])
        }
    }

    private var total: Double { holdings.reduce(0) { $0 + ($1.holding?.currentValue ?? 0) } }
    private var invested: Double { holdings.reduce(0) { $0 + ($1.holding?.invested ?? 0) } }
    private var gain: Double { total - invested }
    private var gainPercent: Double { invested > 0 ? gain / invested * 100 : 0 }

    var body: some View {
        VStack(spacing: 24) {
            AllocationDonut(slices: slices, total: total, selected: $selected)

            HStack(spacing: 8) {
                TotalCard(title: "Total Invested") {
                    Text(invested.naira)
                        .font(AppFont.interTight(20, .semibold, relativeTo: .title3))
                        .foregroundStyle(.white)
                }
                .fixedSize(horizontal: true, vertical: false)
                TotalCard(title: "Total return") {
                    HStack(spacing: 12) {
                        Text(gain.naira)
                            .font(AppFont.interTight(20, .semibold, relativeTo: .title3))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        ChangeBadge(text: String(format: "%.1f%%", abs(gainPercent)), isUp: gain >= 0, size: .small)
                    }
                }
            }
            .frame(height: 106)

            LabeledSection(title: "Asset allocation") {
                HairlineCard {
                    ForEach(slices) { slice in
                        AllocationRow(slice: slice, isSelected: selected == slice.name, isDimmed: selected != nil && selected != slice.name) {
                            withAnimation(Motion.select) { selected = selected == slice.name ? nil : slice.name }
                        }
                    }
                }
            }

            LabeledSection(title: "Investment performance") {
                PriceChart(source: ChartSource(seed: "Portfolio", price: total, change: gainPercent,
                                               history: PriceChart.designHistory),
                           range: $range)
            }
        }
        .sensoryFeedback(.selection, trigger: selected)
    }
}

/// The donut of how the portfolio splits across holdings, with the total in the middle.
/// It sweeps in clockwise on first show. Tap a segment (or its row below) to pull it
/// forward and show its value in the middle; tap it again, or the middle, to go back.
private struct AllocationDonut: View {
    let slices: [Slice]
    let total: Double
    @Binding var selected: String?
    @State private var drawn = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let size: CGFloat = 255
    private static let lineWidth: CGFloat = 24
    private static let selectedWidth: CGFloat = 30
    /// Clear space between segments, on top of their round caps.
    private static let gap: CGFloat = 10

    /// Each slice's share of the circle, as start and end fractions.
    private var spans: [(start: Double, end: Double)] {
        var start = 0.0
        return slices.map { slice in
            let end = start + slice.value / max(total, 1)
            defer { start = end }
            return (start, end)
        }
    }

    var body: some View {
        let radius = (Self.size - Self.selectedWidth) / 2
        // Round caps reach half a line width past each end, so leave room for them too.
        let gapFraction = Double((Self.lineWidth + Self.gap) / (2 * .pi * radius))
        let focus = slices.first { $0.name == selected }

        ZStack {
            ForEach(Array(zip(slices, spans)), id: \.0.id) { slice, span in
                let isSelected = slice.name == selected
                let from = span.start * drawn + gapFraction / 2
                let to = max(from, span.end * drawn - gapFraction / 2)
                Circle()
                    .trim(from: from, to: to)
                    .stroke(slice.color, style: StrokeStyle(lineWidth: isSelected ? Self.selectedWidth : Self.lineWidth,
                                                            lineCap: .round))
                    .opacity(selected == nil || isSelected ? 1 : 0.3)
                    .rotationEffect(.degrees(-90))
                    .padding(Self.selectedWidth / 2)
            }

            VStack(spacing: 4) {
                Text(focus?.name ?? "Total portfolio value")
                    .font(AppFont.interTight(12, relativeTo: .caption))
                    .foregroundStyle(Color.grey50)
                    .contentTransition(.opacity)
                Text((focus?.value ?? total).naira)
                    .font(AppFont.interTight(28, .semibold, relativeTo: .title))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let focus {
                    Text(String(format: "%.0f%% of portfolio", focus.value / max(total, 1) * 100))
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        .foregroundStyle(focus.color)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .frame(width: Self.size - 2 * Self.selectedWidth - 16)
        }
        .frame(width: Self.size, height: Self.size)
        .contentShape(Circle())
        .onTapGesture { location in
            withAnimation(Motion.select) { selected = slice(at: location) }
        }
        .onAppear {
            guard drawn == 0 else { return }
            if reduceMotion { drawn = 1 } else { withAnimation(.spring(duration: 1.1, bounce: 0).delay(0.1)) { drawn = 1 } }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Total portfolio value, \(total.naira)")
        .accessibilityValue(slices.map { "\($0.name) \(Int(($0.value / max(total, 1) * 100).rounded()))%" }.joined(separator: ", "))
    }

    /// The slice under a tap on the ring; nothing for the middle, or the slice already picked.
    private func slice(at location: CGPoint) -> String? {
        let dx = location.x - Self.size / 2, dy = location.y - Self.size / 2
        let distance = (dx * dx + dy * dy).squareRoot()
        guard distance > Self.size / 2 - Self.selectedWidth - 12 else { return nil }
        // Clockwise from the top, as the ring is drawn.
        var angle = atan2(dx, -dy) / (2 * .pi)
        if angle < 0 { angle += 1 }
        guard let index = spans.firstIndex(where: { angle >= $0.start && angle < $0.end }) else { return nil }
        let name = slices[index].name
        return name == selected ? nil : name
    }
}

private struct TotalCard<Value: View>: View {
    let title: String
    @ViewBuilder var value: Value

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(AppFont.interTight(14, relativeTo: .subheadline))
                .foregroundStyle(Color.grey50)
            Spacer(minLength: 8)
            value
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.grey80, in: .rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }
}

private struct AllocationRow: View {
    let slice: Slice
    let isSelected: Bool
    let isDimmed: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                HStack(spacing: 8) {
                    Circle().fill(slice.color)
                        .frame(width: 10, height: 10)
                        .scaleEffect(isSelected ? 1.3 : 1)
                    Text(slice.name)
                        .font(AppFont.interTight(14, relativeTo: .subheadline))
                        .foregroundStyle(isSelected ? .white : Color.grey50)
                }
                Spacer(minLength: 12)
                Text(slice.value.naira)
                    .font(AppFont.interTight(14, relativeTo: .subheadline))
                    .foregroundStyle(.white)
            }
            .opacity(isDimmed ? 0.45 : 1)
            .contentShape(.rect)
        }
        .buttonStyle(RowPressStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - My Investments

private struct InvestmentList: View {
    var body: some View {
        VStack(spacing: 8) {
            ForEach(PortfolioView.holdings) { company in
                if let stake = company.holding {
                    NavigationLink(value: HomeRoute.company(company.name)) {
                        InvestmentCard(company: company, stake: stake)
                    }
                    .buttonStyle(RowPressStyle())
                }
            }
        }
    }
}

private struct InvestmentCard: View {
    let company: Company
    let stake: Company.Stake

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(company.logo)
                        .resizable()
                        .frame(width: 48, height: 48)
                    Text(company.name)
                        .font(AppFont.interTight(14, relativeTo: .subheadline))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Value")
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        .foregroundStyle(Color.grey50)
                    Text(stake.currentValue.naira)
                        .font(AppFont.interTight(20, .semibold, relativeTo: .title3))
                        .tracking(-0.4)
                        .foregroundStyle(.white)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle().fill(.black).frame(height: 1)

            VStack(spacing: 0) {
                row("Return Of Investment (ROI)", stake.gainPercent >= 0 ? "+\(stake.gainPercent)%" : "\(stake.gainPercent)%")
                    .padding(.bottom, 16)
                Rectangle().fill(.black).frame(height: 1)
                row("Amount Invested", stake.invested.naira)
                    .padding(.vertical, 16)
                Rectangle().fill(.black).frame(height: 1)
                row("Status", stake.isActive ? "Active" : "Matured")
                    .padding(.top, 16)
            }
            .padding(.vertical, 16)
        }
        .background(Color.grey80, in: .rect(cornerRadius: 20))
        .contentShape(.rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Color.grey50)
            Spacer(minLength: 12)
            Text(value).foregroundStyle(.white)
        }
        .font(AppFont.interTight(14, relativeTo: .subheadline))
        .padding(.horizontal, 16)
    }
}
