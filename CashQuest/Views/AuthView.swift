import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var auth: AuthService
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, Color(red: 0.08, green: 0.09, blue: 0.18)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.gold)
                        .padding(.top, 60)
                    Text("Welcome to CashQuest")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text("Play. Earn. Cash out.")
                        .foregroundStyle(.secondary)

                    VStack(spacing: 12) {
                        if isSignUp {
                            TextField("Name", text: $name)
                                .textContentType(.name)
                                .authFieldStyle()
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .authFieldStyle()
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .authFieldStyle()
                    }
                    .padding(.top, 12)

                    if let error = auth.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Theme.danger)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task {
                            if isSignUp {
                                await auth.signUp(email: email, password: password, name: name)
                            } else {
                                await auth.signIn(email: email, password: password)
                            }
                        }
                    } label: {
                        Group {
                            if auth.isBusy {
                                ProgressView()
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In").bold()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(auth.isBusy || email.isEmpty || password.count < 6)

                    Button(isSignUp ? "Already have an account? Sign in" : "No account? Sign up") {
                        withAnimation(.snappy) { isSignUp.toggle() }
                    }
                    .font(.footnote)
                }
                .padding(24)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private extension View {
    func authFieldStyle() -> some View {
        self
            .padding(14)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
