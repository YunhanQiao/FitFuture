import SwiftUI

struct HomeView: View {
    @ObservedObject var vm: DashboardViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Greeting
                    if let name = vm.user.displayName {
                        Text("Hi, \(name)!")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                    }

                    // Hero — Future Self card
                    if let url = vm.futureSelfURL {
                        FutureSelfCardView(imageURL: url, streakWeeks: vm.currentStreakWeeks)
                    } else {
                        PlaceholderFutureSelfCard()
                    }

                    // Streak + countdown row
                    HStack(spacing: 16) {
                        StatCard(title: "Streak", value: "\(vm.currentStreakWeeks)w", icon: "flame.fill", color: .orange)
                        StatCard(title: "Days Left", value: "\(vm.daysRemainingToGoal)", icon: "clock.fill", color: .blue)
                    }
                    .padding(.horizontal, 16)

                    // Latest check-in
                    if let latest = vm.checkIns.last {
                        LatestCheckInCard(checkIn: latest)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color.black)
            .navigationTitle("FitFuture")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

private struct FutureSelfCardView: View {
    let imageURL: URL
    let streakWeeks: Int

    var body: some View {
        AsyncImage(url: imageURL) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Color.gray.opacity(0.2)
        }
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Future Self")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Keep going — you're \(streakWeeks) weeks in")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(20)
            .background(LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom))
        }
        .padding(.horizontal, 16)
    }
}

private struct PlaceholderFutureSelfCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.white.opacity(0.05))
            .frame(height: 320)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.3))
                    Text("Complete onboarding to see\nyour Future Self")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 16)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.title2.bold()).foregroundStyle(.white)
                Text(title).font(.caption).foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding()
        .background(.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct LatestCheckInCard: View {
    let checkIn: CheckIn

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Week \(checkIn.weekNumber) Check-In").font(.headline).foregroundStyle(.white)
                if let w = checkIn.weightKg {
                    Text("\(w, specifier: "%.1f") kg").font(.subheadline).foregroundStyle(.white.opacity(0.6))
                }
            }
            Spacer()
            Text(checkIn.loggedAt, style: .date).font(.caption).foregroundStyle(.white.opacity(0.4))
        }
        .padding()
        .background(.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }
}
