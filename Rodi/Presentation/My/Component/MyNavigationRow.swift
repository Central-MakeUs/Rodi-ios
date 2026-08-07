//
//  MyNavigationRow.swift
//  Rodi
//

import SwiftUI

struct MyNavigationRow: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .rodiTypography(.body1Medium)
                .foregroundStyle(RodiColor.black)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(RodiColor.gray700)
                .frame(width: 20, height: 20)
        }
        .frame(height: 45)
        .contentShape(Rectangle())
    }
}

struct MyPlainRow: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .rodiTypography(.body1Medium)
                .foregroundStyle(RodiColor.black)
            Spacer()
        }
        .frame(height: 45)
        .contentShape(Rectangle())
    }
}
