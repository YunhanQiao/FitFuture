import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            switch authViewModel.authState {
            case .unauthenticated:
                OnboardingFlowView()
            case .authenticated(let user):
                DashboardView(user: user)
                    .id(user.id)
            case .loading:
                SplashView()
            }
        }
        .animation(.easeInOut, value: authViewModel.authState)
    }
}
