import Foundation

struct ReviewReportFormResponseDTO: Decodable {
    let questionID: String
    let type: String
    let title: String
    let description: String?
    let required: Bool
    let options: [ReviewReportOptionDTO]

    private enum CodingKeys: String, CodingKey {
        case questionID = "questionId"
        case type
        case title
        case description
        case required
        case options
    }
}

struct ReviewReportOptionDTO: Decodable {
    let code: String
    let label: String
    let order: Int
    let requiresTextInput: Bool
    let textInputPlaceholder: String?
    let textInputMaxLength: Int?
}
