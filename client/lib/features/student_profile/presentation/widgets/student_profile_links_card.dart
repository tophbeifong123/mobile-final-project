import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/student_profile.dart';

class LinkPlatformHelper {
  static const Map<
    String,
    ({String name, IconData icon, Color color, bool isUrl})
  >
  platforms = {
    'portfolio': (
      name: 'ผลงาน / Portfolio',
      icon: Icons.folder_special_rounded,
      color: NeoColors.butterYellow,
      isUrl: true,
    ),
    'github': (
      name: 'GitHub',
      icon: Icons.code_rounded,
      color: NeoColors.pureWhite,
      isUrl: true,
    ),
    'figma': (
      name: 'Figma / Design',
      icon: Icons.draw_rounded,
      color: NeoColors.pastelCoral,
      isUrl: true,
    ),
    'website': (
      name: 'เว็บไซต์ / Blog',
      icon: Icons.language_rounded,
      color: NeoColors.skyBlue,
      isUrl: true,
    ),
    'linkedin': (
      name: 'LinkedIn',
      icon: Icons.work_rounded,
      color: NeoColors.skyBlue,
      isUrl: true,
    ),
    'phone': (
      name: 'เบอร์โทรศัพท์',
      icon: Icons.phone_rounded,
      color: NeoColors.freshMint,
      isUrl: false,
    ),
    'email': (
      name: 'อีเมล',
      icon: Icons.email_rounded,
      color: NeoColors.softRose,
      isUrl: false,
    ),
    'line': (
      name: 'Line ID',
      icon: Icons.chat_bubble_rounded,
      color: NeoColors.freshMint,
      isUrl: false,
    ),
    'facebook': (
      name: 'Facebook',
      icon: Icons.facebook_rounded,
      color: NeoColors.softLilac,
      isUrl: false,
    ),
    'instagram': (
      name: 'Instagram',
      icon: Icons.camera_alt_rounded,
      color: NeoColors.pastelCoral,
      isUrl: false,
    ),
    'other': (
      name: 'อื่นๆ',
      icon: Icons.link_rounded,
      color: NeoColors.paperCanvas,
      isUrl: false,
    ),
  };

  static ({String name, IconData icon, Color color, bool isUrl}) getInfo(
    String platform,
  ) {
    return platforms[platform.toLowerCase()] ??
        (
          name: platform,
          icon: Icons.link_rounded,
          color: NeoColors.paperCanvas,
          isUrl: false,
        );
  }
}

/// Unified Links and Portfolio Card for Student Profile Screen
class StudentProfileLinksCard extends StatelessWidget {
  const StudentProfileLinksCard({
    super.key,
    required this.links,
    required this.onChanged,
  });

  final List<ContactLink> links;
  final ValueChanged<List<ContactLink>> onChanged;

