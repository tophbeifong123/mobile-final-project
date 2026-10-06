import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/provinces/thai_province_picker.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/company_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../../core/widgets/skill_picker_sheet.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../../jobs/presentation/job_categories.dart';
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
        backgroundColor: NeoColors.paperCanvas,
        appBar: CompanyTopBar(
          title: 'แก้ประกาศ',
          showBack: true,
          backLocation: '/company/jobs/$jobId',
        ),
        body: const LoadingView(label: 'กำลังโหลดประกาศ'),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: NeoColors.paperCanvas,
        appBar: CompanyTopBar(
          title: 'แก้ประกาศ',
          showBack: true,
          backLocation: '/company/jobs/$jobId',
        ),
        body: Center(
          child: AppErrorView(
            message: userVisibleError(error),
            onRetry: () => ref.invalidate(companyJobDetailProvider(jobId)),
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
  late final TextEditingController _requirementsController;
  late final TextEditingController _allowanceAmountController;
  late WorkMode _workMode;
  late String _category;
  late bool _hasAllowance;
  late int _version;
  late List<String> _skills;
  int? _selectedProvinceId;
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
    _requirementsController = TextEditingController(
      text: job?.requirements ?? '',
    );
    _allowanceAmountController = TextEditingController(
      text: job?.allowanceAmount?.toString() ?? '',
    );
    _workMode = job == null ? WorkMode.hybrid : workModeFromApi(job.workMode);
    _category = isJobCategory(job?.category ?? '') ? job!.category : '';
    _hasAllowance = job?.hasAllowance ?? false;
    _version = job?.version ?? 1;
    _skills = List<String>.from(job?.skills ?? const []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _provinceController.dispose();
    _requirementsController.dispose();
    _allowanceAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.job != null;
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final form = _FormColumn(
      title: _field(
        fieldKey: const Key('job-title-field'),
        controller: _titleController,
        label: 'ชื่องาน',
        textInputAction: TextInputAction.next,
      ),
      description: _field(
        fieldKey: const Key('job-description-field'),
        controller: _descriptionController,
        label: 'รายละเอียด',
        minLines: 4,
        maxLines: 6,
      ),
      province: InkWell(
        key: const Key('job-province-picker'),
        onTap: _busy ? null : _openProvincePicker,
        child: IgnorePointer(
          child: _field(
            fieldKey: const Key('job-province-field'),
            controller: _provinceController,
            label: 'จังหวัด',
            hintText: 'เลือกจากรายชื่อจังหวัด',
            readOnly: true,
            prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
            suffixIcon: const Icon(Icons.keyboard_arrow_down),
          ),
        ),
      ),
      workMode: _WorkModePicker(
        value: _workMode,
        enabled: !_busy,
        onChanged: (value) => setState(() => _workMode = value),
      ),
      category: _CategoryPicker(
        value: _category,
        enabled: !_busy,
        onChanged: (value) => setState(() => _category = value),
      ),
      allowance: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AllowanceToggle(
            value: _hasAllowance,
            enabled: !_busy,
            onChanged: (value) => setState(() {
              _hasAllowance = value;
              if (!value) _allowanceAmountController.clear();
            }),
          ),
          if (_hasAllowance) ...[
            const Gap(12),
            _field(
              fieldKey: const Key('job-allowance-amount'),
              controller: _allowanceAmountController,
              label: 'จำนวนเงิน (บาท)',
              keyboardType: TextInputType.number,
              validator: _amount,
            ),
          ],
        ],
      ),
      requirements: _field(
        fieldKey: const Key('job-requirements-field'),
        controller: _requirementsController,
        label: 'คุณสมบัติ',
        minLines: 3,
        maxLines: 5,
      ),
      skills: _SkillsEditor(
        skills: _skills,
        enabled: !_busy,
        onPick: _openSkillPicker,
        onRemove: (skill) => setState(() => _skills.remove(skill)),
      ),
      error: _error,
    );
    final actions = _FormActions(
      editing: editing,
      submitting: _submitting,
      deleting: _deleting,
      submitLabel: _submitLabel,
      onSubmit: _busy ? null : _submit,
      onDelete: _busy ? null : _confirmDelete,
    );

    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      appBar: CompanyTopBar(
        title: editing ? 'แก้ประกาศ' : 'สร้างประกาศ',
        showBack: true,
        backLocation: editing
            ? '/company/jobs/${widget.job!.id}'
            : '/company/jobs',
      ),
      body: Form(
        key: _formKey,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: wide
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: form),
                        const Gap(24),
                        SizedBox(width: 320, child: actions),
                      ],
                    ),
                  )
                : form,
          ),
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : Material(
              color: NeoColors.paperCanvas,
              child: SafeArea(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: NeoColors.inkSolid, width: 2),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: actions,
                ),
              ),
            ),
    );
  }

  Widget _field({
    Key? fieldKey,
    required TextEditingController controller,
    required String label,
    String? hintText,
    int minLines = 1,
    int maxLines = 1,
    bool readOnly = false,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    Widget? prefixIcon,
    Widget? suffixIcon,
    TextInputAction? textInputAction,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator ?? _required,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: NeoColors.inkSolid,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: NeoColors.paperCanvas,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: NeoColors.subtleInk,
        ),
        floatingLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: NeoColors.inkSolid,
        ),
        hintStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: NeoColors.mutedInk,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: _fieldBorder(NeoColors.inkSolid, 2),
        enabledBorder: _fieldBorder(NeoColors.inkSolid, 2),
        focusedBorder: _fieldBorder(NeoColors.electricIndigo, 2.2),
        errorBorder: _fieldBorder(NeoColors.errorBorder, 2),
        focusedErrorBorder: _fieldBorder(NeoColors.errorBorder, 2),
      ),
    );
  }

  Future<void> _openSkillPicker() async {
    final selected = await SkillPickerSheet.show(
      context,
      selectedSkills: _skills,
      title: 'เลือกทักษะที่ต้องการ',
      subtitle: 'เลือกทักษะที่เหมาะกับตำแหน่งงานนี้',
    );
    if (selected != null && mounted) {
      setState(() => _skills = selected);
    }
  }

  Future<void> _openProvincePicker() async {
    final selected = await showThaiProvincePicker(
      context,
      selectedProvinceId: _selectedProvinceId,
    );
    if (!mounted || selected == null) return;
    setState(() {
      _selectedProvinceId = selected.id;
      _provinceController.text = selected.nameTh;
    });
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

  String? _amount(String? value) {
    final amount = int.tryParse(value?.trim() ?? '');
    if (amount == null || amount < 1 || amount > 1000000) {
      return 'ระบุจำนวนเงินเป็นบาท';
    }
    return null;
  }

  JobPosting _posting() {
    return JobPosting(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      province: _provinceController.text.trim(),
      workMode: workModeToApi(_workMode),
      category: _category,
      hasAllowance: _hasAllowance,
      allowanceAmount: _hasAllowance
          ? int.parse(_allowanceAmountController.text.trim())
          : null,
      requirements: _requirementsController.text.trim(),
      skills: _skills,
    );
  }

  Future<void> _submit() async {
    final fieldsValid = _formKey.currentState!.validate();
    if (!isJobCategory(_category)) {
      setState(() => _error = 'เลือกหมวดงาน');
      return;
    }
    if (!fieldsValid) {
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
        AppToast.success(context, 'สร้างประกาศแล้ว');
        ref.invalidate(companyJobListProvider);
        context.go('/company/jobs/${created.id}');
        return;
      }
      await ref
          .read(companyJobsControllerProvider.notifier)
          .update(jobId: existing.id, posting: posting, version: _version);
      if (!mounted) {
        return;
      }
      AppToast.success(context, 'บันทึกประกาศแล้ว');
      ref.invalidate(companyJobListProvider);
      ref.invalidate(companyJobDetailProvider(existing.id));
      ref.invalidate(companyOwnedJobProvider(existing.id));
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/company/jobs/${existing.id}');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = userVisibleError(error);
      if (existing != null && message == 'ประกาศถูกแก้ไปแล้ว โหลดข้อมูลใหม่') {
        AppToast.error(context, message);
        ref.invalidate(companyJobDetailProvider(existing.id));
        ref.invalidate(companyOwnedJobProvider(existing.id));
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
      AppToast.info(context, 'ลบประกาศแล้ว');
      ref.invalidate(companyJobListProvider);
      ref.invalidate(companyOwnedJobProvider(existing.id));
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

OutlineInputBorder _fieldBorder(Color color, double width) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: width),
  );
}

