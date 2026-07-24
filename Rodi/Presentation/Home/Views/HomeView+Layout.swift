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
            dragTranslation: sheetDragTranslation,
            settlingSheetHeight: settlingSheetHeight,
            hasSelectedBottomSheet: hasSelectedBottomSheet,
            usesCompactSelectedDetail: selectedPlaceDetail?.type == .course && !isPlaceDetailLoading,
            selectedSheetContentHeight: selectedSheetContentHeight,
            bottomSheetState: homeStore.state.bottomSheet.bottomSheetState,
            sheetHeightRatio: Constants.sheetHeightRatio,
            floatingControlSpacing: Constants.floatingControlSpacing,
            currentLocationButtonSize: Constants.currentLocationButtonSize,
            pageMorphStartRatio: Constants.pageMorphStartRatio,
            expandedSheetSnapRatio: Constants.expandedSheetSnapRatio,
            collapsedSheetSnapRatio: Constants.collapsedSheetSnapRatio,
            bottomTabBarHeight: Constants.bottomTabBarHeight
        )
    }

    var mediumSheetHeight: CGFloat {
        sheetLayout.mediumSheetHeight
    }

    var mediumOverlayBottomInset: CGFloat {
        sheetLayout.mediumOverlayBottomInset
    }

    var floatingControlBottomInset: CGFloat {
        let bottomInset = sheetLayout.floatingControlBottomInset
        guard hasFixedBottomSheet else { return bottomInset }

        return max(
            Constants.bottomTabBarHeight + Constants.floatingControlSpacing,
            bottomInset - selectedDetailDismissOffset
        )
    }

    var cameraObscuredBottomInset: CGFloat {
        if bottomSheetState == .collapsed {
            return Constants.bottomTabBarHeight
        }

        if shouldAllowSheetDrag {
            return mediumSheetHeight
        }

        return hasFixedBottomSheet ? sheetLayout.fixedSheetHeight : sheetLayout.currentSheetHeight
    }

    var hasSelectedBottomSheet: Bool {
        selectedItem != nil
    }

    var hasFixedBottomSheet: Bool {
        sheetLayout.hasFixedBottomSheet
    }

    var usesContentSizedSelectedDetail: Bool {
        selectedPlaceDetail?.type == .course && !isPlaceDetailLoading
    }

    var isBottomSheetPresented: Bool {
        bottomSheetState != .collapsed
    }

    var mapVisibilityState: RodiMapVisibilityState {
        bottomSheetState == .expanded ? .covered : .interactive
    }

    var shouldShowPlaceResearchButton: Bool {
        homeStore.state.placeList.needsResearch
            && overlayState == nil
            && shouldRenderMap
            && bottomSheetState != .expanded
            && !hasSelectedBottomSheet
    }

    var availableSheetHeight: CGFloat {
        sheetLayout.availableSheetHeight
    }

    var renderedSheetHeight: CGFloat {
        sheetLayout.renderedSheetHeight
    }

    /// 화면에 실제로 노출된 목록 시트 높이. 내부 ScrollView의 viewport 기준이다.
    var visibleSheetHeight: CGFloat {
        hasFixedBottomSheet ? sheetLayout.fixedSheetHeight : sheetLayout.currentSheetHeight
    }

    var renderedSheetOffset: CGFloat {
        sheetLayout.renderedSheetOffset + selectedDetailDismissOffset
    }

    var shouldAllowSheetDrag: Bool {
        settlingSheetHeight == nil
            && selectedDetailSettlingOffset == nil
            && (sheetLayout.shouldAllowSheetDrag || hasSelectedBottomSheet)
    }

    var selectedDetailDismissOffset: CGFloat {
        guard hasFixedBottomSheet else { return 0 }
        return selectedDetailSettlingOffset ?? max(sheetDragTranslation, 0)
    }

    var selectedDetailDismissOpacity: CGFloat {
        guard hasFixedBottomSheet else { return 1 }
        let distance = max(sheetLayout.fixedSheetHeight, 1)
        return 1 - min(selectedDetailDismissOffset / distance, 1)
    }

    var locationButtonOpacity: CGFloat {
        sheetLayout.locationButtonOpacity
    }

    var bottomTabBarOpacity: CGFloat {
        sheetLayout.bottomTabBarOpacity
    }

    var bottomTabBarOffset: CGFloat {
        sheetLayout.bottomTabBarOffset
    }

    var bottomSheetOpacity: CGFloat {
        sheetLayout.bottomSheetOpacity * selectedDetailDismissOpacity
    }

    var pageProgress: CGFloat {
        sheetLayout.pageProgress
    }
}
