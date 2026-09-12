import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/models/health_models.dart';
import '../../risk_assessment/domain/models/risk_assessment_models.dart';
import '../../employee/domain/models/employee_models.dart';

class HealthOfficialPdfService {
  // ==========================================================================
  // 1. แบบ จผส. ๑ (แบบแจ้งผลตรวจสุขภาพผิดปกติ ส่งพนักงานตรวจความปลอดภัย)
  // ==========================================================================
  static Future<void> printJorPhorSor1Report({
    required BuildContext context,
    required List<EmployeeHealthRecord> abnormalRecords,
    required List<MedicalSurveillanceFollowup> followups,
    CompanyProfile? company,
    String? checkupYear,
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

      final orgName = (company?.companyName.isNotEmpty == true) ? company!.companyName : 'สถานประกอบกิจการ';
      final fullAddress = _formatCompanyAddress(company);
      final taxId = company?.taxId ?? '01055XXXXXXXX';
      final now = DateTime.now();
      final year = checkupYear ?? '${now.year + 543}';

      // Group by department
      final Map<String, List<EmployeeHealthRecord>> deptMap = {};
      for (final r in abnormalRecords) {
        final d = r.department ?? 'ฝ่ายผลิตหลัก';
        deptMap.putIfAbsent(d, () => []).add(r);
      }

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
                    pw.Text('กรมสวัสดิการและคุ้มครองแรงงาน (กฎกระทรวงตรวจสุขภาพตามปัจจัยเสี่ยง พ.ศ. ๒๕๖๓)', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue900, width: 1), borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Text('แบบ จผส. ๑', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    ),
                  ],
                ),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 4),
              ],
            );
          },
          build: (pw.Context ctx) {
            final tableRows = <List<String>>[];
            int deptIndex = 1;

            deptMap.forEach((dept, records) {
              final riskSummary = records.expand((r) => r.riskFactorsTested).toSet().join(', ');
              final treatedSummary = followups.where((f) => records.any((r) => r.id == f.healthRecordId)).map((f) => '• ${f.actionDetails}').join('\n');

              tableRows.add([
                '$deptIndex. $dept',
                riskSummary.isNotEmpty ? riskSummary : 'สารเคมี/เสียงดัง/ฝุ่น',
                '${records.length}',
                '0',
                '${records.length}',
                treatedSummary.isNotEmpty ? treatedSummary : 'ส่งตรวจซ้ำและพบแพทย์อาชีวเวชศาสตร์',
                'ตรวจวัดสภาพแวดล้อมและบำรุงรักษาเครื่องจักร',
                'กวดขันการสวมใส่ PPE และปรับปรุงเวลาทำงาน',
              ]);
              deptIndex++;
            });

            return [
              pw.Container(
                width: double.infinity,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'แบบแจ้งผลการตรวจสุขภาพของลูกจ้างที่ผิดปกติหรือที่มีอาการหรือเจ็บป่วยเนื่องจากการทำงาน\nการให้การรักษาพยาบาล และการป้องกันแก้ไข',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text('ประจำปี พ.ศ. $year', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              _buildInfoRow('๑. ข้าพเจ้า / ผู้มีอำนาจ', company?.employerName ?? 'ผู้รับมอบอำนาจทำการแทนนายจ้าง'),
              _buildInfoRow('๒. ชื่อสถานประกอบกิจการ', '$orgName  |  เลขนิติบุคคล: $taxId'),
              _buildInfoRow('ที่ตั้งสถานประกอบการ', '$fullAddress  |  โทรศัพท์: ${company?.phone ?? "-"}'),
              _buildInfoRow('๓. การตรวจสุขภาพตามปัจจัยเสี่ยง', '[X] ตรวจสุขภาพประจำปี  [X] ตรวจเฝ้าระวังทางการแพทย์'),
              pw.SizedBox(height: 6),

              pw.Text('๖. ผลการตรวจสุขภาพของลูกจ้างที่ผิดปกติ และการดำเนินการแก้ไขป้องกัน:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.SizedBox(height: 4),

              if (tableRows.isEmpty)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Center(child: pw.Text('ไม่พบผลการตรวจสุขภาพที่ผิดปกติในรอบปีนี้', style: const pw.TextStyle(fontSize: 9.5))),
                )
              else
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  headerStyle: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  cellStyle: const pw.TextStyle(fontSize: 7),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.2),
                    1: const pw.FlexColumnWidth(1.4),
                    2: const pw.FlexColumnWidth(0.7),
                    3: const pw.FlexColumnWidth(0.6),
                    4: const pw.FlexColumnWidth(0.6),
                    5: const pw.FlexColumnWidth(1.6),
                    6: const pw.FlexColumnWidth(1.5),
                    7: const pw.FlexColumnWidth(1.5),
                  },
                  headers: <String>[
                    'แผนก',
                    'งานเกี่ยวกับ\nปัจจัยเสี่ยง',
                    'ตรวจ\n(คน)',
                    'ปกติ',
                    'ผิดปกติ',
                    'การให้การรักษา / ส่งตรวจซ้ำ',
                    'การแก้ไขสภาพแวดล้อม',
                    'การป้องกันที่ตัวลูกจ้าง',
                  ],
                  data: tableRows,
                ),
              pw.SizedBox(height: 8),

              pw.Text(
                'หมายเหตุ: ๑. งานเกี่ยวกับปัจจัยเสี่ยงตามกฎกระทรวง พ.ศ. ๒๕๖๓  ๒. การให้การรักษา เช่น ส่งตรวจสุขภาพซ้ำ, ส่งรักษา  ๓. การแก้ไขสภาพแวดล้อม เช่น ปรับปรุงเครื่องจักร  ๔. การป้องกันที่ตัวลูกจ้าง เช่น สวมใส่ PPE, ปรับเปลี่ยนงาน',
                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 12),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('วันที่รายงาน: ${now.day}/${now.month}/${now.year + 543}', style: const pw.TextStyle(fontSize: 8)),
                  pw.Column(
                    children: [
                      pw.Text('ลงชื่อ.................................................................', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.SizedBox(height: 2),
                      pw.Text('(.................................................................)', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('นายจ้าง / ผู้มีอำนาจกระทำการแทน', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) => doc.save(),
        name: 'JorPhorSor1_Report_$year',
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการพิมพ์แบบ จผส. ๑: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==========================================================================
  // 2. สมุดสุขภาพประจำตัวของลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง (Electronic Health Book)
  // ==========================================================================
  static Future<void> printElectronicHealthBook({
    required BuildContext context,
    required Employee employee,
    required List<EmployeeHealthRecord> healthRecords,
    CompanyProfile? company,
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

      final orgName = (company?.companyName.isNotEmpty == true) ? company!.companyName : 'สถานประกอบกิจการ';
      final fullAddress = _formatCompanyAddress(company);

      // Load worker photo if available
      pw.MemoryImage? employeePhoto;
      if (employee.photoPath != null && employee.photoPath!.isNotEmpty) {
        try {
          final file = File(employee.photoPath!);
          if (file.existsSync()) {
            final bytes = file.readAsBytesSync();
            employeePhoto = pw.MemoryImage(bytes);
          }
        } catch (_) {}
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 20),
          header: (pw.Context ctx) {
            return pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 6),
              margin: const pw.EdgeInsets.only(bottom: 6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue900, width: 1.5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue900,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Text(
                          'SAFAPP EHS',
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'กระทรวงแรงงาน • กรมสวัสดิการและคุ้มครองแรงงาน (กฎกระทรวงตรวจสุขภาพฯ พ.ศ. ๒๕๖๓)',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      border: pw.Border.all(color: PdfColors.blue300, width: 0.8),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Text('รหัสพนักงาน: ', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                        pw.Text(
                          employee.employeeCode,
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          footer: (pw.Context ctx) {
            return pw.Container(
              padding: const pw.EdgeInsets.only(top: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'สมุดสุขภาพประจำตัวของลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง (Electronic Health Book)',
                    style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'หน้า ${ctx.pageNumber} จาก ${ctx.pagesCount}',
                    style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                  ),
                ],
              ),
            );
          },
          build: (pw.Context ctx) {
            return [
              // ==============================================================
              // COVER TITLE BANNER
              // ==============================================================
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'สมุดสุขภาพประจำตัวของลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง',
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 1.5),
                    pw.Text(
                      '(ตามกฎกระทรวงกำหนดมาตรฐานการตรวจสุขภาพลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง พ.ศ. ๒๕๖๓)',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'ออกตามความในพระราชบัญญัติความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔',
                      style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey600),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // ==============================================================
              // SECTION 1: PERSONAL & WORKPLACE PROFILE
              // ==============================================================
              _buildModernSectionHeader('ส่วนที่ ๑: ข้อมูลประวัติส่วนตัวและประวัติการทำงาน', 'Personal & Employment Profile'),
              _buildPersonalInfoCard(
                employee: employee,
                orgName: orgName,
                fullAddress: fullAddress,
                company: company,
                photo: employeePhoto,
              ),
              pw.SizedBox(height: 8),

              // ==============================================================
              // SECTION 2: HEALTH & SURVEILLANCE CHECKUPS
              // ==============================================================
              _buildModernSectionHeader('ส่วนที่ ๒: ประวัติการตรวจสุขภาพและการตรวจตามปัจจัยเสี่ยง', 'Occupational Health & Surveillance Records'),
              if (healthRecords.isEmpty)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Center(
                    child: pw.Text('ยังไม่มีประวัติการบันทึกตรวจสุขภาพในระบบ', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                  ),
                )
              else
                ...healthRecords.map((r) => _buildHealthRecordCard(r)),

              pw.SizedBox(height: 8),

              // ==============================================================
              // SECTION 3: SIGNATURES & CERTIFICATION
              // ==============================================================
              _buildModernSectionHeader('ส่วนที่ ๓: การรับรองสมุดสุขภาพ', 'Certification & Endorsement'),
              pw.SizedBox(height: 4),
              _buildSignatureBoxes(employee),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) => doc.save(),
        name: 'HealthBook_${employee.employeeCode}',
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการพิมพ์สมุดสุขภาพ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==========================================================================
  // 3. ใบสรุปผลการตรวจสุขภาพรายบุคคล (Individual Health Summary Certificate)
  // ==========================================================================
  static Future<void> printHealthSummaryCertificate({
    required BuildContext context,
    required EmployeeHealthRecord record,
    CompanyProfile? company,
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

      final orgName = (company?.companyName.isNotEmpty == true) ? company!.companyName : 'สถานประกอบกิจการ';
      final formattedCheckupDate = formatThaiDate(record.checkupDate);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 20),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Banner Header
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue900, width: 1.5)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.blue900,
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                            child: pw.Text(
                              'ฝ่ายอาชีวอนามัยและความปลอดภัย',
                              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            orgName,
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          border: pw.Border.all(color: PdfColors.blue300, width: 0.8),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Text('วันที่ตรวจ: ', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                            pw.Text(
                              formattedCheckupDate,
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Title
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'ใบสรุปผลการตรวจสุขภาพและประเมินความพร้อมในการทำงาน',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 1.5),
                      pw.Text(
                        'OCCUPATIONAL HEALTH & FITNESS FOR DUTY CERTIFICATE',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        '(ออกตามข้อกำหนดมาตรฐานการตรวจสุขภาพลูกจ้างตามกฎกระทรวง พ.ศ. ๒๕๖๓)',
                        style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey600),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // 1. Employee Profile Card
                _buildModernSectionHeader('ข้อมูลผู้รับการตรวจสุขภาพ', 'Employee & Workplace Profile'),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildModernInfoRow('ชื่อ - นามสกุล', '${record.employeeName ?? "-"} (รหัส: ${record.employeeCode ?? "-"})', isBold: true),
                            pw.SizedBox(height: 2),
                            _buildModernInfoRow('สังกัดแผนก / ตำแหน่ง', '${record.department ?? "-"} / ${record.position ?? "-"}'),
                            pw.SizedBox(height: 2),
                            _buildModernInfoRow('เลขประจำตัวประชาชน', formatNationalId(record.nationalId)),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildModernInfoRow('สถานประกอบการ', orgName, isBold: true),
                            pw.SizedBox(height: 2),
                            _buildModernInfoRow('ประเภทการตรวจ', record.checkupTypeLabel),
                            pw.SizedBox(height: 2),
                            _buildModernInfoRow('หน่วยบริการตรวจสุขภาพ', record.hospitalName),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 7),

                // 2. Physical & Vitals
                _buildModernSectionHeader('ผลการตรวจร่างกายและสัญญาณชีพ', 'Physical Examination & Vital Signs'),
                pw.Row(
                  children: [
                    _buildMetricPill('น้ำหนัก', '${record.weight ?? "-"} กก.', null),
                    pw.SizedBox(width: 4),
                    _buildMetricPill('ส่วนสูง', '${record.height ?? "-"} ซม.', null),
                    pw.SizedBox(width: 4),
                    _buildMetricPill('BMI', record.bmi?.toStringAsFixed(1) ?? '-', interpretBmi(record.bmi)),
                    pw.SizedBox(width: 4),
                    _buildMetricPill('ความดัน (BP)', record.bpReading, interpretBp(record.bpSystolic, record.bpDiastolic)),
                    pw.SizedBox(width: 4),
                    _buildMetricPill('ชีพจร (Pulse)', '${record.pulse ?? "-"} bpm', record.pulse != null ? 'ครั้ง/นาที' : null),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: record.physicalExamResult == 'NORMAL' ? PdfColors.green50 : PdfColors.amber50,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(
                      color: record.physicalExamResult == 'NORMAL' ? PdfColors.green200 : PdfColors.amber300,
                      width: 0.5,
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text('การตรวจร่างกายทั่วไป: ', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text(
                        record.physicalExamResult == 'NORMAL' ? 'ปกติ สมบูรณ์ดี' : 'พบความผิดปกติ (${record.physicalExamNotes ?? "-"})',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          color: record.physicalExamResult == 'NORMAL' ? PdfColors.green900 : PdfColors.amber900,
                          fontWeight: record.physicalExamResult == 'NORMAL' ? pw.FontWeight.normal : pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 7),

                // 3. Lab & Diagnostics Table
                _buildModernSectionHeader('ผลการตรวจทางห้องปฏิบัติการและเครื่องมือพิเศษ', 'Laboratory & Diagnostic Examinations'),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1.4),
                      1: const pw.FlexColumnWidth(1.2),
                      2: const pw.FlexColumnWidth(1.4),
                      3: const pw.FlexColumnWidth(1.2),
                    },
                    children: [
                      _buildLabTableRow(
                        'เอกซเรย์ปอด (Chest X-Ray)', record.chestXrayResult,
                        'ตรวจการได้ยิน (Audiogram)', record.audiogramResult,
                        isHeader: false, isEven: true,
                      ),
                      _buildLabTableRow(
                        'สมรรถภาพปอด (Spirometry)', record.spirometryResult,
                        'การมองเห็น/สายตา (Vision)', record.visionTestResult,
                        isHeader: false, isEven: false,
                      ),
                      _buildLabTableRow(
                        'ความสมบูรณ์เม็ดเลือด (CBC)', record.bloodCbcResult,
                        'ระดับน้ำตาลในเลือด (FBS)', record.bloodSugarResult,
                        isHeader: false, isEven: true,
                      ),
                      _buildLabTableRow(
                        'การทำงานของตับ (Liver)', record.liverFunctionResult,
                        'การทำงานของไต (Kidney)', record.kidneyFunctionResult,
                        isHeader: false, isEven: false,
                      ),
                      _buildLabTableRow(
                        'ตรวจปัสสาวะ (Urine Exam)', record.urineExamResult,
                        'สารเสพติด (Drug Screen)', record.drugScreeningResult,
                        isHeader: false, isEven: true,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 7),

                // 4. Doctor Conclusion & Fitness Box
                _buildModernSectionHeader('สรุปผลการตรวจและความเห็นทางการแพทย์', 'Medical Assessment & Fitness for Duty'),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: record.overallResult == 'NORMAL' ? PdfColors.green50 : (record.overallResult == 'WATCH' ? PdfColors.amber50 : PdfColors.red50),
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(
                      color: record.overallResult == 'NORMAL' ? PdfColors.green300 : (record.overallResult == 'WATCH' ? PdfColors.amber300 : PdfColors.red300),
                      width: 0.8,
                    ),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 7,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                pw.Text('ผลตรวจสุขภาพภาพรวม: ', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                                pw.Text(
                                  record.overallResultPlainLabel,
                                  style: pw.TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: record.overallResult == 'NORMAL' ? PdfColors.green900 : (record.overallResult == 'WATCH' ? PdfColors.amber900 : PdfColors.red900),
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text('คำแนะนำของแพทย์ / Doctor\'s Recommendation:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                            pw.Text(
                              (record.doctorOpinion != null && record.doctorOpinion!.isNotEmpty)
                                  ? record.doctorOpinion!
                                  : (record.overallResult == 'NORMAL' ? 'ผลตรวจร่างกายทั่วไปอยู่ในเกณฑ์ปกติ สุขภาพแข็งแรงดี ปฏิบัติงานได้ตามปกติ' : 'ควรเฝ้าระวังและปฏิบัติตามคำแนะนำของแพทย์อย่างต่อเนื่อง'),
                              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.blueGrey800),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        flex: 5,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('ความพร้อมในการปฏิบัติงาน:', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                            pw.SizedBox(height: 2),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: pw.BoxDecoration(
                                color: record.fitnessToWork == 'FIT'
                                    ? PdfColors.green100
                                    : (record.fitnessToWork == 'FIT_WITH_RESTRICTION' ? PdfColors.amber100 : PdfColors.red100),
                                borderRadius: pw.BorderRadius.circular(4),
                                border: pw.Border.all(
                                  color: record.fitnessToWork == 'FIT'
                                      ? PdfColors.green700
                                      : (record.fitnessToWork == 'FIT_WITH_RESTRICTION' ? PdfColors.amber700 : PdfColors.red700),
                                  width: 0.6,
                                ),
                              ),
                              child: pw.Text(
                                record.fitnessLabel,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: record.fitnessToWork == 'FIT'
                                      ? PdfColors.green900
                                      : (record.fitnessToWork == 'FIT_WITH_RESTRICTION' ? PdfColors.amber900 : PdfColors.red900),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),

                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('หน่วยงานตรวจสุขภาพ: ${record.hospitalName}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
                        pw.Text('แพทย์ผู้ทำการตรวจ: ${record.doctorName ?? "แพทย์อาชีวเวชศาสตร์"}', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                        pw.Text('เลขที่ใบประกอบวิชาชีพเวชกรรม: ${record.doctorLicenseNo ?? "ว.XXXXX"}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('ลงชื่อ.................................................................', style: const pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(height: 2),
                        pw.Text('( ${record.doctorName ?? "................................................................."} )', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text('แพทย์ผู้ตรวจ / ประทับตราสถานพยาบาล', style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey700)),
                        pw.SizedBox(height: 1),
                        pw.Text('วันที่ .......... / .......... / ..............', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) => doc.save(),
        name: 'HealthSummary_${record.employeeCode}_${record.checkupDate}',
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการพิมพ์ใบสรุปผลตรวจสุขภาพ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==========================================================================
  // SHARED UI HELPERS & FORMATTERS
  // ==========================================================================

  /// จัดการแปลงวันที่ให้อ่านง่ายเป็นภาษาไทย เช่น "14 ธันวาคม 2567"
  static String formatThaiDate(String? rawDate, {bool short = false}) {
    if (rawDate == null || rawDate.isEmpty || rawDate == '-') return '-';
    try {
      DateTime dt;
      if (rawDate.contains('T')) {
        dt = DateTime.parse(rawDate).toLocal();
      } else if (rawDate.contains('-')) {
        final parts = rawDate.trim().split('-');
        if (parts.length == 3) {
          int year = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int day = int.parse(parts[2].split(' ')[0]);
          if (year > 2400) year -= 543;
          dt = DateTime(year, month, day);
        } else {
          return rawDate.replaceAll(RegExp(r'T[\d:.]+(Z)?'), '');
        }
      } else if (rawDate.contains('/')) {
        final parts = rawDate.trim().split('/');
        if (parts.length == 3) {
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2].split(' ')[0]);
          if (year > 2400) year -= 543;
          dt = DateTime(year, month, day);
        } else {
          return rawDate;
        }
      } else {
        return rawDate;
      }

      final thaiYear = dt.year > 2400 ? dt.year : dt.year + 543;
      const thaiMonthsLong = [
        '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
        'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
      ];
      const thaiMonthsShort = [
        '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
        'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
      ];

      final mName = short ? thaiMonthsShort[dt.month] : thaiMonthsLong[dt.month];
      return '${dt.day} $mName $thaiYear';
    } catch (_) {
      return rawDate.replaceAll(RegExp(r'T[\d:.]+(Z)?'), '');
    }
  }

  /// จัดการแปลงเลขบัตรประชาชน 13 หลักให้มีขีดคั่น: x-xxxx-xxxxx-xx-x
  static String formatNationalId(String? id) {
    if (id == null || id.isEmpty || id == '-') return '-';
    final clean = id.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 13) {
      return '${clean[0]}-${clean.substring(1, 5)}-${clean.substring(5, 10)}-${clean.substring(10, 12)}-${clean[12]}';
    }
    return id;
  }

  /// แปลผลตรวจแล็บเป็นภาษาไทยให้อ่านง่าย
  static String translateLabResult(String? res) {
    if (res == null || res.isEmpty || res == 'NOT_TESTED') return 'ไม่ได้ตรวจ';
    if (res == 'NORMAL') return 'ปกติ (Normal)';
    if (res == 'ABNORMAL') return 'ผิดปกติ (Abnormal)';
    if (res == 'WATCH') return 'เฝ้าระวัง (Watch)';
    if (res == 'NEGATIVE') return 'ไม่พบสารเสพติด (Negative)';
    if (res == 'POSITIVE') return 'ตรวจพบสารเสพติด (Positive)';
    return res;
  }

  /// แปลผล BMI
  static String interpretBmi(double? bmi) {
    if (bmi == null) return '';
    if (bmi < 18.5) return 'น้ำหนักน้อย/ผอม';
    if (bmi < 23.0) return 'น้ำหนักปกติ';
    if (bmi < 25.0) return 'น้ำหนักเกิน/ท้วม';
    if (bmi < 30.0) return 'อ้วนระดับ 1';
    return 'อ้วนระดับ 2';
  }

  /// แปลผลความดันโลหิต
  static String interpretBp(int? sys, int? dia) {
    if (sys == null || dia == null) return '';
    if (sys < 120 && dia < 80) return 'ปกติ';
    if (sys < 130 && dia < 80) return 'เริ่มสูง';
    if (sys < 140 || dia < 90) return 'เฝ้าระวัง';
    return 'ความดันสูง';
  }

  static String _formatCompanyAddress(CompanyProfile? company) {
    if (company == null) return '-';
    final parts = [
      company.addressNumber != null ? 'เลขที่ ${company.addressNumber}' : null,
      company.moo != null ? 'หมู่ ${company.moo}' : null,
      company.soi != null ? 'ซอย ${company.soi}' : null,
      company.road != null ? 'ถนน ${company.road}' : null,
      company.subdistrict != null ? 'ตำบล/แขวง ${company.subdistrict}' : null,
      company.district != null ? 'อำเภอ/เขต ${company.district}' : null,
      company.province != null ? 'จังหวัด ${company.province}' : null,
      company.postalCode,
    ].where((p) => p != null && p.isNotEmpty).toList();

    return parts.isEmpty ? '-' : parts.join(' ');
  }

  static pw.Widget _buildModernSectionHeader(String title, String subtitle) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4, bottom: 3),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          ),
          pw.Text(
            subtitle,
            style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.blue100),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPersonalInfoCard({
    required Employee employee,
    required String orgName,
    required String fullAddress,
    CompanyProfile? company,
    pw.MemoryImage? photo,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (photo != null) ...[
            pw.Container(
              width: 44,
              height: 55,
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(3),
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 3,
                verticalRadius: 3,
                child: pw.Image(photo, fit: pw.BoxFit.cover),
              ),
            ),
            pw.SizedBox(width: 8),
          ],
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildModernInfoRow('ชื่อ - นามสกุล', employee.fullName, isBold: true),
                pw.SizedBox(height: 1.5),
                _buildModernInfoRow('เลขประจำตัวประชาชน', formatNationalId(employee.nationalId)),
                pw.SizedBox(height: 1.5),
                _buildModernInfoRow('แผนก / ตำแหน่ง', '${employee.department}  |  ${employee.position}'),
                pw.SizedBox(height: 1.5),
                _buildModernInfoRow('วันที่เริ่มเข้าทำงาน', formatThaiDate(employee.hireDate)),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildModernInfoRow('สถานประกอบกิจการ', orgName, isBold: true),
                pw.SizedBox(height: 1.5),
                _buildModernInfoRow('เลขทะเบียนนิติบุคคล', company?.taxId ?? '-'),
                pw.SizedBox(height: 1.5),
                _buildModernInfoRow('ที่ตั้งสถานประกอบการ', fullAddress),
                pw.SizedBox(height: 1.5),
                _buildModernInfoRow('เบอร์โทรศัพท์', company?.phone ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildModernInfoRow(String label, String value, {bool isBold = false}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 7.2, color: PdfColors.grey700),
          ),
        ),
        pw.Text(': ', style: const pw.TextStyle(fontSize: 7.2, color: PdfColors.grey700)),
        pw.Expanded(
          child: pw.Text(
            value.isNotEmpty ? value : '-',
            style: pw.TextStyle(
              fontSize: 7.2,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isBold ? PdfColors.blue900 : PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildHealthRecordCard(EmployeeHealthRecord r) {
    PdfColor resultColor;
    PdfColor resultBg;
    PdfColor resultBorder;
    String resultText;

    switch (r.overallResult) {
      case 'NORMAL':
        resultColor = PdfColors.green900;
        resultBg = PdfColors.green50;
        resultBorder = PdfColors.green300;
        resultText = '✓ ผลตรวจปกติ (Normal)';
        break;
      case 'WATCH':
        resultColor = PdfColors.amber900;
        resultBg = PdfColors.amber50;
        resultBorder = PdfColors.amber300;
        resultText = '⚠ เฝ้าระวัง (Watch)';
        break;
      case 'ABNORMAL':
        resultColor = PdfColors.red900;
        resultBg = PdfColors.red50;
        resultBorder = PdfColors.red300;
        resultText = '✕ ผิดปกติ (Abnormal)';
        break;
      default:
        resultColor = PdfColors.grey800;
        resultBg = PdfColors.grey100;
        resultBorder = PdfColors.grey300;
        resultText = 'รอผลตรวจ (Pending)';
    }

    final formattedDate = formatThaiDate(r.checkupDate);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // 1. Header Bar
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(5),
                topRight: pw.Radius.circular(5),
              ),
              border: const pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 5,
                      height: 5,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue900,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Text(
                      r.checkupTypeLabel,
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'วันที่ตรวจ: $formattedDate',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: pw.BoxDecoration(
                    color: resultBg,
                    borderRadius: pw.BorderRadius.circular(3),
                    border: pw.Border.all(color: resultBorder, width: 0.6),
                  ),
                  child: pw.Text(
                    resultText,
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: resultColor),
                  ),
                ),
              ],
            ),
          ),

          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Hospital & Physician
                pw.Row(
                  children: [
                    pw.Text('สถานพยาบาล: ', style: const pw.TextStyle(fontSize: 7.2, color: PdfColors.grey700)),
                    pw.Text(r.hospitalName.isNotEmpty ? r.hospitalName : '-', style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 10),
                    pw.Text('แพทย์ผู้ตรวจ: ', style: const pw.TextStyle(fontSize: 7.2, color: PdfColors.grey700)),
                    pw.Text(r.doctorName ?? 'แพทย์เวชศาสตร์ครอบครัว/อาชีวเวชศาสตร์', style: const pw.TextStyle(fontSize: 7.2)),
                    if (r.doctorLicenseNo != null && r.doctorLicenseNo!.isNotEmpty)
                      pw.Text(' (${r.doctorLicenseNo})', style: const pw.TextStyle(fontSize: 7.2, color: PdfColors.grey700)),
                  ],
                ),
                pw.SizedBox(height: 4),

                // Vitals & Metrics 5 Boxes
                pw.Row(
                  children: [
                    _buildMetricPill('น้ำหนัก', '${r.weight ?? "-"} กก.', null),
                    pw.SizedBox(width: 3.5),
                    _buildMetricPill('ส่วนสูง', '${r.height ?? "-"} ซม.', null),
                    pw.SizedBox(width: 3.5),
                    _buildMetricPill('BMI', r.bmi?.toStringAsFixed(1) ?? '-', interpretBmi(r.bmi)),
                    pw.SizedBox(width: 3.5),
                    _buildMetricPill('ความดัน (BP)', r.bpReading, interpretBp(r.bpSystolic, r.bpDiastolic)),
                    pw.SizedBox(width: 3.5),
                    _buildMetricPill('ชีพจร (Pulse)', '${r.pulse ?? "-"} bpm', r.pulse != null ? 'ครั้ง/นาที' : null),
                  ],
                ),
                pw.SizedBox(height: 5),

                // Lab & Diagnostic Test Grid
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1.4),
                      1: const pw.FlexColumnWidth(1.2),
                      2: const pw.FlexColumnWidth(1.4),
                      3: const pw.FlexColumnWidth(1.2),
                    },
                    children: [
                      _buildLabTableRow(
                        'เอกซเรย์ปอด (Chest X-Ray)', r.chestXrayResult,
                        'ตรวจการได้ยิน (Audiogram)', r.audiogramResult,
                        isHeader: false, isEven: true,
                      ),
                      _buildLabTableRow(
                        'สมรรถภาพปอด (Spirometry)', r.spirometryResult,
                        'การมองเห็น/สายตา (Vision)', r.visionTestResult,
                        isHeader: false, isEven: false,
                      ),
                      _buildLabTableRow(
                        'ความสมบูรณ์เม็ดเลือด (CBC)', r.bloodCbcResult,
                        'ระดับน้ำตาลในเลือด (FBS)', r.bloodSugarResult,
                        isHeader: false, isEven: true,
                      ),
                      _buildLabTableRow(
                        'การทำงานของตับ (Liver)', r.liverFunctionResult,
                        'การทำงานของไต (Kidney)', r.kidneyFunctionResult,
                        isHeader: false, isEven: false,
                      ),
                      _buildLabTableRow(
                        'ตรวจปัสสาวะ (Urine Exam)', r.urineExamResult,
                        'สารเสพติด (Drug Screen)', r.drugScreeningResult,
                        isHeader: false, isEven: true,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),

                // Doctor Assessment & Fitness Box
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.blue200, width: 0.5),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 7,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'ความเห็นและคำแนะนำของแพทย์:',
                              style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                            ),
                            pw.Text(
                              (r.doctorOpinion != null && r.doctorOpinion!.isNotEmpty)
                                  ? r.doctorOpinion!
                                  : (r.overallResult == 'NORMAL' ? 'ผลตรวจร่างกายทั่วไปอยู่ในเกณฑ์ปกติ สุขภาพแข็งแรงดี' : 'ควรเฝ้าระวังและปฏิบัติตามคำแนะนำของแพทย์'),
                              style: const pw.TextStyle(fontSize: 7.2, color: PdfColors.blueGrey800),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Expanded(
                        flex: 5,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'ความพร้อมทำงาน (Fitness):',
                              style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                            ),
                            pw.SizedBox(height: 1.5),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: pw.BoxDecoration(
                                color: r.fitnessToWork == 'FIT'
                                    ? PdfColors.green100
                                    : (r.fitnessToWork == 'FIT_WITH_RESTRICTION' ? PdfColors.amber100 : PdfColors.red100),
                                borderRadius: pw.BorderRadius.circular(3),
                                border: pw.Border.all(
                                  color: r.fitnessToWork == 'FIT'
                                      ? PdfColors.green700
                                      : (r.fitnessToWork == 'FIT_WITH_RESTRICTION' ? PdfColors.amber700 : PdfColors.red700),
                                  width: 0.5,
                                ),
                              ),
                              child: pw.Text(
                                r.fitnessLabel,
                                style: pw.TextStyle(
                                  fontSize: 7.2,
                                  fontWeight: pw.FontWeight.bold,
                                  color: r.fitnessToWork == 'FIT'
                                      ? PdfColors.green900
                                      : (r.fitnessToWork == 'FIT_WITH_RESTRICTION' ? PdfColors.amber900 : PdfColors.red900),
                                ),
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
        ],
      ),
    );
  }

  static pw.Widget _buildMetricPill(String title, String value, String? sub) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 3),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.circular(3),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 6.2, color: PdfColors.grey700)),
            pw.SizedBox(height: 0.5),
            pw.Text(value, style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            if (sub != null && sub.isNotEmpty)
              pw.Text(sub, style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey600), maxLines: 1),
          ],
        ),
      ),
    );
  }

  static pw.TableRow _buildLabTableRow(
    String test1, String res1,
    String test2, String res2, {
    required bool isHeader,
    required bool isEven,
  }) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isEven ? PdfColors.white : PdfColors.grey50,
      ),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: pw.Text(test1, style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey800)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: _buildLabResultBadge(res1),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: pw.Text(test2, style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey800)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: _buildLabResultBadge(res2),
        ),
      ],
    );
  }

  static pw.Widget _buildLabResultBadge(String rawResult) {
    final label = translateLabResult(rawResult);
    final isAbnormal = rawResult == 'ABNORMAL' || rawResult == 'POSITIVE';
    final isWatch = rawResult == 'WATCH';
    final isNotTested = rawResult == 'NOT_TESTED' || rawResult.isEmpty;

    PdfColor textColor = PdfColors.green900;
    if (isAbnormal) {
      textColor = PdfColors.red900;
    } else if (isWatch) {
      textColor = PdfColors.amber900;
    } else if (isNotTested) {
      textColor = PdfColors.grey600;
    }

    return pw.Text(
      label,
      style: pw.TextStyle(
        fontSize: 6.8,
        fontWeight: isAbnormal ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: textColor,
      ),
    );
  }

  static pw.Widget _buildSignatureBoxes(Employee employee) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Left Box: Employee
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(7),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(5),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'ลูกจ้างผู้ถือสมุดสุขภาพ',
                  style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'ลงชื่อ.................................................................',
                  style: const pw.TextStyle(fontSize: 7.2),
                ),
                pw.SizedBox(height: 1.5),
                pw.Text(
                  '( ${employee.fullName} )',
                  style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'ตำแหน่ง: ${employee.position}',
                  style: const pw.TextStyle(fontSize: 6.2, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 1.5),
                pw.Text(
                  'วันที่ .......... / .......... / ..............',
                  style: const pw.TextStyle(fontSize: 6.2, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),

        // Right Box: Employer / OSH Officer
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(7),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(5),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'นายจ้าง / แพทย์ผู้ตรวจ / เจ้าหน้าที่ความปลอดภัย',
                  style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'ลงชื่อ.................................................................',
                  style: const pw.TextStyle(fontSize: 7.2),
                ),
                pw.SizedBox(height: 1.5),
                pw.Text(
                  '( ................................................................. )',
                  style: const pw.TextStyle(fontSize: 7.2),
                ),
                pw.Text(
                  'เจ้าหน้าที่ความปลอดภัยในการทำงานระดับวิชาชีพ / นายจ้าง',
                  style: const pw.TextStyle(fontSize: 6.2, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 1.5),
                pw.Text(
                  'วันที่ .......... / .......... / ..............',
                  style: const pw.TextStyle(fontSize: 6.2, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
          ),
          pw.Expanded(
            child: pw.Text(': $value', style: const pw.TextStyle(fontSize: 8)),
          ),
        ],
      ),
    );
  }
}
