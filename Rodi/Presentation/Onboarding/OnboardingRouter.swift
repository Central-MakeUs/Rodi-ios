//
//  OnboardingRouter.swift
//  Rodi
//

import Combine
import SwiftUI

enum OnboardingRoute: Int, Hashable {
    case terms
    case nickname
    case drivingExperience
    case optionalDrivingPreference
    case safety
    case locationPermission
}

@MainActor
final class OnboardingRouter: ObservableObject {
    @Published private(set) var path: [OnboardingRoute]

    init(initialPath: [OnboardingRoute] = []) {
        path = initialPath
    }

    var pathBinding: Binding<[OnboardingRoute]> {
        Binding(
            get: { self.path },
            set: { self.replacePath(with: $0) }
        )
    }

    var currentRoute: OnboardingRoute? {
        path.last
    }

    func push(_ route: OnboardingRoute) {
        guard currentRoute != route else { return }
        path.append(route)
    }

    func reset(to route: OnboardingRoute? = nil) {
        path = route.map { [$0] } ?? []
    }

    func pop() {
        guard path.count > 1 else { return }
        path.removeLast()
    }

    /// 시스템 edge-swipe까지 Router의 뒤로가기 정책으로 일관되게 처리한다.
    func replacePath(with path: [OnboardingRoute]) {
        guard !self.path.isEmpty else {
            self.path = path
            return
        }

        // 약관은 로그인 root로 돌아가지 않는 온보딩의 첫 단계다.
        guard !(self.path == [.terms] && path.isEmpty) else { return }
        self.path = path
    }
}
