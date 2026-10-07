import SwiftUI

/// "Scan your ID Card": capture the front, then the back. Each capture plays a scan
/// sweep across the card; once both sides are scanned the tick confirms.
struct KYCIDScanView: View {
    @Bindable var flow: KYCFlow

    enum Side: String, CaseIterable { case front = "Front", back = "Back" }

    @State private var side: Side = .front
    @State private var scanProgress: [Side: Double] = [:]   // 0…1 per captured side
    @State private var isScanning = false
    @State private var flash = false
    @State private var cameraTurns = 0.0
    @Namespace private var segment

    private var isCaptured: Bool { scanProgress[side] != nil }
    private var bothScanned: Bool { scanProgress[.front] == 1 && scanProgress[.back] == 1 }

    var body: some View {
        VStack(spacing: 0) {
            KYCHeading(
                title: "Scan your ID Card (\(side.rawValue))",
                message: "Place your ID card in a well-lit area and ensure all details are clearly visible for a quick and seamless verification process."
            )
            .contentTransition(.opacity)
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Spacer(minLength: 16).frame(maxHeight: 40)

            VStack(spacing: 16) {
                preview
                sideSwitcher
                    .padding(.horizontal, 24)
            }

            Spacer(minLength: 16)

            controls
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.impact(weight: .medium), trigger: flash) { _, new in new }
        .sensoryFeedback(.success, trigger: scanProgress[side] == 1) { _, done in done }
        #if DEBUG
        .task {
            if UserDefaults.standard.string(forKey: "demoKYC") == "idcardscan" {
                try? await Task.sleep(for: .milliseconds(600))
                capture()
            }
        }
        #endif
    }

    // MARK: Preview

    private var preview: some View {
        ZStack {
            Color.grey80

            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.25))
                .overlay {
                    if let progress = scanProgress[side] {
                        ScannedCard(image: side == .front ? .idCardFront : .idCardBack, progress: progress)
                            .transition(.opacity)
                    } else {
                        // Live camera preview of the current side, waiting for capture.
                        ZStack {
                            // Constrained to the viewfinder, so the fill never makes this
                            // stack bigger than the frame (which pushed the corner guides off-screen).
                            Image(side == .front ? .idCardFront : .idCardBack)
                                .resizable()
                                .scaledToFill()
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                .clipped()
                                .blur(radius: 1)
                                .opacity(0.55)
                            ViewfinderCorners()
                                .stroke(.white.opacity(0.85), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .padding(10)
                            Text("Tap ✓ to capture the \(side.rawValue.lowercased())")
                                .font(AppFont.interTight(13, relativeTo: .footnote))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(.black.opacity(0.55)))
                                .frame(maxHeight: .infinity, alignment: .bottom)
                                .padding(.bottom, 18)
                        }
                        .transition(.opacity)
                    }
                }
                .clipShape(.rect(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.primary50, lineWidth: 2)
                        .opacity(isCaptured ? 1 : 0)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 17)

            // Shutter flash
            Color.white.opacity(flash ? 0.7 : 0).allowsHitTesting(false)
        }
        .frame(height: 300)
        .animation(.easeInOut(duration: 0.3), value: side)
        .animation(.easeInOut(duration: 0.3), value: isCaptured)
    }

    // MARK: Front / Back switcher

    private var sideSwitcher: some View {
        HStack(spacing: 10) {
            ForEach(Side.allCases, id: \.self) { item in
                Button { side = item } label: {
                    Text(item.rawValue)
                        .font(AppFont.interTight(16, relativeTo: .callout))
                        .foregroundStyle(side == item ? Color.ink : Color.grey50)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            if side == item {
                                Capsule().fill(Color.primary50)
                                    .matchedGeometryEffect(id: "pill", in: segment)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isScanning)
                .accessibilityAddTraits(side == item ? .isSelected : [])
            }
        }
        .padding(8)
        .background(Capsule().fill(Color.grey80))
        .animation(Motion.select, value: side)
    }

    // MARK: Camera controls

    private var controls: some View {
        HStack {
            Button {
                withAnimation(.spring(duration: 0.5, bounce: 0.2)) { cameraTurns += 1 }
            } label: {
                Image(.cameraRotate)
                    .rotationEffect(.degrees(cameraTurns * 180))
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Color.grey80))
            }
            .buttonStyle(RowPressStyle())
            .accessibilityLabel("Switch camera")

            Spacer()

            Button(action: primaryAction) {
                Image(.tick)
                    .frame(width: 80, height: 80)
                    .background(Circle().fill(Color.primary50))
                    .opacity(isScanning ? 0.5 : 1)
            }
            .buttonStyle(RowPressStyle())
            .disabled(isScanning)
            .accessibilityLabel(isCaptured ? "Confirm" : "Capture \(side.rawValue.lowercased())")

            Spacer()

            Button(action: capture) {
                Image(.imageUpload)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Color.grey80))
            }
            .buttonStyle(RowPressStyle())
            .disabled(isScanning)
            .accessibilityLabel("Upload from photos")
        }
    }

    // MARK: Actions

    /// Tick: capture the current side, or move on once it's scanned.
    private func primaryAction() {
        if !isCaptured {
            capture()
        } else if bothScanned {
            flow.idCardDone = true
            flow.path.removeLast()
        } else if side == .front {
            side = .back
            if scanProgress[.back] == nil { capture() }
        } else {
            side = .front
        }
    }

    private func capture() {
        let captured = side
        isScanning = true
        withAnimation(.easeOut(duration: 0.08)) { flash = true }
        withAnimation(.easeIn(duration: 0.35).delay(0.08)) { flash = false }
        scanProgress[captured] = 0
        withAnimation(.easeInOut(duration: 1.8).delay(0.25)) { scanProgress[captured] = 1 }
        Task {
            try? await Task.sleep(for: .seconds(2.1))
            isScanning = false
            // After the front is scanned, move on to the back automatically.
            if captured == .front, scanProgress[.back] == nil {
                try? await Task.sleep(for: .milliseconds(450))
                side = .back
            }
        }
    }
}

/// The captured card with the design's frosted "still scanning" band, which recedes
/// downwards as `progress` goes from 0 to 1, led by a cyan scan line.
private struct ScannedCard: View, Animatable {
    let image: ImageResource
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let lineY = height * progress
            ZStack(alignment: .top) {
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: height)
                    .clipped()

                // Unscanned region: blurred copy below the line.
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: height)
                    .clipped()
                    .blur(radius: 6)
                    .overlay(Color.black.opacity(0.1))
                    .mask(alignment: .top) {
                        Rectangle().padding(.top, lineY)
                    }

                // Scan line
                Rectangle()
                    .fill(Color.primary50)
                    .frame(height: 3)
                    .shadow(color: Color.primary50.opacity(0.8), radius: 8)
                    .offset(y: lineY - 1.5)
                    .opacity(progress < 1 ? 1 : 0)
            }
        }
    }
}

/// Four corner brackets for the empty viewfinder.
private struct ViewfinderCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let l: CGFloat = 28
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + l)); p.addLine(to: CGPoint(x: rect.minX, y: rect.minY)); p.addLine(to: CGPoint(x: rect.minX + l, y: rect.minY))
        p.move(to: CGPoint(x: rect.maxX - l, y: rect.minY)); p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY)); p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + l))
        p.move(to: CGPoint(x: rect.maxX, y: rect.maxY - l)); p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)); p.addLine(to: CGPoint(x: rect.maxX - l, y: rect.maxY))
        p.move(to: CGPoint(x: rect.minX + l, y: rect.maxY)); p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY)); p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - l))
        return p
    }
}
