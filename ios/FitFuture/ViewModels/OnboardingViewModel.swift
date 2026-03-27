import Foundation
import SwiftUI
import Combine

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case photoCapture
    case stats
    case goalSelection
    case aiGeneration
    case reveal
    case schedule
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var capturedImageData: Data?
    @Published var uploadedBaselinePhotoId: String?
    @Published var height: String = ""
    @Published var weight: String = ""
    @Published var bodyFat: String = ""
    @Published var selectedGoal: User.GoalType = .fatLoss
    @Published var goalMonths: Int = 6
    @Published var trainingDays: Int = 4
    @Published var isUploading = false
    @Published var uploadError: String?

    let aiJobViewModel = AIJobViewModel()

    func advance() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation { currentStep = next }
    }

    func uploadPhotoAndAdvance(user: User) async {
        guard let data = capturedImageData else { return }
        isUploading = true
        defer { isUploading = false }

        do {
            let photo = try await APIService.shared.uploadBaselinePhoto(userId: user.id, imageData: data)
            uploadedBaselinePhotoId = photo.id
            advance()
        } catch {
            uploadError = error.localizedDescription
        }
    }

    func startAIGeneration(user: User) async {
        guard let photoId = uploadedBaselinePhotoId else { return }
        await aiJobViewModel.startGeneration(user: user, baselinePhotoId: photoId)
    }
}
