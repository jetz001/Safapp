import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../domain/models/risk_assessment_models.dart';
import '../providers/risk_assessment_providers.dart';
import '../../services/por1_por2_pdf_service.dart';
import '../../services/por1_por2_excel_service.dart';

class OfficialReportPreviewPage extends ConsumerStatefulWidget {
  final int sessionId;

  const OfficialReportPreviewPage({Key? key, required this.sessionId}) : super(key: key);

  @override
  ConsumerState<OfficialReportPreviewPage> createState() => _OfficialReportPreviewPageState();
}

class _OfficialReportPreviewPageState extends ConsumerState<OfficialReportPreviewPage> {
  Uint8List? _pdfBytes;
  bool _isLoadingPdf = true;
  String? _pdfError;
  bool _isExportingExcel = false;
  bool _isSavingPdf = false;

  @override
  void initState() {
    super.initState();
    _generatePdfBytes();
  }

  Future<void> _generatePdfBytes() async {
    setState(() {
      _isLoadingPdf = true;
      _pdfError = null;
    });

    try {
      final company = ref.read(companyProfileNotifierProvider).value ??
          CompanyProfile(
            companyName: 'สถานประกอบกิจการ',
            businessCategorySchedule: 2,
          );

      final sessionAsync = ref.read(sessionDetailProvider(widget.sessionId));
      final rowsAsync = ref.read(sessionReportRowsProvider(widget.sessionId));

      final session = sessionAsync.value;
      final rows = rowsAsync.value ?? [];

      if (session != null) {
        final bytes = await Por1Por2PdfService.generateOfficialPorDocument(
          company: company,
          session: session,
          rows: rows,
        );
        if (mounted) {
          setState(() {
            _pdfBytes = bytes;
            _isLoadingPdf = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _pdfError = 'ไม่พบข้อมูลชุดการประเมินอันตราย';
            _isLoadingPdf = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pdfError = 'เกิดข้อผิดพลาดในการสร้างเอกสาร PDF: $e';
          _isLoadingPdf = false;
        });
      }
    }
  }

  Future<String?> _savePdfToFile({bool openAfterSave = false}) async {
    if (_pdfBytes == null) return null;
    setState(() => _isSavingPdf = true);

    try {
      final session = ref.read(sessionDetailProvider(widget.sessionId)).value;
      final dir = await getApplicationDocumentsDirectory();
      final exportFolder = Directory('${dir.path}\\SafetySuperapp\\Exports');
      if (!await exportFolder.exists()) {
        await exportFolder.create(recursive: true);
      }

      final cleanTitle = (session?.sessionTitle ?? 'รายงาน_ปอ1_ปอ2').replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final filePath = '${exportFolder.path}\\รายงาน_${cleanTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(_pdfBytes!);

      if (openAfterSave) {
        // เปิดด้วยโปรแกรมดู PDF หรือบราวเซอร์หลักของ Windows ทันที
        Process.run('cmd', ['/c', 'start', '', filePath]);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกเอกสาร PDF เรียบร้อยแล้วที่:\n$filePath'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.indigo.shade700,
          ),
        );
      }
      return filePath;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก PDF: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isSavingPdf = false);
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _isExportingExcel = true);
    try {
      final company = ref.read(companyProfileNotifierProvider).value ??
          CompanyProfile(companyName: 'สถานประกอบกิจการ', businessCategorySchedule: 2);
      final session = ref.read(sessionDetailProvider(widget.sessionId)).value;
      final rows = ref.read(sessionReportRowsProvider(widget.sessionId)).value ?? [];

      if (session != null) {
        final bytes = Por1Por2ExcelService.exportToExcel(company: company, session: session, rows: rows);
        if (bytes != null) {
          final dir = await getApplicationDocumentsDirectory();
          final exportFolder = Directory('${dir.path}\\SafetySuperapp\\Exports');
          if (!await exportFolder.exists()) {
            await exportFolder.create(recursive: true);
          }
          final cleanTitle = session.sessionTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
          final filePath = '${exportFolder.path}\\รายงาน_ปอ1_ปอ2_${cleanTitle}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
          final file = File(filePath);
          await file.writeAsBytes(bytes);

          // เปิดโฟลเดอร์หรือไฟล์ทันที
          Process.run('cmd', ['/c', 'start', '', filePath]);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ส่งออกไฟล์ Excel เรียบร้อยแล้วที่:\n$filePath'),
                duration: const Duration(seconds: 5),
                backgroundColor: Colors.green.shade700,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งออก Excel: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingExcel = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('พรีวิวและส่งออกรายงานทางการ (แบบ ปอ. ๑ และ ปอ. ๒)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          // 1. ปุ่มบันทึก PDF
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E3A8A),
                side: const BorderSide(color: Color(0xFF1E3A8A)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: _isSavingPdf
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text('บันทึก PDF (.pdf)'),
              onPressed: (_pdfBytes == null || _isSavingPdf) ? null : () => _savePdfToFile(openAfterSave: false),
            ),
          ),

          // 2. ปุ่มเปิดในโปรแกรมภายนอก / พิมพ์เอกสาร
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: const Icon(Icons.print_rounded, size: 18),
              label: const Text('เปิดพิมพ์เอกสาร (Print)'),
              onPressed: (_pdfBytes == null || _isSavingPdf) ? null : () => _savePdfToFile(openAfterSave: true),
            ),
          ),

          // 3. ปุ่มส่งออก Excel
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: _isExportingExcel
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.table_view_rounded, size: 18),
              label: const Text('ส่งออก Excel (.xlsx)'),
              onPressed: _isExportingExcel ? null : _exportExcel,
            ),
          ),
        ],
      ),
      body: _isLoadingPdf
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังประมวลผลรายงานทางการ (ปอ.๑ และ ปอ.๒)...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _pdfError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(_pdfError!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _generatePdfBytes,
                          icon: const Icon(Icons.refresh),
                          label: const Text('ลองใหม่'),
                        ),
                      ],
                    ),
                  ),
                )
              : _pdfBytes != null
                  ? Container(
                      color: const Color(0xFF525659),
                      child: SfPdfViewer.memory(
                        _pdfBytes!,
                        canShowPaginationDialog: true,
                        canShowScrollHead: true,
                        canShowScrollStatus: true,
                      ),
                    )
                  : const Center(child: Text('ไม่มีข้อมูลเอกสาร')),
    );
  }
}
