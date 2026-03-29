import Foundation

struct Photo: Codable, Identifiable {
    let id: String
    let userId: String
    let type: PhotoType
    let storagePath: String
    var weekNumber: Int?
    var weightKg: Double?
    let takenAt: Date

    enum PhotoType: String, Codable {
        case baseline
        case progress
        case aiGenerated = "ai_generated"
    }
}

struct CheckIn: Codable, Identifiable {
    let id: String
    let userId: String
    let photoId: String
    let weekNumber: Int
    var weightKg: Double?
    let loggedAt: Date
}
