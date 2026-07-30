//
//  DualBottomButton.swift
//  Rodi
//

import SwiftUI

struct DualBottomButton: View {
    let secondaryTitle: String
    let primaryTitle: String
    let isPrimaryEnabled: Bool
    let secondaryAction: () -> Void
    let primaryAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(RodiColor.gray200)
                .frame(height: 1)

            ProportionalButtonRowLayout {
                secondaryButton
                primaryButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(RodiColor.white)
    }

    private var secondaryButton: some View {
        Button(action: secondaryAction) {
            Text(secondaryTitle)
                .rodiTypography(.buttonMedium)
                .foregroundStyle(RodiColor.gray800)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(RodiColor.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(RodiColor.gray300, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var primaryButton: some View {
        Button(action: primaryAction) {
            Text(primaryTitle)
                .rodiTypography(.buttonMedium)
                .foregroundStyle(isPrimaryEnabled ? RodiColor.white : RodiColor.gray500)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(isPrimaryEnabled ? RodiColor.primary : RodiColor.gray300)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(!isPrimaryEnabled)
    }
}

private struct ProportionalButtonRowLayout: Layout {
    private let spacing: CGFloat = 6
    private let secondaryRatio: CGFloat = 0.4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let height = subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let availableWidth = max(bounds.width - spacing, 0)
        let secondaryWidth = availableWidth * secondaryRatio

        subviews[0].place(
            at: CGPoint(x: bounds.minX, y: bounds.minY),
            anchor: .topLeading,
            proposal: ProposedViewSize(width: secondaryWidth, height: bounds.height)
        )
        subviews[1].place(
            at: CGPoint(x: bounds.minX + secondaryWidth + spacing, y: bounds.minY),
            anchor: .topLeading,
            proposal: ProposedViewSize(width: availableWidth - secondaryWidth, height: bounds.height)
        )
    }
}
