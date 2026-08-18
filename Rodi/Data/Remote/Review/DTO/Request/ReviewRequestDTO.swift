import Foundation

struct ReviewRequestDTO: Encodable {
    let isRecommended: Bool
    let difficulty: String
    let congestion: String
    let practiceMethod: String
    let content: String?
    let caution: String?

    init(_ submission: PlaceReviewSubmission) {
        isRecommended = submission.isRecommended
        difficulty = submission.difficulty.rawValue
        congestion = submission.congestion.rawValue
        practiceMethod = submission.practiceMethod.rawValue
        content = submission.content
        caution = submission.caution
    }
}
