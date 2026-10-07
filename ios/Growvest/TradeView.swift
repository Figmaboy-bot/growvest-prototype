import SwiftUI

/// "Buy SwiftHarvest Ventures" / "Sell SwiftHarvest Ventures": amount entry with a custom keypad.
struct TradeView: View {
    @State private var flow: InvestmentFlow
    @Environment(\.dismiss) private var dismiss

    private var isSheetPresented: Bool { flow.sheetStep != nil }
    /// The screen's height before the PIN keyboard opens. The keyboard shortens the navigation
    /// container, which would slide this bottom-aligned screen up behind the sheet, so while the
    /// PIN step is up the screen keeps this height, pinned to the top.
    @State private var restingHeight: CGFloat?

    init(kind: TradeKind) {
        _flow = State(initialValue: InvestmentFlow(kind: kind))
    }

    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 0) {
                    AmountHeader(flow: flow)
                        .padding(.top, 20)

                    Spacer(minLength: 16)
                        .frame(maxHeight: 72)

                    VStack(spacing: 16) {
                        SummaryCard(rows: flow.isSelling ? [
                            ("Current share price", flow.holding.pricePerShare.wholeNaira + " / share"),
                            ("Shares available", "\(flow.holding.shares) shares"),
                        ] : [
                            ("Current Value", flow.business.currentValue.naira),
                            ("Price per share", flow.business.pricePerShare.naira),
                        ])

                        QuickPicks(flow: flow)

                        Keypad(onKey: flow.press)
                            .layoutPriority(1)

                        // Over-selling keeps Continue disabled and says why.
                        Button(flow.exceedsHolding ? "Only \(flow.holding.shares) shares available" : "Continue") {
                            flow.sheetStep = .payment
                        }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(!flow.canContinue)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                .frame(maxWidth: 480)
                // Bottom-aligned: on tall phones any height the keypad can't use goes to the
                // top, never into a gap between Continue and the home indicator.
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .frame(height: flow.sheetStep == .pin ? restingHeight : nil)
                // minHeight 0 lets this frame shrink with the container instead of growing to the
                // frozen height and being re-centred, so the screen's top stays put.
                .frame(minHeight: 0, maxHeight: .infinity, alignment: .top)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    if flow.sheetStep != .pin { restingHeight = height }
                }
                .background(Color(.systemBackground))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        // Leaves the flow and returns to the flow launcher.
                        Button { dismiss() } label: {
                            Image(.arrowLeft)
                        }
                        .modifier(LegacyCircleBackground())
                        .accessibilityLabel("Back to flows")
                    }
                    ToolbarItem(placement: .principal) {
                        Text("\(flow.isSelling ? "Sell" : "Buy") \(flow.business.name)")
                            .font(AppFont.interTight(16, relativeTo: .headline))
                            .foregroundStyle(.white)
                    }
                }
                .sensoryFeedback(.selection, trigger: flow.typedInput)
                #if DEBUG
                .onAppear(perform: applyDemoLaunchArguments)
                #endif
            }
            // Design backdrop: a light 2.5pt blur (Figma: backdrop-blur 2px) that eases off as the sheet is dragged away.
            .blur(radius: isSheetPresented ? 2.5 * (1 - flow.sheetDragProgress) : 0)
            .scaleEffect(isSheetPresented ? 0.98 + 0.02 * flow.sheetDragProgress : 1)
            .accessibilityHidden(isSheetPresented)

            if isSheetPresented {
                // Design backdrop: 10% white over the lightly blurred screen.
                Color.white.opacity(0.1)
                    .opacity(1 - flow.sheetDragProgress)
                .ignoresSafeArea()
                    .onTapGesture {
                        if flow.sheetStep != .success { flow.sheetStep = nil }
                    }
                    .accessibilityHidden(true)
                    .transition(.opacity)

                InvestmentSheet(flow: flow)
                    .transition(.move(edge: .bottom))
            }
        }
        // The screen behind the sheet stays put when the PIN keyboard opens;
        // InvestmentSheet lifts itself above the keyboard instead.
        .ignoresSafeArea(.keyboard)
        .animation(Motion.sheet, value: isSheetPresented)
    }
}

