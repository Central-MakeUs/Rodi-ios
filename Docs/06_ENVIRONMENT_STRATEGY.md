# RODI Dev And Prod Environment Strategy

Rodi는 단일 `Rodi` 타깃과 두 개의 Xcode Configuration으로 환경을 분리한다.

| 구분 | Dev | Prod |
| --- | --- | --- |
| Xcode Configuration | `Debug` | `Release` |
| Scheme | `Rodi Dev` | `Rodi` |
| Bundle ID | `com.dororong.rodi.dev` | `com.dororong.rodi` |
| 표시명 | `Rodi Dev` | `Rodi` |
| 아이콘 세트 | `AppIconDev` | `AppIcon` |
| 마케팅 버전 / 기본 빌드 | `1.0.0 (1)` | `1.1.0 (3)` |
| 배포 | Xcode, Dev TestFlight | TestFlight, App Store |
| API | `https://api.stillstar.store` | `https://api.stillstar.store` |
| App Store 버전 검사 | 사용 안 함 | 사용 |

`com.dororong.rodi`는 기존 운영 bundle ID로 유지한다. Dev는 별도 bundle ID를 사용하므로
두 앱을 같은 기기에 설치할 수 있고 UserDefaults·기본 Keychain 영역도 분리된다.

## Configuration Files

```text
Config/
├── Dev.xcconfig                    # Git 추적: Debug 환경값
├── Prod.xcconfig                   # Git 추적: Release 환경값
├── Secrets.example.xcconfig         # Git 추적: 키 템플릿
├── Secrets.dev.local.xcconfig       # Git ignore: Dev SDK 키
├── Secrets.prod.local.xcconfig      # Git ignore: Prod SDK·Fastlane 키
└── Firebase/
    ├── Dev/GoogleService-Info.plist # Git ignore: Dev Firebase 설정
    └── Prod/GoogleService-Info.plist# Git ignore: Prod Firebase 설정
```

`Dev.xcconfig`과 `Prod.xcconfig`은 bundle ID, 표시명, 앱 아이콘, API URL,
`RODI_ENVIRONMENT`를 정의한다. 실제 Kakao 키, App Store Connect `.p8` 경로와
Fastlane 인증값은 local secret 파일에서만 제공한다.

xcconfig에서 URL의 `//`는 주석으로 해석될 수 있으므로 API URL은
`https:/$()/api.stillstar.store` 형태로 작성한다. 빌드 결과에는 정상적인
`https://api.stillstar.store`로 주입된다.

기존 `Config/Secrets.local.xcconfig`의 실제 값을 자동으로 이전하지 않는다. 각 개발자는
아래처럼 수동으로 복사한 뒤 필요한 값을 입력한다.

```sh
cp Config/Secrets.example.xcconfig Config/Secrets.dev.local.xcconfig
cp Config/Secrets.example.xcconfig Config/Secrets.prod.local.xcconfig
```

실제 키, `.p8`, `Secrets.*.local.xcconfig`는 Git에 추가하지 않는다.

## Firebase

Firebase는 Dev 프로젝트(`rodi-dev`)와 Prod 프로젝트(`rodi-prod`)를 분리해 사용한다.
각 `GoogleService-Info.plist`의 `BUNDLE_ID`는 해당 환경의 bundle ID와 일치해야 한다.

- Dev: `com.dororong.rodi.dev` → `Config/Firebase/Dev/GoogleService-Info.plist`
- Prod: `com.dororong.rodi` → `Config/Firebase/Prod/GoogleService-Info.plist`

`Prepare Firebase Configuration` Build Phase는 현재 xcconfig의
`FIREBASE_GOOGLE_SERVICE_INFO_PATH` 파일 하나만 앱 번들의
`GoogleService-Info.plist`로 복사한다. 원본 파일이 없으면 빌드는 실패하며, Prod
설정으로 fallback하지 않는다. `Upload Crashlytics Symbols`는 이 복사 단계 뒤 마지막
Build Phase에서 실행된다.

Analytics, Crashlytics, Performance Monitoring을 SDK로 연결했지만 제품 이벤트 설계와
사용자 식별값 설정은 [05_ANALYTICS_AND_OBSERVABILITY_PLAN.md](05_ANALYTICS_AND_OBSERVABILITY_PLAN.md)를
기준으로 별도 진행한다.

