//
//  DrivePracticeCertificationService.swift
//  Rodi
//

import Foundation

@MainActor
/// 인증 대기 상태의 측정을 서버 연습 기록과 방문 기록으로 확정한다.
/// 요청 Task·취소·request ID 최신성 검증을 소유하고, 성공 사실만 상위에 알린다.
final class DrivePracticeCertificationService {
    private let practiceRepository: PracticeRepository
    private let measurementStore: PracticeMeasurementStoring
    private let didCertify: () -> Void

    private var isRequestInFlight = false
    private var requestTask: Task<Void, Never>?
    private var requestID = 0

    init(
        practiceRepository: PracticeRepository,
        measurementStore: PracticeMeasurementStoring,
        didCertify: @escaping () -> Void
    ) {
        self.practiceRepository = practiceRepository
        self.measurementStore = measurementStore
        self.didCertify = didCertify
    }

    func retryIfNeeded() {
        guard !isRequestInFlight,
              let measurement = measurementStore.load(),
              measurement.mode == .gpsTracking,
              measurement.status == .certificationPendingRegistration
                || measurement.status == .certificationPendingVisit
        else {
            return
        }

        requestID += 1
        let activeRequestID = requestID
        isRequestInFlight = true
        requestTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if requestID == activeRequestID {
                    isRequestInFlight = false
                    requestTask = nil
                }
            }

            do {
                var current = measurement
                if current.status == .certificationPendingRegistration {
                    let registration = try await practiceRepository.register(placeID: current.placeID)
                    guard !Task.isCancelled, requestID == activeRequestID else { return }
                    current.practiceID = registration.practiceID
                    current.status = .certificationPendingVisit
                    measurementStore.save(current)
                }

                guard let practiceID = current.practiceID else { return }
                _ = try await practiceRepository.recordVisit(
                    practiceID: practiceID,
                    certifiedDistanceMeters: current.certifiedDistanceMeters
                )
                guard !Task.isCancelled, requestID == activeRequestID else { return }
                current.status = .certified
                measurementStore.save(current)
                didCertify()
            } catch is CancellationError {
                return
            } catch {
                guard requestID == activeRequestID else { return }
                RodiLogger.warning("Drive practice certification pending")
            }
        }
    }

    func cancel() {
        requestID += 1
        requestTask?.cancel()
        requestTask = nil
        isRequestInFlight = false
    }
}
