//
//  DetailTagStrip.swift
//  Rodi
//

import SwiftUI

struct DetailTagStrip: View {
    let item: RodiCourseItem

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                DifficultyChip(score: item.difficultyScore, title: item.difficultyTitle)

                ForEach(item.tags, id: \.self) { tag in
                    TagChip(title: tag)
                }
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
    }
}
