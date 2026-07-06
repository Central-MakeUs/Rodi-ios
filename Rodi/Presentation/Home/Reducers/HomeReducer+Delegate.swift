//
//  HomeReducer+Delegate.swift
//  Rodi
//

import Foundation

extension HomeReducer {
    func reduceDelegateAction(_ action: HomeAction.Delegate, state: inout HomeState) -> Effect<HomeAction> {
        switch action {
        case .none:
            .none
        }
    }
}
