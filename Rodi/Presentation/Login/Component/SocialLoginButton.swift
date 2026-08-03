//
//  SocialLoginButton.swift
//  Rodi
//
//  Created by mac on 7/27/26.
//

import SwiftUI

struct SocialLoginButton: View {
    let title: String
    let assetName: String
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
                
                Text(title)
                    .font(.pretendard(size: 15, weight: .semibold))
                    .tracking(-0.3)
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
