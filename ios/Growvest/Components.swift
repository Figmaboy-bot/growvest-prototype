import SwiftUI
import UIKit

/// The window's home-indicator inset. Unlike the safe area SwiftUI hands to a view,
/// it doesn't change while the keyboard is up, so layouts can pin to it.
var homeIndicatorInset: CGFloat {
    (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.safeAreaInsets.bottom ?? 0
}

/// Rounded grey card of label/value rows separated by black hairlines
/// ("Current Value", "Investment Summary", "Investment Details").
struct SummaryCard: View {
    let rows: [(label: String, value: String)]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack {
                    Text(row.label)
                        .foregroundStyle(Color.grey50)
                    Spacer(minLength: 12)
                    Text(row.value)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.trailing)
                }
                .font(AppFont.interTight(14, relativeTo: .subheadline))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 16)
                .padding(.vertical, 15)

                if index < rows.count - 1 {
                    Rectangle().fill(.black).frame(height: 1)
                }
            }
        }
        .background(Color.grey80, in: .rect(cornerRadius: 24))
    }
}

/// A grey caption above a card ("Business", "Investment Summary", …).
struct LabeledSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.interTight(14, relativeTo: .subheadline))
                .foregroundStyle(Color.grey50)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The 64×6 grab handle drawn at the top of each bottom sheet.
struct SheetHandle: View {
    var body: some View {
        Capsule().fill(Color.grey80).frame(width: 64, height: 6)
    }
}

/// Handle + centered title, with an optional round back button on the leading edge.
struct SheetHeader: View {
    let title: String
    var onBack: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            SheetHandle()
            Text(title)
                .font(AppFont.interTight(16, relativeTo: .headline))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottomLeading) {
            if let onBack {
                Button(action: onBack) {
                    Image(.arrowLeft)
                }
                .buttonStyle(CircleIconButtonStyle())
                .accessibilityLabel("Back")
                .offset(y: 10)
            }
        }
    }
}
