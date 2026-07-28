//
//  MyRouter.swift
//  Rodi
//

import Combine
import SwiftUI

enum MyRoute: Hashable {
    case settings
    case drivingGoal
    case savedPlaces
    case permissions
    case terms
    case licenses
    case accountManagement
    case contact
    case legalDocument(LegalDocument)
}

@MainActor
final class MyRouter: ObservableObject {
    @Published private var path: [MyRoute] = []

    var pathBinding: Binding<[MyRoute]> {
        Binding(
            get: { self.path },
            set: { self.replacePath(with: $0) }
        )
    }

    var isDetailPresented: Bool {
        !path.isEmpty
    }

    func isTopRoute(_ route: MyRoute) -> Bool {
        path.last == route
    }

    func push(_ route: MyRoute) {
        path.append(route)
    }

    /// 시스템 edge-swipe pop을 포함한 NavigationStack의 경로 변경을 한 곳에서 반영합니다.
    func replacePath(with path: [MyRoute]) {
        self.path = path
    }

    func popToRoot() {
        path.removeAll()
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
