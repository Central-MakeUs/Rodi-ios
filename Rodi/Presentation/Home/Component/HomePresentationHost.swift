import SwiftUI

/// Home root 위에 표시되는 검색·상세·후기 full-screen 흐름을 한곳에서 조립한다.
/// 지도와 custom sheet 자체의 표시·drag 상태는 HomeView가 계속 소유한다.
struct HomePresentationHost<Content: View, SearchContent: View, ExpandedContent: View, RouteGuidanceContent: View, ReviewContent: View>: View {
    let isSearchPresented: Binding<Bool>
    let isExpandedPresented: Binding<Bool>
    let isReviewPresented: Binding<Bool>
    let onExpandedDismiss: () -> Void
    let snackbarMessage: String?
    private let content: Content
    private let searchContent: () -> SearchContent
    private let expandedContent: () -> ExpandedContent
    private let routeGuidanceContent: () -> RouteGuidanceContent
    private let reviewContent: () -> ReviewContent

    init(
        isSearchPresented: Binding<Bool>,
        isExpandedPresented: Binding<Bool>,
        isReviewPresented: Binding<Bool>,
        onExpandedDismiss: @escaping () -> Void,
        snackbarMessage: String?,
        @ViewBuilder content: () -> Content,
        @ViewBuilder searchContent: @escaping () -> SearchContent,
        @ViewBuilder expandedContent: @escaping () -> ExpandedContent,
        @ViewBuilder routeGuidanceContent: @escaping () -> RouteGuidanceContent,
        @ViewBuilder reviewContent: @escaping () -> ReviewContent
    ) {
        self.isSearchPresented = isSearchPresented
        self.isExpandedPresented = isExpandedPresented
        self.isReviewPresented = isReviewPresented
        self.onExpandedDismiss = onExpandedDismiss
        self.snackbarMessage = snackbarMessage
        self.content = content()
        self.searchContent = searchContent
        self.expandedContent = expandedContent
        self.routeGuidanceContent = routeGuidanceContent
        self.reviewContent = reviewContent
    }

    var body: some View {
        content
            .overlay { routeGuidanceContent() }
            .fullScreenCover(isPresented: isSearchPresented) {
                searchContent()
            }
            .fullScreenCover(isPresented: isExpandedPresented, onDismiss: onExpandedDismiss) {
                ZStack {
                    expandedContent()
                        .interactiveDismissDisabled()
                        .fullScreenCover(isPresented: isReviewPresented) {
                            reviewContent()
                                .interactiveDismissDisabled()
                        }
                    routeGuidanceContent()
                }
                .rodiSnackbar(message: snackbarMessage)
            }
    }
}
