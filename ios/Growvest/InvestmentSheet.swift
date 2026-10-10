import LocalAuthentication
import SwiftUI
import UIKit

/// The floating bottom sheet that walks through payment method → review → PIN → success.
/// Matches the design rather than the system sheet: it floats 12pt in from the screen
/// edges, has 40pt corners all round, and its height follows the current step's content.
/// Drag it down (or tap the backdrop) to dismiss.
struct InvestmentSheet: View {
    @Bindable var flow: InvestmentFlow
    @State private var contentHeight: CGFloat = 0
    /// Keeps showing the last step while the sheet animates out after `sheetStep` becomes nil.
    @State private var displayedStep: InvestmentFlow.Step
    @State private var dragOffset: CGFloat = 0
    /// Drives the hand-off between steps: fade out → swap content → resize + fade in.
    @State private var isContentVisible = true
    /// How far the keyboard overlaps the screen bottom. The buy screen ignores the keyboard so
    /// it stays put behind the sheet, so the sheet lifts itself above the PIN keyboard instead.
    @State private var keyboardOverlap: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(flow: InvestmentFlow) {
        self.flow = flow
        _displayedStep = State(initialValue: flow.sheetStep ?? .payment)
    }

    private var canDismiss: Bool { displayedStep != .success }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                card
                    .frame(height: contentHeight > 0 ? min(contentHeight, proxy.size.height) : nil)
            }
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 12 + keyboardOverlap)
        // Sit 12pt above the physical screen edge (over the home indicator), or 12pt
        // above the keyboard on the PIN step.
        .ignoresSafeArea(.container, edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let screenHeight = (note.object as? UIScreen)?.bounds.height ?? frame.maxY
            let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
            // While the keyboard is up the home-indicator inset still applies, so leave it out.
            withAnimation(.spring(duration: max(duration, 0.25), bounce: 0)) {
                keyboardOverlap = max(screenHeight - frame.minY - homeIndicatorInset, 0)
            }
        }
        .onChange(of: flow.sheetStep) { _, new in
            guard let new, new != displayedStep else { return }
            Task { await show(new) }
        }
        .sensoryFeedback(.success, trigger: flow.sheetStep) { _, new in new == .success }
        .onAppear { flow.sheetDragProgress = 0 }
    }

    private var card: some View {
        ScrollView {
            stepView(displayedStep)
                .padding(16)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    withAnimation(contentHeight == 0 ? nil : Motion.step) { contentHeight = height }
                }
                .opacity(isContentVisible ? 1 : 0)
                .scaleEffect(isContentVisible || reduceMotion ? 1 : 0.97, anchor: .top)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .background(.black)
        .clipShape(.rect(cornerRadius: 40))
        .offset(y: dragOffset)
        .simultaneousGesture(dragToDismiss)
        .accessibilityAddTraits(.isModal)
    }

    @ViewBuilder
    private func stepView(_ step: InvestmentFlow.Step) -> some View {
        switch step {
        case .payment: PaymentStep(flow: flow)
        case .review: ReviewStep(flow: flow)
        case .pin: PinStep(flow: flow)
        case .success: SuccessStep(flow: flow)
        }
    }

    /// Step hand-off. Done in sequence (rather than overlapping insert/remove transitions)
    /// so the sheet never shows two steps at once or clips the outgoing one while resizing.
    @MainActor
    private func show(_ step: InvestmentFlow.Step) async {
        withAnimation(.easeOut(duration: 0.14)) { isContentVisible = false }
        try? await Task.sleep(for: .milliseconds(110))
        displayedStep = step                     // height change springs via onGeometryChange
        withAnimation(reduceMotion ? .easeOut(duration: 0.2) : Motion.step) {
            isContentVisible = true
        }
    }

    /// Follows the finger 1:1 downwards (rubber-banded upwards), then either springs
    /// back or flings the sheet away using the gesture's velocity.
    private var dragToDismiss: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let y = value.translation.height
                dragOffset = y > 0 ? (canDismiss ? y : y * 0.15) : -sqrt(-y) * 2
                flow.sheetDragProgress = canDismiss ? min(max(y / 400, 0), 1) : 0
            }
            .onEnded { value in
                let velocity = value.velocity.height
                let shouldDismiss = canDismiss
                    && (value.translation.height > 120 || value.predictedEndTranslation.height > 320)
                if shouldDismiss {
                    // Carry the flick's momentum off screen, then remove the sheet.
                    let target: CGFloat = 1000
                    withAnimation(Motion.release(velocity: velocity, distance: target - dragOffset, duration: 0.4)) {
                        dragOffset = target
                        flow.sheetDragProgress = 1
                    } completion: {
                        flow.sheetStep = nil
                    }
                } else {
                    withAnimation(Motion.release(velocity: velocity, distance: -dragOffset, bounce: 0.15)) {
                        dragOffset = 0
                        flow.sheetDragProgress = 0
                    }
                }
            }
    }
}

