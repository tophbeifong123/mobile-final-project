import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/neo_button.dart';
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

    return SingleChildScrollView(
      child: Column(
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
            child: NeoButton(
              key: const Key('add-company-contact'),
              onPressed: canAdd ? () => _edit(context) : null,
              variant: NeoButtonVariant.secondary,
              height: 44,
              text: 'เพิ่มช่องทาง',
              icon: const Icon(Icons.add_rounded, size: 18),
            ),
          ),
          if (!canAdd) ...[
            const Gap(4),
            const Text(
              companyContactLimitError,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: NeoColors.subtleInk,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context, {
    ContactLink? existing,
    int? index,
  }) async {
    final saved = await showDialog<ContactLink>(
      context: context,
      builder: (context) => _ContactDialog(
        existing: existing,
        initialPlatform: links.isEmpty ? null : links.last.platform,
      ),
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
        border: Border.all(color: NeoColors.inkSolid, width: 1.2),
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
  const _ContactDialog({this.existing, this.initialPlatform});

  final ContactLink? existing;
  final String? initialPlatform;

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
    final platform =
        widget.existing?.platform.toLowerCase() ??
        widget.initialPlatform?.toLowerCase();
    _platform = companyContactPlatformLabels.containsKey(platform)
        ? platform!
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
    final media = MediaQuery.of(context);
    final availableHeight = media.size.height - media.viewInsets.bottom - 48;
    final isCompact = media.size.width < 360;
    final title = widget.existing == null
        ? 'เพิ่มช่องทางติดต่อ'
        : 'แก้ไขช่องทางติดต่อ';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 16,
        vertical: 24,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: availableHeight.clamp(180, media.size.height).toDouble(),
        ),
        padding: EdgeInsets.all(isCompact ? 12 : 20),
        decoration: BoxDecoration(
          color: NeoColors.pureWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: NeoColors.inkSolid, width: 2),
          boxShadow: NeoShadows.elevation3,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                  ),
                  const Gap(12),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      key: const Key('close-company-contact-dialog'),
                      tooltip: 'ยกเลิก',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      style: IconButton.styleFrom(
                        foregroundColor: NeoColors.inkSolid,
                        backgroundColor: NeoColors.surfaceCream,
                        side: const BorderSide(
                          color: NeoColors.inkSolid,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(16),
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ประเภท',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Gap(6),
                      DropdownButtonFormField<String>(
                        initialValue: _platform,
                        decoration: _contactInputDecoration(),
                        items: [
                          for (final entry
                              in companyContactPlatformLabels.entries)
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
                      const Gap(14),
                      _ContactFieldLabel(
                        '${companyContactPlatformLabel(_platform)} *',
                      ),
                      const Gap(6),
                      TextFormField(
                        controller: _value,
                        keyboardType: _platform == 'phone'
                            ? TextInputType.phone
                            : _platform == 'email'
                            ? TextInputType.emailAddress
                            : TextInputType.text,
                        decoration: _contactInputDecoration(
                          hintText: _contactValueHint(_platform),
                        ),
                        validator: (value) =>
                            validateCompanyContactValue(_platform, value),
                      ),
                      const Gap(14),
                      const _ContactFieldLabel(
                        'ชื่อเรียก / ป้ายกำกับ (ไม่จำเป็น)',
                      ),
                      const Gap(6),
                      TextFormField(
                        controller: _label,
                        decoration: _contactInputDecoration(
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
              const Gap(18),
              NeoButton(
                key: const Key('save-company-contact'),
                onPressed: _save,
                variant: NeoButtonVariant.primary,
                isFullWidth: true,
                height: 52,
                text: 'บันทึก',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
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
  }
}

class _ContactFieldLabel extends StatelessWidget {
  const _ContactFieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: NeoColors.inkSolid,
      ),
    );
  }
}

String _contactValueHint(String platform) {
  return switch (platform) {
    'phone' => 'เช่น 0812345678',
    'email' => 'เช่น contact@example.com',
    'other' => 'เช่น https://example.com',
    _ => 'กรอกข้อมูลติดต่อ',
  };
}

InputDecoration _contactInputDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: NeoColors.pureWhite,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: NeoColors.inkSolid, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: NeoColors.inkSolid, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: NeoColors.inkSolid, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: NeoColors.errorBorder, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: NeoColors.errorBorder, width: 2),
    ),
  );
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
