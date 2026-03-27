import Foundation

struct AIJob: Codable, Identifiable {
    let id: String
    let userId: String
    let baselinePhotoId: String
    var status: JobStatus
    var resultPhotoURL: URL?
    var errorMessage: String?
    let createdAt: Date
    var updatedAt: Date

    enum JobStatus: String, Codable {
        case queued
        case processing
        case completed
        case failed
    }
}
