import SwiftUI

struct AIGenerationView: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            pulseCircles

            statusText

            Spacer()

            footerText
        }
        .padding(.vertical, 48)
        .background(Color.black.ignoresSafeArea())
        .onAppear { pulseScale = 1.1 }
        .onChange(of: vm.aiJobViewModel.revealState) { _, state in
            if case .complete = state { vm.advance() }
        }
    }

    private var pulseCircles: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                let size = CGFloat(120 + i * 60)
                let opacity = 0.15 - Double(i) * 0.04
                let delay = Double(i) * 0.2
                Circle()
                    .stroke(.white.opacity(opacity), lineWidth: 1)
                    .frame(width: size, height: size)
                    .scaleEffect(pulseScale)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(delay),
                        value: pulseScale
                    )
            }

            Image(systemName: "sparkles")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundStyle(.white)
        }
    }

    private var statusText: some View {
        VStack(spacing: 12) {
            Text("Generating Your Future Self")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text(vm.aiJobViewModel.progressMessage)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var footerText: some View {
        Text("This takes 20–30 seconds.\nYou'll get a notification when it's ready.")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.4))
            .multilineTextAlignment(.center)
    }
}
