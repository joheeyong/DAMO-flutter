# DAMO Flutter

Flutter 기반 DAMO 서비스 모바일 앱 (Android / iOS)

## 기술 스택

- **Framework**: Flutter 3.32.8
- **Language**: Dart 3.8.1
- **Architecture**: Clean Architecture
- **State Management**: BLoC Pattern
- **Firebase**: firebase_core, firebase_messaging, firebase_analytics (damo-app-2026)
- **배포**: Firebase App Distribution
- **IDE**: Android Studio

## 지원 플랫폼

| 플랫폼 | 상태 | 패키지명 |
|--------|------|---------|
| Android | ✅ | `com.damo.app` |
| iOS | ✅ (Apple Developer 등록 보류) | `com.damo.app` |

## 프로젝트 구조

```
lib/
├── core/
│   ├── constants/          # API URL 등 앱 상수
│   └── network/            # HTTP 클라이언트 (ApiClient)
├── data/
│   ├── datasource/         # Firebase + API 원격 데이터소스
│   └── repository/         # Repository 구현체
├── domain/
│   ├── entity/             # 도메인 모델 (NotificationMessage)
│   ├── repository/         # Repository 인터페이스
│   └── usecase/            # 비즈니스 로직 (RegisterFcmTokenUseCase)
├── presentation/
│   ├── bloc/               # BLoC (FcmBloc, Event, State)
│   └── page/               # 화면 (HomePage)
├── main.dart               # DI + Firebase 초기화 + 앱 진입점
└── firebase_options.dart   # Firebase 설정 (자동 생성)
```

## 주요 기능

- **FCM 푸시 알림**: 서버에서 발송한 알림을 수신 (포그라운드/백그라운드)
- **디바이스 토큰 자동 등록**: 앱 실행 시 FCM 토큰을 서버에 자동 등록
- **Firebase Analytics**: 화면 전환 자동 추적 (FirebaseAnalyticsObserver)

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
| Android App ID | `1:961127696213:android:7b2c493c2458ecc9f0d1dc` |
| iOS App ID | `1:961127696213:ios:ef26c0ce57565d28f0d1dc` |
| 콘솔 | https://console.firebase.google.com/project/damo-app-2026 |

## 배포

Firebase App Distribution으로 배포:
```bash
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --project damo-app-2026 \
  --app 1:961127696213:android:7b2c493c2458ecc9f0d1dc
```

## 관련 레포지토리

| 서비스 | 레포 |
|--------|------|
| 백엔드 (Spring Boot) | [DAMO-server](https://github.com/joheeyong/DAMO-server) |
| 웹 (React) | [DAMO-web](https://github.com/joheeyong/DAMO-web) |