#if DEBUG
extension TradeView {
    /// Lets screenshots/demos jump into the flow, e.g.
    /// `simctl launch <device> com.growvest.prototype -demoAmount 45162.77 -demoStep review`
    private func applyDemoLaunchArguments() {
        let defaults = UserDefaults.standard
        if let amount = defaults.string(forKey: "demoAmount") {
            amount.map(String.init).forEach(flow.press)
        }
        switch defaults.string(forKey: "demoStep") {
        case "payment": flow.sheetStep = .payment
        case "review": flow.sheetStep = .review
        case "pin":
            // Arrives via review, as a real user does, so the screen behind settles first.
            flow.sheetStep = .review
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.8))
                flow.sheetStep = .pin
            }
        case "success": flow.complete()
        case "swap":
            // Switches to shares and back, for checking the swap animation.
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.5))
                NotificationCenter.default.post(name: .demoSwapInput, object: nil)
                try? await Task.sleep(for: .seconds(2))
                NotificationCenter.default.post(name: .demoSwapInput, object: nil)
            }
        case "typing":
            // Types an amount key by key, then deletes it, for checking the digit animations.
            Task { @MainActor in
                for key in ["4", "5", "1", "6", "2", ".", "7", "7"] {
                    try? await Task.sleep(for: .milliseconds(450))
                    flow.press(key)
                }
                for _ in 0..<8 {
                    try? await Task.sleep(for: .milliseconds(650))
                    flow.press("back")
                }
            }
        case "tour":
            // Walks the whole flow on a timer, for recording/demoing the transitions.
            Task { @MainActor in
                for step in [InvestmentFlow.Step.payment, .review, .pin, .review, .pin] {
                    try? await Task.sleep(for: .seconds(1.6))
                    flow.sheetStep = step
                }
                try? await Task.sleep(for: .seconds(1.6))
                flow.complete()
            }
        default: break
        }
    }
}
#endif

private struct AmountHeader: View {
    let flow: InvestmentFlow

    private var isSharesMode: Bool { flow.inputMode == .shares }

    var body: some View {
        VStack(spacing: 12) {
            // The two prompts trade places with a short vertical slide.
            ZStack {
                prompt(flow.isSelling ? "How much shares would you like to sell?" : "How much would you like to invest?",
                       isShown: !isSharesMode, direction: -1)
                prompt(flow.isSelling ? "How many shares do you want to sell?" : "How many shares would you like to buy?",
                       isShown: isSharesMode, direction: 1)
            }
            ValueSwap(flow: flow)
        }
    }

    private func prompt(_ text: String, isShown: Bool, direction: CGFloat) -> some View {
        Text(text)
            .font(AppFont.interTight(14, relativeTo: .subheadline))
            .foregroundStyle(Color.grey50)
            .opacity(isShown ? 1 : 0)
            .offset(y: isShown ? 0 : 8 * direction)
            .blur(radius: isShown ? 0 : 3)
            // Outgoing prompt leaves quickly; the incoming one arrives just after, so they never overlap.
            .animation(isShown ? .spring(duration: 0.4, bounce: 0).delay(0.12) : .easeIn(duration: 0.14), value: isShown)
            .accessibilityHidden(!isShown)
    }
}

/// The big number and the pill beneath it. Each value is one continuous view that
/// physically moves between the two slots when you tap the pill: the naira amount shrinks
/// down into the pill while the share count grows up out of it (and vice versa), and the
/// capsule stretches to fit. Both values are always drawn at the big size and scaled, so
/// the move is a single smooth transform rather than a cross-fade.
private struct ValueSwap: View {
    let flow: InvestmentFlow

