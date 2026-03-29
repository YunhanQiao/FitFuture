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
    @Published var savedUser: User?

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
        guard let photoId = uploadedBaselinePhotoId else {
            aiJobViewModel.revealState = .failed("No baseline photo found. Please go back and upload a photo.")
            return
        }

        do {
            let updatedUser = try await APIService.shared.updateProfile(
                userId: user.id,
                heightCm: Double(height),
                weightKg: Double(weight),
                bodyFatPercent: Double(bodyFat),
                goalType: selectedGoal.rawValue,
                goalMonths: goalMonths,
                trainingDaysPerWeek: trainingDays
            )
            savedUser = updatedUser
            await aiJobViewModel.startGeneration(user: updatedUser, baselinePhotoId: photoId)
        } catch {
            aiJobViewModel.revealState = .failed("Failed to save profile: \(error.localizedDescription)")
        }
    }
}
