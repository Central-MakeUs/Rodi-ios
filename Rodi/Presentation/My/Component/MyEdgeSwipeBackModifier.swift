//
//  MyEdgeSwipeBackModifier.swift
//  Rodi
//

import SwiftUI

/// 시스템 interactive-pop이 커스텀 헤더 환경에서 취소될 때를 위한 edge-swipe 보조 처리입니다.
private struct MyEdgeSwipeBackModifier: ViewModifier {
    let route: MyRoute
    @ObservedObject var router: MyRouter

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 12)
                .onEnded { value in
                    guard value.startLocation.x <= 24,
                          value.translation.width >= 80,
                          abs(value.translation.height) <= 80,
                          router.isTopRoute(route)
                    else {
                        return
                    }

                    router.pop()
                }
        )
    }
}

extension View {
    func myEdgeSwipeBack(route: MyRoute, router: MyRouter) -> some View {
        modifier(MyEdgeSwipeBackModifier(route: route, router: router))
    }
}
