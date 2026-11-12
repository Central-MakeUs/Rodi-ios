import SwiftUI

// TODO: Scaffold -> ContainerView (윤수)
struct ReviewFormScaffold<Content: View, BottomBar: View>: View {
    @Environment(\.screenSafeAreaInsets) private var screenSafeAreaInsets

    private let header: ReviewFormHeader
    private let content: Content
    private let bottomBar: BottomBar
    private let ignoresKeyboardSafeArea: Bool
    private let bottomSafeAreaInset: CGFloat?

    init(
        header: ReviewFormHeader,
        ignoresKeyboardSafeArea: Bool = true,
        bottomSafeAreaInset: CGFloat? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder bottomBar: () -> BottomBar
    ) {
        self.header = header
        self.content = content()
        self.bottomBar = bottomBar()
        self.ignoresKeyboardSafeArea = ignoresKeyboardSafeArea
        self.bottomSafeAreaInset = bottomSafeAreaInset
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(maxWidth: .infinity)
                .background(RodiColor.white)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomBar
                .frame(maxWidth: .infinity)
                .background(RodiColor.white)
        }
        .padding(.top, screenSafeAreaInsets.top)
        .padding(.bottom, bottomSafeAreaInset ?? screenSafeAreaInsets.bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(RodiColor.white)
        .ignoresSafeArea(.container)
        .ignoresSafeArea(
            ignoresKeyboardSafeArea ? .keyboard : [],
            edges: .bottom
        )
    }
}
