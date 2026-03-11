class NotificationMessage {
  final String title;
  final String body;
  final DateTime receivedAt;

  NotificationMessage({
    required this.title,
    required this.body,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();
}
