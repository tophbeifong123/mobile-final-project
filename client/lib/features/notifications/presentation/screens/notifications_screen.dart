import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/empty_state.dart';
import '../providers/notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('การแจ้งเตือน')),
      body: const EmptyState(
        icon: Icons.notifications_none,
        title: 'ยังไม่มีการแจ้งเตือน',
        message:
            'จะแสดงเมื่อบริษัทเปลี่ยนสถานะใบสมัคร พร้อมเวลาและสถานะว่าอ่านแล้วหรือยัง กดแล้วเปิดรายละเอียดใบสมัคร',
      ),
    );
  }
}
