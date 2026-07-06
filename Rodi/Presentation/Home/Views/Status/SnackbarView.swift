//
//  SnackbarView.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct SnackbarView: View {
    let message: String

    var body: some View {
        Text(message)
            .rodiTypography(.body3Medium)
            .foregroundStyle(RodiColor.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(RodiColor.black.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
