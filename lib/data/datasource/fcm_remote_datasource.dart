import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/network/api_client.dart';

class FcmRemoteDataSource {
  final FirebaseMessaging _messaging;
  final ApiClient _apiClient;

  FcmRemoteDataSource({
    FirebaseMessaging? messaging,
    ApiClient? apiClient,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _apiClient = apiClient ?? ApiClient();

  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getToken() => _messaging.getToken();

  Stream<String> onTokenRefresh() => _messaging.onTokenRefresh;

  Future<void> registerTokenToServer({
    required String token,
    required String platform,
  }) async {
    await _apiClient.post('/api/fcm/register', body: {
      'token': token,
      'platform': platform,
    });
  }
}
