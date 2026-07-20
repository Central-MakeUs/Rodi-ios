//
//  HomeView+Gestures.swift
//  Rodi
//

import SwiftUI

extension HomeView {
    var sheetDragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard bottomSheetState == .medium else { return }
                homeStore.send(.viewAction(.setSheetHeight(sheetLayout.height(forDragTranslation: value.translation.height))))
            }
            .onEnded { value in
                handleSheetDragEnded(predictedTranslation: value.predictedEndTranslation.height)
            }
    }
}
