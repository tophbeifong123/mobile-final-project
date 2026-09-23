import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remote);

  final NotificationRemoteDataSource _remote;

  @override
  Future<List<AppNotification>> fetchAll() async {
    final models = await _remote.fetchAll();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<AppNotification> markAsRead(String id) async {
    final model = await _remote.markAsRead(id);
    return model.toEntity();
  }
}
