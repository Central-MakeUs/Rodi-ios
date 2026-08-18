import SwiftUI

struct RodiDropdownOption: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
}

struct RodiDropdownAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [AnyHashable: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [AnyHashable: Anchor<CGRect>],
        nextValue: () -> [AnyHashable: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, newest in newest })
    }
}

struct RodiDropdown: View {
    let title: String
    let anchorID: AnyHashable

    @Binding private var isExpanded: Bool

    init(
        title: String,
        anchorID: AnyHashable,
        isExpanded: Binding<Bool>
    ) {
        self.title = title
        self.anchorID = anchorID
        _isExpanded = isExpanded
    }

    var body: some View {
        Button {
            isExpanded.toggle()
        } label: {
            HStack(spacing: 2) {
                Text(title)
                    .rodiTypography(.body3Medium)

                Image("ic_chevron_down")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
            .foregroundStyle(RodiColor.gray700)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("선택 메뉴")
        .accessibilityValue(title)
        .accessibilityHint(isExpanded ? "선택지를 닫으려면 두 번 탭하세요." : "선택지를 열려면 두 번 탭하세요.")
        .anchorPreference(key: RodiDropdownAnchorPreferenceKey.self, value: .bounds) {
            [anchorID: $0]
        }
    }
}

struct RodiDropdownMenu: View {
    let options: [RodiDropdownOption]
    let onSelect: (RodiDropdownOption) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]

                Button {
                    onSelect(option)
                } label: {
                    Text(option.title)
                        .font(.pretendard(size: 15, weight: .medium))
                        .foregroundStyle(RodiColor.gray700)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(option.title) 선택")

                if index < options.count - 1 {
                    Divider()
                        .overlay(RodiColor.gray300)
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .background(RodiColor.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay {
            RoundedRectangle(cornerRadius: 2)
                .stroke(RodiColor.gray300, lineWidth: 1)
        }
        .shadow(color: RodiColor.black.opacity(0.1), radius: 4, x: 0, y: 1)
    }
}
