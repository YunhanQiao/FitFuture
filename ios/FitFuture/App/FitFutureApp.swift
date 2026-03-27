import SwiftUI

@main
struct FitFutureApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .preferredColorScheme(.none) // Respect system dark/light
        }
    }
}
