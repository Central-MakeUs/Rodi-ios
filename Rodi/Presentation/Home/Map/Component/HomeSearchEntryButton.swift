//
//  HomeSearchEntryButton.swift
//  Rodi
//

import SwiftUI

struct HomeSearchEntryButton: View {
    let selectedSearchResultName: String?
    let action: () -> Void
    let clearSelectedSearchResultAction: () -> Void

    var body: some View {
        Group {
            if let selectedSearchResultName {
                HStack(spacing: 8) {
                    Button(action: clearSelectedSearchResultAction) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(RodiColor.black)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("검색 결과 해제")

                    Button(action: action) {
                        HStack(spacing: 0) {
                            Text(selectedSearchResultName)
                                .font(.pretendard(size: 15, weight: .medium))
                                .tracking(-0.3)
                                .foregroundStyle(RodiColor.black)
                                .lineLimit(1)

                            Spacer(minLength: 0)
                        }
                        .padding(.trailing, 16)
                        .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(selectedSearchResultName) 다시 검색")
                }
                .padding(.leading, 12)
            } else {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Image("ic_search")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(RodiColor.black)
                            .frame(width: 24, height: 24)

                        Text("시/군/구/코스명으로 검색하기")
                            .font(.pretendard(size: 15, weight: .medium))
                            .tracking(-0.3)
                            .foregroundStyle(RodiColor.gray500)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("장소 검색")
            }
        }
        .frame(maxWidth: .infinity, minHeight: 46)
        .modifier(Example(selectedSearchResultName: selectedSearchResultName))
    }
}

struct Example: ViewModifier {

    let selectedSearchResultName: String?

    func body(content: Content) -> some View {
        content
            .background(RodiColor.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(
                color: RodiColor.black.opacity(0.2),
                radius: selectedSearchResultName == nil ? 2 : 4,
                x: 0,
                y: 0
            )
    }
}
