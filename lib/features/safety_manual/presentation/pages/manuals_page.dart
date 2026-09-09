import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../services/safety_manual_pdf_exporter.dart';
import '../notifiers/manual_providers.dart';
import '../tabs/employee_handbook_tab.dart';
import '../tabs/master_manual_tab.dart';
import '../tabs/safety_induction_tab.dart';
import '../tabs/sop_hub_tab.dart';
import '../widgets/factory_scope_dialog.dart';

class ManualsPage extends ConsumerStatefulWidget {
  const ManualsPage({super.key});

  @override
  ConsumerState<ManualsPage> createState() => _ManualsPageState();
}

class _ManualsPageState extends ConsumerState<ManualsPage> {
  String? _standalonePdfPath;

  Future<void> _pickStandalonePdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _standalonePdfPath = result.files.single.path;
      });
    }
  }

  void _showFactoryScopeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const FactoryScopeDialog(),
    );
  }

  Future<void> _handlePdfExport(String type) async {
    try {
      if (type == 'MASTER') {
        final chapters = ref.read(masterManualChaptersProvider);
        final bytes = await SafetyManualPdfExporter.generateMasterManualBytes(chapters: chapters);
        await SafetyManualPdfExporter.printOrPreviewPdf(bytes, 'Master_Safety_Manual');
      } else if (type == 'HANDBOOK') {
        final chapters = ref.read(employeeHandbookChaptersProvider);
        final bytes = await SafetyManualPdfExporter.generateEmployeeHandbookBytes(chapters: chapters);
        await SafetyManualPdfExporter.printOrPreviewPdf(bytes, 'Employee_Safety_Handbook');
      } else if (type == 'INDUCTION') {
        final leaflet = ref.read(safetyInductionLeafletProvider);
        final bytes = await SafetyManualPdfExporter.generateInductionLeafletBytes(leaflet: leaflet);
        await SafetyManualPdfExporter.printOrPreviewPdf(bytes, 'Safety_Induction_Leaflet');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้าง PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If standalone PDF is open, show the PDF viewer with a back button
    if (_standalonePdfPath != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'เอกสารคู่มือ: ${File(_standalonePdfPath!).path.split(Platform.pathSeparator).last}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _standalonePdfPath = null),
            tooltip: 'กลับสู่คู่มือความปลอดภัย',
          ),
          actions: [
            TextButton.icon(
              onPressed: () => setState(() => _standalonePdfPath = null),
              icon: const Icon(Icons.close),
              label: const Text('ปิดการดูไฟล์ PDF'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
        body: SfPdfViewer.file(File(_standalonePdfPath!)),
      );
    }

    final scopeAsync = ref.watch(factoryScopeProvider);
    final activeCount = scopeAsync.value?.activeCount ?? 8;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: Color(0xFF0284C7)),
              SizedBox(width: 10),
              Text(
                'คู่มือและมาตรฐานความปลอดภัย (Safety Manual & SOPs Hub)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0.5,
          actions: [
            // Factory Scope Button with Active Count Badge
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: OutlinedButton.icon(
                onPressed: _showFactoryScopeDialog,
                icon: const Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 18),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('ขอบเขตโรงงาน', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$activeCount/8',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0284C7)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

            // Print / Export PDF Popup Menu
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: PopupMenuButton<String>(
                onSelected: _handlePdfExport,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'MASTER',
                    child: Row(
                      children: [
                        Icon(Icons.menu_book, color: Color(0xFF0284C7), size: 18),
                        SizedBox(width: 10),
                        Text('พิมพ์ เล่มเต็ม (Master Manual - A4)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'HANDBOOK',
                    child: Row(
                      children: [
                        Icon(Icons.badge, color: Color(0xFFD97706), size: 18),
                        SizedBox(width: 10),
                        Text('พิมพ์ ฉบับพนักงาน (Pocket Guide)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'INDUCTION',
                    child: Row(
                      children: [
                        Icon(Icons.assignment_ind, color: Color(0xFF0F766E), size: 18),
                        SizedBox(width: 10),
                        Text('พิมพ์ ใบสรุป 1-Page (+ใบฉีกปฐมนิเทศ)'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.print_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'พิมพ์/ส่งออก PDF',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),

            // Standalone PDF Viewer Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: OutlinedButton.icon(
                onPressed: _pickStandalonePdf,
                icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                label: const Text('เปิดไฟล์ PDF อิสระ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFF0284C7),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF0284C7),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(
                icon: Icon(Icons.format_list_bulleted_rounded, size: 20),
                text: '1. คลังขั้นตอนปฏิบัติงาน (SOPs Hub)',
              ),
              Tab(
                icon: Icon(Icons.menu_book_rounded, size: 20),
                text: '2. คู่มือเล่มเต็ม (Master Manual)',
              ),
              Tab(
                icon: Icon(Icons.badge_rounded, size: 20),
                text: '3. คู่มือฉบับพนักงาน (Pocket Guide)',
              ),
              Tab(
                icon: Icon(Icons.assignment_ind_rounded, size: 20),
                text: '4. ใบสรุป 1-Page (New Hire Induction)',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SopHubTab(),
            MasterManualTab(),
            EmployeeHandbookTab(),
            SafetyInductionTab(),
          ],
        ),
      ),
    );
  }
}
