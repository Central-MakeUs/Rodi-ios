//
//  DrivePracticeReducer.swift
//  Rodi
//

import Foundation

/// 연습 측정과 외부 길안내 복귀 후 정책을 하나의 Feature State로 소유한다.
struct DrivePracticeReducer: Reducer {

    struct State {
        var pendingMeasurement: PracticeMeasurement?
        var activeMeasurementContinuation: PracticeMeasurement?
        var isDebugCourseVisitSubmitting = false
        var requestRevision = 0
    }

    enum Action {
        case sceneBecameActive(canPresentPrompt: Bool)
        case sceneBecameInactive
        case certificationRevisionChanged(canPresentPrompt: Bool)
        case activeMeasurementContinued
        case activeMeasurementEnded
        case sessionEnded
        case promptInteractionRequested(PracticeReturnPromptInteraction)
        case debugCourseVisitRecorded(revision: Int, Result<PracticeMeasurement, Error>)
        case delegate(Delegate)
    }

    enum Delegate {
        case reviewPromptRequested(PracticeReturnPrompt)
        case reviewPromptInteractionReady(PracticeReturnPromptInteraction)
        case reviewFlowFinishedWithoutReview(String)
        case showSnackbar(String)
    }

    private enum EffectID {
        case debugCourseVisit
    }

    private let practiceRepository: PracticeRepository
    private let measurementStore: PracticeMeasurementStoring
    private let drivePracticeService: DrivePracticeService

    init(
        practiceRepository: PracticeRepository,
        measurementStore: PracticeMeasurementStoring,
        drivePracticeService: DrivePracticeService
    ) {
        self.practiceRepository = practiceRepository
        self.measurementStore = measurementStore
        self.drivePracticeService = drivePracticeService
    }

    #if DEBUG
    nonisolated static func shouldRecordDebugCourseVisit(
        measurement: PracticeMeasurement,
        now: Date
    ) -> Bool {
        measurement.placeType != .parking
            && measurement.mode == .gpsTracking
            && now.timeIntervalSince(measurement.externalHandoffAt) >= 5
    }
    #endif
}


// MARK: - Reduce
extension DrivePracticeReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .sceneBecameActive(let canPresentPrompt),
             .certificationRevisionChanged(let canPresentPrompt):
            let restorationDecision = drivePracticeService.restoreIfNeeded()
            drivePracticeService.retryCertificationIfNeeded()
            if let restorationEffect = handleRestorationDecision(
                restorationDecision,
                canPresentPrompt: canPresentPrompt,
                state: &state
            ) {
                return restorationEffect
            }
            #if DEBUG
            if canPresentPrompt,
               drivePracticeService.isSessionFromCurrentProcess,
               let measurement = measurementStore.load(),
               Self.shouldRecordDebugCourseVisit(measurement: measurement, now: .now) {
                drivePracticeService.cancel()
                state.activeMeasurementContinuation = nil
                state.isDebugCourseVisitSubmitting = true
                state.requestRevision += 1
                return registerDebugCourseVisit(
                    measurement: measurement,
                    revision: state.requestRevision
                )
            }
            #endif
            guard canPresentPrompt else { return .none }
            return preparePromptIfNeeded(state: &state)

        case .sceneBecameInactive:
            return .none

        case .activeMeasurementContinued:
            guard let measurement = state.activeMeasurementContinuation else { return .none }
            switch drivePracticeService.continueTracking(sessionID: measurement.id) {
            case .started:
                state.activeMeasurementContinuation = nil
            case .authorizationRequested:
                return .send(.delegate(.showSnackbar("위치 권한을 허용하면 이동 측정을 이어갈 수 있어요.")))
            case .reducedAccuracyRequested:
                return .send(.delegate(.showSnackbar("정확한 위치 권한을 허용하면 이동 측정을 이어갈 수 있어요.")))
            case .unavailable(let message):
                return .send(.delegate(.showSnackbar(message)))
            }
            return .none

        case .activeMeasurementEnded:
            drivePracticeService.cancel()
            state.activeMeasurementContinuation = nil
            measurementStore.clear()
            return .none

        case .sessionEnded:
            drivePracticeService.endForSessionChange()
            state.requestRevision += 1
            state = .init(requestRevision: state.requestRevision)
            return .cancel(id: EffectID.debugCourseVisit)

        case .promptInteractionRequested(let interaction):
            return handlePromptInteraction(interaction, state: &state)

        case .debugCourseVisitRecorded(let revision, let result):
            guard revision == state.requestRevision else { return .none }
            state.isDebugCourseVisitSubmitting = false
            switch result {
            case .success(let measurement):
                measurementStore.save(measurement)
                return makePromptEffect(for: measurement, state: &state)
            case .failure:
                measurementStore.clear()
                return .send(.delegate(.showSnackbar("연습 기록에 추가하지 못했어요. 다시 시도해 주세요.")))
            }

        case .delegate:
            return .none
        }
    }
}


