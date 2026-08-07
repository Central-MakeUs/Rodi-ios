# RODI Release

이 문서는 Dev/Prod 환경, TestFlight, 관측 SDK, 개인정보 및 App Store 출시 게이트를 다루며, 변동값은 아래 live source에서 확인한다.

빌드 설정은 `Config/Dev.xcconfig`·`Config/Prod.xcconfig`, 배포 명령은 `fastlane/Fastfile`,
관측·개인정보·공개 URL은 `Rodi/Core/Analytics`, `Rodi/Core/Service/ClarityConfiguration.swift`,
`Rodi/Resources/PrivacyInfo.xcprivacy`, `Rodi/Core/Service/LegalDocument.swift`가 원본이다.

## Environment Contract

| 구분 | Dev | Prod |
| --- | --- | --- |
| Scheme / Configuration | `Rodi Dev` / `Debug` | `Rodi` / `Release` |
| Bundle ID | `com.dororong.rodi.dev` | `com.dororong.rodi` |
| 표시명 / 아이콘 | `Rodi Dev` / `AppIconDev` | `Rodi` / `AppIcon` |
| 환경값 | `RODI_ENVIRONMENT=dev` | `RODI_ENVIRONMENT=prod` |
| 배포 | 로컬, Dev TestFlight | TestFlight, App Store |
| 업데이트 검사 | 비활성 | 활성 |

두 xcconfig의 API URL은 현재 동일한 운영 endpoint를 가리킨다. Dev에서도 테스트 계정을
사용하고 탈퇴·복구처럼 서버 상태를 오래 남기는 검증을 운영 사용자 계정으로 수행하지 않는다.
API URL이 비어 있으면 운영으로 fallback하지 않으며, 환경별 버전과 build number는 xcconfig가 원본이다.

## Local Configuration And Firebase

추적 파일에는 기본값과 빈 자리만 두고 실제 값은 다음 로컬 파일에 둔다.

```sh
cp Config/Secrets.example.xcconfig Config/Secrets.dev.local.xcconfig
cp Config/Secrets.example.xcconfig Config/Secrets.prod.local.xcconfig
```

- Kakao 키와 App Store Connect key ID·issuer ID·`.p8` 경로·App Store app ID는
  해당 `Secrets.*.local.xcconfig`에만 둔다.
- `.p8`, `Secrets.*.local.xcconfig`, 실제 `GoogleService-Info.plist`는 커밋하지 않는다.
- Firebase plist는 Dev가 `Config/Firebase/Dev/GoogleService-Info.plist`, Prod가
  `Config/Firebase/Prod/GoogleService-Info.plist`를 사용하며 `BUNDLE_ID`가 일치해야 한다.
- `Prepare Firebase Configuration`은 선택된 파일만 앱 번들에 복사한다. 파일이 없으면
  빌드를 실패시키며 다른 환경 plist로 fallback하지 않는다.
- `Upload Crashlytics Symbols`는 Firebase 복사 뒤 실행된다. archive 후 dSYM 업로드 결과를 확인한다.
- Kakao client key는 앱 번들에 포함되므로 서버 비밀로 간주할 수 없다. 콘솔의 앱·bundle ID·
  플랫폼 제한을 적용하고, 키 자체는 여전히 저장소와 로그에 남기지 않는다.

## Authentication Environment Separation

- Kakao Developers에 Dev와 Prod bundle ID를 각각 허용하고, 각 빌드의
  `kakao$(KAKAO_NATIVE_APP_KEY)` URL scheme과 사용 중인 Kakao 앱 설정이 일치하는지 확인한다.
- Kakao 앱을 공유한다면 두 bundle ID 허용을 의도적으로 등록한다. 공유 여부를 추측하지 않는다.
- Apple Developer에 두 bundle ID의 App ID를 각각 만들고 Sign in with Apple capability를 켠다.
- 백엔드가 Apple authorization code와 Kakao access token을 검증할 때 해당 환경의 client/app
  설정을 허용해야 한다. Dev callback·client 설정을 Prod 값으로 암묵적으로 대체하지 않는다.
- 두 환경에서 앱 로그인, 웹 fallback, 앱 복귀 callback, 서버 로그인·복구를 실기기로 검증한다.

## Analytics, Crash Reporting, And Clarity

현재 앱은 시작 시 Firebase를 구성하고 xcconfig의 flag에 따라 Analytics collection과 Clarity를
활성화한다. Crashlytics와 Performance SDK도 target에 연결되어 있다. 출시 전에 Firebase와
Clarity가 환경별 프로젝트로 전송되는지 확인한다.

- 이벤트 이름과 허용 parameter의 원본은 `RodiAnalytics.swift`다. 이벤트 전체 목록을 문서에 복제하지 않는다.
- 이벤트는 확정된 사용자 의도나 성공 결과에서 한 번만 기록하고 low-cardinality 범주값만 사용한다.
- Analytics parameter·user property, Crashlytics key/log, Clarity custom event에 검색어 원문,
  닉네임, 운전 목표 원문, 이메일, 전화번호, 회원 ID, OAuth credential, access/refresh token,
  위도·경도, viewport, GPS 경로, 장소 이름·ID를 넣지 않는다.
- Crashlytics에는 예상하지 못한 기술 실패와 `endpoint_category`, HTTP status family 같은
  범주만 기록한다. 로그인 취소·권한 거부 같은 정상 흐름은 non-fatal로 보내지 않는다.
