import SwiftUI

/// "Verify Your Residential Address" form.
struct KYCAddressView: View {
    @Bindable var flow: KYCFlow
    @FocusState private var focused: Field?
    @State private var openDropdown: Dropdown?

    enum Field: Hashable { case address, houseNumber, landmark }
    enum Dropdown: Hashable { case state, localGovernment }

    /// A sample of states and local governments for the prototype's pickers.
    static let localGovernments: [String: [String]] = [
        "Lagos": ["Alimosho", "Eti-Osa", "Ikeja", "Lagos Island", "Surulere"],
        "FCT – Abuja": ["Abuja Municipal", "Bwari", "Gwagwalada", "Kuje"],
        "Rivers": ["Eleme", "Obio-Akpor", "Port Harcourt"],
        "Oyo": ["Ibadan North", "Ibadan South-West", "Ogbomosho North"],
        "Kano": ["Fagge", "Kano Municipal", "Nassarawa"],
        "Enugu": ["Enugu East", "Enugu North", "Nsukka"],
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                KYCHeading(
                    title: "Verify Your Residential Address",
                    message: "Enter your current address accurately to complete your verification and secure your account."
                )

                VStack(alignment: .leading, spacing: 12) {
                    BrandDropdown(title: "State", placeholder: "Select state",
                                  options: Self.localGovernments.keys.sorted(), selection: $flow.state,
                                  isOpen: dropdownBinding(.state))
                        // Keeps the open panel above the fields it floats over.
                        .zIndex(openDropdown == .state ? 1 : 0)
                        .onChange(of: flow.state) { old, new in
                            if old != new { flow.localGovernment = nil }
                        }

                    BrandDropdown(title: "Local governement", placeholder: "Select local governement",
                                  options: Self.localGovernments[flow.state ?? ""] ?? [],
                                  selection: $flow.localGovernment,
                                  isOpen: dropdownBinding(.localGovernment))
                        .disabled(flow.state == nil)
                        .opacity(flow.state == nil ? 0.5 : 1)
                        .zIndex(openDropdown == .localGovernment ? 1 : 0)

                    TextInputField(title: "Address", placeholder: "Enter your detailed address",
                                   text: $flow.address, isFocused: focused == .address)
                        .focused($focused, equals: .address)
                        .textContentType(.fullStreetAddress)
                        .submitLabel(.next)
                        .onSubmit { focused = .houseNumber }

                    TextInputField(title: "House number", placeholder: "House number",
                                   text: $flow.houseNumber, isFocused: focused == .houseNumber)
                        .focused($focused, equals: .houseNumber)
                        .keyboardType(.numbersAndPunctuation)
                        .submitLabel(.next)
                        .onSubmit { focused = .landmark }

                    VStack(alignment: .leading, spacing: 8) {
                        TextInputField(title: "Landmark (Optional)", placeholder: "Select landmark close to your address",
                                       text: $flow.landmark, isFocused: focused == .landmark)
                            .focused($focused, equals: .landmark)
                            .submitLabel(.done)
                        Text("Landmarks could be schools, supermarkets, popular places around your address.")
                            .font(AppFont.interTight(14, relativeTo: .footnote))
                            .foregroundStyle(Color.grey50)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        #if DEBUG
        .task {
            switch UserDefaults.standard.string(forKey: "demoKYC") {
            case "addressstate":
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(Motion.step) { openDropdown = .state }
            case "addresslga":
                flow.state = "Lagos"
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(Motion.step) { openDropdown = .localGovernment }
                try? await Task.sleep(for: .milliseconds(900))
                flow.localGovernment = "Ikeja"
            default: break
            }
        }
        #endif
        .onChange(of: focused) { _, new in
            if new != nil { withAnimation(Motion.step) { openDropdown = nil } }
        }
        .safeAreaInset(edge: .bottom) {
            Button("Done") {
                focused = nil
                flow.addressDone = true
                flow.path.removeLast()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!flow.isAddressValid)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .frame(maxWidth: 480)
            .background(Color(.systemBackground))
        }
    }
}

extension KYCAddressView {
    /// Only one dropdown is open at a time; opening one dismisses the keyboard.
    private func dropdownBinding(_ dropdown: Dropdown) -> Binding<Bool> {
        Binding(
            get: { openDropdown == dropdown },
            set: { isOpen in
                if isOpen { focused = nil }
                // Opening unfolds on the step spring; closing is quicker, so it gets out of the way.
                withAnimation(isOpen ? Motion.step : .smooth(duration: 0.3)) { openDropdown = isOpen ? dropdown : nil }
            }
        )
    }
}
