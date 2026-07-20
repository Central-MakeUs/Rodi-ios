//
//  HomeRadiusFilterLayer.swift
//  Rodi
//

import SwiftUI

struct HomeRadiusFilterLayer: View {
    let isVisible: Bool
    let selectedFilter: HomeRadiusFilter
    let selectAction: (HomeRadiusFilter) -> Void

    var body: some View {
        if isVisible {
            VStack {
                RadiusFilterControl(
                    selectedFilter: selectedFilter,
                    selectAction: selectAction
                )
                .padding(.top, 24)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            // 반경 필터는 바텀싯의 높이, 드래그, 확장 전환과 독립적으로 유지한다.
            // 시트가 올라와도 같은 위치와 상태로 남도록 시트보다 높은 레이어에 둔다.
            .zIndex(2)
        }
    }
}
