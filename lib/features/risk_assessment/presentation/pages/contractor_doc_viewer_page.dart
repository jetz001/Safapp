import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../domain/models/contractor_jsa_models.dart';

class ContractorDocViewerPage extends StatefulWidget {
  final ContractorJsaDocument document;

  const ContractorDocViewerPage({
    Key? key,
    required this.document,
  }) : super(key: key);

  @override
  State<ContractorDocViewerPage> createState() => _ContractorDocViewerPageState();
}

class _ContractorDocViewerPageState extends State<ContractorDocViewerPage> {
  int _selectedFileIndex = 0;
  final PdfViewerController _pdfViewerController = PdfViewerController();

  Future<void> _openWithExternalApp(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบไฟล์ในเครื่อง'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '""', filePath], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.run('open', [filePath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [filePath]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเปิดไฟล์ด้วยโปรแกรมภายนอกได้: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final files = doc.filePaths;
    final currentPath = files.isNotEmpty && _selectedFileIndex < files.length
        ? files[_selectedFileIndex]
        : null;

    final currentExt = currentPath != null ? p.extension(currentPath).toLowerCase() : '';
    final isPdf = currentExt == '.pdf';
    final currentFile = currentPath != null ? File(currentPath) : null;
    final fileExists = currentFile != null && currentFile.existsSync();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade400.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    doc.documentType,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  doc.contractorName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              doc.projectTitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
        actions: [
          if (currentPath != null && fileExists)
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: 'เปิดด้วยโปรแกรมภายนอก (External App)',
              onPressed: () => _openWithExternalApp(currentPath),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Sidebar file selector if multiple files exist
          if (files.length > 1)
            Container(
              width: 220,
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(right: BorderSide(color: Colors.white12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'ไฟล์แนบทั้งหมด (${files.length})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final filePath = files[index];
                        final isSelected = index == _selectedFileIndex;
                        final fileName = p.basename(filePath);
                        final ext = p.extension(filePath).toLowerCase();
                        final isFilePdf = ext == '.pdf';

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedFileIndex = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1E3A8A) : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Colors.blue.shade400 : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isFilePdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                                  color: isFilePdf ? Colors.redAccent : Colors.lightBlueAccent,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fileName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Main View Area
          Expanded(
            child: currentPath == null || !fileExists
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'ไม่พบไฟล์เอกสาร หรือไฟล์ถูกย้าย/ลบไปแล้ว',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentPath ?? '',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                : isPdf
                    ? SfPdfViewer.file(
                        currentFile,
                        controller: _pdfViewerController,
                        canShowScrollHead: true,
                        canShowScrollStatus: true,
                        enableDoubleTapZooming: true,
                      )
                    : Container(
                        color: Colors.black,
                        child: Center(
                          child: InteractiveViewer(
                            panEnabled: true,
                            boundaryMargin: const EdgeInsets.all(30),
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.file(
                              currentFile,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
