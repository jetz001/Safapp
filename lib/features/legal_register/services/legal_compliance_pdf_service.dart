import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/models/legal_master_item_model.dart';
import '../domain/models/legal_compliance_assessment_model.dart';
import '../domain/models/legal_capa_model.dart';
import '../domain/models/legal_compliance_stats_model.dart';

/// Official Statutory PDF Generator for Safety Legal Register & Compliance Evaluation Report
/// (รายงานผลการประเมินความสอดคล้องตามกฎหมายความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน)
/// Conforming to Thai Occupational Safety, Health and Environment Act B.E. 2554 (2011)
/// and the 8 Royal Gazette Statutory Regulations.
class LegalCompliancePdfService {
  /// Generates the complete statutory Legal Compliance Evaluation Report PDF document as bytes.
  static Future<Uint8List> generatePdf({
    required List<LegalMasterItemModel> masterItems,
    required List<LegalComplianceAssessmentModel> assessments,
    required List<LegalCapaModel> capas,
    required LegalComplianceStatsModel stats,
    String? companyName,
    String? companyAddress,
    String? companyTaxId,
    String? companyBranch,
    String? assessmentPeriod,
    String? leadAssessorName,
    String? leadAssessorRole,
    String? safetyCommitteeRepName,
    String? managementRepName,
  }) async {
    final doc = pw.Document();

    // Load authentic Google Sarabun fonts for Thai rendering
    final fontRegular = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();
    final fontItalic = await PdfGoogleFonts.sarabunItalic();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
    );

    final orgName = companyName?.isNotEmpty == true
        ? companyName!
        : 'บริษัท โรงงานอุตสาหกรรมตัวอย่าง จำกัด (มหาชน)';
    final orgAddress = companyAddress?.isNotEmpty == true
        ? companyAddress!
        : '123/45 นิคมอุตสาหกรรม ตำบลคลองหนึ่ง อำเภอคลองหลวง จังหวัดปทุมธานี 12120';
    final orgTaxId = companyTaxId?.isNotEmpty == true ? companyTaxId! : '01055XXXXXXXX';
    final period = assessmentPeriod?.isNotEmpty == true
        ? assessmentPeriod!
        : 'ประจำปี ${DateTime.now().year + 543} (รอบการทบทวนประจำปี)';
    final assessorName = leadAssessorName?.isNotEmpty == true
        ? leadAssessorName!
        : 'นายสมศักดิ์ รักความปลอดภัย (จป.วิชาชีพ)';
    final assessorRole = leadAssessorRole?.isNotEmpty == true
        ? leadAssessorRole!
        : 'เจ้าหน้าที่ความปลอดภัยในการทำงานระดับวิชาชีพ';
    final committeeName = safetyCommitteeRepName?.isNotEmpty == true
        ? safetyCommitteeRepName!
        : 'นายประธาน คณะกรรมการ คปอ.';
    final execName = managementRepName?.isNotEmpty == true
        ? managementRepName!
        : 'นายกรรมการ ผู้จัดการทั่วไป';

    // Map master items by itemId for quick lookup
    final Map<String, LegalMasterItemModel> masterMap = {
      for (final m in masterItems) m.itemId: m,
    };

