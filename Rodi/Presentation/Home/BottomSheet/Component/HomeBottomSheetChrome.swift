//
//  HomeBottomSheetChrome.swift
//  Rodi
//

import SwiftUI

struct HomeBottomSheetChrome<Content: View>: View {
    @ViewBuilder private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .background(RodiColor.white)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 20,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 20
                )
            )
            .shadow(color: RodiColor.black.opacity(0.08), radius: 4, x: 0, y: -3)
    }
}

struct HomeBottomSheetDragHandle: View {
    let isEnabled: Bool
    let bottomSpacing: CGFloat
    let onChanged: (CGFloat) -> Void
    let onEnded: (CGFloat) -> Void

    init(
        isEnabled: Bool,
        bottomSpacing: CGFloat = 12,
        onChanged: @escaping (CGFloat) -> Void,
        onEnded: @escaping (CGFloat) -> Void
    ) {
        self.isEnabled = isEnabled
        self.bottomSpacing = bottomSpacing
        self.onChanged = onChanged
        self.onEnded = onEnded
    }

    var body: some View {
        Capsule()
            .fill(RodiColor.gray400)
            .frame(width: 60, height: 4)
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 12 + bottomSpacing, alignment: .top)
            .contentShape(Rectangle())
            .overlay {
                BottomSheetPanGestureView(
                    isEnabled: isEnabled,
                    onChanged: onChanged,
                    onEnded: onEnded
                )
            }
    }
}

/// 바텀시트의 제목 영역에 기존 pan 처리만 확장한다.
/// 버튼을 포함하지 않는 제목 전용 영역에만 적용해, close·filter 등의 tap 동작을 가로채지 않는다.
struct HomeBottomSheetTitleDragRegion<Content: View>: View {
    let isEnabled: Bool
    let onChanged: (CGFloat) -> Void
    let onEnded: (CGFloat) -> Void
    @ViewBuilder private let content: () -> Content

    init(
        isEnabled: Bool,
        onChanged: @escaping (CGFloat) -> Void,
        onEnded: @escaping (CGFloat) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isEnabled = isEnabled
        self.onChanged = onChanged
        self.onEnded = onEnded
        self.content = content
    }

    var body: some View {
        content()
            .contentShape(Rectangle())
            .overlay {
                BottomSheetPanGestureView(
                    isEnabled: isEnabled,
                    onChanged: onChanged,
                    onEnded: onEnded
                )
            }
            .accessibilityLabel("바텀 시트 크기 조절")
    }
}
