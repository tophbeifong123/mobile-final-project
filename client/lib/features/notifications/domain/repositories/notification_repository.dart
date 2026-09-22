import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> fetchAll();
}
