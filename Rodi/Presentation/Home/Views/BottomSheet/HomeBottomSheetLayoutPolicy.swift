//
//  HomeBottomSheetLayoutPolicy.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

/// 홈 바텀싯 높이와 지도 위 플로팅 컨트롤 위치를 한 곳에서 계산하는 정책 객체.
/// 화면마다 동일한 높이 기준을 쓰게 해서 지도 카메라 보정, 버튼 위치, 페이지 전환 진행도가 서로 어긋나지 않도록 한다.
struct HomeBottomSheetLayoutPolicy {
    let containerHeight: CGFloat
    let sheetHeight: CGFloat
    let hasSelectedBottomSheet: Bool
    let showsEmptyRadiusResult: Bool
    let bottomSheetState: HomeBottomSheetState
    let sheetHeightRatio: CGFloat
    let floatingControlSpacing: CGFloat
    let currentLocationButtonSize: CGFloat
    let pageMorphStartRatio: CGFloat
    let pageSnapRatio: CGFloat

    /// 기본 상태의 바텀싯 높이. 현재 홈 화면은 기기 높이의 비율로 고정한다.
    var mediumSheetHeight: CGFloat {
        baseHeight * sheetHeightRatio
    }

    /// 기본 바텀싯 위에 떠야 하는 내 위치/설정 버튼의 하단 여백.
    var mediumOverlayBottomInset: CGFloat {
        mediumSheetHeight + floatingControlSpacing
    }

    /// 선택 상세 또는 빈 반경 결과처럼 드래그가 잠긴 바텀싯 위 플로팅 컨트롤 여백.
    var selectedOverlayBottomInset: CGFloat {
        fixedSheetHeight + floatingControlSpacing
    }

    var floatingControlBottomInset: CGFloat {
        hasFixedBottomSheet ? selectedOverlayBottomInset : mediumOverlayBottomInset
    }

    /// 지도 카메라가 가려진 영역을 피하도록 넘겨주는 하단 가림 높이.
    var cameraObscuredBottomInset: CGFloat {
        hasFixedBottomSheet ? fixedSheetHeight : currentSheetHeight
    }

    /// 선택 상세와 빈 반경 결과는 사용자가 위로 끌어올릴 수 없는 고정 바텀싯이다.
    var hasFixedBottomSheet: Bool {
        hasSelectedBottomSheet || showsEmptyRadiusResult
    }

    /// 고정 바텀싯 높이. 작은 화면에서도 사용 가능한 높이를 넘지 않게 제한한다.
    var fixedSheetHeight: CGFloat {
        min(mediumSheetHeight, availableSheetHeight)
    }

    /// 바텀싯이 최대로 차지할 수 있는 높이.
    var availableSheetHeight: CGFloat {
        max(containerHeight, mediumSheetHeight)
    }

    /// 실제 렌더링에 사용할 바텀싯 높이.
    var renderedSheetHeight: CGFloat {
        hasFixedBottomSheet ? fixedSheetHeight : availableSheetHeight
    }

    /// 확장 가능한 바텀싯은 offset으로 높이 변화를 표현하고, 고정 바텀싯은 offset을 주지 않는다.
    var renderedSheetOffset: CGFloat {
        hasFixedBottomSheet ? 0 : sheetOffset
    }

    /// 현재는 기본 목록 바텀싯만 드래그를 허용한다.
    var shouldAllowSheetDrag: Bool {
        bottomSheetState == .medium && !hasFixedBottomSheet
    }

    /// 드래그 중인 현재 바텀싯 높이.
    var currentSheetHeight: CGFloat {
        clamp(sheetHeight, lowerBound: mediumSheetHeight, upperBound: availableSheetHeight)
    }

    /// 전체 높이에서 현재 높이를 뺀 만큼 아래로 내려 바텀싯을 표현한다.
    var sheetOffset: CGFloat {
        availableSheetHeight - currentSheetHeight
    }

    /// 플로팅 컨트롤 opacity와 확장 페이지 전환에 사용할 바텀싯 확장 진행도.
    var sheetExpansionProgress: CGFloat {
        guard availableSheetHeight > mediumSheetHeight else {
            return bottomSheetState == .expanded ? 1 : 0
        }

        let progress = (currentSheetHeight - mediumSheetHeight) / (availableSheetHeight - mediumSheetHeight)
        return clamp(progress, lowerBound: 0, upperBound: 1)
    }

    /// 바텀싯이 올라와 컨트롤을 덮기 시작하면 자연스럽게 사라지도록 만드는 opacity.
    var locationButtonOpacity: CGFloat {
        guard !hasFixedBottomSheet else { return 1 }

        let overlap = currentSheetHeight - mediumOverlayBottomInset
        return 1 - clamp(overlap / currentLocationButtonSize, lowerBound: 0, upperBound: 1)
    }

    /// 바텀싯이 전체 페이지처럼 보이기 시작하는 구간의 진행도.
    var pageProgress: CGFloat {
        guard availableSheetHeight > mediumSheetHeight else {
            return bottomSheetState == .expanded ? 1 : 0
        }

        let morphStartHeight = availableSheetHeight * pageMorphStartRatio
        let progress = (currentSheetHeight - morphStartHeight) / (availableSheetHeight - morphStartHeight)
        return clamp(progress, lowerBound: 0, upperBound: 1)
    }

    /// 드래그 translation을 바텀싯 높이로 변환한다.
    func height(forDragTranslation translation: CGFloat) -> CGFloat {
        clamp(
            mediumSheetHeight - translation,
            lowerBound: mediumSheetHeight,
            upperBound: availableSheetHeight
        )
    }

    /// 예측 드래그 위치가 기준을 넘으면 확장 페이지로 스냅한다.
    func shouldExpandAfterDrag(predictedTranslation: CGFloat) -> Bool {
        let predictedHeight = height(forDragTranslation: predictedTranslation)
        return predictedHeight / availableSheetHeight >= pageSnapRatio || predictedTranslation < -80
    }

    private var baseHeight: CGFloat {
        containerHeight > 0 ? containerHeight : UIScreen.main.bounds.height
    }

    private func clamp(_ value: CGFloat, lowerBound: CGFloat, upperBound: CGFloat) -> CGFloat {
        min(max(value, lowerBound), upperBound)
    }
}
