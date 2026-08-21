# Resources 레이어 규칙

## 목적

`Resources`는 앱이 실행 시 사용하는 이미지, 색상, 폰트, plist, localized string 같은 비코드 리소스를 관리한다.

## MUST

- MUST Asset catalog, 등록 폰트, plist, localization resource를 실제 target membership과 함께 관리한다.
- MUST 새 asset의 이름을 화면 위치가 아닌 안정적인 의미로 작성한다.
- MUST Figma export의 scale, 투명 여백, rendering mode를 확인한 뒤 asset catalog에 추가한다.
- MUST 이미지가 app target과 extension target에 각각 필요하면 각 target의 resource 경계를 명확히 유지한다.
- SHOULD 미사용·중복·과도한 해상도의 리소스를 release 전 점검한다.
- SHOULD design token의 원본을 asset catalog와 design-system 코드로 유지한다.

## MUST NOT

- MUST NOT 제품 로직, Swift 파일, Markdown 문서, 임시 캡처, 토큰·키 파일을 Resources에 둔다.
- MUST NOT Figma의 임시 URL이나 외부 다운로드 URL을 source code에 남긴다.
- MUST NOT 동일 asset을 target 구분 없이 무조건 중복 복사한다.
- MUST NOT 기기 bezel, status bar, home indicator를 앱 asset으로 추가한다.

## 검토 기준

- resource 변경 뒤에는 실제 target에서 asset name과 font registration을 확인한다.
- release 전에는 IPA payload에서 큰 image·font·framework와 미사용 리소스를 점검한다.
