import '../../domain/entity/notification_message.dart';

sealed class FcmEvent {}

class FcmInitRequested extends FcmEvent {}

class FcmTokenReceived extends FcmEvent {
  final String token;
  FcmTokenReceived(this.token);
}

class FcmNotificationReceived extends FcmEvent {
  final NotificationMessage message;
  FcmNotificationReceived(this.message);
}
