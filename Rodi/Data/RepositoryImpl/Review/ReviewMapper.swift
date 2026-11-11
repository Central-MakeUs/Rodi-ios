import Foundation

nonisolated enum ReviewMapper {
    static func detail(
        from dto: ReviewDetailResponseDTO
    ) throws(NetworkError) -> ReviewDetail {
        let difficulty = dto.difficulty.flatMap(ReviewDifficulty.init(rawValue:))
        let congestion = dto.congestion.flatMap(ReviewCongestion.init(rawValue:))
        guard (dto.difficulty == nil || difficulty != nil),
              (dto.congestion == nil || congestion != nil),
              (!dto.isRecommended || (difficulty != nil && congestion != nil)),
              let practiceMethod = ReviewPracticeMethod(rawValue: dto.practiceMethod)
        else {
            throw .decodingFail
        }

        return .init(
            reviewID: try int(from: dto.reviewId),
            placeID: try int(from: dto.placeId),
            placeName: dto.placeName,
            isRecommended: dto.isRecommended,
            difficulty: difficulty,
            congestion: congestion,
            courseIssues: dto.courseIssues,
            courseIssueDetail: dto.courseIssueDetail,
            practiceMethod: practiceMethod,
            content: dto.content ?? "",
            caution: dto.caution,
            isEditable: dto.isEditable,
            isHidden: dto.isHidden,
            isVerifiedVisit: dto.isVerifiedVisit,
            createdAt: dto.createdAt
        )
    }

    static func writingForm(from dto: ReviewWritingFormResponseDTO) throws(NetworkError) -> ReviewWritingForm {
        let steps = dto.steps.sorted { $0.order < $1.order }
        guard steps.count == 2 else { throw .decodingFail }
        var questions: [ReviewWritingForm.Field: ReviewWritingForm.Question] = [:]
        for (index, step) in steps.enumerated() {
            for question in step.questions {
                guard let field = ReviewWritingForm.Field(rawValue: question.code),
                      questions[field] == nil else { throw .decodingFail }
                let isSecondPage = field == .practiceMethod || field == .content
                let expectedType = field == .courseIssues ? "MULTI_SELECT" :
                    (field == .caution || field == .content ? "TEXT" : "SINGLE_SELECT")
                guard isSecondPage == (index == 1), question.type == expectedType,
                      question.maxLength.map({ $0 > 0 }) ?? true else { throw .decodingFail }
                let options = (question.options ?? []).sorted { $0.order < $1.order }
                let codes = Set(options.map(\.code))
                guard options.count == codes.count,
                      expectedType == "TEXT" || !codes.isEmpty,
                      options.allSatisfy({ !$0.code.isEmpty && ($0.textInputMaxLength.map { $0 > 0 } ?? true) })
                else { throw .decodingFail }
                switch field {
                case .isRecommended:
                    guard codes == ["true", "false"], question.showWhen == nil else { throw .decodingFail }
                case .difficulty:
                    guard options.count <= 5, codes.allSatisfy({ ReviewDifficulty(rawValue: $0) != nil }) else { throw .decodingFail }
                case .congestion:
                    guard codes.allSatisfy({ ReviewCongestion(rawValue: $0) != nil }) else { throw .decodingFail }
                case .practiceMethod:
                    guard codes.allSatisfy({ ReviewPracticeMethod(rawValue: $0) != nil }) else { throw .decodingFail }
                default:
                    break
                }
                let recommendations: Set<Bool>?
                if let condition = question.showWhen {
                    guard condition.question == "isRecommended", !condition.anyOf.isEmpty,
                          condition.anyOf.allSatisfy({ $0 == "true" || $0 == "false" })
                    else { throw .decodingFail }
                    recommendations = Set(condition.anyOf.map { $0 == "true" })
                } else {
                    recommendations = nil
                }
                questions[field] = .init(
                    title: question.title, required: question.required, placeholder: question.placeholder,
                    maxLength: question.maxLength, recommendations: recommendations,
                    options: options.map {
                        .init(code: $0.code, label: $0.label, requiresTextInput: $0.requiresTextInput,
                              textInputPlaceholder: $0.textInputPlaceholder, textInputMaxLength: $0.textInputMaxLength)
                    }
                )
            }
        }
        guard questions[.isRecommended] != nil,
              questions[.difficulty]?.isVisible(for: true) == true,
              questions[.congestion]?.isVisible(for: true) == true,
              questions[.courseIssues]?.isVisible(for: false) == true,
              questions[.practiceMethod]?.isVisible(for: true) == true,
              questions[.practiceMethod]?.isVisible(for: false) == true
        else { throw .decodingFail }
        return .init(title: dto.title, placeName: dto.placeName, firstStepTitle: steps.first?.title, questions: questions)
    }

    static func summary(
        from dto: ReviewSummaryResponseDTO
    ) throws(NetworkError) -> PlaceReviewSummary {
        let difficultyCounts = try dictionary(dto.difficultyCounts, key: ReviewDifficulty.init(rawValue:))
        let levelCounts = try dictionary(dto.levelCounts, key: ReviewLevel.init(rawValue:))
        let topDifficulty: ReviewDifficulty?
        let topDifficultyCount: Int
        if let topDifficultyDTO = dto.topDifficulty {
            guard let difficulty = ReviewDifficulty(rawValue: topDifficultyDTO.difficulty) else {
                throw NetworkError.decodingFail
            }
            topDifficulty = difficulty
            topDifficultyCount = try int(from: topDifficultyDTO.count)
        } else {
            topDifficulty = nil
            topDifficultyCount = 0
        }

        return .init(
            level: try resolvedReviewLevel(from: dto.level),
            levelReviewCount: try int(from: dto.levelReviewCount),
            totalReviewCount: try int(from: dto.totalReviewCount),
            topDifficulty: topDifficulty,
            topDifficultyCount: topDifficultyCount,
            recommendCount: try int(from: dto.recommendCount),
            notRecommendCount: try int(from: dto.notRecommendCount),
            difficultyCounts: difficultyCounts,
            levelCounts: levelCounts
        )
    }

    static func placeReviewPage(
        from dto: ReviewCursorPageResponseDTO
    ) throws(NetworkError) -> PlaceReviewPage {
        .init(
            items: try dto.items.map(placeReviewItem(from:)),
            hasNext: dto.hasNext,
            nextCursor: dto.nextCursor,
            totalCount: try dto.totalCount.map(int(from:))
        )
    }

    static func myReviewPage(
        from dto: MyReviewCursorPageResponseDTO
    ) throws(NetworkError) -> MyReviewPage {
        .init(
            items: try dto.items.map(myReviewItem(from:)),
            hasNext: dto.hasNext,
            nextCursor: dto.nextCursor,
            totalCount: try dto.totalCount.map(int(from:))
        )
    }

    static func reportForm(
        from dto: ReportFormResponseDTO
    ) -> ReviewReportForm {
        .init(
            title: dto.title,
            description: dto.description,
            options: dto.options
                .sorted { $0.order < $1.order }
                .map {
                    .init(
                        code: $0.code,
                        label: $0.label,
                        order: $0.order,
                        requiresTextInput: $0.requiresTextInput,
                        textInputPlaceholder: $0.textInputPlaceholder,
                        textInputMaxLength: $0.textInputMaxLength
                    )
                }
        )
    }

    private static func placeReviewItem(
        from dto: ReviewItemResponseDTO
    ) throws(NetworkError) -> PlaceReviewItem {
        guard let practiceMethod = ReviewPracticeMethod(rawValue: dto.practiceMethod) else {
            throw .decodingFail
        }

        return .init(
            id: try int(from: dto.reviewId),
            memberID: try int(from: dto.memberId),
            nickname: dto.nickname,
            practiceMethod: practiceMethod,
            content: dto.content ?? "",
            isMine: dto.isMine,
            isEditable: dto.isEditable,
            isHidden: dto.isHidden,
            isVerifiedVisit: dto.isVerifiedVisit,
            createdAt: dto.createdAt
        )
    }

    private static func myReviewItem(
        from dto: MyReviewItemResponseDTO
    ) throws(NetworkError) -> MyReviewItem {
        guard let createdAt = ServerDateParser.date(from: dto.createdAt) else {
            throw .decodingFail
        }

        return .init(
            id: try int(from: dto.reviewId),
            placeID: try int(from: dto.placeId),
            placeName: dto.placeName,
            content: dto.content ?? "",
            isEditable: dto.isEditable,
            isHidden: dto.isHidden,
            isVerifiedVisit: dto.isVerifiedVisit,
            createdAt: createdAt
        )
    }

    private static func dictionary<Key: Hashable>(
        _ rawValues: [String: Int64],
        key: (String) -> Key?
    ) throws(NetworkError) -> [Key: Int] {
        var result: [Key: Int] = [:]
        for (rawKey, value) in rawValues {
            guard let resolvedKey = key(rawKey) else {
                throw .decodingFail
            }
            result[resolvedKey] = try int(from: value)
        }
        return result
    }

    private static func resolvedReviewLevel(
        from rawValue: String?
    ) throws(NetworkError) -> ReviewLevel? {
        guard let rawValue else { return nil }
        guard rawValue == "ALL" || ReviewLevel(rawValue: rawValue) != nil else {
            throw .decodingFail
        }
        return ReviewLevel(rawValue: rawValue)
    }

    private static func int(from value: Int64) throws(NetworkError) -> Int {
        guard let value = Int(exactly: value) else {
            throw .decodingFail
        }
        return value
    }

}

