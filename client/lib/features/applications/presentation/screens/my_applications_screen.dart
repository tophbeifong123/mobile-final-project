import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/job_application.dart';
import '../providers/applications_controller.dart';

class MyApplicationsScreen extends ConsumerStatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  ConsumerState<MyApplicationsScreen> createState() =>
      _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends ConsumerState<MyApplicationsScreen> {
  ApplicationStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final applicationsAsync = ref.watch(myApplicationsProvider);

    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      body: SafeArea(
        child: Column(
          children: [
            const _ApplicationsTopBar(),
            Expanded(
              child: applicationsAsync.when(
                skipLoadingOnReload: true,
                loading: () => const _LoadingApplications(),
                error: (error, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
                  children: [
                    _StatePanel(
                      icon: Icons.cloud_off_rounded,
                      title: 'โหลดใบสมัครไม่ได้',
                      message: userVisibleError(error),
                      actionLabel: 'ลองอีกครั้ง',
                      onAction: () => ref.invalidate(myApplicationsProvider),
                    ),
                  ],
                ),
                data: (items) {
                  final visible = _selectedStatus == null
                      ? items
                      : items
                            .where((item) => item.status == _selectedStatus)
                            .toList();

                  return RefreshIndicator(
                    color: NeoColors.electricIndigo,
                    onRefresh: () =>
                        ref.refresh(myApplicationsProvider.future).then((_) {}),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: 2 + (visible.isEmpty ? 1 : visible.length),
                      separatorBuilder: (context, index) => const Gap(16),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _SummaryCard(items: items);
                        }
                        if (index == 1) {
                          return _StatusFilters(
                            items: items,
                            selectedStatus: _selectedStatus,
                            onSelected: (status) {
                              setState(() => _selectedStatus = status);
                            },
                          );
                        }
                        if (visible.isEmpty) {
                          return _StatePanel(
                            icon: items.isEmpty
                                ? Icons.assignment_outlined
                                : Icons.filter_alt_off_rounded,
                            title: items.isEmpty
                                ? 'ยังไม่มีใบสมัคร'
                                : 'ไม่มีใบสมัครในสถานะนี้',
                            message: items.isEmpty
                                ? 'เจองานที่สนใจแล้ว สมัครได้จากหน้ารายละเอียดงาน'
                                : 'ลองเลือกสถานะอื่นเพื่อดูใบสมัครของคุณ',
                            actionLabel: items.isEmpty
                                ? 'ค้นหางานฝึกงาน'
                                : 'ดูใบสมัครทั้งหมด',
                            onAction: items.isEmpty
                                ? () => context.go('/student/home')
                                : () => setState(() => _selectedStatus = null),
                          );
                        }
                        final application = visible[index - 2];
                        return _ApplicationCard(
                          application: application,
                          onTap: () => context.push(
                            '/student/applications/${application.id}',
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationsTopBar extends StatelessWidget {
  const _ApplicationsTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      decoration: const BoxDecoration(color: NeoColors.paperCanvas),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: NeoColors.butterYellow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NeoColors.inkSolid, width: 2),
              boxShadow: NeoShadows.elevation1,
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              size: 18,
              color: NeoColors.inkSolid,
            ),
          ),
          const Gap(8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'InternMatch',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: NeoColors.inkSolid,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'การสมัครของฉัน',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: NeoColors.subtleInk,
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          _TopBarAction(
            icon: Icons.notifications_none_rounded,
            label: 'การแจ้งเตือน',
            onTap: () => context.push('/student/notifications'),
          ),
        ],
      ),
    );
  }
}

class _TopBarAction extends StatelessWidget {
  const _TopBarAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: NeoColors.surfaceCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NeoColors.inkSolid, width: 1.5),
            boxShadow: NeoShadows.elevation1,
          ),
          child: Icon(
            icon,
            size: 22,
            color: NeoColors.inkSolid,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.items});

  final List<JobApplication> items;

  @override
  Widget build(BuildContext context) {
    final submitted = _count(items, ApplicationStatus.submitted);
    final reviewing = _count(items, ApplicationStatus.reviewing);
    final decided =
        _count(items, ApplicationStatus.accepted) +
        _count(items, ApplicationStatus.rejected);

    return AppCard(
      backgroundColor: NeoColors.pureWhite,
      borderColor: NeoColors.inkSolid,
      borderWidth: 2.5,
      borderRadius: BorderRadius.circular(16),
      shadows: NeoShadows.elevation2,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -34,
            bottom: -43,
            child: IgnorePointer(
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: NeoColors.butterYellow.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: NeoColors.inkSolid.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: NeoColors.electricIndigo,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      size: 17,
                      color: NeoColors.pureWhite,
                    ),
                  ),
                  const Gap(6),
                  _SmallBadge(label: 'ติดตามสถานะ', color: NeoColors.freshMint),
                ],
              ),
              const Gap(12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'การสมัครของฉัน',
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 25,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                  ),
                  const Gap(8),
                  _SmallBadge(
                    label: '${items.length} รายการ',
                    color: NeoColors.butterYellow,
                    large: true,
                  ),
                ],
              ),
              const Gap(7),
              const Text(
                'ดูความคืบหน้าและผลการพิจารณาจากบริษัทได้ที่นี่',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: NeoColors.subtleInk,
                ),
              ),
              const Gap(14),
              Container(
                height: 1.5,
                color: NeoColors.inkSolid.withValues(alpha: 0.25),
              ),
              const Gap(12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryStat(
                      count: submitted,
                      label: 'ส่งแล้ว',
                      color: NeoColors.skyBlue,
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: _SummaryStat(
                      count: reviewing,
                      label: 'กำลังพิจารณา',
                      color: NeoColors.pastelCoral,
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: _SummaryStat(
                      count: decided,
                      label: 'ทราบผลแล้ว',
                      color: NeoColors.softLilac,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _count(List<JobApplication> items, ApplicationStatus status) {
    return items.where((item) => item.status == status).length;
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NeoColors.inkSolid, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: NeoColors.inkSolid,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: NeoColors.subtleInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.label,
    required this.color,
    this.large = false,
  });

  final String label;
  final Color color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 8,
        vertical: large ? 6 : 3,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: NeoColors.inkSolid, width: 1.5),
        boxShadow: large ? NeoShadows.elevation1 : null,
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          fontSize: large ? 12 : 10,
          fontWeight: FontWeight.w800,
          color: NeoColors.inkSolid,
        ),
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({
    required this.items,
    required this.selectedStatus,
    required this.onSelected,
  });

  final List<JobApplication> items;
  final ApplicationStatus? selectedStatus;
  final ValueChanged<ApplicationStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    const filters = <ApplicationStatus?>[
      null,
      ApplicationStatus.submitted,
      ApplicationStatus.reviewing,
      ApplicationStatus.accepted,
      ApplicationStatus.rejected,
    ];

    return SizedBox(
      height: 49,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const Gap(8),
        itemBuilder: (context, index) {
          final status = filters[index];
          final count = status == null
              ? items.length
              : items.where((item) => item.status == status).length;
          final label = status == null ? 'ทั้งหมด' : status.labelTh;
          final selected = selectedStatus == status;

          return Semantics(
            button: true,
            selected: selected,
            label: '$label $count รายการ',
            child: GestureDetector(
              onTap: () => onSelected(status),
              behavior: HitTestBehavior.opaque,
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                margin: const EdgeInsets.only(bottom: 3, right: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? NeoColors.butterYellow
                      : NeoColors.pureWhite,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: NeoColors.inkSolid, width: 1.8),
                  boxShadow: NeoShadows.elevation1,
                ),
                child: Text(
                  '$label ($count)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    color: selected ? NeoColors.inkSolid : NeoColors.subtleInk,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application, this.onTap});

  final JobApplication application;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _colorForStatus(application.status);

    return AppCard(
      onTap: onTap,
      backgroundColor: NeoColors.pureWhite,
      borderColor: NeoColors.inkSolid,
      borderWidth: 2.5,
      borderRadius: BorderRadius.circular(18),
      shadows: NeoShadows.elevation2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CompanyMark(name: application.companyName),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.jobTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                    const Gap(3),
                    Text(
                      application.companyName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: NeoColors.subtleInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(13),
          _StatusBadge(status: application.status, color: statusColor),
          const Gap(13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeoColors.inkSolid, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _iconForStatus(application.status),
                  size: 19,
                  color: NeoColors.inkSolid,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    _messageForStatus(application.status),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: NeoColors.inkSolid,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),
          _ApplicationProgress(status: application.status),
          const Gap(14),
          Container(
            height: 1.5,
            color: NeoColors.inkSolid.withValues(alpha: 0.25),
          ),
          const Gap(5),
          Row(
            children: [
              if (application.createdAt != null)
                Expanded(
                  child: Text(
                    'ยื่นเมื่อ ${_formatDate(application.createdAt!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: NeoColors.subtleInk,
                    ),
                  ),
                )
              else
                const Spacer(),
              TextButton.icon(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  foregroundColor: NeoColors.electricIndigo,
                ),
                label: const Text(
                  'ดูไทม์ไลน์',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompanyMark extends StatelessWidget {
  const _CompanyMark({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    const markColors = [
      NeoColors.freshMint,
      NeoColors.skyBlue,
      NeoColors.pastelCoral,
      NeoColors.softLilac,
      NeoColors.butterYellow,
    ];
    final runes = name.trim().runes;
    final letter = runes.isEmpty
        ? '?'
        : String.fromCharCode(runes.first).toUpperCase();
    final colorIndex = runes.fold<int>(0, (sum, rune) => sum + rune);

    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: markColors[colorIndex % markColors.length],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NeoColors.inkSolid, width: 1.5),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: NeoColors.inkSolid,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final ApplicationStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: NeoColors.inkSolid, width: 1.5),
        boxShadow: NeoShadows.elevation1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForStatus(status), size: 14, color: NeoColors.inkSolid),
          const Gap(5),
          Text(
            status.labelTh,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: NeoColors.inkSolid,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationProgress extends StatelessWidget {
  const _ApplicationProgress({required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final currentStep = switch (status) {
      ApplicationStatus.submitted => 0,
      ApplicationStatus.reviewing => 1,
      ApplicationStatus.accepted || ApplicationStatus.rejected => 2,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ProgressStep(
            number: 1,
            label: 'ส่งใบสมัคร',
            completed: currentStep > 0,
            current: currentStep == 0,
            color: NeoColors.skyBlue,
          ),
        ),
        _ProgressLine(completed: currentStep > 0),
        Expanded(
          child: _ProgressStep(
            number: 2,
            label: 'พิจารณา',
            completed: currentStep > 1,
            current: currentStep == 1,
            color: NeoColors.pastelCoral,
          ),
        ),
        _ProgressLine(completed: currentStep > 1),
        Expanded(
          child: _ProgressStep(
            number: 3,
            label: 'ผลคัดเลือก',
            completed: false,
            current: currentStep == 2,
            color: _colorForStatus(status),
          ),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 11),
      child: Container(
        width: 17,
        height: 2,
        color: completed
            ? NeoColors.inkSolid
            : NeoColors.mutedInk.withValues(alpha: 0.5),
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.number,
    required this.label,
    required this.completed,
    required this.current,
    required this.color,
  });

  final int number;
  final String label;
  final bool completed;
  final bool current;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final active = completed || current;

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? color : NeoColors.pureWhite,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? NeoColors.inkSolid : NeoColors.mutedInk,
              width: 1.5,
            ),
          ),
          child: completed
              ? const Icon(Icons.check_rounded, size: 15)
              : Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: active ? NeoColors.inkSolid : NeoColors.mutedInk,
                  ),
                ),
        ),
        const Gap(4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            color: active ? NeoColors.inkSolid : NeoColors.subtleInk,
          ),
        ),
      ],
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: NeoColors.pureWhite,
      borderColor: NeoColors.inkSolid,
      borderWidth: 2.5,
      shadows: NeoShadows.elevation2,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: NeoColors.skyBlue,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: NeoColors.inkSolid, width: 1.5),
            ),
            child: Icon(icon, size: 30, color: NeoColors.inkSolid),
          ),
          const Gap(14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: NeoColors.inkSolid,
            ),
          ),
          const Gap(5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: NeoColors.subtleInk,
            ),
          ),
          const Gap(18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: NeoColors.inkSolid,
                backgroundColor: NeoColors.butterYellow,
                side: const BorderSide(color: NeoColors.inkSolid, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingApplications extends StatelessWidget {
  const _LoadingApplications();

  @override
  Widget build(BuildContext context) {
    const placeholders = [
      JobApplication(
        id: 'loading-1',
        jobTitle: 'ตำแหน่งงานฝึกงาน',
        companyName: 'บริษัทตัวอย่าง จำกัด',
        status: ApplicationStatus.reviewing,
        coverLetter: '',
      ),
      JobApplication(
        id: 'loading-2',
        jobTitle: 'ตำแหน่งงานฝึกงาน',
        companyName: 'บริษัทตัวอย่าง จำกัด',
        status: ApplicationStatus.submitted,
        coverLetter: '',
      ),
    ];

    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SummaryCard(items: placeholders),
          const Gap(16),
          _ApplicationCard(application: placeholders[0]),
          const Gap(16),
          _ApplicationCard(application: placeholders[1]),
        ],
      ),
    );
  }
}

