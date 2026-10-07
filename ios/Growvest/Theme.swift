import SwiftUI

// Colors live in Assets.xcassets, named after the Figma variables
// (primary/50 → Primary50, grey/80 → Grey80, …) and are referenced through
// the generated asset symbols, e.g. `Color.grey80`.

/// Brand typography. Inter Tight is the app's only face (it also replaces the Satoshi,
/// General Sans, Inter and Playfair styles from the design). Every style scales with Dynamic Type.
enum AppFont {
    static func interTight(_ size: CGFloat, _ weight: Weight = .medium, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(weight == .semibold ? "InterTight-SemiBold" : "InterTight-Medium", size: size, relativeTo: style)
    }

    enum Weight { case medium, semibold }
}

// MARK: - Motion

/// Shared springs so every transition in the app feels like the same physical system.
enum Motion {
    /// Sheet presenting / dismissing.
    static let sheet = Animation.spring(duration: 0.5, bounce: 0.06)
    /// Moving between sheet steps and resizing the sheet.
    static let step = Animation.spring(duration: 0.5, bounce: 0)
    /// Button / key press feedback.
    static let press = Animation.spring(duration: 0.25, bounce: 0.25)
    /// Selection changes (radio, chips, PIN dots).
    static let select = Animation.spring(duration: 0.3, bounce: 0.2)
    /// Sheet springing back after an incomplete drag.
    static let snapBack = Animation.spring(duration: 0.45, bounce: 0.12)

    /// A spring that starts at the finger's release velocity, the way UIKit hands a gesture
    /// off to an animation, so there's no jolt when you let go.
    /// - Parameters:
    ///   - velocity: release velocity along the axis (points per second).
    ///   - distance: how far the animation will travel (target − current position).
    static func release(velocity: CGFloat, distance: CGFloat, duration: Double = 0.45, bounce: Double = 0) -> Animation {
        let relativeVelocity = abs(distance) < 1 ? 0 : velocity / distance
        return .interpolatingSpring(duration: duration, bounce: bounce, initialVelocity: relativeVelocity)
    }
}

// MARK: - Button styles

/// The cyan pill used for primary actions ("Continue", "Confirm Investment", "Done").
/// Disabled, it falls back to the design's 20% tint state.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.interTight(16, relativeTo: .callout))
            .foregroundStyle(isEnabled ? Color.ink : Color.primary50)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background {
                Capsule()
                    .fill(isEnabled ? Color.primary50 : Color.primary20)
                    .overlay {
                        if isEnabled {
                            // The design's inner highlight: inset white shadows on the top-left and bottom.
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.1), .white.opacity(0.45)],
                                                   startPoint: .top, endPoint: .bottom),
                                    lineWidth: 2
                                )
                                .blur(radius: 1.5)
                                .clipShape(Capsule())
                        }
                    }
            }
            .contentShape(Capsule())
            .brightness(configuration.isPressed ? -0.06 : 0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.press, value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.25), value: isEnabled)
    }
}

/// "View Investment": the tinted secondary pill.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.interTight(16, relativeTo: .callout))
            .foregroundStyle(Color.primary50)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Capsule().fill(Color.primary20))
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

/// Small grey pills (quick amounts, share count, Face ID).
struct ChipButtonStyle: ButtonStyle {
    var isSelected = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.interTight(12, relativeTo: .caption))
            .foregroundStyle(isSelected ? Color.white : Color.grey30)
            .lineLimit(1)
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(isSelected ? Color.grey70 : Color.grey80))
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(Motion.press, value: configuration.isPressed)
            .animation(Motion.select, value: isSelected)
    }
}

/// The 40pt round back button used inside the bottom sheets.
struct CircleIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 40, height: 40)
            .background(Circle().fill(Color.grey80))
            .contentShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

/// iOS 26 renders toolbar buttons inside a glass circle automatically; on earlier
/// versions draw the design's grey circle instead.
struct LegacyCircleBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
        } else {
            content.buttonStyle(CircleIconButtonStyle())
        }
    }
}

// MARK: - Transitions

private struct BlurTransition: ViewModifier {
    let radius: CGFloat
    func body(content: Content) -> some View { content.blur(radius: radius) }
}

extension AnyTransition {
    /// A little motion blur while entering/leaving, as Apple's rolling numbers do.
    static func blurred(_ radius: CGFloat) -> AnyTransition {
        .modifier(active: BlurTransition(radius: radius), identity: BlurTransition(radius: 0))
    }
}
