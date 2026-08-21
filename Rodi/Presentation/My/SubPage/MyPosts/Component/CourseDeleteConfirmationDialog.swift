//
//  CourseDeleteConfirmationDialog.swift
//  Rodi
//

import SwiftUI

struct CourseDeleteConfirmationDialog: View {
    let isDeleting: Bool
    let errorMessage: String?
    let deleteAction: () -> Void
    let cancelAction: () -> Void

    var body: some View {
        RodiModalBackground {
            RodiDialog(contentInsets: .init(top: 32, leading: 20, bottom: 32, trailing: 20)) {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        Text("정말 삭제하시겠습니까?")
                            .font(.pretendard(size: 16, weight: .bold))
                            .tracking(-0.32)
                            .foregroundStyle(RodiColor.black)

                        Text("현재 검토 중인 코스예요.\n삭제하면 코스 검토가 중단돼요.")
                            .rodiTypography(.caption1Medium)
                            .foregroundStyle(RodiColor.black)
                            .multilineTextAlignment(.center)

                        if let errorMessage {
                            Text(errorMessage)
                                .rodiTypography(.caption2Medium)
                                .foregroundStyle(RodiColor.secondary400)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(minWidth: 240)

                    HStack(spacing: 8) {
                        Button(action: deleteAction) {
                            Group {
                                if isDeleting {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(RodiColor.gray800)
                                } else {
                                    Text("삭제하기")
                                        .rodiTypography(.buttonMedium)
                                        .foregroundStyle(RodiColor.gray800)
                                }
                            }
                            .frame(width: 116, height: 42)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(RodiColor.gray300, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(isDeleting)

                        Button(action: cancelAction) {
                            Text("취소")
                                .rodiTypography(.buttonMedium)
                                .foregroundStyle(RodiColor.white)
                                .frame(width: 116, height: 42)
                                .background(RodiColor.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .disabled(isDeleting)
                    }
                    .padding(.top, 24)
                }
            }
        }
    }
}
