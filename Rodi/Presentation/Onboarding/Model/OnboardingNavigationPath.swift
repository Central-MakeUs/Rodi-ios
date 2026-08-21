/// 복원한 onboarding 세션이 진입할 navigation stack을 결정한다.
/// View는 Coordinator 조립과 화면 렌더링만 맡기고, guest/member 별 route 정책은 Model에 둔다.
enum OnboardingNavigationPath {
    static func restoredPath(
        route: OnboardingRoute?,
        session: OnboardingSession
    ) -> [OnboardingRoute] {
        guard let route else { return [] }

        let memberRoutes: [OnboardingRoute] = [
            .terms,
            .nickname,
            .drivingExperience,
            .optionalDrivingPreference,
            .safety,
            .locationPermission
        ]
        let guestRoutes: [OnboardingRoute] = [.terms, .safety, .locationPermission]
        let routes = session.isGuest ? guestRoutes : memberRoutes

        guard let routeIndex = routes.firstIndex(of: route) else { return [route] }
        return Array(routes[...routeIndex])
    }
}
