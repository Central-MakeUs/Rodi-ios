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

- 현 위치 기반 주변 운전 연습 코스 탐색
- 전체, 3km, 5km, 10km 반경 필터
- 코스 연습 유형, 한 줄 설명 제공
- 출발지, 경유지, 도착지를 포함한 경로 미리보기
- 공영 주차장 위치 및 상세 정보 제공
- 카카오맵, 카카오내비 외부 앱 연동

> Rodi는 운전 연습에 참고할 수 있는 코스 정보를 제공하는 서비스이며, 실제 도로 상황과 안전을 보장하지 않습니다. 사용자는 항상 교통 법규와 현장 상황을 우선해야 합니다.
> 

<br/>

# 폴더 구조

```bash
|-- Rodi
    |-- App                         # 앱 진입점, RootView, 앱 초기화
    |
    |-- Core                        # 공통 인프라 및 기반 코드
    |   |-- Components              # 공통 UI 컴포넌트 확장 후보
    |   |-- DesignSystem            # 색상, 타이포그래피, 폰트 등록
    |   |-- Extension               # Swift / SwiftUI 공통 Extension
    |   |-- Feedback                # 앱 업데이트 체크, 햅틱 등 사용자 피드백
    |   |-- MVICore                 # Store, Reducer, Effect 등 MVI 기반 코드
    |   |-- Network                 # 네트워크 매니저, 인터셉터, 토큰 저장
    |   |-- Service                 # Logger, LegalDocument 등 공통 서비스
    |   |-- Setting                 # 앱 환경설정, 외부 SDK 설정
    |
    |-- Data                        # 외부/로컬 데이터 구현 레이어
    |   |-- Local                   # 로컬 저장소 관련 구현
    |   |-- Remote                  # 서버 API 연동 구현
    |
    |-- Domain                      # 앱 핵심 도메인 계약 및 모델
    |   |-- Auth                    # 인증 도메인
    |   |-- Entity                  # 도메인 엔티티
    |   |-- Repository              # Repository 인터페이스
    |
    |-- Presentation                # 화면 및 사용자 인터랙션 레이어
    |   |-- Home                    # 홈 지도, 코스/주차장 탐색, 바텀싯
    |   |-- Onboarding              # 약관, 닉네임, 운전 경험, 위치 권한 온보딩
    |
    |-- Resources                   # 앱 리소스
        |-- Assets.xcassets         # 이미지, 아이콘 에셋
        |-- Data                    # 로컬 JSON 데이터
        |-- Fonts                   # Pretendard 폰트
```