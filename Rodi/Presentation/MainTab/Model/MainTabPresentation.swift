//
//  MainTabPresentation.swift
//  Rodi
//

import Foundation

/// Root가 MainTab에 전달하는 화면 전환·후기 갱신 계약입니다.
///
/// App의 route 상태를 개별 callback으로 흩어 전달하지 않고, MainTab이 필요한
/// Presentation 입력을 하나의 읽기 전용 값으로 묶습니다.
struct MainTabPresentation {
    let consumePendingAuthenticationIntent: () -> MainTabIntent?
    let requestLogin: (MainTabIntent?) -> Void
    let onLogoutCompleted: () -> Void
    let navigationRequestID: Int
    let homeTabSelectionRequestID: Int
    let homeReviewFlowFinishedRequestID: Int
    let myPracticeRecordsReviewFlowFinishedRequestID: Int
    let myPostsReviewFlowFinishedRequestID: Int
    let onReviewTestRequested: () -> Void
    let onReviewRequested: (ReviewFlowRequest) -> Void
    let courseDetailReviewPresentation: CourseDetailReviewPresentation
    let isCourseTutorialCompleted: Bool
    let onCourseTutorialCompleted: () -> Void
}
