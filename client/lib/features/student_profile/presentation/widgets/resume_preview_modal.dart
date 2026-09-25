import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../resume/presentation/providers/resume_controller.dart';

/// Neo-Brutalist Resume PDF Preview Modal Dialog
class ResumePreviewModal extends ConsumerWidget {
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
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => ResumePreviewModal(
        fileName: fileName,
        onReplace: onReplace,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    loading: () => const _PdfLoadingView(
                      message: 'กำลังดาวน์โหลดเอกสาร PDF...',
                    ),
                    error: (err, _) => _buildErrorState(ref, err),
                    data: (bytes) => _PdfViewerCanvas(
                      bytes: bytes,
                      fileName: fileName,
                    ),
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
                  fileName,
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


  Widget _buildErrorState(WidgetRef ref, Object error) {
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
                if (onReplace != null) {
                  onReplace!();
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

/// Dedicated PDF Viewer Canvas that isolates the PdfController lifecycle
class _PdfViewerCanvas extends StatefulWidget {
  const _PdfViewerCanvas({
    required this.bytes,
    required this.fileName,
  });

  final List<int> bytes;
  final String fileName;

  @override
  State<_PdfViewerCanvas> createState() => _PdfViewerCanvasState();
}

class _PdfViewerCanvasState extends State<_PdfViewerCanvas> {
  late final PdfController _controller;
  Object? _renderError;
  File? _tempFile;

  @override
  void initState() {
    super.initState();
    _controller = PdfController(
      document: _openDocument(widget.bytes),
    );
  }

  // Support both Web (in-memory openData via pdf.js) and Native (temp file openFile
  // to avoid Android IPC 64KB pipe-buffer limit)
  Future<PdfDocument> _openDocument(List<int> bytes) async {
    if (kIsWeb) {
      return PdfDocument.openData(Uint8List.fromList(bytes));
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/resume_preview_${DateTime.now().millisecondsSinceEpoch}.pdf';
      _tempFile = File(tempPath);
      await _tempFile!.writeAsBytes(bytes, flush: true);
      return await PdfDocument.openFile(tempPath);
    } catch (_) {
      // Fallback to in-memory openData if filesystem is restricted or unavailable
      return await PdfDocument.openData(Uint8List.fromList(bytes));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    if (!kIsWeb) {
      _tempFile?.delete().ignore();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_renderError != null) {
      return _buildFallbackInfo(error: _renderError);
    }

    return Container(
      color: NeoColors.surfaceCream,
      child: Stack(
        children: [
          PdfView(
            controller: _controller,
            scrollDirection: Axis.vertical,
            backgroundDecoration: const BoxDecoration(
              color: NeoColors.surfaceCream,
            ),
            builders: PdfViewBuilders<DefaultBuilderOptions>(
              options: const DefaultBuilderOptions(),
              documentLoaderBuilder: (context) => const _PdfLoadingView(
                message: 'กำลังจัดเตรียมเอกสาร PDF...',
              ),
              pageLoaderBuilder: (context) => const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: NeoColors.inkSolid,
                  ),
                ),
              ),
              errorBuilder: (context, error) {
                return _buildFallbackInfo(error: error);
              },
            ),
            onDocumentError: (error) {
              if (mounted) {
                setState(() {
                  _renderError = error;
                });
              }
            },
          ),
          // Floating Page Indicator Pill at bottom right
          Positioned(
            right: 12,
            bottom: 12,
            child: PdfPageNumber(
              controller: _controller,
              builder: (context, loadingState, page, pagesCount) {
                if (pagesCount == null || pagesCount == 0) {
                  return const SizedBox.shrink();
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: NeoColors.pureWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: NeoColors.inkSolid,
                        offset: Offset(1.5, 1.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    'หน้า $page / $pagesCount',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: NeoColors.inkSolid,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackInfo({Object? error}) {
    final sizeKb = (widget.bytes.length / 1024).toStringAsFixed(1);
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
                borderRadius: BorderRadius.circular(16),
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
                Icons.picture_as_pdf_rounded,
                size: 32,
                color: NeoColors.inkSolid,
              ),
            ),
            const Gap(16),
            Text(
              widget.fileName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: NeoColors.inkSolid,
              ),
            ),
            const Gap(6),
            Text(
              'ขนาดไฟล์: $sizeKb KB (พร้อมใช้งานในระบบ)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: NeoColors.subtleInk,
              ),
            ),
            if (error != null) ...[
              const Gap(10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: NeoColors.surfaceCream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NeoColors.inkSolid, width: 1),
                ),
                child: Text(
                  'ระบบดาวน์โหลดไฟล์สมบูรณ์แล้ว แต่ไม่สามารถเรนเดอร์ในอุปกรณ์นี้ได้',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: NeoColors.subtleInk,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Unified Neo-Brutalist Loading Indicator for both download and document preparation
class _PdfLoadingView extends StatelessWidget {
  const _PdfLoadingView({
    this.message = 'กำลังโหลดเอกสาร PDF...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
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
            Text(
              message,
              style: const TextStyle(
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
}

