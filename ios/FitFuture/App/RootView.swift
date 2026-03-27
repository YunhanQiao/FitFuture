import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            switch authViewModel.authState {
            case .unauthenticated:
                OnboardingFlowView()
            case .authenticated:
                DashboardView()
            case .loading:
                SplashView()
            }
        }
        .animation(.easeInOut, value: authViewModel.authState)
    }
}
