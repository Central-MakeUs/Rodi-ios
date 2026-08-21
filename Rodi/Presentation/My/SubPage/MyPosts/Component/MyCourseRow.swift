import SwiftUI

struct MyCourseRow: View {
    let course: MyCourseItem
    let isMenuExpanded: Bool
    let menuTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.name)
                .font(.pretendard(size: 15, weight: .semibold))
                .tracking(-0.3)
                .foregroundStyle(RodiColor.black)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .trailing) {
                    Button(action: menuTapped) {
                        Image("ic_more_horizontal_circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .anchorPreference(key: RodiDropdownAnchorPreferenceKey.self, value: .bounds) {
                                [AnyHashable("course-\(course.id)"): $0]
                            }
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel(isMenuExpanded ? "코스 메뉴 닫기" : "코스 메뉴 열기")
                }

            HStack(spacing: 4) {
                Text(course.approvalStatus.title)
                    .font(.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(statusTextColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                Text("･")
                Text(createdAtText)
            }
            .font(.pretendard(size: 13, weight: .medium))
            .tracking(-0.26)
            .foregroundStyle(RodiColor.gray600)
        }
    }
}

private extension MyCourseRow {

    var statusTextColor: Color {
        switch course.approvalStatus {
        case .approved: Color(hex: 0x04B3AA)
        case .pending: RodiColor.gray50
        case .rejected: Color(hex: 0xFF3019)
        }
    }

    var statusBackgroundColor: Color {
        switch course.approvalStatus {
        case .approved: Color(hex: 0xE4FAF7)
        case .pending: RodiColor.gray400
        case .rejected: Color(hex: 0xFFEDF6)
        }
    }

    var createdAtText: String {
        let dateComponents = course.createdAt.prefix(10).split(separator: "-")
        guard dateComponents.count == 3,
              dateComponents[0].count == 4,
              dateComponents[1].count == 2,
              dateComponents[2].count == 2
        else {
            return course.createdAt
        }

        return "\(dateComponents[0].suffix(2)).\(dateComponents[1]).\(dateComponents[2])"
    }
}
