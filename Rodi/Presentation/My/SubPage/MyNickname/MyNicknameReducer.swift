import Foundation

@MainActor
struct MyNicknameReducer: Reducer {
    struct State {
        let initialNickname: String
        var nickname: String
        var isSaving = false
        var isActive = true
        var requestID = 0
        var errorMessage: String?
        var updatedNickname: String?

        init(nickname: String) {
            initialNickname = MemberNicknamePolicy.normalized(nickname)
            self.nickname = String(initialNickname.prefix(MemberNicknamePolicy.maximumLength))
        }

        var canSave: Bool {
            isActive && !isSaving && updatedNickname == nil
                && nickname != initialNickname && MemberNicknamePolicy.isValid(nickname)
        }
    }

    enum Action {
        case appeared
        case nicknameChanged(String)
        case saveTapped
        case saveCompleted(Result<String, NetworkError>, requestID: Int)
        case disappeared
    }

    private enum EffectID { case save }
    private let memberRepository: MemberRepository

    init(memberRepository: MemberRepository) {
        self.memberRepository = memberRepository
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .appeared:
            state.isActive = true

        case .nicknameChanged(let nickname):
            guard !state.isSaving, state.isActive else { return .none }
            state.nickname = String(MemberNicknamePolicy.normalized(nickname).prefix(MemberNicknamePolicy.maximumLength))
            state.errorMessage = nil

        case .saveTapped:
            guard state.canSave else { return .none }
            state.isSaving = true
            state.errorMessage = nil
            state.requestID += 1
            let requestID = state.requestID
            let nickname = state.nickname
            let repository = memberRepository
            return .run { send in
                let result: Result<String, NetworkError>
                do {
                    result = .success(try await repository.updateNickname(nickname))
                } catch let error as NetworkError {
                    result = .failure(error)
                } catch {
                    result = .failure(Task.isCancelled ? .cancel : .unknown(errorCode: "nickname_update"))
                }
                guard !Task.isCancelled else { return }
                await send(.saveCompleted(result, requestID: requestID))
            }
            .cancelTask(id: EffectID.save)

        case .saveCompleted(let result, let requestID):
            guard state.isActive, state.isSaving, state.requestID == requestID else { return .none }
            state.isSaving = false
            switch result {
            case .success(let nickname):
                state.updatedNickname = nickname
            case .failure(.cancel):
                break
            case .failure(.apiError(_, let message, _)):
                state.errorMessage = message
            case .failure(.networkUnavailable), .failure(.timeOut):
                state.errorMessage = "네트워크 연결을 확인해주세요."
            case .failure:
                state.errorMessage = "닉네임을 수정하지 못했어요. 잠시 후 다시 시도해주세요."
            }

        case .disappeared:
            state.isActive = false
            state.isSaving = false
            state.requestID += 1
            return .cancel(id: EffectID.save)
        }
        return .none
    }
}
