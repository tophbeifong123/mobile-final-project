import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    NotificationRemoteDataSource(ref.watch(dioProvider)),
  );
});

class NotificationsController extends Notifier<void> {
  @override
  void build() {
    ref.watch(notificationRepositoryProvider);
  }
}

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, void>(
      NotificationsController.new,
    );
