import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_hero_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../saved_jobs/presentation/providers/saved_jobs_controller.dart';
import '../../domain/entities/job.dart';
import '../job_labels.dart';
import '../providers/jobs_controller.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(jobDetailProvider(widget.jobId));
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดงาน')),
      body: detail.when(
        loading: () => const LoadingView(label: 'กำลังโหลดประกาศ'),
        error: (error, _) => EmptyState(
          icon: Icons.work_outline,
          title: 'โหลดประกาศไม่ได้',
          message: userVisibleError(error),
          action: AppPrimaryButton(
            onPressed: () => ref.invalidate(jobDetailProvider(widget.jobId)),
            child: const Text('ลองอีกครั้ง'),
          ),
        ),
        data: (job) => _JobBody(job: job),
      ),
      bottomNavigationBar: detail.maybeWhen(
        data: (job) => _Actions(
          saving: _saving,
          saved: job.saved,
          onSave: () => _toggleSave(job),
          onApply: () => context.push('/student/jobs/${job.id}/apply'),
        ),
        orElse: () => null,
      ),
    );
  }

  Future<void> _toggleSave(JobDetail job) async {
    setState(() => _saving = true);
    try {
      final repository = ref.read(jobRepositoryProvider);
      if (job.saved) {
        await repository.unsave(job.id);
      } else {
        await repository.save(job.id);
      }
      ref.invalidate(jobDetailProvider(job.id));
      ref.invalidate(savedJobsProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(job.saved ? 'ยกเลิกบันทึกแล้ว' : 'บันทึกงานแล้ว'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userVisibleError(error))));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _JobBody extends StatelessWidget {
  const _JobBody({required this.job});

  final JobDetail job;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final businessType = _shown(job.businessType);
    return ListView(
      padding: const EdgeInsets.all(kPagePadding),
      children: [
        AppHeroCard(title: job.title, body: job.companyName),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CompanyMark(name: job.companyName),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('เกี่ยวกับบริษัท', style: textTheme.titleMedium),
                          Text(job.companyName, style: textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _DetailRow(label: 'ประเภทกิจการ', value: businessType),
                if (job.companyDescription.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    job.companyDescription.trim(),
                    style: textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(title: 'รายละเอียดงาน', body: job.description),
        const SizedBox(height: 12),
        _SectionCard(title: 'คุณสมบัติ', body: job.requirements),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DetailRow(label: 'จังหวัด', value: job.province),
                _DetailRow(
                  label: 'รูปแบบงาน',
                  value: workModeLabel(job.workMode),
                ),
                _DetailRow(label: 'หมวดงาน', value: job.category),
                _DetailRow(
                  label: 'เบี้ยเลี้ยง',
                  value: allowanceLabel(job.hasAllowance),
                ),
                _DetailRow(
                  label: 'สถานะ',
                  value: jobStatusLabel(job.status),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.saving,
    required this.saved,
    required this.onSave,
    required this.onApply,
  });

  final bool saving;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(kPagePadding, 8, kPagePadding, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onSave,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(kMinTouchTarget),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  saving
                      ? 'กำลังบันทึก'
                      : saved
                      ? 'ยกเลิกบันทึก'
                      : 'บันทึก',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppPrimaryButton(
                onPressed: onApply,
                child: const Text('สมัครงาน'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyMark extends StatelessWidget {
  const _CompanyMark({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = trimmed.isEmpty ? '?' : trimmed.characters.first;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Text(letter, style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: textTheme.bodyMedium)),
          Expanded(child: Text(value, style: textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

String _shown(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'ยังไม่ได้ระบุ' : trimmed;
}
