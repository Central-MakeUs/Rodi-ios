import Foundation

struct MemberOnboardingFormResponseDTO: Decodable {
    let steps: [MemberOnboardingFormStepDTO]
}

struct MemberOnboardingFormStepDTO: Decodable {
    let order: Int
    let title: String?
    // Dev의 공유 폼 schema에서 빠진 속성은 누락 상태를 보존합니다.
    let skippable: Bool?
    let description: String?
    let questions: [MemberOnboardingFormQuestionDTO]
}

struct MemberOnboardingFormQuestionDTO: Decodable {
    let code: String
    let order: Int
    let type: String
    let required: Bool
    let title: String
    let description: String?
    let placeholder: String?
    let maxSelect: Int?
    let maxLength: Int?
    let showWhen: MemberOnboardingFormConditionDTO?
    let options: [MemberOnboardingFormOptionDTO]?
}

struct MemberOnboardingFormOptionDTO: Decodable {
    let code: String
    let label: String
    let order: Int
    let exclusive: Bool?
    let skipsFollowUps: Bool?
    let requiresTextInput: Bool?
    let textInputPlaceholder: String?
    let textInputMaxLength: Int?
}

struct MemberOnboardingFormConditionDTO: Decodable {
    let question: String
    let anyOf: [String]
}
