import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../resume/domain/entities/resume_file.dart';
import '../../../resume/presentation/providers/resume_controller.dart';
import 'resume_preview_modal.dart';

/// Active Resume Card for Student Profile Screen matching Neo-Brutalist design
class StudentProfileResumeCard extends ConsumerWidget {
  const StudentProfileResumeCard({super.key, required this.resumeFileName});

  final String? resumeFileName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents =
        ref.watch(studentDocumentsProvider).asData?.value ??
        const <StudentDocument>[];
    final cv = documents.where((document) => document.type == 'cv').firstOrNull;
    final transcript = documents
        .where((document) => document.type == 'transcript')
        .firstOrNull;
    final others = documents.where((document) => document.type == 'other');
    final activeResumeName = cv?.fileName ?? resumeFileName;
    final hasResume = activeResumeName != null && activeResumeName.isNotEmpty;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: NeoColors.freshMint,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: NeoColors.inkSolid,
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: NeoColors.inkSolid,
                            offset: Offset(1.5, 1.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        size: 15,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                    const Gap(8),
                    const Expanded(
                      child: Text(
                        'เรซูเม่หลัก (Active Resume)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.inkSolid,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(8),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: hasResume ? NeoColors.freshMint : NeoColors.mutedInk,
                  shape: BoxShape.circle,
                  border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                ),
              ),
            ],
          ),
          const Gap(12),

          // One shared document frame: CV, transcript, and other documents.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NeoColors.surfaceCream,
              borderRadius: BorderRadius.circular(12),
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
                _ProfileDocumentLine(
                  label: 'Resume',
                  fileName: activeResumeName ?? 'ยังไม่มี Resume ในระบบ',
                  prominent: true,
                  onTap: hasResume
                      ? () => ResumePreviewModal.show(
                          context,
                          fileName: activeResumeName,
                          documentId: cv?.id,
                        )
                      : null,
                ),
                if (transcript != null || others.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: NeoColors.inkSolid, height: 1),
                  ),
                  const Text(
                    'เอกสารที่อัปโหลดแล้ว',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: NeoColors.subtleInk,
                    ),
                  ),
                  if (transcript != null) ...[
                    const Gap(8),
                    _ProfileDocumentLine(
                      label: 'Transcript',
                      fileName: transcript.fileName,
                      onTap: () => ResumePreviewModal.show(
                        context,
                        fileName: transcript.fileName,
                        documentId: transcript.id,
                      ),
                    ),
                  ],
                  for (final document in others) ...[
                    const Gap(8),
                    _ProfileDocumentLine(
                      label: 'เอกสารอื่น',
                      fileName: document.fileName,
                      onTap: () => ResumePreviewModal.show(
                        context,
                        fileName: document.fileName,
                        documentId: document.id,
                      ),
                    ),
                  ],
                ],
                const Gap(14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/student/resume'),
                    icon: const Icon(Icons.edit_rounded, size: 17),
                    label: const Text('แก้ไข'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NeoColors.butterYellow,
                      foregroundColor: NeoColors.inkSolid,
                      elevation: 0,
                      side: const BorderSide(
                        color: NeoColors.inkSolid,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDocumentLine extends StatelessWidget {
  const _ProfileDocumentLine({
    required this.label,
    required this.fileName,
    this.prominent = false,
    this.onTap,
  });

  final String label;
  final String fileName;
  final bool prominent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.picture_as_pdf_rounded,
          size: prominent ? 22 : 18,
          color: onTap == null ? NeoColors.subtleInk : NeoColors.electricIndigo,
        ),
        const Gap(8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: NeoColors.subtleInk,
                ),
              ),
              InkWell(
                onTap: onTap,
                child: Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: prominent ? 14 : 13,
                    fontWeight: FontWeight.w800,
                    color: onTap == null
                        ? NeoColors.subtleInk
                        : NeoColors.electricIndigo,
                    decoration: onTap == null ? null : TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
