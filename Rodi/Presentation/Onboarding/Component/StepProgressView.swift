//
//  StepProgressView.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct StepProgressView: View {
    let activeCount: Int
    let totalCount: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<totalCount, id: \.self) { index in
                Capsule()
                    .fill(index < activeCount ? RodiColor.primary : RodiColor.gray300)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 32)
    }
}
