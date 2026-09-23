import '../../domain/entities/app_notification.dart';

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.applicationId,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] as String,
      applicationId: json['applicationId'] as String,
      message: json['message'] as String? ?? '',
      isRead: json['readAt'] != null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  final String id;
  final String applicationId;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification toEntity() {
    return AppNotification(
      id: id,
      applicationId: applicationId,
      message: message,
      isRead: isRead,
      createdAt: createdAt,
    );
  }
}
