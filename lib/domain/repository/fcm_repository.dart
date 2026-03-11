abstract class FcmRepository {
  Future<String?> getToken();
  Future<void> registerToken({required String token, required String platform});
  Stream<String> onTokenRefresh();
}