    @State private var availableWidth: CGFloat = 0
    @State private var amountWidth: CGFloat = 0
    @State private var sharesWidth: CGFloat = 0
    @State private var isPillPressed = false
    @State private var suffixWidth: CGFloat = 0
    /// While the values travel between slots they hold their text steady; the amount then
    /// updates to the exact cost of whole shares once it has landed in the pill.
    @State private var heldTexts: (amount: String, shares: String)?

    private let bigHeight: CGFloat = 60
    private let pillHeight: CGFloat = 40
    private let gap: CGFloat = 4
    /// 12pt pill text, drawn from the 56pt big glyphs.
    private let pillScale: CGFloat = 12 / 56

    private var isSharesMode: Bool { flow.inputMode == .shares }
    private var bigY: CGFloat { bigHeight / 2 }
    private var pillY: CGFloat { bigHeight + gap + pillHeight / 2 }

    private static let enUS = Locale(identifier: "en_US")

    var body: some View {
        let amountIsBig = !isSharesMode
        let pillContentWidth = amountIsBig ? sharesWidth * pillScale + suffixWidth : amountWidth * pillScale
        let pillWidth = pillContentWidth + 40
        let pressScale: CGFloat = isPillPressed ? 0.94 : 1

        ZStack {
            Capsule()
                .fill(Color.grey80)
                .brightness(isPillPressed ? 0.04 : 0)
                .frame(width: pillWidth, height: pillHeight)
                .scaleEffect(pressScale)
                .position(x: availableWidth / 2, y: pillY)

            value(heldTexts?.amount ?? amountText, prefix: "₦ ", hasSuffix: false,
                  placeholder: "0.00", isBig: amountIsBig, width: $amountWidth)
            value(heldTexts?.shares ?? sharesText, prefix: nil, hasSuffix: true,
                  placeholder: "0", isBig: !amountIsBig, width: $sharesWidth)

            // "shares" belongs to the pill, not to the number: it never scales, it just
            // fades out in place when the count leaves the pill and back in once it returns.
            Text(flow.shares == 1 ? " share" : " shares")
                .font(AppFont.interTight(12, relativeTo: .caption))
                .foregroundStyle(Color.grey30)
                .fixedSize()
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { suffixWidth = $0 }
                .scaleEffect(pressScale, anchor: .leading)
                .opacity(amountIsBig ? 1 : 0)
                .blur(radius: amountIsBig ? 0 : 2)
                .animation(amountIsBig ? .easeOut(duration: 0.25).delay(0.3) : .easeOut(duration: 0.12), value: amountIsBig)
                .position(x: availableWidth / 2 + (sharesWidth * pillScale * pressScale) / 2 - (amountIsBig ? suffixWidth / 2 : 0)
                             + suffixWidth / 2,
                          y: pillY)
                .accessibilityHidden(true)

            // Tap target for the pill
            Button(action: swap) {
                Color.clear
                    .frame(width: pillWidth, height: pillHeight)
                    .contentShape(Capsule())
            }
            .buttonStyle(PressReportingStyle(isPressed: $isPillPressed))
            .position(x: availableWidth / 2, y: pillY)
            .sensoryFeedback(.impact(weight: .light), trigger: flow.inputMode)
            #if DEBUG
            .onReceive(NotificationCenter.default.publisher(for: .demoSwapInput)) { _ in swap() }
            #endif
            .accessibilityLabel(isSharesMode ? "\(flow.isSelling ? "Value" : "Cost") \(flow.amount.naira)" : "\(flow.shares) shares")
            .accessibilityHint(isSharesMode ? "Switch to entering an amount" : "Switch to entering shares")
        }
        .frame(maxWidth: .infinity)
        .frame(height: bigHeight + gap + pillHeight)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
        .animation(Motion.press, value: isPillPressed)
        .animation(Motion.select, value: pillWidth)
    }

