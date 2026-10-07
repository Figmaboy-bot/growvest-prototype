import SwiftUI

/// The success seal from the design, animated as one calm sequence:
///
/// 1. the seal's scalloped outline traces itself while the seal turns gently into place,
/// 2. the green fill floods out from the centre and a ring pulses outwards,
/// 3. the tick draws itself,
/// 4. confetti bursts out as the tick is about to land,
/// 5. the seal gives a small "pop" as the tick lands.
///
/// Everything runs on a single keyframe timeline, so each part follows one continuous
/// curve. The seal is drawn from `SealShape` (the asset's own outline) and the tick is a
/// black stroke over the fill, so the finished frame matches the Figma asset.
///
/// With Reduce Motion the sequence still plays without the turn, zoom, ring and pop:
/// the outline traces, the fill fades in and the tick draws.
struct AnimatedSealCheck: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Rendered size of the icon. The design's asset is 64pt; the app shows it larger.
    var size: CGFloat = 96

    @State private var isPlaying = false
    @State private var hasLanded = false
    @State private var firesConfetti = false

    /// Everything is drawn in the asset's 64pt geometry, scaled to `size`.
    private var unit: CGFloat { size / 64 }

    private static let green = Color(red: 46 / 255, green: 204 / 255, blue: 113 / 255) // #2ECC71, from the asset

    // Timeline (seconds after `startDelay`)
    /// Wait for the success step to finish fading in.
    static let startDelay = 0.3
    private static let outlineDuration = 1.0
    private static let fillStart = 0.8
    private static let fillDuration = 0.55
    private static let ringStart = 1.05
    private static let checkStart = 1.5
    private static let checkDuration = 1.6
    private static var checkEnd: Double { checkStart + checkDuration }
    /// Confetti fires when the tick is almost drawn, so the burst peaks as it lands.
    private static var confettiStart: Double { checkStart + checkDuration * 0.85 }

    struct Frame {
        var outline = 0.0        // trim of the traced outline
        var outlineOpacity = 1.0
        var fill = 0.0           // 0 → 1 fill flood
        var check = 0.0          // trim of the tick
        var scale = 0.85
        var rotation = 0.0       // turns a full 360° while the tick draws
        var ring = 0.0
    }

    var body: some View {
        KeyframeAnimator(
            initialValue: reduceMotion ? Frame(scale: 1, rotation: 0, ring: 1) : Frame(),
            trigger: isPlaying
        ) { frame in
            ZStack {
                // Expanding ring
                Circle()
                    .stroke(Self.green, lineWidth: 2 * unit)
                    .frame(width: 56 * unit, height: 56 * unit)
                    .scaleEffect(0.9 + 0.8 * frame.ring)
                    // Fades in over the first part of its travel (no pop), then out as it expands.
                    .opacity(0.6 * min(1, frame.ring * 6) * (1 - frame.ring))

                ZStack {
                    SealShape()
                        .fill(Self.green)
                        .scaleEffect(reduceMotion ? 1 : 0.5 + 0.5 * frame.fill)
                        .opacity(min(1, frame.fill * 1.6))
                    SealShape()
                        .trim(from: 0, to: frame.outline)
                        .stroke(Self.green, style: StrokeStyle(lineWidth: 2 * unit, lineCap: .round, lineJoin: .round))
                        .opacity(frame.outlineOpacity)
                    CheckMark()
                        .trim(from: 0, to: frame.check)
                        .stroke(.black, style: StrokeStyle(lineWidth: 4 * unit, lineCap: .round, lineJoin: .round))
                }
                .frame(width: size, height: size)
                .scaleEffect(frame.scale)
                .rotationEffect(.degrees(frame.rotation))
            }
        } keyframes: { _ in
            KeyframeTrack(\.outline) {
                CubicKeyframe(1, duration: Self.outlineDuration, startVelocity: 0.6, endVelocity: 0)
            }
            KeyframeTrack(\.rotation) {
                // The seal is nearly round, so a spin only reads once the tick is on it:
                // the whole icon turns one full circle while the tick draws, easing in and out
                // and coming to rest exactly as the tick finishes (no overshoot to wobble).
                LinearKeyframe(0, duration: Self.checkStart)
                CubicKeyframe(reduceMotion ? 0 : 360, duration: Self.checkDuration, startVelocity: 0, endVelocity: 0)
            }
            KeyframeTrack(\.fill) {
                LinearKeyframe(0, duration: Self.fillStart)
                // Eases in and stops at the outline; no spring, so it never bulges past it.
                CubicKeyframe(1, duration: Self.fillDuration + 0.1, startVelocity: 0, endVelocity: 0)
            }
            KeyframeTrack(\.outlineOpacity) {
                // The fill covers the stroke; then fade it so the edge matches the asset exactly.
                LinearKeyframe(1, duration: Self.fillStart + Self.fillDuration)
                CubicKeyframe(0, duration: 0.3, startVelocity: 0, endVelocity: 0)
            }
            KeyframeTrack(\.scale) {
                CubicKeyframe(1, duration: Self.outlineDuration, startVelocity: 0, endVelocity: 0)
                // Hold through the drawing, then one gentle swell as the tick lands.
                LinearKeyframe(1, duration: Self.checkEnd - Self.outlineDuration)
                CubicKeyframe(reduceMotion ? 1 : 1.06, duration: 0.24, startVelocity: 0, endVelocity: 0)
                CubicKeyframe(1, duration: 0.5, startVelocity: 0, endVelocity: 0)
            }
            KeyframeTrack(\.check) {
                LinearKeyframe(0, duration: Self.checkStart)
                // Even pen speed with only a gentle start and finish.
                LinearKeyframe(1, duration: Self.checkDuration,
                               timingCurve: .bezier(startControlPoint: UnitPoint(x: 0.2, y: 0.08),
                                                    endControlPoint: UnitPoint(x: 0.35, y: 1)))
            }
            KeyframeTrack(\.ring) {
                LinearKeyframe(reduceMotion ? 1 : 0, duration: Self.ringStart)
                CubicKeyframe(1, duration: 1.8, startVelocity: reduceMotion ? 0 : 0.9, endVelocity: 0)
            }
        }
        .frame(width: size, height: size)
        .overlay { ConfettiBurst(isFiring: firesConfetti) }
        .accessibilityElement()
        .accessibilityLabel("Success")
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.8), trigger: hasLanded) { _, new in new }
        .task {
            // Let the success step finish fading in before the seal starts drawing.
            try? await Task.sleep(for: .seconds(Self.startDelay))
            isPlaying = true
            try? await Task.sleep(for: .seconds(Self.confettiStart))
            firesConfetti = true
            try? await Task.sleep(for: .seconds(Self.checkEnd - Self.confettiStart))
            hasLanded = true
        }
    }
}

/// The tick's centre line in the asset's 64×64 coordinate space.
private struct CheckMark: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 64, sy = rect.height / 64
        var path = Path()
        path.move(to: CGPoint(x: 22 * sx, y: 34 * sy))
        path.addLine(to: CGPoint(x: 28 * sx, y: 40 * sy))
        path.addLine(to: CGPoint(x: 42 * sx, y: 26 * sy))
        return path
    }
}

#Preview {
    AnimatedSealCheck()
        .padding(40)
        .background(.black)
}
