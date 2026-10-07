import SwiftUI

/// The design's floating bottom sheet as a reusable container: it floats 12pt in from the
/// screen edges, has 40pt corners all round, and dims/blurs the screen behind it.
/// Tapping the backdrop or dragging the sheet down dismisses it (unless `isDismissible` is false).
///
/// (The buy flow's `InvestmentSheet` is a richer, multi-step version of the same idea.)
struct FloatingSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    var isDismissible: Bool
    @ViewBuilder var sheet: () -> SheetContent

    @State private var dragOffset: CGFloat = 0

    private var dragProgress: Double { min(max(dragOffset / 400, 0), 1) }

    func body(content: Content) -> some View {
        ZStack {
            content
                // Design backdrop: a light 2.5pt blur (Figma: backdrop-blur 2px).
                .blur(radius: isPresented ? 2.5 * (1 - dragProgress) : 0)
                .scaleEffect(isPresented ? 0.98 + 0.02 * dragProgress : 1)
                .accessibilityHidden(isPresented)

            if isPresented {
                Color.white.opacity(0.1)
                    .opacity(1 - dragProgress)
                .ignoresSafeArea()
                .onTapGesture { if isDismissible { isPresented = false } }
                .accessibilityHidden(true)
                .transition(.opacity)

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    sheet()
                        .frame(maxWidth: .infinity)
                        .background(.black, in: .rect(cornerRadius: 40))
                        .frame(maxWidth: 520)
                        .offset(y: dragOffset)
                        .gesture(dragToDismiss)
                        .accessibilityAddTraits(.isModal)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .ignoresSafeArea(.container, edges: .bottom)
                .transition(.move(edge: .bottom))
                .onAppear { dragOffset = 0 }
                .onDisappear { dragOffset = 0 }
            }
        }
        .animation(Motion.sheet, value: isPresented)
    }

    private var dragToDismiss: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let y = value.translation.height
                dragOffset = y > 0 ? (isDismissible ? y : y * 0.15) : -sqrt(-y) * 2
            }
            .onEnded { value in
                let velocity = value.velocity.height
                if isDismissible,
                   value.translation.height > 120 || value.predictedEndTranslation.height > 320 {
                    // Carry the flick's momentum off screen, then remove the sheet.
                    let target: CGFloat = 1000
                    withAnimation(Motion.release(velocity: velocity, distance: target - dragOffset, duration: 0.4)) {
                        dragOffset = target
                    } completion: {
                        isPresented = false
                    }
                } else {
                    withAnimation(Motion.release(velocity: velocity, distance: -dragOffset, bounce: 0.15)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

extension View {
    func floatingSheet<Content: View>(
        isPresented: Binding<Bool>,
        isDismissible: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(FloatingSheetModifier(isPresented: isPresented, isDismissible: isDismissible, sheet: content))
    }
}
