//
//  HomeBottomSheetUIState.swift
//  Rodi
//

import Foundation

/// 바텀싯의 표시 단계와 실제 렌더링 높이를 관리한다.
struct HomeBottomSheetUIState {
    var bottomSheetState: HomeBottomSheetState = .medium
    var sheetHeight: CGFloat = 0
}
