import SwiftUI

protocol ReviewScaleOption: Hashable {
    var title: String { get }
}

private enum ReviewScaleMetrics {
    static let maximumOptionCount = 5
    static let markerHorizontalPadding: CGFloat = 16
    static let indicatorSize: CGFloat = 16
    static let connectionHeight: CGFloat = 2
}

@MainActor
private struct ReviewScaleTrackLayout: @preconcurrency Layout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = proposal.width ?? 320
        let slotWidth = slotWidth(for: width)
        let height = subviews
            .map { $0.sizeThatFits(.init(width: slotWidth, height: nil)).height }
            .max() ?? 0

        return .init(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let slotWidth = slotWidth(for: bounds.width)
        let firstMarkerCenter = bounds.minX
            + ReviewScaleMetrics.markerHorizontalPadding
            + ReviewScaleMetrics.indicatorSize / 2

        for (index, subview) in subviews.enumerated() {
            let centerX = firstMarkerCenter + slotWidth * CGFloat(index)
            subview.place(
                at: .init(x: centerX - slotWidth / 2, y: bounds.minY),
                anchor: .topLeading,
                proposal: .init(width: slotWidth, height: bounds.height)
            )
        }
    }

    private func slotWidth(for width: CGFloat) -> CGFloat {
        let drawableWidth = width
            - ReviewScaleMetrics.markerHorizontalPadding * 2
            - ReviewScaleMetrics.indicatorSize
        return max(0, drawableWidth / CGFloat(ReviewScaleMetrics.maximumOptionCount - 1))
    }
}

struct ReviewScaleSelector<Value: CaseIterable & ReviewScaleOption>: View where
    Value.AllCases: RandomAccessCollection, Value.AllCases.Element == Value {
    let title: String
    let selected: Value?
    let action: (Value) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .rodiTypography(.body1SemiBold)
                .foregroundStyle(RodiColor.black)
            scaleTrack
        }
    }
}

// MARK: - Component
private extension ReviewScaleSelector {

    var options: [Value] {
        Array(Value.allCases)
    }

    var scaleTrack: some View {
        ReviewScaleTrackLayout {
            ForEach(0..<ReviewScaleMetrics.maximumOptionCount, id: \.self) { index in
                if index < options.count {
                    scaleOption(value: options[index], index: index)
                } else {
                    Color.clear
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func scaleOption(value: Value, index: Int) -> some View {
        Button(action: { action(value) }) {
            ZStack(alignment: .top) {
                HStack(spacing: 0) {
                    connectionSegment(isVisible: index > 0)
                    connectionSegment(isVisible: index < options.count - 1)
                }
                .frame(height: ReviewScaleMetrics.connectionHeight)
                .padding(.top, (ReviewScaleMetrics.indicatorSize - ReviewScaleMetrics.connectionHeight) / 2)

                VStack(spacing: 8) {
                    Circle()
                        .fill(selected == value ? RodiColor.primary : RodiColor.white)
                        .overlay {
                            Circle()
                                .stroke(RodiColor.primary300, lineWidth: 1)
                        }
                        .frame(width: ReviewScaleMetrics.indicatorSize, height: ReviewScaleMetrics.indicatorSize)

                    Text(value.title)
                        .rodiTypography(.caption1Medium)
                        .foregroundStyle(RodiColor.gray800)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityLabel(value.title)
        .accessibilityValue(selected == value ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(selected == value ? .isSelected : [])
    }

    func connectionSegment(isVisible: Bool) -> some View {
        Rectangle()
            .fill(isVisible ? RodiColor.primary300 : Color.clear)
            .frame(maxWidth: .infinity)
    }
}

extension ReviewDifficulty: ReviewScaleOption {}
extension ReviewCongestion: ReviewScaleOption {}
