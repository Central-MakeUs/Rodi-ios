import SwiftUI

struct RodiCenteredNavigationHeader<Leading: View, Trailing: View>: View {
    let title: String
    private let leading: Leading
    private let trailing: Trailing

    init(
        title: String,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        ZStack {
            Text(title)
                .rodiTypography(.headline1)
                .foregroundStyle(RodiColor.black)
                .lineLimit(1)

            HStack(spacing: 0) {
                leading
                    .frame(width: 44, height: 44)

                Spacer(minLength: 0)

                trailing
                    .frame(width: 44, height: 44)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
    }
}
