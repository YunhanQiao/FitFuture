import Foundation
import AuthenticationServices
import Combine

enum AuthState: Equatable {
    case loading
    case unauthenticated
    case authenticated(User)
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var error: String?

    private let tokenKey = "fitfuture_auth_token"
    private let userKey = "fitfuture_user"

    init() {
        restoreSession()
    }

    private func restoreSession() {
        guard let token = UserDefaults.standard.string(forKey: tokenKey),
              let userData = UserDefaults.standard.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            authState = .unauthenticated
            return
        }
        APIService.shared.setAuthToken(token)
        authState = .authenticated(user)
    }

    func register(email: String, password: String, displayName: String?) {
        Task {
            do {
                let response = try await APIService.shared.register(email: email, password: password, displayName: displayName)
                persist(token: response.token, user: response.user)
                authState = .authenticated(response.user)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func login(email: String, password: String) {
        Task {
            do {
                let response = try await APIService.shared.login(email: email, password: password)
                persist(token: response.token, user: response.user)
                authState = .authenticated(response.user)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let err):
            error = err.localizedDescription
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else {
                error = "Apple sign-in failed: missing credential"
                return
            }
            Task {
                do {
                    print("[Auth] Got Apple token, calling backend...")
                    let response = try await APIService.shared.signInWithApple(identityToken: token)
                    print("[Auth] Backend success, user: \(response.user.id)")
                    persist(token: response.token, user: response.user)
                    authState = .authenticated(response.user)
                } catch {
                    print("[Auth] Error: \(error)")
                    self.error = error.localizedDescription
                }
            }
        }
    }

    #if DEBUG
    func devLogin() {
        Task {
            do {
                let response = try await APIService.shared.devSignIn()
                persist(token: response.token, user: response.user)
                authState = .authenticated(response.user)
            } catch {
                self.error = "Dev login failed: \(error.localizedDescription)"
            }
        }
    }
    #endif

    func signOut() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        authState = .unauthenticated
    }

    private func persist(token: String, user: User) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
        APIService.shared.setAuthToken(token)
    }
}
