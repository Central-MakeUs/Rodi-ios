import Foundation

struct ReviewDraft: Equatable {
    var isRecommended: Bool?
    var difficulty: ReviewDifficulty?
    var congestion: ReviewCongestion?
    var caution = ""
    var practiceMethod: ReviewPracticeMethod?
    var content = ""

    func canProceedToSecondPage() -> Bool {
        isRecommended != nil
            && difficulty != nil
            && congestion != nil
    }

    func submission() -> PlaceReviewSubmission? {
        guard let isRecommended,
              let difficulty,
              let congestion,
              let practiceMethod
        else {
            return nil
        }

        return .init(
            isRecommended: isRecommended,
            difficulty: difficulty,
            congestion: congestion,
            practiceMethod: practiceMethod,
            content: content.normalizedOptionalText,
            caution: caution.normalizedOptionalText
        )
    }
}

extension ReviewDraft {
    init(detail: ReviewDetail) {
        isRecommended = detail.isRecommended
        difficulty = detail.difficulty
        congestion = detail.congestion
        caution = detail.caution ?? ""
        practiceMethod = detail.practiceMethod
        content = detail.content ?? ""
    }
}

extension String {
    var normalizedOptionalText: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
