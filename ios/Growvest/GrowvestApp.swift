import CoreText
import SwiftUI
import UIKit

@main
struct GrowvestApp: App {
    init() {
        FontRegistry.registerBundledFonts()
        FontRegistry.styleNavigationBars()
    }

    var body: some Scene {
        WindowGroup {
            FlowLauncherView()
                // Any text without its own font still uses Inter Tight.
                .font(AppFont.interTight(16))
                .preferredColorScheme(.dark)
        }
    }
}

/// Registers the .ttf files shipped in the bundle so they can be used with `Font.custom`.
enum FontRegistry {
    static func registerBundledFonts() {
        let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    /// Navigation bar titles are drawn by UIKit, so they don't pick up SwiftUI's `.font`.
    static func styleNavigationBars() {
        func interTight(_ size: CGFloat, _ style: UIFont.TextStyle) -> UIFont {
            let font = UIFont(name: "InterTight-SemiBold", size: size) ?? .systemFont(ofSize: size, weight: .semibold)
            return UIFontMetrics(forTextStyle: style).scaledFont(for: font)
        }
        let appearance = UINavigationBar.appearance()
        appearance.titleTextAttributes = [.font: interTight(17, .headline)]
        appearance.largeTitleTextAttributes = [.font: interTight(34, .largeTitle)]
    }
}
