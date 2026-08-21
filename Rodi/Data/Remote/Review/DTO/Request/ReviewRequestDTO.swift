import Foundation

struct ReviewRequestDTO: Encodable {
    let isRecommended: Bool
    let difficulty: String
    let congestion: String
    let practiceMethod: String
    let content: String?
    let caution: String?

}
