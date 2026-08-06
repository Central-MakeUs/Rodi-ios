//
//  FilterBottomSheetView.swift
//  Rodi
//

import SwiftUI

struct FilterBottomSheetView: View {
    let state: FilterBottomSheetReducer.State
    let send: (FilterBottomSheetReducer.Action) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("필터")
                    .rodiTypography(.headline1)
                Spacer()
                Button(action: { send(.dismiss) }) {
                    Image("ic_close")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("필터 닫기")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)

            HomePracticeFilterView(
                selection: state.draftSelection,
                isApplying: state.isApplying,
                canApply: state.canApply,
                resetAction: { send(.reset) },
                selectCategoryAction: { send(.selectCategory($0)) },
                toggleTypeAction: { send(.toggleType($0)) },
                selectAllAction: { send(.selectAll) },
                applyAction: { send(.apply) }
            )
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}
