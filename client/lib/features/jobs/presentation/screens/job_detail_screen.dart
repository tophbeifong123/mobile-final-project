import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_hero_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
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
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดงาน')),
      body: ListView(
        padding: const EdgeInsets.all(kPagePadding),
        children: [
          const AppHeroCard(
            title: 'ประกาศฝึกงาน',
            body:
                'ชื่อบริษัท รายละเอียด จังหวัด รูปแบบงาน หมวดงาน เบี้ยเลี้ยง และคุณสมบัติ จะแสดงเมื่อโหลดประกาศนี้ได้',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.apartment_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'เกี่ยวกับบริษัท',
                          style: textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const _DetailRow(
                    label: 'ชื่อบริษัท',
                    value: 'ยังไม่มีข้อมูล',
                  ),
                  const _DetailRow(
                    label: 'ประเภทกิจการ',
                    value: 'ยังไม่มีข้อมูล',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _SectionCard(
            title: 'รายละเอียดงาน',
            body: 'ยังไม่มีข้อมูลประกาศ',
          ),
          const SizedBox(height: 12),
          const _SectionCard(title: 'คุณสมบัติ', body: 'ยังไม่มีข้อมูลประกาศ'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  _DetailRow(label: 'จังหวัด', value: 'ยังไม่มีข้อมูล'),
                  _DetailRow(label: 'รูปแบบงาน', value: 'ยังไม่มีข้อมูล'),
                  _DetailRow(label: 'หมวดงาน', value: 'ยังไม่มีข้อมูล'),
                  _DetailRow(label: 'เบี้ยเลี้ยง', value: 'ยังไม่มีข้อมูล'),
                  _DetailRow(label: 'สถานะ', value: 'ยังไม่มีข้อมูล'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('รหัสประกาศ ${widget.jobId}', style: textTheme.bodySmall),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kPagePadding, 8, kPagePadding, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _save,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(kMinTouchTarget),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(_saving ? 'กำลังบันทึก' : 'บันทึก'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppPrimaryButton(
                  onPressed: () =>
                      context.push('/student/jobs/${widget.jobId}/apply'),
                  child: const Text('สมัครงาน'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(jobRepositoryProvider).save(widget.jobId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกงานแล้ว')));
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
