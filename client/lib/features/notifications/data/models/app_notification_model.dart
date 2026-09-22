import '../../domain/entities/app_notification.dart';

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.applicationId,
    required this.message,
    required this.isRead,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] as String,
      applicationId: json['applicationId'] as String,
      message: json['message'] as String? ?? '',
      isRead: json['readAt'] != null,
    );
  }

  final String id;
  final String applicationId;
  final String message;
  final bool isRead;

  AppNotification toEntity() {
    return AppNotification(
      id: id,
      applicationId: applicationId,
      message: message,
      isRead: isRead,
    );
  }
}
