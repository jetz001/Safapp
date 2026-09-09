import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/models/audit_models.dart';

class SafetyAuditPdfExporter {
  static Future<pw.ThemeData> _buildTheme() async {
    pw.Font? regular;
    pw.Font? bold;

    try {
      regular = await PdfGoogleFonts.sarabunRegular();
      bold = await PdfGoogleFonts.sarabunBold();
    } catch (_) {
      try {
        final regData = await rootBundle.load('google_fonts/Prompt-Regular.ttf');
        final boldData = await rootBundle.load('google_fonts/Prompt-Bold.ttf');
        regular = pw.Font.ttf(regData);
        bold = pw.Font.ttf(boldData);
      } catch (_) {}
    }

    if (regular != null && bold != null) {
      return pw.ThemeData.withFont(base: regular, bold: bold);
    }
    return pw.ThemeData.base();
  }

  static Future<String> _getExportDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }

  static Future<Uint8List> generateAuditReportPdfBytes({
    required AuditSession session,
    required List<AuditChecklistItem> items,
    required List<AuditFindingCapa> findings,
    String companyName = 'สถานประกอบกิจการ',
    String? employerName,
    String? safetyOfficerName,
  }) async {
    final doc = pw.Document(
      title: 'รายงานการตรวจประเมินระบบการจัดการความปลอดภัย - ${session.auditNo}',
      author: 'Safapp SMS 2565 Audit Engine',
    );

    final theme = await _buildTheme();

    // Group items by category
    final Map<String, List<AuditChecklistItem>> groupedItems = {};
    for (final item in items) {
      groupedItems.putIfAbsent(item.categoryTitle, () => []).add(item);
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.all(32),
        ),
        header: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 8),
            margin: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('แบบรายงานการตรวจประเมินระบบการจัดการด้านความปลอดภัย (SMS Audit Report)',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                pw.Text('เอกสารจัดเก็บตามกฎกระทรวงฯ พ.ศ. ๒๕๖๕ ข้อ ๘(๓)',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            margin: const pw.EdgeInsets.only(top: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('ระบบบริหารความปลอดภัย Safapp • บริษัท $companyName',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('หน้า ${context.pageNumber} จาก ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          );
        },
        build: (context) => [
          // 1. Header & Statutory Banner
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.blue300, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('รายงานผลการตรวจประเมินระบบการจัดการด้านความปลอดภัย',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: session.isCompleted ? PdfColors.green700 : PdfColors.orange700,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        session.isCompleted ? 'ตรวจประเมินเสร็จสมบูรณ์' : 'อยู่ระหว่างตรวจประเมิน',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'ตามกฎกระทรวง กำหนดมาตรฐานเกี่ยวกับระบบการจัดการด้านความปลอดภัย พ.ศ. ๒๕๖๕ (๕ องค์ประกอบหลัก & ๕๔ กิจการ)',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue800),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // 2. Audit Details Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                children: [
                  _buildMetaCell('เลขที่การตรวจ:', true),
                  _buildMetaCell(session.auditNo, false),
                  _buildMetaCell('วันที่ตรวจประเมิน:', true),
                  _buildMetaCell(session.auditDate, false),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildMetaCell('สถานประกอบการ:', true),
                  _buildMetaCell(companyName, false),
                  _buildMetaCell('หัวหน้าทีมผู้ตรวจ:', true),
                  _buildMetaCell(session.leadAuditor, false),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildMetaCell('ขอบเขตการตรวจ:', true),
                  _buildMetaCell(session.auditScope == 'INTEGRATED' ? 'SMS ๒๕๖๕ + บริบทโรงงาน' : 'SMS ๒๕๖๕ (๕ เสาหลัก)', false),
                  _buildMetaCell('ทีมผู้ตรวจร่วม:', true),
                  _buildMetaCell(session.auditorTeam ?? '-', false),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // 3. KPI Scorecards
          pw.Row(
            children: [
              _buildScorecard('ผลประเมินความสอดคล้อง', '${session.compliancePercentage}%', PdfColors.blue800, PdfColors.blue50),
              pw.SizedBox(width: 8),
              _buildScorecard('สอดคล้อง (Conform)', '${session.conformCount} ข้อ', PdfColors.green800, PdfColors.green50),
              pw.SizedBox(width: 8),
              _buildScorecard('ข้อบกพร่องเล็กน้อย (Minor)', '${session.minorNcCount} ข้อ', PdfColors.orange800, PdfColors.orange50),
              pw.SizedBox(width: 8),
              _buildScorecard('ข้อบกพร่องร้ายแรง (Major)', '${session.majorNcCount} ข้อ', PdfColors.red800, PdfColors.red50),
              pw.SizedBox(width: 8),
              _buildScorecard('ไม่เกี่ยวข้อง (N/A)', '${session.naCount} ข้อ', PdfColors.grey700, PdfColors.grey100),
            ],
          ),
          pw.SizedBox(height: 16),

          // 4. Checklist Items by Category
          pw.Text('รายละเอียดผลการตรวจประเมินแยกตามหมวดหมู่ (Checklist Findings)',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),

          ...groupedItems.entries.map((entry) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const pw.EdgeInsets.only(top: 8, bottom: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(entry.key, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                ),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(3.5),
                    2: const pw.FlexColumnWidth(3.5),
                    3: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _buildTableHeader('ข้อ'),
                        _buildTableHeader('ข้อกำหนดและกฎหมายอ้างอิง'),
                        _buildTableHeader('หลักฐานและบันทึกผู้ตรวจ'),
                        _buildTableHeader('ผลการตรวจ'),
                      ],
                    ),
                    ...entry.value.map((item) {
                      PdfColor statusColor = PdfColors.grey600;
                      String statusText = 'ยังไม่ตรวจ';
                      switch (item.resultStatus) {
                        case 'CONFORM':
                          statusColor = PdfColors.green700;
                          statusText = 'สอดคล้อง';
                          break;
                        case 'MINOR_NC':
                          statusColor = PdfColors.orange700;
                          statusText = 'Minor NC';
                          break;
                        case 'MAJOR_NC':
                          statusColor = PdfColors.red700;
                          statusText = 'Major NC';
                          break;
                        case 'NA':
                          statusColor = PdfColors.grey600;
                          statusText = 'N/A';
                          break;
                      }

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('${item.sortOrder}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(item.itemTitle, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                                pw.Text(item.requirementDescription, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                                pw.Text('อ้างอิง: ${item.legalReference}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.blue800)),
                              ],
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                if (item.evidenceSummary != null && item.evidenceSummary!.isNotEmpty)
                                  pw.Text('หลักฐาน: ${item.evidenceSummary}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.green900)),
                                if (item.auditorNotes != null && item.auditorNotes!.isNotEmpty)
                                  pw.Text('บันทึก: ${item.auditorNotes}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
                              ],
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              decoration: pw.BoxDecoration(
                                color: statusColor,
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                              child: pw.Text(
                                statusText,
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            );
          }),
          pw.SizedBox(height: 16),

          // 5. CAR / CAPA Findings Table
          if (findings.isNotEmpty) ...[
            pw.Text('รายการข้อบกพร่องและมาตรการแก้ไขป้องกัน (CAR / CAPA Action Plan)',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(3),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildTableHeader('เลขที่ CAR'),
                    _buildTableHeader('ระดับ'),
                    _buildTableHeader('ข้อบกพร่องที่พบ'),
                    _buildTableHeader('มาตรการแก้ไข / ป้องกัน'),
                    _buildTableHeader('ผู้รับผิดชอบ / กำหนดเสร็จ'),
                  ],
                ),
                ...findings.map((f) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(f.findingNo, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(f.findingType, style: const pw.TextStyle(fontSize: 8, color: PdfColors.red800)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(f.problemDescription, style: const pw.TextStyle(fontSize: 8)),
                            if (f.rootCause != null && f.rootCause!.isNotEmpty)
                              pw.Text('สาเหตุ: ${f.rootCause}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('แก้ไข: ${f.correctiveAction}', style: const pw.TextStyle(fontSize: 8)),
                            if (f.preventiveAction != null && f.preventiveAction!.isNotEmpty)
                              pw.Text('ป้องกัน: ${f.preventiveAction}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(f.responsiblePerson, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                            pw.Text('ภายใน: ${f.dueDate}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.blue800)),
                            pw.Text('สถานะ: ${f.status}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // 6. Statutory Signature Blocks (3 Blocks)
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'การรับรองผลการตรวจประเมินตามกฎกระทรวงระบบการจัดการด้านความปลอดภัย พ.ศ. ๒๕๖๕ ข้อ ๘(๓)',
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSignatureBox('ผู้ตรวจประเมินหลัก (Lead Auditor)', session.leadAuditor),
                    _buildSignatureBox('จป.วิชาชีพ ประจำโรงงาน', safetyOfficerName ?? '...................................................'),
                    _buildSignatureBox('นายจ้าง / ผู้มีอำนาจลงนาม', employerName ?? '...................................................'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildScorecard(String title, String value, PdfColor textColor, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: textColor, width: 0.5),
        ),
        child: pw.Column(
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 3),
            pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: textColor), textAlign: pw.TextAlign.center),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildMetaCell(String text, bool isHeader) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.grey800 : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
      ),
    );
  }

  static pw.Widget _buildSignatureBox(String role, String name) {
    return pw.Column(
      children: [
        pw.Text('ลงชื่อ .....................................................', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 4),
        pw.Text('($name)', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 2),
        pw.Text(role, style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text('วันที่ ........ / ........ / ................', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
      ],
    );
  }

  static Future<String> savePdfFile(Uint8List bytes, String fileName) async {
    final dir = await _getExportDirectory();
    final file = File(p.join(dir, fileName));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static Future<void> printOrPreviewPdf(Uint8List bytes, String title) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: title,
    );
  }
}
