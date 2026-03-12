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
| Android | ✅ | `com.damo.app` |
| iOS | ✅ (Apple Developer 등록 보류) | `com.damo.app` |

## 앱 구조

앱은 **WebView 기반 하이브리드 앱**으로, 웹 프론트엔드(`damo-web.vercel.app`)를 WebView로 로드하고 네이티브 기능(푸시 알림)을 결합합니다.

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
│  │  Native Layer          │  │
│  │  - FCM 푸시 알림       │  │
│  │  - Firebase Analytics  │  │
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
│       └── home_page.dart             # WebView + FCM 리스너
├── main.dart                          # DI + Firebase 초기화
└── firebase_options.dart              # Firebase 설정
```

## 주요 기능

### WebView
- `https://damo-web.vercel.app/search` 로딩
- Google/Naver OAuth 도메인 네비게이션 허용
- SafeArea 적용 (노치/상태바 대응)
- 로딩 인디케이터

### FCM 푸시 알림
- 앱 실행 시 FCM 토큰 자동 등록 (서버 전송)
- 포그라운드 알림: SnackBar 표시
- 백그라운드 알림: 시스템 노티피케이션

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
