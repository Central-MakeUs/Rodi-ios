//
//  MyPostsState.swift
//  Rodi
//

import Foundation

enum MyPostsTab: Equatable {
    case courses
    case reviews
}

enum MyPostsCourseFilter: CaseIterable, Equatable, Identifiable {
    case all
    case approved
    case pending
    case rejected

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "전체"
        case .approved: "승인"
        case .pending: "검토중"
        case .rejected: "반려"
        }
    }

    var approvalStatus: MyCourseApprovalStatus? {
        switch self {
        case .all: nil
        case .approved: .approved
        case .pending: .pending
        case .rejected: .rejected
        }
    }
}

/// 내 활동 화면이 선택한 탭과 child 목록 화면을 조립한다.
struct MyPostsState {
    var selectedTab: MyPostsTab = .courses
    var reviews = MyReviewPostsReducer.State()
    var courses = MyCoursePostsReducer.State()
    var snackbarMessage: String?
    var practiceRecordsRefreshRequestID = 0
    var pendingEditReviewID: Int?
}
