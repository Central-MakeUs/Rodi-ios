//
//  HomeBottomSheetLayer.swift
//  Rodi
//

import SwiftUI

struct HomeBottomSheetLayer<Drag: Gesture>: View {
    let content: CourseBottomSheetContentState
    let actions: CourseBottomSheetActions
    let height: CGFloat
    let offsetY: CGFloat
    let opacity: CGFloat
    let dragGesture: Drag
    let shouldAllowDrag: Bool

    var body: some View {
        CourseBottomSheet(
            content: content,
            actions: actions
        )
        .frame(height: height)
        .offset(y: offsetY)
        .opacity(opacity)
        .gesture(dragGesture, including: shouldAllowDrag ? .all : .none)
        .zIndex(1)
    }
}
