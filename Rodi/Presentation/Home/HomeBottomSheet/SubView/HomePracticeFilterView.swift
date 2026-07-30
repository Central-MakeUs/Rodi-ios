//
//  HomePracticeFilterView.swift
//  Rodi
//

import SwiftUI

struct HomePracticeFilterView: View {
    let selection: HomePracticeFilterSelection
    let isApplying: Bool
    let canApply: Bool
    let resetAction: () -> Void
    let selectCategoryAction: (HomePracticeCategory) -> Void
    let toggleTypeAction: (PlacePracticeType) -> Void
    let selectAllAction: () -> Void
    let applyAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    filterSection(title: "카테고리") {
                        RodiChipFlow {
                            ForEach(HomePracticeCategory.allCases, id: \.self) { category in
                                RodiSelectionChip(
                                    title: category.title,
                                    isSelected: selection.category == category,
                                    action: { selectCategoryAction(category) }
                                )
                            }
                        }
                    }

                    if selection.showsPracticeTypeOptions {
                        filterSection(title: "연습유형") {
                            RodiChipFlow {
                                ForEach(selection.category.options) { option in
                                    RodiSelectionChip(
                                        title: option.title,
                                        isSelected: selection.selectedTypes.contains(option.type),
                                        action: { toggleTypeAction(option.type) }
                                    )
                                }

                                RodiSelectionChip(
                                    title: "전체",
                                    isSelected: selection.isAllSelected,
                                    action: selectAllAction
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .disabled(isApplying)

            DualBottomButton(
                secondaryTitle: "초기화",
                primaryTitle: isApplying ? "적용 중" : "결과보기",
                isPrimaryEnabled: canApply,
                secondaryAction: resetAction,
                primaryAction: applyAction
            )
        }
    }

    private func filterSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .rodiTypography(.body1SemiBold)
                .foregroundStyle(RodiColor.black)

            content()
        }
    }
}
