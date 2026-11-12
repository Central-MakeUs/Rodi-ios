import Foundation

struct ReviewDraft: Equatable {
    var isRecommended: Bool?
    var difficulty: ReviewDifficulty?
    var congestion: ReviewCongestion?
    var caution = ""
    var courseIssues: Set<String> = []
    var courseIssueDetail = ""
    var practiceMethod: ReviewPracticeMethod?
    var content = ""

    func issueTextOption(in form: ReviewWritingForm?) -> ReviewWritingForm.Option? {
        guard isRecommended == false else { return nil }
        return form?[.courseIssues]?.options.first { courseIssues.contains($0.code) && $0.requiresTextInput }
    }

    func canProceedToSecondPage(form: ReviewWritingForm?) -> Bool {
        guard let isRecommended else { return false }
        if let form, !isRecommended {
            let allowed = Set(form[.courseIssues]?.options.map(\.code) ?? [])
            guard !courseIssues.isEmpty, courseIssues.isSubset(of: allowed) else { return false }
            if let option = issueTextOption(in: form) {
                guard courseIssueDetail.normalizedOptionalText != nil,
                      courseIssueDetail.count <= min(option.textInputMaxLength ?? 30, 30) else { return false }
            }
            return true
        }
        guard let difficulty, let congestion else { return false }
        if let form {
            guard form[.difficulty]?.options.contains(where: { $0.code == difficulty.rawValue }) == true,
                  form[.congestion]?.options.contains(where: { $0.code == congestion.rawValue }) == true else { return false }
            if let cautionQuestion = form[.caution], cautionQuestion.isVisible(for: isRecommended) {
                if cautionQuestion.required && caution.normalizedOptionalText == nil { return false }
                if let limit = cautionQuestion.maxLength, caution.count > limit { return false }
            }
        }
        return true
    }

    func submission(form: ReviewWritingForm?) -> PlaceReviewSubmission? {
        guard canProceedToSecondPage(form: form), let isRecommended, let practiceMethod else { return nil }
        let contentQuestion = form?[.content]
        let showsContent = form == nil || contentQuestion?.isVisible(for: isRecommended) == true
        if let form {
            guard form[.practiceMethod]?.options.contains(where: { $0.code == practiceMethod.rawValue }) == true else { return nil }
            if showsContent {
                guard content.count <= min(contentQuestion?.maxLength ?? 150, 150),
                      contentQuestion?.required != true || content.normalizedOptionalText != nil else { return nil }
            }
        }
        let reportsCourse = form != nil && !isRecommended
        let showsCaution = form == nil || form?[.caution]?.isVisible(for: isRecommended) == true

        return .init(
            isRecommended: isRecommended,
            difficulty: reportsCourse ? nil : difficulty,
            congestion: reportsCourse ? nil : congestion,
            practiceMethod: practiceMethod,
            content: showsContent ? content.normalizedOptionalText : nil,
            caution: !reportsCourse && showsCaution ? caution.normalizedOptionalText : nil,
            courseIssues: reportsCourse ? form?[.courseIssues]?.options.map(\.code).filter(courseIssues.contains) : nil,
            courseIssueDetail: issueTextOption(in: form) != nil ? courseIssueDetail.normalizedOptionalText : nil
        )
    }
}

extension ReviewDraft {
    init(detail: ReviewDetail) {
        isRecommended = detail.isRecommended
        difficulty = detail.difficulty
        congestion = detail.congestion
        caution = detail.caution ?? ""
        courseIssues = Set(detail.courseIssues ?? [])
        courseIssueDetail = detail.courseIssueDetail ?? ""
        practiceMethod = detail.practiceMethod
        content = detail.content ?? ""
    }
}

extension String {
    var normalizedOptionalText: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
