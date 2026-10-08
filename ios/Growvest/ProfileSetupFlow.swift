import Observation
import PhotosUI
import SwiftUI

/// State for "Profile Setup". The role chosen on the first screen decides the path:
///
/// - Investor:        profile → investor profile → experience → success
/// - Business owner:  profile → business profile → success
/// - Both:            profile → investor profile → experience → business profile → success
///
/// The progress bar has one segment per screen of the path (success included), so it
/// shows 4 segments for an investor, 3 for a business owner and 5 for both.
@Observable
final class ProfileSetupFlow {
    enum Role: String, CaseIterable, Identifiable {
        case investor = "Investor"
        case businessOwner = "Business Owner"
        case both = "Both"
        var id: Self { self }
    }

    enum Step: Hashable {
        case profile, investor, experience, business, verification, success
    }

    struct Country: Hashable, Identifiable {
        let name: String
        let dialCode: String
        /// Nigeria uses the design's flag asset; the rest fall back to emoji flags.
        let emoji: String
        var id: String { name }

        static let nigeria = Country(name: "Nigeria", dialCode: "+234", emoji: "🇳🇬")
        static let all: [Country] = [
            .nigeria,
            Country(name: "Ghana", dialCode: "+233", emoji: "🇬🇭"),
            Country(name: "Kenya", dialCode: "+254", emoji: "🇰🇪"),
            Country(name: "South Africa", dialCode: "+27", emoji: "🇿🇦"),
            Country(name: "United Kingdom", dialCode: "+44", emoji: "🇬🇧"),
            Country(name: "United States", dialCode: "+1", emoji: "🇺🇸"),
        ]
    }

    static let categories = [
        "Tech", "Real Estate", "SaaS", "Cybersecurity", "Education", "Gaming",
        "Agriculture & Farming", "Clean Energy", "Fintech & Banking", "Electric Vehicles", "Blockchain",
    ]
    static let experienceLevels = [
        "Beginner – new to investing", "Intermediate – 1 to 3 years", "Experienced – 3 to 5 years", "Expert – 5+ years",
    ]
    static let previousInvestments = ["Stocks", "Real Estate", "Bonds", "Crypto", "Mutual Funds", "Other"]
    static let durations = ["Short term – under 1 year", "Medium term – 1 to 3 years", "Long term – 3+ years"]
    static let amountRanges = ["Under ₦100K", "₦100K–₦500K", "₦500K–₦1M", "₦1M - ₦4M", "₦5M - ₦9M", "₦10M+"]
    static let industries = [
        "AgriTech", "Clean Energy", "Education", "Fintech", "Healthcare", "Logistics",
        "Real Estate", "Retail & E-commerce", "SaaS",
    ]
    static let currencies = [("NGN", "🇳🇬"), ("USD", "🇺🇸"), ("GBP", "🇬🇧")]

    /// Risk appetite slider: 40 ticks (fewer than the Slider component's 48, by request).
    static let riskTickCount = 40

    /// The screens pushed on top of the profile screen, bound to the navigation stack.
    var path: [Step] = []
    var step: Step { path.last ?? .profile }

    // Profile
    var photo: Image?
    var fullName = ""
    var country = Country.nigeria
    var phone = ""
    var role: Role?

    // Investor profile
    var categories: Set<String> = []
    var riskTick = 1

    // Experience
    var experience: String?
    var previouslyInvested: Set<String> = []
    var duration: String?
    var amountRange: String?

    // Business profile
    var businessName = ""
    var industry: String?
    var currency = "NGN"
    var fundingGoal = ""            // digits only
    var website = ""
    var instagram = ""
    var facebook = ""
    var xTwitter = ""
    var linkedIn = ""

    // Business verification documents, keyed by kind; a missing key means not uploaded yet.
    var documents: [BusinessDocument: DocumentUpload] = [:]

    var allDocumentsUploaded: Bool {
        BusinessDocument.allCases.allSatisfy { documents[$0]?.isComplete == true }
    }

    /// The screens for the chosen role. Until a role is picked it previews the investor path.
    var steps: [Step] {
        switch role {
        case .businessOwner: [.profile, .business, .verification, .success]
        case .both: [.profile, .investor, .experience, .business, .verification, .success]
        case .investor, nil: [.profile, .investor, .experience, .success]
        }
    }

    var stepIndex: Int { steps.firstIndex(of: step) ?? 0 }

    var riskLevel: String {
        switch Double(riskTick) / Double(Self.riskTickCount - 1) {
        case ..<(1.0 / 3): "Low"
        case ..<(2.0 / 3): "Medium"
        default: "High"
        }
    }

    var canContinue: Bool {
        switch step {
        case .profile:
            !fullName.trimmingCharacters(in: .whitespaces).isEmpty && phone.count >= 7 && role != nil
        case .investor:
            !categories.isEmpty
        case .experience:
            experience != nil && duration != nil && amountRange != nil
        case .business:
            !businessName.trimmingCharacters(in: .whitespaces).isEmpty && industry != nil && (Int(fundingGoal) ?? 0) > 0
        case .verification:
            allDocumentsUploaded
        case .success:
            true
        }
    }

