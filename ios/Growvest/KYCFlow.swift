import Observation
import SwiftUI

/// State for the identity-verification (KYC) flow.
@Observable
final class KYCFlow {
    enum Route: Hashable {
        case idCard, face, address
    }

    enum Review {
        case pending, approved
    }

    var path: [Route] = []
    var idCardDone = false
    var faceDone = false
    var addressDone = false

    // Residential address form
    var state: String?
    var localGovernment: String?
    var address = ""
    var houseNumber = ""
    var landmark = ""

    var isSubmitSheetPresented = false
    var review: Review = .pending

    var isComplete: Bool { idCardDone && faceDone && addressDone }

    var isAddressValid: Bool {
        state != nil && localGovernment != nil
            && !address.trimmingCharacters(in: .whitespaces).isEmpty
            && !houseNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func submit() {
        review = .pending
        isSubmitSheetPresented = true
    }
}

/// Root of the KYC flow: the verification checklist, with each task pushed on top.
struct KYCView: View {
    @State private var flow = KYCFlow()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack(path: $flow.path) {
            KYCChecklistView(flow: flow)
                .kycScreenChrome { dismiss() }
                .navigationDestination(for: KYCFlow.Route.self) { route in
                    Group {
                        switch route {
                        case .idCard: KYCIDScanView(flow: flow)
                        case .face: KYCFaceScanView(flow: flow)
                        case .address: KYCAddressView(flow: flow)
                        }
                    }
                    .kycScreenChrome { flow.path.removeLast() }
                }
        }
        .floatingSheet(isPresented: $flow.isSubmitSheetPresented, isDismissible: flow.review == .pending) {
            KYCReviewSheet(flow: flow) { dismiss() }
        }
        #if DEBUG
        .onAppear(perform: applyDemoLaunchArguments)
        #endif
    }
}

#if DEBUG
extension KYCView {
    /// `-demoKYC idcard|face|address|ready|submitted` jumps into the flow for demos/screenshots.
    private func applyDemoLaunchArguments() {
        switch UserDefaults.standard.string(forKey: "demoKYC") {
        case "idcard", "idcardscan": flow.path = [.idCard]
        case "face": flow.idCardDone = true; flow.path = [.face]
        case "address", "addressstate", "addresslga": flow.idCardDone = true; flow.faceDone = true; flow.path = [.address]
        case "ready": flow.idCardDone = true; flow.faceDone = true; flow.addressDone = true
        case "submitted":
            flow.idCardDone = true; flow.faceDone = true; flow.addressDone = true
            flow.submit()
        default: break
        }
    }
}
#endif

// MARK: - Shared chrome

private struct KYCScreenChrome: ViewModifier {
    let onBack: () -> Void

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onBack) { Image(.arrowLeft) }
                        .modifier(LegacyCircleBackground())
                        .accessibilityLabel("Back")
                }
                ToolbarItem(placement: .principal) {
                    Text("Verify Your Identity")
                        .font(AppFont.interTight(16, relativeTo: .headline))
                        .foregroundStyle(.white)
                }
            }
    }
}

extension View {
    func kycScreenChrome(onBack: @escaping () -> Void) -> some View {
        modifier(KYCScreenChrome(onBack: onBack))
    }
}

/// Heading + grey body copy used at the top of each KYC screen.
struct KYCHeading: View {
    let title: String
    let message: String
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 8) {
            Text(title)
                .font(AppFont.interTight(24, relativeTo: .title2))
                .foregroundStyle(.white)
            Text(message)
                .font(AppFont.interTight(16, relativeTo: .callout))
                .foregroundStyle(Color.grey50)
        }
        .multilineTextAlignment(alignment == .center ? .center : .leading)
        .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
    }
}

// MARK: - Checklist

struct KYCChecklistView: View {
    @Bindable var flow: KYCFlow

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    KYCHeading(
                        title: "Verify Your Identity to Get Started",
                        message: "Secure your account by uploading the required documents for verification."
                    )

