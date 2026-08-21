import Foundation

nonisolated enum ReviewMapper {
    static func detail(
        from dto: ReviewDetailResponseDTO
    ) throws(NetworkError) -> ReviewDetail {
        guard let difficulty = ReviewDifficulty(rawValue: dto.difficulty),
              let congestion = ReviewCongestion(rawValue: dto.congestion),
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
            practiceMethod: practiceMethod,
            content: dto.content ?? "",
            caution: dto.caution,
            isEditable: dto.isEditable,
            isHidden: dto.isHidden,
            isVerifiedVisit: dto.isVerifiedVisit,
            createdAt: dto.createdAt
        )
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
        from dto: ReviewReportFormResponseDTO
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
            difficulty: submission.difficulty.rawValue,
            congestion: submission.congestion.rawValue,
            practiceMethod: submission.practiceMethod.rawValue,
            content: submission.content,
            caution: submission.caution
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
