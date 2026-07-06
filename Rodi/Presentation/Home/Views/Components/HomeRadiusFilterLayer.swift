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
            .zIndex(2.4)
        }
    }
}
