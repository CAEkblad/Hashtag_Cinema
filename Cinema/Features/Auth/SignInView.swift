import SwiftUI

struct SignInView: View {
    @Environment(CinemaStore.self) private var store
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focused: Field?

    private enum Field { case email, password }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.redDeep.opacity(0.55), Theme.background, Theme.background], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 14) {
                    CinemaLogo(size: 40)
                    Text("Your content team in your pocket.")
                        .font(.cinema(17, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    feature("lightbulb.fill", "Daily ideas made for your market")
                    feature("scissors", "Film on your phone, we edit")
                    feature("paperplane.fill", "Post everywhere, capture leads")
                    feature("person.3.fill", "Learn from agents nationwide")
                }
                .padding(.horizontal, 8)

                Spacer()

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focused = .password }
                        .inputStyle()

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .focused($focused, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { store.signIn(email: email) }
                        .inputStyle()

                    Button("Sign in") { store.signIn(email: email) }
                        .buttonStyle(PrimaryButtonStyle())

                    Button {
                        // Wire to Sign in with Apple (AuthenticationServices) once the
                        // capability is added under Signing & Capabilities.
                        store.signIn(email: "")
                    } label: {
                        Label("Continue with Apple", systemImage: "apple.logo")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Text("Demo mode: any email works.")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private func feature(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.red)
                .frame(width: 24)
            Text(text)
                .font(.cinema(16, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

extension View {
    func inputStyle() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.stroke, lineWidth: 1))
            .foregroundStyle(Theme.textPrimary)
    }
}
