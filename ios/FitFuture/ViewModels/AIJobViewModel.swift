import Foundation
import Combine

enum RevealState: Equatable {
    case idle
    case uploading
    case queued
    case processing
    case complete(URL)
    case failed(String)
}

@MainActor
final class AIJobViewModel: ObservableObject {
    @Published var revealState: RevealState = .idle
    @Published var progressMessage: String = "Preparing your transformation..."

    private var pollingTask: Task<Void, Never>?
    private let pollInterval: TimeInterval = 3.0
    private let maxPollAttempts = 60 // 3 min max

    func startGeneration(user: User, baselinePhotoId: String) async {
        guard let goalType = user.goalType?.rawValue,
              let goalMonths = user.goalMonths,
              let trainingDays = user.trainingDaysPerWeek else {
            revealState = .failed("Please complete your profile before generating.")
            return
        }

        revealState = .queued
        progressMessage = "Queuing your AI transformation..."

        do {
            let job = try await APIService.shared.createAIJob(
                userId: user.id,
                baselinePhotoId: baselinePhotoId,
                goalType: goalType,
                goalMonths: goalMonths,
                trainingDays: trainingDays
            )
            startPolling(jobId: job.id)
        } catch {
            revealState = .failed(error.localizedDescription)
        }
    }

    private func startPolling(jobId: String) {
        pollingTask?.cancel()
        pollingTask = Task {
            var attempts = 0
            while !Task.isCancelled && attempts < maxPollAttempts {
                try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
                attempts += 1

                do {
                    let job = try await APIService.shared.pollAIJob(jobId: jobId)
                    await handleJobUpdate(job)
                    if case .complete = revealState { return }
                    if case .failed = revealState { return }
                } catch {
                    // Continue polling on transient errors
                }
            }
            if attempts >= maxPollAttempts {
                revealState = .failed("Generation is taking longer than expected. We'll notify you when it's ready.")
            }
        }
    }

    func handlePushNotification(jobId: String) {
        Task {
            do {
                let job = try await APIService.shared.pollAIJob(jobId: jobId)
                await handleJobUpdate(job)
            } catch {}
        }
    }

    private func handleJobUpdate(_ job: AIJob) {
        switch job.status {
        case .queued:
            revealState = .queued
            progressMessage = "In queue — your transformation is next..."
        case .processing:
            revealState = .processing
            progressMessage = "AI is sculpting your Future Self..."
        case .completed:
            pollingTask?.cancel()
            if let url = job.resultPhotoURL {
                revealState = .complete(url)
            } else {
                revealState = .failed("Result unavailable. Please try again.")
            }
        case .failed:
            pollingTask?.cancel()
            revealState = .failed(job.errorMessage ?? "Generation failed. Please try again.")
        }
    }

    deinit {
        pollingTask?.cancel()
    }
}
