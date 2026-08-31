import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../domain/models/legal_master_item_model.dart';
import '../../domain/models/legal_compliance_assessment_model.dart';
import '../providers/legal_register_providers.dart';
import 'legal_assessment_dialog.dart';

/// Modal dialog for browsing official Royal Gazette (ราชกิจจานุเบกษา) statutory details,
/// publication citation metadata, full legal provisions, compliance criteria, penalty clauses,
/// and document preview with quick assessment trigger.
class LegalGazetteViewerDialog extends ConsumerStatefulWidget {
  final LegalMasterItemModel masterItem;
  final VoidCallback? onStartAssessment;

  const LegalGazetteViewerDialog({
    Key? key,
    required this.masterItem,
    this.onStartAssessment,
  }) : super(key: key);

  @override
  ConsumerState<LegalGazetteViewerDialog> createState() => _LegalGazetteViewerDialogState();
}

class _LegalGazetteViewerDialogState extends ConsumerState<LegalGazetteViewerDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _printGazetteProvision() async {
    final item = widget.masterItem;
    final doc = pw.Document();
    final fontRegular = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'สำเนาประกาศราชกิจจานุเบกษา (Statutory Safety Reference)',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  item.gazetteReference.formattedCitation,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ),
              pw.Divider(thickness: 1, color: PdfColors.teal800),
              pw.SizedBox(height: 12),

              pw.Text('ชื่อกฎหมาย: ${item.lawNameTh}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('English: ${item.lawNameEn}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.SizedBox(height: 8),

              pw.Text('หน่วยงานกำกับดูแล: ${item.governingAuthority}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('มาตรา / ข้อ: ${item.articleNo}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
              pw.SizedBox(height: 12),

              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('หัวข้อ: ${item.title}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Text('รายละเอียดข้อกำหนด:', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text(item.description, style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),
              pw.Text('เกณฑ์การบังคับใช้ (Applicability):', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(item.applicabilityCriteria, style: const pw.TextStyle(fontSize: 9)),

              pw.SizedBox(height: 8),
              pw.Text('เกณฑ์การปฏิบัติตาม (Compliance Criteria):', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(item.complianceCriteria, style: const pw.TextStyle(fontSize: 9)),

              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  border: pw.Border.all(color: PdfColors.red300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'บทกำหนดโทษ: ${item.penaltySummary}',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('SAFAPP Legal Compliance Repository', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('พิมพ์เมื่อ: ${DateTime.now().toIso8601String().substring(0, 16)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: 'Gazette_${item.itemId}.pdf',
    );
  }

  void _openAssessmentForThisItem() async {
    final repo = ref.read(legalRepoProvider);
    final existing = await repo.getAssessmentByRequirementCode(widget.masterItem.itemId);

    LegalComplianceAssessmentModel itemToAssess;
    if (existing != null) {
      itemToAssess = existing;
    } else {
      itemToAssess = LegalComplianceAssessmentModel(
        masterItemId: widget.masterItem.itemId,
        requirementCode: widget.masterItem.itemId,
        requirementTitle: widget.masterItem.title,
        requirementDetails: widget.masterItem.complianceCriteria,
        category: widget.masterItem.category,
        lawId: widget.masterItem.lawId,
        lawTitleTh: widget.masterItem.lawNameTh,
        articleNo: widget.masterItem.articleNo,
        riskLevel: widget.masterItem.riskLevel,
        penaltySummary: widget.masterItem.penaltySummary,
        evaluatedDate: DateTime.now().toIso8601String().substring(0, 10),
        evaluatorName: 'จป.วิชาชีพ',
      );
    }

    if (mounted) {
      Navigator.pop(context); // Close gazette viewer
      showDialog(
        context: context,
        builder: (ctx) => LegalAssessmentDialog(
          assessment: itemToAssess,
          onSaved: (saved) {
            ref.invalidate(legalAssessmentListProvider);
            ref.invalidate(legalComplianceKpiProvider);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.masterItem;
    final catEnum = item.categoryEnum;
    final riskEnum = item.riskLevelEnum;
    final gazette = item.gazetteReference;

    final hasPdfAsset = item.pdfAssetPath != null && item.pdfAssetPath!.isNotEmpty;
    final pdfFile = hasPdfAsset ? File(item.pdfAssetPath!) : null;
    final pdfExists = pdfFile != null && pdfFile.existsSync();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        width: 920,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF0F172A), catEnum.primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(catEnum.icon, color: Colors.white, size: 24),
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
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.itemId,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: riskEnum.bgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                riskEnum.labelTh,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: riskEnum.color),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                gazette.formattedCitation,
                                style: TextStyle(fontSize: 12, color: Colors.teal.shade100),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.lawNameTh,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.print_rounded, color: Colors.white),
                    tooltip: 'พิมพ์สำเนาข้อกำหนด',
                    onPressed: _printGazetteProvision,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: 'ปิด',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF0D9488),
                indicatorWeight: 3,
                labelColor: const Color(0xFF0D9488),
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(icon: Icon(Icons.description_rounded, size: 18), text: 'รายละเอียดข้อกฎหมาย & เกณฑ์ปฏิบัติ'),
                  Tab(icon: Icon(Icons.menu_book_rounded, size: 18), text: 'ฉบับประกาศราชกิจจานุเบกษา'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Comprehensive Statutory Detail View
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Article & Title Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.articleNo,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D9488),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.description,
                                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade800, height: 1.5),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Two column layout: Applicability vs Compliance Criteria
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 650;
                            return isNarrow
                                ? Column(
                                    children: [
                                      _buildSectionCard(
                                        title: 'เกณฑ์การบังคับใช้ (Applicability Criteria)',
                                        icon: Icons.domain_rounded,
                                        color: const Color(0xFF3B82F6),
                                        content: item.applicabilityCriteria,
                                      ),
                                      const SizedBox(height: 14),
                                      _buildSectionCard(
                                        title: 'เกณฑ์ความสอดคล้อง (Compliance Criteria)',
                                        icon: Icons.task_alt_rounded,
                                        color: const Color(0xFF10B981),
                                        content: item.complianceCriteria,
                                      ),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildSectionCard(
                                          title: 'เกณฑ์การบังคับใช้ (Applicability Criteria)',
                                          icon: Icons.domain_rounded,
                                          color: const Color(0xFF3B82F6),
                                          content: item.applicabilityCriteria,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: _buildSectionCard(
                                          title: 'เกณฑ์ความสอดคล้อง (Compliance Criteria)',
                                          icon: Icons.task_alt_rounded,
                                          color: const Color(0xFF10B981),
                                          content: item.complianceCriteria,
                                        ),
                                      ),
                                    ],
                                  );
                          },
                        ),

                        const SizedBox(height: 18),

                        // Statutory Evidence & Form Metadata Row
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'หลักฐานที่ต้องจัดทำ / ตรวจสอบ',
                                      style: TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(item.evidenceTypeEnum.icon, size: 18, color: const Color(0xFF0D9488)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            item.evidenceTypeLabelTh,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (item.officialFormName != null && item.officialFormName!.isNotEmpty) ...[
                                Container(width: 1, height: 40, color: Colors.grey.shade300),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'แบบฟอร์มรายงานราชการ',
                                        style: TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.officialFormName!,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              Container(width: 1, height: 40, color: Colors.grey.shade300),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ระยะเวลาเก็บรักษา',
                                    style: TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.retentionYears} ปี',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Statutory Penalty Alert Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.gavel_rounded, color: Color(0xFFDC2626), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'บทกำหนดโทษตามกฎหมาย (Statutory Penalties)',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF991B1B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.penaltySummary,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFB91C1C),
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 2: Official Royal Gazette Paper Layout Preview
                  pdfExists
                      ? SfPdfViewer.file(pdfFile!)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Container(
                              width: 680,
                              padding: const EdgeInsets.all(36),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFDF8),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2D9C8), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Royal Garuda Emblem Header simulation
                                  const Icon(Icons.account_balance_rounded, size: 48, color: Color(0xFF854D0E)),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'ราชกิจจานุเบกษา',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF451A03),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    gazette.formattedCitation,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF78350F)),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: Color(0xFFB45309), thickness: 1.5),
                                  const SizedBox(height: 16),

                                  Text(
                                    item.lawNameTh,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1C1917),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'หน่วยงาน: ${item.governingAuthority}',
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF57534E)),
                                  ),
                                  const SizedBox(height: 24),

                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${item.articleNo} : ${item.title}',
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '        ${item.description}',
                                      textAlign: TextAlign.justify,
                                      style: const TextStyle(fontSize: 13.5, color: Color(0xFF292524), height: 1.6),
                                    ),
                                  ),

                                  const SizedBox(height: 20),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFFDE68A)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'เกณฑ์การปฏิบัติตามมาตรฐาน:',
                                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.complianceCriteria,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.4),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'บทกำหนดโทษ: ${item.penaltySummary}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),

            // Footer with Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'รหัสกฎหมาย: ${item.lawId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('ปิด'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _openAssessmentForThisItem,
                        icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                        label: const Text('ประเมินความสอดคล้องข้อนี้'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
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
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, height: 1.45),
          ),
        ],
      ),
    );
  }
}
