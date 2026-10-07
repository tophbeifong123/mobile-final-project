import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../student_profile/domain/entities/student_profile.dart';
import '../../domain/entities/company_contact_policy.dart';

class CompanyContactLinksEditor extends StatelessWidget {
  const CompanyContactLinksEditor({
    super.key,
    required this.links,
    required this.onChanged,
  });

  final List<ContactLink> links;
  final ValueChanged<List<ContactLink>> onChanged;

  @override
  Widget build(BuildContext context) {
    final canAdd = links.length < maxCompanyContacts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'นักศึกษาเห็นช่องทางนี้ในรายละเอียดงาน เว้นว่างได้ และไม่ใช่อีเมลที่ใช้เข้าสู่ระบบ',
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: NeoColors.subtleInk,
          ),
        ),
        const Gap(12),
        if (links.isEmpty)
          const Text(
            'ยังไม่มีช่องทางติดต่อ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: NeoColors.inkSolid,
            ),
          )
        else
          for (var index = 0; index < links.length; index++) ...[
            if (index > 0) const Gap(8),
            _ContactRow(
              link: links[index],
              onEdit: () =>
                  _edit(context, existing: links[index], index: index),
              onDelete: () {
                final next = List<ContactLink>.from(links)..removeAt(index);
                onChanged(next);
              },
            ),
          ],
        const Gap(12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('add-company-contact'),
            onPressed: canAdd ? () => _edit(context) : null,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              canAdd ? 'เพิ่มช่องทาง' : companyContactLimitError,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _edit(
    BuildContext context, {
    ContactLink? existing,
    int? index,
  }) async {
    final saved = await showDialog<ContactLink>(
      context: context,
      builder: (context) => _ContactDialog(existing: existing),
    );
    if (saved == null) return;
    final next = List<ContactLink>.from(links);
    if (index != null && index >= 0 && index < next.length) {
      next[index] = saved;
    } else {
      next.add(saved);
    }
    onChanged(next);
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.link,
    required this.onEdit,
    required this.onDelete,
  });

  final ContactLink link;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final caption = (link.label != null && link.label!.trim().isNotEmpty)
        ? link.label!.trim()
        : companyContactPlatformLabel(link.platform);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: NeoColors.paperCanvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NeoColors.inkSolid, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            _platformIcon(link.platform),
            size: 18,
            color: NeoColors.inkSolid,
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: NeoColors.subtleInk,
                  ),
                ),
                Text(
                  link.value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: NeoColors.inkSolid,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'แก้ไข',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 18),
          ),
          IconButton(
            tooltip: 'ลบ',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ContactDialog extends StatefulWidget {
  const _ContactDialog({this.existing});

  final ContactLink? existing;

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _platform;
  late final TextEditingController _label;
  late final TextEditingController _value;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing?.platform.toLowerCase();
    _platform = companyContactPlatformLabels.containsKey(existing)
        ? existing!
        : 'phone';
    _label = TextEditingController(text: widget.existing?.label ?? '');
    _value = TextEditingController(text: widget.existing?.value ?? '');
  }

  @override
  void dispose() {
    _label.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: NeoColors.pureWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: NeoColors.inkSolid, width: 2),
      ),
      title: Text(
        widget.existing == null ? 'เพิ่มช่องทางติดต่อ' : 'แก้ไขช่องทางติดต่อ',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ประเภท',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const Gap(6),
              DropdownButtonFormField<String>(
                initialValue: _platform,
                items: [
                  for (final entry in companyContactPlatformLabels.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _platform = value);
                },
              ),
              const Gap(12),
              TextFormField(
                controller: _value,
                keyboardType: _platform == 'phone'
                    ? TextInputType.phone
                    : _platform == 'email'
                    ? TextInputType.emailAddress
                    : TextInputType.text,
                decoration: InputDecoration(
                  labelText: companyContactPlatformLabel(_platform),
                ),
                validator: (value) =>
                    validateCompanyContactValue(_platform, value),
              ),
              const Gap(12),
              TextFormField(
                controller: _label,
                decoration: const InputDecoration(
                  labelText: 'ป้ายชื่อ (ไม่จำเป็น)',
                  hintText: 'เช่น ฝ่ายบุคคล',
                ),
                validator: (value) {
                  if ((value?.trim().length ?? 0) > 100) {
                    return 'ป้ายชื่อต้องไม่เกิน 100 ตัวอักษร';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final label = _label.text.trim();
            Navigator.of(context).pop(
              ContactLink(
                id: widget.existing?.id,
                platform: _platform,
                label: label.isEmpty ? null : label,
                value: _value.text.trim(),
              ),
            );
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}

IconData _platformIcon(String platform) {
  return switch (platform.toLowerCase()) {
    'phone' => Icons.phone_rounded,
    'email' => Icons.email_rounded,
    'line' => Icons.chat_bubble_rounded,
    'linkedin' => Icons.work_rounded,
    'facebook' => Icons.facebook_rounded,
    'instagram' => Icons.camera_alt_rounded,
    _ => Icons.link_rounded,
  };
}
