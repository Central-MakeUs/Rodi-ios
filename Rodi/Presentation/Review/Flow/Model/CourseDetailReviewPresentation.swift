//
//  CourseDetailReviewPresentation.swift
//  Rodi
//

import Foundation

/// 코스 상세가 후기 작성 flow를 표시하는 데 필요한 읽기 전용 계약이다.
struct CourseDetailReviewPresentation {
    let state: ReviewReducer.State
    let snackbarMessage: String?
    let isPresented: Bool
    let send: (ReviewReducer.Action) -> Void
}
