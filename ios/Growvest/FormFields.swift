import SwiftUI

/// The design's form controls, shared by the KYC and profile-setup flows.

struct FieldLabel: View {
    let title: String
    var body: some View {
        Text(title)
            .font(AppFont.interTight(16, relativeTo: .callout))
            .foregroundStyle(.white)
    }
}

/// The design's pill input: grey capsule, 20pt padding; the brand colour rings it while active.
struct FieldCapsule<Content: View>: View {
    var isActive: Bool
    @ViewBuilder var content: Content

    var body: some View {
        content
            .font(AppFont.interTight(16, relativeTo: .callout))
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Capsule().fill(Color.grey80))
            .overlay {
                Capsule()
                    .strokeBorder(Color.primary50, lineWidth: 1.5)
                    .opacity(isActive ? 1 : 0)
                    .shadow(color: Color.primary50.opacity(isActive ? 0.35 : 0), radius: 6)
            }
            .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

struct TextInputField: View {
    let title: String?
    let placeholder: String
    @Binding var text: String
    let isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title { FieldLabel(title: title) }
            FieldCapsule(isActive: isFocused) {
                TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Color.grey50))
                    .foregroundStyle(.white)
                    .tint(Color.primary50)
            }
        }
    }
}

/// The brand dropdown: a pill field that unfolds a grey options panel floating beneath it.
/// The open field gets the brand-colour ring; the selected option is marked in cyan.
struct BrandDropdown: View {
    let title: String
    let placeholder: String
    let options: [String]
    @Binding var selection: String?
    @Binding var isOpen: Bool
    /// The design's own caret icon; without one, an SF chevron is drawn.
    var caret: ImageResource?
    @State private var fieldHeight: CGFloat = 0
    /// Set between tapping an option and the panel closing, so a second tap can't sneak in.
    @State private var isClosing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            FieldLabel(title: title)

            Button { isOpen.toggle() } label: {
                FieldCapsule(isActive: isOpen) {
                    HStack {
                        Text(selection ?? placeholder)
                            .foregroundStyle(selection == nil ? Color.grey50 : .white)
                            .contentTransition(.opacity)
                        Spacer()
                        Group {
                            if let caret {
                                Image(caret)
                            } else {
                                Image(systemName: "chevron.down")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(isOpen ? Color.primary50 : Color.grey50)
                            }
                        }
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                    }
                }
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(selection ?? "Not selected")
            .accessibilityHint(isOpen ? "Collapses the options" : "Shows the options")
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fieldHeight = $0 }
            // The panel floats over the fields below instead of pushing them down:
            // as an overlay it takes no layout space, and its container is moved to sit 8pt
            // under the field. The transition lives inside, so it's anchored to the panel itself.
            .overlay(alignment: .top) {
                ZStack(alignment: .top) {
                    if isOpen {
                        optionsPanel.transition(DropdownFold())
                    }
                }
                .offset(y: fieldHeight + 8)
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    /// The highlight moves to the chosen row first, holds for a beat so you see it land,
    /// then the panel folds away.
    private func choose(_ option: String) {
        guard !isClosing else { return }
        isClosing = true
        withAnimation(.snappy(duration: 0.2)) { selection = option }
        Task {
            try? await Task.sleep(for: .milliseconds(220))
            isOpen = false
            isClosing = false
        }
    }

    private var optionsPanel: some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(options, id: \.self) { option in
                    let isSelected = option == selection
                    Button { choose(option) } label: {
                        HStack {
                            Text(option)
                                .font(AppFont.interTight(16, relativeTo: .callout))
                                .foregroundStyle(isSelected ? Color.primary50 : .white)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(Color.primary50)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isSelected ? Color.primary20 : .clear)
                        )
                        .contentShape(.rect(cornerRadius: 16))
                    }
                    .buttonStyle(DropdownRowStyle())
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(6)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: 300)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.grey80, in: .rect(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.grey70.opacity(0.6), lineWidth: 1))
    }
}

/// The options panel unrolls downwards out of the field, and rolls back up into it:
/// a top-anchored mask reveals it while it fades and settles from slightly above.
struct DropdownFold: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .mask(alignment: .top) {
                Rectangle()
                    .scaleEffect(x: 1, y: phase.isIdentity ? 1 : 0.15, anchor: .top)
            }
            .scaleEffect(phase.isIdentity ? 1 : 0.97, anchor: .top)
            .offset(y: phase.isIdentity ? 0 : -8)
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

struct DropdownRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.grey70.opacity(configuration.isPressed ? 0.6 : 0))
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
