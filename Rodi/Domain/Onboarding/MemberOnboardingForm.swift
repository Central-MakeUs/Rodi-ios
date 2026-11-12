import Foundation

/// 회원의 운전 경험·선호 입력 계약과 서버 제공 표시 메타데이터입니다.
nonisolated struct MemberOnboardingForm: Equatable {
    enum Field: String, CaseIterable {
        case drivingPeriod, recentFrequency, roadExperiences, soloDrivingRange, soloParkingLevel
        case practiceTypes, carType, drivingGoal

        var isExperience: Bool {
            switch self {
            case .drivingPeriod, .recentFrequency, .roadExperiences, .soloDrivingRange, .soloParkingLevel: true
            default: false
            }
        }
    }

    enum Kind: String { case single = "SINGLE_SELECT", multiple = "MULTI_SELECT", ranked = "RANKED_SELECT", text = "TEXT" }
    struct Option: Equatable, Identifiable {
        let id: String
        let label: String
        let exclusive: Bool
        let skipsFollowUps: Bool
    }
    struct Condition: Equatable {
        let field: Field
        let anyOf: [String]
    }
    struct Question: Equatable, Identifiable {
        let id: Field
        let kind: Kind
        let required: Bool
        let title: String
        let description: String?
        let placeholder: String?
        let maxSelect: Int?
        let maxLength: Int?
        let condition: Condition?
        let options: [Option]
    }
    struct Step: Equatable {
        let isExperience: Bool
        let title: String?
        let description: String?
        let skippable: Bool
        let questions: [Question]
    }
    let steps: [Step]

    func step(isExperience: Bool) -> Step? { steps.first { $0.isExperience == isExperience } }

    func visibleQuestions(in step: Step, answers: [Field: [String]]) -> [Question] {
        var visible: [Question] = []
        var effectiveAnswers = answers
        for question in step.questions {
            if let condition = question.condition,
               Set(effectiveAnswers[condition.field] ?? []).isDisjoint(with: condition.anyOf) {
                effectiveAnswers[question.id] = nil
                continue
            }
            visible.append(question)
            if question.options.contains(where: { $0.skipsFollowUps && (effectiveAnswers[question.id] ?? []).contains($0.id) }) {
                break
            }
        }
        return visible
    }

    func canProceed(in step: Step, answers: [Field: [String]]) -> Bool {
        visibleQuestions(in: step, answers: answers).allSatisfy { question in
            let values = answers[question.id] ?? []
            if question.kind == .text {
                let text = values.first ?? ""
                return (!question.required || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    && (question.maxLength.map { text.count <= $0 } ?? true)
            }
            return (!question.required || !values.isEmpty)
                && Set(values).count == values.count
                && values.allSatisfy { value in question.options.contains { $0.id == value } }
                && (question.maxSelect.map { values.count <= $0 } ?? true)
                && (question.kind != .single || values.count <= 1)
                && (values.count <= 1 || !question.options.contains { $0.exclusive && values.contains($0.id) })
        }
    }
}
