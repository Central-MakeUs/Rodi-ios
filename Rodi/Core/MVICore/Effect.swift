//
//  Effect.swift
//  Rodi
//
//  Created by mac on 7/1/26.
//

import Foundation

struct Effect<Action>: @unchecked Sendable {
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
        case run(TaskPriority? = nil, (_ send: @escaping (Action) async -> Void) async -> Void)
        case cancel
    }

    static var none: Self {
        Self(caseOf: .none)
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
        case .run(let taskPriority, let action):
            Self(caseOf: .run(taskPriority, action), taskID: id)
        case .cancel:
            .none
        }
    }

    func map<MappedAction>(
        _ transform: @escaping @Sendable (Action) -> MappedAction
    ) -> Effect<MappedAction> {
        switch caseOf {
        case .none:
            .none
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
