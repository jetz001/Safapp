import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/models/contractor_models.dart';
import '../../risk_assessment/domain/models/risk_assessment_models.dart';

class SafetyViolationPdfService {
  /// สร้าง PDF หนังสือแจ้งเตือนการฝ่าฝืนกฎความปลอดภัย และสั่งพิมพ์ผ่าน Windows Print Dialog
  static Future<void> printViolationNotice({
    required BuildContext context,
    required ContractorViolation violation,
    CompanyProfile? companyProfile,
  }) async {
    try {
      final doc = pw.Document();

      final fontRegular = await PdfGoogleFonts.sarabunRegular();
      final fontBold = await PdfGoogleFonts.sarabunBold();
      final fontItalic = await PdfGoogleFonts.sarabunItalic();

      final theme = pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
        italic: fontItalic,
      );

      final orgName = (companyProfile?.companyName.isNotEmpty == true)
          ? companyProfile!.companyName
          : 'สถานประกอบกิจการ / แผนกความปลอดภัยและอาชีวอนามัย';

      final severityText = violation.severityLevel == 'CRITICAL'
          ? 'วิกฤต (Critical - ระงับการปฏิบัติงานทันที)'
          : violation.severityLevel == 'SEVERE'
              ? 'ร้ายแรง (Severe - สั่งหยุดงานชั่วคราว)'
              : violation.severityLevel == 'MODERATE'
                  ? 'ปานกลาง (Moderate - ออกใบเตือน & ตัดคะแนน)'
                  : 'เล็กน้อย (Minor - ตักเตือนและแก้ไขหน้างาน)';

      final docNo = 'SVN-${violation.incidentDate.replaceAll('-', '')}-${violation.id ?? 100}';

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 1. Header with Logo / Org info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          orgName,
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'หน่วยงานความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน (EHS Department)',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.red900, width: 1.5),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'เลขที่เอกสาร: $docNo',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                          ),
                          pw.Text(
                            'วันที่ออกเอกสาร: ${violation.incidentDate}',
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 1.5, color: PdfColors.blue900),
                pw.SizedBox(height: 10),

                // 2. Title
                pw.Center(
                  child: pw.Text(
                    'หนังสือแจ้งเตือนการฝ่าฝืนกฎระเบียบความปลอดภัยในการทำงาน',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    '(CONTRACTOR SAFETY VIOLATION & WARNING NOTICE)',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                  ),
                ),
                pw.SizedBox(height: 16),

                // 3. Contractor Information Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(text: 'บริษัทผู้รับเหมา: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  pw.TextSpan(text: violation.contractorName ?? '-', style: const pw.TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(text: 'คนงานผู้กระทำผิด: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  pw.TextSpan(text: violation.workerName ?? 'ไม่ระบุตัวบุคคล (ทั้งหน่วยงาน)', style: const pw.TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(text: 'วันที่ตรวจพบ: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  pw.TextSpan(text: violation.incidentDate, style: const pw.TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(text: 'ระดับความรุนแรง: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                                  pw.TextSpan(text: severityText, style: pw.TextStyle(fontSize: 10, color: PdfColors.red900, fontWeight: pw.FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),

                // 4. Violation Details
                _buildSectionHeader('๑. ประเภทการฝ่าฝืนและข้อกำหนดความปลอดภัย (Violation Category):'),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    '• ${violation.violationType}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                ),
                pw.SizedBox(height: 12),

                _buildSectionHeader('๒. พฤติกรรม / สภาพการทำงานที่ไม่ปลอดภัยที่ตรวจพบ (Description of Incident):'),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    violation.description,
                    style: const pw.TextStyle(fontSize: 9.5),
                  ),
                ),
                pw.SizedBox(height: 12),

                _buildSectionHeader('๓. มาตรการดำเนินการ / การลงโทษและการแก้ไข (Action Taken & Sanctions):'),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    border: pw.Border.all(color: PdfColors.red200),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'มาตรการบังคับใช้: ${violation.actionTaken}',
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                      ),
                      if (violation.scoreDeducted > 0) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'ตัดคะแนนประเมินความปลอดภัยของผู้รับเหมา: -${violation.scoreDeducted} คะแนน',
                          style: pw.TextStyle(fontSize: 9.5, color: PdfColors.red800, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),

                // 5. Caution Note
                pw.Text(
                  'หมายเหตุ: หากพบการกระทำผิดซ้ำ ทางสถานประกอบการขอสงวนสิทธิ์ในการสั่งระงับงานทันที หรือเพิกถอนสิทธิ์การเข้าปฏิบัติงาน (Blacklist)',
                  style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic),
                ),
                pw.Spacer(),

                // 6. Signatures Area
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // Inspector Signature
                    pw.Column(
                      children: [
                        pw.Text('ลงชื่อ.................................................................', style: const pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 4),
                        pw.Text('(${violation.inspectorName ?? "เจ้าหน้าที่ความปลอดภัย / ผู้ตรวจพบ"})', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('ผู้ตรวจพบการกระทำผิด / จป.วิชาชีพ', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),

                    // Contractor Acknowledgment
                    pw.Column(
                      children: [
                        pw.Text('ลงชื่อ.................................................................', style: const pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 4),
                        pw.Text('(.................................................................)', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('ผู้ควบคุมงาน / ตัวแทนผู้รับเหมา (ผู้รับทราบ)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],
            );
          },
        ),
      );

      // Trigger Windows / Native Print Preview
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'SafetyViolationNotice_$docNo',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการพิมพ์ใบตักเตือน: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
      ),
    );
  }
}