  void _showAddEditDialog(
    BuildContext context, [
    ContactLink? existing,
    int? index,
  ]) {
    final formKey = GlobalKey<FormState>();
    var selectedPlatform = existing?.platform ?? 'portfolio';
    if (!LinkPlatformHelper.platforms.containsKey(selectedPlatform)) {
      selectedPlatform = 'other';
    }
    final labelController = TextEditingController(text: existing?.label ?? '');
    final valueController = TextEditingController(text: existing?.value ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final platformInfo = LinkPlatformHelper.getInfo(selectedPlatform);

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: NeoColors.inkSolid, width: 2),
            ),
            backgroundColor: NeoColors.pureWhite,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    existing != null
                        ? 'แก้ไขผลงาน / ช่องทางติดต่อ'
                        : 'เพิ่มผลงาน / ช่องทางติดต่อ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: NeoColors.inkSolid,
                      fontSize: 17,
                    ),
                  ),
                ),
                const Gap(8),
                InkWell(
                  onTap: () => Navigator.of(dialogCtx).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: NeoColors.paperCanvas,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: NeoColors.inkSolid,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ประเภท / แพลตฟอร์ม',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                    const Gap(6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: NeoColors.paperCanvas,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: NeoColors.mutedInk,
                          width: 1.5,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPlatform,
                          isExpanded: true,
                          items: LinkPlatformHelper.platforms.entries.map((
                            entry,
                          ) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Row(
                                children: [
                                  Icon(
                                    entry.value.icon,
                                    size: 18,
                                    color: NeoColors.inkSolid,
                                  ),
                                  const Gap(8),
                                  Expanded(
                                    child: Text(
                                      entry.value.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: NeoColors.inkSolid,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedPlatform = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const Gap(12),
                    Text(
                      platformInfo.isUrl
                          ? 'ลิงก์ URL *'
                          : 'ข้อมูลติดต่อ (เบอร์, ID หรือ URL) *',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                    const Gap(6),
                    TextFormField(
                      controller: valueController,
                      keyboardType: platformInfo.isUrl
                          ? TextInputType.url
                          : TextInputType.text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: NeoColors.inkSolid,
                      ),
                      decoration: InputDecoration(
                        hintText: platformInfo.isUrl
                            ? 'https://...'
                            : 'เช่น 0812345678, user@example.com หรือ @myline',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: NeoColors.mutedInk,
                        ),
                        filled: true,
                        fillColor: NeoColors.paperCanvas,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: NeoColors.inkSolid,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: NeoColors.mutedInk,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: NeoColors.inkSolid,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (val) {
                        final trimmed = val?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'กรุณากรอกข้อมูลนี้';
                        }
                        if (platformInfo.isUrl) {
                          final uri = Uri.tryParse(trimmed);
                          if (uri == null ||
                              (uri.scheme != 'http' && uri.scheme != 'https') ||
                              uri.host.isEmpty) {
                            return 'ใส่ลิงก์ที่ขึ้นต้นด้วย https:// หรือ http://';
                          }
                        }
                        return null;
                      },
                    ),
                    const Gap(12),
                    const Text(
                      'ชื่อเรียก / ป้ายกำกับ (ตัวเลือกเพิ่มเติม)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                    const Gap(6),
                    TextFormField(
                      controller: labelController,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: NeoColors.inkSolid,
                      ),
                      decoration: InputDecoration(
                        hintText: platformInfo.isUrl
                            ? 'เช่น โปรเจกต์แอปร้านค้า, Portfolio 2026'
                            : 'เช่น เบอร์ส่วนตัว, อีเมลสำรอง',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: NeoColors.mutedInk,
                        ),
                        filled: true,
                        fillColor: NeoColors.paperCanvas,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: NeoColors.inkSolid,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: NeoColors.mutedInk,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: NeoColors.inkSolid,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: NeoColors.electricIndigo,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(
                        color: NeoColors.inkSolid,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final item = ContactLink(
                        id: existing?.id,
                        platform: selectedPlatform,
                        label: labelController.text.trim().isEmpty
                            ? null
                            : labelController.text.trim(),
                        value: valueController.text.trim(),
                      );
                      final updated = List<ContactLink>.from(links);
                      if (index != null &&
                          index >= 0 &&
                          index < updated.length) {
                        updated[index] = item;
                      } else {
                        updated.add(item);
                      }
                      onChanged(updated);
                      Navigator.of(dialogCtx).pop();
                    }
                  },
                  child: const Text(
                    'บันทึก',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: NeoColors.pureWhite,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _removeLink(int index) {
    final updated = List<ContactLink>.from(links)..removeAt(index);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NeoColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeoColors.inkSolid, width: 2),
        boxShadow: const [
          BoxShadow(
            color: NeoColors.inkSolid,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: NeoColors.butterYellow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: NeoColors.inkSolid,
                      offset: Offset(1.5, 1.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.link_rounded,
                  size: 16,
                  color: NeoColors.inkSolid,
                ),
              ),
              const Gap(8),
              const Expanded(
                child: Text(
                  'ผลงานและช่องทางติดต่อ (Links)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: NeoColors.inkSolid,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showAddEditDialog(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: NeoColors.freshMint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: NeoColors.inkSolid,
                        offset: Offset(1.5, 1.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: NeoColors.inkSolid,
                      ),
                      Gap(4),
                      Text(
                        'เพิ่ม',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.inkSolid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Gap(14),

          if (links.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: NeoColors.paperCanvas,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: NeoColors.mutedInk,
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.share_outlined,
                    size: 28,
                    color: NeoColors.mutedInk,
                  ),
                  Gap(6),
                  Text(
                    'ยังไม่มีผลงานหรือช่องทางการติดต่อ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: NeoColors.mutedInk,
                    ),
                  ),
                  Gap(2),
                  Text(
                    'กดปุ่ม "+ เพิ่ม" เพื่อเพิ่มผลงาน, GitHub, Portfolio หรือเบอร์ติดต่อ',
                    style: TextStyle(fontSize: 11, color: NeoColors.mutedInk),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: links.length,
              separatorBuilder: (_, _) => const Gap(8),
              itemBuilder: (context, i) {
                final item = links[i];
                final info = LinkPlatformHelper.getInfo(item.platform);

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: NeoColors.pureWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: NeoColors.inkSolid,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: info.color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: NeoColors.inkSolid,
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          info.icon,
                          size: 18,
                          color: NeoColors.inkSolid,
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              children: [
                                Text(
                                  item.label != null && item.label!.isNotEmpty
                                      ? item.label!
                                      : info.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: NeoColors.inkSolid,
                                  ),
                                ),
                                if (item.label != null &&
                                    item.label!.isNotEmpty)
                                  Text(
                                    '(${info.name})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: NeoColors.mutedInk,
                                    ),
                                  ),
                              ],
                            ),
                            const Gap(2),
                            SelectableText(
                              item.value,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: info.isUrl
                                    ? NeoColors.electricIndigo
                                    : NeoColors.inkSolid,
                                decoration: info.isUrl
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _showAddEditDialog(context, item, i),
                        tooltip: 'แก้ไข',
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: NeoColors.errorText,
                        ),
                        onPressed: () => _removeLink(i),
                        tooltip: 'ลบ',
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