    func next() {
        guard stepIndex + 1 < steps.count else { return }
        path.append(steps[stepIndex + 1])
    }

    /// Returns false on the first screen, where "back" leaves the flow.
    func back() -> Bool {
        guard !path.isEmpty else { return false }
        path.removeLast()
        return true
    }

    #if DEBUG
    /// Pushes every screen up to `step`, so back still walks through them.
    func jump(to step: Step) {
        guard let index = steps.firstIndex(of: step) else { return }
        path = Array(steps[1...index])
    }
    #endif
}

// MARK: - Container

/// "Profile Setup": a real navigation stack, so screens push and pop like any iOS screen
/// (including the edge swipe back). The progress bar floats above the stack, just under the
/// navigation bar, so it stays put while the screens move beneath it.
struct ProfileSetupView: View {
    @State private var flow = ProfileSetupFlow()
    /// Where the navigation bar ends, measured from the screens, so the progress bar sits right under it.
    @State private var navigationBarBottom: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    private static let progressTopPadding: CGFloat = 16
    private static let progressHeight: CGFloat = 6

    var body: some View {
        NavigationStack(path: $flow.path) {
            screen(for: .profile)
                .navigationDestination(for: ProfileSetupFlow.Step.self) { screen(for: $0) }
        }
        .overlay(alignment: .top) {
            ProgressSegments(count: flow.steps.count, filled: flow.stepIndex + 1)
                .padding(.horizontal, 24)
                .frame(maxWidth: 480)
                .offset(y: navigationBarBottom + Self.progressTopPadding)
                .animation(Motion.step, value: flow.stepIndex)
                .animation(Motion.step, value: flow.steps.count)
                // The offset is measured from the stack's top edge, so don't add the status bar again.
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .coordinateSpace(.named(Self.coordinateSpace))
        #if DEBUG
        .onAppear(perform: applyDemoLaunchArguments)
        #endif
    }

    private static let coordinateSpace = "ProfileSetup"

    private func screen(for step: ProfileSetupFlow.Step) -> some View {
        Group {
            switch step {
            case .profile: ProfileStep(flow: flow)
            case .investor: InvestorStep(flow: flow)
            case .experience: ExperienceStep(flow: flow)
            case .business: BusinessStep(flow: flow)
            case .verification: VerificationStep(flow: flow)
            case .success: ProfileSuccessStep(flow: flow) { dismiss() }
            }
        }
        // Leave room for the floating progress bar, and keep scrolled content from showing under it.
        .safeAreaInset(edge: .top, spacing: 0) {
            Color(.systemBackground)
                .frame(height: Self.progressTopPadding + Self.progressHeight)
                .onGeometryChange(for: CGFloat.self) {
                    $0.frame(in: .named(Self.coordinateSpace)).minY
                } action: { navigationBarBottom = $0 }
        }
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if step != .success {
                    Button { if !flow.back() { dismiss() } } label: { Image(.arrowLeft) }
                        .modifier(LegacyCircleBackground())
                        .accessibilityLabel("Back")
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Profile Setup")
                    .font(AppFont.interTight(16, relativeTo: .headline))
                    .foregroundStyle(.white)
            }
        }
    }
}

#if DEBUG
extension ProfileSetupView {
    /// `-demoProfile filled|investor|experience|experienceblank|business|both|verification|verifymix|verified|success|businesssuccess`
    /// jumps into the flow with sample answers, for demos and screenshots.
    private func applyDemoLaunchArguments() {
        guard let demo = UserDefaults.standard.string(forKey: "demoProfile") else { return }
        if demo == "experienceblank" {          // experience step with nothing chosen yet
            flow.role = .investor
            flow.jump(to: .experience)
            return
        }
        flow.fullName = "Adaeze Okafor"
        flow.phone = "8031234567"
        flow.role = demo.hasPrefix("business") || demo.hasPrefix("verif") ? .businessOwner : demo == "both" ? .both : .investor
        flow.categories = ["Tech", "Agriculture & Farming", "Clean Energy"]
        flow.riskTick = 20
        flow.experience = ProfileSetupFlow.experienceLevels[1]
        flow.previouslyInvested = ["Stocks", "Crypto"]
        flow.duration = ProfileSetupFlow.durations[1]
        flow.amountRange = ProfileSetupFlow.amountRanges[1]
        flow.businessName = "SwiftHarvest Ventures"
        flow.industry = "AgriTech"
        flow.fundingGoal = "25000000"
        flow.website = "swiftharvest.ng"
        switch demo {
        case "investor": flow.jump(to: .investor)
        case "experience": flow.jump(to: .experience)
        case "business", "both": flow.jump(to: .business)
        case "verification": flow.jump(to: .verification)
        case "verifymix":                       // one uploaded, one mid-upload, the rest empty
            flow.documents[.registration] = DocumentUpload(fileName: "CAC-Certificate.pdf", byteCount: 131_072, progress: 1)
            flow.documents[.address] = DocumentUpload(fileName: "Lease-Agreement.pdf", byteCount: 245_760, progress: 0.45)
            flow.jump(to: .verification)
        case "verified":
            for kind in BusinessDocument.allCases {
                flow.documents[kind] = DocumentUpload(fileName: "\(kind.title).pdf", byteCount: 131_072, progress: 1)
            }
            flow.jump(to: .verification)
        case "success", "businesssuccess":
            for kind in BusinessDocument.allCases {
                flow.documents[kind] = DocumentUpload(fileName: "\(kind.title).pdf", byteCount: 131_072, progress: 1)
            }
            flow.jump(to: .success)
        default: break
        }
    }
}
#endif

