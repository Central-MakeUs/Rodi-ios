//
//  OnboardingRouter.swift
//  Rodi
//

import Combine
import Foundation

/// 온보딩 화면 전환만 담당한다. 입력 상태, 인증, 제출과 저장 정책은 OnboardingReducer가 소유한다.
@MainActor
final class OnboardingRouter: ObservableObject {
    @Published private(set) var route: OnboardingRoute

    init(initialRoute: OnboardingRoute) {
        route = initialRoute
    }

    func navigate(to route: OnboardingRoute) {
        self.route = route
    }

    @discardableResult
    func goBack() -> OnboardingRoute? {
        guard let previous = route.previous else { return nil }
        route = previous
        return previous
    }
}
