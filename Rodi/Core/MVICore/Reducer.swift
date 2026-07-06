//
//  Reducer.swift
//  Rodi
//
//  Created by Yundal8755 on 7/1/26.
//

import Foundation

protocol Reducer<State, Action> {
    associatedtype State
    associatedtype Action

    func reduce(_ state: inout State, with action: Action) -> Effect<Action>
}
