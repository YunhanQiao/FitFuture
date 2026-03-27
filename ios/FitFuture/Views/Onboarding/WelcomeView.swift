import SwiftUI

struct WelcomeView: View {
    let onSignIn: () -> Void
    @State private var animateLogo = false

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

            Button(action: onSignIn) {
                Label("Continue with Apple", systemImage: "apple.logo")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)

            Text("By continuing you agree to our Terms and Privacy Policy.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 48)
        .onAppear { animateLogo = true }
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
