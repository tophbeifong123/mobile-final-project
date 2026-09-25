import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    final unreadCount =
        notificationsAsync.asData?.value.where((n) => !n.isRead).length ?? 0;

    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      body: SafeArea(
        child: Column(
          children: [
            _NotiTopBar(unreadCount: unreadCount),
            Expanded(
              child: notificationsAsync.when(
                skipLoadingOnReload: true,
                loading: () => const _NotiSkeletonList(),
                error: (error, _) => _NotiErrorView(
                  message: userVisibleError(error),
                  onRetry: () => ref.invalidate(notificationsProvider),
                ),
                data: (items) => items.isEmpty
                    ? _NotiEmptyView(
                        onRefresh: () =>
                            ref.refresh(notificationsProvider.future),
                      )
                    : _NotiList(
                        items: items,
                        onRefresh: () =>
                            ref.refresh(notificationsProvider.future),
                        onTap: (item) {
                          if (!item.isRead) {
                            ref
                                .read(notificationsProvider.notifier)
                                .markAsRead(item.id);
                          }
                          context.push(
                            '/student/applications/${item.applicationId}',
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────

class _NotiTopBar extends StatelessWidget {
  const _NotiTopBar({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: NeoColors.paperCanvas,
        border: Border(bottom: BorderSide(color: NeoColors.inkSolid, width: 2)),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: NeoColors.pureWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: NeoColors.inkSolid, width: 1.8),
                boxShadow: NeoShadows.elevation1,
              ),
              child: const Icon(
                LucideIcons.arrowLeft,
                size: 18,
                color: NeoColors.inkSolid,
              ),
            ),
          ),
          const Gap(12),
          // Bell icon box
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: NeoColors.butterYellow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NeoColors.inkSolid, width: 1.8),
              boxShadow: NeoShadows.elevation1,
            ),
            child: const Icon(
              LucideIcons.bell,
              size: 17,
              color: NeoColors.inkSolid,
            ),
          ),
          const Gap(10),
          // Title
          const Expanded(
            child: Text(
              'การแจ้งเตือน',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: NeoColors.inkSolid,
                letterSpacing: -0.3,
              ),
            ),
          ),
          // Unread badge
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: NeoColors.electricIndigo,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                boxShadow: NeoShadows.elevation1,
              ),
              child: Text(
                '$unreadCount ใหม่',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: NeoColors.pureWhite,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Notification List ────────────────────────────────────────────────────────

class _NotiList extends StatelessWidget {
  const _NotiList({
    required this.items,
    required this.onRefresh,
    required this.onTap,
  });

  final List<AppNotification> items;
  final Future<void> Function() onRefresh;
  final void Function(AppNotification) onTap;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: NeoColors.inkSolid,
      backgroundColor: NeoColors.butterYellow,
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(kPagePadding),
        itemCount: items.length,
        separatorBuilder: (_, _) => const Gap(10),
        itemBuilder: (context, index) => _NotificationCard(
          notification: items[index],
          onTap: () => onTap(items[index]),
        ),
      ),
    );
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? NeoColors.softLilac : NeoColors.pureWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NeoColors.inkSolid, width: 2),
          boxShadow: NeoShadows.elevation2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon box
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isUnread
                    ? NeoColors.electricIndigo
                    : NeoColors.surfaceCream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                boxShadow: NeoShadows.elevation1,
              ),
              child: Icon(
                isUnread ? LucideIcons.bellRing : LucideIcons.bell,
                size: 20,
                color: isUnread ? NeoColors.pureWhite : NeoColors.subtleInk,
              ),
            ),
            const Gap(12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: NeoColors.inkSolid,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (isUnread) ...[
                        const Gap(8),
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: NeoColors.electricIndigo,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: NeoColors.inkSolid,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Gap(8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      // Timestamp
                      if (notification.createdAt != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.clock3,
                              size: 12,
                              color: NeoColors.subtleInk,
                            ),
                            const Gap(4),
                            Text(
                              _formatDateTime(notification.createdAt!),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: NeoColors.subtleInk,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Read status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isUnread
                              ? NeoColors.butterYellow
                              : NeoColors.surfaceCream,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: NeoColors.inkSolid,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isUnread ? 'ยังไม่ได้อ่าน' : 'อ่านแล้ว',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isUnread
                                ? NeoColors.inkSolid
                                : NeoColors.subtleInk,
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
              size: 18,
              color: NeoColors.subtleInk,
            ),
          ],
        ),
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

// ─── Skeleton Loading ────────────────────────────────────────────────────────

class _NotiSkeletonList extends StatelessWidget {
  const _NotiSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: NeoColors.surfaceCream,
        highlightColor: NeoColors.pureWhite,
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(kPagePadding),
        itemCount: 5,
        separatorBuilder: (_, _) => const Gap(10),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: NeoColors.pureWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: NeoColors.inkSolid, width: 2),
            boxShadow: NeoShadows.elevation2,
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(width: 42, height: 42, radius: 12),
              Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: double.infinity, height: 16, radius: 6),
                    Gap(6),
                    _SkeletonBox(width: 160, height: 14, radius: 6),
                    Gap(8),
                    _SkeletonBox(width: 120, height: 12, radius: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: NeoColors.mutedInk,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _NotiEmptyView extends StatelessWidget {
  const _NotiEmptyView({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: NeoColors.inkSolid,
      backgroundColor: NeoColors.butterYellow,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: NeoColors.butterYellow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: NeoColors.inkSolid, width: 2),
                        boxShadow: NeoShadows.elevation2,
                      ),
                      child: const Icon(
                        LucideIcons.bellOff,
                        size: 34,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                    const Gap(20),
                    const Text(
                      'ยังไม่มีการแจ้งเตือน',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: NeoColors.inkSolid,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Gap(8),
                    const Text(
                      'จะแสดงเมื่อบริษัทเปลี่ยนสถานะใบสมัคร พร้อมเวลาและสถานะว่าอ่านแล้วหรือยัง กดแล้วเปิดรายละเอียดใบสมัคร',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: NeoColors.subtleInk,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class _NotiErrorView extends StatelessWidget {
  const _NotiErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: NeoColors.errorBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: NeoColors.inkSolid, width: 2),
                boxShadow: NeoShadows.elevation2,
              ),
              child: const Icon(
                LucideIcons.bellOff,
                size: 30,
                color: NeoColors.errorText,
              ),
            ),
            const Gap(16),
            const Text(
              'โหลดการแจ้งเตือนไม่ได้',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: NeoColors.inkSolid,
              ),
            ),
            const Gap(6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: NeoColors.subtleInk,
              ),
            ),
            const Gap(20),
            NeoButton(
              onPressed: onRetry,
              text: 'ลองอีกครั้ง',
              icon: const Icon(LucideIcons.refreshCw, size: 15),
              variant: NeoButtonVariant.secondary,
              height: 42,
            ),
          ],
        ),
      ),
    );
  }
}
