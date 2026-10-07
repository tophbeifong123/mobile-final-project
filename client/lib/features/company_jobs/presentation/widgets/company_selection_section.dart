import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../applications/domain/selection_progress.dart';
import '../../domain/entities/company_job.dart';
import 'company_applicant_widgets.dart';

class CompanySelectionSection extends StatelessWidget {
  const CompanySelectionSection({
    super.key,
    required this.applicant,
    required this.onEditExam,
    required this.onPassExam,
    required this.onEditInterview,
    this.busy = false,
    this.now,
  });

  final Applicant applicant;
  final VoidCallback? onEditExam;
  final VoidCallback? onPassExam;
  final VoidCallback? onEditInterview;
  final bool busy;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final reviewing = applicant.status.trim().toLowerCase() == 'reviewing';
    final examUrl = applicant.examUrl;
    final hasExam = examUrl != null && examUrl.isNotEmpty;
    final completed = applicant.examCompletedAt != null;
    final passed = applicant.examPassedAt != null;
    final expired =
        hasExam &&
        !completed &&
        applicant.examDeadline != null &&
        (now ?? DateTime.now()).isAfter(applicant.examDeadline!);
    final onSite = applicant.interviewMode == 'on_site';
    final interviewUrl = applicant.interviewUrl;
    final hasInterview = onSite
        ? applicant.interviewStartsAt != null
        : interviewUrl != null && interviewUrl.isNotEmpty;
    final interviewLocked = reviewing && !passed;
    if (!reviewing && !hasExam && !hasInterview) {
      return const SizedBox.shrink();
    }

    final examBody = !hasExam
        ? 'ยังไม่ได้ส่งลิงก์ข้อสอบ'
        : completed
        ? passed
              ? 'ตรวจว่าข้อสอบผ่านแล้วเมื่อ ${formatSelectionWhen(applicant.examPassedAt!)}'
              : 'นักศึกษาทำข้อสอบแล้วเมื่อ ${formatSelectionWhen(applicant.examCompletedAt!)}'
        : expired
        ? 'เลยกำหนด ${formatSelectionWhen(applicant.examDeadline!)}'
        : applicant.examDeadline == null
        ? 'ยังไม่กำหนดเวลาส่ง'
        : 'กำหนดส่ง ${formatSelectionWhen(applicant.examDeadline!)}';

    return Column(
      children: [
        CompanyApplicantCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ข้อสอบ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const Gap(6),
              Text(examBody),
              if (hasExam) ...[
                const Gap(4),
                Text(examUrl, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              if (reviewing && !completed) ...[
                const Gap(12),
                NeoButton(
                  text: hasExam ? 'แก้ลิงก์ข้อสอบ' : 'ส่งลิงก์ข้อสอบ',
                  variant: NeoButtonVariant.outline,
                  isFullWidth: true,
                  onPressed: busy ? null : onEditExam,
                ),
              ],
              if (reviewing && completed && !passed) ...[
                const Gap(12),
                NeoButton(
                  text: 'ข้อสอบผ่าน',
                  isFullWidth: true,
                  onPressed: busy ? null : onPassExam,
                ),
              ],
            ],
          ),
        ),
        const Gap(16),
        CompanyApplicantCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                onSite ? 'นัดสัมภาษณ์ออนไซต์' : 'นัดสัมภาษณ์ออนไลน์',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Gap(6),
              Text(
                interviewLocked
                    ? completed
                          ? 'เรียกสัมภาษณ์ได้หลังตรวจว่าข้อสอบผ่าน'
                          : expired
                          ? 'นักศึกษาไม่ได้ทำข้อสอบภายในกำหนด จึงเรียกสัมภาษณ์ไม่ได้'
                          : 'เรียกสัมภาษณ์ได้หลังนักศึกษาทำข้อสอบแล้ว'
                    : hasInterview
                    ? onSite
                          ? 'นัดที่สำนักงานวันที่ ${applicant.interviewStartsAt == null ? '-' : formatSelectionWhen(applicant.interviewStartsAt!)}'
                          : 'นัดวันที่ ${applicant.interviewStartsAt == null ? '-' : formatSelectionWhen(applicant.interviewStartsAt!)}'
                    : onSite
                    ? 'ยังไม่ได้นัดที่สำนักงาน'
                    : 'ยังไม่ได้ส่งลิงก์นัด',
              ),
              if (hasInterview && !onSite && interviewUrl != null) ...[
                const Gap(4),
                Text(
                  interviewUrl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (reviewing && passed) ...[
                const Gap(12),
                NeoButton(
                  text: hasInterview
                      ? (onSite ? 'แก้เวลานัด' : 'แก้ลิงก์นัด')
                      : (onSite ? 'นัดที่สำนักงาน' : 'ส่งลิงก์นัด'),
                  variant: NeoButtonVariant.outline,
                  isFullWidth: true,
                  onPressed: busy ? null : onEditInterview,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SelectionLinkDialog extends StatefulWidget {
  const SelectionLinkDialog({
    super.key,
    required this.title,
    required this.timeLabel,
    this.initialUrl = '',
    this.initialWhen,
    this.requireUrl = true,
  });

  final String title;
  final String timeLabel;
  final String initialUrl;
  final DateTime? initialWhen;
  final bool requireUrl;

  @override
  State<SelectionLinkDialog> createState() => _SelectionLinkDialogState();
}

class _SelectionLinkDialogState extends State<SelectionLinkDialog> {
  late final TextEditingController _url = TextEditingController(
    text: widget.initialUrl,
  );
  late DateTime _when =
      widget.initialWhen ?? DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _when.isBefore(DateTime.now()) ? DateTime.now() : _when,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (time == null || !mounted) return;
    setState(() {
      _when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: NeoColors.paperCanvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: NeoColors.inkSolid, width: 2),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.requireUrl) ...[
            TextField(
              controller: _url,
              decoration: const InputDecoration(
                labelText: 'ลิงก์',
                hintText: 'https://',
              ),
            ),
            const Gap(12),
          ],
          OutlinedButton(
            onPressed: _pickWhen,
            child: Text('${widget.timeLabel}: ${formatSelectionWhen(_when)}'),
          ),
        ],
      ),
      actions: [
        NeoButton(
          text: 'ยกเลิก',
          variant: NeoButtonVariant.outline,
          onPressed: () => Navigator.pop(context),
        ),
        NeoButton(
          text: 'บันทึก',
          onPressed: () {
            final url = _url.text.trim();
            if (widget.requireUrl &&
                !url.startsWith('http://') &&
                !url.startsWith('https://')) {
              return;
            }
            Navigator.pop(context, (
              url: widget.requireUrl ? url : '',
              when: _when,
            ));
          },
        ),
      ],
    );
  }
}
