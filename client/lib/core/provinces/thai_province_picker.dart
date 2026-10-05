import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'thai_province.dart';
import 'thai_provinces_provider.dart';

/// Opens a searchable list backed by the canonical province master.
/// Returns null when the user dismisses the sheet without selecting anything.
Future<ThaiProvince?> showThaiProvincePicker(
  BuildContext context, {
  int? selectedProvinceId,
}) {
  return showModalBottomSheet<ThaiProvince>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) =>
        _ThaiProvincePickerSheet(selectedProvinceId: selectedProvinceId),
  );
}

class _ThaiProvincePickerSheet extends ConsumerStatefulWidget {
  const _ThaiProvincePickerSheet({this.selectedProvinceId});

  final int? selectedProvinceId;

  @override
  ConsumerState<_ThaiProvincePickerSheet> createState() =>
      _ThaiProvincePickerSheetState();
}

class _ThaiProvincePickerSheetState
    extends ConsumerState<_ThaiProvincePickerSheet> {
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
    final provinces = ref.watch(thaiProvincesProvider);

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
                'เลือกจังหวัด',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: false,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'ค้นหาจังหวัด',
                  hintText: 'เช่น สงขลา หรือ กทม.',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'ล้างคำค้นจังหวัด',
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
                child: provinces.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('โหลดรายชื่อจังหวัดไม่สำเร็จ'),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(thaiProvincesProvider),
                          child: const Text('ลองใหม่'),
                        ),
                      ],
                    ),
                  ),
                  data: (items) {
                    final matches = items
                        .where((province) => province.matches(_query))
                        .toList(growable: false);
                    if (matches.isEmpty) {
                      return const Center(child: Text('ไม่พบจังหวัดที่ค้นหา'));
                    }
                    return ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final province = matches[index];
                        final selected =
                            province.id == widget.selectedProvinceId;
                        return ListTile(
                          key: ValueKey('province-${province.id}'),
                          title: Text(province.nameTh),
                          subtitle: province.aliases.isEmpty
                              ? null
                              : Text(province.aliases.join(', ')),
                          trailing: selected ? const Icon(Icons.check) : null,
                          onTap: () => Navigator.of(context).pop(province),
                        );
                      },
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
