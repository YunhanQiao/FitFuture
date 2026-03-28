import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    let onSignIn: (Result<ASAuthorization, Error>) -> Void
    let onDevLogin: () -> Void
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var animateLogo = false
    @State private var showEmailAuth = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.white)
                    .scaleEffect(animateLogo ? 1.0 : 0.7)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateLogo)

                Text("FitFuture")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("See your transformation\nbefore it happens.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            VStack(spacing: 16) {
                FeaturePillView(icon: "camera.viewfinder", text: "AI-powered body transformation")
                FeaturePillView(icon: "chart.line.uptrend.xyaxis", text: "Track your real progress weekly")
                FeaturePillView(icon: "bell.badge", text: "Stay motivated with streaks")
            }

            Spacer()

            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                onSignIn(result)
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 24)

            Button {
                showEmailAuth = true
            } label: {
                Text("Continue with Email")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)

            #if DEBUG
            Button("Dev Login (Skip)") { onDevLogin() }
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.4))
            #endif

            Text("By continuing you agree to our Terms and Privacy Policy.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 48)
        .onAppear { animateLogo = true }
        .sheet(isPresented: $showEmailAuth) {
            ZStack {
                Color.black.ignoresSafeArea()
                EmailAuthView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

struct EmailAuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(isLogin ? "Welcome Back" : "Create Account")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            VStack(spacing: 16) {
                if !isLogin {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        TextField("Your name", text: $displayName)
                            .textContentType(.name)
                            .autocorrectionDisabled()
                            .padding()
                            .background(.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    TextField("you@example.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding()
                        .background(.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    SecureField(isLogin ? "Enter your password" : "At least 8 characters", text: $password)
                        .textContentType(isLogin ? .password : .newPassword)
                        .padding()
                        .background(.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 24)

            Button {
                isLoading = true
                if isLogin {
                    authViewModel.login(email: email, password: password)
                } else {
                    authViewModel.register(email: email, password: password, displayName: displayName)
                }
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.black)
                    } else {
                        Text(isLogin ? "Sign In" : "Create Account")
                            .font(.headline)
                            .foregroundStyle(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(email.isEmpty || password.isEmpty || (!isLogin && displayName.isEmpty) || isLoading)
            .padding(.horizontal, 24)

            Button(isLogin ? "Don't have an account? Sign Up" : "Already have an account? Sign In") {
                isLogin.toggle()
                isLoading = false
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.6))

            Spacer()
        }
        .alert("Error", isPresented: Binding(
            get: { authViewModel.error != nil },
            set: { if !$0 { authViewModel.error = nil } }
        )) {
            Button("OK") { authViewModel.error = nil }
        } message: {
            Text(authViewModel.error ?? "")
        }
        .onChange(of: authViewModel.error) { _ in isLoading = false }
        .onChange(of: authViewModel.authState) { _ in dismiss() }
    }
}

private struct FeaturePillView: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .frame(width: 24)
            Text(text)
                .foregroundStyle(.white.opacity(0.85))
                .font(.subheadline)
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
