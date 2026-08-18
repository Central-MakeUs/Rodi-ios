import Foundation

struct PracticeSkipReasonRequestDTO: Encodable {
    let reason: String
    let detail: String?

    init(reasonCode: String, detail: String?) {
        reason = reasonCode
        self.detail = detail
    }
}