// MARK: - Choose Payment Method

private struct PaymentStep: View {
    @Bindable var flow: InvestmentFlow
    @State private var showAddAlert = false

    var body: some View {
        VStack(spacing: 28) {
            SheetHeader(title: flow.isSelling ? "Choose Payment Destination" : "Choose Payment Method")

            VStack(spacing: 4) {
                ForEach(PaymentMethod.allCases) { method in
                    Button { flow.paymentMethod = method } label: {
                        MethodRow(icon: method.icon, name: method.name, detail: method.maskedNumber,
                                  isSelected: flow.paymentMethod == method)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(flow.paymentMethod == method ? .isSelected : [])
                }
                Button { showAddAlert = true } label: {
                    MethodRow(icon: .plus, name: flow.isSelling ? "Add Payment Destination" : "Add Payment Method",
                              detail: nil, isSelected: false)
                }
                .buttonStyle(.plain)
            }

            Button("Continue") { flow.sheetStep = .review }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(flow.paymentMethod == nil)
        }
        .alert(flow.isSelling ? "Add Payment Destination" : "Add Payment Method", isPresented: $showAddAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(flow.isSelling ? "Adding new payment destinations is coming soon."
                                : "Adding new payment methods is coming soon.")
        }
    }
}

private struct MethodRow: View {
    let icon: ImageResource
    let name: String
    let detail: String?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(icon)
                .frame(width: 52, height: 52)
                .background(.black, in: .rect(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(AppFont.interTight(16, relativeTo: .callout))
                    .foregroundStyle(.white)
                if let detail {
                    Text(detail)
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        .foregroundStyle(Color.grey50)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Circle()
                .strokeBorder(isSelected ? Color.primary50 : Color.grey70, lineWidth: isSelected ? 5 : 2)
                .frame(width: 16, height: 16)
                .padding(.leading, 16)
        }
        .padding(12)
        .background(Color.grey80, in: .rect(cornerRadius: 20))
        .contentShape(.rect(cornerRadius: 20))
        .animation(Motion.select, value: isSelected)
    }
}

// MARK: - Review Investment

private struct ReviewStep: View {
    @Bindable var flow: InvestmentFlow

    var body: some View {
        VStack(spacing: 28) {
            SheetHeader(title: flow.isSelling ? "Review Sale" : "Review Investment") { flow.sheetStep = .payment }

            VStack(spacing: 16) {
                LabeledSection(title: "Business") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(flow.business.logo)
                                .resizable()
                                .frame(width: 28, height: 28)
                            Text(flow.business.name)
                                .font(AppFont.interTight(14, relativeTo: .subheadline))
                                .foregroundStyle(.white)
                        }
                        Text(flow.business.tags.joined(separator: " · "))
                            .font(AppFont.interTight(12, relativeTo: .caption))
                            .foregroundStyle(Color.grey50)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.grey80, in: .rect(cornerRadius: 24))
                }

                LabeledSection(title: "Investment Summary") {
                    SummaryCard(rows: flow.isSelling ? [
                        ("Shares to sell", "\(flow.shares)"),
                        ("Asking price", flow.pricePerShare.naira + " / share"),
                        ("Sale value", flow.saleValue.naira),
                        ("Transaction fee", 0.0.naira),
                        ("You'll receive", flow.saleValue.naira),
                    ] : [
                        ("Investment amount", flow.amount.naira),
                        ("Number of shares", "\(flow.shares)"),
                        ("Transaction fee", 0.0.naira),
                        ("Total", flow.amount.naira),
                    ])
                }

                LabeledSection(title: "Investment") {
                    Button { flow.sheetStep = .payment } label: {
                        HStack(spacing: 12) {
                            Text(flow.isSelling ? "Payment destination" : "Payment Method").foregroundStyle(Color.grey50)
                            Spacer()
                            Text(flow.paymentMethod?.name ?? "—").foregroundStyle(.white)
                            Image(.arrowLeft).scaleEffect(x: -1)
                        }
                        .font(AppFont.interTight(14, relativeTo: .subheadline))
                        .padding(16)
                        .background(Color.grey80, in: .rect(cornerRadius: 24))
                        .contentShape(.rect(cornerRadius: 24))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(flow.isSelling ? "Change payment destination" : "Change payment method")
                }
            }

