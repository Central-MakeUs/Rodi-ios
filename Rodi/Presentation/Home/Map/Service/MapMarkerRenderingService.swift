//
//  MapMarkerRenderingService.swift
//  Rodi
//

import Foundation

@MainActor
final class MapMarkerRenderingService {
    
    func progressiveSnapshots( for markers: [RodiMapMarker]) -> AsyncStream<[RodiMapMarker]> {
        let batches = batches(for: markers)

        return AsyncStream { continuation in
            guard !batches.isEmpty else {
                continuation.yield([])
                continuation.finish()
                return
            }

            let renderingTask = Task { @MainActor in
                for (index, batch) in batches.enumerated() {
                    if index > 0 {
                        do {
                            try await Task.sleep(for: .milliseconds(16))
                        } catch {
                            break
                        }
                    }

                    guard !Task.isCancelled else { break }
                    continuation.yield(batch)
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                renderingTask.cancel()
            }
        }
    }

    private func batches(for markers: [RodiMapMarker]) -> [[RodiMapMarker]] {
        guard !markers.isEmpty else { return [] }

        let initialBatchSize = 80
        let batchSize = 150
        var batches: [[RodiMapMarker]] = []
        var renderedCount = min(initialBatchSize, markers.count)
        batches.append(Array(markers.prefix(renderedCount)))

        while renderedCount < markers.count {
            renderedCount = min(renderedCount + batchSize, markers.count)
            batches.append(Array(markers.prefix(renderedCount)))
        }

        return batches
    }
}
