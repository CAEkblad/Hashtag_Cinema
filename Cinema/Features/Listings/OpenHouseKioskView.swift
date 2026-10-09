import SwiftUI

/// Hand the phone to visitors at the door. Big fields, one tap sign in,
/// then it resets for the next guest. Every sign in becomes a lead.
struct OpenHouseKioskView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let listing: Listing
    let openHouse: OpenHouse

    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var workingWithAgent = false
    @State private var preapproved = false
    @State private var timeline = "Just looking"
    @State private var thanks = false
    @FocusState private var focus: Field?

    private enum Field { case name, phone, email }
    private let timelines = ["Just looking", "0 to 3 months", "3 to 6 months", "6+ months"]

    private var hostLine: String {
        let brokerage = store.profile.brokerage
        return brokerage.isEmpty ? "Hosted by \(store.profile.name)" : "Hosted by \(store.profile.name), \(brokerage)"
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (phone.filter(\.isNumber).count >= 7 || email.contains("@"))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if thanks {
                thankYou
            } else {
                form
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(12)
                    .background(Theme.surface, in: Circle())
            }
            .padding()
            .accessibilityLabel("Close sign in")
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome!")
                        .font(.cinema(34, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Please sign in to tour \(listing.address).")
                        .font(.cinema(17))
                        .foregroundStyle(Theme.textSecondary)
                    Text(hostLine)
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(.top, 40)

                TextField("Your name", text: $name)
                    .textContentType(.name)
                    .focused($focus, equals: .name)
                    .font(.cinema(20))
                    .inputStyle()
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .focused($focus, equals: .phone)
                    .font(.cinema(20))
                    .inputStyle()
                TextField("Email (optional)", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focus, equals: .email)
                    .font(.cinema(20))
                    .inputStyle()

                VStack(alignment: .leading, spacing: 8) {
                    Text("When are you hoping to move?")
                        .font(.cinema(15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Picker("Timeline", selection: $timeline) {
                        ForEach(timelines, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(spacing: 10) {
                    Toggle("I'm already working with an agent", isOn: $workingWithAgent)
                    Toggle("I'm pre-approved for a mortgage", isOn: $preapproved)
                }
                .font(.cinema(16, weight: .medium))
                .tint(Theme.red)
                .cardStyle()

                Button("Sign in") { submit() }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.5)

                Text("Your info goes only to \(store.profile.firstName). No spam.")
                    .font(.cinema(12))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var thankYou: some View {
        VStack(spacing: 16) {
            Image(systemName: "house.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Theme.red)
            Text("Thanks for stopping by!")
                .font(.cinema(28, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Enjoy the tour. \(store.profile.firstName) will follow up with the details.")
                .font(.cinema(16))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 32)
        }
        .task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation { thanks = false }
        }
    }

    private func submit() {
        store.signIn(
            OpenHouseVisitor(
                name: name.trimmingCharacters(in: .whitespaces),
                phone: phone,
                email: email.trimmingCharacters(in: .whitespaces),
                workingWithAgent: workingWithAgent,
                preapproved: preapproved,
                timeline: timeline,
                signedInAt: Date()
            ),
            openHouseID: openHouse.id,
            listingID: listing.id
        )
        name = ""
        phone = ""
        email = ""
        workingWithAgent = false
        preapproved = false
        timeline = "Just looking"
        focus = nil
        withAnimation { thanks = true }
    }
}