Color _colorForStatus(ApplicationStatus status) {
  return switch (status) {
    ApplicationStatus.submitted => NeoColors.skyBlue,
    ApplicationStatus.reviewing => NeoColors.pastelCoral,
    ApplicationStatus.accepted => NeoColors.freshMint,
    ApplicationStatus.rejected => NeoColors.softRose,
  };
}

IconData _iconForStatus(ApplicationStatus status) {
  return switch (status) {
    ApplicationStatus.submitted => Icons.mark_email_read_outlined,
    ApplicationStatus.reviewing => Icons.hourglass_top_rounded,
    ApplicationStatus.accepted => Icons.verified_rounded,
    ApplicationStatus.rejected => Icons.info_outline_rounded,
  };
}

String _messageForStatus(ApplicationStatus status) {
  return switch (status) {
    ApplicationStatus.submitted =>
      'ส่งใบสมัครเรียบร้อยแล้ว รอให้บริษัทเริ่มพิจารณา',
    ApplicationStatus.reviewing => 'บริษัทกำลังพิจารณาใบสมัครและเรซูเมของคุณ',
    ApplicationStatus.accepted =>
      'ยินดีด้วย คุณผ่านการคัดเลือกสำหรับตำแหน่งนี้',
    ApplicationStatus.rejected =>
      'บริษัทแจ้งผลการคัดเลือกแล้ว ดูรายละเอียดเพื่ออ่านไทม์ไลน์',
  };
}

String _formatDate(DateTime date) {
  const months = [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];
  final local = date.toLocal();
  final day = local.day;
  final month = months[local.month - 1];
  final year = local.year;
  return '$day $month $year';
}
