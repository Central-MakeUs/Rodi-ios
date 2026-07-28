//
//  Store.swift
//  Rodi
//
//  Created by mac on 7/1/26.
//

import Combine
import Foundation

typealias StoreOf<R: Reducer> = Store<R.State, R.Action>

@MainActor
final class Store<State, Action>: ObservableObject {
    @Published private(set) var state: State

    private let reducer: any Reducer<State, Action>
    private var taskMap: [_CancelID: Task<Void, Never>] = [:]

    init(state: State, reducer: any Reducer<State, Action>) {
        self.state = state
        self.reducer = reducer
    }

    deinit {
        taskMap.values.forEach { $0.cancel() }
    }

    func send(_ action: Action) {
        // @Published 저장 프로퍼티를 inout으로 직접 변경하면 일부 SwiftUI 런타임에서
        // objectWillChange 전달이 누락될 수 있다. Reducer 결과를 재할당해 갱신을 보장한다.
        var nextState = state
        let effect = reducer.reduce(&nextState, with: action)
        state = nextState
        handleEffect(effect)
    }
}

private extension Store {
    func handleEffect(_ effect: Effect<Action>) {
        if case let .run(priority, task) = effect.caseOf {
            let taskToStore = Task(priority: priority) { [weak self] in
                await task { newAction in
                    if Task.isCancelled { return }

                    await MainActor.run {
                        self?.send(newAction)
                    }
                }
            }

            if let taskID = effect.taskID {
                taskMap[taskID]?.cancel()
                taskMap[taskID] = taskToStore
            }
        }

        if case .cancel = effect.caseOf {
            guard let taskID = effect.taskID else { return }

            let matchingKeys = taskMap.keys.filter { $0.id == taskID.id }
            matchingKeys.forEach { key in
                taskMap[key]?.cancel()
                taskMap.removeValue(forKey: key)
            }
        }
    }
}
