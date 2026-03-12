# DAMO Flutter

**다모(DAMO)** - 통합 콘텐츠 검색 플랫폼 모바일 앱

## 기술 스택

| 분류 | 기술 |
|------|------|
| Framework | Flutter 3.32.8 |
| Language | Dart 3.8.1 |
| Architecture | Clean Architecture |
| State | BLoC Pattern (flutter_bloc) |
| WebView | webview_flutter 4.x |
| Push | Firebase Cloud Messaging |
| Analytics | Firebase Analytics |
| Deploy | Firebase App Distribution |

## 지원 플랫폼

| 플랫폼 | 상태 | 패키지명 |
|--------|------|---------|
| Android | 지원 | `com.damo.app` |
| iOS | 지원 (Apple Developer 등록 보류) | `com.damo.app` |

## 앱 구조

앱은 **WebView 기반 하이브리드 앱**으로, 웹 프론트엔드(`damo-web.vercel.app`)를 WebView로 로드하고 네이티브 기능(푸시 알림, 뒤로가기)을 결합합니다.

```
┌─────────────────────────────┐
│         Flutter App          │
│  ┌───────────────────────┐  │
│  │    WebView             │  │
│  │  damo-web.vercel.app   │  │
│  │  (검색, 피드, 로그인,   │  │
│  │   프로필, 관심사 등)    │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  Content Overlay       │  │
│  │  (외부 콘텐츠 WebView) │  │
│  │  - 모바일 UA 자동 적용 │  │
│  │  - 뒤로가기로 닫기     │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  Native Layer          │  │
│  │  - FCM 푸시 알림       │  │
│  │  - Firebase Analytics  │  │
│  │  - DamoAuth (JWT 연동) │  │
│  │  - Android 뒤로가기    │  │
│  │    (history.back +     │  │
│  │     더블탭 종료)       │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

## 프로젝트 구조

```
lib/
├── core/
│   ├── constants/app_constants.dart   # API URL 등 상수
│   └── network/api_client.dart        # HTTP 클라이언트
├── data/
│   ├── datasource/fcm_remote_datasource.dart
│   └── repository/fcm_repository_impl.dart
├── domain/
│   ├── entity/notification_message.dart
│   ├── repository/fcm_repository.dart
│   └── usecase/register_fcm_token_usecase.dart
├── presentation/
│   ├── bloc/
│   │   ├── fcm_bloc.dart              # FCM 상태 관리
│   │   ├── fcm_event.dart
│   │   └── fcm_state.dart
│   └── page/
│       ├── home_page.dart             # WebView + FCM + 콘텐츠 오버레이 + 뒤로가기
│       └── content_webview_page.dart  # 콘텐츠 전용 WebView 페이지
├── main.dart                          # DI + Firebase 초기화
└── firebase_options.dart              # Firebase 설정
```

## 주요 기능

### WebView
- `https://damo-web.vercel.app/search` 로딩
- Google/Naver/Kakao OAuth 도메인 네비게이션 허용
- SafeArea 적용 (노치/상태바 대응)
- iOS 스와이프 뒤로/앞으로 제스처 지원

### 콘텐츠 오버레이 WebView
- 외부 URL 이동 시 `NavigationDelegate`에서 가로챔
- 메인 WebView 위에 Stack 오버레이로 콘텐츠 WebView 표시
- 기본 모바일 User Agent + `DAMO-App/1.0` 식별자
- 뒤로가기 버튼(←) 또는 Android 백키: 히스토리 있으면 `goBack()`, 없으면 오버레이 닫기
- iOS 스와이프 제스처 (왼→오른): WKWebView 내장 제스처로 히스토리 뒤로가기, 히스토리 없으면 엣지 스와이프로 오버레이 닫기
- 메인 WebView 상태 완전 유지 (새로고침 없음)

### 스플래시 화면
- DAMO 그라데이션 로고 + "모든 콘텐츠, 하나로"
- `DamoReady` JS 채널로 React 콘텐츠 로딩 완료 감지
- 10초 타임아웃 fallback
- 페이드 아웃 애니메이션

### JavaScript 채널
| 채널 | 방향 | 용도 |
|------|------|------|
| `DamoReady` | Web → App | 콘텐츠 로딩 완료 (스플래시 해제) |
| `DamoAuth` | Web → App | JWT 토큰 전달 (FCM 등록 연동) |

### 뒤로가기 (Android + iOS)
- 콘텐츠 오버레이 열림 + 히스토리 있음 → `goBack()` (히스토리 뒤로가기)
- 콘텐츠 오버레이 열림 + 히스토리 없음 → 오버레이 닫기 (목록 복귀)
- iOS: 스와이프 제스처(왼→오른)로도 동일하게 동작
- 메인 WebView `canGoBack()` → `goBack()`
- 더이상 뒤로갈 페이지가 없을 때 → 토스트 메시지 표시
- 2초 내 재클릭 시 앱 종료 (WillPopScope)

### FCM 푸시 알림
- 로그인 시 FCM 토큰 + JWT를 서버에 등록 (사용자 연동)
- 포그라운드 알림: SnackBar 표시
- 백그라운드 알림: 시스템 노티피케이션
- 알림 탭 시 액션 처리 (예: `open_interests` → 프로필 페이지)
- 1시간 간격 관심사 알림 (서버 스케줄러)

### 앱 브랜딩
- 앱 이름: **DAMO**
- 앱 아이콘: 보라색 그라데이션 (#6366F1 → #A78BFA) + 흰색 D
- Android/iOS 모든 해상도 아이콘 자동 생성 (flutter_launcher_icons)

### Firebase Analytics
- 자동 화면 추적 (FirebaseAnalyticsObserver)

## 로컬 실행

```bash
flutter pub get
flutter run
```

## 빌드

```bash
# Android APK
flutter build apk --release

# iOS (Apple Developer 계정 필요)
flutter build ios --release
```

## Firebase 설정

| 항목 | 값 |
|------|-----|
| 프로젝트 | damo-app-2026 |
| Android App ID | `1:961127696213:android:...` |
| iOS App ID | `1:961127696213:ios:...` |
| 콘솔 | https://console.firebase.google.com/project/damo-app-2026 |

## 관련 레포지토리

| 서비스 | 레포 |
|--------|------|
| 백엔드 (Spring Boot) | [DAMO-server](https://github.com/joheeyong/DAMO-server) |
| 웹 (React) | [DAMO-web](https://github.com/joheeyong/DAMO-web) |
