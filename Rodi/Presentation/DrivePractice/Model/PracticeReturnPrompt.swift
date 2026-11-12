//
//  PracticeReturnPrompt.swift
//  Rodi
//

import Foundation

struct PracticeReturnPrompt: Equatable {
    let placeID: Int
    let placeName: String
    let allowsSkipReason: Bool
    let allowsReviewWriting: Bool
    let visitedSnackbarMessage: String?
}

// 코스 잘 다녀왔는가?
enum PracticeReturnPromptInteraction: Equatable {
    case visited
    case notVisited
    case closed
}
