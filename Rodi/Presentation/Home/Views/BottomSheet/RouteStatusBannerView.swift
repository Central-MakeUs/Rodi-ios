//
//  RouteStatusBannerView.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct RouteStatusBannerView: View {
    let message: String

    var body: some View {
        Text(message)
            .rodiTypography(.caption1Medium)
            .foregroundStyle(RodiColor.primary)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RodiColor.primary20)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