nonisolated extension ReviewRequestDTO {
    init(_ submission: PlaceReviewSubmission) {
        self.init(
            isRecommended: submission.isRecommended,
            difficulty: submission.difficulty?.rawValue,
            congestion: submission.congestion?.rawValue,
            practiceMethod: submission.practiceMethod.rawValue,
            content: submission.content,
            caution: submission.caution,
            courseIssues: submission.courseIssues,
            courseIssueDetail: submission.courseIssueDetail
        )
    }
}

nonisolated extension ReviewReportRequestDTO {
    init(_ submission: ReviewReportSubmission) {
        self.init(reason: submission.reasonCode, detail: submission.detail)
    }
}

nonisolated extension ReviewSummaryQueryDTO {
    init(_ filter: ReviewLevelFilter) {
        self.init(level: ReviewMapper.queryValue(from: filter))
    }
}

nonisolated extension PlaceReviewListQueryDTO {
    init(_ query: PlaceReviewQuery) {
        self.init(
            level: ReviewMapper.queryValue(from: query.level),
            size: query.size,
            cursor: query.cursor
        )
    }
}

nonisolated extension MyReviewListQueryDTO {
    init(_ query: MyReviewQuery) {
        self.init(size: query.size, cursor: query.cursor)
    }
}

nonisolated private extension ReviewMapper {
    static func queryValue(from filter: ReviewLevelFilter) -> String? {
        switch filter {
        case .current:
            nil
        case .level(let level):
            level.rawValue
        case .all:
            "ALL"
        }
    }
}
