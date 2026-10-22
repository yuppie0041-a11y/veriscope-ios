# 논문검증 iOS 앱 (App Store 판)

웹 서비스(https://veriscope.mindsafe365.co.kr)를 띄우는 Swift WebView 앱입니다.
Mac 없이 GitHub Actions 의 macOS 빌드 서버에서 만들어 App Store Connect 로 올립니다 (긴급콜과 같은 방식).

| 항목 | 값 |
|---|---|
| 번들 ID | `kr.co.mindn.veriscope` |
| 팀 | MIND-N (`UX7GD558S8`) |
| 최소 iOS | 16.0, iPhone 전용 |
| 빌드 번호 | GitHub Actions 실행 번호 (자동으로 올라감) |

## 앱이 하는 일

- 사용자 에이전트 끝에 `VeriscopeiOS/1.0` 을 붙입니다. 웹은 이것을 보고(`is_ios_app()`)
  간편 로그인(카카오·네이버·구글)과 홈 화면 추가 안내를 숨깁니다.
  - 애플 심사 지침 4.8: 다른 회사 로그인을 넣으면 애플 로그인도 넣어야 합니다. 앱에서는 이메일 로그인만 씁니다.
  - 구글은 앱 안의 웹뷰에서 로그인을 막습니다.
- 보고서·수정본(DOCX)·원본 내려받기 → iOS 공유 창("파일에 저장", 메일 등).
- 서비스 밖의 링크(DOI, 학술 사이트)는 사파리로 엽니다.
- 인터넷이 끊기면 다시 시도 화면, 아래로 당겨 새로 고침.

## 처음 한 번 준비

1. developer.apple.com → Certificates, IDs & Profiles → Identifiers → **+** → App IDs → App
   → Bundle ID `kr.co.mindn.veriscope` (Explicit), 설명 `Veriscope`.
2. App Store Connect → 앱 → **+ 신규 앱** → iOS, 이름 `논문검증 - 참고문헌·인용·통계 검증`,
   기본 언어 한국어, 번들 ID `kr.co.mindn.veriscope`, SKU `veriscope-ios`.
3. GitHub 저장소 Settings → Secrets and variables → Actions 에 아래 5개를 넣습니다 (긴급콜 저장소와 같은 값).

| 이름 | 값 |
|---|---|
| `APPLE_CERTIFICATE_P12_BASE64` | 배포 인증서 .p12 를 base64 로 바꾼 글 |
| `APPLE_CERTIFICATE_PASSWORD` | 그 .p12 의 비밀번호 |
| `ASC_API_KEY_ID` | App Store Connect API 키 ID (AuthKey_XXXX.p8 의 XXXX) |
| `ASC_API_ISSUER_ID` | App Store Connect → 사용자 및 액세스 → 통합 → 발급자 ID |
| `ASC_API_PRIVATE_KEY` | AuthKey_XXXX.p8 를 base64 로 바꾼 글 |

   API 키는 **관리자(Admin)** 권한이어야 프로비저닝 프로파일을 자동으로 만들 수 있습니다.

## 빌드·업로드

GitHub → Actions → **iOS Build & App Store Upload** → Run workflow.
15~25분 뒤 App Store Connect → TestFlight 에 빌드가 나타납니다 (처리에 10~30분 더).
