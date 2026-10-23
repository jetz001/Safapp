import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/widgets/safapp_print_preview.dart';
import '../domain/models/chemical_measurement_sor3_model.dart';

/// Official Statutory PDF Generator for Form สอ.๓
/// Strictly conforming to DLPW Notification on Atmospheric Measurement & Form สอ.๓ (No. 2) B.E. 2565
/// (แบบรายงานผลการตรวจวัดและวิเคราะห์ระดับความเข้มข้นของสารเคมีอันตรายในบรรยากาศฯ แบบ สอ.๓ ท้ายประกาศกรมสวัสดิการและคุ้มครองแรงงาน).
class ChemicalSor3PdfService {
  /// Opens print preview dialog for Form สอ.๓
  static Future<void> printOrShare(
    BuildContext context,
    ChemicalMeasurementSor3Model item, {
    String? companyName,
    String? companyAddress,
    String? companyTaxId,
  }) async {
    final bytes = await generatePdf(item, companyName: companyName, companyAddress: companyAddress, companyTaxId: companyTaxId);
    if (!context.mounted) return;
    await SafappPrintPreview.showBytes(
      context,
      title: 'รายงานผลการตรวจวัดสารเคมีอันตรายในบรรยากาศ (สอ.๓)',
      subtitle: '${item.chemicalName} • ${item.workplaceArea}',
      formCode: 'แบบ สอ.๓',
      fileName: 'Form_Sor3_${item.casNumber.replaceAll("-", "")}.pdf',
      pdfBytes: bytes,
      initialPageFormat: PdfPageFormat.a4.landscape,
    );
  }

  /// Generates the complete 2-page official statutory PDF conforming strictly to the gazette.
  static Future<Uint8List> generatePdf(
    ChemicalMeasurementSor3Model item, {
    String? companyName,
    String? companyAddress,
    String? companyTaxId,
  }) async {
    final doc = pw.Document();

    pw.Font fontRegular;
    pw.Font fontBold;
    pw.Font fontItalic;

    try {
      final regData = await rootBundle.load('google_fonts/Prompt-Regular.ttf');
      final boldData = await rootBundle.load('google_fonts/Prompt-Bold.ttf');
      final medData = await rootBundle.load('google_fonts/Prompt-Medium.ttf');
      fontRegular = pw.Font.ttf(regData);
      fontBold = pw.Font.ttf(boldData);
      fontItalic = pw.Font.ttf(medData);
    } catch (_) {
      try {
        fontRegular = await PdfGoogleFonts.sarabunRegular();
        fontBold = await PdfGoogleFonts.sarabunBold();
        fontItalic = await PdfGoogleFonts.sarabunItalic();
      } catch (_) {
        fontRegular = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
        fontItalic = pw.Font.helveticaOblique();
      }
    }

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
    );

    final orgName = companyName ?? 'บริษัท อุตสาหกรรมสยาม จำกัด (มหาชน)';
    final orgAddress = companyAddress ?? 'เลขที่ 88 หมู่ 3 นิคมอุตสาหกรรมบางปู ต.แพรกษา อ.เมือง จ.สมุทรปราการ 10280';
    final orgTaxId = companyTaxId ?? '0105556012345';
    final isSec9 = item.surveyorType == 'SECTION_9';
    final isSec11 = item.surveyorType == 'SECTION_11';
    final isEmployer = !isSec9 && !isSec11;

    // =========================================================================
    // PAGE 1: A4 LANDSCAPE - FORM สอ.๓
    // =========================================================================
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header: สอ.๓ on top right
              pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Text('สอ.๓', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 2),