class _FormColumn extends StatelessWidget {
  const _FormColumn({
    required this.title,
    required this.description,
    required this.province,
    required this.workMode,
    required this.category,
    required this.allowance,
    required this.requirements,
    required this.skills,
    required this.error,
  });

  final Widget title;
  final Widget description;
  final Widget province;
  final Widget workMode;
  final Widget category;
  final Widget allowance;
  final Widget requirements;
  final Widget skills;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _FormCard(
          icon: LucideIcons.briefcase,
          iconBg: NeoColors.butterYellow,
          title: 'ข้อมูลประกาศ',
          child: Column(children: [title, const Gap(12), description]),
        ),
        const Gap(16),
        _FormCard(
          icon: LucideIcons.mapPin,
          iconBg: NeoColors.skyBlue,
          title: 'สถานที่และเงื่อนไข',
          child: Column(
            children: [
              province,
              const Gap(12),
              workMode,
              const Gap(12),
              category,
              const Gap(12),
              allowance,
            ],
          ),
        ),
        const Gap(16),
        _FormCard(
          icon: LucideIcons.listChecks,
          iconBg: NeoColors.freshMint,
          title: 'คุณสมบัติ',
          child: requirements,
        ),
        const Gap(16),
        skills,
        if (error != null) ...[
          const Gap(12),
          Text(
            error!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: NeoColors.errorText,
            ),
          ),
        ],
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeoColors.inkSolid, width: 2.2),
        boxShadow: NeoShadows.elevation2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                ),
                child: Icon(icon, size: 16, color: NeoColors.inkSolid),
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: NeoColors.inkSolid,
                  ),
                ),
              ),
            ],
          ),
          const Gap(10),
          const Divider(color: NeoColors.inkSolid, height: 1, thickness: 1.5),
          const Gap(14),
          child,
        ],
      ),
    );
  }
}

