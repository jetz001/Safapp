import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Modal dialog for previewing and navigating environmental document attachments,
/// rendering PDFs directly inside the app with SfPdfViewer and providing multi-file switching.
class AttachmentPreviewDialog extends StatefulWidget {
  final String title;
  final List<String> filePaths;
  final String? category;
  final int initialIndex;

  AttachmentPreviewDialog({
    Key? key,
    required this.title,
    List<String>? filePaths,
    String? filePath,
    this.category,
    this.initialIndex = 0,
  })  : filePaths = filePaths ?? (filePath != null ? [filePath] : const []),
        super(key: key);

  @override
  State<AttachmentPreviewDialog> createState() => _AttachmentPreviewDialogState();
}

class _AttachmentPreviewDialogState extends State<AttachmentPreviewDialog> {
  late int _selectedIndex;
  bool _showSidebar = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = (widget.initialIndex >= 0 && widget.initialIndex < widget.filePaths.length)
        ? widget.initialIndex
        : 0;
  }

  String get _currentPath {
    if (widget.filePaths.isEmpty) return '';
    return widget.filePaths[_selectedIndex];
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.webp');
  }

  bool _isPdf(String path) {
    return path.toLowerCase().endsWith('.pdf');
  }

  Future<void> _launchFile(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd.exe', ['/c', 'start', '', path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [path]);
      } else {
        await Process.run('xdg-open', [path]);
      }
    } catch (e) {
      debugPrint('Error launching native document viewer: $e');
    }
  }

  Future<void> _openFolder(String path) async {
    try {
      final file = File(path);
      if (Platform.isWindows) {
        if (file.existsSync()) {
          await Process.run('explorer.exe', ['/select,', file.path]);
        } else if (file.parent.existsSync()) {
          await Process.run('explorer.exe', [file.parent.path]);
        }
      } else if (Platform.isMacOS) {
        await Process.run('open', ['-R', path]);
      }
    } catch (e) {
      debugPrint('Error opening directory: $e');
    }
  }

  String _formatFileSize(File file) {
    try {
      if (!file.existsSync()) return 'ไม่พบไฟล์';
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.94).clamp(860.0, 1380.0);
    final dialogHeight = (screenSize.height * 0.92).clamp(620.0, 920.0);

    final hasFiles = widget.filePaths.isNotEmpty;
    final file = hasFiles ? File(_currentPath) : null;
    final exists = file?.existsSync() ?? false;
    final hasMultiple = widget.filePaths.length > 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        color: Colors.white,
        child: Column(
          children: [
            // Top Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A8A),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.title,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasFiles) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${widget.filePaths.length} ฉบับ',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (widget.category != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.category!,
                            style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasMultiple)
                    IconButton(
                      icon: Icon(_showSidebar ? Icons.view_sidebar_rounded : Icons.view_sidebar_outlined, color: Colors.white),
                      tooltip: _showSidebar ? 'ซ่อนรายการเอกสาร' : 'แสดงรายการเอกสาร',
                      onPressed: () => setState(() => _showSidebar = !_showSidebar),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    tooltip: 'ปิดหน้าต่าง',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content Area: Left Sidebar (List) + Right Embedded PDF Viewer
            Expanded(
              child: hasFiles
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Sidebar: File List
                        if (hasMultiple && _showSidebar)
                          Container(
                            width: 290,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border(right: BorderSide(color: Colors.grey.shade300)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'รายการเอกสารทั้งหมด',
                                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                      ),
                                      Text(
                                        '(${_selectedIndex + 1}/${widget.filePaths.length})',
                                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    itemCount: widget.filePaths.length,
                                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                                    itemBuilder: (ctx, idx) {
                                      final itemPath = widget.filePaths[idx];
                                      final itemFile = File(itemPath);
                                      final isSelected = idx == _selectedIndex;
                                      final itemName = p.basename(itemPath);
                                      final isPdf = _isPdf(itemPath);

                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedIndex = idx;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? const Color(0xFFDBEAFE)
                                                      : (isPdf ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9)),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Icon(
                                                  isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
                                                  size: 16,
                                                  color: isPdf ? const Color(0xFFDC2626) : const Color(0xFF475569),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      itemName,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                        color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF1E293B),
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          _formatFileSize(itemFile),
                                                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                                        ),
                                                        if (isSelected)
                                                          const Text(
                                                            '✓ แสดงอยู่',
                                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
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

                        // Right Pane: Embedded PDF Viewer & File Controls
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Secondary Top Bar for Current File & Navigation
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                ),
                                child: Row(
                                  children: [
                                    if (hasMultiple) ...[
                                      OutlinedButton.icon(
                                        onPressed: _selectedIndex > 0
                                            ? () => setState(() => _selectedIndex--)
                                            : null,
                                        icon: const Icon(Icons.arrow_back_rounded, size: 14),
                                        label: const Text('ก่อนหน้า', style: TextStyle(fontSize: 11.5)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'ฉบับที่ ${_selectedIndex + 1} / ${widget.filePaths.length}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: _selectedIndex < widget.filePaths.length - 1
                                            ? () => setState(() => _selectedIndex++)
                                            : null,
                                        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                        label: const Text('ถัดไป', style: TextStyle(fontSize: 11.5)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                    ],
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.insert_drive_file_outlined, size: 15, color: Color(0xFF64748B)),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              p.basename(_currentPath),
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (file != null && exists) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '(${_formatFileSize(file)})',
                                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (exists) ...[
                                      OutlinedButton.icon(
                                        onPressed: () => _openFolder(_currentPath),
                                        icon: const Icon(Icons.folder_open_rounded, size: 14),
                                        label: const Text('โฟลเดอร์', style: TextStyle(fontSize: 11.5)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF475569),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton.tonalIcon(
                                        onPressed: () => _launchFile(_currentPath),
                                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                                        label: const Text('เปิดใน PDF Viewer ภายนอก', style: TextStyle(fontSize: 11.5)),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Embedded Viewer: Shows PDF directly inside app!
                              Expanded(
                                child: Container(
                                  color: const Color(0xFFE2E8F0),
                                  child: exists
                                      ? (_isPdf(_currentPath)
                                          ? SfPdfViewer.file(
                                              file!,
                                              key: ValueKey(_currentPath),
                                              canShowScrollHead: true,
                                              canShowScrollStatus: true,
                                              canShowPaginationDialog: true,
                                            )
                                          : (_isImage(_currentPath)
                                              ? InteractiveViewer(
                                                  child: Center(child: Image.file(file!, fit: BoxFit.contain)),
                                                )
                                              : Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Icon(Icons.insert_drive_file_rounded, size: 64, color: Color(0xFF64748B)),
                                                      const SizedBox(height: 12),
                                                      Text(
                                                        p.basename(_currentPath),
                                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                                      ),
                                                      const SizedBox(height: 14),
                                                      ElevatedButton.icon(
                                                        onPressed: () => _launchFile(_currentPath),
                                                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                                        label: const Text('เปิดดูด้วยโปรแกรมของเครื่อง'),
                                                      ),
                                                    ],
                                                  ),
                                                )))
                                      : Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.error_outline_rounded, size: 56, color: Color(0xFFDC2626)),
                                              const SizedBox(height: 12),
                                              Text(
                                                'ไม่พบไฟล์: ${p.basename(_currentPath)}',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _currentPath,
                                                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const Center(child: Text('ไม่มีเอกสารที่แนบในหมวดหมู่นี้')),
            ),

            // Footer Status & Quick Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            hasFiles
                                ? 'แสดงเอกสาร: ${p.basename(_currentPath)} | พร้อมเปิดอ่านในระบบทันที (กดเลือกรายการทางซ้ายเพื่อเปลี่ยนฉบับ)'
                                : 'ไม่มีเอกสาร',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                    ),
                    child: const Text('ปิดหน้าต่าง', style: TextStyle(fontSize: 12)),
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
