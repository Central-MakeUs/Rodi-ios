//
//  HomeSearchRegionList.swift
//  Rodi
//

import SwiftUI

struct HomeSearchRegionList: View {
    let regions: [String]
    let selectAction: (String) -> Void

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(regions, id: \.self) { region in
                Button {
                    selectAction(region)
                } label: {
                    HStack(spacing: 12) {
                        Image("ic_search")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(RodiColor.gray600)
                            .frame(width: 20, height: 20)

                        Text(HomeSearchDisplayName.region(region))
                            .rodiTypography(.body1Medium)
                            .foregroundStyle(RodiColor.gray800)
                            .lineLimit(1)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(HomeSearchDisplayName.region(region)) 검색")

                Divider()
                    .overlay(RodiColor.primaryMinus100)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
