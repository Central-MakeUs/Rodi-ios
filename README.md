<h1 align="center">Rodi</h1>

<table align="center">
<tr>
<td align="center"><img width="1320" height="2868" alt="1" src="https://github.com/user-attachments/assets/7616cb2d-ad89-4c68-bcc7-85d0b9e46e1d" /></td>
<td align="center"><img width="1320" height="2868" alt="2" src="https://github.com/user-attachments/assets/1548f15a-c8d0-477a-95f3-55d7c23bcd05" /></td>
<td align="center"><img width="1320" height="2868" alt="3" src="https://github.com/user-attachments/assets/261e462f-e702-459b-b801-268a3a5eda88" /></td>
<td align="center"><img width="1320" height="2868" alt="4" src="https://github.com/user-attachments/assets/5ca29030-5678-49ab-9aee-f60564932828" /></td>
<td align="center"><img width="1320" height="2868" alt="5" src="https://github.com/user-attachments/assets/0fb73daf-0839-4677-a1b3-e9f15843e886" /></td>
</tr>
</table>

<p align="center">
<b>Rodi</b>는 <b>초보 운전자와 장롱면허 운전자</b>를 위한<br/>
맞춤형 운전 연습 장소 및 코스 탐색 서비스입니다.
</p>

<p align="center">
현 위치를 기준으로 주변 운전 연습 코스, 공영 주차장, 경유지가 포함된 경로를 확인하고<br/>
카카오맵·카카오내비와 연동해 바로 길안내를 시작할 수 있습니다.
</p>

<p align="center">
<a href="https://apps.apple.com/kr/app/id6785479816">
<img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg"
alt="Download on the App Store"
height="48" />
</a>
</p>

<br/>

# 서비스 소개

Rodi는 운전 연습이 막막한 초보 운전자에게 주변 연습 코스와 주차 연습 장소를 지도 기반으로 제공합니다.

- 카카오·Apple 소셜 로그인 및 비회원 둘러보기
- 운전 경험·선호 정보 기반 온보딩과 운전 레벨, 추천 연습 유형 안내
- 현재 위치 또는 지도 화면 범위 기반 코스·주차장 탐색과 재검색
- 줌 단계별 마커 클러스터링, 코스·주차장 상세 정보 및 경로 미리보기
- 출발지, 경유지, 도착지를 포함한 코스 경로와 카카오맵·카카오내비 길안내 연동
- 직접 찾은 장소를 기반으로 한 사용자 코스 등록
- 연습기록, 후기 작성·수정, 북마크·저장 목록·운전 목표를 관리하는 마이페이지

> Rodi는 운전 연습에 참고할 수 있는 코스 정보를 제공하는 서비스이며, 실제 도로 상황과 안전을 보장하지 않습니다. 사용자는 항상 교통 법규와 현장 상황을 우선해야 합니다.
> 

> 이 README는 공개 서비스 소개와 개발 진입점 안내를 위한 문서입니다. 구현 구조·API 계약·배포 정책의 원본은 각각 `Docs/Architecture/ARCHITECTURE.md`, `Docs/API/API_SWAGGER.md`, `Docs/Release/RELEASE.md`와 현재 코드에서 확인합니다.

<br/>

# 개발 구조

```text
Rodi/
  App/           # 앱 시작·의존성 조립
  Core/          # 공통 기술 기반
  Data/          # 외부·로컬 데이터 구현
  Domain/        # 제품 모델·기능 계약
  Presentation/  # 화면·상태·사용자 상호작용
  Resources/     # 이미지·폰트·실행 리소스
RodiTests/       # XCTest
```

SwiftUI와 MVI를 기반으로 화면 상태를 관리하며, UIKit 기반 지도 SDK는 Adapter 경계에서 연결합니다. 세부 폴더·상태 소유권·API·저장 정책은 아래 문서와 현재 코드에서 확인합니다.

- [아키텍처와 책임 경계](Docs/Architecture/ARCHITECTURE.md)
- [UI·Figma 구현](Docs/Guides/UI_FIGMA.md)
- [API·Swagger 연결](Docs/API/API_SWAGGER.md)
- [배포·개발 환경 설정](Docs/Release/RELEASE.md)

# 개발 환경

`Rodi Dev` / Debug는 개발·내부 검증용, `Rodi` / Release는 운영 배포용입니다. 환경별 실제 설정은 `Config/Dev.xcconfig`·`Config/Prod.xcconfig`, 빌드·업로드 명령은 `fastlane/Fastfile`에서 확인합니다. 실제 키와 Firebase plist는 local config 및 Git ignore로 관리합니다.
