//
//  LoginWithdrawalDialogState.swift
//  Rodi
//

import Foundation

enum LoginWithdrawalDialogState: Equatable {
    case restore(AuthWithdrawalRecovery)
    case rejoinLocked(rejoinAvailableAt: Date?)
}
