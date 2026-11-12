import Foundation

struct ReviewWritingForm: Equatable {
    enum Field: String {
        case isRecommended, difficulty, congestion, caution, courseIssues, practiceMethod, content
    }

    struct Option: Equatable, Identifiable {
        let code: String
        let label: String
        let requiresTextInput: Bool
        let textInputPlaceholder: String?
        let textInputMaxLength: Int?

        var id: String { code }
    }

    struct Question: Equatable {
        let title: String
        let required: Bool
        let placeholder: String?
        let maxLength: Int?
        let recommendations: Set<Bool>?
        let options: [Option]

        nonisolated func isVisible(for recommendation: Bool?) -> Bool {
            guard let recommendations else { return true }
            return recommendation.map(recommendations.contains) ?? false
        }
    }

    let title: String
    let placeName: String
    let firstStepTitle: String?
    let questions: [Field: Question]

    subscript(_ field: Field) -> Question? { questions[field] }
}