    private func swap() {
        heldTexts = (amountText, sharesText)
        withAnimation(.spring(duration: 0.55, bounce: 0.12)) { flow.toggleInputMode() }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(560))
            heldTexts = nil      // the landed values now update with their own digit animation
        }
    }

    /// What the amount slot shows: typed naira while entering an amount, otherwise the cost.
    private var amountText: String {
        if !isSharesMode { return flow.typedAmount }
        return flow.shares > 0 ? String(format: "%.2f", flow.amount) : ""
    }

    /// What the shares slot shows: typed shares while entering shares, otherwise what the amount buys.
    private var sharesText: String {
        if isSharesMode { return flow.typedShares }
        return flow.shares > 0 ? String(flow.shares) : ""
    }

    private func value(_ text: String, prefix: String?, hasSuffix: Bool, placeholder: String,
                       isBig: Bool, width: Binding<CGFloat>) -> some View {
        let natural = width.wrappedValue
        let fit = natural > 0 && availableWidth > 0 ? min(1, availableWidth / natural) : 1
        let color: Color = isBig ? (text.isEmpty ? .grey50 : .white) : .grey30
        let scale = isBig ? fit : pillScale * (isPillPressed ? 0.94 : 1)
        // In the pill, the number + "shares" label are centred together.
        let suffixShift = (hasSuffix && !isBig) ? suffixWidth / 2 : 0
        return GlyphNumber(typed: text, prefix: prefix, placeholder: placeholder)
            .fixedSize()
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width.wrappedValue = $0 }
            .foregroundStyle(color)
            .scaleEffect(scale)
            .position(x: availableWidth / 2 - suffixShift, y: isBig ? bigY : pillY)
            // Staggered so the two values pass at different heights instead of colliding:
            // the one heading into the pill moves a touch quicker, the one rising starts a beat later.
            .animation(isBig ? .spring(duration: 0.55, bounce: 0.1).delay(0.06) : .spring(duration: 0.42, bounce: 0),
                       value: isBig)
            .accessibilityHidden(!isBig)
            .accessibilityLabel(isSharesMode ? "\(flow.shares) shares" : "Amount \(flow.amount.naira)")
    }
}

/// The four quick-pick chips. Their labels follow the input mode (₦10K… or 5, 10, 50, 100
/// shares) and change with a left-to-right ripple: each label lifts out with a little blur
/// as the new one rises in.
private struct QuickPicks: View {
    let flow: InvestmentFlow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                let label = flow.quickPickLabels[index]
                Button { flow.selectQuickPick(index) } label: {
                    ZStack {
                        Text(label)
                            .id(label)
                            .transition(labelTransition(index))
                    }
                }
                .buttonStyle(ChipButtonStyle(isSelected: flow.isQuickPickSelected(index)))
                .accessibilityLabel(flow.inputMode == .shares ? "\(label) shares" : label)
            }
        }
    }

    private func labelTransition(_ index: Int) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        let delay = 0.1 + Double(index) * 0.045
        return .asymmetric(
            insertion: .offset(y: 10).combined(with: .opacity).combined(with: .blurred(3))
                .animation(.spring(duration: 0.4, bounce: 0.1).delay(delay)),
            removal: .offset(y: -10).combined(with: .opacity).combined(with: .blurred(3))
                .animation(.easeIn(duration: 0.16).delay(delay - 0.1))
        )
    }
}

/// Reports a button's pressed state so the pill's visuals (drawn elsewhere) can react.
private struct PressReportingStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in isPressed = pressed }
    }
}

/// A number built glyph by glyph so typing and deleting only animate the digit that
/// changed: a new digit rises in at the end, a deleted digit drops away, and everything
/// else (including the thousands separators) slides into place.
private struct GlyphNumber: View {
    let typed: String
    var prefix: String?
    var placeholder = "0.00"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Glyph: Identifiable {
        let id: String
        let character: String
        var isPlaceholder = false
    }

