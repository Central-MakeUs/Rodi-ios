//
//  CheckIcon.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct CheckIcon: View {
    let isActive: Bool

    var body: some View {
        Image(isActive ? "ic_check_active" : "ic_check_inactive")
            .resizable()
            .frame(width: 24, height: 24)
            .accessibilityHidden(true)
    }
}
