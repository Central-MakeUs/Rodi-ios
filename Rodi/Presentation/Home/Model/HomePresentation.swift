import Foundation

/// MainTab이 Home에 전달하는 외부 화면 입력과 상위 flow delegate 처리기입니다.
struct HomePresentation {
    let isHomeTabSelected: Bool
    let listPresentationRequestID: Int
    let placeSelectionRequest: HomePlaceSelectionRequest?
    let reviewFlowFinishedRequestID: Int
    let courseDetailReviewPresentation: CourseDetailReviewPresentation
    let bottomTabBarVisibilityChanged: (Bool) -> Void
    let placeSelectionHandled: (Int) -> Void
    let handleDelegate: (HomeReducer.Delegate) -> Void

}
