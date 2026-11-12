import Foundation

struct ReviewWritingFormResponseDTO: Decodable {
    let title: String
    let placeName: String
    let steps: [ReviewWritingFormStepDTO]
}

struct ReviewWritingFormStepDTO: Decodable {
    let order: Int
    let title: String?
    let questions: [ReviewWritingFormQuestionDTO]
}

struct ReviewWritingFormQuestionDTO: Decodable {
    let code: String
    let order: Int
    let type: String
    let required: Bool
    let title: String
    let placeholder: String?
    let maxLength: Int?
    let showWhen: ReviewWritingFormConditionDTO?
    let options: [FormOptionDTO]?
}

struct ReviewWritingFormConditionDTO: Decodable {
    let question: String
    let anyOf: [String]
}
