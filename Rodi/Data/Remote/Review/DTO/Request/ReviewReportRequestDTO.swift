import Foundation

struct ReviewReportRequestDTO: Encodable {
    let reason: String
    let detail: String?

    init(_ submission: ReviewReportSubmission) {
        reason = submission.reasonCode
        detail = submission.detail
    }
}