                    VStack(spacing: 8) {
                        TaskRow(icon: .aiScan, title: "ID Card",
                                detail: "Provide us with a passport photograph and Valid ID card.",
                                isDone: flow.idCardDone) { flow.path.append(.idCard) }
                        TaskRow(icon: .faceScan, title: "Face Verification",
                                detail: "Get a face shot by following the instructions that will be provided.",
                                isDone: flow.faceDone) { flow.path.append(.face) }
                        TaskRow(icon: .home, title: "Residential address",
                                detail: "Provide us with your permanent address and residential address.",
                                isDone: flow.addressDone) { flow.path.append(.address) }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }

            Button("Submit", action: flow.submit)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!flow.isComplete)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                .frame(maxWidth: 480)
        }
    }
}

private struct TaskRow: View {
    let icon: ImageResource
    let title: String
    let detail: String
    let isDone: Bool
    let action: () -> Void

    /// The seal is revealed after the pushed screen has slid away, so you see it arrive.
    @State private var showsSeal = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(icon)
                    .frame(width: 64, height: 64)
                    .background(.black, in: .rect(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFont.interTight(16, relativeTo: .callout))
                        .foregroundStyle(.white)
                    Text(detail)
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        .foregroundStyle(Color.grey50)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // The seal's slot is always reserved so the detail text wraps the same
                // before and after it appears, instead of re-folding mid-animation.
                Image(.sealCheckSmall)
                    .scaleEffect(showsSeal ? 1 : 0.2)
                    .opacity(showsSeal ? 1 : 0)
                    .padding(.leading, 16)
                    .accessibilityHidden(true)
            }
            .padding(12)
            .background(Color.grey80, in: .rect(cornerRadius: 24))
            .contentShape(.rect(cornerRadius: 24))
        }
        .buttonStyle(RowPressStyle())
        .sensoryFeedback(.success, trigger: showsSeal) { _, new in new }
        .accessibilityValue(isDone ? "Completed" : "Not started")
        .task(id: isDone) {
            guard isDone != showsSeal else { return }
            if isDone { try? await Task.sleep(for: .milliseconds(380)) }   // let the pop finish
            withAnimation(.spring(duration: 0.5, bounce: 0.45)) { showsSeal = isDone }
        }
    }
}

/// Subtle press feedback for full-width rows.
struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

// MARK: - Submitted sheet

/// Shown after Submit: "pending review" with an hourglass, which resolves to the
/// animated success seal.
private struct KYCReviewSheet: View {
    @Bindable var flow: KYCFlow
    let onFinish: () -> Void
    @State private var hourglassTurns = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 61) {
            HStack {
                Button { flow.isSubmitSheetPresented = false } label: { Image(.arrowLeft) }
                    .buttonStyle(CircleIconButtonStyle())
                    .accessibilityLabel("Close")
                Spacer()
            }
            .padding(.top, 4)
            .overlay(alignment: .top) { SheetHandle() }

            VStack(spacing: 24) {
                ZStack {
                    if flow.review == .pending {
                        Image(.hourglass)
                            .resizable()
                            .frame(width: 96, height: 96)   // matches the 96pt success seal
                            .rotationEffect(.degrees(hourglassTurns * 180))
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    } else {
                        AnimatedSealCheck()
                            .transition(.opacity)
                    }
                }
                .frame(width: 96, height: 96)

                // The copy follows the review: it swaps when the hourglass resolves to the seal.
                KYCHeading(
                    title: flow.review == .pending ? "Verification in Progress" : "Identity Verified",
                    message: flow.review == .pending
                        ? "We're reviewing your documents. This usually takes just a moment."
                        : "You're all set. Your account is verified and ready for you to start investing.",
                    alignment: .center
                )
                .contentTransition(.opacity)
            }

            Button("Continue", action: onFinish)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(12)
        .task {
            // Simulated review: the hourglass flips a few times, then the check is approved.
            guard flow.review == .pending else { return }
            for _ in 0..<2 {
                try? await Task.sleep(for: .milliseconds(900))
                withAnimation(reduceMotion ? nil : .spring(duration: 0.7, bounce: 0.2)) { hourglassTurns += 1 }
            }
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.easeInOut(duration: 0.35)) { flow.review = .approved }
        }
    }
}
