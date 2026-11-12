import Foundation

/// 서버 폼의 안정적인 코드와 기존 초안·레벨 계산용 답변을 연결합니다.
enum OnboardingFormAnswerAdapter {
    typealias Field = MemberOnboardingForm.Field

    static func values(experience: OnboardingDrivingExperience, preferences: OnboardingDrivingPreferences, goal: String) -> [Field: [String]] {
        [
            .drivingPeriod: experience.licenseDrivingPeriod.map { [$0.memberDrivingPeriod.rawValue] } ?? [],
            .recentFrequency: experience.recentDrivingFrequency.map { [$0.memberRecentFrequency.rawValue] } ?? [],
            .roadExperiences: experience.selectedRoadDrivingExperiences.map { $0.memberRoadExperience.rawValue },
            .soloDrivingRange: experience.soloDrivingRange.map { [$0.memberSoloDrivingRange.rawValue] } ?? [],
            .soloParkingLevel: experience.soloParkingLevel.map { [$0.memberSoloParkingLevel.rawValue] } ?? [],
            .practiceTypes: preferences.selectedPracticeSituations.map { $0.placePracticeType.rawValue },
            .carType: preferences.vehicleType.map { [$0.memberCarType.rawValue] } ?? [],
            .drivingGoal: goal.isEmpty ? [] : [goal]
        ]
    }

    static func apply(_ values: [Field: [String]], experience: inout OnboardingDrivingExperience, preferences: inout OnboardingDrivingPreferences, goal: inout String) {
        experience.licenseDrivingPeriod = LicenseDrivingPeriod.allCases.first { $0.memberDrivingPeriod.rawValue == values[.drivingPeriod]?.first }
        experience.recentDrivingFrequency = RecentDrivingFrequency.allCases.first { $0.memberRecentFrequency.rawValue == values[.recentFrequency]?.first }
        experience.selectedRoadDrivingExperiences = (values[.roadExperiences] ?? []).compactMap { code in RoadDrivingExperience.allCases.first { $0.memberRoadExperience.rawValue == code } }
        experience.soloDrivingRange = SoloDrivingRange.allCases.first { $0.memberSoloDrivingRange.rawValue == values[.soloDrivingRange]?.first }
        experience.soloParkingLevel = SoloParkingLevel.allCases.first { $0.memberSoloParkingLevel.rawValue == values[.soloParkingLevel]?.first }
        preferences.selectedPracticeSituations = (values[.practiceTypes] ?? []).compactMap { code in PracticeSituation.allCases.first { $0.placePracticeType.rawValue == code } }
        preferences.vehicleType = VehicleType.allCases.first { $0.memberCarType.rawValue == values[.carType]?.first }
        goal = values[.drivingGoal]?.first ?? ""
    }

    static func sanitized(_ answers: [Field: [String]], form: MemberOnboardingForm) -> [Field: [String]] {
        var result = answers
        let fields = Set(form.steps.flatMap(\.questions).map(\.id))
        result = result.filter { fields.contains($0.key) }
        for question in form.steps.flatMap(\.questions) {
            if question.kind == .text {
                if let limit = question.maxLength, let text = result[question.id]?.first { result[question.id] = [String(text.prefix(limit))] }
            } else {
                var values = (result[question.id] ?? []).filter { value in question.options.contains { $0.id == value } }
                if question.kind == .single { values = Array(values.prefix(1)) }
                if let limit = question.maxSelect { values = Array(values.prefix(limit)) }
                if values.count > 1, let exclusive = question.options.first(where: { $0.exclusive && values.contains($0.id) }) { values = [exclusive.id] }
                result[question.id] = values
            }
        }
        for step in form.steps {
            let visible = Set(form.visibleQuestions(in: step, answers: result).map(\.id))
            for question in step.questions where !visible.contains(question.id) {
                result[question.id] = nil
            }
        }
        return result
    }
}
