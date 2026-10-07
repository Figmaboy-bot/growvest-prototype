import SwiftUI

/// "Center your face": a live-camera stand-in with the oval guide. A scan line sweeps the
/// oval while the face is detected; then "Snap" takes the photo.
struct KYCFaceScanView: View {
    @Bindable var flow: KYCFlow

    @State private var scanPhase = 0.0          // drives the sweeping line (0…1, repeats)
    @State private var isFaceDetected = false
    @State private var flash = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let oval = CGSize(width: 280, height: 350)

    var body: some View {
        VStack(spacing: 0) {
            camera
                .frame(maxHeight: 574)

            VStack(spacing: 40) {
                KYCHeading(
                    title: isFaceDetected ? "Face detected" : "Center your face",
                    message: isFaceDetected
                        ? "Hold still, then take a photo"
                        : "Place your face inside the shape, then take a photo",
                    alignment: .center
                )
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: isFaceDetected)

                Button("Snap", action: snap)
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!isFaceDetected)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 8)
            .frame(maxWidth: 480)
        }
        .sensoryFeedback(.success, trigger: isFaceDetected) { _, new in new }
        .sensoryFeedback(.impact(weight: .medium), trigger: flash) { _, new in new }
        .task {
            // Simulated detection: sweep the oval for a few passes, then lock on.
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { scanPhase = 1 }
            }
            try? await Task.sleep(for: .seconds(2.6))
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) { isFaceDetected = true }
        }
    }

    private var camera: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let ovalRect = CGRect(x: (size.width - oval.width) / 2,
                                  y: min(62, max(0, (size.height - oval.height) / 2)),
                                  width: oval.width, height: oval.height)
            ZStack(alignment: .topLeading) {
                // Background: softened, lightly tinted camera feed
                portrait(size)
                    .blur(radius: 2.5)
                    .overlay(Color.white.opacity(0.1))

                // Sharp feed inside the oval
                portrait(size)
                    .mask(alignment: .topLeading) {
                        Capsule().frame(width: ovalRect.width, height: ovalRect.height)
                            .offset(x: ovalRect.minX, y: ovalRect.minY)
                    }

                // Scan line + glow sweeping inside the oval
                ScanSweep(phase: scanPhase)
                    .frame(width: ovalRect.width, height: ovalRect.height)
                    .clipShape(Capsule())
                    .offset(x: ovalRect.minX, y: ovalRect.minY)
                    .opacity(isFaceDetected ? 0 : 1)

                Capsule()
                    .strokeBorder(isFaceDetected ? Color(red: 46 / 255, green: 204 / 255, blue: 113 / 255) : Color.primary50,
                                  lineWidth: isFaceDetected ? 3 : 2)
                    .frame(width: ovalRect.width, height: ovalRect.height)
                    .scaleEffect(isFaceDetected ? 1.02 : 1)
                    .offset(x: ovalRect.minX, y: ovalRect.minY)

                Color.white.opacity(flash ? 0.8 : 0).allowsHitTesting(false)
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
    }

    private func portrait(_ size: CGSize) -> some View {
        Image(.facePortrait)
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipped()
    }

    private func snap() {
        withAnimation(.easeOut(duration: 0.08)) { flash = true }
        Task {
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(.easeIn(duration: 0.35)) { flash = false }
            try? await Task.sleep(for: .milliseconds(450))
            flow.faceDone = true
            flow.path.removeLast()
        }
    }
}

/// The design's scan line: a white line with a fading glow trailing below it.
private struct ScanSweep: View, Animatable {
    var phase: Double

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    var body: some View {
        GeometryReader { proxy in
            let y = proxy.size.height * (0.12 + 0.6 * phase)
            VStack(spacing: 0) {
                Rectangle().fill(.white).frame(height: 3)
                LinearGradient(colors: [.white.opacity(0.48), .white.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: proxy.size.height * 0.54)
            }
            .offset(y: y)
        }
    }
}