// MARK: - Shared pieces

/// The step indicator: one 6pt bar per screen; completed and current ones fill with the
/// brand colour from the leading edge. Segments are added or removed when the role changes.
private struct ProgressSegments: View {
    let count: Int
    let filled: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(Color.grey80)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary50)
                            .scaleEffect(x: index < filled ? 1 : 0.001, anchor: .leading)
                    }
                    .clipShape(Capsule())
                    .transition(.opacity.combined(with: .scale(scale: 0.6, anchor: .leading)))
            }
        }
        .frame(height: 6)
        .accessibilityElement()
        .accessibilityLabel("Step \(filled) of \(count)")
    }
}

/// Scrolling body of a step: heading, then the fields; the action button stays pinned below.
private struct StepScaffold<Fields: View>: View {
    let title: String
    let message: String
    let buttonTitle: String
    let canContinue: Bool
    let onContinue: () -> Void
    @ViewBuilder var fields: Fields

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                KYCHeading(title: title, message: message)
                VStack(alignment: .leading, spacing: 24) { fields }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            Button(buttonTitle, action: onContinue)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canContinue)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
        }
    }
}

/// A 16pt white heading over a group of controls ("Who are you?", "Risk Appetite", …).
private struct FieldGroup<Content: View>: View {
    let title: String
    var spacing: CGFloat = 12
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            FieldLabel(title: title)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Multi- or single-select pills that wrap onto as many lines as they need.
private struct TagPicker: View {
    let options: [String]
    let isSelected: (String) -> Bool
    let onTap: (String) -> Void

    var body: some View {
        WrapLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                let selected = isSelected(option)
                Button { onTap(option) } label: {
                    Text(option)
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        // Selected: solid brand blue with black text, no outline.
                        .foregroundStyle(selected ? Color.ink : Color.grey50)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(selected ? Color.primary50 : Color.grey80))
                        .contentShape(Capsule())
                }
                .buttonStyle(TagPressStyle())
                .animation(Motion.select, value: selected)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: options.filter(isSelected))
        .hapticSound(trigger: options.filter(isSelected))
    }
}

/// A multi-select `TagPicker` led by an "All" chip: All selects every option (or clears them
/// if all are already on), and shows as selected whenever every option is.
private struct MultiTagPicker: View {
    let options: [String]
    @Binding var selection: Set<String>

    private static let all = "All"
    private var allSelected: Bool { selection.count == options.count }

    var body: some View {
        TagPicker(options: [Self.all] + options,
                  isSelected: { $0 == Self.all ? allSelected : selection.contains($0) },
                  onTap: { option in
                      if option == Self.all {
                          selection = allSelected ? [] : Set(options)
                      } else {
                          selection.formSymmetricDifference([option])
                      }
                  })
    }
}

private struct TagPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

/// Lays children out left to right, wrapping to a new line when a row is full.
private struct WrapLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, width: proposal.width ?? .infinity)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> [Row] {
        var rows = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = rows[rows.count - 1].indices.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if needed > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            let last = rows.count - 1
            rows[last].width = rows[last].indices.isEmpty ? size.width : rows[last].width + spacing + size.width
            rows[last].height = max(rows[last].height, size.height)
            rows[last].indices.append(index)
        }
        return rows
    }
}

/// The flag-and-caret pill used for the country and currency pickers.
private struct FlagPill<Label: View>: View {
    var horizontalPadding: CGFloat = 20
    var verticalPadding: CGFloat = 20
    @ViewBuilder var label: Label

    var body: some View {
        HStack(spacing: 8) {
            label
            Image(.chevronSmallDown)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(Capsule().fill(Color.grey80))
        .contentShape(Capsule())
    }
}

private struct FlagImage: View {
    let emoji: String
    var width: CGFloat = 27
    var height: CGFloat = 20

    var body: some View {
        if emoji == "🇳🇬" {
            Image(.flagNigeria).resizable().frame(width: width, height: height)
        } else {
            Text(emoji).font(.system(size: height)).frame(width: width, height: height)
        }
    }
}

// MARK: - 1. Complete Your Profile

private struct ProfileStep: View {
    @Bindable var flow: ProfileSetupFlow
    @FocusState private var focused: Field?
    @State private var photoItem: PhotosPickerItem?

