import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_hero_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../providers/applications_controller.dart';

class ApplyJobScreen extends ConsumerStatefulWidget {
  const ApplyJobScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends ConsumerState<ApplyJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครงาน')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(kPagePadding),
          children: [
            const AppHeroCard(
              title: 'ยืนยันการสมัคร',
              body:
                  'เขียน Cover Letter ให้ครบ ใบสมัครใหม่จะได้สถานะ Submitted ต้องมี Resume PDF ก่อน และสมัครได้ครั้งเดียวต่องาน',
            ),
            const SizedBox(height: 16),
            Text(
              'รหัสประกาศ ${widget.jobId}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _coverLetterController,
              minLines: 8,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Cover Letter',
                alignLabelWithHint: true,
                hintText: 'บอกว่าทำไมอยากฝึกงานที่นี่',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรอก Cover Letter';
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            TextButton(
              onPressed: () => context.push('/student/resume'),
              child: const Text('อัปโหลด Resume'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kPagePadding, 8, kPagePadding, 16),
          child: AppPrimaryButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'กำลังส่ง' : 'ยืนยันสมัคร'),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(applicationRepositoryProvider)
          .apply(
            jobId: widget.jobId,
            coverLetter: _coverLetterController.text.trim(),
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ส่งใบสมัครแล้ว')));
      context.go('/student/applications');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = userVisibleError(error));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
