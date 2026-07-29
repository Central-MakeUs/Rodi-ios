//
//  HomeAdministrativeAreaList.swift
//  Rodi
//

import SwiftUI

struct HomeAdministrativeAreaList: View {
    let areas: [KoreanAdministrativeArea]
    let selectAction: (KoreanAdministrativeArea) -> Void

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(areas) { area in
                Button {
                    selectAction(area)
                } label: {
                    HStack(spacing: 12) {
                        Image("ic_search")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(RodiColor.gray600)
                            .frame(width: 20, height: 20)

                        Text(area.searchDisplayName)
                            .rodiTypography(.body1Medium)
                            .foregroundStyle(RodiColor.gray800)
                            .lineLimit(1)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 61)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(area.searchDisplayName) 지도에서 보기")
            }
        }
    }
}