    /// Digits are keyed by their position in what was typed (plus the digit itself), so
    /// earlier digits keep their identity as you type or delete. Commas are keyed by their
    /// group counted from the right, so they slide rather than pop.
    private var glyphs: [Glyph] {
        guard !typed.isEmpty else {
            return placeholder.enumerated().map {
                Glyph(id: "placeholder-\($0.offset)", character: String($0.element), isPlaceholder: true)
            }
        }
        let parts = typed.split(separator: ".", omittingEmptySubsequences: false)
        let integer = Array(parts[0].isEmpty ? "0" : parts[0])
        var result: [Glyph] = []
        for (index, digit) in integer.enumerated() {
            let fromRight = integer.count - index
            if index > 0, fromRight % 3 == 0 {
                result.append(Glyph(id: "comma-\(fromRight / 3)", character: ","))
            }
            result.append(Glyph(id: "int-\(index)-\(digit)", character: String(digit)))
        }
        if parts.count > 1 {
            result.append(Glyph(id: "dot", character: "."))
            for (index, digit) in parts[1].enumerated() {
                result.append(Glyph(id: "dec-\(index)-\(digit)", character: String(digit)))
            }
        }
        return result
    }

    private var glyphTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                // New digits rise into place with a touch of motion blur.
                insertion: .offset(y: 22).combined(with: .opacity).combined(with: .blurred(3)),
                // Deleted digits drop: they stay sharp and fall with gravity-like acceleration,
                // shrinking slightly and fading out towards the end of the fall.
                removal: .offset(y: 44)
                    .combined(with: .scale(scale: 0.7, anchor: .top))
                    .combined(with: .opacity)
                    .animation(.easeIn(duration: 0.32))
            )
    }

    /// The grey "0.00" isn't a value being deleted, so it never drops: it dissolves in place
    /// when the first digit is typed, and fades back in (after the last digit has dropped)
    /// when the input is cleared.
    private var placeholderTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .opacity.combined(with: .blurred(3))
                    .animation(.easeOut(duration: 0.25).delay(0.18)),
                removal: .opacity.combined(with: .scale(scale: 0.92)).combined(with: .blurred(4))
                    .animation(.easeOut(duration: 0.18))
            )
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            if let prefix {
                Text(prefix)
                    .font(AppFont.interTight(56, relativeTo: .largeTitle))
            }
            ForEach(glyphs) { glyph in
                Text(glyph.character)
                    .font(AppFont.interTight(56, .semibold, relativeTo: .largeTitle))
                    .transition(glyph.isPlaceholder ? placeholderTransition : glyphTransition)
            }
        }
        .lineLimit(1)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: typed)
    }
}

private struct Keypad: View {
    let onKey: (String) -> Void

    private let rows = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], [".", "0", "back"]]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(row, id: \.self) { key in
                        Button { onKey(key) } label: {
                            if key == "back" {
                                Image(.backspace)
                            } else {
                                Text(key)
                                    .font(AppFont.interTight(28, relativeTo: .title))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(KeyButtonStyle(filled: key == "back"))
                        .accessibilityLabel(key == "back" ? "Delete" : key)
                    }
                }
            }
        }
    }
}

private struct KeyButtonStyle: ButtonStyle {
    var filled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 72)
            .background(
                Capsule()
                    .fill(Color.grey80)
                    .opacity(filled || configuration.isPressed ? 1 : 0)
                    .scaleEffect(configuration.isPressed && !filled ? 0.92 : 1)
            )
            .contentShape(Capsule())
            .animation(Motion.press, value: configuration.isPressed)
    }
}

#Preview {
    TradeView(kind: .buy)
        .preferredColorScheme(.dark)
}

#Preview("Sell") {
    TradeView(kind: .sell)
        .preferredColorScheme(.dark)
}

#if DEBUG
extension Notification.Name {
    /// Lets the `-demoStep swap` launch argument press the pill.
    static let demoSwapInput = Notification.Name("demoSwapInput")
}
#endif