- Clarity에서는 Kakao 지도·현재 위치, 입력 필드, 프로필, 인증, 탈퇴·복구 화면을 마스킹한다.
  지원 범위 실기기에서 탭·지도 drag·sheet·키보드 회귀와 녹화 결과를 직접 확인한다.
- Prod Clarity를 켜기 전에 세션 replay, masking, 제3자 처리 사실이 공개 개인정보처리방침과
  Privacy Label에 반영되어야 한다. 현재 Prod flag가 켜져 있으므로 미확인 상태는 출시 차단이다.

## Secrets And Release Logs

- Release log에 전체 API key, OAuth/access/refresh token, authorization code, 이메일, 닉네임,
  정확한 좌표나 원본 서버 응답을 출력하지 않는다.
- `RodiLogger.coordinate`의 Release 마스킹만 믿지 말고 문자열 보간, SDK verbose log,
  `NSError.localizedDescription`, network interceptor를 archive 기준으로 점검한다.
- Release logger는 warning 이상만 출력해야 하며 Clarity log level은 `none`을 유지한다.
- Dev 진단 로그도 공유 채널이나 이슈에 붙이기 전 같은 민감값을 제거한다.
- 배포 전에 `git status`, tracked files, staged diff에서 local xcconfig, Firebase plist,
  `.p8`, 임시 인증 파일이 없는지 확인한다.

## Fastlane And TestFlight

Fastlane은 현재 로컬 Mac에서 실행하며 lane 정의는 `fastlane/Fastfile`이 원본이다.

```sh
bundle install
bundle exec fastlane version
bundle exec fastlane build_dev
bundle exec fastlane dev_beta
bundle exec fastlane archive_prod
bundle exec fastlane prod_beta
```

- `build_dev`는 `Rodi Dev` Debug simulator build만 수행한다.
- `archive_prod`는 `Rodi` Release archive를 만들며 업로드하지 않는다.
- `dev_beta`와 `prod_beta`는 각 App Store Connect build train의 다음 번호를 계산해 archive에만
  주입하고 TestFlight에 업로드한다. 프로젝트 파일의 build number를 변경하지 않는다.
- 두 beta lane 모두 해당 환경 local secrets의 App Store app ID와 API key가 필요하다.
- `BUILD_NUMBER=...` 방식은 현재 lane 계약이 아니다. 번호 정책을 바꾸려면 Fastfile부터 수정한다.

## App Store, Privacy, And Legal Gates

`PrivacyInfo.xcprivacy`는 현재 User ID, 사용자 콘텐츠·기타 데이터, 제품 상호작용,
대략적·정확한 위치를 선언한다. 이 manifest가 App Store Connect Privacy Label을 자동으로
완성하지 않으므로, 배포 backend와 Firebase·Crashlytics·Performance·Clarity의 실제 동작을
기준으로 목적, 사용자 연결 여부, 추적 여부를 다시 확인한다.

- IDFA나 앱 간 추적이 없다는 사실을 확인한 경우에만 “추적에 사용 안 함”으로 제출한다.
- 계정, 온보딩 profile, bookmark, 위치 query, 분석·session replay의 실제 처리가 Label,
  manifest, 공개 개인정보처리방침에서 서로 일치해야 한다.
- `LegalDocument.swift`의 URL은 앱 연결점일 뿐 승인된 법무 원문이 아니다.
- 저장소에는 권위 있는 서비스 이용약관·개인정보처리방침·위치기반서비스 이용약관 원문이 없다.
  승인 원문과 공개본의 정합성을 확인할 수 없으면 출시를 차단한다.
- 세 문서와 support URL이 로그인 없는 외부 브라우저에서 HTTPS로 열리고, 시행일·운영 주체·
  연락처·위치 처리·분석/세션 replay·계정 삭제 정책이 실제 동작과 일치해야 한다.
- App Store Support URL과 Privacy Policy URL도 같은 공개본을 가리키는지 확인한다.
- 설명과 review notes는 RODI를 운전 연습 장소·코스 탐색과 외부 길안내 handoff로 표현한다.
  안전·사고 방지·도로 상태·주차 가능 여부를 보장한다고 표현하지 않는다.
- 해외 reviewer를 위해 한국 중심 Kakao 지도, simulator 위치 제약, guest browsing,
  위치 권한 거부 시 제한 범위를 review notes에 설명한다.

## Release Verification Matrix

| 확인 | Dev Debug | Prod Release |
| --- | --- | --- |
| Identity | Dev scheme·bundle ID·표시명·아이콘 | Prod scheme·bundle ID·표시명·아이콘 |
| Firebase | Dev plist와 Dev console | Prod plist, Prod console, dSYM |
| Auth | Dev Kakao/Apple 설정과 callback | Prod Kakao/Apple 설정과 callback |
| Observability | DebugView, non-fatal, masking 회귀 | 수집 목적, masking, 로그·symbol 검증 |
| Install | Prod와 동시 설치, 테스트 계정 | 업그레이드·업데이트 URL |
| TestFlight | Dev app record에만 업로드 | Prod app record에만 업로드 |
| Privacy | 테스트 데이터에 민감값 없음 | Label·manifest·공개 고지 일치 |
| Legal | 공개본 접근 smoke test | 승인 원문·공개본·metadata 일치 |

누락된 Firebase 설정, 잘못된 callback, secret 포함, 민감한 Release log, Clarity 미마스킹, Privacy Label 불일치, 접근 불가하거나 승인 여부를 확인할 수 없는 법무·지원 문서는 모두 출시 차단이다.
