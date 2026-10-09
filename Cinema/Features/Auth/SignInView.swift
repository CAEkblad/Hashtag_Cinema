import SwiftUI

struct SignInView: View {
    @Environment(CinemaStore.self) private var store
    @State private var email = ""
    @State private var code = ""
    @State private var codeSent = false
    @State private var isWorking = false
    @FocusState private var focused: Field?

    private enum Field { case email, code }

    private var emailIsValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.red.opacity(0.16), Theme.background, Theme.background], startPoint: .top, endPoint: .bottom)
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
                    feature("mappin.and.ellipse", "Daily ideas for your Florida city")
                    feature("scissors", "Film on your phone, we edit")
                    feature("paperplane.fill", "Post everywhere, capture leads")
                    feature("person.3.fill", "Learn from agents nationwide")
                }
                .padding(.horizontal, 8)

                Spacer()

                VStack(spacing: 12) {
                    if codeSent {
                        Text("We sent a 6 digit code to \(email)")
                            .font(.cinema(14))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextField("6 digit code", text: $code)
                            .textContentType(.oneTimeCode)
                            .keyboardType(.numberPad)
                            .focused($focused, equals: .code)
                            .inputStyle()
                        Button {
                            Task { await verify() }
                        } label: {
                            if isWorking { ProgressView().tint(.white) } else { Text("Sign in") }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(code.count < 6 || isWorking)
                        Button("Use a different email") {
                            codeSent = false
                            code = ""
                        }
                        .font(.cinema(14, weight: .semibold))
                        .foregroundStyle(Theme.red)
                    } else {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focused, equals: .email)
                            .submitLabel(.go)
                            .onSubmit { Task { await start() } }
                            .inputStyle()

                        Button {
                            Task { await start() }
                        } label: {
                            if isWorking { ProgressView().tint(.white) } else { Text(store.usesRealSignIn ? "Email me a code" : "Get started") }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isWorking)

                        Text(store.usesRealSignIn ? "No password needed. We email you a code." : "Demo mode: any email works.")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private func start() async {
        guard store.usesRealSignIn else {
            store.signIn(email: email.trimmingCharacters(in: .whitespaces))
            return
        }
        guard emailIsValid else {
            store.showToast("Enter your email address")
            return
        }
        isWorking = true
        let sent = await store.sendSignInCode(to: email.trimmingCharacters(in: .whitespaces))
        isWorking = false
        if sent {
            codeSent = true
            focused = .code
        }
    }

    private func verify() async {
        isWorking = true
        _ = await store.verifySignInCode(code.trimmingCharacters(in: .whitespaces), email: email.trimmingCharacters(in: .whitespaces))
        isWorking = false
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
