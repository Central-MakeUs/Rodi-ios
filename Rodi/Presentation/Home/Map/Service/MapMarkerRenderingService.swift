//
//  MapMarkerRenderingService.swift
//  Rodi
//

import Foundation

@MainActor
final class MapMarkerRenderingService {

    func progressiveSnapshots(for markers: [RodiMapMarker]) -> AsyncStream<[RodiMapMarker]> {
        return AsyncStream { continuation in
            let renderingTask = Task { @MainActor [markers] in
                guard !markers.isEmpty else {
                    continuation.yield([])
                    continuation.finish()
                    return
                }

                let initialBatchSize = 80
                let batchSize = 150
                var renderedCount = min(initialBatchSize, markers.count)

                while !Task.isCancelled {
                    continuation.yield(Array(markers.prefix(renderedCount)))
                    guard renderedCount < markers.count else { break }

                    do {
                        try await Task.sleep(for: .milliseconds(16))
                    } catch {
                        break
                    }

                    renderedCount = min(renderedCount + batchSize, markers.count)
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                renderingTask.cancel()
            }
        }
    }
}