    enum Field { case name, phone }

    var body: some View {
        StepScaffold(title: "Complete Your Profile",
                     message: "Discover and support promising businesses while earning returns on your investments.",
                     buttonTitle: "Continue", canContinue: flow.canContinue,
                     onContinue: { focused = nil; flow.next() }) {
            HStack(spacing: 20) {
                Group {
                    if let photo = flow.photo {
                        photo.resizable().scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                    } else {
                        Image(.avatarPlaceholder)
                    }
                }
                .animation(Motion.select, value: flow.photo != nil)

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Text(flow.photo == nil ? "Upload Profile Picture" : "Change Profile Picture")
                        .font(AppFont.interTight(14, relativeTo: .subheadline))
                        .foregroundStyle(Color.ink)
                        .frame(width: 200, height: 48)
                        .background(Capsule().fill(Color.primary50))
                        .contentShape(Capsule())
                }
                .buttonStyle(TagPressStyle())
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        flow.photo = Image(uiImage: image)
                    }
                }
            }

            TextInputField(title: "Full Name", placeholder: "Enter Full Name",
                           text: $flow.fullName, isFocused: focused == .name)
                .focused($focused, equals: .name)
                .textContentType(.name)
                .submitLabel(.next)
                .onSubmit { focused = .phone }

            HStack(alignment: .bottom, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    FieldLabel(title: "Country")
                    Menu {
                        Picker("Country", selection: $flow.country) {
                            ForEach(ProfileSetupFlow.Country.all) { country in
                                Text("\(country.emoji)  \(country.name) (\(country.dialCode))").tag(country)
                            }
                        }
                    } label: {
                        FlagPill { FlagImage(emoji: flow.country.emoji) }
                    }
                    .accessibilityLabel("Country, \(flow.country.name)")
                }

                TextInputField(title: "Phone Number", placeholder: "Enter Phone Number",
                               text: $flow.phone, isFocused: focused == .phone)
                    .focused($focused, equals: .phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .onChange(of: flow.phone) { _, new in
                        let digits = String(new.filter(\.isNumber).prefix(11))
                        if digits != new { flow.phone = digits }
                    }
            }

            FieldGroup(title: "Who are you?") {
                HStack(spacing: 20) {
                    ForEach(ProfileSetupFlow.Role.allCases) { role in
                        RadioOption(title: role.rawValue, isSelected: flow.role == role) {
                            withAnimation(Motion.select) { flow.role = role }
                        }
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: flow.role)
            .hapticSound(trigger: flow.role)
        }
    }
}

