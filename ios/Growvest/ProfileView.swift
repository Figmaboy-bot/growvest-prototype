import SwiftUI

/// The Profile tab (Figma 1074-22444): the user's photo, name and email, then grouped
/// settings rows under General, Preference and Others. KYC Verification opens the KYC flow;
/// Log out leads back to the flow launcher.
struct ProfileView: View {
    let onLogOut: () -> Void
    @State private var showsKYC = false

    private static let sections: [(title: String, rows: [ProfileRow])] = [
        ("General", [
            ProfileRow(icon: .profileUser, title: "Profile Information"),
            ProfileRow(icon: .profileShieldCheck, title: "KYC Verification"),
            ProfileRow(icon: .profileBank, title: "Bank accounts"),
        ]),
        ("Preference", [
            ProfileRow(icon: .profileFaders, title: "Investment preferences"),
            ProfileRow(icon: .profileBell, title: "Notification Preferences"),
            ProfileRow(icon: .profileLockKey, title: "Security & Privacy"),
        ]),
        ("Others", [
            ProfileRow(icon: .profileHeadset, title: "Help & support"),
            ProfileRow(icon: .profileUserAdd, title: "Refer & earn"),
            ProfileRow(icon: .profileFileText, title: "Legal & policies"),
            ProfileRow(icon: .profileSignOut, title: "Log out", isDestructive: true),
        ]),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Profile")
                    .font(AppFont.interTight(20, .semibold, relativeTo: .title3))
                    .foregroundStyle(.white)
                    .frame(height: 40)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 20) {
                    identity
                    ForEach(Self.sections, id: \.title) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.title)
                                .font(AppFont.interTight(14, relativeTo: .subheadline))
                                .foregroundStyle(Color.grey50)
                                .accessibilityAddTraits(.isHeader)
                            VStack(spacing: 0) {
                                ForEach(section.rows) { row in
                                    Button { select(row) } label: {
                                        rowLabel(row, isFirst: row.id == section.rows.first?.id, isLast: row.id == section.rows.last?.id)
                                    }
                                    .buttonStyle(RowPressStyle())
                                }
                            }
                            .background(RoundedRectangle(cornerRadius: 24).fill(Color.grey80))
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 120)          // room to scroll past the floating tab bar
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .fullScreenCover(isPresented: $showsKYC) { KYCView() }
        #if DEBUG
        .onAppear {
            if UserDefaults.standard.string(forKey: "demoProfile") == "kyc" { showsKYC = true }
        }
        #endif
    }

    private func select(_ row: ProfileRow) {
        switch row.title {
        case "KYC Verification": showsKYC = true
        case "Log out": onLogOut()
        default: break
        }
    }

    private var identity: some View {
        VStack(spacing: 8) {
            Image(.profilePhoto)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 25.6, style: .continuous))
                .accessibilityHidden(true)
            VStack(spacing: 4) {
                Text("Odeniran Sulaimon")
                    .font(AppFont.interTight(20, relativeTo: .title3))
                    .foregroundStyle(.white)
                Text(verbatim: "sulaimon@growvest.app")      // verbatim: no auto-linked email
                    .font(AppFont.interTight(14, relativeTo: .subheadline))
                    .foregroundStyle(Color.grey50)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// One settings row: icon and label, with a black hairline under every row but the last.
    /// Spacing follows the design: 16pt above the first row, 12pt above the rest, 16pt below each.
    private func rowLabel(_ row: ProfileRow, isFirst: Bool, isLast: Bool) -> some View {
        HStack(spacing: 8) {
            Image(row.icon)
            Text(row.title)
                .font(AppFont.interTight(14, relativeTo: .subheadline))
                .foregroundStyle(row.isDestructive ? Color.error50 : Color.grey50)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, isFirst ? 16 : 12)
        .padding(.bottom, 16)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(.black).frame(height: 1) }
        }
        .contentShape(.rect)
    }
}

private struct ProfileRow: Identifiable {
    let icon: ImageResource
    let title: String
    var isDestructive = false
    var id: String { title }
}

#Preview {
    ProfileView {}
        .preferredColorScheme(.dark)
}
