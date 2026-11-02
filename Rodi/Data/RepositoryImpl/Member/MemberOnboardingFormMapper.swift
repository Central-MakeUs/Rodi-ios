import Foundation

nonisolated enum MemberOnboardingFormMapper {
    static func map(_ dto: MemberOnboardingFormResponseDTO) throws(NetworkError) -> MemberOnboardingForm {
        typealias Form = MemberOnboardingForm
        var seen = Set<Form.Field>()
        let steps: [Form.Step] = try dto.steps.sorted { $0.order < $1.order }.map { (step) throws(NetworkError) -> Form.Step in
            guard let skippable = step.skippable, !step.questions.isEmpty else { throw NetworkError.decodingFail }
            let questions: [Form.Question] = try step.questions.sorted { $0.order < $1.order }.map { (question) throws(NetworkError) -> Form.Question in
                guard let field = Form.Field(rawValue: question.code), seen.insert(field).inserted,
                      let kind = Form.Kind(rawValue: question.type), kind == expectedKind(field) else { throw NetworkError.decodingFail }
                if let limit = question.maxLength, limit < 1 { throw NetworkError.decodingFail }
                if let limit = question.maxSelect, limit < 1 { throw NetworkError.decodingFail }
                if field == .practiceTypes {
                    guard let limit = question.maxSelect, (1...3).contains(limit) else { throw NetworkError.decodingFail }
                }
                if field == .drivingGoal {
                    guard let limit = question.maxLength, (1...30).contains(limit) else { throw NetworkError.decodingFail }
                }
                let options: [Form.Option] = try (question.options ?? []).sorted { $0.order < $1.order }.map { (option) throws(NetworkError) -> Form.Option in
                    guard allowedCodes(field).contains(option.code), option.requiresTextInput != true else { throw NetworkError.decodingFail }
                    return .init(id: option.code, label: option.label, exclusive: option.exclusive == true, skipsFollowUps: option.skipsFollowUps == true)
                }
                guard kind == .text || !options.isEmpty,
                      Set(options.map(\.id)).count == options.count else { throw NetworkError.decodingFail }
                let condition: Form.Condition?
                if let source = question.showWhen {
                    guard let field = Form.Field(rawValue: source.question), !source.anyOf.isEmpty else { throw NetworkError.decodingFail }
                    condition = .init(field: field, anyOf: source.anyOf)
                } else { condition = nil }
                return .init(id: field, kind: kind, required: question.required, title: question.title,
                             description: question.description, placeholder: question.placeholder,
                             maxSelect: question.maxSelect, maxLength: question.maxLength, condition: condition, options: options)
            }
            let experience = questions[0].id.isExperience
            guard questions.allSatisfy({ $0.id.isExperience == experience }) else { throw NetworkError.decodingFail }
            return .init(isExperience: experience, title: step.title, description: step.description, skippable: skippable, questions: questions)
        }
        guard steps.count == 2, Set(steps.map(\.isExperience)).count == 2,
              let period = steps.flatMap(\.questions).first(where: { $0.id == .drivingPeriod }), period.required else { throw NetworkError.decodingFail }
        guard steps[0].isExperience, steps[0].questions.first?.id == .drivingPeriod,
              period.condition == nil, !steps[0].skippable else { throw NetworkError.decodingFail }
        let allQuestions = steps.flatMap(\.questions)
        for question in allQuestions {
            if let condition = question.condition {
                guard let source = allQuestions.first(where: { $0.id == condition.field }),
                      source.id != question.id,
                      condition.anyOf.allSatisfy({ value in source.options.contains { $0.id == value } }),
                      let sourceIndex = allQuestions.firstIndex(where: { $0.id == source.id }),
                      let index = allQuestions.firstIndex(where: { $0.id == question.id }), sourceIndex < index else { throw NetworkError.decodingFail }
            }
        }
        return .init(steps: steps)
    }

    private static func expectedKind(_ field: MemberOnboardingForm.Field) -> MemberOnboardingForm.Kind {
        switch field {
        case .roadExperiences: .multiple
        case .practiceTypes: .ranked
        case .drivingGoal: .text
        default: .single
        }
    }

    private static func allowedCodes(_ field: MemberOnboardingForm.Field) -> Set<String> {
        switch field {
        case .drivingPeriod: ["UNDER_1_MONTH", "MONTHS_1_2", "MONTHS_3_5", "MONTHS_6_11", "YEARS_1_2", "YEARS_3_9", "OVER_10_YEARS"]
        case .recentFrequency: ["RARELY", "MONTHLY_1_2", "WEEKLY_1", "WEEKLY_2_3", "WEEKLY_4_PLUS"]
        case .roadExperiences: ["NONE", "ACCOMPANIED", "PROFESSIONAL_TRAINING", "SOLO"]
        case .soloDrivingRange: ["NEAR_HOME", "FAMILIAR_ROAD", "UNFAMILIAR_ROAD", "HIGHWAY_LONG"]
        case .soloParkingLevel: ["NONE", "WIDE_ONLY", "FAMILIAR_PLACE", "MOSTLY_POSSIBLE"]
        case .practiceTypes: ["U_TURN", "LEFT_RIGHT_TURN", "PARKING", "LANE_CHANGE", "INTERSECTION", "ROUNDABOUT", "UNPROTECTED_LEFT_TURN", "HIGHWAY_ENTRY", "CORNERING", "NARROW_ROAD", "MULTILANE", "MERGING", "STRAIGHT"]
        case .carType: ["LIGHT", "COMPACT", "MIDSIZE", "SEMI_LARGE", "LARGE", "SUV"]
        case .drivingGoal: []
        }
    }
}
