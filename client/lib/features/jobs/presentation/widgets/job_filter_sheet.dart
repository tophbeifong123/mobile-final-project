import 'package:flutter/material.dart';

import '../../domain/entities/job.dart';

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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filter', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _province,
              decoration: const InputDecoration(labelText: 'Province'),
            ),
            DropdownButtonFormField<WorkMode>(
              initialValue: _workMode,
              decoration: const InputDecoration(labelText: 'Work mode'),
              items: WorkMode.values
                  .map(
                    (mode) =>
                        DropdownMenuItem(value: mode, child: Text(mode.name)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _workMode = value),
            ),
            TextField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Has allowance'),
              value: _hasAllowance ?? false,
              onChanged: (value) => setState(() => _hasAllowance = value),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                widget.onApply(
                  JobFilter(
                    search: widget.initial.search,
                    province: _emptyToNull(_province.text),
                    workMode: _workMode,
                    category: _emptyToNull(_category.text),
                    hasAllowance: _hasAllowance,
                  ),
                );
              },
              child: const Text('Apply filter'),
            ),
          ],
        ),
      ),
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
