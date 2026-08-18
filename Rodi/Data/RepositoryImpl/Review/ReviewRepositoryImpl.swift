import Foundation

final class ReviewRepositoryImpl: ReviewRepository {
    private let remoteDataSource: ReviewRemoteDataSource

    init(remoteDataSource: ReviewRemoteDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func create(placeID: Int, submission: PlaceReviewSubmission) async throws(NetworkError) {
        try await remoteDataSource.create(placeID: placeID, submission: submission)
    }

    func fetchDetail(reviewID: Int) async throws(NetworkError) -> ReviewDetail {
        try detail(from: await remoteDataSource.fetchDetail(reviewID: reviewID))
    }

    func update(reviewID: Int, submission: PlaceReviewSubmission) async throws(NetworkError) {
        try await remoteDataSource.update(reviewID: reviewID, submission: submission)
    }

    func fetchSummary(
        placeID: Int,
        level: ReviewLevelFilter
    ) async throws(NetworkError) -> PlaceReviewSummary {
        try summary(from: await remoteDataSource.fetchSummary(placeID: placeID, level: level))
    }

    func fetchReviews(
        placeID: Int,
        query: PlaceReviewQuery
    ) async throws(NetworkError) -> PlaceReviewPage {
        try page(from: await remoteDataSource.fetchReviews(placeID: placeID, query: query))
    }

    func fetchMyReviews(query: MyReviewQuery) async throws(NetworkError) -> MyReviewPage {
        try myReviewPage(from: await remoteDataSource.fetchMyReviews(query: query))
    }

    func delete(reviewID: Int) async throws(NetworkError) {
        try await remoteDataSource.delete(reviewID: reviewID)
    }

    func fetchReportForm() async throws(NetworkError) -> ReviewReportForm {
        let response = try await remoteDataSource.fetchReportForm()
        return .init(
            title: response.title,
            description: response.description,
            options: response.options
                .sorted { $0.order < $1.order }
                .map(reportOption(from:))
        )
    }

    func report(reviewID: Int, submission: ReviewReportSubmission) async throws(NetworkError) {
        try await remoteDataSource.report(reviewID: reviewID, submission: submission)
    }
}

private extension ReviewRepositoryImpl {

    func detail(from dto: ReviewDetailResponseDTO) throws(NetworkError) -> ReviewDetail {
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

    func reportOption(from dto: ReviewReportOptionDTO) -> ReviewReportOption {
        .init(
            code: dto.code,
            label: dto.label,
            order: dto.order,
            requiresTextInput: dto.requiresTextInput,
            textInputPlaceholder: dto.textInputPlaceholder,
            textInputMaxLength: dto.textInputMaxLength
        )
    }
    func summary(from dto: ReviewSummaryResponseDTO) throws(NetworkError) -> PlaceReviewSummary {
        let difficultyCounts = try dictionary(
            dto.difficultyCounts,
            key: ReviewDifficulty.init(rawValue:)
        )
        let levelCounts = try dictionary(
            dto.levelCounts,
            key: ReviewLevel.init(rawValue:)
        )

        let topDifficulty: ReviewDifficulty?
        if let topDifficultyDTO = dto.topDifficulty {
            let rawValue = topDifficultyDTO.difficulty
            guard let difficulty = ReviewDifficulty(rawValue: rawValue) else {
                throw NetworkError.decodingFail
            }
            topDifficulty = difficulty
        } else {
            topDifficulty = nil
        }

        let topDifficultyCount: Int
        if let topDifficultyDTO = dto.topDifficulty {
            topDifficultyCount = try int(from: topDifficultyDTO.count)
        } else {
            topDifficultyCount = 0
        }

        return PlaceReviewSummary(
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

    func page(from dto: ReviewCursorPageResponseDTO) throws(NetworkError) -> PlaceReviewPage {
        PlaceReviewPage(
            items: try dto.items.map(item(from:)),
            hasNext: dto.hasNext,
            nextCursor: dto.nextCursor,
            totalCount: try dto.totalCount.map(int(from:))
        )
    }

    func item(from dto: ReviewItemResponseDTO) throws(NetworkError) -> PlaceReviewItem {
        guard let practiceMethod = ReviewPracticeMethod(rawValue: dto.practiceMethod) else {
            throw .decodingFail
        }

        return PlaceReviewItem(
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

    func myReviewPage(from dto: MyReviewCursorPageResponseDTO) throws(NetworkError) -> MyReviewPage {
        .init(
            items: try dto.items.map(myReviewItem(from:)),
            hasNext: dto.hasNext,
            nextCursor: dto.nextCursor,
            totalCount: try dto.totalCount.map(int(from:))
        )
    }

    func myReviewItem(from dto: MyReviewItemResponseDTO) throws(NetworkError) -> MyReviewItem {
        guard let createdAt = Self.date(from: dto.createdAt) else {
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

    func dictionary<Key: Hashable>(
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

    func resolvedReviewLevel(from rawValue: String?) throws(NetworkError) -> ReviewLevel? {
        guard let rawValue else { return nil }
        guard rawValue == "ALL" || ReviewLevel(rawValue: rawValue) != nil else {
            throw .decodingFail
        }
        return ReviewLevel(rawValue: rawValue)
    }

    func int(from value: Int64) throws(NetworkError) -> Int {
        guard let value = Int(exactly: value) else {
            throw .decodingFail
        }
        return value
    }

    static let iso8601DateFormatter = ISO8601DateFormatter()

    static let fractionalISO8601DateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func date(from value: String) -> Date? {
        fractionalISO8601DateFormatter.date(from: value)
            ?? iso8601DateFormatter.date(from: value)
            ?? dateWithoutTimeZone(from: value)
    }

    static func dateWithoutTimeZone(from value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        for format in [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss"
        ] {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                return date
            }
        }

        return nil
    }
}
