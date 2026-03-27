import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    var email: String?
    var displayName: String?
    var heightCm: Double?
    var weightKg: Double?
    var bodyFatPercent: Double?
    var goalType: GoalType?
    var goalMonths: Int?
    var trainingDaysPerWeek: Int?
    var checkInDay: Int? // 0=Sunday ... 6=Saturday
    let createdAt: Date

    enum GoalType: String, Codable, CaseIterable {
        case fatLoss = "fat_loss"
        case muscleGain = "muscle_gain"
        case recomposition = "recomposition"

        var displayName: String {
            switch self {
            case .fatLoss: return "Fat Loss"
            case .muscleGain: return "Muscle Gain"
            case .recomposition: return "Body Recomposition"
            }
        }
    }
}
