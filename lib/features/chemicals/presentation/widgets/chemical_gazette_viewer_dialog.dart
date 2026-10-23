import 'package:path/path.dart' as p;
import '../../../environment/presentation/widgets/attachment_preview_dialog.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/widgets/safapp_print_preview.dart';

/// Full-screen high-fidelity dialog viewer for official Royal Gazette (ราชกิจจานุเบกษา)
/// and statutory Thai government forms (แบบ สอ.๑, แบบ สอ.๓, กฎกระทรวง).
class ChemicalGazetteViewerDialog extends StatelessWidget {
  final String assetPath;
  final String title;
  final String? subtitle;
  final String? formCode;
  final String? externalUrl;

  const ChemicalGazetteViewerDialog({
    super.key,
    required this.assetPath,
    required this.title,
    this.subtitle,
    this.formCode,
    this.externalUrl,
  });

  /// Opens the gazette viewer dialog directly
  static Future<void> show(
    BuildContext context, {
    required String assetPath,
    required String title,
    String? subtitle,
    String? formCode,
    String? externalUrl,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ChemicalGazetteViewerDialog(
        assetPath: assetPath,
        title: title,
        subtitle: subtitle,
        formCode: formCode,
        externalUrl: externalUrl,
      ),
    );
  }

  /// Opens a selector modal allowing users to choose which statutory gazette original to inspect
  static Future<void> showSelectionMenu(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _GazetteDocumentPickerModal(),
    );
  }

  Future<void> _openExternal(BuildContext context) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${assetPath.split("/").last}');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '""', tempFile.path], runInShell: true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเปิดเอกสารภายนอกได้: $e')),
        );
      }
    }
  }

  Future<void> _openExternalUrl(BuildContext context) async {
    if (externalUrl == null || externalUrl!.isEmpty) return;
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '""', externalUrl!], runInShell: true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเปิดเว็บไซต์ได้: $e')),
        );
      }
    }
  }

  Future<void> _printDocument(BuildContext context) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      if (context.mounted) {
        await SafappPrintPreview.showBytes(
          context,
          title: title,
          subtitle: subtitle,
          formCode: formCode ?? 'ต้นฉบับราชกิจจานุเบกษา',
          fileName: assetPath.split('/').last,
          pdfBytes: bytes,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถสั่งพิมพ์เอกสารได้: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        width: 1100,
        height: 880,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
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
                      color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.5)),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Color(0xFF2DD4BF),
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
                            if (formCode != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  formCode!,
                                  style: GoogleFonts.prompt(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                title,
                                style: GoogleFonts.prompt(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: GoogleFonts.prompt(
                              fontSize: 11.5,
                              color: const Color(0xFF94A3B8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (externalUrl != null && externalUrl!.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _openExternalUrl(context),
                      icon: const Icon(Icons.public_rounded, size: 16),
                      label: const Text('เว็บไซต์ราชกิจจาฯ'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        side: const BorderSide(color: Color(0xFF0284C7)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _openExternal(context),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('เปิดภายนอก'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Color(0xFF475569)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _printDocument(context),
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text('พิมพ์ / พรีวิว'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    tooltip: 'ปิดหน้าต่าง',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Document Viewer Body
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: SfPdfViewer.asset(
                  assetPath,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  enableDoubleTapZooming: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selector modal for statutory documents
class _GazetteDocumentPickerModal extends StatelessWidget {
  const _GazetteDocumentPickerModal();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 720,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.all(20),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'เอกสารและแบบฟอร์มต้นฉบับราชการ (ราชกิจจานุเบกษา)',
                          style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'เลือกเปิดดูเอกสารต้นฉบับของกรมสวัสดิการและคุ้มครองแรงงาน เพื่อตรวจสอบและเทียบเคียง',
                          style: GoogleFonts.prompt(fontSize: 12, color: Colors.blue.shade100),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Document List
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDocCard(
                    context,
                    title: 'แฟ้มเอกสารการตรวจวัดสภาพแวดล้อมและสารเคมีทั้งหมด (สแกนต้นฉบับจริง ๓๒ ฉบับ)',
                    subtitle: 'รายงานผลการตรวจวัดสารเคมีอันตราย สอ.๓ และสภาพแวดล้อมพร้อมตราประทับและลายมือชื่อจริง (Scan2569-05-19_101623.pdf)',
                    badge: 'สแกนต้นฉบับจริง ๒๕๖๙',
                    badgeColor: const Color(0xFF9333EA),
                    icon: Icons.folder_shared_rounded,
                    assetPath: '',
                    onCustomTap: () {
                      Navigator.pop(context);
                      final dir = Directory(r'D:\DEV\Safapp\bin\สวล69\2026');
                      List<String> files = [];
                      if (dir.existsSync()) {
                        files = dir.listSync()
                            .whereType<File>()
                            .where((f) => f.path.toLowerCase().endsWith('.pdf') || f.path.toLowerCase().endsWith('.jpg') || f.path.toLowerCase().endsWith('.png'))
                            .map((f) => f.path)
                            .toList();
                        files.sort((a, b) => p.basename(a).compareTo(p.basename(b)));
                      }
                      final initialIndex = files.indexWhere((f) => f.contains('101623'));
                      showDialog(
                        context: context,
                        builder: (ctx) => AttachmentPreviewDialog(
                          title: 'แฟ้มเอกสารการตรวจวัดสภาพแวดล้อมทั้งหมด (ปี ๒๕๖๙)',
                          filePaths: files,
                          initialIndex: initialIndex != -1 ? initialIndex : 0,
                          category: 'เอกสารทั้งหมดในแฟ้ม',
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDocCard(
                    context,
                    title: 'แบบ สอ.๓: รายงานผลการตรวจวัดในบรรยากาศ (ฉบับที่ ๒ พ.ศ. ๒๕๖๕)',
                    subtitle: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน • ตาราง ๑๒ คอลัมน์ แนวนอน พร้อมหมายเหตุ ๖ ข้อท้ายประกาศ',
                    badge: 'แบบ สอ.๓ ๒๕๖๕',
                    badgeColor: const Color(0xFF065F46),
                    icon: Icons.speed_rounded,
                    assetPath: 'assets/laws/dlpw_form_sor3_measurement_2565.pdf',
                    externalUrl: 'https://ratchakitcha.soc.go.th/documents/2205781.pdf',
                  ),
                  const SizedBox(height: 12),
                  _buildDocCard(
                    context,
                    title: 'แบบ สอ.๑: บัญชีรายชื่อสารเคมีอันตรายและ SDS ๑๖ หัวข้อ (พ.ศ. ๒๕๕๖)',
                    subtitle: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน • รายละเอียดข้อมูลความปลอดภัย ๑๖ หัวข้อ จำนวน ๔ หน้า A4',
                    badge: 'แบบ สอ.๑ ๒๕๕๖',
                    badgeColor: const Color(0xFF1E3A8A),
                    icon: Icons.description_rounded,
                    assetPath: 'assets/laws/dlpw_form_sor1_sds.pdf',
                    externalUrl: 'https://ratchakitcha.soc.go.th/documents/1991824.pdf',
                  ),
                  const SizedBox(height: 12),
                  _buildDocCard(
                    context,
                    title: 'กฎกระทรวงสารเคมีอันตราย พ.ศ. ๒๕๕๖ (ฉบับเต็ม ๖๑ หน้า)',
                    subtitle: 'กฎกระทรวงกำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัยเกี่ยวกับสารเคมีอันตราย',
                    badge: 'กฎกระทรวง ๒๕๕๖',
                    badgeColor: const Color(0xFF6B21A8),
                    icon: Icons.gavel_rounded,
                    assetPath: 'assets/laws/ministerial_regulation_chemical_2556.pdf',
                    externalUrl: 'https://ratchakitcha.soc.go.th/documents/1990425.pdf',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required String assetPath,
    String? externalUrl,
    VoidCallback? onCustomTap,
  }) {
    return InkWell(
      onTap: () {
        if (onCustomTap != null) {
          onCustomTap();
          return;
        }
        Navigator.pop(context);
        ChemicalGazetteViewerDialog.show(
          context,
          assetPath: assetPath,
          title: title,
          subtitle: subtitle,
          formCode: badge,
          externalUrl: externalUrl,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: badgeColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.prompt(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: GoogleFonts.prompt(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.prompt(fontSize: 11, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                if (onCustomTap != null) {
                  onCustomTap();
                  return;
                }
                Navigator.pop(context);
                ChemicalGazetteViewerDialog.show(
                  context,
                  assetPath: assetPath,
                  title: title,
                  subtitle: subtitle,
                  formCode: badge,
                  externalUrl: externalUrl,
                );
              },
              icon: const Icon(Icons.visibility_rounded, size: 16),
              label: const Text('เปิดดูต้นฉบับ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: badgeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
