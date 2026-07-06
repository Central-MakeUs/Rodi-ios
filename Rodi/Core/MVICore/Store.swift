//
//  Store.swift
//  Rodi
//
//  Created by Yundal8755 on 7/1/26.
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
        let effect = reducer.reduce(&state, with: action)
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
