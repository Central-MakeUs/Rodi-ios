//
//  OnboardingWithdrawalDialogState.swift
//  Rodi
//

import Foundation

enum OnboardingWithdrawalDialogState: Equatable {
    case restore(AuthWithdrawalRecovery)
    case rejoinLocked(rejoinAvailableAt: Date?)
}
