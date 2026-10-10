import SwiftUI

/// Every interaction flow the prototype can play.
///
/// To add a flow: build its root view, add a case here, and fill in its details and
/// `destination`. It then shows up on the launcher automatically.
enum PrototypeFlow: String, CaseIterable, Identifiable {
    case home
    case buyShares
    case sellShares
    case kyc
    case profileSetup

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .buyShares: "Buy Shares"
        case .sellShares: "Sell Shares"
        case .kyc: "Verify Identity (KYC)"
        case .profileSetup: "Profile Setup"
        }
    }

    var summary: String {
        switch self {
        case .home: "Investor and business owner dashboards"
        case .buyShares: "Amount → Payment method → Review → PIN → Success"
        case .sellShares: "Shares → Payment destination → Review → PIN → Success"
        case .kyc: "ID card scan → Face verification → Address → Submit"
        case .profileSetup: "Profile → Investor or business details → Success"
        }
    }

    var icon: ImageResource {
        switch self {
        case .home: .tabHome
        case .buyShares: .creditCard
        case .sellShares: .bank
        case .kyc: .aiScan
        case .profileSetup: .scanSmiley
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        // Pulling down on Home refreshes it, so it mustn't also swipe the flow closed.
        case .home: HomeView().interactiveDismissDisabled()
        case .buyShares: TradeView(kind: .buy)
        case .sellShares: TradeView(kind: .sell)
        case .kyc: KYCView()
        case .profileSetup: ProfileSetupView()
        }
    }
}

/// The prototype's home screen: pick an interaction flow to play.
struct FlowLauncherView: View {
    @State private var activeFlow: PrototypeFlow?
    @Namespace private var zoom

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose a flow to play. Use the back button inside a flow to return here.")
                        .font(AppFont.interTight(14, relativeTo: .subheadline))
                        .foregroundStyle(Color.grey50)
                        .padding(.bottom, 16)

                    ForEach(PrototypeFlow.allCases) { flow in
                        Button { activeFlow = flow } label: {
                            FlowRow(flow: flow)
                        }
                        .buttonStyle(FlowRowButtonStyle())
                        // The card zooms open into the flow (and back), like App Store cards.
                        .matchedTransitionSource(id: flow, in: zoom) { source in
                            source.clipShape(.rect(cornerRadius: 20))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Growvest Flows")
        }
        .fullScreenCover(item: $activeFlow) { flow in
            flow.destination
                .navigationTransition(.zoom(sourceID: flow, in: zoom))
        }
        #if DEBUG
        .onAppear {
            // Demo/screenshot launch arguments jump straight into a flow:
            // -demoFlow kyc | sell, or -demoStep / -demoAmount for the buy (or sell) flow.
            let defaults = UserDefaults.standard
            var flow: PrototypeFlow?
            if defaults.string(forKey: "demoFlow") == "kyc" || defaults.string(forKey: "demoKYC") != nil {
                flow = .kyc
            } else if defaults.string(forKey: "demoFlow") == "home" || defaults.string(forKey: "demoHome") != nil {
                flow = .home
            } else if defaults.string(forKey: "demoFlow") == "sell" {
                flow = .sellShares
            } else if defaults.string(forKey: "demoFlow") == "profile" || defaults.string(forKey: "demoProfile") != nil {
                flow = .profileSetup
            } else if defaults.string(forKey: "demoStep") != nil || defaults.string(forKey: "demoAmount") != nil {
                flow = .buyShares
            }
            if defaults.string(forKey: "demoZoom") != nil {
                // Opens and closes a flow with the real transition, for recording it.
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.2))
                    activeFlow = defaults.string(forKey: "demoZoom") == "kyc" ? .kyc : .buyShares
                    try? await Task.sleep(for: .seconds(2.2))
                    activeFlow = nil
                }
                return
            }
            if let flow {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) { activeFlow = flow }
            }
        }
        #endif
    }
}

private struct FlowRow: View {
    let flow: PrototypeFlow

    var body: some View {
        HStack(spacing: 12) {
            Image(flow.icon)
                .frame(width: 52, height: 52)
                .background(.black, in: .rect(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 4) {
                Text(flow.title)
                    .font(AppFont.interTight(16, relativeTo: .callout))
                    .foregroundStyle(.white)
                Text(flow.summary)
                    .font(AppFont.interTight(12, relativeTo: .caption))
                    .foregroundStyle(Color.grey50)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(.arrowLeft)
                .scaleEffect(x: -1)
        }
        .padding(12)
        .background(Color.grey80, in: .rect(cornerRadius: 20))
        .contentShape(.rect(cornerRadius: 20))
    }
}

private struct FlowRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

#Preview {
    FlowLauncherView()
        .preferredColorScheme(.dark)
}
