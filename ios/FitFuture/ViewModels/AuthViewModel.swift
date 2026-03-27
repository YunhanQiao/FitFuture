import Foundation
import AuthenticationServices
import Combine

enum AuthState: Equatable {
    case loading
    case unauthenticated
    case authenticated(User)
}

@MainActor
final class AuthViewModel: NSObject, ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var error: String?

    private let tokenKey = "fitfuture_auth_token"
    private let userKey = "fitfuture_user"

    override init() {
        super.init()
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

    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }

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

extension AuthViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            self.error = "Apple sign-in failed: missing credential"
            return
        }
        Task {
            do {
                let response = try await APIService.shared.signInWithApple(identityToken: token)
                persist(token: response.token, user: response.user)
                authState = .authenticated(response.user)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.error = error.localizedDescription
    }
}