              // Title
              pw.Center(
                child: pw.Text(
                  'รายงานผลการตรวจวัดและวิเคราะห์ระดับความเข้มข้นของสารเคมีอันตรายในบรรยากาศของสถานที่ทำงานและสถานที่เก็บรักษาสารเคมีอันตราย',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 6),

              // ๑. ข้อมูลสถานประกอบกิจการ
              pw.Row(
                children: [
                  _buildInlineDotted('๑. ชื่อสถานประกอบกิจการ', orgName, flex: 5),
                  pw.SizedBox(width: 8),
                  _buildInlineDotted('เลขทะเบียนนิติบุคคล', orgTaxId, flex: 3),
                  pw.SizedBox(width: 8),
                  _buildInlineDotted('ประเภทกิจการ', 'อุตสาหกรรมแปรรูปและการผลิต', flex: 3),
                ],
              ),
              _buildFullDotted('ตั้งอยู่', orgAddress),
              pw.Row(
                children: [
                  _buildInlineDotted('โทรศัพท์', '02-709-1234', flex: 3),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    flex: 8,
                    child: pw.Text(
                      'ได้ตรวจวัดและวิเคราะห์ระดับความเข้มข้นของสารเคมีอันตรายในบรรยากาศของสถานที่ทำงานและสถานที่เก็บรักษาสารเคมีอันตราย',
                      style: const pw.TextStyle(fontSize: 8.5),
                    ),
                  ),
                ],
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 14, top: 2, bottom: 2),
                child: pw.Row(
                  children: [
                    pw.Text('โดย  ', style: const pw.TextStyle(fontSize: 8.5)),
                    _buildRadioBox(isEmployer, 'นายจ้างดำเนินการ'),
                    pw.SizedBox(width: 14),
                    _buildRadioBox(isSec9, 'บุคคลที่ได้ขึ้นทะเบียนตามมาตรา ๙'),
                    pw.SizedBox(width: 14),
                    _buildRadioBox(isSec11, 'นิติบุคคลที่ได้รับอนุญาตตามมาตรา ๑๑'),
                  ],
                ),
              ),

              // ๒. ชื่อบุคคลผู้ให้บริการฯ
              pw.Row(
                children: [
                  _buildInlineDotted('๒. ชื่อบุคคลผู้ให้บริการฯ', isSec9 ? item.serviceProviderName : '-', flex: 5),
                  pw.SizedBox(width: 8),
                  _buildInlineDotted('ใบสำคัญเลขที่', isSec9 ? (item.serviceProviderM9RegNo ?? '-') : '-', flex: 3),
                  pw.SizedBox(width: 8),
                  _buildInlineDotted('ให้ไว้ ณ วันที่', isSec9 ? (item.surveyorValidTo ?? '-') : '-', flex: 3),
                ],
              ),

              // ๓. ชื่อนิติบุคคลผู้ให้บริการฯ
              pw.Text('๓. ชื่อนิติบุคคลผู้ให้บริการฯ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 14),
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        _buildInlineDotted('๓.๑ ชื่อผู้ให้บริการตรวจวัด', isSec11 ? item.serviceProviderName : '-', flex: 6),
                        pw.SizedBox(width: 8),
                        _buildInlineDotted('เลขทะเบียนนิติบุคคล', isSec11 ? (item.serviceProviderM11CertNo ?? '-') : '-', flex: 5),
                      ],
                    ),
                    pw.Row(
                      children: [
                        _buildInlineDotted('ใบอนุญาตเลขที่', isSec11 ? (item.serviceProviderM11CertNo ?? '-') : '-', flex: 4),
                        pw.SizedBox(width: 8),
                        _buildInlineDotted('ตั้งแต่วันที่', item.assessmentDate, flex: 3),
                        pw.SizedBox(width: 8),
                        _buildInlineDotted('ถึงวันที่', item.surveyorValidTo ?? '-', flex: 3),
                      ],
                    ),
                    pw.Row(
                      children: [
                        _buildInlineDotted('๓.๒ ชื่อผู้ให้บริการตรวจวิเคราะห์', item.analysisLaboratory ?? (isSec11 ? item.serviceProviderName : '-'), flex: 6),
                        pw.SizedBox(width: 8),
                        _buildInlineDotted('เลขทะเบียนนิติบุคคล', isSec11 ? (item.serviceProviderM11CertNo ?? '-') : '-', flex: 5),
                      ],
                    ),
                    pw.Row(
                      children: [
                        _buildInlineDotted('ใบอนุญาตเลขที่', isSec11 ? (item.serviceProviderM11CertNo ?? '-') : '-', flex: 4),
                        pw.SizedBox(width: 8),
                        _buildInlineDotted('ตั้งแต่วันที่', item.assessmentDate, flex: 3),
                        pw.SizedBox(width: 8),
                        _buildInlineDotted('ถึงวันที่', item.surveyorValidTo ?? '-', flex: 3),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),

              // ๔. ผลการตรวจวัดและวิเคราะห์ (ตาราง ๑๒ คอลัมน์)
              pw.Text('๔. ผลการตรวจวัดและวิเคราะห์ระดับความเข้มข้นของสารเคมีอันตราย มีรายละเอียดดังนี้', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              _buildResultsTable(item),
              pw.SizedBox(height: 4),

              // ๕. วิธีการตรวจวัดและมาตรฐาน
              _buildFullDotted(
                '๕. วิธีการตรวจวัดและการวิเคราะห์ทางห้องปฏิบัติการใช้มาตรฐานของ',
                '${item.samplingMethod} (Analytical: ${item.analysisLaboratory ?? "Standard Lab Protocol"})',
              ),
              pw.SizedBox(height: 6),

              // Bottom Signatures & Stamp Box (3 Columns)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Col 1: ผู้ตรวจวัดและรับรอง
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ตรวจวัดและรับรอง โดย', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        _buildRadioBox(isEmployer, 'นายจ้างดำเนินการ'),
                        _buildRadioBox(isSec9, 'บุคคลที่ได้ขึ้นทะเบียน'),
                        _buildRadioBox(isSec11, 'นิติบุคคลที่ได้รับใบอนุญาต'),
                        pw.SizedBox(height: 12),
                        pw.Text('ลงชื่อ..........................................................', style: const pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(height: 2),
                        pw.Text('( ${item.samplingOfficerName ?? "..........................................................."} )', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),

                  // Col 2: ผู้ตรวจวิเคราะห์และรับรอง
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ตรวจวิเคราะห์และรับรอง โดย', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        _buildRadioBox(isEmployer, 'นายจ้างดำเนินการ'),
                        _buildRadioBox(isSec9 || isSec11, 'นิติบุคคลที่ได้รับอนุญาต'),
                        pw.SizedBox(height: 20),
                        pw.Text('ลงชื่อ..........................................................', style: const pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(height: 2),
                        pw.Text('( ${item.analystName ?? "..........................................................."} )', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),

                  // Col 3: ตราประทับนิติบุคคล และนายจ้าง
                  pw.Expanded(
                    flex: 4,
                    child: pw.Row(
                      children: [
                        // Stamp Box
                        pw.Container(
                          width: 82,
                          height: 72,
                          alignment: pw.Alignment.center,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.black, width: 0.6),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Text('ประทับตรา\nนิติบุคคล', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.SizedBox(height: 14),
                              pw.Text('ลงชื่อ..........................................................', style: const pw.TextStyle(fontSize: 8)),
                              pw.SizedBox(height: 2),
                              pw.Text('(...............................................................)', style: const pw.TextStyle(fontSize: 8)),
                              pw.SizedBox(height: 2),
                              pw.Text('นายจ้าง/ผู้มีอำนาจกระทำการแทน', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // =========================================================================
    // PAGE 2: A4 LANDSCAPE - หมายเหตุ (STATUTORY FOOTNOTES)
    // =========================================================================
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('หมายเหตุ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              _buildFootnoteText('๑. กรณีนายจ้างดำเนินการตรวจวัดและวิเคราะห์ระดับความเข้มข้นของสารเคมีอันตรายเอง ให้แนบเอกสารหรือหลักฐานแสดงคุณสมบัติของผู้ดำเนินการตรวจวัดสารเคมีอันตราย และผู้ดำเนินการตรวจวิเคราะห์สารเคมีอันตรายทางห้องปฏิบัติการประจำสถานประกอบกิจการมาพร้อมเอกสาร สอ.๓'),
              _buildFootnoteText('๒. กรณีนายจ้างให้บุคคลที่ได้รับใบสำคัญตามมาตรา ๙ แห่งพระราชบัญญัติความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔ เป็นผู้ดำเนินการตรวจวัดระดับความเข้มข้นของสารเคมีอันตราย ให้แนบสำเนาใบสำคัญเป็นผู้ให้บริการตรวจวัดฯ มาพร้อมเอกสาร สอ.๓'),
              _buildFootnoteText('๓. กรณีนายจ้างให้นิติบุคคลที่ได้รับใบอนุญาตตามมาตรา ๑๑ แห่งพระราชบัญญัติความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔ เป็นผู้ดำเนินการตรวจวิเคราะห์ระดับความเข้มข้นของสารเคมีอันตราย ให้แนบสำเนาใบอนุญาตเป็นผู้ให้บริการตรวจวิเคราะห์ฯ มาพร้อมเอกสาร สอ.๓'),
              _buildFootnoteText('๔. กรณีนายจ้างให้นิติบุคคลที่ได้รับใบอนุญาตตามมาตรา ๑๑ เป็นผู้ดำเนินการตรวจวัดและวิเคราะห์ระดับความเข้มข้นของสารเคมีอันตราย ให้แนบสำเนาใบอนุญาตเป็นผู้ให้บริการตรวจวัดและวิเคราะห์ฯ มาพร้อมเอกสาร สอ.๓'),
              _buildFootnoteText('๕. เครื่องหมาย * หมายถึง หน่วย ลิตรต่อนาที'),
              _buildFootnoteText('    เครื่องหมาย ** หมายถึง นาทีหรือชั่วโมง'),
              _buildFootnoteText('    เครื่องหมาย *** หมายถึง mg/m3 หรือ μg/m3 หรือ f/cm3 หรือ mppcf หรือ ppm หรือ ppb'),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 18),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('mg/m3 = มิลลิกรัมต่ออากาศหนึ่งลูกบาศก์เมตร', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('μg/m3 = ไมโครกรัมต่ออากาศหนึ่งลูกบาศก์เมตร', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('f/cm3 = จำนวนเส้นใยต่ออากาศหนึ่งลูกบาศก์เซนติเมตร', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('mppcf = จำนวนล้านอนุภาคต่อปริมาตรของอากาศหนึ่งลูกบาศก์ฟุต', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('ppm   = ส่วนในล้านส่วนโดยปริมาตร', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('ppb   = ส่วนในพันล้านส่วนโดยปริมาตร', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
              _buildFootnoteText('๖. กรณีเป็นนิติบุคคลที่หนังสือรับรองนิติบุคคลระบุให้ประทับตราจะต้องมีตราประทับพร้อมลงนาม'),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // =========================================================================
  // STATUTORY FORMATTING HELPERS
  // =========================================================================
  static pw.Widget _buildFullDotted(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('$label ', style: const pw.TextStyle(fontSize: 8.5)),
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.5, style: pw.BorderStyle.dotted),
                ),
              ),
              child: pw.Text(
                value.isNotEmpty && value != '-' ? value : ' ',
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInlineDotted(String label, String value, {int flex = 1}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('$label ', style: const pw.TextStyle(fontSize: 8.5)),
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.5, style: pw.BorderStyle.dotted),
                ),
              ),
              child: pw.Text(
                value.isNotEmpty && value != '-' ? value : ' ',
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRadioBox(bool isSelected, String label) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 8,
          height: 8,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: PdfColors.black, width: 0.8),
            color: isSelected ? PdfColors.black : PdfColors.white,
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  static pw.Widget _buildFootnoteText(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
    );
  }

  /// Official 12-Column Table according to Form สอ.๓
  static pw.Widget _buildResultsTable(ChemicalMeasurementSor3Model item) {
    final points = item.samplingPoints;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(11), // ชื่อสาร
        1: pw.FlexColumnWidth(9),  // วันที่เริ่ม-สิ้นสุด
        2: pw.FlexColumnWidth(10), // จุดที่เก็บ
        3: pw.FlexColumnWidth(8),  // จำนวนลูกจ้าง
        4: pw.FlexColumnWidth(10), // ชื่อเครื่องมือเก็บ
        5: pw.FlexColumnWidth(7),  // อัตราดูดอากาศ *
        6: pw.FlexColumnWidth(7),  // ระยะเวลาที่เก็บ **
        7: pw.FlexColumnWidth(8),  // วันที่วิเคราะห์
        8: pw.FlexColumnWidth(9),  // ชื่อเครื่องมือวิเคราะห์
        9: pw.FlexColumnWidth(8),  // ระดับความเข้มข้นที่ได้ ***
        10: pw.FlexColumnWidth(8), // ขีดจำกัด TLV ***
        11: pw.FlexColumnWidth(7), // การประเมินผล
      },
      children: [
        // Official Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            _buildThCell('ชื่อสาร'),
            _buildThCell('วันที่เริ่ม – สิ้นสุด\nการเก็บตัวอย่าง'),
            _buildThCell('จุดที่เก็บ\nตัวอย่าง'),
            _buildThCell('จำนวน\nลูกจ้าง\nที่สัมผัสหรือ\nเกี่ยวข้องกับ\nสารเคมี\nอันตราย'),
            _buildThCell('ชื่อเครื่องมือ\nและวัสดุ\nอุปกรณ์ที่ใช้\nเก็บตัวอย่าง'),
            _buildThCell('อัตรา\nดูดอากาศ *'),
            _buildThCell('ระยะเวลาที่\nเก็บตัวอย่าง **'),
            _buildThCell('วันที่วิเคราะห์'),
            _buildThCell('ชื่อเครื่องมือ\nวิเคราะห์'),
            _buildThCell('ระดับ\nความเข้มข้นที่\nวิเคราะห์ได้ ***'),
            _buildThCell('ขีดจำกัด\nความเข้มข้น\n(TLV s) ***'),
            _buildThCell('การ\nประเมินผล\n(เกิน/\nไม่เกิน)'),
          ],
        ),

        // Data Rows
        if (points.isNotEmpty)
          ...points.map((p) {
            final isFail = p.evaluationResult == 'FAIL';
            return pw.TableRow(
              children: [
                _buildTdCell(p.chemicalName.isNotEmpty ? p.chemicalName : item.chemicalName),
                _buildTdCell(item.assessmentDate),
                _buildTdCell('${p.pointCode}\n${p.workAreaName}'),
                _buildTdCell('${p.exposedWorkersCount} คน'),
                _buildTdCell(p.samplingMethod ?? 'Air Sampler Pump'),
                _buildTdCell(p.airVolumeLiters != null ? '${p.airVolumeLiters}' : '2.0 ล./น.'),
                _buildTdCell('${p.samplingDurationMinutes} นาที'),
                _buildTdCell(item.assessmentDate),
                _buildTdCell(p.analyticalMethod ?? 'GC-FID / Spectro'),
                _buildTdCell('${p.measuredValue} ${p.unit}'),
                _buildTdCell('${p.tlvStandardValue} ${p.unit}'),
                _buildTdCell(isFail ? 'เกิน' : 'ไม่เกิน', isBold: true),
              ],
            );
          })
        else
          pw.TableRow(
            children: [
              _buildTdCell(item.chemicalName),
              _buildTdCell(item.assessmentDate),
              _buildTdCell('${item.workplaceArea}\n${item.samplingPointDescription ?? ""}'),
              _buildTdCell('5 คน'),
              _buildTdCell(item.samplingMethod),
              _buildTdCell('2.0 ล./น.'),
              _buildTdCell('${item.samplingDurationMinutes} นาที'),
              _buildTdCell(item.assessmentDate),
              _buildTdCell(item.analysisLaboratory ?? 'GC-FID'),
              _buildTdCell('${item.measuredValue} ${item.unit}'),
              _buildTdCell('${item.tlvStandardValue} ${item.unit}'),
              _buildTdCell(item.evaluationResult == 'FAIL' ? 'เกิน' : 'ไม่เกิน', isBold: true),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildThCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTdCell(String text, {bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 6.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
