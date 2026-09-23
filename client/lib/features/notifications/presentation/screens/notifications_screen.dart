import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('การแจ้งเตือน')),
      body: notificationsAsync.when(
        skipLoadingOnReload: true,
        loading: () => Skeletonizer(
          enabled: true,
          child: ListView.separated(
            padding: const EdgeInsets.all(kPagePadding),
            itemCount: 4,
            separatorBuilder: (context, index) => const Gap(12),
            itemBuilder: (context, index) => const AppCard(
              child: Row(
                children: [
                  CircleAvatar(radius: 20),
                  Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ข้อความแจ้งเตือนตัวอย่างการเปลี่ยนสถานะใบสมัคร'),
                        Gap(8),
                        Text('23/09/2026 12:00'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        error: (error, _) => EmptyState(
          icon: LucideIcons.bellOff,
          title: 'โหลดการแจ้งเตือนไม่ได้',
          message: userVisibleError(error),
          action: AppButton(
            variant: AppButtonVariant.outline,
            size: AppButtonSize.sm,
            onPressed: () => ref.invalidate(notificationsProvider),
            text: 'ลองอีกครั้ง',
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.refresh(notificationsProvider.future),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: const EmptyState(
                      icon: LucideIcons.bell,
                      title: 'ยังไม่มีการแจ้งเตือน',
                      message:
                          'จะแสดงเมื่อบริษัทเปลี่ยนสถานะใบสมัคร พร้อมเวลาและสถานะว่าอ่านแล้วหรือยัง กดแล้วเปิดรายละเอียดใบสมัคร',
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(notificationsProvider.future),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(kPagePadding),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _NotificationCard(
                  notification: item,
                  onTap: () {
                    if (!item.isRead) {
                      ref
                          .read(notificationsProvider.notifier)
                          .markAsRead(item.id);
                    }
                    context.push('/student/applications/${item.applicationId}');
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;
    final isUnread = !notification.isRead;

    return AppCard(
      onTap: onTap,
      backgroundColor: isUnread
          ? AppColors.primary.withValues(alpha: 0.05)
          : colors.card,
      borderColor: isUnread
          ? AppColors.primary.withValues(alpha: 0.3)
          : colors.border,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: isUnread
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : colors.muted,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                isUnread
                    ? LucideIcons.bellRing
                    : LucideIcons.bell,
                color: isUnread
                    ? AppColors.primary
                    : colors.mutedForeground,
                size: 20,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.message,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: isUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isUnread) ...[
                      const Gap(8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const Gap(8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (notification.createdAt != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 14,
                            color: colors.mutedForeground,
                          ),
                          const Gap(4),
                          Text(
                            _formatDateTime(notification.createdAt!),
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isUnread
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : colors.muted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isUnread ? 'ยังไม่ได้อ่าน' : 'อ่านแล้ว',
                        style: textTheme.labelSmall?.copyWith(
                          color: isUnread
                              ? AppColors.primary
                              : colors.mutedForeground,
                          fontWeight: isUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(8),
          Icon(
            LucideIcons.chevronRight,
            color: colors.mutedForeground.withValues(alpha: 0.6),
            size: 20,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
