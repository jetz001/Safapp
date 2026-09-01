import 'dart:io';
import 'package:flutter/material.dart';

/// Modal dialog for previewing environmental document attachments, calibration certs, licenses, and site photos.
class AttachmentPreviewDialog extends StatelessWidget {
  final String title;
  final String filePath;
  final String? category;

  const AttachmentPreviewDialog({
    Key? key,
    required this.title,
    required this.filePath,
    this.category,
  }) : super(key: key);

  bool get _isImage {
    final lower = filePath.toLowerCase();
    return lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.webp');
  }

  bool get _isPdf {
    return filePath.toLowerCase().endsWith('.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    final exists = file.existsSync();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        height: 600,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A8A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPdf ? Icons.picture_as_pdf_rounded : (_isImage ? Icons.image_rounded : Icons.insert_drive_file_rounded),
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
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
                        if (category != null)
                          Text(
                            category!,
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
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

            // Content Area
            Expanded(
              child: Container(
                color: Colors.grey.shade100,
                child: Center(
                  child: exists
                      ? (_isImage
                          ? Image.file(file, fit: BoxFit.contain)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded, size: 72, color: Color(0xFFDC2626)),
                                const SizedBox(height: 16),
                                Text(
                                  file.path.split(Platform.pathSeparator).last,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ขนาดไฟล์: ${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    'ตำแหน่งไฟล์: ${file.path}',
                                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                  ),
                                ),
                              ],
                            ))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isPdf ? Icons.picture_as_pdf_outlined : Icons.description_outlined,
                              size: 64,
                              color: const Color(0xFF1E3A8A),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              title,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'เอกสารจำลอง/อ้างอิง: $filePath\n(ไฟล์พร้อมเปิดดูหรือส่งออกในระบบ)',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