/// The design's 20pt round radio: a grey well that fills with a brand-colour dot when chosen.
private struct RadioOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.grey80)
                    .overlay {
                        Circle()
                            .fill(Color.primary50)
                            .padding(5)
                            .scaleEffect(isSelected ? 1 : 0.2)
                            .opacity(isSelected ? 1 : 0)
                    }
                    .overlay(Circle().strokeBorder(isSelected ? Color.primary50 : Color.grey80, lineWidth: 1))
                    .frame(width: 20, height: 20)
                Text(title)
                    .font(AppFont.interTight(14, relativeTo: .subheadline))
                    .foregroundStyle(.white)
            }
            .contentShape(.rect)
        }
        .buttonStyle(TagPressStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - 2. Build Your Investor Profile

private struct InvestorStep: View {
    @Bindable var flow: ProfileSetupFlow

    var body: some View {
        StepScaffold(title: "Build Your Investor Profile",
                     message: "Personalize your investment experience by selecting your preferences and financial details.",
                     buttonTitle: "Continue", canContinue: flow.canContinue, onContinue: flow.next) {
            FieldGroup(title: "Preferred Investment Categories") {
                MultiTagPicker(options: ProfileSetupFlow.categories, selection: $flow.categories)
            }

            FieldGroup(title: "Risk Appetite") {
                RiskSlider(tick: $flow.riskTick, level: flow.riskLevel)
            }
        }
    }
}

/// The ruler-style risk slider: 40 ticks in a grey pill with a white needle. The needle
/// follows the finger 1:1 and settles onto the nearest tick on release; ticks up to it
/// light up in the brand colour. Haptics: a light click per tick crossed, a firmer tap when
/// the level changes (Low → Medium → High), and a solid knock at either end.
private struct RiskSlider: View {
    @Binding var tick: Int
    let level: String

    /// The needle's position in tick units while dragging (fractional), nil at rest.
    @State private var dragPosition: CGFloat?
    @State private var selectionHaptic = UISelectionFeedbackGenerator()
    @State private var levelHaptic = UIImpactFeedbackGenerator(style: .medium)
    @State private var edgeHaptic = UIImpactFeedbackGenerator(style: .rigid)

    private let count = ProfileSetupFlow.riskTickCount
    private var isDragging: Bool { dragPosition != nil }
    private var position: CGFloat { dragPosition ?? CGFloat(tick) }

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { proxy in
                let step = proxy.size.width / CGFloat(count - 1)
                ZStack(alignment: .leading) {
                    // Each tick is centred on its own grid point (the same grid the needle uses),
                    // so lit ticks can be wider without shifting the others.
                    ForEach(0..<count, id: \.self) { index in
                        // Lit ticks are 2pt wide (Slider component, Figma 1102:3022) and, by request,
                        // grow to the first tick's 28pt height; unlit ticks stay 1pt × 20pt.
                        // Each one springs up as the needle reaches it, so a drag sends a ripple along.
                        let isLit = CGFloat(index) <= position + 0.001
                        let width: CGFloat = isLit ? 2 : 1
                        Capsule()
                            .fill(isLit ? Color.primary50 : Color.grey50)
                            .frame(width: width, height: isLit ? 28 : 20)
                            .animation(.spring(duration: 0.22, bounce: 0.35), value: isLit)
                            .offset(x: CGFloat(index) * step - width / 2)
                    }
                    Capsule()
                        .fill(.white)
                        .frame(width: 2, height: 48)
                        .scaleEffect(x: isDragging ? 1 : 0.5, y: isDragging ? 1.04 : 1)
                        .shadow(color: .white.opacity(isDragging ? 0.5 : 0), radius: 4)
                        .offset(x: position * step - 1)
                }
                // Ticks are placed by offset, which takes no layout space, so the frame must
                // fill the track explicitly; otherwise the touch area collapses to the first tick.
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .contentShape(.rect)
                // High priority so a sideways drag inside the scroll view always moves the needle.
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in drag(to: value.location.x / step) }
                        .onEnded { _ in release() }
                )
            }
            .padding(.horizontal, 20)
            .frame(height: 60)
            .background(Capsule().fill(Color.grey80))
            .animation(Motion.press, value: isDragging)

            HStack {
                ForEach(["Low", "Medium", "High"], id: \.self) { label in
                    Text(label)
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        .foregroundStyle(label == level ? .white : Color.grey50)
                        .scaleEffect(label == level && isDragging ? 1.08 : 1)
                    if label != "High" { Spacer() }
                }
            }
            .padding(.horizontal, 20)
            .animation(Motion.select, value: level)
            .animation(Motion.press, value: isDragging)
        }
        .accessibilityElement()
        .accessibilityLabel("Risk appetite")
        .accessibilityValue(level)
        .accessibilityAdjustableAction { direction in
            withAnimation(Motion.select) {
                switch direction {
                case .increment: tick = min(tick + 5, count - 1)
                case .decrement: tick = max(tick - 5, 0)
                @unknown default: break
                }
            }
        }
    }

    private func drag(to rawPosition: CGFloat) {
        let clamped = min(max(rawPosition, 0), CGFloat(count - 1))
        if dragPosition == nil {
            // Touch-down: wake the haptic engines, and glide to a tapped spot rather than jump.
            selectionHaptic.prepare()
            levelHaptic.prepare()
            edgeHaptic.prepare()
            withAnimation(.spring(duration: 0.25, bounce: 0)) { dragPosition = clamped }
        } else {
            dragPosition = clamped        // 1:1 with the finger, no animation lag
        }

        let newTick = Int(clamped.rounded())
        guard newTick != tick else { return }
        let crossesLevel = band(of: newTick) != band(of: tick)
        tick = newTick
        if newTick == 0 || newTick == count - 1 {
            edgeHaptic.impactOccurred(intensity: 0.8)
            HapticSound.play(.rigid)
        } else if crossesLevel {
            levelHaptic.impactOccurred()
            HapticSound.play(.impact)
        } else {
            selectionHaptic.selectionChanged()
            HapticSound.play(.selection)
        }
        selectionHaptic.prepare()
    }

    /// 0, 1, 2 for Low, Medium, High — the same thirds `ProfileSetupFlow.riskLevel` uses.
    private func band(of tick: Int) -> Int {
        min(Int(Double(tick) / Double(count - 1) * 3), 2)
    }

    /// Let go: the needle settles onto the nearest tick.
    private func release() {
        withAnimation(.spring(duration: 0.3, bounce: 0.25)) { dragPosition = nil }
    }
}

// MARK: - 3. Tell Us About Your Experience

private struct ExperienceStep: View {
    @Bindable var flow: ProfileSetupFlow
    @State private var openDropdown: Dropdown?

    enum Dropdown { case experience, duration }