Clarity는 `CLARITY_ENABLED`, `CLARITY_PROJECT_ID`, `CLARITY_LOG_LEVEL`로 분리한다.
Dev는 `xuel7v1h92`, Prod는 `xuepsqfoyk` 프로젝트를 사용한다. Prod 활성화 전 개인정보·위치기반
서비스 약관과 App Store Privacy Label의 분석·세션 리플레이 고지는 별도로 검토한다.

## Required Console Setup

Dev 앱을 실기기에서 인증하기 전에 다음 외부 설정을 완료한다.

1. Apple Developer에서 `com.dororong.rodi.dev` App ID를 만들고 Sign in with Apple을
   활성화한다.
2. Kakao Developers에서 `com.dororong.rodi.dev`를 iOS 플랫폼 허용 목록에 추가한다.
3. Dev 키와 Prod 키를 각각 local secret 파일에 넣는다. 동일 Kakao 앱 키를 사용할 수
   있는지는 Kakao 콘솔 설정으로 확인한다.

Dev는 운영 API를 공유하므로 전용 Kakao/Apple 테스트 계정만 사용한다. 탈퇴·복구처럼
상태를 오래 남기는 검증은 운영 사용자 계정으로 수행하지 않는다.

## App Behavior

- `AppEnvironment`는 `RODI_ENVIRONMENT` Info.plist 값만 읽어 현재 환경을 판단한다.
- API URL은 각 xcconfig에 명시한다. 누락 시 운영 URL로 자동 fallback하지 않는다.
- App Store 업데이트 검사는 Prod에서만 실행한다.
- `Rodi Dev` Scheme은 Debug로 Run/Test/Analyze/Archive하며 Dev TestFlight 배포에도 사용한다.
- `Rodi` Scheme은 Release로 Run/Test/Analyze/Profile/Archive하며 운영 배포용이다.

## Fastlane

```sh
bundle exec fastlane build_dev      # Rodi Dev simulator build
bundle exec fastlane dev_beta       # Dev TestFlight upload
bundle exec fastlane archive_prod   # 운영 archive
bundle exec fastlane prod_beta      # 운영 TestFlight upload
bundle exec fastlane version
```

`dev_beta`는 `Config/Secrets.dev.local.xcconfig`의 App Store Connect 자격과
`APP_STORE_APP_ID = 6796222178`을 사용한다. `prod_beta`는
`Config/Secrets.prod.local.xcconfig`만 사용한다. 동일한 App Store Connect API `.p8`를
두 local secret 파일에서 참조할 수 있다.

Dev와 Prod의 `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`은 각 환경 xcconfig에서
독립 관리한다. `dev_beta`와 `prod_beta`는 각 App Store Connect 앱의 해당 버전 TestFlight
build train을 조회해 다음 빌드 번호를 archive에만 주입하므로, 서로의 build number나
프로젝트 파일을 변경하지 않는다.

## Validation Checklist

- [ ] Debug 빌드가 `com.dororong.rodi.dev`, `Rodi Dev`, `RODI_ENVIRONMENT=dev`를 사용한다.
- [ ] Release 빌드가 `com.dororong.rodi`, `Rodi`, `RODI_ENVIRONMENT=prod`를 사용한다.
- [ ] Dev에서 App Store 업데이트 팝업이 표시되지 않는다.
- [ ] Dev/Prod가 같은 기기에 동시에 설치된다.
- [ ] `dev_beta` 업로드 빌드가 App Store Connect의 `Rodi - dev` 레코드에만 표시된다.
- [ ] Apple 로그인, Kakao 앱·웹 로그인, 지도, 길안내를 Dev와 Prod 실기기에서 각각 검증한다.
- [ ] Dev/Prod 앱 번들의 `GoogleService-Info.plist`가 각각 올바른 Firebase 프로젝트를 가리킨다.
- [ ] 실제 키, Firebase plist와 `.p8`이 Git status, tracked files, 커밋 diff에 포함되지 않는다.

Clarity 운영은 [05_ANALYTICS_AND_OBSERVABILITY_PLAN.md](05_ANALYTICS_AND_OBSERVABILITY_PLAN.md)의
마스킹·법무 검토 기준을 따른다.