            if flow.isSelling {
                VStack(spacing: 16) {
                    SaleMatchingNote(flow: flow)
                    SaleAcknowledgement(isChecked: $flow.hasAcknowledgedSaleRisk, buybackPrice: flow.buybackPrice)
                }
            } else {
                HStack(alignment: .top, spacing: 10) {
                    Image(.warning)
                    Text("By continuing, you confirm that you understand the investment terms and associated risks.")
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        .foregroundStyle(Color.warning50)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(Color.warning10, in: .rect(cornerRadius: 20))
            }

            Button(flow.isSelling ? "List Shares for Sale" : "Confirm Investment") { flow.sheetStep = .pin }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(flow.isSelling && !flow.hasAcknowledgedSaleRisk)
        }
    }
}

/// Sell review: how a sale works. Growvest doesn't buy the shares straight away; it offers
/// them to other investors and pays the seller as they sell, buying any left over itself.
private struct SaleMatchingNote: View {
    let flow: InvestmentFlow

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.primary50)
                .padding(.top, 2)
            Text("Your shares go on sale to other investors on Growvest, and you’re paid as they sell. Any still unsold after \(InvestmentFlow.saleMatchingDays) days, Growvest buys at \(flow.buybackPrice.naira) a share (\(Int(InvestmentFlow.unsoldBuybackDiscount * 100))% below the asking price).")
                .font(AppFont.interTight(12, relativeTo: .caption))
                .foregroundStyle(Color.grey40)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.primary20.opacity(0.5), in: .rect(cornerRadius: 20))
    }
}

/// Sell review: a round checkbox the user ticks before "List Shares for Sale" unlocks.
/// Design: a 20pt grey circle beside the statement; ticked, it fills with the brand colour.
private struct SaleAcknowledgement: View {
    @Binding var isChecked: Bool
    let buybackPrice: Double

    var body: some View {
        Button { isChecked.toggle() } label: {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle().fill(isChecked ? Color.primary50 : Color.grey80)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.ink)
                        .scaleEffect(isChecked ? 1 : 0.3)
                        .opacity(isChecked ? 1 : 0)
                }
                .frame(width: 20, height: 20)

                Text("I understand my shares sell only when another investor buys them, or to Growvest at \(buybackPrice.naira) a share after \(InvestmentFlow.saleMatchingDays) days.")
                    .font(AppFont.interTight(14, relativeTo: .subheadline))
                    .foregroundStyle(Color.grey50)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .animation(Motion.select, value: isChecked)
        .sensoryFeedback(.selection, trigger: isChecked)
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }
}

// MARK: - Enter PIN

