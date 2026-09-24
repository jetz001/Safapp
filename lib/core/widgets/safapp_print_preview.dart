import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

typedef LayoutPdfCallback = Future<Uint8List> Function(PdfPageFormat format);

/// Universal In-App Print Preview Dialog for Safapp
/// Can be invoked from any module using:
/// ```dart
/// SafappPrintPreview.show(
///   context,
///   title: 'รายงานสรุปผลการตรวจสอบ',
///   subtitle: 'แบบ ๕๖๒๘๙ • ม.๑๒',
///   fileName: 'Electrical_Inspection_Report.pdf',
///   onLayout: (format) => generator.buildPdf(format),
/// );
/// ```
class SafappPrintPreview {
  /// Show print preview from a dynamic PDF builder
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? formCode,
    String fileName = 'document.pdf',
    required LayoutPdfCallback onLayout,
    PdfPageFormat initialPageFormat = PdfPageFormat.a4,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SafappPrintPreviewDialog(
        title: title,
        subtitle: subtitle,
        formCode: formCode,
        fileName: fileName.endsWith('.pdf') ? fileName : '$fileName.pdf',
        onLayout: onLayout,
        initialPageFormat: initialPageFormat,
      ),
    );
  }

  /// Show print preview from existing PDF bytes in memory
  static Future<void> showBytes(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? formCode,
    String fileName = 'document.pdf',
    required Uint8List pdfBytes,
    PdfPageFormat initialPageFormat = PdfPageFormat.a4,
  }) async {
    return show(
      context,
      title: title,
      subtitle: subtitle,
      formCode: formCode,
      fileName: fileName,
      onLayout: (format) async => pdfBytes,
      initialPageFormat: initialPageFormat,
    );
  }

  /// Show print preview from an existing PDF file path on disk
  static Future<void> showFile(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? formCode,
    required String filePath,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบไฟล์เอกสารบนเครื่อง (ไฟล์อาจถูกย้ายหรือลบ)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    return showBytes(
      context,
      title: title,
      subtitle: subtitle,
      formCode: formCode,
      fileName: file.uri.pathSegments.last,
      pdfBytes: bytes,
    );
  }
}

class SafappPrintPreviewDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? formCode;
  final String fileName;
  final LayoutPdfCallback onLayout;
  final PdfPageFormat initialPageFormat;

  const SafappPrintPreviewDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.formCode,
    required this.fileName,
    required this.onLayout,
    this.initialPageFormat = PdfPageFormat.a4,
  });

  @override
  State<SafappPrintPreviewDialog> createState() => _SafappPrintPreviewDialogState();
}

class _SafappPrintPreviewDialogState extends State<SafappPrintPreviewDialog> {
  Uint8List? _renderedBytes;
  bool _isSaving = false;
  bool _isPrinting = false;

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final bytes = await widget.onLayout(format);
    _renderedBytes = bytes;
    return bytes;
  }

  Future<void> _handleSaveAs() async {
    setState(() => _isSaving = true);
    try {
      final bytes = _renderedBytes ?? await widget.onLayout(widget.initialPageFormat);

      final savePath = await FilePicker.saveFile(
        dialogTitle: 'บันทึกเอกสาร PDF',
        fileName: widget.fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (savePath != null) {
        String finalPath = savePath;
        if (!finalPath.toLowerCase().endsWith('.pdf')) {
          finalPath = '$finalPath.pdf';
        }
        final file = File(finalPath);
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('บันทึกไฟล์สำเร็จ: ${file.path}')),
                ],
              ),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleOpenExternal() async {
    try {
      final bytes = _renderedBytes ?? await widget.onLayout(widget.initialPageFormat);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${widget.fileName}');
      await tempFile.writeAsBytes(bytes);

      if (Platform.isWindows) {
        await Process.run('cmd.exe', ['/c', 'start', '', tempFile.path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [tempFile.path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [tempFile.path]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเปิดโปรแกรมภายนอกได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDirectPrint() async {
    setState(() => _isPrinting = true);
    try {
      final bytes = _renderedBytes ?? await widget.onLayout(widget.initialPageFormat);
      await Printing.layoutPdf(
        name: widget.fileName,
        onLayout: (format) async => bytes,
        format: widget.initialPageFormat,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการพิมพ์: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = (size.width * 0.88).clamp(700.0, 1100.0);
    final dialogHeight = (size.height * 0.90).clamp(500.0, 920.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            // Top Header & Action Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Dark Slate Modern Header
                border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
              ),
              child: Row(
                children: [
                  // PDF Badge Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFF87171), size: 22),
                  ),
                  const SizedBox(width: 12),

                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.formCode != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF334155)),
                                ),
                                child: Text(
                                  widget.formCode!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Toolbar Actions
                  // 1. Open External
                  OutlinedButton.icon(
                    onPressed: _handleOpenExternal,
                    icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF94A3B8)),
                    label: const Text('เปิดภายนอก', style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF334155)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Save As PDF
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _handleSaveAs,
                    icon: _isSaving
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.file_download_outlined, size: 16, color: Color(0xFF38BDF8)),
                    label: const Text('บันทึก PDF', style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF334155)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. Print Button
                  FilledButton.icon(
                    onPressed: _isPrinting ? null : _handleDirectPrint,
                    icon: _isPrinting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.print_rounded, size: 16),
                    label: const Text('สั่งพิมพ์', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 4. Close Button
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                    tooltip: 'ปิดหน้าต่างพรีวิว',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Live PDF Preview Area
            Expanded(
              child: Container(
                color: const Color(0xFFF1F5F9), // Light Slate Background
                child: PdfPreview(
                  build: _generatePdf,
                  initialPageFormat: widget.initialPageFormat,
                  allowPrinting: false, // Handled by our custom toolbar
                  allowSharing: false, // Handled by our custom toolbar
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  maxPageWidth: 780,
                  pdfFileName: widget.fileName,
                  loadingWidget: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF2563EB)),
                        SizedBox(height: 14),
                        Text(
                          'กำลังจัดเตรียมและเรนเดอร์เอกสาร...',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  onError: (context, error) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
                        const SizedBox(height: 10),
                        Text(
                          'เกิดข้อผิดพลาดในการแสดงผลเอกสาร:\n$error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
