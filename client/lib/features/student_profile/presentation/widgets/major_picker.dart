import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/major.dart';
import '../providers/student_profile_controller.dart';

Future<MajorChoice?> showMajorPicker(
  BuildContext context, {
  String? selectedId,
  String? customName,
}) => showModalBottomSheet<MajorChoice>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _MajorPicker(selectedId: selectedId, customName: customName),
);

class _MajorPicker extends ConsumerStatefulWidget {
  const _MajorPicker({this.selectedId, this.customName});
  final String? selectedId;
  final String? customName;
  @override
  ConsumerState<_MajorPicker> createState() => _MajorPickerState();
}

class _MajorPickerState extends ConsumerState<_MajorPicker> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String? _settled = '';
  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _settled == null
        ? const AsyncLoading<List<Major>>()
        : ref.watch(majorsSearchProvider(_settled!));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: math.min(
          640,
          math.max(280, MediaQuery.sizeOf(context).height * .82),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('เลือกสาขา', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'ค้นหาสาขา',
                  hintText: 'เช่น วิศว',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'ล้างคำค้นหา',
                          onPressed: () {
                            _controller.clear();
                            _setQuery('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                onChanged: _setQuery,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: results.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => _errorState(),
                  data: (items) => ListView(
                    children: [
                      if (items.isEmpty) _customActionTile('ไม่พบสาขาที่ค้นหา'),
                      ...items.map(
                        (major) => ListTile(
                          key: ValueKey('major-${major.id}'),
                          title: Text(major.nameTh),
                          trailing: major.id == widget.selectedId
                              ? const Icon(Icons.check)
                              : null,
                          onTap: () => Navigator.of(
                            context,
                          ).pop(MajorChoice.master(major)),
                        ),
                      ),
                      if (_query.trim().isNotEmpty &&
                          !items.any(
                            (m) => _normalize(m.nameTh) == _normalize(_query),
                          )) ...[
                        const Divider(),
                        _customActionTile(
                          'ใช้ “${_query.trim()}” เป็นชื่อสาขา',
                        ),
                      ],
                      if (widget.customName?.isNotEmpty == true)
                        ListTile(
                          leading: const Icon(Icons.edit_outlined),
                          title: const Text('สาขาที่กรอกเอง'),
                          subtitle: Text(widget.customName!),
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

  Widget _errorState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('โหลดรายชื่อสาขาไม่สำเร็จ'),
        TextButton(
          onPressed: () => ref.invalidate(majorsSearchProvider(_settled!)),
          child: const Text('ลองใหม่'),
        ),
        if (_query.trim().isNotEmpty)
          _customActionTile('ใช้ “${_query.trim()}” เป็นชื่อสาขา'),
      ],
    ),
  );
  Widget _customActionTile(String title) => ListTile(
    leading: const Icon(Icons.edit_outlined),
    title: Text(title),
    onTap: () {
      final value = _query.trim();
      if (value.isNotEmpty) {
        Navigator.of(context).pop(MajorChoice.custom(value));
      }
    },
  );
  void _setQuery(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (mounted) setState(() => _settled = _query.trim());
    });
  }

  String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();
}
