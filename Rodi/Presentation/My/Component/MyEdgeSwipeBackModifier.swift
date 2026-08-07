//
//  MyEdgeSwipeBackModifier.swift
//  Rodi
//

import SwiftUI

/// 시스템 interactive-pop이 커스텀 헤더 환경에서 취소될 때를 위한 edge-swipe 보조 처리입니다.
private struct MyEdgeSwipeBackModifier: ViewModifier {
    let isTopRoute: Bool
    let router: Router<MyRoute>

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 12)
                .onEnded { value in
                    guard value.startLocation.x <= 24,
                          value.translation.width >= 80,
                          abs(value.translation.height) <= 80,
                          isTopRoute
                    else {
                        return
                    }

                    router.pop()
                }
        )
    }
}

extension View {
    func myEdgeSwipeBack(isTopRoute: Bool, router: Router<MyRoute>) -> some View {
        modifier(MyEdgeSwipeBackModifier(isTopRoute: isTopRoute, router: router))
    }
}
