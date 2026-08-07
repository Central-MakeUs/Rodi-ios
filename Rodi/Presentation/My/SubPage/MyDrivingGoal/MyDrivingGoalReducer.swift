//
//  MyDrivingGoalReducer.swift
//  Rodi
//

import Foundation

@MainActor
struct MyDrivingGoalReducer: Reducer {
    struct State {
        var drivingGoal: String
        var isSaving = false
        var errorMessage: String?
        var updatedProfile: MemberProfile?

        var canSave: Bool {
            drivingGoal.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
        }
    }

    enum Action {
        case drivingGoalChanged(String)
        case saveTapped
        case saveCompleted(SaveResult)
        case errorDismissed
    }

    enum SaveResult {
        case success(MemberProfile)
        case failure(String)
    }

    private enum EffectID { case save }
    private let memberRepository: MemberRepository

    init(memberRepository: MemberRepository) {
        self.memberRepository = memberRepository
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .drivingGoalChanged(let goal):
            state.drivingGoal = String(goal.prefix(30))

        case .saveTapped:
            guard state.canSave, !state.isSaving else { return .none }
            state.isSaving = true
            state.errorMessage = nil
            let goal = state.drivingGoal.trimmingCharacters(in: .whitespacesAndNewlines)

            return .run { send in
                do {
                    try await memberRepository.updateDrivingGoal(goal)
                    let profile = try await memberRepository.fetchMyProfile()
                    await send(.saveCompleted(.success(profile)))
                } catch {
                    await send(.saveCompleted(.failure("작성해주신 목표가 정상적으로 처리되지 못했어요.\n다시 한번 시도해주세요.")))
                }
            }
            .cancelTask(id: EffectID.save)

        case .saveCompleted(let result):
            state.isSaving = false
            switch result {
            case .success(let profile):
                state.updatedProfile = profile
                RodiAnalytics.track(
                    .drivingGoalSaved(goalLengthBucket: RodiAnalytics.lengthBucket(for: state.drivingGoal))
                )
            case .failure(let message):
                state.errorMessage = message
            }

        case .errorDismissed:
            state.errorMessage = nil
        }

        return .none
    }
}
