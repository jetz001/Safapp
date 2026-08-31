import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class CertificateViewerDialog extends StatelessWidget {
  final String filePath;
  final String title;
  final String employeeName;

  const CertificateViewerDialog({
    Key? key,
    required this.filePath,
    required this.title,
    required this.employeeName,
  }) : super(key: key);

  Future<void> _openInExternalApp() async {
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
          name: 'Certificate_${p.basenameWithoutExtension(filePath)}',
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    final exists = file.existsSync();
    final isPdf = p.extension(filePath).toLowerCase() == '.pdf';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Container(
        width: 850,
        height: 700,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded, color: isPdf ? Colors.redAccent : Colors.lightBlueAccent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'พนักงาน: $employeeName  |  ไฟล์: ${p.basename(filePath)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.print_rounded, color: Colors.white70),
                    tooltip: 'สั่งพิมพ์วุฒิบัตร (Print)',
                    onPressed: _printDocument,
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded, color: Colors.white70),
                    tooltip: 'เปิดในโปรแกรมภายนอก (Windows)',
                    onPressed: _openInExternalApp,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Main Viewer Area
            Expanded(
              child: !exists
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_outlined, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('ไม่พบไฟล์เอกสารในระบบ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(filePath, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  : isPdf
                      ? SfPdfViewer.file(file)
                      : Container(
                          color: const Color(0xFF1E293B),
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Center(
                              child: Image.file(file, fit: BoxFit.contain),
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
