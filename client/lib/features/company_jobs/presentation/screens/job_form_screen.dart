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

class JobFormScreen extends ConsumerStatefulWidget {
  const JobFormScreen({super.key, this.jobId});

  final String? jobId;

  @override
  ConsumerState<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends ConsumerState<JobFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _provinceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _requirementsController = TextEditingController();
  WorkMode _workMode = WorkMode.hybrid;
  bool _hasAllowance = false;
  String? _error;
  bool _submitting = false;

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
    final editing = widget.jobId != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'แก้ประกาศ' : 'สร้างประกาศ')),
      body: editing
          ? const Center(child: Text('หน้าแก้ประกาศยังไม่เปิด'))
          : Form(
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
                    onChanged: (value) {
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
                    onChanged: (value) => setState(() => _hasAllowance = value),
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
      bottomNavigationBar: editing
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  kPagePadding,
                  8,
                  kPagePadding,
                  16,
                ),
                child: AppPrimaryButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_submitting ? 'กำลังสร้าง' : 'สร้างประกาศ'),
                ),
              ),
            ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรอกข้อมูลนี้';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final posting = JobPosting(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      province: _provinceController.text.trim(),
      workMode: workModeToApi(_workMode),
      category: _categoryController.text.trim(),
      hasAllowance: _hasAllowance,
      requirements: _requirementsController.text.trim(),
    );
    try {
      final created = await ref
          .read(companyJobsControllerProvider.notifier)
          .create(posting);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สร้างประกาศแล้ว สถานะ ${created.status}')),
      );
      context.go('/company/jobs');
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
