import '../../domain/entity/notification_message.dart';

class FcmState {
  final String token;
  final NotificationMessage? lastMessage;
  final bool isInitialized;

  const FcmState({
    this.token = '',
    this.lastMessage,
    this.isInitialized = false,
  });

  FcmState copyWith({
    String? token,
    NotificationMessage? lastMessage,
    bool? isInitialized,
  }) {
    return FcmState(
      token: token ?? this.token,
      lastMessage: lastMessage ?? this.lastMessage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}
