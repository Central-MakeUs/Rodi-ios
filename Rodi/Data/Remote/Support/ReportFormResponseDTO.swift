import Foundation

struct ReportFormResponseDTO: Decodable {
    let questionID: String
    let type: String
    let title: String
    let description: String?
    let required: Bool
    let options: [FormOptionDTO]

    private enum CodingKeys: String, CodingKey {
        case questionID = "questionId"
        case type
        case title
        case description
        case required
        case options
    }
}

struct FormOptionDTO: Decodable {
    let code: String
    let label: String
    let order: Int
    let requiresTextInput: Bool
    let textInputPlaceholder: String?
    let textInputMaxLength: Int?
}
