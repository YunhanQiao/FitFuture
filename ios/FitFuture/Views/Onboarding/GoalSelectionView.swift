import SwiftUI

struct GoalSelectionView: View {
    @ObservedObject var vm: OnboardingViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Set Your Goal")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Your AI transformation will be tailored to this.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top, 60)

                // Goal type
                VStack(alignment: .leading, spacing: 12) {
                    Text("GOAL TYPE").font(.caption.bold()).foregroundStyle(.white.opacity(0.5))
                    ForEach(User.GoalType.allCases, id: \.self) { goal in
                        Button {
                            vm.selectedGoal = goal
                        } label: {
                            HStack {
                                Text(goal.displayName)
                                    .font(.body)
                                    .foregroundStyle(.white)
                                Spacer()
                                if vm.selectedGoal == goal {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding()
                            .background(vm.selectedGoal == goal ? .white.opacity(0.15) : .white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                // Timeline
                VStack(alignment: .leading, spacing: 12) {
                    Text("TIMELINE").font(.caption.bold()).foregroundStyle(.white.opacity(0.5))
                    HStack(spacing: 12) {
                        ForEach([3, 6, 12], id: \.self) { months in
                            Button {
                                vm.goalMonths = months
                            } label: {
                                Text("\(months)mo")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(vm.goalMonths == months ? .white.opacity(0.2) : .white.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }

                // Training days
                VStack(alignment: .leading, spacing: 12) {
                    Text("TRAINING DAYS / WEEK").font(.caption.bold()).foregroundStyle(.white.opacity(0.5))
                    Stepper("\(vm.trainingDays) days", value: $vm.trainingDays, in: 1...7)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    if case .authenticated(let user) = authViewModel.authState {
                        Task { await vm.startAIGeneration(user: user) }
                        vm.advance()
                    }
                } label: {
                    Text("Generate My Future Self")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.bottom, 48)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.black.ignoresSafeArea())
    }
}
