# DAMO Flutter

Flutter 기반 DAMO 서비스 모바일 앱 (Android / iOS)

## 기술 스택

- **Framework**: Flutter 3.32.8
- **Language**: Dart 3.8.1
- **Firebase**: firebase_core (damo-app-2026)
- **배포**: Firebase App Distribution

## 지원 플랫폼

| 플랫폼 | 상태 | 패키지명 |
|--------|------|---------|
| Android | ✅ | `com.example.damo_flutter` |
| iOS | ✅ (코드사이닝 필요) | `com.example.damoFlutter` |

## 프로젝트 구조

```
lib/
├── main.dart                # 앱 엔트리포인트 + Firebase 초기화
└── firebase_options.dart    # Firebase 설정 (자동 생성)
```

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
| Android App ID | `1:961127696213:android:875ad30cafb67b38f0d1dc` |
| iOS App ID | `1:961127696213:ios:e2c1a3c89fc9ee66f0d1dc` |
| 콘솔 | https://console.firebase.google.com/project/damo-app-2026 |

## 배포

Firebase App Distribution으로 배포:
```bash
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --project damo-app-2026 \
  --app 1:961127696213:android:875ad30cafb67b38f0d1dc
```

## Backend API

- **Server**: http://54.180.179.231:8080
- **Repository**: https://github.com/joheeyong/DAMO-server
