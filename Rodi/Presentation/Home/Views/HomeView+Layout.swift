//
//  HomeView+Layout.swift
//  Rodi
//
//  Created by Codex on 7/4/26.
//

import SwiftUI

extension HomeView {
    var sheetLayout: HomeBottomSheetLayoutPolicy {
        HomeBottomSheetLayoutPolicy(
            containerHeight: containerHeight,
            sheetHeight: homeStore.state.bottomSheet.sheetHeight,
            hasSelectedBottomSheet: hasSelectedBottomSheet,
            showsEmptyRadiusResult: shouldShowEmptyRadiusResult,
            bottomSheetState: homeStore.state.bottomSheet.bottomSheetState,
            sheetHeightRatio: Constants.sheetHeightRatio,
            floatingControlSpacing: Constants.floatingControlSpacing,
            currentLocationButtonSize: Constants.currentLocationButtonSize,
            pageMorphStartRatio: Constants.pageMorphStartRatio,
            pageSnapRatio: Constants.pageSnapRatio
        )
    }

    var mediumSheetHeight: CGFloat {
        sheetLayout.mediumSheetHeight
    }

    var mediumOverlayBottomInset: CGFloat {
        sheetLayout.mediumOverlayBottomInset
    }

    var floatingControlBottomInset: CGFloat {
        sheetLayout.floatingControlBottomInset
    }

    var cameraObscuredBottomInset: CGFloat {
        sheetLayout.cameraObscuredBottomInset
    }

    var hasSelectedBottomSheet: Bool {
        selectedItem != nil
    }

    var hasFixedBottomSheet: Bool {
        sheetLayout.hasFixedBottomSheet
    }

    var mapVisibilityState: RodiMapVisibilityState {
        bottomSheetState == .expanded ? .covered : .interactive
    }

    var shouldShowRadiusFilter: Bool {
        overlayState == nil
            && bottomSheetState == .medium
            && !hasSelectedBottomSheet
            && shouldRenderMap
    }

    var availableSheetHeight: CGFloat {
        sheetLayout.availableSheetHeight
    }

    var renderedSheetHeight: CGFloat {
        sheetLayout.renderedSheetHeight
    }

    var renderedSheetOffset: CGFloat {
        sheetLayout.renderedSheetOffset
    }

    var shouldAllowSheetDrag: Bool {
        sheetLayout.shouldAllowSheetDrag
    }

    var locationButtonOpacity: CGFloat {
        sheetLayout.locationButtonOpacity
    }

    var pageProgress: CGFloat {
        sheetLayout.pageProgress
    }
}
