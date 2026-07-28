//
//  MyProfileView.swift
//  Rodi
//

import SwiftUI

struct MyProfileView: View {
    let profile: MemberProfile?
    let isLoading: Bool
    let hasCompletedInitialLoad: Bool
    let errorMessage: String?
    let openSettings: () -> Void
    let openDrivingGoal: () -> Void
    let openSavedPlaces: () -> Void
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 0) {
                    profileSection
                        .padding(.horizontal, 16)

                    Rectangle()
                        .fill(RodiColor.primaryMinus100)
                        .frame(height: 2)
                        .padding(.top, 20)

                    savedPlacesRow
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                }
                .padding(.bottom, 114)
            }
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        ZStack {
            Text("프로필")
                .rodiTypography(.headline1)
                .foregroundStyle(RodiColor.black)

            HStack {
                Spacer()
                Button(action: openSettings) {
                    Image("ic_setting")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("설정")
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var profileSection: some View {
        if let profile {
            MyProfileCard(profile: profile, openDrivingGoal: openDrivingGoal)
                .padding(.top, 16)
        } else if isLoading || !hasCompletedInitialLoad {
            MyProfileSkeleton()
                .padding(.top, 16)
        } else {
            VStack(spacing: 12) {
                Text(errorMessage ?? "내 정보를 불러오지 못했어요.")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray700)
                Button(action: retry) {
                    Text("다시 시도")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 227)
            .padding(.top, 16)
        }
    }

    private var savedPlacesRow: some View {
        Button(action: openSavedPlaces) {
            HStack(spacing: 4) {
                Text("저장 목록")
                    .rodiTypography(.body1Medium)
                    .foregroundStyle(RodiColor.black)
                Text("(\(profile?.savedPlaceCount ?? 0))")
                    .rodiTypography(.body1Medium)
                    .foregroundStyle(RodiColor.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(RodiColor.gray700)
                    .frame(width: 20, height: 20)
            }
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, minHeight: 20)
        }
        .buttonStyle(.plain)
        .disabled(profile == nil)
        .accessibilityLabel("저장 목록 \(profile?.savedPlaceCount ?? 0)개")
    }
}

private struct MyProfileSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                placeholder(cornerRadius: 8).frame(width: 90, height: 90)
                VStack(alignment: .leading, spacing: 8) {
                    placeholder().frame(width: 82, height: 18)
                    placeholder().frame(width: 30, height: 12).padding(.top, 4)
                    placeholder().frame(width: 52, height: 16)
                }
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: 8) {
                placeholder().frame(width: 64, height: 12)
                HStack(spacing: 4) {
                    placeholder(cornerRadius: 2).frame(width: 52, height: 20)
                    placeholder(cornerRadius: 2).frame(width: 64, height: 20)
                    placeholder(cornerRadius: 2).frame(width: 44, height: 20)
                }
            }
            .padding(.top, 12)
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 8) {
                placeholder().frame(width: 48, height: 12)
                placeholder().frame(maxWidth: .infinity).frame(height: 16)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, minHeight: 227, maxHeight: 227, alignment: .top)
        .background(RodiColor.gray50)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay { RoundedRectangle(cornerRadius: 8).stroke(RodiColor.primary50, lineWidth: 1) }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) { isAnimating = true }
        }
        .accessibilityLabel("내 정보 불러오는 중")
    }

    private func placeholder(cornerRadius: CGFloat = 4) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(RodiColor.gray200)
            .opacity(isAnimating ? 0.55 : 1)
    }
}

private struct MyProfileCard: View {
    let profile: MemberProfile
    let openDrivingGoal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                RodiLevelProfileImage(level: profile.level, size: 90, backgroundColor: RodiColor.primary100, cornerRadius: 8, imageOffsetY: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.nickname).rodiTypography(.body1SemiBold).foregroundStyle(RodiColor.black).lineLimit(1)
                    Text("레벨").rodiTypography(.caption1Medium).foregroundStyle(RodiColor.gray700).padding(.top, 8)
                    Text(profile.level.displayName).rodiTypography(.body3Medium).foregroundStyle(RodiColor.black)
                }
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("추천 연습 유형").rodiTypography(.caption1Medium).foregroundStyle(RodiColor.gray700)
                HStack(spacing: 4) {
                    ForEach(profile.recommendationTags, id: \.self) { tag in
                        Text(PlacePracticeType.displayName(for: tag))
                            .rodiTypography(.caption1Medium).foregroundStyle(RodiColor.black).lineLimit(1)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(RodiColor.primary50).clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                }
                .lineLimit(1)
            }
            .padding(.top, 12)
            Spacer(minLength: 0)
            Button(action: openDrivingGoal) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("운전 목표").rodiTypography(.caption1Medium).foregroundStyle(RodiColor.gray700)
                    HStack(spacing: 8) {
                        Text(profile.drivingGoal?.isEmpty == false ? profile.drivingGoal! : "아직 설정한 운전 목표가 없어요.")
                            .rodiTypography(.body3Medium).foregroundStyle(RodiColor.black).lineLimit(1)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .medium)).foregroundStyle(RodiColor.gray700)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("운전 목표")
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, minHeight: 227, maxHeight: 227, alignment: .top)
        .background(RadialGradient(colors: [RodiColor.white, RodiColor.primary20], center: .bottom, startRadius: 30, endRadius: 250))
        .overlay(alignment: .topTrailing) {
            Image("img_stamp").resizable().scaledToFit().frame(width: 100, height: 100).opacity(0.2).padding(.top, 15).padding(.trailing, 11).accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay { RoundedRectangle(cornerRadius: 8).stroke(RodiColor.primary50, lineWidth: 1) }
    }
}
