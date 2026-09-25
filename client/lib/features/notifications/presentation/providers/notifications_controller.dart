import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    NotificationRemoteDataSource(ref.watch(dioProvider)),
  );
});

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
      NotificationsNotifier.new,
    );

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    final repo = ref.watch(notificationRepositoryProvider);
    return repo.fetchAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(notificationRepositoryProvider);
      return repo.fetchAll();
    });
  }

  Future<void> markAsRead(String id) async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAsRead(id);

      final current = state.value;
      if (current != null) {
        state = AsyncValue.data(
          current.map((item) {
            if (item.id == id) {
              return AppNotification(
                id: item.id,
                applicationId: item.applicationId,
                message: item.message,
                isRead: true,
                createdAt: item.createdAt,
              );
            }
            return item;
          }).toList(),
        );
      }
    } catch (_) {
      // Best-effort; server state will sync on next fetch
    }
  }
}
