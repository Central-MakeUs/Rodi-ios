//
//  PracticeReturnReducer.swift
//  Rodi
//

import Foundation

/// 외부 길안내 복귀 뒤의 측정 연속·방문 기록·후기 권유 정책을 소유한다.
struct PracticeReturnReducer: Reducer {

    struct State {
        var pendingMeasurement: PracticeMeasurement?
        var activeMeasurementContinuation: PracticeMeasurement?
        var isParkingVisitSubmitting = false
        var isDebugCourseVisitSubmitting = false
        var requestRevision = 0
    }

    enum Action {
        case sceneBecameActive(canPresentPrompt: Bool)
        case sceneBecameInactive
        case activeMeasurementContinued
        case activeMeasurementEnded
        case promptInteraction(PracticeReturnPromptInteraction)
        case parkingVisitCompleted(revision: Int, Result<Void, Error>)
        case debugCourseVisitRecorded(revision: Int, Result<PracticeMeasurement, Error>)
        case reset
        case delegate(Delegate)
    }

    enum Delegate {
        case promptRequested(PracticeReturnPrompt)
        case reviewPromptInteraction(PracticeReturnPromptInteraction)
        case reviewPromptVisitSubmissionChanged(Bool)
        case finishedWithoutReview(String)
        case showSnackbar(String)
    }

    private enum EffectID {
        case parkingVisit
        case debugCourseVisit
    }

    private let practiceRepository: PracticeRepository
    private let measurementStore: PracticeMeasurementStoring
    private let trackingService: PracticeTrackingService

    init(
        practiceRepository: PracticeRepository,
        measurementStore: PracticeMeasurementStoring,
        trackingService: PracticeTrackingService
    ) {
        self.practiceRepository = practiceRepository
        self.measurementStore = measurementStore
        self.trackingService = trackingService
    }

    #if DEBUG
    nonisolated static func shouldRecordDebugCourseVisit(
        measurement: PracticeMeasurement,
        now: Date
    ) -> Bool {
        guard measurement.placeType != .parking,
              measurement.mode == .gpsTracking
        else {
            return false
        }
        return now.timeIntervalSince(measurement.lastRodiInactiveAt ?? measurement.externalHandoffAt) >= 10
    }
    #endif
}

// MARK: - Reduce
extension PracticeReturnReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .sceneBecameActive(let canPresentPrompt):
            let restorationDecision = trackingService.restoreIfNeeded()
            trackingService.retryCertificationIfNeeded()
            if let restorationEffect = handleRestorationDecision(
                restorationDecision,
                canPresentPrompt: canPresentPrompt,
                state: &state
            ) {
                return restorationEffect
            }
            guard canPresentPrompt else { return .none }
            return preparePromptIfNeeded(state: &state)

        case .sceneBecameInactive:
            markInactiveIfNeeded()

        case .activeMeasurementContinued:
            guard let measurement = state.activeMeasurementContinuation else { return .none }
            switch trackingService.continueTracking(sessionID: measurement.id) {
            case .started:
                state.activeMeasurementContinuation = nil
            case .authorizationRequested:
                return .send(.delegate(.showSnackbar("위치 권한을 허용하면 이동 측정을 이어갈 수 있어요.")))
            case .reducedAccuracyRequested:
                return .send(.delegate(.showSnackbar("정확한 위치 권한을 허용하면 이동 측정을 이어갈 수 있어요.")))
            case .unavailable(let message):
                return .send(.delegate(.showSnackbar(message)))
            }

        case .activeMeasurementEnded:
            trackingService.cancel()
            state.activeMeasurementContinuation = nil
            guard var measurement = measurementStore.load() else { return .none }
            guard measurement.isParking else {
                #if DEBUG
                guard Self.shouldRecordDebugCourseVisit(
                    measurement: measurement,
                    now: .now
                ) else {
                    measurementStore.clear()
                    return .none
                }
                state.isDebugCourseVisitSubmitting = true
                state.requestRevision += 1
                return registerDebugCourseVisit(
                    measurement: measurement,
                    revision: state.requestRevision
                )
                #else
                measurementStore.clear()
                return .none
                #endif
            }
            guard hasElapsedPromptDelay(since: measurement.externalHandoffAt) else {
                measurementStore.clear()
                return .none
            }
            measurement.status = .awaitingReturn
            measurementStore.save(measurement)
            return makePromptEffect(for: measurement, requiresEligibility: false, state: &state)

        case .promptInteraction(let interaction):
            return handlePromptInteraction(interaction, state: &state)

        case .parkingVisitCompleted(let revision, let result):
            guard revision == state.requestRevision else { return .none }
            state.isParkingVisitSubmitting = false
            switch result {
            case .success:
                removePendingMeasurement(state: &state)
                return .send(.delegate(.finishedWithoutReview("연습 기록에 추가되었습니다.")))
            case .failure:
                return .run { send in
                    await send(.delegate(.reviewPromptVisitSubmissionChanged(false)))
                    await send(.delegate(.showSnackbar("연습 기록에 추가하지 못했어요. 다시 시도해 주세요.")))
                }
            }

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

        case .reset:
            state.requestRevision += 1
            state = .init(requestRevision: state.requestRevision)
            return .none

        case .delegate:
            return .none
        }

        return .none
    }
}

