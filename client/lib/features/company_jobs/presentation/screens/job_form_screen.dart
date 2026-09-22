import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../../jobs/presentation/job_labels.dart';
import '../../domain/entities/company_job.dart';
import '../providers/company_jobs_controller.dart';

class JobFormScreen extends ConsumerWidget {
  const JobFormScreen({super.key, this.jobId});

  final String? jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobId = this.jobId;
    if (jobId == null) {
      return const _JobForm();
    }
    final detail = ref.watch(companyJobDetailProvider(jobId));
    return detail.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('แก้ประกาศ')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('แก้ประกาศ')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(kPagePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(userVisibleError(error), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(companyJobDetailProvider(jobId)),
                  child: const Text('ลองอีกครั้ง'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (job) =>
          _JobForm(key: ValueKey('${job.id}-${job.version}'), job: job),
    );
  }
}

class _JobForm extends ConsumerStatefulWidget {
  const _JobForm({super.key, this.job});

  final EditableJob? job;

  @override
  ConsumerState<_JobForm> createState() => _JobFormState();
}

class _JobFormState extends ConsumerState<_JobForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _provinceController;
  late final TextEditingController _categoryController;
  late final TextEditingController _requirementsController;
  late WorkMode _workMode;
  late bool _hasAllowance;
  late int _version;
  String? _error;
  bool _submitting = false;
  bool _deleting = false;

  bool get _busy => _submitting || _deleting;

  @override
  void initState() {
    super.initState();
    final job = widget.job;
    _titleController = TextEditingController(text: job?.title ?? '');
    _descriptionController = TextEditingController(
      text: job?.description ?? '',
    );
    _provinceController = TextEditingController(text: job?.province ?? '');
    _categoryController = TextEditingController(text: job?.category ?? '');
    _requirementsController = TextEditingController(
      text: job?.requirements ?? '',
    );
    _workMode = job == null ? WorkMode.hybrid : workModeFromApi(job.workMode);
    _hasAllowance = job?.hasAllowance ?? false;
    _version = job?.version ?? 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _provinceController.dispose();
    _categoryController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.job != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'แก้ประกาศ' : 'สร้างประกาศ')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(kPagePadding),
          children: [
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'ชื่องาน'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'รายละเอียด',
                alignLabelWithHint: true,
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _provinceController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'จังหวัด',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<WorkMode>(
              key: ValueKey(_workMode),
              initialValue: _workMode,
              decoration: const InputDecoration(labelText: 'รูปแบบงาน'),
              items: [
                for (final mode in WorkMode.values)
                  DropdownMenuItem(
                    value: mode,
                    child: Text(workModeLabel(mode)),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _workMode = value);
                      }
                    },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'หมวดงาน'),
              validator: _required,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('มีเบี้ยเลี้ยง'),
              value: _hasAllowance,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _hasAllowance = value),
            ),
            TextFormField(
              controller: _requirementsController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'คุณสมบัติ',
                alignLabelWithHint: true,
              ),
              validator: _required,
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
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kPagePadding, 8, kPagePadding, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (editing)
                TextButton(
                  onPressed: _busy ? null : _confirmDelete,
                  child: Text(_deleting ? 'กำลังลบ' : 'ลบประกาศ'),
                ),
              AppPrimaryButton(
                onPressed: _busy ? null : _submit,
                child: Text(_submitLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _submitLabel {
    if (widget.job != null) {
      return _submitting ? 'กำลังบันทึก' : 'บันทึกประกาศ';
    }
    return _submitting ? 'กำลังสร้าง' : 'สร้างประกาศ';
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรอกข้อมูลนี้';
    }
    return null;
  }

  JobPosting _posting() {
    return JobPosting(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      province: _provinceController.text.trim(),
      workMode: workModeToApi(_workMode),
      category: _categoryController.text.trim(),
      hasAllowance: _hasAllowance,
      requirements: _requirementsController.text.trim(),
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
    final posting = _posting();
    final existing = widget.job;
    try {
      if (existing == null) {
        final created = await ref
            .read(companyJobsControllerProvider.notifier)
            .create(posting);
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('สร้างประกาศแล้ว สถานะ ${created.status}')),
        );
      } else {
        await ref
            .read(companyJobsControllerProvider.notifier)
            .update(jobId: existing.id, posting: posting, version: _version);
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกประกาศแล้ว')));
      }
      ref.invalidate(companyJobListProvider);
      context.go('/company/jobs');
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = userVisibleError(error);
      if (existing != null && message == 'ประกาศถูกแก้ไปแล้ว โหลดข้อมูลใหม่') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        ref.invalidate(companyJobDetailProvider(existing.id));
        return;
      }
      setState(() => _error = message);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final existing = widget.job;
    if (existing == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบประกาศนี้?'),
        content: const Text(
          'ประกาศจะหายจากรายการ และนักศึกษาที่บันทึกไว้จะไม่เห็นประกาศนี้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await ref
          .read(companyJobsControllerProvider.notifier)
          .remove(existing.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบประกาศแล้ว')));
      ref.invalidate(companyJobListProvider);
      context.go('/company/jobs');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = userVisibleError(error));
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }
}
