import SwiftUI

/// A one-shot confetti burst that bursts out from its centre, then drifts down and fades.
///
/// It is drawn in a `Canvas` overlay that takes no layout space and ignores touches, so it
/// can sit on top of a small view (like the success seal) and spill out over the screen.
/// The burst starts when `isFiring` turns true; with Reduce Motion it never plays.
struct ConfettiBurst: View {
    var isFiring: Bool
    var colors: [Color] = [
        Color(red: 46 / 255, green: 204 / 255, blue: 113 / 255), // seal green
        .primary50,
        .warning50,
        .white,
    ]
    var count = 70

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate: Date?
    @State private var pieces: [Piece] = []

    /// How long a piece lives before it has fully faded.
    private static let lifetime = 2.4
    /// Downward acceleration, in points per second².
    private static let gravity = 520.0
    /// Air drag: the share of velocity lost per second, so the burst slows and then floats.
    private static let drag = 1.6

    struct Piece {
        var velocity: CGVector
        var spin: Double          // radians per second
        var flip: Double          // how fast the piece tumbles (fakes a 3D flip)
        var size: CGSize
        var isRound: Bool
        var colorIndex: Int
        var delay: Double
    }

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .overlay {
                if let startDate {
                    TimelineView(.animation(paused: false)) { timeline in
                        let elapsed = timeline.date.timeIntervalSince(startDate)
                        Canvas { context, size in
                            draw(in: &context, size: size, elapsed: elapsed)
                        }
                        .frame(width: 600, height: 900)
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
            .onChange(of: isFiring, initial: true) { _, firing in
                guard firing, !reduceMotion, startDate == nil else { return }
                pieces = (0..<count).map { _ in Self.makePiece(colorCount: colors.count) }
                startDate = .now
            }
            .task(id: startDate) {
                // Drop the timeline once the last piece has faded, so it stops redrawing.
                guard startDate != nil else { return }
                try? await Task.sleep(for: .seconds(Self.lifetime + 0.3))
                pieces = []
            }
    }

    private static func makePiece(colorCount: Int) -> Piece {
        // Mostly upwards and outwards, a little downwards too, so it reads as a pop.
        let angle = Double.random(in: -.pi * 0.95 ... .pi * 0.05) - .pi * 0.05
        let speed = Double.random(in: 260...620)
        let isRound = Double.random(in: 0...1) < 0.25
        let side = Double.random(in: 5...8)
        return Piece(
            velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
            spin: Double.random(in: -9...9),
            flip: Double.random(in: 6...14),
            size: isRound ? CGSize(width: side, height: side) : CGSize(width: side * 0.7, height: side * 1.6),
            isRound: isRound,
            colorIndex: Int.random(in: 0..<colorCount),
            delay: Double.random(in: 0...0.08)
        )
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, elapsed: Double) {
        let origin = CGPoint(x: size.width / 2, y: size.height / 2)
        for piece in pieces {
            let t = elapsed - piece.delay
            guard t > 0, t < Self.lifetime else { continue }

            // Velocity decays as e^(-drag·t); integrate it for the position, then add gravity
            // as a "terminal velocity" drift so pieces float down instead of plummeting.
            let decay = (1 - exp(-Self.drag * t)) / Self.drag
            let fall = Self.gravity / Self.drag * (t - decay)
            let x = origin.x + piece.velocity.dx * decay
            let y = origin.y + piece.velocity.dy * decay + fall

            let fadeStart = Self.lifetime * 0.6
            let opacity = t < fadeStart ? 1 : 1 - (t - fadeStart) / (Self.lifetime - fadeStart)

            var ctx = context
            ctx.opacity = opacity
            ctx.translateBy(x: x, y: y)
            ctx.rotate(by: .radians(piece.spin * t))
            // Squash one axis with a cosine so the piece looks like it's tumbling.
            ctx.scaleBy(x: 1, y: piece.isRound ? 1 : max(0.15, abs(cos(piece.flip * t))))

            let rect = CGRect(x: -piece.size.width / 2, y: -piece.size.height / 2,
                              width: piece.size.width, height: piece.size.height)
            let path = piece.isRound ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 1)
            ctx.fill(path, with: .color(colors[piece.colorIndex]))
        }
    }
}

#Preview {
    struct Demo: View {
        @State private var fire = false
        var body: some View {
            ConfettiBurst(isFiring: fire)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black)
                .onTapGesture { fire = true }
        }
    }
    return Demo()
}
