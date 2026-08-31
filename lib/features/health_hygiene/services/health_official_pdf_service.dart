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

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          header: (pw.Context ctx) {
            return pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('สมุดสุขภาพประจำตัวของลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.Text('รหัสพนักงาน: ${employee.employeeCode}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  ],
                ),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 4),
              ],
            );
          },
          build: (pw.Context ctx) {
            return [
              // Cover / Header
              pw.Container(
                width: double.infinity,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'สมุดสุขภาพประจำตัวของลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง',
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.Text(
                      '(ตามกฎกระทรวงกำหนดมาตรฐานการตรวจสุขภาพลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง พ.ศ. ๒๕๖๓)',
                      style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // Section 1: ประวัติส่วนตัว
              _buildSectionTitle('ส่วนที่ ๑: ข้อมูลประวัติส่วนตัวและประวัติการทำงาน'),
              _buildInfoRow('ชื่อ - นามสกุล', employee.fullName),
              _buildInfoRow('เลขประจำตัวประชาชน', employee.nationalId ?? "-"),
              _buildInfoRow('แผนก / ตำแหน่งงาน', '${employee.department}  |  ตำแหน่ง: ${employee.position}'),
              _buildInfoRow('วันที่เริ่มเข้าทำงาน', employee.hireDate ?? "-"),
              _buildInfoRow('ชื่อสถานประกอบกิจการ', orgName),
              _buildInfoRow('ที่ตั้งสถานประกอบการ', fullAddress),
              pw.SizedBox(height: 8),

              // Section 2: รายการตรวจสุขภาพสะสม
              _buildSectionTitle('ส่วนที่ ๒: ประวัติการตรวจสุขภาพและการตรวจตามปัจจัยเสี่ยง'),
              if (healthRecords.isEmpty)
                pw.Text('ยังไม่มีประวัติการบันทึกตรวจสุขภาพในระบบ', style: const pw.TextStyle(fontSize: 8.5))
              else
                ...healthRecords.map((r) {
                  final vitals = 'น้ำหนัก: ${r.weight ?? "-"} กก., ส่วนสูง: ${r.height ?? "-"} ซม., BMI: ${r.bmi?.toStringAsFixed(1) ?? "-"}, ความดัน: ${r.bpReading}, ชีพจร: ${r.pulse ?? "-"} bpm';
                  final labTests = 'CXR: ${r.chestXrayResult}, การได้ยิน: ${r.audiogramResult}, ปอด: ${r.spirometryResult}, สายตา: ${r.visionTestResult}, CBC: ${r.bloodCbcResult}, น้ำตาล: ${r.bloodSugarResult}, สารเสพติด: ${r.drugScreeningResult}';

                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('• ${r.checkupTypeLabel} (${r.checkupDate})', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                            pw.Text('ผลตรวจ: ${r.overallResultPlainLabel}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('สถานพยาบาล: ${r.hospitalName} ${r.doctorName != null ? "| แพทย์: ${r.doctorName}" : ""}', style: const pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(height: 2),
                        pw.Text('สัญญาณชีพ: $vitals', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text('ผลตรวจ Lab & เครื่องมือพิเศษ: $labTests', style: const pw.TextStyle(fontSize: 7.5)),
                        if (r.doctorOpinion != null && r.doctorOpinion!.isNotEmpty)
                          pw.Text('ความเห็นแพทย์: ${r.doctorOpinion}', style: pw.TextStyle(fontSize: 7.5, fontStyle: pw.FontStyle.italic, color: PdfColors.blueGrey800)),
                        pw.Text('การประเมินความพร้อมทำงาน: ${r.fitnessLabel}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                      ],
                    ),
                  );
                }),
              pw.SizedBox(height: 10),

              // Section 3: ลงนามรับรอง
              _buildSectionTitle('ส่วนที่ ๓: การรับรองสมุดสุขภาพ'),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('ลงชื่อ.................................................................', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.SizedBox(height: 2),
                      pw.Text('(${employee.fullName})', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('ลูกจ้างผู้ถือสมุดสุขภาพ', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('ลงชื่อ.................................................................', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.SizedBox(height: 2),
                      pw.Text('(.................................................................)', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('นายจ้าง / เจ้าหน้าที่ความปลอดภัย', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
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
  // 3. ใบสรุปผลการตรวจสุขภาพรายบุคคล (Individual Health Summary)
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

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('ฝ่ายอาชีวอนามัยและความปลอดภัย', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.Text('วันที่ตรวจ: ${record.checkupDate}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  ],
                ),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 8),

                pw.Container(
                  width: double.infinity,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('ใบสรุปผลการตรวจสุขภาพและประเมินความพร้อมในการทำงาน', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text('Occupational Health & Fitness for Duty Certificate', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                _buildSectionTitle('ข้อมูลผู้รับการตรวจสุขภาพ'),
                _buildInfoRow('ชื่อ - นามสกุล', '${record.employeeName ?? "-"} (รหัส: ${record.employeeCode ?? "-"})'),
                _buildInfoRow('สังกัดแผนก / ตำแหน่ง', '${record.department ?? "-"} / ${record.position ?? "-"}'),
                _buildInfoRow('สถานประกอบการ', orgName),
                _buildInfoRow('ประเภทการตรวจ', record.checkupTypeLabel),
                _buildInfoRow('หน่วยบริการตรวจสุขภาพ', record.hospitalName),
                pw.SizedBox(height: 8),

                _buildSectionTitle('ผลการตรวจร่างกายและสัญญาณชีพ'),
                _buildInfoRow('น้ำหนัก / ส่วนสูง / BMI', '${record.weight ?? "-"} กก. / ${record.height ?? "-"} ซม. (BMI: ${record.bmi?.toStringAsFixed(1) ?? "-"})'),
                _buildInfoRow('ความดันโลหิต / ชีพจร', '${record.bpReading} / ${record.pulse ?? "-"} ครั้ง/นาที'),
                _buildInfoRow('การตรวจร่างกายทั่วไป', record.physicalExamResult == 'NORMAL' ? 'ปกติ' : 'ผิดปกติ: ${record.physicalExamNotes ?? ""}'),
                pw.SizedBox(height: 8),

                _buildSectionTitle('ผลการตรวจทางห้องปฏิบัติการและเครื่องมือพิเศษ'),
                _buildInfoRow('เอกซเรย์ปอด (Chest X-Ray)', record.chestXrayResult == 'NORMAL' ? 'ปกติ (Normal)' : record.chestXrayResult),
                _buildInfoRow('สมรรถภาพการได้ยิน (Audiogram)', record.audiogramResult),
                _buildInfoRow('สมรรถภาพปอด (Spirometry)', record.spirometryResult),
                _buildInfoRow('การมองเห็นและตาบอดสี', record.visionTestResult),
                _buildInfoRow('ผลตรวจเลือด (CBC / น้ำตาล / ตับ / ไต)', '${record.bloodCbcResult} / น้ำตาล: ${record.bloodSugarResult} / ตับ: ${record.liverFunctionResult} / ไต: ${record.kidneyFunctionResult}'),
                _buildInfoRow('ตรวจสารเสพติดในปัสสาวะ', record.drugScreeningResult),
                pw.SizedBox(height: 8),

                // Doctor Conclusion Box
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: record.overallResult == 'NORMAL' ? PdfColors.green50 : PdfColors.amber50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: record.overallResult == 'NORMAL' ? PdfColors.green300 : PdfColors.amber300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('สรุปผลการตรวจและความเห็นทางการแพทย์:', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 2),
                      pw.Text('• ผลตรวจสุขภาพภาพรวม: ${record.overallResultPlainLabel}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('• ความพร้อมในการปฏิบัติงาน: ${record.fitnessLabel}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      if (record.doctorOpinion != null && record.doctorOpinion!.isNotEmpty)
                        pw.Text('• คำแนะนำแพทย์: ${record.doctorOpinion}', style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                ),
                pw.Spacer(),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('แพทย์ผู้ทำการตรวจ: ${record.doctorName ?? "แพทย์อาชีวเวชศาสตร์"}', style: const pw.TextStyle(fontSize: 8.5)),
                        pw.Text('เลขที่ใบประกอบวิชาชีพ: ${record.doctorLicenseNo ?? "ว.XXXXX"}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('ลงชื่อ.................................................................', style: const pw.TextStyle(fontSize: 8.5)),
                        pw.SizedBox(height: 2),
                        pw.Text('(.................................................................)', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('แพทย์ผู้ตรวจ / ประทับตราสถานพยาบาล', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
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
  // HELPERS
  // ==========================================================================
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

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
      ),
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