private struct PinStep: View {
    @Bindable var flow: InvestmentFlow
    @State private var pin = ""
    @State private var isPinVisible = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 64) {
            VStack(spacing: 28) {
                SheetHeader(title: flow.isSelling ? "Confirm Listing" : "Confirm Investment") { flow.sheetStep = .review }

                VStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter your PIN")
                            .font(AppFont.interTight(24, relativeTo: .title2))
                            .foregroundStyle(.white)
                        Text("Enter your 4-digit PIN to \(flow.isSelling ? "list your shares for sale" : "complete your investment").")
                            .font(AppFont.interTight(16, relativeTo: .callout))
                            .foregroundStyle(Color.grey50)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            pinBoxes
                            Button { isPinVisible.toggle() } label: {
                                Image(isPinVisible ? .eyeOpen : .eyeClosed)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(isPinVisible ? "Hide PIN" : "Show PIN")
                        }
                        .frame(maxWidth: 350)

                        Button(action: authenticateWithFaceID) {
                            HStack(spacing: 10) {
                                Image(.scanSmiley)
                                Text("Confirm with Face ID")
                                    .font(AppFont.interTight(14, relativeTo: .subheadline))
                                    .foregroundStyle(.white)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Capsule().fill(Color.grey80))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button(flow.isSelling ? "List Shares for Sale" : "Confirm Investment", action: flow.complete)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(pin.count < 4)
        }
        .task {
            // Raise the keyboard once the step has settled in, not mid-transition.
            try? await Task.sleep(for: .milliseconds(450))
            isFocused = true
        }
    }

    private var pinBoxes: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                let digit = index < pin.count ? String(pin[pin.index(pin.startIndex, offsetBy: index)]) : nil
                ZStack {
                    if let digit {
                        if isPinVisible {
                            Text(digit).font(AppFont.interTight(24, relativeTo: .title2)).foregroundStyle(.white)
                                .transition(.scale(scale: 0.5).combined(with: .opacity))
                        } else {
                            Circle().fill(.white).frame(width: 10, height: 10)
                                .transition(.scale(scale: 0.2).combined(with: .opacity))
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Capsule().fill(Color.grey80))
                // The box awaiting the next digit gets the brand-colour ring.
                .overlay {
                    let isActive = isFocused && index == pin.count
                    Capsule()
                        .strokeBorder(Color.primary50, lineWidth: 1.5)
                        .opacity(isActive ? 1 : 0)
                        .shadow(color: Color.primary50.opacity(isActive ? 0.35 : 0), radius: 6)
                }
            }
        }
        .animation(Motion.select, value: pin)
        .animation(Motion.select, value: isPinVisible)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        // A hidden number-pad field drives the boxes.
        .overlay {
            TextField("", text: $pin)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .foregroundStyle(.clear)
                .tint(.clear)
                .opacity(0.02)
                .accessibilityLabel("4-digit PIN")
                .onChange(of: pin) { _, new in
                    let digits = String(new.filter(\.isNumber).prefix(4))
                    if digits != new { pin = digits }
                }
        }
        .contentShape(.rect)
        .onTapGesture { isFocused = true }
    }

    private func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?
        // The prototype skips straight to success when biometrics aren't set up (e.g. a fresh simulator).
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            flow.complete()
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                               localizedReason: flow.isSelling ? "List your \(flow.business.name) shares for sale"
                                                               : "Confirm your investment in \(flow.business.name)") { success, _ in
            if success {
                Task { @MainActor in flow.complete() }
            }
        }
    }
}

// MARK: - Investment Successful

private struct SuccessStep: View {
    @Bindable var flow: InvestmentFlow

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                // Design: a 40pt row holding the close button, with the handle overlaid on top.
                HStack {
                    Button(action: flow.reset) { Image(.arrowLeft) }
                        .buttonStyle(CircleIconButtonStyle())
                        .accessibilityLabel("Close")
                    Spacer()
                }
                .padding(.top, 16)
                .overlay(alignment: .top) { SheetHandle() }

                AnimatedSealCheck()

                VStack(spacing: 8) {
                    Text(flow.isSelling ? "Shares Listed for Sale" : "Investment Successful")
                        .font(AppFont.interTight(24, relativeTo: .title2))
                        .foregroundStyle(.white)
                    Text(flow.isSelling
                         ? "Your \(flow.shares) \(flow.shares == 1 ? "share" : "shares") of \(flow.business.name) \(flow.shares == 1 ? "is" : "are") on sale to other investors. We’ll pay you as they sell."
                         : "Secure your account by uploading the required documents for verification.")
                        .font(AppFont.interTight(16, relativeTo: .callout))
                        .foregroundStyle(Color.grey50)
                        .multilineTextAlignment(.center)
                }

                LabeledSection(title: flow.isSelling ? "Sale Details" : "Investment Details") {
                    SummaryCard(rows: flow.isSelling ? [
                        ("Status", "Waiting for a buyer"),
                        ("Shares listed", "\(flow.shares)"),
                        ("Asking price", flow.pricePerShare.naira + " / share"),
                        ("Sale value", flow.saleValue.naira),
                        ("If unsold by", flow.buybackDate.formatted(.dateTime.day(.twoDigits).month(.abbreviated).year().locale(Locale(identifier: "en_GB")))),
                        ("Growvest buys at", flow.buybackPrice.naira + " / share"),
                        ("Timestamp", flow.completedAt.investmentTimestamp),
                        ("Payment Destination", flow.paymentMethod?.name ?? "—"),
                    ] : [
                        ("Investment amount", flow.amount.naira),
                        ("Number of shares", "\(flow.shares)"),
                        ("Timestamp", flow.completedAt.investmentTimestamp),
                        ("Payment Method", flow.paymentMethod?.name ?? "—"),
                    ])
                }
            }

            // Side by side, equal widths: the secondary action on the left, Done on the right.
            HStack(spacing: 8) {
                Button(flow.isSelling ? "View Sale" : "View Investment", action: flow.reset)
                    .buttonStyle(SecondaryButtonStyle())
                Button("Done", action: flow.reset)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}
