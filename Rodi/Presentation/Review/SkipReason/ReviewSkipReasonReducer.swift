import Foundation

struct ReviewSkipReasonReducer: Reducer {
    struct State {
        enum FormState: Equatable {
            case idle
            case loading
            case loaded(PracticeSkipReasonForm)
            case failed
        }

        var target: ReviewTarget?
        var formState: FormState = .idle
        var selectedReason: PracticeSkipReasonOption?
        var detail = ""
        var isSubmitting = false
        var isDiscardConfirmationPresented = false
        var isCompletionPresented = false
        var flowID = UUID()
        var requestID = 0

        var detailCharacterLimit: Int {
            selectedReason?.textInputMaxLength ?? 30
        }

        var canSubmit: Bool {
            guard let selectedReason, !isSubmitting else { return false }
            guard selectedReason.requiresTextInput else { return true }
            return !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var hasDraft: Bool {
            selectedReason != nil
                || !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    enum Action {
        case start(ReviewTarget)
        case formLoaded(ReviewRequestResult<PracticeSkipReasonForm>, flowID: UUID, requestID: Int)
        case retryTapped
        case reasonSelected(PracticeSkipReasonOption)
        case detailChanged(String)
        case submitTapped
        case submissionCompleted(ReviewRequestResult<Void>, flowID: UUID, requestID: Int)
        case closeTapped
        case discardConfirmed
        case discardCancelled
        case completionConfirmed
        case reset
        case cancelFormLoading
        case cancelSubmission
        case delegate(Delegate)
    }

    enum Delegate {
        case finished
        case showSnackbar(String)
    }

    private enum EffectID {
        case formLoading
        case submission
    }

    private let service: any ReviewSkipReasonServicing

    init(service: any ReviewSkipReasonServicing) {
        self.service = service
    }
}

// MARK: - Reduce
extension ReviewSkipReasonReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .start(let target):
            state = .init(target: target, formState: .loading, requestID: state.requestID + 1)
            return loadFormEffect(flowID: state.flowID, requestID: state.requestID)

        case .formLoaded(let result, let flowID, let requestID):
            guard state.formState == .loading,
                  state.flowID == flowID,
                  state.requestID == requestID
            else {
                return .none
            }
            switch result {
            case .success(let form):
                state.formState = .loaded(form)
            case .failure(let message):
                state.formState = .failed
                return .send(.delegate(.showSnackbar(message)))
            }

        case .retryTapped:
            guard state.formState == .failed else { return .none }
            state.formState = .loading
            state.requestID += 1
            return loadFormEffect(flowID: state.flowID, requestID: state.requestID)

        case .reasonSelected(let option):
            guard case let .loaded(form) = state.formState,
                  form.options.contains(where: { $0.code == option.code })
            else {
                return .none
            }
            state.selectedReason = option
            if !option.requiresTextInput {
                state.detail = ""
            }

        case .detailChanged(let value):
            guard state.selectedReason?.requiresTextInput == true,
                  value.count <= state.detailCharacterLimit
            else {
                return .none
            }
            state.detail = value

        case .submitTapped:
            guard state.canSubmit,
                  let practiceID = state.target?.practiceID,
                  let selectedReason = state.selectedReason
            else {
                return .none
            }
            state.isSubmitting = true
            state.requestID += 1
            return submitEffect(
                practiceID: practiceID,
                reasonCode: selectedReason.code,
                detail: selectedReason.requiresTextInput ? state.detail.normalizedOptionalText : nil,
                flowID: state.flowID,
                requestID: state.requestID
            )

        case .submissionCompleted(let result, let flowID, let requestID):
            guard state.isSubmitting,
                  state.flowID == flowID,
                  state.requestID == requestID
            else {
                return .none
            }
            state.isSubmitting = false
            switch result {
            case .success:
                state.isCompletionPresented = true
            case .failure(let message):
                return .send(.delegate(.showSnackbar(message)))
            }

        case .closeTapped:
            guard !state.isSubmitting, !state.isCompletionPresented else { return .none }
            if state.hasDraft {
                state.isDiscardConfirmationPresented = true
                return .none
            }
            return .send(.delegate(.finished))

        case .discardConfirmed:
            guard state.isDiscardConfirmationPresented else { return .none }
            return .send(.delegate(.finished))

        case .discardCancelled:
            state.isDiscardConfirmationPresented = false

        case .completionConfirmed:
            guard state.isCompletionPresented else { return .none }
            return .send(.delegate(.finished))

        case .reset:
            state = .init()
            return .run { send in
                await send(.cancelFormLoading)
                await send(.cancelSubmission)
            }

        case .cancelFormLoading:
            return .cancel(id: EffectID.formLoading)

        case .cancelSubmission:
            return .cancel(id: EffectID.submission)

        case .delegate:
            return .none
        }

        return .none
    }
}

// MARK: - Effect
private extension ReviewSkipReasonReducer {

    func loadFormEffect(flowID: UUID, requestID: Int) -> Effect<Action> {
        let service = service
        return .run { send in
            do {
                let form = try await service.fetchForm()
                await send(.formLoaded(.success(form), flowID: flowID, requestID: requestID))
            } catch is CancellationError {
                return
            } catch let error as NetworkError {
                await send(.formLoaded(.failure(error.localizedDescription), flowID: flowID, requestID: requestID))
            } catch {
                await send(.formLoaded(.failure("미방문 사유를 불러오지 못했어요. 다시 시도해주세요."), flowID: flowID, requestID: requestID))
            }
        }
        .cancelTask(id: EffectID.formLoading)
    }

    func submitEffect(
        practiceID: Int,
        reasonCode: String,
        detail: String?,
        flowID: UUID,
        requestID: Int
    ) -> Effect<Action> {
        let service = service
        return .run { send in
            do {
                try await service.submit(practiceID: practiceID, reasonCode: reasonCode, detail: detail)
                await send(.submissionCompleted(.success(()), flowID: flowID, requestID: requestID))
            } catch is CancellationError {
                return
            } catch let error as NetworkError {
                await send(.submissionCompleted(.failure(error.localizedDescription), flowID: flowID, requestID: requestID))
            } catch {
                await send(.submissionCompleted(.failure("미방문 사유를 등록하지 못했어요. 다시 시도해주세요."), flowID: flowID, requestID: requestID))
            }
        }
        .cancelTask(id: EffectID.submission)
    }
}
