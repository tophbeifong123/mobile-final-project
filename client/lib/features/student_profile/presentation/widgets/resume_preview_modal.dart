import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../resume/presentation/providers/resume_controller.dart';

/// Neo-Brutalist Resume PDF Preview Modal Dialog
class ResumePreviewModal extends ConsumerStatefulWidget {
  const ResumePreviewModal({
    super.key,
    required this.fileName,
    this.onReplace,
  });

  final String fileName;
  final VoidCallback? onReplace;

  static Future<void> show(
    BuildContext context, {
    required String fileName,
    VoidCallback? onReplace,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => ResumePreviewModal(
        fileName: fileName,
        onReplace: onReplace,
      ),
    );
  }

  @override
  ConsumerState<ResumePreviewModal> createState() => _ResumePreviewModalState();
}

class _ResumePreviewModalState extends ConsumerState<ResumePreviewModal> {
  PdfController? _pdfController;
  List<int>? _lastBytes;
  Object? _docError;

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  void _initPdfController(List<int> bytes) {
    if (_lastBytes == bytes && _pdfController != null) return;
    _lastBytes = bytes;
    _pdfController?.dispose();
    _docError = null;
    try {
      _pdfController = PdfController(
        document: PdfDocument.openData(Uint8List.fromList(bytes)),
      );
    } catch (e) {
      _pdfController = null;
      _docError = e;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfBytesAsync = ref.watch(resumePdfBytesProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 580,
            maxHeight: 740,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: NeoColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NeoColors.inkSolid, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: NeoColors.inkSolid,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Top Bar (Neo-Brutalist Frame Header)
                _buildHeader(context),

                // Main Preview Canvas
                Expanded(
                  child: pdfBytesAsync.when(
                    loading: () => _buildLoadingState(),
                    error: (err, _) => _buildErrorState(err),
                    data: (bytes) {
                      _initPdfController(bytes);
                      return _buildPdfViewer(bytes);
                    },
                  ),
                ),

                // Footer Actions
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: NeoColors.butterYellow,
        border: Border(
          bottom: BorderSide(color: NeoColors.inkSolid, width: 2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: NeoColors.softRose,
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
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              size: 18,
              color: NeoColors.inkSolid,
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: NeoColors.inkSolid,
                  ),
                ),
                const Text(
                  'ตัวอย่างเรซูเม่ (PDF Preview)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: NeoColors.subtleInk,
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          // Page Indicator Pill (if PDF controller is ready)
          if (_pdfController != null)
            PdfPageNumber(
              controller: _pdfController!,
              builder: (context, loadingState, page, pagesCount) {
                if (pagesCount == null || pagesCount == 0) {
                  return const SizedBox.shrink();
                }
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: NeoColors.pureWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: NeoColors.inkSolid,
                        offset: Offset(1, 1),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    '$page / $pagesCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: NeoColors.inkSolid,
                    ),
                  ),
                );
              },
            ),
          // Close Icon Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: NeoColors.pureWhite,
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
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: NeoColors.inkSolid,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: NeoColors.paperCanvas,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: NeoColors.butterYellow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NeoColors.inkSolid, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: NeoColors.inkSolid,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    color: NeoColors.inkSolid,
                  ),
                ),
              ),
            ),
            const Gap(14),
            const Text(
              'กำลังโหลดตัวอย่างเอกสาร...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: NeoColors.inkSolid,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Container(
      color: NeoColors.paperCanvas,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: NeoColors.errorBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NeoColors.inkSolid, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: NeoColors.inkSolid,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 28,
                color: NeoColors.errorText,
              ),
            ),
            const Gap(14),
            Text(
              userVisibleError(error),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: NeoColors.errorText,
              ),
            ),
            const Gap(16),
            NeoButton(
              onPressed: () => ref.invalidate(resumePdfBytesProvider),
              text: 'ลองอีกครั้ง',
              icon: const Icon(Icons.refresh_rounded, size: 16),
              variant: NeoButtonVariant.secondary,
              height: 38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfViewer(List<int> bytes) {
    if (_docError != null || _pdfController == null) {
      // Fallback for headless environments or rendering issues
      return Container(
        color: NeoColors.paperCanvas,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: NeoColors.freshMint,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: NeoColors.inkSolid, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: NeoColors.inkSolid,
                      offset: Offset(2.5, 2.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 32,
                  color: NeoColors.inkSolid,
                ),
              ),
              const Gap(14),
              Text(
                widget.fileName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: NeoColors.inkSolid,
                ),
              ),
              const Gap(4),
              Text(
                'ขนาดไฟล์: ${(bytes.length / 1024).toStringAsFixed(1)} KB (พร้อมใช้งาน)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: NeoColors.subtleInk,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: NeoColors.surfaceCream,
      child: PdfView(
        controller: _pdfController!,
        scrollDirection: Axis.vertical,
        backgroundDecoration: const BoxDecoration(
          color: NeoColors.surfaceCream,
        ),
        onDocumentError: (error) {
          if (mounted) {
            setState(() {
              _docError = error;
              _pdfController = null;
            });
          }
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: NeoColors.paperCanvas,
        border: Border(
          top: BorderSide(color: NeoColors.inkSolid, width: 2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: NeoButton(
              onPressed: () => Navigator.of(context).pop(),
              text: 'ปิด',
              icon: const Icon(
                Icons.close_rounded,
                size: 16,
                color: NeoColors.errorText,
              ),
              variant: NeoButtonVariant.destructive,
              height: 40,
            ),
          ),
          const Gap(10),
          Expanded(
            child: NeoButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (widget.onReplace != null) {
                  widget.onReplace!();
                } else {
                  context.push('/student/resume');
                }
              },
              text: 'เปลี่ยนไฟล์',
              icon: const Icon(Icons.sync_rounded, size: 16),
              variant: NeoButtonVariant.secondary,
              height: 40,
            ),
          ),
        ],
      ),
    );
  }
}
