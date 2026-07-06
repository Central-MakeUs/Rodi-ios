//
//  CourseListView.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct CourseListView: View {
    let items: [RodiCourseItem]
    let selectAction: (RodiCourseItem) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    CourseCard(item: item) {
                        selectAction(item)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}
