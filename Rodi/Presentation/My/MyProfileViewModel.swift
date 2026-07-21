//
//  MyProfileViewModel.swift
//  Rodi
//

import Combine
import Foundation

@MainActor
final class MyProfileViewModel: ObservableObject {
    @Published private(set) var profile: MemberProfile?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let memberRepository: MemberRepository

    init(memberRepository: MemberRepository) {
        self.memberRepository = memberRepository
    }

    func loadIfNeeded() async {
        guard profile == nil, !isLoading else { return }
        await load()
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            profile = try await memberRepository.fetchMyProfile()
            RodiLogger.info("My profile loaded")
        } catch {
            errorMessage = "내 정보를 불러오지 못했어요."
            RodiLogger.warning("My profile load failed. error=\(error.localizedDescription)")
        }

        isLoading = false
    }

    func replaceProfile(_ profile: MemberProfile) {
        self.profile = profile
        errorMessage = nil
    }
}
