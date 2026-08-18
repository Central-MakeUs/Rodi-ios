import SwiftUI

/// 코스 등록의 출발지·도착지·경유지 입력을 위한 검색 화면이다.
struct CourseRegistrationPlaceSearchView: View {
    @StateObject private var store = Store(
        state: CourseRegistrationPlaceSearchReducer.State(initialQuery: ""),
        reducer: CourseRegistrationPlaceSearchReducer()
    )
    @FocusState private var isSearchFieldFocused: Bool
    @State private var recentSearches: [CourseRegistrationRecentSearch] = []
    @State private var isClosing = false

    let closeAction: () -> Void
    let resultSelectedAction: (CourseRegistrationPlaceSearchItem) -> Void
    private let recentSearchStore = CourseRegistrationRecentSearchStore()

    var body: some View {
        VStack(spacing: 0) {
            searchField
            searchResults
        }
        .background(RodiColor.white.ignoresSafeArea())
        .onAppear {
            recentSearches = recentSearchStore.load()
            store.send(.appeared)
            DispatchQueue.main.async {
                isSearchFieldFocused = true
            }
        }
    }
}

private extension CourseRegistrationPlaceSearchView {
    var searchField: some View {
        HomeSearchTextField(
            text: Binding(
                get: { store.state.query },
                set: { store.send(.queryChanged($0)) }
            ),
            isFocused: $isSearchFieldFocused,
            placeholder: "장소 · 도로명 검색",
            backAction: dismissKeyboardThenClose,
            submitAction: {
                isSearchFieldFocused = false
                store.send(.searchTapped)
            }
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .background(RodiColor.white)
    }

    var searchResults: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if store.state.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    recentSearchSection
                } else {
                    regionResults

                    if !store.state.regions.isEmpty, showsPlaceSection {
                        RodiColor.primaryMinus100
                            .frame(height: 4)
                    }

                    placeResults
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFieldFocused = false
        }
    }

    var regionResults: some View {
        ForEach(store.state.regions) { region in
            Button {
                isSearchFieldFocused = false
                recentSearches = recentSearchStore.save(.init(
                    id: UUID(),
                    title: region.displayName,
                    kind: .region,
                    coordinate: nil
                ))
                store.send(.regionTapped(region))
            } label: {
                    resultRow(
                        title: region.displayName,
                        imageName: "ic_search",
                        usesTemplateRendering: true,
                        accessibilityLabel: "\(region.displayName) 검색"
                    )
            }
            .buttonStyle(.plain)

            if region.id != store.state.regions.last?.id {
                Divider().overlay(RodiColor.primaryMinus100)
            }
        }
    }

    @ViewBuilder
    var placeResults: some View {
        if store.state.query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
            EmptyView()
        } else if store.state.isPlaceLoading {
            ProgressView()
                .tint(RodiColor.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        } else if let errorMessage = store.state.placeErrorMessage {
            VStack(spacing: 12) {
                messageState(errorMessage)
                Button {
                    store.send(.searchTapped)
                } label: {
                    Text("다시 시도")
                        .rodiTypography(.buttonMedium)
                        .foregroundStyle(RodiColor.primary)
                }
                    .buttonStyle(.plain)
            }
            .padding(.vertical, 24)
        } else if store.state.hasSearchedPlaces, store.state.places.isEmpty, store.state.regions.isEmpty {
            messageState("검색 결과가 없어요.")
        } else {
            ForEach(store.state.places) { place in
                Button {
                    isSearchFieldFocused = false
                    recentSearches = recentSearchStore.save(.init(
                        id: UUID(),
                        title: place.title,
                        kind: .place,
                        coordinate: place.coordinate
                    ))
                    resultSelectedAction(place)
                } label: {
                    resultRow(
                        title: place.title,
                        imageName: "ic_map_pin",
                        usesTemplateRendering: false,
                        accessibilityLabel: "\(place.title) 장소 검색 결과"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint("지도에서 핀 위치를 조정할 수 있어요.")
                .onAppear {
                    guard place.id == store.state.places.last?.id else { return }
                    store.send(.loadNextPage)
                }
                Divider().overlay(RodiColor.primaryMinus100)
            }

            if store.state.isLoadingNextPage {
                ProgressView()
                    .tint(RodiColor.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
    }

    var showsPlaceSection: Bool {
        store.state.isPlaceLoading
            || store.state.placeErrorMessage != nil
            || !store.state.places.isEmpty
    }

    @ViewBuilder
    var recentSearchSection: some View {
        if !recentSearches.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("최근 검색어")
                        .rodiTypography(.caption2Medium)
                        .foregroundStyle(RodiColor.gray700)

                    Spacer()

                    Button {
                        recentSearchStore.removeAll()
                        recentSearches = []
                    } label: {
                        Text("전체 삭제")
                            .rodiTypography(.caption2Medium)
                            .foregroundStyle(RodiColor.gray500)
                    }
                    .buttonStyle(.plain)
                }

                LazyVStack(spacing: 0) {
                    ForEach(recentSearches) { search in
                        HStack(spacing: 12) {
                            Button {
                                selectRecentSearch(search)
                            } label: {
                                HStack(spacing: 10) {
                                    Group {
                                        if search.kind == .region {
                                            Image("ic_search")
                                                .resizable()
                                                .renderingMode(.template)
                                                .foregroundStyle(RodiColor.gray600)
                                        } else {
                                            Image("ic_map_pin")
                                                .resizable()
                                        }
                                    }
                                    .frame(width: 20, height: 20)
                                    .accessibilityHidden(true)

                                    Text(search.title)
                                        .rodiTypography(.body1Medium)
                                        .foregroundStyle(RodiColor.gray800)
                                        .lineLimit(1)

                                    Spacer(minLength: 0)
                                }
                                .frame(maxWidth: .infinity, minHeight: 61, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                recentSearches = recentSearchStore.remove(id: search.id)
                            } label: {
                                Image("ic_close")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundStyle(RodiColor.black)
                                    .frame(width: 20, height: 20)
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(search.title) 삭제")
                        }

                        Divider().overlay(RodiColor.primaryMinus100)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
        }
    }

    func resultRow(
        title: String,
        imageName: String,
        usesTemplateRendering: Bool,
        accessibilityLabel: String
    ) -> some View {
        HStack(spacing: 12) {
            Group {
                if usesTemplateRendering {
                    Image(imageName)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(RodiColor.gray600)
                } else {
                    Image(imageName)
                        .resizable()
                }
            }
                .frame(width: 20, height: 20)
                .accessibilityHidden(true)
            Text(title)
                .rodiTypography(.body1Medium)
                .foregroundStyle(RodiColor.gray800)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    func messageState(_ message: String) -> some View {
        Text(message)
            .rodiTypography(.body3Medium)
            .foregroundStyle(RodiColor.gray600)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
    }

    func selectRecentSearch(_ search: CourseRegistrationRecentSearch) {
        isSearchFieldFocused = false
        switch search.kind {
        case .region:
            store.send(.sampleSearchTapped(search.title))
        case .place:
            guard let coordinate = search.coordinate else {
                store.send(.sampleSearchTapped(search.title))
                return
            }
            resultSelectedAction(.init(
                id: "recent-\(search.id.uuidString)",
                title: search.title,
                address: search.title,
                coordinate: coordinate,
                category: nil,
                phone: nil
            ))
        }
    }

    func dismissKeyboardThenClose() {
        guard !isClosing else { return }
        isClosing = true
        isSearchFieldFocused = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            closeAction()
        }
    }
}