class _FormActions extends StatelessWidget {
  const _FormActions({
    required this.editing,
    required this.submitting,
    required this.deleting,
    required this.submitLabel,
    required this.onSubmit,
    required this.onDelete,
  });

  final bool editing;
  final bool submitting;
  final bool deleting;
  final String submitLabel;
  final VoidCallback? onSubmit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NeoButton(
          variant: NeoButtonVariant.secondary,
          text: submitLabel,
          icon: Icon(editing ? LucideIcons.save : LucideIcons.plus, size: 18),
          isFullWidth: true,
          isLoading: submitting,
          onPressed: onSubmit,
        ),
        if (editing) ...[
          const Gap(8),
          NeoButton(
            variant: NeoButtonVariant.destructive,
            text: deleting ? 'กำลังลบ' : 'ลบประกาศ',
            icon: const Icon(LucideIcons.trash2, size: 18),
            isFullWidth: true,
            isLoading: deleting,
            onPressed: onDelete,
          ),
        ],
      ],
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'หมวดงาน',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: NeoColors.inkSolid,
          ),
        ),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in jobCategories)
              GestureDetector(
                onTap: enabled ? () => onChanged(category) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: category == value
                        ? NeoColors.butterYellow
                        : NeoColors.paperCanvas,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NeoColors.inkSolid, width: 1.8),
                    boxShadow: category == value ? NeoShadows.elevation1 : null,
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: NeoColors.inkSolid,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _WorkModePicker extends StatelessWidget {
  const _WorkModePicker({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final WorkMode value;
  final bool enabled;
  final ValueChanged<WorkMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'รูปแบบงาน',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: NeoColors.inkSolid,
          ),
        ),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mode in WorkMode.values)
              GestureDetector(
                onTap: enabled ? () => onChanged(mode) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: mode == value
                        ? NeoColors.butterYellow
                        : NeoColors.paperCanvas,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NeoColors.inkSolid, width: 1.8),
                    boxShadow: mode == value ? NeoShadows.elevation1 : null,
                  ),
                  child: Text(
                    workModeLabel(mode),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: NeoColors.inkSolid,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AllowanceToggle extends StatelessWidget {
  const _AllowanceToggle({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? () => onChanged(!value) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: value ? NeoColors.butterYellow : NeoColors.paperCanvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NeoColors.inkSolid, width: 2),
        ),
        child: Row(
          children: [
            Icon(
              value ? LucideIcons.circleCheck : LucideIcons.circle,
              size: 18,
              color: NeoColors.inkSolid,
            ),
            const Gap(8),
            const Expanded(
              child: Text(
                'มีเบี้ยเลี้ยง',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: NeoColors.inkSolid,
                ),
              ),
            ),
            Text(
              value ? 'มี' : 'ไม่มี',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: NeoColors.inkSolid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillsEditor extends StatelessWidget {
  const _SkillsEditor({
    required this.skills,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  final List<String> skills;
  final bool enabled;
  final VoidCallback onPick;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      icon: LucideIcons.sparkles,
      iconBg: NeoColors.softLilac,
      title: 'ทักษะที่ต้องการ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeoButton(
            onPressed: enabled ? onPick : null,
            text: skills.isEmpty ? 'เลือกทักษะ' : 'แก้ไข (${skills.length})',
            variant: NeoButtonVariant.outline,
            height: 40,
            icon: const Icon(LucideIcons.plus, size: 16),
          ),
          if (skills.isEmpty) ...[
            const Gap(8),
            const Text(
              'ยังไม่ได้ระบุทักษะ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: NeoColors.subtleInk,
              ),
            ),
          ] else ...[
            const Gap(10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final skill in skills)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: NeoColors.skyBlue,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: NeoColors.inkSolid,
                          ),
                        ),
                        const Gap(6),
                        GestureDetector(
                          onTap: enabled ? () => onRemove(skill) : null,
                          child: const Icon(
                            LucideIcons.x,
                            size: 14,
                            color: NeoColors.inkSolid,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
