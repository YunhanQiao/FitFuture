import SwiftUI

struct ScheduleView: View {
    @ObservedObject var vm: OnboardingViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedWeekday = 1 // Monday
    @State private var notificationsGranted = false

    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Set Check-In Day")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("We'll remind you every week on this day.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.top, 60)

            // Weekday picker
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { i in
                    Button {
                        selectedWeekday = i + 1
                    } label: {
                        Text(weekdays[i])
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedWeekday == i + 1 ? .white.opacity(0.25) : .white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            Spacer()

            VStack(spacing: 16) {
                Button {
                    Task {
                        notificationsGranted = await NotificationService.shared.requestPermission()
                        NotificationService.shared.scheduleWeeklyCheckInReminder(weekday: selectedWeekday)
                        finishOnboarding()
                    }
                } label: {
                    Text("Enable Reminders & Start")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    finishOnboarding()
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.bottom, 48)
        }
        .padding(.horizontal, 24)
        .background(Color.black.ignoresSafeArea())
    }

    private func finishOnboarding() {
        if let updatedUser = vm.savedUser {
            authViewModel.updateUser(updatedUser)
        }
    }
}
