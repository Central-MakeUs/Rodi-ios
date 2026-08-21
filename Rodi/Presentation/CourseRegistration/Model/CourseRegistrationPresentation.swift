/// 코스 등록 진입점이 제공해야 하는 화면 상태와 종료 계약입니다.
struct CourseRegistrationPresentation {
    let isTutorialCompleted: Bool
    let close: () -> Void
    let tutorialCompleted: () -> Void
    let registrationCompleted: () -> Void
}
