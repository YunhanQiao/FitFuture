import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var vm = OnboardingViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch vm.currentStep {
            case .welcome:
                WelcomeView { authViewModel.signInWithApple() }
            case .photoCapture:
                PhotoCaptureView(vm: vm)
            case .stats:
                StatsEntryView(vm: vm)
            case .goalSelection:
                GoalSelectionView(vm: vm)
            case .aiGeneration:
                AIGenerationView(vm: vm)
            case .reveal:
                if case .complete(let url) = vm.aiJobViewModel.revealState,
                   let baselineData = vm.capturedImageData {
                    RevealView(
                        baselineImageData: baselineData,
                        futureSelfURL: url,
                        onContinue: { vm.advance() }
                    )
                }
            case .schedule:
                ScheduleView(vm: vm)
            }
        }
        .environmentObject(vm)
    }
}
