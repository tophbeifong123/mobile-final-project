import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../jobs/presentation/job_labels.dart';
import '../../domain/entities/job_application.dart';
import '../providers/applications_controller.dart';

class ApplicationDetailScreen extends ConsumerWidget {
  const ApplicationDetailScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationAsync = ref.watch(
      applicationDetailProvider(applicationId),
    );

    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      body: SafeArea(
        child: Column(
          children: [
            const _DetailTopBar(),
            Expanded(
              child: applicationAsync.when(
                skipLoadingOnReload: true,
                loading: () => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: NeoColors.electricIndigo,
                      ),
                      Gap(14),
                      Text(
                        'กำลังโหลดรายละเอียดใบสมัคร',
                        style: TextStyle(
                          fontSize: 13,
                          color: NeoColors.subtleInk,
                        ),
                      ),
                    ],
                  ),
                ),
                error: (error, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
                  children: [
                    AppCard(
                      backgroundColor: NeoColors.pureWhite,
                      borderColor: NeoColors.inkSolid,
                      borderWidth: 2.5,
                      shadows: NeoShadows.elevation2,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 42,
                            color: NeoColors.electricIndigo,
                          ),
                          const Gap(12),
                          const Text(
                            'โหลดรายละเอียดใบสมัครไม่ได้',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: NeoColors.inkSolid,
                            ),
                          ),
                          const Gap(6),
                          Text(
                            userVisibleError(error),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: NeoColors.subtleInk,
                            ),
                          ),
                          const Gap(16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => ref.invalidate(
                                applicationDetailProvider(applicationId),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                foregroundColor: NeoColors.inkSolid,
                                backgroundColor: NeoColors.butterYellow,
                                side: const BorderSide(
                                  color: NeoColors.inkSolid,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'ลองอีกครั้ง',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                data: (app) => RefreshIndicator(
                  color: NeoColors.electricIndigo,
                  onRefresh: () => ref.refresh(
                    applicationDetailProvider(applicationId).future,
                  ),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _JobSummaryCard(application: app),
                      const Gap(24),
                      _TimelineHeading(application: app),
                      const Gap(12),
                      _StatusTimelineCard(application: app),
                      const Gap(20),
                      _ResumeCard(resumeObjectKey: app.resumeObjectKey),
                      const Gap(16),
                      _CoverLetterCard(coverLetter: app.coverLetter),
                      const Gap(20),
                      Center(
                        child: Text(
                          'รหัสใบสมัคร: ${app.id}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: NeoColors.subtleInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      color: NeoColors.paperCanvas,
      child: Row(
        children: [
          IconButton(
            tooltip: 'กลับ',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/student/applications');
              }
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: NeoColors.surfaceCream,
              foregroundColor: NeoColors.inkSolid,
              side: const BorderSide(color: NeoColors.inkSolid, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(44, 44),
            ),
          ),
          const Gap(10),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
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
                  'สถานะใบสมัคร',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: NeoColors.subtleInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobSummaryCard extends StatelessWidget {
  const _JobSummaryCard({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(application.status);
    final hasMetadata =
        application.province?.isNotEmpty == true ||
        application.workMode?.isNotEmpty == true ||
        application.category?.isNotEmpty == true ||
        application.hasAllowance != null;

    return AppCard(
      backgroundColor: NeoColors.pureWhite,
      borderColor: NeoColors.inkSolid,
      borderWidth: 2.5,
      borderRadius: BorderRadius.circular(16),
      shadows: NeoShadows.elevation2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: NeoColors.freshMint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NeoColors.inkSolid, width: 2),
                  boxShadow: NeoShadows.elevation1,
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  size: 27,
                  color: NeoColors.inkSolid,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: NeoColors.subtleInk,
                      ),
                    ),
                    const Gap(3),
                    Text(
                      application.jobTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(14),
          _DetailBadge(
            label: application.status.labelTh,
            color: color,
            icon: _statusIcon(application.status),
          ),
          const Gap(12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeoColors.inkSolid, width: 2),
              boxShadow: NeoShadows.elevation1,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: NeoColors.pureWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                  ),
                  child: Icon(
                    _statusIcon(application.status),
                    size: 18,
                    color: NeoColors.inkSolid,
                  ),
                ),
                const Gap(9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusHeadline(application.status),
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.3,
                          fontWeight: FontWeight.w900,
                          color: NeoColors.inkSolid,
                        ),
                      ),
                      const Gap(3),
                      Text(
                        _statusMessage(application.status),
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          color: NeoColors.subtleInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (hasMetadata) ...[
            const Gap(14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                if (application.province != null &&
                    application.province!.isNotEmpty)
                  _MetaTag(
                    label: application.province!,
                    icon: Icons.location_on_outlined,
                  ),
                if (application.workMode != null &&
                    application.workMode!.isNotEmpty)
                  _MetaTag(
                    label: _workModeText(application.workMode!),
                    icon: Icons.devices_outlined,
                  ),
                if (application.category != null &&
                    application.category!.isNotEmpty)
                  _MetaTag(
                    label: application.category!,
                    icon: Icons.category_outlined,
                  ),
                if (application.hasAllowance != null)
                  _MetaTag(
                    label: allowanceLabel(application.hasAllowance!),
                    icon: Icons.payments_outlined,
                  ),
              ],
            ),
          ],
          if (application.jobId != null) ...[
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('/student/jobs/${application.jobId}'),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('ดูประกาศงาน'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  foregroundColor: NeoColors.inkSolid,
                  backgroundColor: NeoColors.surfaceCream,
                  side: const BorderSide(color: NeoColors.inkSolid, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _workModeText(String mode) {
    switch (mode) {
      case 'on_site':
        return 'On-site';
      case 'hybrid':
        return 'Hybrid';
      case 'remote':
        return 'Remote';
      default:
        return mode;
    }
  }
}

class _DetailBadge extends StatelessWidget {
  const _DetailBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: NeoColors.inkSolid, width: 1.5),
        boxShadow: NeoShadows.elevation1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: NeoColors.inkSolid),
          const Gap(5),
          Text(
            label,
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

class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: NeoColors.surfaceCream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NeoColors.inkSolid, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: NeoColors.electricIndigo),
          const Gap(4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: NeoColors.inkSolid,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineHeading extends StatelessWidget {
  const _TimelineHeading({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    DateTime? latest;
    for (final event in application.timeline) {
      if (latest == null || event.createdAt.isAfter(latest)) {
        latest = event.createdAt;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'สถานะการสมัคร',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: NeoColors.subtleInk,
          ),
        ),
        const Gap(3),
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: NeoColors.electricIndigo,
                shape: BoxShape.circle,
                border: Border.all(color: NeoColors.inkSolid, width: 1.5),
              ),
            ),
            const Gap(8),
            const Expanded(
              child: Text(
                'ไทม์ไลน์การคัดเลือก',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: NeoColors.inkSolid,
                ),
              ),
            ),
          ],
        ),
        if (latest != null) ...[
          const Gap(4),
          Text(
            'อัปเดตล่าสุด ${_formatDateTime(latest)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: NeoColors.subtleInk,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusTimelineCard extends StatelessWidget {
  const _StatusTimelineCard({required this.application});

  final JobApplication application;

  DateTime? _eventDate(ApplicationStatus status) {
    for (final event in application.timeline) {
      if (event.toStatus == status) {
        return event.createdAt;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final status = application.status;
    final decided =
        status == ApplicationStatus.accepted ||
        status == ApplicationStatus.rejected;
    final reviewStarted = status == ApplicationStatus.reviewing || decided;
    final submittedDate =
        _eventDate(ApplicationStatus.submitted) ?? application.createdAt;

    return AppCard(
      backgroundColor: NeoColors.pureWhite,
      borderColor: NeoColors.inkSolid,
      borderWidth: 2.5,
      borderRadius: BorderRadius.circular(16),
      shadows: NeoShadows.elevation2,
      child: Stack(
        children: [
          Positioned(
            left: 17,
            top: 18,
            bottom: 18,
            child: Container(width: 3, color: NeoColors.inkSolid),
          ),
          Column(
            children: [
              _TimelineStepItem(
                title: 'ยื่นใบสมัครแล้ว',
                description: 'ส่งใบสมัครและข้อมูลไปยังบริษัทแล้ว',
                date: submittedDate,
                state: reviewStarted
                    ? _StepState.completed
                    : _StepState.current,
                currentIcon: Icons.send_rounded,
                showAttachment: application.resumeObjectKey?.isNotEmpty == true,
              ),
              const Gap(20),
              _TimelineStepItem(
                title: 'กำลังพิจารณา',
                description: reviewStarted
                    ? 'บริษัทกำลังตรวจประวัติและ Resume'
                    : 'รอการตรวจสอบจากบริษัท',
                date: _eventDate(ApplicationStatus.reviewing),
                state: decided
                    ? _StepState.completed
                    : status == ApplicationStatus.reviewing
                    ? _StepState.current
                    : _StepState.upcoming,
                currentIcon: Icons.manage_search_rounded,
              ),
              const Gap(20),
              _TimelineStepItem(
                title: decided ? status.labelTh : 'ผลการคัดเลือก',
                description: switch (status) {
                  ApplicationStatus.accepted =>
                    'ยินดีด้วย คุณผ่านการคัดเลือกสำหรับตำแหน่งนี้',
                  ApplicationStatus.rejected =>
                    'ขออภัย คุณไม่ผ่านการคัดเลือกสำหรับตำแหน่งนี้',
                  _ => 'รอการตัดสินใจและประกาศผลจากบริษัท',
                },
                date: decided ? _eventDate(status) : null,
                state: switch (status) {
                  ApplicationStatus.accepted => _StepState.accepted,
                  ApplicationStatus.rejected => _StepState.rejected,
                  _ => _StepState.upcoming,
                },
                currentIcon: Icons.verified_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _StepState { completed, current, upcoming, accepted, rejected }

class _TimelineStepItem extends StatelessWidget {
  const _TimelineStepItem({
    required this.title,
    required this.description,
    required this.date,
    required this.state,
    required this.currentIcon,
    this.showAttachment = false,
  });

  final String title;
  final String description;
  final DateTime? date;
  final _StepState state;
  final IconData currentIcon;
  final bool showAttachment;

  @override
  Widget build(BuildContext context) {
    final upcoming = state == _StepState.upcoming;
    final nodeColor = switch (state) {
      _StepState.completed || _StepState.accepted => NeoColors.freshMint,
      _StepState.current => NeoColors.butterYellow,
      _StepState.rejected => NeoColors.softRose,
      _StepState.upcoming => const Color(0xFFE4E1E6),
    };
    final badgeLabel = switch (state) {
      _StepState.completed => 'เรียบร้อย',
      _StepState.current => 'ขั้นตอนปัจจุบัน',
      _StepState.upcoming => 'รอขั้นตอนถัดไป',
      _StepState.accepted || _StepState.rejected => 'ประกาศผลแล้ว',
    };
    final icon = switch (state) {
      _StepState.completed || _StepState.accepted => Icons.check_rounded,
      _StepState.rejected => Icons.close_rounded,
      _StepState.upcoming => Icons.hourglass_top_rounded,
      _StepState.current => currentIcon,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: nodeColor,
            shape: BoxShape.circle,
            border: Border.all(color: NeoColors.inkSolid, width: 2.5),
            boxShadow: upcoming ? null : NeoShadows.elevation1,
          ),
          child: Icon(icon, size: 19, color: NeoColors.inkSolid),
        ),
        const Gap(14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: upcoming
                  ? NeoColors.paperCanvas
                  : state == _StepState.current
                  ? NeoColors.surfaceCream
                  : const Color(0xFFF6F2F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: upcoming ? NeoColors.subtleInk : NeoColors.inkSolid,
                width: upcoming ? 1.5 : 2,
              ),
              boxShadow: upcoming ? null : NeoShadows.elevation1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                    color: upcoming ? NeoColors.subtleInk : NeoColors.inkSolid,
                  ),
                ),
                const Gap(7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: nodeColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: upcoming
                          ? NeoColors.subtleInk
                          : NeoColors.inkSolid,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: upcoming
                          ? NeoColors.subtleInk
                          : NeoColors.inkSolid,
                    ),
                  ),
                ),
                const Gap(7),
                Text(
                  date == null
                      ? upcoming
                            ? 'รอการอัปเดต'
                            : 'ยังไม่มีข้อมูลเวลา'
                      : _formatDateTime(date!),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: NeoColors.subtleInk,
                  ),
                ),
                const Gap(6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: upcoming ? NeoColors.subtleInk : NeoColors.inkSolid,
                  ),
                ),
                if (showAttachment) ...[
                  const Gap(9),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: NeoColors.pureWhite,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 14,
                          color: NeoColors.errorText,
                        ),
                        Gap(5),
                        Text(
                          'แนบ Resume แล้ว',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: NeoColors.inkSolid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverLetterCard extends StatelessWidget {
  const _CoverLetterCard({required this.coverLetter});

  final String coverLetter;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: NeoColors.surfaceCream,
      borderColor: NeoColors.inkSolid,
      borderWidth: 2.5,
      borderRadius: BorderRadius.circular(16),
      shadows: NeoShadows.elevation2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.article_outlined,
                color: NeoColors.electricIndigo,
                size: 21,
              ),
              Gap(8),
              Text(
                'Cover Letter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: NeoColors.inkSolid,
                ),
              ),
            ],
          ),
          const Gap(12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NeoColors.pureWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NeoColors.inkSolid, width: 1.5),
            ),
            child: Text(
              coverLetter.trim().isNotEmpty
                  ? coverLetter.trim()
                  : 'ไม่ได้ระบุ Cover Letter',
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: NeoColors.inkSolid,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({this.resumeObjectKey});

  final String? resumeObjectKey;

  @override
  Widget build(BuildContext context) {
    final hasResume = resumeObjectKey?.isNotEmpty == true;

    return AppCard(
      backgroundColor: NeoColors.pureWhite,
      borderColor: NeoColors.inkSolid,
      borderWidth: 2.5,
      borderRadius: BorderRadius.circular(16),
      shadows: NeoShadows.elevation2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.folder_shared_outlined,
                color: NeoColors.electricIndigo,
                size: 22,
              ),
              const Gap(8),
              const Expanded(
                child: Text(
                  'เอกสารที่แนบส่งไปแล้ว',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: NeoColors.inkSolid,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: NeoColors.surfaceCream,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                ),
                child: Text(
                  hasResume ? '1 ฉบับ' : '0 ฉบับ',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: NeoColors.inkSolid,
                  ),
                ),
              ),
            ],
          ),
          const Gap(13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NeoColors.paperCanvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeoColors.inkSolid, width: 2),
              boxShadow: NeoShadows.elevation1,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: NeoColors.softRose,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    size: 21,
                    color: NeoColors.inkSolid,
                  ),
                ),
                const Gap(9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resume ที่ใช้สมัคร',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: NeoColors.inkSolid,
                        ),
                      ),
                      const Gap(3),
                      Text(
                        hasResume
                            ? 'สำเนา Resume ในระบบ ณ วันที่ยื่นใบสมัคร'
                            : 'ยังไม่มี Resume ในใบสมัครนี้',
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: NeoColors.subtleInk,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasResume) ...[
                  const Gap(6),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: NeoColors.electricIndigo,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(ApplicationStatus status) {
  return switch (status) {
    ApplicationStatus.submitted => NeoColors.skyBlue,
    ApplicationStatus.reviewing => NeoColors.butterYellow,
    ApplicationStatus.accepted => NeoColors.freshMint,
    ApplicationStatus.rejected => NeoColors.softRose,
  };
}

IconData _statusIcon(ApplicationStatus status) {
  return switch (status) {
    ApplicationStatus.submitted => Icons.mark_email_read_outlined,
    ApplicationStatus.reviewing => Icons.hourglass_top_rounded,
    ApplicationStatus.accepted => Icons.verified_rounded,
    ApplicationStatus.rejected => Icons.info_outline_rounded,
  };
}

String _statusHeadline(ApplicationStatus status) {
  return switch (status) {
    ApplicationStatus.submitted => 'ส่งใบสมัครเรียบร้อยแล้ว',
    ApplicationStatus.reviewing => 'บริษัทกำลังพิจารณาใบสมัครของคุณ',
    ApplicationStatus.accepted => 'ยินดีด้วย! คุณผ่านการคัดเลือก',
    ApplicationStatus.rejected => 'บริษัทแจ้งผลการคัดเลือกแล้ว',
  };
}

String _statusMessage(ApplicationStatus status) {
  return switch (status) {
    ApplicationStatus.submitted => 'ใบสมัครและเอกสารถูกส่งไปยังบริษัทแล้ว',
    ApplicationStatus.reviewing => 'ติดตามความคืบหน้าได้จากไทม์ไลน์ด้านล่าง',
    ApplicationStatus.accepted =>
      'ดูวันที่และรายละเอียดการเปลี่ยนสถานะในไทม์ไลน์',
    ApplicationStatus.rejected =>
      'ขอบคุณที่สมัครงานนี้ คุณยังค้นหาตำแหน่งอื่นได้',
  };
}

String _formatDateTime(DateTime dateTime) {
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
  final local = dateTime.toLocal();
  final day = local.day;
  final month = months[local.month - 1];
  final year = local.year;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day $month $year • $hour:$minute น.';
}
