import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/student_profile.dart';

/// Dynamic Portfolio Projects Card for Student Profile Screen
class StudentProfilePortfolioCard extends StatelessWidget {
  const StudentProfilePortfolioCard({
    super.key,
    required this.portfolios,
    required this.onChanged,
  });

  final List<PortfolioLink> portfolios;
  final ValueChanged<List<PortfolioLink>> onChanged;

  void _showAddEditDialog(BuildContext context, [PortfolioLink? existing, int? index]) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: existing?.title ?? '');
    final urlController = TextEditingController(text: existing?.url ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: NeoColors.inkSolid, width: 2),
        ),
        backgroundColor: NeoColors.pureWhite,
        title: Text(
          existing != null ? 'แก้ไขผลงาน / โปรเจกต์' : 'เพิ่มผลงาน / โปรเจกต์',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: NeoColors.inkSolid,
            fontSize: 18,
          ),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ชื่อผลงาน / โปรเจกต์ *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: NeoColors.inkSolid,
                  ),
                ),
                const Gap(6),
                TextFormField(
                  controller: titleController,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: NeoColors.inkSolid,
                  ),
                  decoration: InputDecoration(
                    hintText: 'เช่น InternFinder Mobile App, GitHub Portfolio',
                    hintStyle: const TextStyle(fontSize: 13, color: NeoColors.mutedInk),
                    filled: true,
                    fillColor: NeoColors.paperCanvas,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: NeoColors.inkSolid, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: NeoColors.mutedInk, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: NeoColors.inkSolid, width: 2),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'กรุณาระบุชื่อผลงาน';
                    }
                    return null;
                  },
                ),
                const Gap(12),
                const Text(
                  'ลิงก์ผลงาน (URL) *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: NeoColors.inkSolid,
                  ),
                ),
                const Gap(6),
                TextFormField(
                  controller: urlController,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: NeoColors.inkSolid,
                  ),
                  decoration: InputDecoration(
                    hintText: 'https://github.com/... หรือ https://myproject.com',
                    hintStyle: const TextStyle(fontSize: 13, color: NeoColors.mutedInk),
                    filled: true,
                    fillColor: NeoColors.paperCanvas,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: NeoColors.inkSolid, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: NeoColors.mutedInk, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: NeoColors.inkSolid, width: 2),
                    ),
                  ),
                  validator: (val) {
                    final trimmed = val?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'กรุณากรอกลิงก์ผลงาน';
                    }
                    final uri = Uri.tryParse(trimmed);
                    if (uri == null ||
                        (uri.scheme != 'http' && uri.scheme != 'https') ||
                        uri.host.isEmpty) {
                      return 'ใส่ลิงก์ที่ขึ้นต้นด้วย https:// หรือ http://';
                    }
                    return null;
                  },
                ),
                const Gap(12),
                const Text(
                  'คำอธิบายสั้นๆ (ตัวเลือกเพิ่มเติม)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: NeoColors.inkSolid,
                  ),
                ),
                const Gap(6),
                TextFormField(
                  controller: descController,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: NeoColors.inkSolid,
                  ),
                  decoration: InputDecoration(
                    hintText: 'เช่น พัฒนาด้วย Flutter + NestJS รองรับทั้ง iOS & Android',
                    hintStyle: const TextStyle(fontSize: 13, color: NeoColors.mutedInk),
                    filled: true,
                    fillColor: NeoColors.paperCanvas,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: NeoColors.inkSolid, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: NeoColors.mutedInk, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: NeoColors.inkSolid, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: NeoColors.mutedInk,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: NeoColors.electricIndigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: NeoColors.inkSolid, width: 1.5),
              ),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final item = PortfolioLink(
                  id: existing?.id,
                  title: titleController.text.trim(),
                  url: urlController.text.trim(),
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                );
                final updated = List<PortfolioLink>.from(portfolios);
                if (index != null && index >= 0 && index < updated.length) {
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removePortfolio(int index) {
    final updated = List<PortfolioLink>.from(portfolios)..removeAt(index);
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
                  Icons.folder_special_rounded,
                  size: 16,
                  color: NeoColors.inkSolid,
                ),
              ),
              const Gap(8),
              const Expanded(
                child: Text(
                  'ผลงานและโปรเจกต์ (Portfolio)',
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      Icon(Icons.add_rounded, size: 16, color: NeoColors.inkSolid),
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

          if (portfolios.isEmpty)
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
                    Icons.work_history_outlined,
                    size: 28,
                    color: NeoColors.mutedInk,
                  ),
                  Gap(6),
                  Text(
                    'ยังไม่มีผลงานหรือโปรเจกต์ที่เพิ่มไว้',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: NeoColors.mutedInk,
                    ),
                  ),
                  Gap(2),
                  Text(
                    'กดปุ่ม "+ เพิ่ม" ด้านบนเพื่อเพิ่มผลงาน GitHub หรือ Portfolio',
                    style: TextStyle(
                      fontSize: 11,
                      color: NeoColors.mutedInk,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: portfolios.length,
              separatorBuilder: (_, _) => const Gap(10),
              itemBuilder: (context, i) {
                final item = portfolios[i];

                return Container(
                  padding: const EdgeInsets.all(12),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: NeoColors.softLilac,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: NeoColors.inkSolid, width: 1),
                            ),
                            child: const Icon(
                              Icons.rocket_launch_rounded,
                              size: 14,
                              color: NeoColors.inkSolid,
                            ),
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: NeoColors.inkSolid,
                              ),
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
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: NeoColors.errorText),
                            onPressed: () => _removePortfolio(i),
                            tooltip: 'ลบ',
                          ),
                        ],
                      ),
                      const Gap(4),
                      SelectableText(
                        item.url,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: NeoColors.electricIndigo,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      if (item.description != null && item.description!.isNotEmpty) ...[
                        const Gap(6),
                        Text(
                          item.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: NeoColors.mutedInk,
                          ),
                        ),
                      ],
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
