//
//  HomeBottomSheetLayer.swift
//  Rodi
//

import SwiftUI

struct HomeBottomSheetLayer<Drag: Gesture>: View {
    let content: CourseBottomSheetContentState
    let actions: CourseBottomSheetActions
    let height: CGFloat
    let usesIntrinsicHeight: Bool
    let offsetY: CGFloat
    let opacity: CGFloat
    let dragGesture: Drag
    let shouldAllowDrag: Bool
    let contentHeightAction: (CGFloat) -> Void

    var body: some View {
        Group {
            if usesIntrinsicHeight {
                CourseBottomSheet(
                    content: content,
                    actions: actions,
                    dragGesture: dragGesture,
                    shouldAllowDrag: shouldAllowDrag
                )
                .fixedSize(horizontal: false, vertical: true)
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: HomeBottomSheetContentHeightPreferenceKey.self,
                            value: proxy.size.height
                        )
                    }
                }
                .onPreferenceChange(HomeBottomSheetContentHeightPreferenceKey.self, perform: contentHeightAction)
                // 레이어는 화면 크기를 쓰고, 실제 시트만 하단에서 고유 높이로 렌더링한다.
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            } else {
                CourseBottomSheet(
                    content: content,
                    actions: actions,
                    dragGesture: dragGesture,
                    shouldAllowDrag: shouldAllowDrag
                )
                .frame(height: height)
            }
        }
        // NavigationStack의 safe area가 아니라 실제 화면 하단을 시트 정렬 기준으로 사용한다.
        .ignoresSafeArea(edges: .bottom)
        .offset(y: offsetY)
        .opacity(opacity)
        .zIndex(1)
    }
}

private struct HomeBottomSheetContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
