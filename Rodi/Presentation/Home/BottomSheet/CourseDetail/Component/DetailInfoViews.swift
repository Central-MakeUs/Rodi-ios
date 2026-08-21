//
//  DetailInfoViews.swift
//  Rodi
//

import SwiftUI

struct DetailInfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .rodiTypography(.caption2SemiBold)
                .foregroundStyle(RodiColor.gray900)

            content
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RodiColor.gray50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct DetailInfoRowData: Identifiable {
    let title: String
    let value: String

    var id: String {
        title
    }
}

struct DetailInfoRow: View {
    let row: DetailInfoRowData

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(row.title)
                .rodiTypography(.caption1Medium)
                .foregroundStyle(RodiColor.gray600)
                .frame(width: 68, alignment: .leading)

            Text(row.value)
                .rodiTypography(.caption1Medium)
                .foregroundStyle(RodiColor.gray900)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
