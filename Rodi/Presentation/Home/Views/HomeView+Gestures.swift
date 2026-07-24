//
//  HomeView+Gestures.swift
//  Rodi
//

import SwiftUI

extension HomeView {
    var sheetDragGesture: some Gesture {
        DragGesture(
            minimumDistance: 8,
            coordinateSpace: .named(Constants.bottomSheetDragCoordinateSpace)
        )
            .updating($sheetDragTranslation) { value, state, _ in
                state = hasSelectedBottomSheet
                    ? max(value.translation.height, 0)
                    : value.translation.height
            }
            .onEnded { value in
                handleSheetDragEnded(translation: value.translation.height)
            }
    }
}