// MARK: - Prompt Policy
private extension PracticeReturnReducer {

    func handleRestorationDecision(
        _ decision: PracticeTrackingRestorationDecision?,
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

        if measurement.isActiveTracking, trackingService.hasActiveMeasurement {
            state.activeMeasurementContinuation = measurement
            return .none
        }

        return makePromptEffect(for: measurement, state: &state)
    }

    func makePromptEffect(
        for measurement: PracticeMeasurement,
        requiresEligibility: Bool = true,
        state: inout State
    ) -> Effect<Action> {
        guard !requiresEligibility || isReviewEligible(measurement) else { return .none }
        state.pendingMeasurement = measurement
        return .send(.delegate(.promptRequested(
            .init(
                placeID: measurement.placeID,
                placeName: measurement.placeName,
                allowsSkipReason: true,
                allowsReviewWriting: !measurement.isParking,
                visitedSnackbarMessage: measurement.isParking ? "연습 기록에 추가되었습니다." : nil
            )
        )))
    }

    func handlePromptInteraction(
        _ interaction: PracticeReturnPromptInteraction,
        state: inout State
    ) -> Effect<Action> {
        guard let measurement = state.pendingMeasurement else {
            return .send(.delegate(.reviewPromptInteraction(interaction)))
        }
        guard !state.isParkingVisitSubmitting, !state.isDebugCourseVisitSubmitting else {
            return .none
        }

        // GPS 인증이 끝난 코스의 방문 기록은 이미 서버에 저장되어 있다.
        // 미방문 사유로 상태를 바꾸지 않고 팝업만 닫는다.
        if !measurement.isParking,
           measurement.status == .certified,
           interaction == .notVisited {
            removePendingMeasurement(state: &state)
            return .send(.delegate(.reviewPromptInteraction(.closed)))
        }

        if measurement.isParking,
           interaction != .notVisited,
           measurement.status != .certified,
           !state.isParkingVisitSubmitting {
            state.isParkingVisitSubmitting = true
            state.requestRevision += 1
            let revision = state.requestRevision
            let practiceRepository = practiceRepository
            return .run { send in
                await send(.delegate(.reviewPromptVisitSubmissionChanged(true)))
                do {
                    let registration = try await practiceRepository.register(placeID: measurement.placeID)
                    _ = try await practiceRepository.recordVisit(
                        practiceID: registration.practiceID,
                        certifiedDistanceMeters: nil
                    )
                    await send(.parkingVisitCompleted(revision: revision, .success(())))
                } catch {
                    await send(.parkingVisitCompleted(revision: revision, .failure(error)))
                }
            }
            .cancelTask(id: EffectID.parkingVisit)
        }

        removePendingMeasurement(state: &state)
        return .send(.delegate(.reviewPromptInteraction(interaction)))
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

    func markInactiveIfNeeded() {
        guard var measurement = measurementStore.load() else { return }
        measurement.lastRodiInactiveAt = .now
        measurementStore.save(measurement)
    }

    func isReviewEligible(_ measurement: PracticeMeasurement) -> Bool {
        if measurement.isParking {
            guard measurement.status == .certified || measurement.status == .awaitingReturn else { return false }
            return hasElapsedPromptDelay(since: measurement.externalHandoffAt)
        }

        return measurement.status == .certified
    }

    func hasElapsedPromptDelay(since date: Date?) -> Bool {
        guard let date else { return false }
        return Date.now.timeIntervalSince(date) >= reviewPromptDelay
    }

    var reviewPromptDelay: TimeInterval {
        #if DEBUG
        10
        #else
        10 * 60
        #endif
    }
}
