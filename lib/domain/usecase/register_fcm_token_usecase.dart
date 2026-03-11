import '../repository/fcm_repository.dart';

class RegisterFcmTokenUseCase {
  final FcmRepository _repository;

  RegisterFcmTokenUseCase(this._repository);

  Future<String?> getToken() => _repository.getToken();

  Future<void> register({
    required String token,
    required String platform,
  }) =>
      _repository.registerToken(token: token, platform: platform);

  Stream<String> onTokenRefresh() => _repository.onTokenRefresh();
}
