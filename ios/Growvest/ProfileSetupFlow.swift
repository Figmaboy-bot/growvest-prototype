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
        case profile, investor, experience, business, success
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

    /// Risk appetite slider: 71 ticks, as in the design.
    static let riskTickCount = 71

    private(set) var step: Step = .profile
    /// Which way the last step change went, so screens slide in from the correct side.
    private(set) var isMovingForward = true

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

    /// The screens for the chosen role. Until a role is picked it previews the investor path.
    var steps: [Step] {
        switch role {
        case .businessOwner: [.profile, .business, .success]
        case .both: [.profile, .investor, .experience, .business, .success]
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
        case .success:
            true
        }
    }

    func next() {
        guard stepIndex + 1 < steps.count else { return }
        isMovingForward = true
        step = steps[stepIndex + 1]
    }

    /// Returns false on the first screen, where "back" leaves the flow.
    func back() -> Bool {
        guard stepIndex > 0 else { return false }
        isMovingForward = false
        step = steps[stepIndex - 1]
        return true
    }

    #if DEBUG
    func jump(to step: Step) {
        isMovingForward = true
        self.step = step
    }
    #endif
}

// MARK: - Container

/// "Profile Setup": a fixed header (back, title, progress) over screens that slide between steps.
struct ProfileSetupView: View {
    @State private var flow = ProfileSetupFlow()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressSegments(count: flow.steps.count, filled: flow.stepIndex + 1)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                ZStack {
                    stepView
                        .id(flow.step)
                        .transition(stepTransition)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .clipped()
            }
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .animation(Motion.step, value: flow.step)
            .animation(Motion.step, value: flow.steps.count)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if flow.step != .success {
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
        #if DEBUG
        .onAppear(perform: applyDemoLaunchArguments)
        #endif
    }

    @ViewBuilder
    private var stepView: some View {
        switch flow.step {
        case .profile: ProfileStep(flow: flow)
        case .investor: InvestorStep(flow: flow)
        case .experience: ExperienceStep(flow: flow)
        case .business: BusinessStep(flow: flow)
        case .success: ProfileSuccessStep(flow: flow) { dismiss() }
        }
    }

    /// Forward, the next screen slides in from the trailing edge; back, from the leading edge.
    private var stepTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        let edge: Edge = flow.isMovingForward ? .trailing : .leading
        let opposite: Edge = flow.isMovingForward ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .move(edge: opposite).combined(with: .opacity)
        )
    }
}

#if DEBUG
extension ProfileSetupView {
    /// `-demoProfile filled|investor|experience|business|both|success|businesssuccess`
    /// jumps into the flow with sample answers, for demos and screenshots.
    private func applyDemoLaunchArguments() {
        guard let demo = UserDefaults.standard.string(forKey: "demoProfile") else { return }
        flow.fullName = "Adaeze Okafor"
        flow.phone = "8031234567"
        flow.role = demo.hasPrefix("business") ? .businessOwner : demo == "both" ? .both : .investor
        flow.categories = ["Tech", "Agriculture & Farming", "Clean Energy"]
        flow.riskTick = 30
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
        case "success", "businesssuccess": flow.jump(to: .success)
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
                        .foregroundStyle(selected ? Color.primary50 : Color.grey50)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(selected ? Color.primary20 : Color.grey80))
                        .overlay(Capsule().strokeBorder(Color.primary50.opacity(selected ? 0.6 : 0), lineWidth: 1))
                        .contentShape(Capsule())
                }
                .buttonStyle(TagPressStyle())
                .animation(Motion.select, value: selected)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: options.filter(isSelected))
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
                TagPicker(options: ProfileSetupFlow.categories,
                          isSelected: { flow.categories.contains($0) },
                          onTap: { flow.categories.formSymmetricDifference([$0]) })
            }

            FieldGroup(title: "Risk Appetite") {
                RiskSlider(tick: $flow.riskTick, level: flow.riskLevel)
            }
        }
    }
}

/// The ruler-style risk slider: 71 ticks in a grey pill with a white needle. The needle
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
                    HStack(spacing: 0) {
                        ForEach(0..<count, id: \.self) { index in
                            Capsule()
                                .fill(CGFloat(index) <= position + 0.001 ? Color.primary50 : Color.grey50)
                                .frame(width: 1, height: index == 0 || index == count - 1 ? 28 : 20)
                            if index < count - 1 { Spacer(minLength: 0) }
                        }
                    }
                    Capsule()
                        .fill(.white)
                        .frame(width: 2, height: 56)
                        .scaleEffect(x: isDragging ? 1 : 0.5, y: isDragging ? 1.04 : 1)
                        .shadow(color: .white.opacity(isDragging ? 0.5 : 0), radius: 4)
                        .offset(x: position * step - 1)
                }
                .frame(maxHeight: .infinity)
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
        } else if crossesLevel {
            levelHaptic.impactOccurred()
        } else {
            selectionHaptic.selectionChanged()
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
                TagPicker(options: ProfileSetupFlow.previousInvestments,
                          isSelected: { flow.previouslyInvested.contains($0) },
                          onTap: { flow.previouslyInvested.formSymmetricDifference([$0]) })
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
        case .businessOwner: "Business Profile Created"
        case .both: "Your Profiles Are Ready"
        case .investor, nil: "Investor Profile Complete"
        }
    }

    private var message: String {
        let business = flow.businessName.isEmpty ? "your business" : flow.businessName
        return switch flow.role {
        case .businessOwner: "\(business) is ready to meet investors. We'll let you know as soon as they show interest."
        case .both: "You can now invest in promising businesses and raise funding for \(business)."
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

#Preview {
    ProfileSetupView()
        .preferredColorScheme(.dark)
}