    // Use A4 Landscape layout for optimal multi-column statutory table readability
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        header: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue900,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Text(
                          'SAFAPP LEGAL REGISTER',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'ระบบประเมินความสอดคล้องตามกฎหมายความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน (๘ หมวดหมู่ราชกิจจานุเบกษา)',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text(
                    'พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ & ISO 45001:2018 §6.1.3',
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                ],
              ),
              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
            ],
          );
        },
        footer: (pw.Context ctx) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'รายงานผลการประเมินความสอดคล้องตามกฎหมาย: $orgName ($period)',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'วันที่จัดพิมพ์: ${DateTime.now().toIso8601String().substring(0, 10)}  |  หน้าที่ ${ctx.pageNumber} จาก ${ctx.pagesCount}',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context ctx) {
          return [
            // ----------------------------------------------------------------
            // 1. Report Title & Header Banner
            // ----------------------------------------------------------------
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.blue300, width: 1),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'รายงานผลการประเมินความสอดคล้องตามกฎหมายความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'STATUTORY SAFETY LEGAL COMPLIANCE EVALUATION & ACTION PLAN REPORT',
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'สถานประกอบการ: $orgName  |  ที่ตั้ง: $orgAddress  |  เลขประจำตัวผู้เสียภาษี: $orgTaxId',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: PdfColors.blue200),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('รอบการประเมิน: $period', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text('ผู้ประเมินหลัก: $assessorName', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
                        pw.Text('วันที่ประเมิน: ${stats.evaluatedDate ?? DateTime.now().toIso8601String().substring(0, 10)}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // ----------------------------------------------------------------
            // 2. Executive KPI Compliance Summary Boxes
            // ----------------------------------------------------------------
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Basic Compliance Index Card
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: stats.basicCompliancePercent >= 90
                          ? PdfColors.green50
                          : stats.basicCompliancePercent >= 75
                              ? PdfColors.amber50
                              : PdfColors.red50,
                      borderRadius: pw.BorderRadius.circular(5),
                      border: pw.Border.all(
                        color: stats.basicCompliancePercent >= 90
                            ? PdfColors.green300
                            : stats.basicCompliancePercent >= 75
                                ? PdfColors.amber300
                                : PdfColors.red300,
                        width: 1,
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'ดัชนีความสอดคล้องพื้นฐาน (Basic Compliance Index)',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${stats.basicCompliancePercent.toStringAsFixed(1)} %',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: stats.basicCompliancePercent >= 90
                                ? PdfColors.green900
                                : stats.basicCompliancePercent >= 75
                                    ? PdfColors.amber900
                                    : PdfColors.red900,
                          ),
                        ),
                        pw.Text(
                          'คิดจากข้อที่สอดคล้องเทียบข้อที่เกี่ยวข้องทั้งหมด (${stats.compliantCount} / ${stats.applicableItems} ข้อ)',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),

                // Risk-Weighted Compliance Index Card
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: stats.riskWeightedCompliancePercent >= 90
                          ? PdfColors.green50
                          : stats.riskWeightedCompliancePercent >= 75
                              ? PdfColors.amber50
                              : PdfColors.red50,
                      borderRadius: pw.BorderRadius.circular(5),
                      border: pw.Border.all(
                        color: stats.riskWeightedCompliancePercent >= 90
                            ? PdfColors.green300
                            : stats.riskWeightedCompliancePercent >= 75
                                ? PdfColors.amber300
                                : PdfColors.red300,
                        width: 1,
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'ดัชนีถ่วงน้ำหนักความเสี่ยง (Risk-Weighted Index)',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${stats.riskWeightedCompliancePercent.toStringAsFixed(1)} %',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: stats.riskWeightedCompliancePercent >= 90
                                ? PdfColors.green900
                                : stats.riskWeightedCompliancePercent >= 75
                                    ? PdfColors.amber900
                                    : PdfColors.red900,
                          ),
                        ),
                        pw.Text(
                          'คำนวณตามน้ำหนักความเสี่ยงกฎหมาย (High:3, Med:2, Low:1)',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),

                // Summary Counters Box
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(5),
                      border: pw.Border.all(color: PdfColors.grey300, width: 1),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('สถานะข้อกำหนดในทะเบียนกฎหมาย (${stats.totalItems} ข้อ):', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                            pw.Text('แผน CAPA: ${stats.totalCapaCount} แผน (เสร็จ ${stats.completedCapaCount} / ค้าง ${stats.pendingCapaCount + stats.inProgressCapaCount + stats.overdueCapaCount})', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMiniCounter('สอดคล้อง', stats.compliantCount, PdfColors.green800, PdfColors.green50),
                            _buildMiniCounter('ไม่สอดคล้อง', stats.nonCompliantCount, PdfColors.red800, PdfColors.red50),
                            _buildMiniCounter('อยู่ระหว่างทำ', stats.inProgressCount, PdfColors.amber800, PdfColors.amber50),
                            _buildMiniCounter('ไม่เกี่ยวข้อง', stats.notApplicableCount, PdfColors.grey700, PdfColors.grey200),
                            _buildMiniCounter('เสี่ยงสูงไม่สอดคล้อง', stats.highRiskNonCompliantCount, PdfColors.red900, PdfColors.red100),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // ----------------------------------------------------------------
            // 3. Executive Summary Breakdown across 8 Law Categories
            // ----------------------------------------------------------------
            _buildSectionHeader('ส่วนที่ ๑: สรุปผลการประเมินความสอดคล้องแยกตาม ๘ หมวดหมู่กฎหมายความปลอดภัย'),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    _buildTableCell('ลำดับ', isHeader: true, flex: 1),
                    _buildTableCell('หมวดหมู่กฎหมายตามราชกิจจานุเบกษา', isHeader: true, flex: 6, alignLeft: true),
                    _buildTableCell('ทั้งหมด\n(ข้อ)', isHeader: true, flex: 2),
                    _buildTableCell('เกี่ยวข้อง\n(ข้อ)', isHeader: true, flex: 2),
                    _buildTableCell('สอดคล้อง\n(ข้อ)', isHeader: true, flex: 2),
                    _buildTableCell('ไม่สอดคล้อง\n(ข้อ)', isHeader: true, flex: 2),
                    _buildTableCell('กำลังทำ\n(ข้อ)', isHeader: true, flex: 2),
                    _buildTableCell('ไม่เกี่ยว\n(ข้อ)', isHeader: true, flex: 2),
                    _buildTableCell('% สอดคล้อง\n(CI)', isHeader: true, flex: 3),
                    _buildTableCell('% ถ่วงน้ำหนัก\n(WCI)', isHeader: true, flex: 3),
                    _buildTableCell('สถานะสรุปหมวด', isHeader: true, flex: 3),
                  ],
                ),
                ...stats.categoryBreakdown.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final cat = entry.value;
                  final isPass = cat.basicCompliancePercent >= 100.0;
                  final statusText = isPass
                      ? 'สอดคล้องครบถ้วน'
                      : cat.nonCompliantCount > 0
                          ? 'มีข้อไม่สอดคล้อง'
                          : 'อยู่ระหว่างปรับปรุง';
                  final statusColor = isPass
                      ? PdfColors.green800
                      : cat.nonCompliantCount > 0
                          ? PdfColors.red800
                          : PdfColors.amber800;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: idx.isEven ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      _buildTableCell('$idx', flex: 1),
                      _buildTableCell(cat.categoryTitleTh, flex: 6, alignLeft: true),
                      _buildTableCell('${cat.totalItems}', flex: 2),
                      _buildTableCell('${cat.applicableItems}', flex: 2),
                      _buildTableCell('${cat.compliantCount}', flex: 2, color: PdfColors.green800),
                      _buildTableCell('${cat.nonCompliantCount}', flex: 2, color: cat.nonCompliantCount > 0 ? PdfColors.red800 : PdfColors.black),
                      _buildTableCell('${cat.inProgressCount}', flex: 2, color: cat.inProgressCount > 0 ? PdfColors.amber800 : PdfColors.black),
                      _buildTableCell('${cat.notApplicableCount}', flex: 2, color: PdfColors.grey700),
                      _buildTableCell('${cat.basicCompliancePercent.toStringAsFixed(1)}%', flex: 3, isBold: true),
                      _buildTableCell('${cat.riskWeightedCompliancePercent.toStringAsFixed(1)}%', flex: 3, isBold: true),
                      _buildTableCell(statusText, flex: 3, color: statusColor, isBold: true),
                    ],
                  );
                }),
                // Total Summary Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                  children: [
                    _buildTableCell('', flex: 1, isBold: true),
                    _buildTableCell('รวม / ค่าเฉลี่ยภาพรวมทั้งสิ้น (TOTAL SUMMARY)', flex: 6, alignLeft: true, isBold: true),
                    _buildTableCell('${stats.totalItems}', flex: 2, isBold: true),
                    _buildTableCell('${stats.applicableItems}', flex: 2, isBold: true),
                    _buildTableCell('${stats.compliantCount}', flex: 2, isBold: true, color: PdfColors.green900),
                    _buildTableCell('${stats.nonCompliantCount}', flex: 2, isBold: true, color: stats.nonCompliantCount > 0 ? PdfColors.red900 : PdfColors.black),
                    _buildTableCell('${stats.inProgressCount}', flex: 2, isBold: true, color: stats.inProgressCount > 0 ? PdfColors.amber900 : PdfColors.black),
                    _buildTableCell('${stats.notApplicableCount}', flex: 2, isBold: true),
                    _buildTableCell('${stats.basicCompliancePercent.toStringAsFixed(1)}%', flex: 3, isBold: true, color: PdfColors.blue900),
                    _buildTableCell('${stats.riskWeightedCompliancePercent.toStringAsFixed(1)}%', flex: 3, isBold: true, color: PdfColors.blue900),
                    _buildTableCell(
                      stats.basicCompliancePercent >= 90.0 ? 'ผ่านเกณฑ์ดีเยี่ยม' : 'ต้องเร่งรัด CAPA',
                      flex: 3,
                      isBold: true,
                      color: stats.basicCompliancePercent >= 90.0 ? PdfColors.green900 : PdfColors.red900,
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // ----------------------------------------------------------------
            // 4. Detailed Compliance Evaluation Table
            // ----------------------------------------------------------------
            _buildSectionHeader('ส่วนที่ ๒: ตารางทะเบียนและการประเมินความสอดคล้องรายข้อกำหนด (Legal Register & Evaluation Table)'),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    _buildTableCell('รหัส\nข้อกำหนด', isHeader: true, flex: 2),
                    _buildTableCell('หมวดหมู่ / กฎหมายอ้างอิง', isHeader: true, flex: 4, alignLeft: true),
                    _buildTableCell('มาตรา / ข้อกำหนดกฎหมาย', isHeader: true, flex: 5, alignLeft: true),
                    _buildTableCell('ระดับ\nความเสี่ยง', isHeader: true, flex: 2),
                    _buildTableCell('สถานะการประเมิน\nความสอดคล้อง', isHeader: true, flex: 3),
                    _buildTableCell('การปฏิบัติจริงของสถานประกอบการ / มาตรการควบคุม', isHeader: true, flex: 6, alignLeft: true),
                    _buildTableCell('เอกสารหลักฐาน / ผู้ประเมิน / วันที่', isHeader: true, flex: 4, alignLeft: true),
                  ],
                ),
                ...assessments.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final a = entry.value;
                  final master = masterMap[a.masterItemId];

                  String statusThai = a.statusLabelTh;
                  PdfColor statusTextColor = PdfColors.black;
                  PdfColor statusBgColor = PdfColors.white;

                  if (a.isCompliant) {
                    statusThai = 'สอดคล้อง (Compliant)';
                    statusTextColor = PdfColors.green900;
                    statusBgColor = PdfColors.green50;
                  } else if (a.isNonCompliant) {
                    statusThai = 'ไม่สอดคล้อง (Non-Compliant)';
                    statusTextColor = PdfColors.red900;
                    statusBgColor = PdfColors.red50;
                  } else if (a.isInProgress) {
                    statusThai = 'อยู่ระหว่างทำ (In-Progress)';
                    statusTextColor = PdfColors.amber900;
                    statusBgColor = PdfColors.amber50;
                  } else {
                    statusThai = 'ไม่เกี่ยวข้อง (N/A)';
                    statusTextColor = PdfColors.grey700;
                    statusBgColor = PdfColors.grey100;
                  }

                  final riskLevelStr = a.riskLevel == 'HIGH'
                      ? 'สูง (3)'
                      : a.riskLevel == 'LOW'
                          ? 'ต่ำ (1)'
                          : 'กลาง (2)';
                  final riskColor = a.riskLevel == 'HIGH'
                      ? PdfColors.red800
                      : a.riskLevel == 'LOW'
                          ? PdfColors.green800
                          : PdfColors.amber800;

                  final evidenceCount = a.evidenceFilePaths.length;
                  final evidenceStr = evidenceCount > 0
                      ? 'แนบหลักฐาน $evidenceCount ไฟล์\n'
                      : (master?.officialFormName != null ? 'แบบฟอร์ม: ${master!.officialFormName}\n' : '');

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: idx.isEven ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      _buildTableCell(a.requirementCode, flex: 2, isBold: true),
                      _buildTableCell(
                        '${a.categoryLabelTh}\n(${a.lawTitleTh})',
                        flex: 4,
                        alignLeft: true,
                      ),
                      _buildTableCell(
                        '${a.articleNo}: ${a.requirementTitle}\n${a.requirementDetails}',
                        flex: 5,
                        alignLeft: true,
                      ),
                      _buildTableCell(riskLevelStr, flex: 2, color: riskColor, isBold: true),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(3.5),
                        color: statusBgColor,
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          statusThai,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            color: statusTextColor,
                          ),
                        ),
                      ),
                      _buildTableCell(
                        a.actualPractice?.isNotEmpty == true
                            ? a.actualPractice!
                            : (a.isNotApplicable ? 'สถานประกอบการไม่มีกระบวนการหรือกิจกรรมที่เกี่ยวข้องกับข้อกฎหมายนี้' : 'รอดำเนินการระบุแนวทางปฏิบัติ'),
                        flex: 6,
                        alignLeft: true,
                      ),
                      _buildTableCell(
                        '$evidenceStrผู้ประเมิน: ${a.evaluatorName}\nวันที่: ${a.evaluatedDate}${a.nextReviewDate != null ? "\nทบทวน: ${a.nextReviewDate}" : ""}',
                        flex: 4,
                        alignLeft: true,
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 12),

            // ----------------------------------------------------------------
            // 5. CAPA Action Plan Table (Corrective & Preventive Action)
            // ----------------------------------------------------------------
            _buildSectionHeader('ส่วนที่ ๓: แผนปฏิบัติการแก้ไขและป้องกันข้อกฎหมายที่ไม่สอดคล้อง (CAPA Action Plan)'),
            if (capas.isEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.green300),
                ),
                child: pw.Center(
                  child: pw.Text(
                    '✓ สถานประกอบการมีผลการประเมินสอดคล้องตามกฎหมายครบถ้วนทุกข้อกำหนด หรือไม่มีรายการที่ต้องเปิดแผน CAPA ในรอบนี้',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                  ),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                    children: [
                      _buildTableCell('ลำดับ', isHeader: true, flex: 1),
                      _buildTableCell('รหัสข้อกำหนด / หัวข้อกฎหมาย', isHeader: true, flex: 4, alignLeft: true),
                      _buildTableCell('หัวข้อแผนงาน / สาเหตุรากเหง้า (Root Cause)', isHeader: true, flex: 5, alignLeft: true),
                      _buildTableCell('มาตรการแก้ไข (Corrective) & ป้องกัน (Preventive)', isHeader: true, flex: 6, alignLeft: true),
                      _buildTableCell('ผู้รับผิดชอบ\n(PIC)', isHeader: true, flex: 3),
                      _buildTableCell('กำหนดเสร็จ\n(Target)', isHeader: true, flex: 2),
                      _buildTableCell('วันที่เสร็จ\n(Actual)', isHeader: true, flex: 2),
                      _buildTableCell('สถานะ\n(Status)', isHeader: true, flex: 3),
                    ],
                  ),
                  ...capas.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final c = entry.value;

                    final statusLabel = c.statusLabelTh;
                    final statusColor = c.isCompleted
                        ? PdfColors.green800
                        : c.isOverdue
                            ? PdfColors.red800
                            : c.status.toUpperCase() == 'IN_PROGRESS'
                                ? PdfColors.blue800
                                : PdfColors.grey800;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: idx.isEven ? PdfColors.grey50 : PdfColors.white,
                      ),
                      children: [
                        _buildTableCell('$idx', flex: 1),
                        _buildTableCell(
                          '${c.requirementCode ?? "CAPA-$idx"}\n${c.requirementTitle ?? c.actionTitle}',
                          flex: 4,
                          alignLeft: true,
                        ),
                        _buildTableCell(
                          'แผนงาน: ${c.actionTitle}\nสาเหตุ: ${c.rootCause}',
                          flex: 5,
                          alignLeft: true,
                        ),
                        _buildTableCell(
                          'แก้ไข: ${c.correctiveAction}${c.preventiveAction != null && c.preventiveAction!.isNotEmpty ? "\nป้องกัน: ${c.preventiveAction}" : ""}',
                          flex: 6,
                          alignLeft: true,
                        ),
                        _buildTableCell(
                          '${c.picName}${c.picDepartment != null ? "\n(${c.picDepartment})" : ""}',
                          flex: 3,
                        ),
                        _buildTableCell(c.targetDate, flex: 2),
                        _buildTableCell(c.completedDate ?? '-', flex: 2),
                        _buildTableCell(statusLabel, flex: 3, color: statusColor, isBold: true),
                      ],
                    );
                  }),
                ],
              ),
            pw.SizedBox(height: 16),

            // ----------------------------------------------------------------
            // 6. 3-Tier Statutory Signature & Endorsement Block
            // ----------------------------------------------------------------
            _buildSectionHeader('ส่วนที่ ๔: การรับรองผลการประเมินและการลงนามอนุมัติ (Statutory Endorsement & Approval)'),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // 1. Assessor Signature
                pw.Container(
                  width: 235,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('ผู้ประเมินความสอดคล้องตามกฎหมาย', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 18),
                      pw.Text('ลงชื่อ ............................................................', style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 3),
                      pw.Text('( $assessorName )', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text(assessorRole, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                      pw.Text('วันที่: ....... / ....... / .......', style: const pw.TextStyle(fontSize: 7.5)),
                    ],
                  ),
                ),

                // 2. Safety Committee (คปอ.) Signature
                pw.Container(
                  width: 235,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('ผู้แทนคณะกรรมการความปลอดภัยฯ (คปอ.)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 18),
                      pw.Text('ลงชื่อ ............................................................', style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 3),
                      pw.Text('( $committeeName )', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('ประธาน / เลขานุการ คณะกรรมการ คปอ.', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                      pw.Text('วันที่: ....... / ....... / .......', style: const pw.TextStyle(fontSize: 7.5)),
                    ],
                  ),
                ),

                // 3. Top Management Signature
                pw.Container(
                  width: 235,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('ผู้บริหารสูงสุด / ผู้มีอำนาจลงนามผูกพัน', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 18),
                      pw.Text('ลงชื่อ ............................................................', style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 3),
                      pw.Text('( $execName )', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('กรรมการผู้จัดการ / นายจ้าง', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                      pw.Text('วันที่: ....... / ....... / .......', style: const pw.TextStyle(fontSize: 7.5)),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return await doc.save();
  }

  /// Displays interactive preview dialog and printing/sharing UI.
  static Future<void> printOrShare(
    BuildContext context, {
    required List<LegalMasterItemModel> masterItems,
    required List<LegalComplianceAssessmentModel> assessments,
    required List<LegalCapaModel> capas,
    required LegalComplianceStatsModel stats,
    String? companyName,
    String? companyAddress,
    String? companyTaxId,
    String? assessmentPeriod,
    String? leadAssessorName,
  }) async {
    final bytes = await generatePdf(
      masterItems: masterItems,
      assessments: assessments,
      capas: capas,
      stats: stats,
      companyName: companyName,
      companyAddress: companyAddress,
      companyTaxId: companyTaxId,
      assessmentPeriod: assessmentPeriod,
      leadAssessorName: leadAssessorName,
    );

    final filename = 'SAFAPP_Legal_Compliance_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: filename,
    );
  }

  /// Shares the PDF via standard platform share dialog.
  static Future<void> sharePdf({
    required List<LegalMasterItemModel> masterItems,
    required List<LegalComplianceAssessmentModel> assessments,
    required List<LegalCapaModel> capas,
    required LegalComplianceStatsModel stats,
    String? companyName,
    String? companyAddress,
    String? companyTaxId,
    String? assessmentPeriod,
    String? leadAssessorName,
  }) async {
    final bytes = await generatePdf(
      masterItems: masterItems,
      assessments: assessments,
      capas: capas,
      stats: stats,
      companyName: companyName,
      companyAddress: companyAddress,
      companyTaxId: companyTaxId,
      assessmentPeriod: assessmentPeriod,
      leadAssessorName: leadAssessorName,
    );

    final filename = 'SAFAPP_Legal_Compliance_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  /// Saves the PDF document directly to the app's export documents directory.
  static Future<String?> savePdfToFile({
    required List<LegalMasterItemModel> masterItems,
    required List<LegalComplianceAssessmentModel> assessments,
    required List<LegalCapaModel> capas,
    required LegalComplianceStatsModel stats,
    String? companyName,
    String? companyAddress,
    String? companyTaxId,
    String? assessmentPeriod,
    String? leadAssessorName,
  }) async {
    final bytes = await generatePdf(
      masterItems: masterItems,
      assessments: assessments,
      capas: capas,
      stats: stats,
      companyName: companyName,
      companyAddress: companyAddress,
      companyTaxId: companyTaxId,
      assessmentPeriod: assessmentPeriod,
      leadAssessorName: leadAssessorName,
    );

    final appDocDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final filename = 'SAFAPP_Legal_Compliance_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final targetPath = p.join(exportDir.path, filename);
    final file = File(targetPath);
    await file.writeAsBytes(bytes);

    return targetPath;
  }

  // --------------------------------------------------------------------------
  // Helper UI Builders
  // --------------------------------------------------------------------------

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4, bottom: 4),
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildMiniCounter(String label, int count, PdfColor textColor, PdfColor bgColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Row(
        children: [
          pw.Text('$label: ', style: pw.TextStyle(fontSize: 7, color: textColor)),
          pw.Text('$count', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    bool alignLeft = false,
    PdfColor? color,
    int flex = 1,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3.5),
      alignment: isHeader
          ? (alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center)
          : (alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center),
      child: pw.Text(
        text,
        textAlign: isHeader
            ? (alignLeft ? pw.TextAlign.left : pw.TextAlign.center)
            : (alignLeft ? pw.TextAlign.left : pw.TextAlign.center),
        style: pw.TextStyle(
          fontSize: isHeader ? 7.5 : 7,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.blue900 : PdfColors.black),
        ),
      ),
    );
  }
}