// MARK: - Return Policy
private extension DrivePracticeReducer {

    func handleRestorationDecision(
        _ decision: DrivePracticeRestorationDecision?,
        canPresentPrompt: Bool,
        state: inout State
    ) -> Effect<Action>? {
        switch decision {
        case .continueApproach:
            guard canPresentPrompt,
                  let measurement = measurementStore.load(),
                  measurement.isActiveTracking
            else {
                return .none
            }
            state.activeMeasurementContinuation = measurement
            return .none

        case .interruptDriving:
            state.activeMeasurementContinuation = nil
            return .send(.delegate(.showSnackbar("앱이 종료되어 연습 측정이 중단되었어요.")))

        case .discardApproach:
            state.activeMeasurementContinuation = nil
            return nil

        case nil:
            return nil
        }
    }

    func preparePromptIfNeeded(state: inout State) -> Effect<Action> {
        guard state.pendingMeasurement == nil,
              let measurement = measurementStore.load()
        else {
            return .none
        }

        if measurement.isActiveTracking, drivePracticeService.hasActiveMeasurement {
            state.activeMeasurementContinuation = measurement
            return .none
        }

        if measurement.isParking {
            guard measurement.status == .certified else { return .none }
            measurementStore.remove(measurement)
            return .send(.delegate(.reviewFlowFinishedWithoutReview("연습 기록에 추가되었습니다.")))
        }

        return makePromptEffect(for: measurement, state: &state)
    }

    func makePromptEffect(
        for measurement: PracticeMeasurement,
        state: inout State
    ) -> Effect<Action> {
        guard measurement.status == .certified else { return .none }
        state.pendingMeasurement = measurement
        return .send(.delegate(.reviewPromptRequested(
            .init(
                placeID: measurement.placeID,
                placeName: measurement.placeName,
                allowsSkipReason: true,
                allowsReviewWriting: true,
                visitedSnackbarMessage: nil
            )
        )))
    }

    func handlePromptInteraction(
        _ interaction: PracticeReturnPromptInteraction,
        state: inout State
    ) -> Effect<Action> {
        guard let measurement = state.pendingMeasurement else {
            return .send(.delegate(.reviewPromptInteractionReady(interaction)))
        }

        if measurement.status == .certified, interaction == .notVisited {
            removePendingMeasurement(state: &state)
            return .send(.delegate(.reviewPromptInteractionReady(.closed)))
        }

        removePendingMeasurement(state: &state)
        return .send(.delegate(.reviewPromptInteractionReady(interaction)))
    }

    #if DEBUG
    func registerDebugCourseVisit(
        measurement: PracticeMeasurement,
        revision: Int
    ) -> Effect<Action> {
        let practiceRepository = practiceRepository
        return .run { send in
            do {
                let registration = try await practiceRepository.register(placeID: measurement.placeID)
                _ = try await practiceRepository.recordVisit(
                    practiceID: registration.practiceID,
                    certifiedDistanceMeters: nil
                )
                var registeredMeasurement = measurement
                registeredMeasurement.practiceID = registration.practiceID
                registeredMeasurement.status = .certified
                await send(.debugCourseVisitRecorded(revision: revision, .success(registeredMeasurement)))
            } catch is CancellationError {
                return
            } catch {
                await send(.debugCourseVisitRecorded(revision: revision, .failure(error)))
            }
        }
        .cancelTask(id: EffectID.debugCourseVisit)
    }
    #endif

    func removePendingMeasurement(state: inout State) {
        if let measurement = state.pendingMeasurement {
            measurementStore.remove(measurement)
        }
        state.pendingMeasurement = nil
    }
}
