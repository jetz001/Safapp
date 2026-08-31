import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Full-screen dialog viewer for chemical attachments (SDS PDFs, photos, and lab certificates).
class ChemicalDocViewerDialog extends StatelessWidget {
  final String filePath;
  final String title;
  final String? subtitle;
  final String? casNumber;

  const ChemicalDocViewerDialog({
    Key? key,
    required this.filePath,
    required this.title,
    this.subtitle,
    this.casNumber,
  }) : super(key: key);

  bool get _isPdf => p.extension(filePath).toLowerCase() == '.pdf';

  Future<void> _openExternal() async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '""', filePath], runInShell: true);
      }
    } catch (e) {
      debugPrint('Error opening external file: $e');
    }
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
    } catch (e) {
      debugPrint('Error printing document: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    final fileExists = file.existsSync();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Container(
        width: 960,
        height: 820,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header Bar
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (casNumber != null && casNumber!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'CAS: $casNumber',
                                  style: const TextStyle(fontSize: 11, color: Colors.white, fontFamily: 'monospace'),
                                ),
                              ),
                            ]
                          ],
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade100),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]
                      ],
                    ),
                  ),
                  if (fileExists) ...[
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                      tooltip: 'เปิดด้วยโปรแกรมภายนอก',
                      onPressed: _openExternal,
                    ),
                    if (_isPdf)
                      IconButton(
                        icon: const Icon(Icons.print_rounded, color: Colors.white),
                        tooltip: 'พิมพ์เอกสาร',
                        onPressed: _printDocument,
                      ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: 'ปิดหน้าต่าง',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Document Viewer Body
            Expanded(
              child: !fileExists
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'ไม่พบไฟล์เอกสารในระบบ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            filePath,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : _isPdf
                      ? SfPdfViewer.file(
                          file,
                          canShowScrollHead: true,
                          canShowScrollStatus: true,
                          enableDoubleTapZooming: true,
                        )
                      : Container(
                          color: const Color(0xFF1E293B),
                          child: Center(
                            child: InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Image.file(
                                file,
                                fit: BoxFit.contain,
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
