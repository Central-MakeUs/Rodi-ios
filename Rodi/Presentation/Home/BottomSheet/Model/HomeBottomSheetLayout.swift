import Foundation

/// BottomSheet의 drag 중 높이와 settle 목적지를 계산한다.
/// Gesture 진행값과 animation task는 View-local 상태로 남기고, 상태 없는 layout 정책만 분리한다.
enum HomeBottomSheetLayout {
    static func sheetHeight(
        baseHeight: CGFloat,
        translation: CGFloat,
        screenHeight: CGFloat
    ) -> CGFloat {
        min(max(baseHeight - translation, 0), screenHeight)
    }

    static func dismissalOpacity(visibleHeight: CGFloat, totalHeight: CGFloat) -> CGFloat {
        guard totalHeight > 0 else { return 1 }
        let visibleRatio = visibleHeight / totalHeight
        return min(max((visibleRatio - 0.1) / 0.6, 0), 1)
    }

    static func recommendationDestination(
        height: CGFloat,
        screenHeight: CGFloat
    ) -> RecommendListBottomSheetReducer.Presentation {
        let heightRatio = height / screenHeight

        if heightRatio <= 0.45 {
            return .collapsed
        }
        if heightRatio >= 0.55 {
            return .expanded
        }
        return .medium
    }

    static func courseDestination(
        height: CGFloat,
        restingHeight: CGFloat,
        screenHeight: CGFloat
    ) -> CourseSheetDestination {
        if height <= max(restingHeight - 48, 0) {
            return .dismissed
        }
        if height / screenHeight >= 0.55 {
            return .expanded
        }
        return .resting
    }
}

enum CourseSheetDestination {
    case dismissed
    case resting
    case expanded
}
