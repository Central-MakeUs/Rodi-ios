//
//  HomeSearchTextField.swift
//  Rodi
//

import SwiftUI

struct HomeSearchTextField: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let backAction: () -> Void
    let submitAction: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: backAction) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(RodiColor.black)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("검색 닫기")

            TextField("시/군/구/코스명으로 검색하기", text: $text)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit(submitAction)
                .font(.pretendard(size: 15, weight: .medium))
                .tracking(-0.3)
                .foregroundStyle(RodiColor.black)
                .tint(RodiColor.black)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
        .background(RodiColor.gray200)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
