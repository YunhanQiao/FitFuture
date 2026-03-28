import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var vm: DashboardViewModel

    init(user: User) {
        _vm = StateObject(wrappedValue: DashboardViewModel(user: user))
    }

    var body: some View {
        TabView {
            HomeView(vm: vm)
                .tabItem { Label("Home", systemImage: "house.fill") }

            TimelineView(vm: vm)
                .tabItem { Label("Progress", systemImage: "calendar") }

            CheckInView(vm: vm)
                .tabItem { Label("Check In", systemImage: "camera.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.white)
        .task { await vm.loadData() }
    }
}
