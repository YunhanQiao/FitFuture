import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var checkIns: [CheckIn] = []
    @Published var currentStreakWeeks: Int = 0
    @Published var futureSelfURL: URL?
    @Published var isLoading = false

    private let user: User

    init(user: User) {
        self.user = user
    }

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            checkIns = try await APIService.shared.fetchCheckIns(userId: user.id)
            currentStreakWeeks = calculateStreak()
        } catch {}
    }

    private func calculateStreak() -> Int {
        guard !checkIns.isEmpty else { return 0 }
        let sorted = checkIns.sorted { $0.weekNumber > $1.weekNumber }
        var streak = 0
        var expected = sorted[0].weekNumber
        for checkIn in sorted {
            if checkIn.weekNumber == expected {
                streak += 1
                expected -= 1
            } else {
                break
            }
        }
        return streak
    }

    var daysRemainingToGoal: Int {
        guard let months = user.goalMonths else { return 0 }
        let totalDays = months * 30
        let elapsed = checkIns.count * 7
        return max(0, totalDays - elapsed)
    }
}
