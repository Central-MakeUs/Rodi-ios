//
//  OnboardingContainer.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct OnboardingContainer<Content: View>: View {
    let step: OnboardingStep
    @ViewBuilder let content: Content
    let onBack: () -> Void

    var body: some View {
        ZStack {
            RodiColor.white.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                if let progressCount = step.progressCount {
                    StepProgressView(activeCount: progressCount, totalCount: 3)
                        .padding(.top, 0)
                }
                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.pretendard(size: 18, weight: .medium))
                    .foregroundStyle(RodiColor.black)
                    .frame(width: 44, height: 56, alignment: .leading)
            }
            .opacity(step.previous == nil ? 0 : 1)
            .disabled(step.previous == nil)
            .accessibilityHidden(step.previous == nil)

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }
}
