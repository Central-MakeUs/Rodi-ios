import Foundation

protocol ReviewSkipReasonServicing {
    func fetchForm() async throws -> PracticeSkipReasonForm
    func submit(practiceID: Int, reasonCode: String, detail: String?) async throws
}

struct ReviewSkipReasonService: ReviewSkipReasonServicing {
    private let practiceRepository: PracticeRepository

    init(practiceRepository: PracticeRepository) {
        self.practiceRepository = practiceRepository
    }

    func fetchForm() async throws -> PracticeSkipReasonForm {
        try await practiceRepository.fetchSkipReasonForm()
    }

    func submit(practiceID: Int, reasonCode: String, detail: String?) async throws {
        try await practiceRepository.submitSkipReason(
            practiceID: practiceID,
            reasonCode: reasonCode,
            detail: detail
        )
    }
}
