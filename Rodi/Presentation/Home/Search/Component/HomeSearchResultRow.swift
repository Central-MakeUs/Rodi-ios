//
//  HomeSearchResultRow.swift
//  Rodi
//

import SwiftUI

struct HomeSearchResultRow: View {
    let item: PlaceListItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image("ic_map_pin")
                    .resizable()
                    .frame(width: 20, height: 20)

                Text(item.name)
                    .rodiTypography(.body1Medium)
                    .foregroundStyle(RodiColor.gray800)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 61, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.name) 상세 보기")
    }
}
