import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../resume/presentation/providers/resume_controller.dart';
import '../../../student_profile/presentation/widgets/resume_preview_modal.dart';

class ApplicationDocumentsDialog extends ConsumerStatefulWidget {
  const ApplicationDocumentsDialog({super.key, this.selectedIds = const []});
  final List<String> selectedIds;

  static Future<List<String>?> show(
    BuildContext context, {
    List<String> selectedIds = const [],
  }) => showDialog<List<String>>(
    context: context,
    builder: (_) => ApplicationDocumentsDialog(selectedIds: selectedIds),
  );

  @override
  ConsumerState<ApplicationDocumentsDialog> createState() =>
      _ApplicationDocumentsDialogState();
}

class _ApplicationDocumentsDialogState
    extends ConsumerState<ApplicationDocumentsDialog> {
  late final Set<String> _selected = widget.selectedIds.toSet();

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(studentDocumentsProvider);
    return Dialog(
      backgroundColor: NeoColors.pureWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: NeoColors.inkSolid, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 448,
          maxHeight: MediaQuery.sizeOf(context).height * .8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: NeoColors.inkSolid,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'เอกสารของฉัน',
                      style: TextStyle(
                        color: NeoColors.inkSolid,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'ปิด',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                'เลือกไฟล์ที่จะแนบ บริษัทจะเห็นเฉพาะไฟล์ที่เลือก\nCV จำเป็น • Transcript และเอกสารอื่นไม่บังคับ',
                style: TextStyle(color: NeoColors.subtleInk, height: 1.5),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: library.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(userVisibleError(error)),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(studentDocumentsProvider),
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                  data: (documents) => SingleChildScrollView(
                    child: Column(
                      children: [
                        if (!documents.any((d) => d.type == 'cv'))
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'ยังไม่มี CV กรุณาเพิ่ม CV ในหน้าโปรไฟล์ก่อนสมัคร',
                              style: TextStyle(color: NeoColors.errorText),
                            ),
                          ),
                        for (final document in documents)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: NeoColors.pureWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: NeoColors.inkSolid,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    key: ValueKey('attach-${document.id}'),
                                    value:
                                        document.type == 'cv' ||
                                        _selected.contains(document.id),
                                    onChanged: document.type == 'cv'
                                        ? null
                                        : (checked) => setState(() {
                                            if (checked == true) {
                                              _selected.add(document.id);
                                            } else {
                                              _selected.remove(document.id);
                                            }
                                          }),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          document.type == 'cv'
                                              ? 'CV (จำเป็น)'
                                              : document.type == 'transcript'
                                              ? 'Transcript'
                                              : 'เอกสารอื่นๆ',
                                          style: const TextStyle(
                                            color: NeoColors.subtleInk,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          document.fileName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: NeoColors.inkSolid,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'ดู ${document.fileName}',
                                    icon: const Icon(
                                      Icons.visibility_outlined,
                                      color: NeoColors.inkSolid,
                                    ),
                                    onPressed: () => showDialog<void>(
                                      context: context,
                                      builder: (_) => Consumer(
                                        builder: (context, ref, _) =>
                                            ResumePreviewModal(
                                              fileName: document.fileName,
                                              readOnly: true,
                                              pdfBytes: ref.watch(
                                                studentDocumentPdfBytesProvider(
                                                  document.id,
                                                ),
                                              ),
                                              onRetry: () => ref.invalidate(
                                                studentDocumentPdfBytesProvider(
                                                  document.id,
                                                ),
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              NeoButton(
                isFullWidth: true,
                text: 'ใช้เอกสารที่เลือก',
                onPressed:
                    library.asData?.value.any((d) => d.type == 'cv') == true
                    ? () {
                        final documents = library.asData!.value;
                        Navigator.pop(
                          context,
                          documents
                              .where(
                                (d) =>
                                    d.type == 'cv' || _selected.contains(d.id),
                              )
                              .map((d) => d.id)
                              .toList(),
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