    var body: some View {
        StepScaffold(title: "Tell Us About Your Experience",
                     message: "Help us understand your investing background so we can tailor your experience.",
                     buttonTitle: "Continue", canContinue: flow.canContinue, onContinue: flow.next) {
            BrandDropdown(title: "Investment Experience", placeholder: "Select your investment experience",
                          options: ProfileSetupFlow.experienceLevels, selection: $flow.experience,
                          isOpen: binding(.experience), caret: .caretDown)
                .zIndex(openDropdown == .experience ? 1 : 0)

            FieldGroup(title: "Previously invested in") {
                MultiTagPicker(options: ProfileSetupFlow.previousInvestments, selection: $flow.previouslyInvested)
            }

            BrandDropdown(title: "Preferred Investment Duration", placeholder: "Select your preferred investment duration",
                          options: ProfileSetupFlow.durations, selection: $flow.duration,
                          isOpen: binding(.duration), caret: .caretDown)
                .zIndex(openDropdown == .duration ? 1 : 0)

            FieldGroup(title: "Expected investment amount") {
                TagPicker(options: ProfileSetupFlow.amountRanges,
                          isSelected: { flow.amountRange == $0 },
                          onTap: { flow.amountRange = $0 })
            }
        }
    }

    private func binding(_ dropdown: Dropdown) -> Binding<Bool> {
        Binding(
            get: { openDropdown == dropdown },
            set: { isOpen in
                withAnimation(isOpen ? Motion.step : .smooth(duration: 0.3)) { openDropdown = isOpen ? dropdown : nil }
            }
        )
    }
}

// MARK: - 4. Set Up Your Business Profile

private struct BusinessStep: View {
    @Bindable var flow: ProfileSetupFlow
    @FocusState private var focused: Field?
    @State private var isIndustryOpen = false

    enum Field { case name, goal, website, instagram, facebook, xTwitter, linkedIn }

    var body: some View {
        StepScaffold(title: "Set Up Your Business Profile",
                     message: "Provide key details about your business to connect with potential investors and secure funding.",
                     buttonTitle: "Save & Continue", canContinue: flow.canContinue,
                     onContinue: { focused = nil; flow.next() }) {
            TextInputField(title: "Business Name", placeholder: "Enter Business Name",
                           text: $flow.businessName, isFocused: focused == .name)
                .focused($focused, equals: .name)
                .textContentType(.organizationName)
                .submitLabel(.next)

            BrandDropdown(title: "Industry Category", placeholder: "Select Industry Category",
                          options: ProfileSetupFlow.industries, selection: $flow.industry,
                          isOpen: Binding(get: { isIndustryOpen }, set: { isOpen in
                              if isOpen { focused = nil }
                              withAnimation(isOpen ? Motion.step : .smooth(duration: 0.3)) { isIndustryOpen = isOpen }
                          }),
                          caret: .caretDown)
                .zIndex(isIndustryOpen ? 1 : 0)

            FieldGroup(title: "Funding Goal") {
                HStack(spacing: 8) {
                    Menu {
                        Picker("Currency", selection: $flow.currency) {
                            ForEach(ProfileSetupFlow.currencies, id: \.0) { code, flag in
                                Text("\(flag)  \(code)").tag(code)
                            }
                        }
                    } label: {
                        FlagPill(horizontalPadding: 16, verticalPadding: 18) {
                            FlagImage(emoji: ProfileSetupFlow.currencies.first { $0.0 == flow.currency }?.1 ?? "🇳🇬",
                                      width: 24, height: 18)
                            Text(flow.currency)
                                .font(AppFont.interTight(16, relativeTo: .callout))
                                .foregroundStyle(.white)
                        }
                    }
                    .accessibilityLabel("Currency, \(flow.currency)")

                    TextInputField(title: nil, placeholder: "Enter Funding Goal",
                                   text: groupedGoal, isFocused: focused == .goal)
                        .focused($focused, equals: .goal)
                        .keyboardType(.numberPad)
                }
            }

            FieldGroup(title: "Business Website / Social Media Profile", spacing: 12) {
                VStack(spacing: 8) {
                    link("Website", $flow.website, .website)
                    link("Instagram", $flow.instagram, .instagram)
                    link("Facebook", $flow.facebook, .facebook)
                    link("X/Twitter", $flow.xTwitter, .xTwitter)
                    link("Linkedin", $flow.linkedIn, .linkedIn)
                }
            }
        }
        .onChange(of: focused) { _, new in
            if new != nil { withAnimation(.smooth(duration: 0.3)) { isIndustryOpen = false } }
        }
    }

    private func link(_ placeholder: String, _ text: Binding<String>, _ field: Field) -> some View {
        TextInputField(title: nil, placeholder: placeholder, text: text, isFocused: focused == field)
            .focused($focused, equals: field)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
    }

    /// Shows the goal with thousands separators ("25,000,000") while storing digits only.
    private var groupedGoal: Binding<String> {
        Binding(
            get: {
                guard let value = Int(flow.fundingGoal) else { return "" }
                return value.formatted(.number.locale(Locale(identifier: "en_US")))
            },
            set: { flow.fundingGoal = String($0.filter(\.isNumber).prefix(13)) }
        )
    }
}

// MARK: - Success

/// Closes every path. The copy and the summary follow the role the user chose.
private struct ProfileSuccessStep: View {
    let flow: ProfileSetupFlow
    let onDone: () -> Void

    private var title: String {
        switch flow.role {
        case .businessOwner: "Business Profile Submitted"
        case .both: "Your Profiles Are Ready"
        case .investor, nil: "Investor Profile Complete"
        }
    }

