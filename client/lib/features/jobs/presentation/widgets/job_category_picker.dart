import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../job_categories.dart';

/// Opens the shared category list. Returns null when the sheet is dismissed.
Future<String?> showJobCategoryPicker(
  BuildContext context, {
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _JobCategoryPickerSheet(selected: selected),
  );
}

class _JobCategoryPickerSheet extends StatefulWidget {
  const _JobCategoryPickerSheet({this.selected});

  final String? selected;

  @override
  State<_JobCategoryPickerSheet> createState() =>
      _JobCategoryPickerSheetState();
}

class _JobCategoryPickerSheetState extends State<_JobCategoryPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight = MediaQuery.sizeOf(context).height - keyboardHeight;
    final height = math.min(600.0, math.max(220.0, availableHeight * 0.8));
    final query = _query.trim().toLowerCase();
    final matches = [
      for (final category in jobCategories)
        if (query.isEmpty || category.toLowerCase().contains(query)) category,
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'เลือกหมวดงาน',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'ค้นหาหมวดงาน',
                  hintText: 'เช่น Software หรือ Design',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'ล้างคำค้นหมวดงาน',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: matches.isEmpty
                    ? const Center(child: Text('ไม่พบหมวดงานที่ค้นหา'))
                    : ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final category = matches[index];
                          final selected = category == widget.selected;
                          return ListTile(
                            key: ValueKey('category-$category'),
                            title: Text(category),
                            trailing: selected ? const Icon(Icons.check) : null,
                            onTap: () => Navigator.of(context).pop(category),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
