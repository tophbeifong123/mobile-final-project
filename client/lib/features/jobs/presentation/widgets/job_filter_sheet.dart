import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../domain/entities/job.dart';
import '../job_labels.dart';

class JobFilterSheet extends StatefulWidget {
  const JobFilterSheet({
    super.key,
    required this.initial,
    required this.onApply,
  });

  final JobFilter initial;
  final ValueChanged<JobFilter> onApply;

  @override
  State<JobFilterSheet> createState() => _JobFilterSheetState();
}

class _JobFilterSheetState extends State<JobFilterSheet> {
  late final TextEditingController _province = TextEditingController(
    text: widget.initial.province ?? '',
  );
  late final TextEditingController _category = TextEditingController(
    text: widget.initial.category ?? '',
  );
  WorkMode? _workMode;
  bool? _hasAllowance;

  @override
  void initState() {
    super.initState();
    _workMode = widget.initial.workMode;
    _hasAllowance = widget.initial.hasAllowance;
  }

  @override
  void dispose() {
    _province.dispose();
    _category.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kPagePadding, 0, kPagePadding, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('ตัวกรอง', style: textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'จังหวัด รูปแบบงาน หมวดงาน และเบี้ยเลี้ยง',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _province,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'จังหวัด',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<WorkMode?>(
                key: ValueKey(_workMode),
                initialValue: _workMode,
                decoration: const InputDecoration(labelText: 'รูปแบบงาน'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('ทั้งหมด')),
                  for (final mode in WorkMode.values)
                    DropdownMenuItem(
                      value: mode,
                      child: Text(workModeLabel(mode)),
                    ),
                ],
                onChanged: (value) => setState(() => _workMode = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _category,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'หมวดงาน',
                  prefixIcon: const Icon(Icons.category_outlined),
                  suffixIcon: _category.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'ล้างหมวดงาน',
                          onPressed: () => setState(() => _category.clear()),
                          icon: const Icon(Icons.clear, size: 20),
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final cat in [
                    'IT & Software',
                    'Design & UX/UI',
                    'Marketing',
                    'Data',
                  ])
                    ActionChip(
                      label: Text(cat),
                      avatar: _category.text.trim() == cat
                          ? const Icon(Icons.check, size: 16)
                          : null,
                      onPressed: () {
                        setState(() {
                          if (_category.text.trim() == cat) {
                            _category.clear();
                          } else {
                            _category.text = cat;
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('เบี้ยเลี้ยง', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _AllowanceChoice(
                    label: 'ทั้งหมด',
                    selected: _hasAllowance == null,
                    onSelected: () => setState(() => _hasAllowance = null),
                  ),
                  _AllowanceChoice(
                    label: 'มีเบี้ยเลี้ยง',
                    selected: _hasAllowance == true,
                    onSelected: () => setState(() => _hasAllowance = true),
                  ),
                  _AllowanceChoice(
                    label: 'ไม่มีเบี้ยเลี้ยง',
                    selected: _hasAllowance == false,
                    onSelected: () => setState(() => _hasAllowance = false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppPrimaryButton(
                onPressed: () => widget.onApply(_currentFilter()),
                child: const Text('ใช้ตัวกรอง'),
              ),
              TextButton(
                onPressed: () {
                  widget.onApply(JobFilter(search: widget.initial.search));
                },
                child: const Text('ล้างตัวกรอง'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  JobFilter _currentFilter() {
    return JobFilter(
      search: widget.initial.search,
      province: _emptyToNull(_province.text),
      workMode: _workMode,
      category: _emptyToNull(_category.text),
      hasAllowance: _hasAllowance,
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _AllowanceChoice extends StatelessWidget {
  const _AllowanceChoice({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: selected ? scheme.onPrimary : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.surface;
      }),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.line),
      onSelected: (_) => onSelected(),
    );
  }
}
