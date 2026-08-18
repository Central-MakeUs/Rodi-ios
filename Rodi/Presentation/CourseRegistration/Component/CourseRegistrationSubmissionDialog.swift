import SwiftUI

struct CourseRegistrationSubmittingDialog: View {
    var body: some View {
        RodiModalBackground {
            RodiDialog(contentInsets: .init(top: 0, leading: 0, bottom: 0, trailing: 0)) {
                ZStack {
                    CourseRegistrationLoadingIndicator()
                        .accessibilityLabel("등록 요청 중")

                    Text("등록 요청 중")
                        .font(.pretendard(size: 16, weight: .bold))
                        .tracking(-0.32)
                        .foregroundStyle(RodiColor.black)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 39)
                }
                .frame(width: 280, height: 226)
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}

struct CourseRegistrationCompletionDialog: View {
    let confirmAction: () -> Void

    var body: some View {
        RodiModalBackground {
            RodiDialog(contentInsets: .init(top: 32, leading: 20, bottom: 32, trailing: 20)) {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("등록 요청 완료!")
                            .font(.pretendard(size: 16, weight: .bold))
                            .tracking(-0.32)
                            .foregroundStyle(RodiColor.black)

                        Text("관리자의 검토 후 48시간 내에\n등록될 예정입니다.")
                            .rodiTypography(.caption1Medium)
                            .foregroundStyle(RodiColor.black)
                            .multilineTextAlignment(.center)
                            .frame(height: 60)
                    }

                    Button(action: confirmAction) {
                        Text("확인")
                            .rodiTypography(.buttonMedium)
                            .foregroundStyle(RodiColor.white)
                            .frame(width: 116, height: 42)
                            .background(RodiColor.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 116, minHeight: 44)
                    .accessibilityLabel("확인")
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}

private struct CourseRegistrationLoadingIndicator: View {
    @State private var rotation = 0.0

    private let colors: [Color] = [
        RodiColor.primary,
        RodiColor.primary20,
        RodiColor.primary50,
        RodiColor.primary100,
        RodiColor.primary200,
        RodiColor.primary300,
        RodiColor.primary400,
        RodiColor.primary500
    ]

    var body: some View {
        ZStack {
            ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                Capsule()
                    .fill(color)
                    .frame(width: 4, height: 12)
                    .offset(y: -13.5)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
        }
        .frame(width: 39, height: 39)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
