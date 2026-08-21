//
//  CourseReviewState.swift
//  Rodi
//

import Foundation

enum CourseReviewRoute: Equatable {
    case preview
    case allReviews
    case report
}

struct CourseReviewPageState: Equatable {
    var items: [PlaceReviewItem] = []
    var hasNext = false
    var nextCursor: String?
    var totalCount: Int?
    var isInitialLoading = false
    var isLoadingNextPage = false
    var errorMessage: String?
}

struct CourseReviewSummaryState: Equatable {
    var value: PlaceReviewSummary?
    var isLoading = false
    var errorMessage: String?
}

/// 코스 상세 후기 preview·전체보기·신고 흐름의 단일 렌더링 상태다.
struct CourseReviewState: Equatable {
    var placeID: Int?
    var route: CourseReviewRoute = .preview
    var reportReturnRoute: CourseReviewRoute?
    var selectedLevel: ReviewLevelFilter = .current
    var summaries: [ReviewLevelFilter: CourseReviewSummaryState] = [:]
    var pages: [ReviewLevelFilter: CourseReviewPageState] = [:]
    var requestRevision = UUID()
    var reportedReviewIDs: Set<Int> = []
    var blockedMemberIDs: Set<Int> = []
    var report = CourseReviewReportReducer.State()
    var block = CourseReviewBlockReducer.State()
    var deleteTargetReviewID: Int?
    var isDeleting = false
    var deleteErrorMessage: String?
}