    private var message: String {
        let business = flow.businessName.isEmpty ? "your business" : flow.businessName
        return switch flow.role {
        case .businessOwner: "We're reviewing \(business)'s documents. This usually takes 1–2 business days, and we'll let you know once it's verified."
        case .both: "You can start investing now. We're verifying \(business)'s documents and will let you know when it's ready to raise funding."
        case .investor, nil: "You're all set to discover and support promising businesses."
        }
    }

    private var rows: [(label: String, value: String)] {
        var rows: [(String, String)] = [("Name", flow.fullName), ("Profile type", flow.role?.rawValue ?? "—")]
        if flow.role != .businessOwner {
            rows.append(("Interests", "\(flow.categories.count) \(flow.categories.count == 1 ? "category" : "categories")"))
            rows.append(("Risk appetite", flow.riskLevel))
        }
        if flow.role != .investor {
            rows.append(("Business", flow.businessName))
            let goal = Int(flow.fundingGoal).map { $0.formatted(.number.locale(Locale(identifier: "en_US"))) } ?? "0"
            rows.append(("Funding goal", "\(flow.currency) \(goal)"))
            rows.append(("Verification", "In review"))
        }
        return rows
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AnimatedSealCheck()
                    .padding(.top, 56)

                VStack(spacing: 8) {
                    Text(title)
                        .font(AppFont.interTight(24, relativeTo: .title2))
                        .foregroundStyle(.white)
                    Text(message)
                        .font(AppFont.interTight(16, relativeTo: .callout))
                        .foregroundStyle(Color.grey50)
                }
                .multilineTextAlignment(.center)

                LabeledSection(title: "Profile Details") {
                    SummaryCard(rows: rows)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom) {
            Button(flow.role == .businessOwner ? "Go to Dashboard" : "Start Exploring", action: onDone)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
        }
    }
}

// MARK: - 5. Verify Your Business

/// The five documents a business uploads for verification.
enum BusinessDocument: String, CaseIterable, Identifiable {
    case registration, address, ownership, tax, financials
    var id: Self { self }

    var title: String {
        switch self {
        case .registration: "Business Registration"
        case .address: "Proof of Business Address"
        case .ownership: "Business Ownership"
        case .tax: "Tax Documents"
        case .financials: "Financial Records"
        }
    }

    var about: String {
        switch self {
        case .registration: "Certificate of Incorporation / Business Registration Certificate"
        case .address: "Utility bill, lease agreement, or other accepted document"
        case .ownership: "Document showing the business owners or directors"
        case .tax: "Recent tax filings or tax clearance document till now"
        case .financials: "Financial documents from the beginning of the business till now"
        }
    }
}

/// A picked file and how far its (simulated) upload has got.
struct DocumentUpload: Equatable {
    var fileName: String
    var byteCount: Int
    var progress: Double = 0
    /// A preview for photos; documents show the PDF icon.
    var thumbnail: UIImage?

    var isComplete: Bool { progress >= 1 }
    var sizeText: String { ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file) }
}

private struct VerificationStep: View {
    @Bindable var flow: ProfileSetupFlow

    var body: some View {
        StepScaffold(title: "Verify Your Business",
                     message: "Upload a few documents to verify your business and build trust with potential investors.",
                     buttonTitle: "Submit for Verification", canContinue: flow.canContinue, onContinue: flow.next) {
            VStack(spacing: 12) {
                ForEach(BusinessDocument.allCases) { kind in
                    UploadDocumentCard(kind: kind, upload: $flow.documents[kind])
                }
            }
        }
    }
}

/// The Upload Document component (Figma 1112:4522) in its three states:
/// Default ("Click here to upload"), Uploading (name, spinner, progress, ✕ to cancel)
/// and Uploaded (size, "Completed", bin to remove). Uploads are simulated.
private struct UploadDocumentCard: View {
    let kind: BusinessDocument
    @Binding var upload: DocumentUpload?

