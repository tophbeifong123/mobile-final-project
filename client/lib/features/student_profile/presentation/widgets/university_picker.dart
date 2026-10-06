import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/university.dart';
import '../providers/student_profile_controller.dart';

Future<UniversityChoice?> showUniversityPicker(
  BuildContext context, {
  String? selectedId,
  String? customName,
}) => showModalBottomSheet<UniversityChoice>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) =>
      _UniversityPickerSheet(selectedId: selectedId, customName: customName),
);

class _UniversityPickerSheet extends ConsumerStatefulWidget {
  const _UniversityPickerSheet({this.selectedId, this.customName});
  final String? selectedId;
  final String? customName;

  @override
  ConsumerState<_UniversityPickerSheet> createState() =>
      _UniversityPickerSheetState();
}

class _UniversityPickerSheetState
    extends ConsumerState<_UniversityPickerSheet> {
  final _searchController = TextEditingController();
  final _customController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String? _settledQuery = '';
  bool _customMode = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final height = math.min(
      640.0,
      math.max(280.0, MediaQuery.sizeOf(context).height * .82),
    );
    final results = _settledQuery == null
        ? const AsyncLoading<List<University>>()
        : ref.watch(universitiesSearchProvider(_settledQuery!));

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'เลือกมหาวิทยาลัย',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (!_customMode)
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: 'ค้นหามหาวิทยาลัย',
                    hintText: 'ชื่อเต็ม หรือคำย่อ เช่น ม.อ. / PSU',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'ล้างคำค้นหา',
                            onPressed: () {
                              _searchController.clear();
                              _setQuery('');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  onChanged: _setQuery,
                )
              else
                TextField(
                  controller: _customController,
                  autofocus: true,
                  maxLength: 255,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อสถาบัน',
                    hintText: 'พิมพ์ชื่อสถาบันของคุณ',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submitCustom(),
                ),
              const SizedBox(height: 8),
              if (_customMode) ...[
                ListTile(
                  leading: const Icon(Icons.arrow_back),
                  title: const Text('กลับไปค้นหารายการ'),
                  onTap: () => setState(() => _customMode = false),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _customController.text.trim().isEmpty
                      ? null
                      : _submitCustom,
                  child: const Text('ใช้ชื่อนี้'),
                ),
              ] else
                Expanded(
                  child: results.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('โหลดรายชื่อมหาวิทยาลัยไม่สำเร็จ'),
                          TextButton(
                            onPressed: () => ref.invalidate(
                              universitiesSearchProvider(_settledQuery!),
                            ),
                            child: const Text('ลองใหม่'),
                          ),
                        ],
                      ),
                    ),
                    data: (items) => ListView(
                      children: [
                        if (items.isEmpty)
                          const ListTile(
                            title: Text('ไม่พบมหาวิทยาลัยที่ค้นหา'),
                          ),
                        ...items.map(
                          (university) => ListTile(
                            key: ValueKey('university-${university.id}'),
                            title: Text(university.nameTh),
                            trailing: university.id == widget.selectedId
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () => Navigator.of(context).pop(
                              UniversityChoice.master(
                                university.id,
                                university.nameTh,
                              ),
                            ),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.edit_outlined),
                          title: const Text('อื่นๆ — พิมพ์ชื่อสถาบันเอง'),
                          subtitle: widget.customName?.isNotEmpty == true
                              ? Text('ปัจจุบัน: ${widget.customName}')
                              : null,
                          onTap: () => setState(() => _customMode = true),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _setQuery(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (mounted) setState(() => _settledQuery = _query.trim());
    });
  }

  void _submitCustom() {
    final value = _customController.text.trim();
    if (value.isNotEmpty) {
      Navigator.of(context).pop(UniversityChoice.custom(value));
    }
  }
}
