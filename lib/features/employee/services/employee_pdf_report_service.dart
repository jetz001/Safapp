import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/models/employee_models.dart';

class EmployeePdfReportService {
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

  static Future<Uint8List> generateEmployeeSummaryReportPdf({
    required List<Employee> employees,
    String companyName = 'สถานประกอบกิจการ',
  }) async {
    final pdf = pw.Document(theme: await _buildTheme());

    final activeEmployees = employees.where((e) => e.status == 'ACTIVE').toList();
    final totalHours = employees.fold<double>(0.0, (sum, e) => sum + e.totalTrainingHours);
    final jorporCount = employees.where((e) => e.safetyRole.contains('SAFETY') || e.safetyRole == 'COMMITTEE_MEMBER').length;
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year + 543}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      companyName,
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'รายงานสรุปทะเบียนพนักงานและประวัติการฝึกอบรมความปลอดภัยในการทำงาน',
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
                    ),
                    pw.Text(
                      'ตาม พ.ร.บ. ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.blue300),
                      ),
                      child: pw.Text(
                        'แบบรายงานทะเบียนพนักงาน & OSH Training',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('พิมพ์เมื่อ: $dateStr', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.grey300, thickness: 1),
            pw.SizedBox(height: 6),
          ],
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Safapp - Safety & Occupational Health SuperApp', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              pw.Text('หน้า ${context.pageNumber} จาก ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ),
        build: (context) => [
          // KPI Summary Cards
          pw.Row(
            children: [
              _buildKpiCard('พนักงานทั้งหมด', '${employees.length} คน', PdfColors.blue50, PdfColors.blue800),
              pw.SizedBox(width: 8),
              _buildKpiCard('สถานะปฏิบัติงาน (Active)', '${activeEmployees.length} คน', PdfColors.green50, PdfColors.green800),
              pw.SizedBox(width: 8),
              _buildKpiCard('ชั่วโมงอบรมสะสมรวม', '${totalHours.toStringAsFixed(1)} ชม.', PdfColors.amber50, PdfColors.amber800),
              pw.SizedBox(width: 8),
              _buildKpiCard('จนท.ความปลอดภัย / คปอ.', '$jorporCount คน', PdfColors.purple50, PdfColors.purple800),
            ],
          ),
          pw.SizedBox(height: 14),

          // Employee Table
          pw.TableHelper.fromTextArray(
            headers: [
              'ลำดับ',
              'รหัสพนักงาน',
              'ชื่อ - นามสกุล',
              'แผนก / ฝ่าย',
              'ตำแหน่ง',
              'บทบาทด้าน OSH',
              'ชม.อบรม',
              'อบรมผ่าน',
              'สถานะ',
            ],
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            headerAlignment: pw.Alignment.center,
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            columnWidths: {
              0: const pw.FixedColumnWidth(28), // ลำดับ
              1: const pw.FixedColumnWidth(55), // รหัส
              2: const pw.FlexColumnWidth(2.2), // ชื่อ
              3: const pw.FlexColumnWidth(1.8), // แผนก
              4: const pw.FlexColumnWidth(1.8), // ตำแหน่ง
              5: const pw.FlexColumnWidth(2.0), // บทบาท
              6: const pw.FixedColumnWidth(45), // ชม.
              7: const pw.FixedColumnWidth(45), // อบรมผ่าน
              8: const pw.FixedColumnWidth(40), // สถานะ
            },
            data: List<List<String>>.generate(employees.length, (i) {
              final e = employees[i];
              return [
                '${i + 1}',
                e.employeeCode,
                e.fullName,
                e.department,
                e.position,
                e.safetyRoleLabel,
                '${e.totalTrainingHours.toStringAsFixed(1)} ชม.',
                '${e.validTrainingCount} รายการ',
                e.status == 'ACTIVE' ? 'ปฏิบัติงาน' : (e.status == 'RESIGNED' ? 'ลาออก' : 'ระงับ'),
              ];
            }),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildKpiCard(String label, String value, PdfColor bg, PdfColor text) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: text, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: text)),
          ],
        ),
      ),
    );
  }
}
