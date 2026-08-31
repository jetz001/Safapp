import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class HealthReportViewerDialog extends StatelessWidget {
  final String filePath;
  final String title;
  final String? subtitle;

  const HealthReportViewerDialog({
    Key? key,
    required this.filePath,
    required this.title,
    this.subtitle,
  }) : super(key: key);

  bool get _isPdf => p.extension(filePath).toLowerCase() == '.pdf';

  Future<void> _openExternal() async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '""', filePath], runInShell: true);
      }
    } catch (_) {}
  }

  Future<void> _printDocument() async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        await Printing.layoutPdf(
          onLayout: (_) => bytes,
          name: p.basenameWithoutExtension(filePath),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    final fileExists = file.existsSync();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 900,
        height: 760,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, style: TextStyle(fontSize: 12, color: Colors.blue.shade100)),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content Viewer
            Expanded(
              child: Container(
                color: const Color(0xFFF1F5F9),
                child: !fileExists
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('ไม่พบไฟล์เอกสารในเครื่อง ($filePath)', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : _isPdf
                        ? SfPdfViewer.file(file)
                        : InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Center(
                              child: Image.file(file, fit: BoxFit.contain),
                            ),
                          ),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: fileExists ? _openExternal : null,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('เปิดในโปรแกรมภายนอก (Adobe / Viewer)'),
                  ),
                  const Spacer(),
                  if (_isPdf) ...[
                    ElevatedButton.icon(
                      onPressed: fileExists ? _printDocument : null,
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('พิมพ์เอกสาร (Print PDF)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('ปิดหน้าต่าง'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
