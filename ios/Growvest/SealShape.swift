import SwiftUI

/// The scalloped outline of the success seal, converted from the Figma asset's path
/// (`SealCheck` / seal-check.svg, 64×64 viewBox) so it can be traced and filled in code.
struct SealShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 64, sy = rect.height / 64
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy) }
        var path = Path()
        path.move(to: p(56.465, 25.705))
        path.addCurve(to: p(54.18, 22.8125), control1: p(55.5225, 24.72), control2: p(54.5475, 23.705))
        path.addCurve(to: p(53.8, 19.3275), control1: p(53.84, 21.995), control2: p(53.82, 20.64))
        path.addCurve(to: p(51.8, 12.2), control1: p(53.7625, 16.8875), control2: p(53.7225, 14.1225))
        path.addCurve(to: p(44.6725, 10.2), control1: p(49.8775, 10.2775), control2: p(47.1125, 10.2375))
        path.addCurve(to: p(41.1875, 9.82), control1: p(43.36, 10.18), control2: p(42.005, 10.16))
        path.addCurve(to: p(38.295, 7.535), control1: p(40.2975, 9.4525), control2: p(39.28, 8.4775))
        path.addCurve(to: p(32, 4), control1: p(36.57, 5.8775), control2: p(34.61, 4))
        path.addCurve(to: p(25.705, 7.535), control1: p(29.39, 4), control2: p(27.4325, 5.8775))
        path.addCurve(to: p(22.8125, 9.82), control1: p(24.72, 8.4775), control2: p(23.705, 9.4525))
        path.addCurve(to: p(19.3275, 10.2), control1: p(22, 10.16), control2: p(20.64, 10.18))
        path.addCurve(to: p(12.2, 12.2), control1: p(16.8875, 10.2375), control2: p(14.1225, 10.2775))
        path.addCurve(to: p(10.2, 19.3275), control1: p(10.2775, 14.1225), control2: p(10.25, 16.8875))
        path.addCurve(to: p(9.82, 22.8125), control1: p(10.18, 20.64), control2: p(10.16, 21.995))
        path.addCurve(to: p(7.535, 25.705), control1: p(9.4525, 23.7025), control2: p(8.4775, 24.72))
        path.addCurve(to: p(4, 32), control1: p(5.8775, 27.43), control2: p(4, 29.39))
        path.addCurve(to: p(7.535, 38.295), control1: p(4, 34.61), control2: p(5.8775, 36.5675))
        path.addCurve(to: p(9.82, 41.1875), control1: p(8.4775, 39.28), control2: p(9.4525, 40.295))
        path.addCurve(to: p(10.2, 44.6725), control1: p(10.16, 42.005), control2: p(10.18, 43.36))
        path.addCurve(to: p(12.2, 51.8), control1: p(10.2375, 47.1125), control2: p(10.2775, 49.8775))
        path.addCurve(to: p(19.3275, 53.8), control1: p(14.1225, 53.7225), control2: p(16.8875, 53.7625))
        path.addCurve(to: p(22.8125, 54.18), control1: p(20.64, 53.82), control2: p(21.995, 53.84))
        path.addCurve(to: p(25.705, 56.465), control1: p(23.7025, 54.5475), control2: p(24.72, 55.5225))
        path.addCurve(to: p(32, 60), control1: p(27.43, 58.1225), control2: p(29.39, 60))
        path.addCurve(to: p(38.295, 56.465), control1: p(34.61, 60), control2: p(36.5675, 58.1225))
        path.addCurve(to: p(41.1875, 54.18), control1: p(39.28, 55.5225), control2: p(40.295, 54.5475))
        path.addCurve(to: p(44.6725, 53.8), control1: p(42.005, 53.84), control2: p(43.36, 53.82))
        path.addCurve(to: p(51.8, 51.8), control1: p(47.1125, 53.7625), control2: p(49.8775, 53.7225))
        path.addCurve(to: p(53.8, 44.6725), control1: p(53.7225, 49.8775), control2: p(53.7625, 47.1125))
        path.addCurve(to: p(54.18, 41.1875), control1: p(53.82, 43.36), control2: p(53.84, 42.005))
        path.addCurve(to: p(56.465, 38.295), control1: p(54.5475, 40.2975), control2: p(55.5225, 39.28))
        path.addCurve(to: p(60, 32), control1: p(58.1225, 36.57), control2: p(60, 34.61))
        path.addCurve(to: p(56.465, 25.705), control1: p(60, 29.39), control2: p(58.1225, 27.4325))
        path.closeSubpath()
        return path
    }
}
