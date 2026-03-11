import '../../domain/repository/fcm_repository.dart';
import '../datasource/fcm_remote_datasource.dart';

class FcmRepositoryImpl implements FcmRepository {
  final FcmRemoteDataSource _dataSource;

  FcmRepositoryImpl(this._dataSource);

  @override
  Future<String?> getToken() => _dataSource.getToken();

  @override
  Future<void> registerToken({
    required String token,
    required String platform,
  }) =>
      _dataSource.registerTokenToServer(token: token, platform: platform);

  @override
  Stream<String> onTokenRefresh() => _dataSource.onTokenRefresh();
}
