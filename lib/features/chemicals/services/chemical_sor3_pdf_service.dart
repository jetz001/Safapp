import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/models/chemical_measurement_sor3_model.dart';

/// Official Statutory PDF Generator for Form สอ.๓ (พ.ศ. ๒๕๖๕)
/// Conforming to DLPW Notification on Atmospheric Measurement & Form สอ.๓ (No. 2) B.E. 2565.
class ChemicalSor3PdfService {
  /// Generates the complete multi-page PDF document as bytes.
  static Future<Uint8List> generatePdf(
    ChemicalMeasurementSor3Model item, {
    String? companyName,
    String? companyAddress,
    String? companyTaxId,
  }) async {
    final doc = pw.Document();

    final fontRegular = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();
    final fontItalic = await PdfGoogleFonts.sarabunItalic();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
    );

    final orgName = companyName ?? 'บริษัท โรงงานอุตสาหกรรมตัวอย่าง จำกัด';
    final fullAddress = companyAddress ?? 'นิคมอุตสาหกรรมอมตะซิตี้ ชลบุรี';
    final taxId = companyTaxId ?? '01055XXXXXXXX';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (pw.Context ctx) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'กรมสวัสดิการและคุ้มครองแรงงาน (ประกาศกรมฯ เรื่อง การตรวจวัดและแบบ สอ.๓ ฉบับที่ ๒ พ.ศ. ๒๕๖๕)',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.teal900, width: 1),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'แบบ สอ.๓ ๒๕๖๕',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
            ],
          );
        },
        footer: (pw.Context ctx) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('แบบ สอ.๓: รายงานผลการตรวจวัดบรรยากาศ เลขที่ ${item.documentNo}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('หน้าที่ ${ctx.pageNumber} จาก ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
        build: (pw.Context ctx) {
          final isSec9 = item.surveyorType == 'SECTION_9';

          return [
            // Title Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.teal300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'รายงานผลการตรวจวัดระดับความเข้มข้นของสารเคมีอันตรายในบรรยากาศ\nของสถานที่ทำงานและสถานที่เก็บรักษาสารเคมีอันตราย (แบบ สอ.๓)',
                    style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'เลขที่รายงาน: ${item.documentNo}  |  วันที่ทำการตรวจวัด: ${item.assessmentDate}',
                    style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // PART 1: Company Info
            _buildSectionHeader('ส่วนที่ ๑: ข้อมูลทั่วไปของสถานประกอบกิจการ'),
            _buildInfoRow('ชื่อสถานประกอบกิจการ', '$orgName  |  เลขนิติบุคคล: $taxId'),
            _buildInfoRow('ที่ตั้งสถานประกอบการ', fullAddress),
            pw.SizedBox(height: 6),

            // PART 2: Workplace Area & Process
            _buildSectionHeader('ส่วนที่ ๒: บริเวณที่ตรวจวัดและสภาพแวดล้อมการทำงาน'),
            _buildInfoRow('บริเวณ / แผนก / อาคาร', item.workplaceArea),
            _buildInfoRow('จุดตรวจวัดและลักษณะงาน', item.samplingPointDescription ?? 'จุดทำงานประจำของลูกจ้างในกระบวนการผลิต'),
            _buildInfoRow('สภาวะแวดล้อมขณะตรวจวัด', 'สภาพอากาศ: ${item.weatherCondition ?? "-"} | อุณหภูมิ: ${item.temperatureCelsius != null ? "${item.temperatureCelsius} °C" : "-"} | ความชื้นสัมพัทธ์: ${item.relativeHumidity != null ? "${item.relativeHumidity} %RH" : "-"}'),
            pw.SizedBox(height: 6),

            // PART 3: Chemical & Method
            _buildSectionHeader('ส่วนที่ ๓: สารเคมีที่ตรวจวัดและวิธีการเก็บตัวอย่าง / วิเคราะห์'),
            _buildInfoRow('ชื่อสารเคมีที่ตรวจวัด', '${item.chemicalName}  (CAS Number: ${item.casNumber})'),
            _buildInfoRow('ประเภทการตรวจวัด / ระยะเวลา', '${item.samplingType == "TWA_8HR" ? "เฉลี่ยตลอดเวลาการทำงาน (TWA 8 ชม.)" : item.samplingType == "STEL_15MIN" ? "ระยะสั้น (STEL 15 นาที)" : "เพดานสูงสุด (Ceiling)"} | ระยะเวลา: ${item.samplingDurationMinutes} นาที'),
            _buildInfoRow('วิธีการเก็บตัวอย่างและวิเคราะห์', item.samplingMethod),
            _buildInfoRow('ห้องปฏิบัติการตรวจวิเคราะห์', item.analysisLaboratory ?? 'ห้องปฏิบัติการที่ได้รับการรับรองมาตรฐานสากล ISO/IEC 17025'),
            _buildInfoRow('เจ้าหน้าที่เก็บตัวอย่าง / นักวิเคราะห์', '${item.samplingOfficerName ?? "-"} / ${item.analystName ?? "-"}'),
            pw.SizedBox(height: 6),

            // PART 4: Results & TLV Comparison Table
            _buildSectionHeader('ส่วนที่ ๔: ผลการตรวจวัดและเปรียบเทียบกับขีดจำกัดความเข้มข้นตามกฎหมาย (๓๒๔ รายการ)'),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal100),
                  children: [
                    _buildTableCell('จุดตรวจวัด / บริเวณ', isHeader: true, flex: 3),
                    _buildTableCell('สารเคมี (CAS)', isHeader: true, flex: 3),
                    _buildTableCell('เวลา (นาที)', isHeader: true, flex: 2),
                    _buildTableCell('ค่าที่วัดได้\n(${item.unit})', isHeader: true, flex: 2),
                    _buildTableCell('มาตรฐาน TLV\n(${item.unit})', isHeader: true, flex: 2),
                    _buildTableCell('สัดส่วน\n(% TLV)', isHeader: true, flex: 2),
                    _buildTableCell('ผลการประเมิน', isHeader: true, flex: 3),
                  ],
                ),
                if (item.samplingPoints.isNotEmpty)
                  ...item.samplingPoints.map((sp) {
                    final ratioStr = sp.tlvStandardValue > 0 ? '${((sp.measuredValue / sp.tlvStandardValue) * 100).toStringAsFixed(1)}%' : '-';
                    final evalLabel = sp.isPass ? 'ผ่านเกณฑ์ (ปกติ)' : sp.isActionLevel ? 'เฝ้าระวัง (>50%)' : 'เกินมาตรฐาน';
                    final evalColor = sp.isPass ? PdfColors.green900 : sp.isActionLevel ? PdfColors.amber900 : PdfColors.red900;

                    return pw.TableRow(
                      children: [
                        _buildTableCell('${sp.pointCode}: ${sp.workAreaName}', flex: 3),
                        _buildTableCell('${sp.chemicalName}\n(${sp.casNumber})', flex: 3),
                        _buildTableCell('${sp.samplingDurationMinutes}', flex: 2),
                        _buildTableCell('${sp.measuredValue}', flex: 2),
                        _buildTableCell('${sp.tlvStandardValue}', flex: 2),
                        _buildTableCell(ratioStr, flex: 2),
                        _buildTableCell(evalLabel, color: evalColor, flex: 3),
                      ],
                    );
                  })
                else
                  pw.TableRow(
                    children: [
                      _buildTableCell(item.workplaceArea, flex: 3),
                      _buildTableCell('${item.chemicalName}\n(${item.casNumber})', flex: 3),
                      _buildTableCell('${item.samplingDurationMinutes}', flex: 2),
                      _buildTableCell('${item.measuredValue}', flex: 2),
                      _buildTableCell('${item.tlvStandardValue}', flex: 2),
                      _buildTableCell('${item.ratioPercentage.toStringAsFixed(1)}%', flex: 2),
                      _buildTableCell(
                        item.isPass ? 'ผ่านเกณฑ์มาตรฐาน' : item.isActionLevel ? 'เฝ้าระวัง (>50%)' : 'เกินเกณฑ์มาตรฐาน',
                        color: item.isPass ? PdfColors.green900 : item.isActionLevel ? PdfColors.amber900 : PdfColors.red900,
                        flex: 3,
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 6),

            // PART 5: Certifier Information
            _buildSectionHeader('ส่วนที่ ๕: ผู้ตรวจวัดและรับรองผลการตรวจวัดที่ขึ้นทะเบียนกับกรมสวัสดิการและคุ้มครองแรงงาน'),
            pw.Row(
              children: [
                pw.Container(
                  width: 12,
                  height: 12,
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
                  child: isSec9 ? pw.Center(child: pw.Text('X', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))) : null,
                ),
                pw.SizedBox(width: 6),
                pw.Text('นิติบุคคลที่ขึ้นทะเบียนตามมาตรา ๙ แห่ง พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(width: 20),
                pw.Container(
                  width: 12,
                  height: 12,
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
                  child: !isSec9 ? pw.Center(child: pw.Text('X', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))) : null,
                ),
                pw.SizedBox(width: 6),
                pw.Text('บุคคลธรรมดาที่ขึ้นทะเบียนตามมาตรา ๑๑ แห่ง พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 4),
            if (isSec9) ...[
              _buildInfoRow('ชื่อนิติบุคคลผู้ตรวจวัด', item.serviceProviderName),
              _buildInfoRow('เลขทะเบียนใบสำคัญ (ตามมาตรา ๙)', item.serviceProviderM9RegNo ?? '-'),
            ] else ...[
              _buildInfoRow('ชื่อบุคคลผู้ตรวจวัด', item.serviceProviderName),
              _buildInfoRow('เลขทะเบียนใบสำคัญ (ตามมาตรา ๑๑)', item.serviceProviderM11CertNo ?? '-'),
              _buildInfoRow('คุณวุฒิ / สาขาวิชาชีพ', item.surveyorQualification ?? 'สุขศาสตร์อุตสาหกรรม'),
            ],
            pw.SizedBox(height: 6),

            // PART 6: Recommendations
            _buildSectionHeader('ส่วนที่ ๖: สรุปผลการตรวจวัด ข้อเสนอแนะและมาตรการปรับปรุงแก้ไข'),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Text(
                item.correctiveAction?.isNotEmpty == true
                    ? item.correctiveAction!
                    : 'ผลการตรวจวัดอยู่ในเกณฑ์มาตรฐานความปลอดภัยตามกฎหมาย ให้สถานประกอบกิจการดำเนินการบำรุงรักษาระบบระบายอากาศอย่างสม่ำเสมอ และตรวจวัดซ้ำตามรอบที่กฎหมายกำหนด',
                style: const pw.TextStyle(fontSize: 8.5),
              ),
            ),
            pw.SizedBox(height: 16),

            // Signatures block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  width: 220,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('ลงชื่อ .....................................................', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.SizedBox(height: 3),
                      pw.Text('( ${item.serviceProviderName} )', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text('ผู้ตรวจวัดขึ้นทะเบียน (มาตรา ${isSec9 ? "๙" : "๑๑"})', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.Text('เลขทะเบียน: ${isSec9 ? (item.serviceProviderM9RegNo ?? "-") : (item.serviceProviderM11CertNo ?? "-")}', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
                pw.Container(
                  width: 220,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('ลงชื่อ .....................................................', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.SizedBox(height: 3),
                      pw.Text('( ..................................................... )', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Text('เจ้าหน้าที่ความปลอดภัยในการทำงานระดับวิชาชีพ (จป.)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.Text('วันที่: ....... / ....... / .......', style: const pw.TextStyle(fontSize: 8)),
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

  /// Displays the interactive print preview and PDF exporter dialog.
  static Future<void> printOrShare(
    BuildContext context,
    ChemicalMeasurementSor3Model item, {
    String? companyName,
    String? companyAddress,
    String? companyTaxId,
  }) async {
    final bytes = await generatePdf(
      item,
      companyName: companyName,
      companyAddress: companyAddress,
      companyTaxId: companyTaxId,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Form_SorOr3_${item.documentNo.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf',
    );
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 3, bottom: 3),
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: const pw.BoxDecoration(
        color: PdfColors.teal100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 175,
            child: pw.Text('• $label:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
          ),
          pw.Expanded(
            child: pw.Text(value.isNotEmpty ? value : '-', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? color, int flex = 1}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3.5),
      alignment: isHeader ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.teal900 : PdfColors.black),
        ),
      ),
    );
  }
}
