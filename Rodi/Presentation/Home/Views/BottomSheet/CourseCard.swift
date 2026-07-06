//
//  CourseCard.swift
//  Rodi
//

import SwiftUI

struct CourseCard: View {
    let item: RodiCourseItem
    let selectAction: () -> Void

    @State private var isAddressExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)
                    .lineLimit(1)

                ExpandableAddressMetaRow(item: item, isExpanded: $isAddressExpanded)

                HStack(spacing: 4) {
                    DifficultyChip(score: item.difficultyScore, title: item.difficultyTitle)
                    ForEach(item.visibleTags, id: \.self) { tag in
                        TagChip(title: tag)
                    }
                }
            }

            Text(item.summary)
                .rodiTypography(.caption1Regular)
                .foregroundStyle(RodiColor.gray700)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 37)
                .background(RodiColor.gray50)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Rectangle()
                .fill(RodiColor.gray100)
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(perform: selectAction)
    }
}
