//
//  Effect.swift
//  Rodi
//
//  Created by mac on 7/1/26.
//

import Foundation

@MainActor
struct Effect<Action> {
    let caseOf: EffectCase
    let taskID: _CancelID?

    init(caseOf: EffectCase, taskID: AnyHashable? = nil) {
        self.caseOf = caseOf

        if let taskID {
            self.taskID = _CancelID(id: taskID)
        } else {
            self.taskID = nil
        }
    }

    enum EffectCase {
        case none
        case send(Action)
        case run(TaskPriority? = nil, (_ send: @escaping (Action) async -> Void) async -> Void)
        case cancel
    }

    static var none: Self {
        Self(caseOf: .none)
    }

    static func send(_ action: Action) -> Self {
        Self(caseOf: .send(action))
    }

    static func run(
        priority: TaskPriority? = nil,
        task: @escaping (_ send: @escaping (Action) async -> Void) async -> Void
    ) -> Self {
        Self(caseOf: .run(priority, task))
    }

    static func cancel(id: some Hashable) -> Self {
        Self(caseOf: .cancel, taskID: id)
    }

    func cancelTask(id: some Hashable) -> Self {
        switch caseOf {
        case .none:
            .none
        case .send:
            self
        case .run(let taskPriority, let action):
            Self(caseOf: .run(taskPriority, action), taskID: id)
        case .cancel:
            .none
        }
    }

    func map<MappedAction>(
        _ transform: @escaping (Action) -> MappedAction
    ) -> Effect<MappedAction> {
        switch caseOf {
        case .none:
            .none
        case .send(let action):
            Effect<MappedAction>(
                caseOf: .send(transform(action)),
                taskID: taskID?.id
            )
        case .cancel:
            Effect<MappedAction>(caseOf: .cancel, taskID: taskID?.id)
        case .run(let priority, let task):
            Effect<MappedAction>(
                caseOf: .run(priority) { send in
                    await task { action in
                        await send(transform(action))
                    }
                },
                taskID: taskID?.id
            )
        }
    }
}
