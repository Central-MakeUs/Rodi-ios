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

enum PracticeReturnPromptInteraction: Equatable {
    case visited
    case notVisited
    case closed
}