    @State private var isChoosingSource = false
    @State private var isImportingFile = false
    @State private var isPickingPhoto = false
    @State private var photoItem: PhotosPickerItem?
    @State private var uploadTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(kind.title)
                    .font(AppFont.interTight(16, relativeTo: .callout))
                    .foregroundStyle(.white)
                Text(kind.about)
                    .font(AppFont.interTight(14, relativeTo: .subheadline))
                    .foregroundStyle(Color.grey50)
            }

            VStack(alignment: .leading, spacing: 8) {
                Group {
                    if let upload {
                        FileRow(upload: upload, onCancel: cancel, onRemove: remove)
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    } else {
                        Button { isChoosingSource = true } label: {
                            HStack(spacing: 10) {
                                Image(.fileArrowUp)
                                Text("Click here to upload")
                                    .font(AppFont.interTight(12, relativeTo: .caption))
                                    .foregroundStyle(Color.grey50)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.black, in: .rect(cornerRadius: 16))
                            .contentShape(.rect(cornerRadius: 16))
                        }
                        .buttonStyle(RowPressStyle())
                        .transition(.opacity)
                        .accessibilityLabel("Upload \(kind.title)")
                    }
                }
                .animation(Motion.step, value: upload == nil)

                Text("Supported formats: JPG, PNG, PDF")
                    .font(AppFont.interTight(12, relativeTo: .caption))
                    .foregroundStyle(Color.grey50)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.grey80, in: .rect(cornerRadius: 20))
        .confirmationDialog("Upload \(kind.title)", isPresented: $isChoosingSource, titleVisibility: .visible) {
            Button("Choose File") { isImportingFile = true }
            Button("Choose from Photos") { isPickingPhoto = true }
        }
        .fileImporter(isPresented: $isImportingFile, allowedContentTypes: [.pdf, .jpeg, .png]) { result in
            guard case .success(let url) = result else { return }
            let isScoped = url.startAccessingSecurityScopedResource()
            defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            let thumbnail = url.pathExtension.lowercased() == "pdf" ? nil : UIImage(contentsOfFile: url.path)
            start(DocumentUpload(fileName: url.lastPathComponent, byteCount: size, thumbnail: thumbnail))
        }
        .photosPicker(isPresented: $isPickingPhoto, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                let data = try? await item.loadTransferable(type: Data.self)
                let ext = item.supportedContentTypes.first?.preferredFilenameExtension ?? "jpg"
                start(DocumentUpload(fileName: "\(kind.title.replacingOccurrences(of: " ", with: "-")).\(ext)",
                                     byteCount: data?.count ?? 0,
                                     thumbnail: data.flatMap(UIImage.init(data:))))
                photoItem = nil
            }
        }
        .sensoryFeedback(.success, trigger: upload?.isComplete == true) { _, done in done }
        .hapticSound(.impact, trigger: upload?.isComplete == true)
    }

    /// Simulates the upload: the bar eases from 0 to full over about a second and a half.
    private func start(_ file: DocumentUpload) {
        uploadTask?.cancel()
        withAnimation(Motion.step) { upload = file }
        uploadTask = Task { @MainActor in
            let steps = 30
            for step in 1...steps {
                try? await Task.sleep(for: .milliseconds(50))
                guard !Task.isCancelled, upload != nil else { return }
                let t = Double(step) / Double(steps)
                withAnimation(.linear(duration: 0.05)) { upload?.progress = 1 - pow(1 - t, 2) }
            }
        }
    }

    private func cancel() {
        uploadTask?.cancel()
        withAnimation(Motion.step) { upload = nil }
    }

    private func remove() {
        withAnimation(Motion.step) { upload = nil }
    }
}

/// The black file row inside an upload card, for the Uploading and Uploaded states.
private struct FileRow: View {
    let upload: DocumentUpload
    let onCancel: () -> Void
    let onRemove: () -> Void
    @State private var isSpinning = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Group {
                    if let thumbnail = upload.thumbnail {
                        Image(uiImage: thumbnail).resizable().scaledToFill()
                    } else {
                        Image(.filePdf)
                    }
                }
                .frame(width: 40, height: 40)
                .background(Color.grey80)
                .clipShape(.rect(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 4) {
                    Text(upload.fileName)
                        .font(AppFont.interTight(14, relativeTo: .subheadline))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if upload.isComplete {
                        HStack(spacing: 6) {
                            Text("\(upload.sizeText) of \(upload.sizeText)")
                            Text("·")
                            HStack(spacing: 4) {
                                Image(.sealCheckTiny)
                                Text("Completed")
                            }
                        }
                        .font(AppFont.interTight(12, relativeTo: .caption))
                        .foregroundStyle(Color.grey50)
                        .transition(.opacity)
                    } else {
                        HStack(spacing: 4) {
                            Image(.spinner)
                                .rotationEffect(.degrees(isSpinning ? 360 : 0))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isSpinning)
                                .onAppear { isSpinning = true }
                            Text("Uploading...")
                                .font(AppFont.interTight(12, relativeTo: .caption))
                                .foregroundStyle(Color.grey50)
                        }
                        .transition(.opacity)
                    }
                }
                Spacer(minLength: 8)

                Button(action: upload.isComplete ? onRemove : onCancel) {
                    Image(upload.isComplete ? .trash : .closeX)
                        .frame(width: 32, height: 32)
                        .contentShape(.rect)
                }
                .buttonStyle(RowPressStyle())
                .accessibilityLabel(upload.isComplete ? "Remove \(upload.fileName)" : "Cancel upload")
            }

            if !upload.isComplete {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.grey80)
                        Capsule().fill(Color.primary50)
                            .frame(width: proxy.size.width * upload.progress)
                    }
                }
                .frame(height: 4)
                .transition(.opacity)
            }
        }
        .padding(12)
        .background(.black, in: .rect(cornerRadius: 12))
        .animation(Motion.step, value: upload.isComplete)
    }
}

#Preview {
    ProfileSetupView()
        .preferredColorScheme(.dark)
}
