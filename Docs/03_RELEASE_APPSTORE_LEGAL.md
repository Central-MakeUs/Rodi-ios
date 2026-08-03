# RODI Release, App Store, And Legal Notes

This document combines release commands, App Store submission notes, and legal-release safeguards.

The legal source of truth is `Docs/Legal`:

- `TERMS_OF_SERVICE.md`
- `PRIVACY_POLICY.md`
- `LOCATION_BASED_SERVICES_TERMS.md`

Do not use this operational document as the text to publish. Update the three legal documents first, then reflect the approved text in public pages and App Store metadata.

## Fastlane

Rodi uses fastlane only on the local Mac. GitHub Actions is not configured.

Setup:

```sh
bundle install
cp Config/Secrets.example.xcconfig Config/Secrets.prod.local.xcconfig
export FASTLANE_APPLE_ID="Apple Developer Portal email"
```

Production local secrets belong in `Config/Secrets.prod.local.xcconfig`:

```xcconfig
KAKAO_NATIVE_APP_KEY =
KAKAO_REST_API_KEY =
APP_STORE_CONNECT_KEY_ID =
APP_STORE_CONNECT_ISSUER_ID =
APP_STORE_CONNECT_API_KEY_PATH =
APP_STORE_APP_ID =
```

Keep `.p8` files local. `Config/AuthKey_*.p8` and `fastlane/AuthKey_*.p8` are ignored by git.

Commands:

```sh
bundle exec fastlane build_dev
bundle exec fastlane archive_prod
bundle exec fastlane prod_beta
bundle exec fastlane version
```

Use `BUILD_NUMBER` when needed:

```sh
BUILD_NUMBER=2 bundle exec fastlane prod_beta
```

## App Store Connect Checklist

- Support URL must be a public HTTPS page.
- Privacy Label must match actual implementation.
- Current code uses precise location for app functionality.
- Apple/Kakao login entry points, server-backed member data, onboarding profile data, bookmarks, and account withdrawal/recovery are implemented. Privacy Label and legal text must reflect the deployed backend behavior.
- Do not list Firebase, Analytics, IDFA, ads, community, reviews, points, or driving record storage unless implemented in the release build.
- App description must say RODI is map-based course discovery with external navigation handoff, not a full standalone navigation app.
- Country availability can be Korea-focused if desired, because Kakao map usage is Korea-centered.
- Review notes should explain Kakao map/location limitations for foreign testers and simulator locations.

### Privacy Label submission values

App Store Connect의 Privacy Label은 `PrivacyInfo.xcprivacy`만으로 자동 완성되지 않습니다. 배포 직전 서버·SDK 실제 동작을 기준으로 다음 값을 직접 입력합니다. 현재 출시 빌드 기준으로 모두 **사용자와 연결됨**, **추적에 사용 안 함**입니다.

| App Store Connect 데이터 유형 | 실제 데이터 | 목적 | 사용자와 연결 | 추적 |
| --- | --- | --- | --- | --- |
| User ID | 소셜 로그인 기반 내부 회원 식별자 | App Functionality | 예 | 아니오 |
| Other User Content | 운전 목표 | App Functionality | 예 | 아니오 |
| Other Data | 운전 경험, 선호 연습 유형, 차종, 계산된 레벨 | App Functionality, Product Personalization | 예 | 아니오 |
| Product Interaction | 북마크 및 저장 목록 | App Functionality | 예 | 아니오 |
| Coarse Location | 대략적 현재 위치 또는 지도 뷰포트 좌표 | App Functionality | 예 | 아니오 |
| Precise Location | 정확한 현재 위치 또는 지도 뷰포트 좌표 | App Functionality | 예 | 아니오 |

Firebase Analytics, 광고 식별자, 푸시, Crashlytics, 커뮤니티, 리뷰, 포인트, 운전 기록은 이번 출시 빌드에서 처리하지 않으므로 입력하지 않습니다. 소셜 제공자로부터 이메일을 서버에 별도로 보관하는 정책을 도입했다면, 배포 전에 Contact Info의 Email Address 항목을 추가로 검토합니다.

### App Review Notes template

```text
- Rodi는 한국 내 운전 연습 코스·주차장 탐색 앱입니다.
- 로그인 없이 ‘둘러보기’로 지도와 공개 장소 목록을 확인할 수 있습니다.
- 회원 기능은 카카오 또는 Sign in with Apple 로그인 후 이용할 수 있습니다.
- 위치 권한을 거부해도 공개 장소 탐색은 가능하며, 현재 위치 기반 거리 정렬과 내 위치 이동만 제한됩니다.
- 지도는 Kakao Maps 기반이므로 해외 또는 Simulator 위치에서는 일부 지도·위치 동작이 제한될 수 있습니다.
```

Privacy Label must be confirmed against the actual backend and third-party SDK behavior. Do not copy the former MVP-only suggestion without verifying whether location, member profile, onboarding, and bookmark data are linked to a user.

## Current Data Handling

Current implementation:
- supports guest browsing and Kakao/Apple social login
- stores authentication tokens in Keychain, incomplete onboarding drafts, recent login provider, and onboarding display state in UserDefaults
- sends current location or viewport coordinates to the Rodi server for place discovery and can pass route coordinates to Kakao services
- provides member onboarding profiles, calculated driving level, bookmarks, saved places, my page, driving-goal updates, account withdrawal, and account recovery
- does not store location history as a separate movement history
- does not implement review, community, points, ads, or driving-record features

## Legal Publication Checklist

- Finalize the effective date in all three `Docs/Legal` documents.
- Resolve their marked TODO items with server operations and legal review before public publication.
- Keep terms, privacy policy, location terms, App Store Privacy Label, and the deployed backend behavior aligned.
- Public pages should include app name, support email, links to all three documents, and the driving-practice safety disclaimer.

## Location Business Safeguards

This section is for location-based service business filing preparation, not App Store submission itself.

Current implementation-aligned statements:
- location permission is requested only while using the app
- RODI server receives place-query coordinates but does not claim to store a separate location history
- Kakao API calls use HTTPS
- API keys are excluded from version control through local secrets
- Release logs must not expose full keys or precise coordinates

Do not claim unimplemented Firebase, analytics, IDFA, reviews, community, points, or driving-record collection.

Before filing, confirm:
- location information manager
- privacy manager
- support email
- support URL
- location collection/use/provision record retention obligation
- Kakao REST key platform restrictions and a future server-proxy migration for the client-bundled key
- whether the business filing is required and completed

## Release Safety

- Keep `Config/Secrets.dev.local.xcconfig` and `Config/Secrets.prod.local.xcconfig` out of git.
- Keep `.p8` files out of git.
- Do not expose full API keys in build logs.
- Archive/TestFlight verification does not replace App Store legal and metadata review.
- Kakao 개발자 콘솔에서 REST API 키의 앱·플랫폼·도메인/허용 호출 제한을 배포 전 확인한다. 앱 번들에 포함되는 REST API 키는 비밀값으로 간주하지 않는다.
