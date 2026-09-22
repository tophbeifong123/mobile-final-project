class AppNotification {
  const AppNotification({
    required this.id,
    required this.applicationId,
    required this.message,
    required this.isRead,
  });

  final String id;
  final String applicationId;
  final String message;
  final bool isRead;
}
