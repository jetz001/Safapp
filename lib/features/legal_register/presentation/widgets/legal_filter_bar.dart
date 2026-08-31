import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/legal_master_item_model.dart';
import '../../domain/models/legal_compliance_assessment_model.dart';
import '../../domain/models/legal_capa_model.dart';
import '../providers/legal_register_providers.dart';

/// Filter & Quick Action Toolbar for SAFAPP Legal Register:
/// - Keyword Search Textfield
/// - 8 Statutory Category Horizontal Chips
/// - Compliance Status Dropdown Selector
/// - Quick Actions: PDF Export, Excel Export, Reset Filters
class LegalFilterBar extends ConsumerStatefulWidget {
  final int activeTab; // 0: Register/Assessments, 1: Master Gazette, 2: CAPA

  const LegalFilterBar({
    Key? key,
    this.activeTab = 0,
  }) : super(key: key);

  @override
  ConsumerState<LegalFilterBar> createState() => _LegalFilterBarState();
}

class _LegalFilterBarState extends ConsumerState<LegalFilterBar> {
  late TextEditingController _searchController;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (widget.activeTab == 0) {
      ref.read(legalSearchQueryProvider.notifier).state = val;
    } else if (widget.activeTab == 1) {
      ref.read(legalMasterSearchQueryProvider.notifier).state = val;
    } else {
      ref.read(legalCapaSearchQueryProvider.notifier).state = val;
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  void _resetAllFilters() {
    _searchController.clear();
    if (widget.activeTab == 0) {
      ref.read(legalSearchQueryProvider.notifier).clear();
      ref.read(legalCategoryFilterProvider.notifier).reset();
      ref.read(legalStatusFilterProvider.notifier).reset();
    } else if (widget.activeTab == 1) {
      ref.read(legalMasterSearchQueryProvider.notifier).clear();
      ref.read(legalCategoryFilterProvider.notifier).reset();
    } else {
      ref.read(legalCapaSearchQueryProvider.notifier).clear();
      ref.read(legalCapaStatusFilterProvider.notifier).reset();
    }
  }

  // --------------------------------------------------------------------------
  // Official PDF Compliance Report Generation
  // --------------------------------------------------------------------------
  Future<void> _exportPdfReport() async {
    setState(() => _isExporting = true);
    try {
      final repo = ref.read(legalRepoProvider);
      final assessments = await repo.getAllAssessments();
      final stats = await repo.calculateStats();
      final capas = await repo.getAllCapa();

      final pdfDoc = pw.Document();

      // Thai Font loading fallback with default base fonts
      final fontRegular = await PdfGoogleFonts.sarabunRegular();
      final fontBold = await PdfGoogleFonts.sarabunBold();

      pdfDoc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
          ),
          header: (pw.Context context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.only(bottom: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal, width: 1.5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ทะเบียนกฎหมายความปลอดภัยและการประเมินความสอดคล้อง (Legal Register & Compliance Report)',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                      ),
                      pw.Text(
                        'ตามพระราชบัญญัติความปลอดภัยฯ ๒๕๕๔ และกฎกระทรวงราชกิจจานุเบกษา ๘ ฉบับหลัก',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'วันที่จัดทำ: ${DateTime.now().toIso8601String().substring(0, 10)}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                      ),
                      pw.Text(
                        'Basic CI: ${stats.basicCompliancePercent}% | Risk WCI: ${stats.riskWeightedCompliancePercent}%',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('SAFAPP Occupational Safety & Health Legal Management System', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('หน้า ${context.pageNumber} จาก ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            );
          },
          build: (pw.Context context) {
            return [
              // KPI Summary Table
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                margin: const pw.EdgeInsets.only(bottom: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildPdfKpiItem('ข้อกำหนดทั้งหมด', '${stats.totalItems} ข้อ', fontBold),
                    _buildPdfKpiItem('ที่เกี่ยวข้อง', '${stats.applicableItems} ข้อ', fontBold),
                    _buildPdfKpiItem('สอดคล้อง (Compliant)', '${stats.compliantCount} ข้อ', fontBold, color: PdfColors.green800),
                    _buildPdfKpiItem('ไม่สอดคล้อง (Non-Compliant)', '${stats.nonCompliantCount} ข้อ', fontBold, color: PdfColors.red800),
                    _buildPdfKpiItem('อยู่ระหว่างดำเนินการ', '${stats.inProgressCount} ข้อ', fontBold, color: PdfColors.orange800),
                    _buildPdfKpiItem('CAPA รอแก้ไข', '${stats.pendingCapaCount + stats.inProgressCapaCount} รายการ', fontBold, color: PdfColors.blue800),
                  ],
                ),
              ),

              // Assessment Table
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0F766E)),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.center,
                columnWidths: {
                  0: const pw.FixedColumnWidth(45), // Code
                  1: const pw.FlexColumnWidth(2.5), // Law & Article
                  2: const pw.FlexColumnWidth(3), // Title & Criteria
                  3: const pw.FixedColumnWidth(40), // Risk
                  4: const pw.FixedColumnWidth(60), // Status
                  5: const pw.FlexColumnWidth(2.5), // Actual Practice
                  6: const pw.FixedColumnWidth(55), // Evaluator
                  7: const pw.FixedColumnWidth(45), // Date
                },
                headers: [
                  'รหัส',
                  'กฎหมาย & มาตรา',
                  'ข้อกำหนด & เกณฑ์ความสอดคล้อง',
                  'ความเสี่ยง',
                  'สถานะการประเมิน',
                  'การปฏิบัติตามจริงในสถานประกอบการ',
                  'ผู้ประเมิน',
                  'วันที่ตรวจ',
                ],
                data: assessments.map((a) {
                  return [
                    a.requirementCode,
                    '${a.lawTitleTh}\n(${a.articleNo})',
                    '${a.requirementTitle}\n${a.requirementDetails}',
                    a.riskLevelEnum.labelTh.split(' ').first,
                    a.statusLabelTh,
                    a.actualPractice ?? '-',
                    a.evaluatorName,
                    a.evaluatedDate,
                  ];
                }).toList(),
              ),

              // CAPA Table Section if any
              if (capas.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  'แผนการปรับปรุงแก้ไขข้อบกพร่อง (CAPA Action Plans)',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                ),
                pw.SizedBox(height: 6),
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E3A8A)),
                  cellStyle: const pw.TextStyle(fontSize: 7.5),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(45),
                    1: const pw.FlexColumnWidth(2.5),
                    2: const pw.FlexColumnWidth(2.5),
                    3: const pw.FlexColumnWidth(2.5),
                    4: const pw.FixedColumnWidth(55),
                    5: const pw.FixedColumnWidth(50),
                    6: const pw.FixedColumnWidth(55),
                  },
                  headers: [
                    'รหัสข้อกำหนด',
                    'ชื่อแผนงานปรับปรุง (Action Title)',
                    'สาเหตุที่แท้จริง (Root Cause)',
                    'มาตรการแก้ไข / ป้องกัน (CAPA)',
                    'ผู้รับผิดชอบ (PIC)',
                    'กำหนดเสร็จ',
                    'สถานะ',
                  ],
                  data: capas.map((c) {
                    return [
                      c.requirementCode ?? '-',
                      c.actionTitle,
                      c.rootCause,
                      'แก้ไข: ${c.correctiveAction}\nป้องกัน: ${c.preventiveAction ?? "-"}',
                      '${c.picName} (${c.picDepartment ?? "-"})',
                      c.targetDate,
                      c.statusLabelTh,
                    ];
                  }).toList(),
                ),
              ],
            ];
          },
        ),
      );

      final pdfBytes = await pdfDoc.save();
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: 'SAFAPP_Legal_Register_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งออกรายงานทะเบียนกฎหมาย PDF เรียบร้อยแล้ว'),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการสร้าง PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  pw.Widget _buildPdfKpiItem(String title, String value, pw.Font fontBold, {PdfColor color = PdfColors.blueGrey900}) {
    return pw.Column(
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Excel (.xlsx) Spreadsheet Export Generation
  // --------------------------------------------------------------------------
  Future<void> _exportExcelWorkbook() async {
    setState(() => _isExporting = true);
    try {
      final repo = ref.read(legalRepoProvider);
      final assessments = await repo.getAllAssessments();
      final capas = await repo.getAllCapa();
      final stats = await repo.calculateStats();

      final excel = xl.Excel.createExcel();

      // Sheet 1: ทะเบียนและการประเมินความสอดคล้อง
      const sheetNameAssessments = 'Legal_Assessments';
      excel.rename('Sheet1', sheetNameAssessments);
      final sheet1 = excel[sheetNameAssessments];
      excel.setDefaultSheet(sheetNameAssessments);

      // Header style
      final headerStyle = xl.CellStyle(
        backgroundColorHex: xl.ExcelColor.fromHexString('#0D9488'),
        fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
        bold: true,
        horizontalAlign: xl.HorizontalAlign.Center,
        verticalAlign: xl.VerticalAlign.Center,
      );

      // Row 1-2: Summary Title
      sheet1.appendRow([
        xl.TextCellValue('รายงานทะเบียนกฎหมายความปลอดภัยและการประเมินความสอดคล้อง (SAFAPP Legal Register)'),
      ]);
      sheet1.appendRow([
        xl.TextCellValue('วันที่ส่งออก: ${DateTime.now().toIso8601String().substring(0, 10)} | Basic Compliance: ${stats.basicCompliancePercent}% | Risk-Weighted Compliance: ${stats.riskWeightedCompliancePercent}%'),
      ]);
      sheet1.appendRow([xl.TextCellValue('')]); // Blank row

      // Table Headers
      sheet1.appendRow([
        xl.TextCellValue('ลำดับ'),
        xl.TextCellValue('รหัสข้อกำหนด'),
        xl.TextCellValue('หมวดหมู่กฎหมาย'),
        xl.TextCellValue('ชื่อกฎหมายราชกิจจานุเบกษา'),
        xl.TextCellValue('มาตรา / ข้อ'),
        xl.TextCellValue('หัวข้อข้อกำหนด'),
        xl.TextCellValue('รายละเอียดข้อกฎหมาย'),
        xl.TextCellValue('ระดับความเสี่ยง'),
        xl.TextCellValue('ความเกี่ยวข้อง (Applicable)'),
        xl.TextCellValue('สถานะความสอดคล้อง'),
        xl.TextCellValue('การปฏิบัติตามจริงในสถานประกอบการ'),
        xl.TextCellValue('ผู้ประเมิน'),
        xl.TextCellValue('ตำแหน่ง / แผนก'),
        xl.TextCellValue('วันที่ประเมิน'),
        xl.TextCellValue('วันที่ทบทวนครั้งถัดไป'),
        xl.TextCellValue('บทกำหนดโทษ'),
      ]);

      // Style header row
      for (int i = 0; i < 16; i++) {
        final cell = sheet1.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3));
        cell.cellStyle = headerStyle;
      }

      // Add Data rows
      for (int idx = 0; idx < assessments.length; idx++) {
        final a = assessments[idx];
        sheet1.appendRow([
          xl.IntCellValue(idx + 1),
          xl.TextCellValue(a.requirementCode),
          xl.TextCellValue(a.categoryLabelTh),
          xl.TextCellValue(a.lawTitleTh),
          xl.TextCellValue(a.articleNo),
          xl.TextCellValue(a.requirementTitle),
          xl.TextCellValue(a.requirementDetails),
          xl.TextCellValue(a.riskLevelEnum.labelTh),
          xl.TextCellValue(a.isApplicable ? 'เกี่ยวข้อง' : 'ไม่เกี่ยวข้อง'),
          xl.TextCellValue(a.statusLabelTh),
          xl.TextCellValue(a.actualPractice ?? '-'),
          xl.TextCellValue(a.evaluatorName),
          xl.TextCellValue('${a.evaluatorRole ?? "-"} / ${a.department ?? "-"}'),
          xl.TextCellValue(a.evaluatedDate),
          xl.TextCellValue(a.nextReviewDate ?? '-'),
          xl.TextCellValue(a.penaltySummary ?? '-'),
        ]);
      }

      // Sheet 2: แผน CAPA
      const sheetNameCapa = 'CAPA_Action_Plans';
      final sheet2 = excel[sheetNameCapa];

      final capaHeaderStyle = xl.CellStyle(
        backgroundColorHex: xl.ExcelColor.fromHexString('#1E3A8A'),
        fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
        bold: true,
        horizontalAlign: xl.HorizontalAlign.Center,
      );

      sheet2.appendRow([
        xl.TextCellValue('แผนการแก้ไขและป้องกันข้อบกพร่องทางกฎหมาย (CAPA Action Plans)'),
      ]);
      sheet2.appendRow([xl.TextCellValue('')]);

      sheet2.appendRow([
        xl.TextCellValue('ลำดับ'),
        xl.TextCellValue('รหัสข้อกำหนดอ้างอิง'),
        xl.TextCellValue('ชื่อกฎหมาย'),
        xl.TextCellValue('ชื่อแผนงานแก้ไข (Action Title)'),
        xl.TextCellValue('สาเหตุที่แท้จริง (Root Cause)'),
        xl.TextCellValue('มาตรการแก้ไขเฉพาะหน้า (Corrective Action)'),
        xl.TextCellValue('มาตรการป้องกันการเกิดซ้ำ (Preventive Action)'),
        xl.TextCellValue('ผู้รับผิดชอบ (PIC)'),
        xl.TextCellValue('แผนก'),
        xl.TextCellValue('กำหนดเสร็จ (Target Date)'),
        xl.TextCellValue('วันที่เสร็จจริง (Completed Date)'),
        xl.TextCellValue('สถานะ'),
        xl.TextCellValue('บันทึกปิดงาน'),
      ]);

      for (int i = 0; i < 13; i++) {
        final cell = sheet2.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2));
        cell.cellStyle = capaHeaderStyle;
      }

      for (int idx = 0; idx < capas.length; idx++) {
        final c = capas[idx];
        sheet2.appendRow([
          xl.IntCellValue(idx + 1),
          xl.TextCellValue(c.requirementCode ?? '-'),
          xl.TextCellValue(c.lawTitle ?? '-'),
          xl.TextCellValue(c.actionTitle),
          xl.TextCellValue(c.rootCause),
          xl.TextCellValue(c.correctiveAction),
          xl.TextCellValue(c.preventiveAction ?? '-'),
          xl.TextCellValue(c.picName),
          xl.TextCellValue(c.picDepartment ?? '-'),
          xl.TextCellValue(c.targetDate),
          xl.TextCellValue(c.completedDate ?? '-'),
          xl.TextCellValue(c.statusLabelTh),
          xl.TextCellValue(c.notes ?? '-'),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final dir = await getApplicationDocumentsDirectory();
        final filename = 'SAFAPP_Legal_Register_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final savePath = p.join(dir.path, filename);
        final file = File(savePath);
        await file.writeAsBytes(fileBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('บันทึกไฟล์ Excel สำเร็จ: $filename'),
              backgroundColor: const Color(0xFF0D9488),
              action: SnackBarAction(
                label: 'เปิดไฟล์',
                textColor: Colors.white,
                onPressed: () async {
                  if (Platform.isWindows) {
                    await Process.run('cmd', ['/c', 'start', '""', savePath], runInShell: true);
                  }
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการสร้าง Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCategory = ref.watch(legalCategoryFilterProvider);
    final activeStatus = ref.watch(legalStatusFilterProvider);
    final activeCapaStatus = ref.watch(legalCapaStatusFilterProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Filter Row: Search Field, Status Dropdown, Action Buttons
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 750;
              return Column(
                children: [
                  Row(
                    children: [
                      // Search TextField
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: widget.activeTab == 0
                                ? 'ค้นหาข้อกำหนด, ชื่อกฎหมาย, มาตรา, ผู้ประเมิน...'
                                : (widget.activeTab == 1
                                    ? 'ค้นหาคลังกฎหมายราชกิจจานุเบกษา ๘ ฉบับ, บทลงโทษ...'
                                    : 'ค้นหาแผนงาน CAPA, PIC, สาเหตุที่แท้จริง...'),
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0D9488)),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
                            ),
                          ),
                        ),
                      ),

                      if (!isNarrow) ...[
                        const SizedBox(width: 12),
                        // Status Filter Dropdown
                        if (widget.activeTab == 0) _buildStatusDropdown(activeStatus),
                        if (widget.activeTab == 2) _buildCapaStatusDropdown(activeCapaStatus),
                        const SizedBox(width: 12),
                        // Action Buttons (PDF, Excel, Reset)
                        _buildActionButtons(),
                      ],
                    ],
                  ),
                  if (isNarrow) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (widget.activeTab == 0) Expanded(child: _buildStatusDropdown(activeStatus)),
                        if (widget.activeTab == 2) Expanded(child: _buildCapaStatusDropdown(activeCapaStatus)),
                        const SizedBox(width: 8),
                        _buildActionButtons(),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),

          // 8 Category Filter Chips (Shown for Tab 0 and Tab 1)
          if (widget.activeTab == 0 || widget.activeTab == 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip('ALL', 'ทั้งหมด (All 8 Laws)', Icons.apps_rounded, const Color(0xFF0D9488), activeCategory == 'ALL'),
                  const SizedBox(width: 6),
                  ...LegalCategoryEnum.values.map((cat) {
                    final isSelected = activeCategory == cat.code;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildCategoryChip(
                        cat.code,
                        cat.titleTh,
                        cat.icon,
                        cat.primaryColor,
                        isSelected,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(String activeStatus) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: activeStatus,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF0D9488)),
          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
          items: const [
            DropdownMenuItem(value: 'ALL', child: Text('สถานะ: ทั้งหมด')),
            DropdownMenuItem(value: 'COMPLIANT', child: Text('🟢 สอดคล้อง (Compliant)')),
            DropdownMenuItem(value: 'NON_COMPLIANT', child: Text('🔴 ไม่สอดคล้อง (Non-Compliant)')),
            DropdownMenuItem(value: 'IN_PROGRESS', child: Text('🟡 อยู่ระหว่างดำเนินการ')),
            DropdownMenuItem(value: 'NOT_APPLICABLE', child: Text('⚪ ไม่เกี่ยวข้อง (N/A)')),
          ],
          onChanged: (val) {
            if (val != null) {
              ref.read(legalStatusFilterProvider.notifier).state = val;
            }
          },
        ),
      ),
    );
  }

  Widget _buildCapaStatusDropdown(String activeStatus) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: activeStatus,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF0D9488)),
          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
          items: const [
            DropdownMenuItem(value: 'ALL', child: Text('สถานะ CAPA: ทั้งหมด')),
            DropdownMenuItem(value: 'PENDING', child: Text('⏳ รอดำเนินการ (Pending)')),
            DropdownMenuItem(value: 'IN_PROGRESS', child: Text('🏃 กำลังดำเนินการ (In-Progress)')),
            DropdownMenuItem(value: 'COMPLETED', child: Text('✅ เสร็จสิ้นแล้ว (Completed)')),
            DropdownMenuItem(value: 'OVERDUE', child: Text('⚠️ เกินกำหนด (Overdue)')),
          ],
          onChanged: (val) {
            if (val != null) {
              ref.read(legalCapaStatusFilterProvider.notifier).state = val;
            }
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Export PDF Button
        Tooltip(
          message: 'พิมพ์รายงานประเมินความสอดคล้อง (PDF)',
          child: ElevatedButton.icon(
            onPressed: _isExporting ? null : _exportPdfReport,
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
            label: const Text('PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Export Excel Button
        Tooltip(
          message: 'ส่งออกทะเบียนและแผนงาน CAPA (Excel .xlsx)',
          child: ElevatedButton.icon(
            onPressed: _isExporting ? null : _exportExcelWorkbook,
            icon: const Icon(Icons.table_chart_rounded, size: 16),
            label: const Text('Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Reset Filter Button
        Tooltip(
          message: 'ล้างตัวกรองทั้งหมด',
          child: OutlinedButton(
            onPressed: _resetAllFilters,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Icon(Icons.refresh_rounded, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    String code,
    String label,
    IconData icon,
    Color color,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        ref.read(legalCategoryFilterProvider.notifier).state = code;
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
