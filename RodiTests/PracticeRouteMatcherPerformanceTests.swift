import CoreLocation
import XCTest
@testable import Rodi

final class PracticeRouteMatcherPerformanceTests: XCTestCase {

    func testLongRouteMatchingPerformance() {
        let path = makePath(pointCount: 2_001)
        let cumulativeDistance = PracticeRouteMatcher.cumulativeDistance(for: path)
        let location = CLLocation(latitude: path[1_000].latitude, longitude: path[1_000].longitude)

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for _ in 0..<20 {
                XCTAssertNotNil(
                    PracticeRouteMatcher.match(
                        location: location,
                        path: path,
                        cumulativeDistanceMeters: cumulativeDistance
                    )
                )
            }
        }
    }

    @MainActor
    func testProgressiveMarkerSnapshotsKeepExistingBatchContract() async {
        let markers = (0..<1_000).map { index in
            RodiMapMarker(
                id: "marker-\(index)",
                kind: .course,
                title: "코스 \(index)",
                coordinate: .init(
                    latitude: 37.500_000 + (Double(index) * 0.000_010),
                    longitude: 127.000_000 + (Double(index) * 0.000_010)
                )
            )
        }

        let stream = MapMarkerRenderingService().progressiveSnapshots(for: markers)
        var counts: [Int] = []
        for await snapshot in stream {
            counts.append(snapshot.count)
        }

        XCTAssertEqual(counts, [80, 230, 380, 530, 680, 830, 980, 1_000])
    }

    private func makePath(pointCount: Int) -> [RodiCoordinate] {
        (0..<pointCount).map { index in
            RodiCoordinate(
                latitude: 37.500_000 + (Double(index) * 0.000_010),
                longitude: 127.000_000 + (Double(index) * 0.000_010)
            )
        }
    }
}
