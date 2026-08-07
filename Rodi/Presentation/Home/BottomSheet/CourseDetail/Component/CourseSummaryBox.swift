//
//  CourseSummaryBox.swift
//  Rodi
//

import SwiftUI

struct CourseSummaryBox: View {
    let text: String

    var body: some View {
        Text(text)
            .rodiTypography(.caption1Regular)
            .foregroundStyle(RodiColor.gray800)
            .lineLimit(2)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 37, alignment: .leading)
            .background(RodiColor.gray100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
