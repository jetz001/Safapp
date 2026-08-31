import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/models/accident_models.dart';
import '../../risk_assessment/domain/models/risk_assessment_models.dart';

class AccidentOfficialPdfService {
  // ==========================================================================
  // 1. แบบรายงานผลการสอบสวนวิเคราะห์อุบัติเหตุและโรคจากการทำงาน (๗ หัวข้อตามคู่มือราชการ)
  // ==========================================================================
  static Future<void> printOfficialInvestigationReport({
    required BuildContext context,
    required AccidentInvestigation investigation,
    required List<AccidentCapaAction> capaActions,
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
      final bizType = (company?.businessCategoryTitle?.isNotEmpty == true) ? company!.businessCategoryTitle! : 'การผลิตและประกอบอุตสาหกรรม';
      final totalEmp = company?.employeeCount ?? 100;
      final fullAddress = _formatCompanyAddress(company);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
          header: (pw.Context ctx) {
            return pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('แบบรายงานผลการสอบสวน วิเคราะห์อุบัติเหตุและโรคจากการทำงาน', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.Text('เลขที่: ${investigation.eventNo}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  ],
                ),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 6),
              ],
            );
          },
          build: (pw.Context ctx) {
            final tableData = capaActions.map((AccidentCapaAction a) {
              final statusText = a.status == 'COMPLETED' ? 'เสร็จสิ้น' : 'กำลังดำเนินการ';
              final cleanLabel = a.hierarchyLabel.replaceAll(RegExp(r'[^\w\s\u0E00-\u0E7F]'), '');
              return <String>[
                cleanLabel,
                a.actionDescription,
                a.responsiblePerson,
                a.targetDate,
                statusText,
              ];
            }).toList();

            return [
              // Title
              pw.Center(
                child: pw.Text(
                  'แบบรายงานผลการสอบสวน วิเคราะห์อุบัติเหตุและโรคจากการทำงาน',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'กรณีเหตุการณ์: ${investigation.incidentTitle} (${investigation.eventTypeLabel})',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                ),
              ),
              pw.SizedBox(height: 12),

              // ๑. ข้อมูลสถานประกอบกิจการ/นายจ้าง
              _buildSectionTitle('๑. ข้อมูลสถานประกอบกิจการ / นายจ้าง'),
              _buildInfoRow('๑.๑ ชื่อสถานประกอบการ', orgName),
              _buildInfoRow('ประเภทกิจการ', bizType),
              _buildInfoRow('ที่ตั้ง / แผนก', '$fullAddress | แผนกที่เกิดเหตุ: ${investigation.injuredPersonDepartment ?? investigation.incidentLocation}'),
              _buildInfoRow('๑.๒ จำนวนลูกจ้างรวม', '$totalEmp คน'),
              pw.SizedBox(height: 10),

              // ๒. ข้อมูลทั่วไปและลำดับเหตุการณ์
              _buildSectionTitle('๒. ข้อมูลทั่วไป / รายละเอียดและลำดับเหตุการณ์การเกิดอุบัติเหตุ'),
              _buildInfoRow('๒.๑ วันที่และเวลาเกิดเหตุ', '${investigation.incidentDate} เวลา ${investigation.incidentTime} น.'),
              _buildInfoRow('สถานที่เกิดเหตุ', investigation.incidentLocation),
              if (investigation.machineInvolved != null && investigation.machineInvolved!.isNotEmpty)
                _buildInfoRow('เครื่องจักร/อุปกรณ์ที่เกี่ยวข้อง', investigation.machineInvolved!),
              if (investigation.chemicalInvolved != null && investigation.chemicalInvolved!.isNotEmpty)
                _buildInfoRow('สารเคมี/วัตถุอันตราย', investigation.chemicalInvolved!),
              if (investigation.workProcessInvolved != null && investigation.workProcessInvolved!.isNotEmpty)
                _buildInfoRow('ขั้นตอนกระบวนการทำงาน', investigation.workProcessInvolved!),
              pw.SizedBox(height: 4),

              pw.Text('๒.๒ รายละเอียดเหตุการณ์ (5W 1H Narrative):', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(6),
                margin: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Text(
                  investigation.description5w1h ?? 'ขณะปฏิบัติงานตามปกติ เกิดเหตุการณ์ขัดข้องทำให้ผู้ประสบเหตุได้รับอันตราย',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),

              if (investigation.timelineEvents.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text('ลำดับเหตุการณ์ (Timeline Sequence):', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ...investigation.timelineEvents.map((t) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
                      child: pw.Text('• เวลา ${t.time} น. : ${t.action}', style: const pw.TextStyle(fontSize: 8.5)),
                    )),
              ],
              pw.SizedBox(height: 10),

              // ๓. รายละเอียดความสูญเสีย
              _buildSectionTitle('๓. รายละเอียดการประสบอันตราย / ความสูญเสีย / หยุดการผลิต'),
              _buildInfoRow('ผู้ประสบอันตราย', '${investigation.injuredPersonName ?? "-"} (ตำแหน่ง: ${investigation.injuredPersonPosition ?? "-"}, แผนก: ${investigation.injuredPersonDepartment ?? "-"})'),
              _buildInfoRow('ลักษณะการบาดเจ็บ / อวัยวะ', '${investigation.injuryNature ?? "-"} (บริเวณ: ${investigation.injuredBodyPart ?? "-"})'),
              _buildInfoRow('สถานพยาบาลที่ส่งรักษา', '${investigation.hospitalName ?? "-"} (ส่งตัวเมื่อ: ${investigation.hospitalSentDate ?? "-"})'),
              _buildInfoRow('สถิติความสูญเสีย', 'จำนวนวันหยุดงาน: ${investigation.daysLost} วัน | ค่ารักษาพยาบาล: ${investigation.medicalExpense.toStringAsFixed(2)} บาท | ทรัพย์สินเสียหาย: ${investigation.propertyDamageCost.toStringAsFixed(2)} บาท'),
              pw.SizedBox(height: 10),

              // ๔. การวิเคราะห์สาเหตุ ๓ ปัจจัย (Causation Analysis)
              _buildSectionTitle('๔. การวิเคราะห์ปัจจัย / สาเหตุการเกิดอุบัติเหตุ (Root Cause Analysis)'),
              pw.Text('๔.๑ ปัจจัยด้านบุคคล / การกระทำที่ไม่ปลอดภัย (Unsafe Act / Substandard Act):', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
              if (investigation.unsafeActs.isEmpty)
                pw.Padding(padding: const pw.EdgeInsets.only(left: 8), child: pw.Text('- ไม่พบการกระทำที่ไม่ปลอดภัยของผู้ปฏิบัติงาน', style: const pw.TextStyle(fontSize: 8.5)))
              else
                ...investigation.unsafeActs.map((act) => pw.Padding(padding: const pw.EdgeInsets.only(left: 8, bottom: 2), child: pw.Text('• $act', style: const pw.TextStyle(fontSize: 8.5)))),
              pw.SizedBox(height: 4),

              pw.Text('๔.๒ ปัจจัยด้านสภาพแวดล้อม / เครื่องจักร / สภาพที่ไม่ปลอดภัย (Unsafe Condition):', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
              if (investigation.unsafeConditions.isEmpty)
                pw.Padding(padding: const pw.EdgeInsets.only(left: 8), child: pw.Text('- เครื่องจักรและสภาพแวดล้อมอยู่ในเกณฑ์มาตรฐาน', style: const pw.TextStyle(fontSize: 8.5)))
              else
                ...investigation.unsafeConditions.map((cond) => pw.Padding(padding: const pw.EdgeInsets.only(left: 8, bottom: 2), child: pw.Text('• $cond', style: const pw.TextStyle(fontSize: 8.5)))),
              pw.SizedBox(height: 4),

              pw.Text('๔.๓ ปัจจัยด้านการบริหารจัดการ / ระบบควบคุม (Management Error / Lack of Control):', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              if (investigation.managementErrors.isEmpty)
                pw.Padding(padding: const pw.EdgeInsets.only(left: 8), child: pw.Text('- มีระบบการควบคุมและขั้นตอนการทำงาน', style: const pw.TextStyle(fontSize: 8.5)))
              else
                ...investigation.managementErrors.map((err) => pw.Padding(padding: const pw.EdgeInsets.only(left: 8, bottom: 2), child: pw.Text('• $err', style: const pw.TextStyle(fontSize: 8.5)))),
              pw.SizedBox(height: 10),

              // ๕. ข้อเสนอแนะมาตรการแก้ไขป้องกัน (CAPA 4 ระดับ)
              _buildSectionTitle('๕. ข้อเสนอแนะและมาตรการสำหรับการแก้ไขป้องกัน (4-Level Controls)'),
              if (capaActions.isEmpty)
                pw.Text('ยังไม่มีการระบุมาตรการแก้ไขป้องกัน', style: const pw.TextStyle(fontSize: 8.5))
              else
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  headers: <String>['ระดับการควบคุม', 'รายละเอียดมาตรการแก้ไขป้องกัน', 'ผู้รับผิดชอบ', 'กำหนดเสร็จ', 'สถานะ'],
                  data: tableData,
                ),
              pw.SizedBox(height: 10),

              // ๖. กฎหมายที่เกี่ยวข้อง
              _buildSectionTitle('๖. กฎหมายที่เกี่ยวข้องกับอุบัติเหตุ'),
              if (investigation.applicableLaws.isEmpty)
                pw.Text('• พ.ร.บ. ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔ (มาตรา ๑๔, ๑๖, ๓๒, ๓๔)', style: const pw.TextStyle(fontSize: 8.5))
              else
                ...investigation.applicableLaws.map((law) => pw.Padding(padding: const pw.EdgeInsets.only(left: 8, bottom: 2), child: pw.Text('• $law', style: const pw.TextStyle(fontSize: 8.5)))),
              pw.SizedBox(height: 16),

              // ๗. ผู้สอบสวนและลงนาม
              _buildSectionTitle('๗. ผู้สอบสวนและวิเคราะห์อุบัติเหตุ'),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('ลงชื่อ.................................................................', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 4),
                      pw.Text('(${investigation.inspectorName ?? "เจ้าหน้าที่ความปลอดภัยในการทำงาน"})', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Text('ผู้สอบสวนและวิเคราะห์อุบัติเหตุ', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('ลงชื่อ.................................................................', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 4),
                      pw.Text('(.................................................................)', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Text('กรรมการผู้จัดการ / ตัวแทนนายจ้าง', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
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
        name: 'AccidentInvestigationReport_${investigation.eventNo}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการพิมพ์รายงานสอบสวน: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==========================================================================
  // 2. แบบ กท. ๔๔ (ใบส่งตัวลูกจ้างเข้ารับการรักษาพยาบาล กองทุนเงินทดแทน)
  // ==========================================================================
  static Future<void> printKorTor44Document({
    required BuildContext context,
    required AccidentInvestigation investigation,
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
      final ssoAccountNo = company?.taxId ?? 'XXXXXXXXXX';
      final hospital = investigation.hospitalName ?? 'สถานพยาบาลในความตกลงของกองทุนเงินทดแทน';
      final fullAddress = _formatCompanyAddress(company);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Right Badge
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('สำนักงานประกันสังคม กองทุนเงินทดแทน', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue900, width: 1.5), borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Text('แบบ กท. ๔๔', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                pw.Center(
                  child: pw.Text('ใบส่งตัวลูกจ้างเข้ารับการรักษาพยาบาล', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                ),
                pw.Center(
                  child: pw.Text('(สำหรับสถานพยาบาลในความตกลงของกองทุนเงินทดแทน)', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                ),
                pw.SizedBox(height: 14),

                pw.Text('เรียน  ผู้อำนวยการ / หัวหน้าสถานพยาบาล $hospital', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),

                pw.RichText(
                  text: pw.TextSpan(
                    style: const pw.TextStyle(fontSize: 10, lineSpacing: 4),
                    children: [
                      const pw.TextSpan(text: '       ด้วยข้าพเจ้า (นายจ้าง / ผู้รับมอบอำนาจ) ในนาม '),
                      pw.TextSpan(text: orgName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      const pw.TextSpan(text: '  เลขที่บัญชีนายจ้าง / เลขนิติบุคคล '),
                      pw.TextSpan(text: ssoAccountNo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      const pw.TextSpan(text: '  ตั้งอยู่เลขที่ '),
                      pw.TextSpan(text: fullAddress),
                      const pw.TextSpan(text: '  โทรศัพท์ '),
                      pw.TextSpan(text: company?.phone ?? "-"),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                pw.RichText(
                  text: pw.TextSpan(
                    style: const pw.TextStyle(fontSize: 10, lineSpacing: 4),
                    children: [
                      const pw.TextSpan(text: '       ขอส่งตัวลูกจ้างชื่อ '),
                      pw.TextSpan(text: investigation.injuredPersonName ?? "พนักงานผู้ประสบเหตุ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      const pw.TextSpan(text: '  เลขประจำตัวประชาชน '),
                      pw.TextSpan(text: investigation.injuredPersonNationalId ?? "-", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      const pw.TextSpan(text: '  ตำแหน่ง '),
                      pw.TextSpan(text: investigation.injuredPersonPosition ?? "-"),
                      const pw.TextSpan(text: '  สังกัดแผนก '),
                      pw.TextSpan(text: investigation.injuredPersonDepartment ?? "-"),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                pw.RichText(
                  text: pw.TextSpan(
                    style: const pw.TextStyle(fontSize: 10, lineSpacing: 4),
                    children: [
                      const pw.TextSpan(text: '       ซึ่งได้ประสบอันตรายหรือเจ็บป่วยเนื่องจากการทำงาน เมื่อวันที่ '),
                      pw.TextSpan(text: investigation.incidentDate, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      const pw.TextSpan(text: '  เวลาประมาณ '),
                      pw.TextSpan(text: '${investigation.incidentTime} น.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      const pw.TextSpan(text: '  สถานที่เกิดเหตุ: '),
                      pw.TextSpan(text: investigation.incidentLocation),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // Injury Details Box
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(4), border: pw.Border.all(color: PdfColors.grey300)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ลักษณะการประสบอันตรายและสภาพบาดแผลเบื้องต้น:', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 2),
                      pw.Text('• ลักษณะบาดแผล: ${investigation.injuryNature ?? "บาดเจ็บจากการทำงาน"} (บริเวณอวัยวะ: ${investigation.injuredBodyPart ?? "-"})', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('• รายละเอียด: ${investigation.incidentTitle}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                pw.Text(
                  '       จึงขอส่งตัวลูกจ้างรายนี้มาเพื่อรับการตรวจรักษาพยาบาลตามสิทธิประโยชน์แห่งพระราชบัญญัติเงินทดแทน พ.ศ. ๒๕๓๗ โดยขอความกรุณาเรียกเก็บค่าใช้จ่ายในการรักษาพยาบาลจากกองทุนเงินทดแทน สำนักงานประกันสังคม ตามระเบียบต่อไป',
                  style: const pw.TextStyle(fontSize: 10, lineSpacing: 4),
                ),
                pw.Spacer(),

                // Sign-off
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('วันที่ออกใบส่งตัว: ${investigation.hospitalSentDate ?? investigation.incidentDate}', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('หมายเหตุ: ใช้ยื่นต่อสถานพยาบาลทันที', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('ลงชื่อ.................................................................', style: const pw.TextStyle(fontSize: 9.5)),
                        pw.SizedBox(height: 4),
                        pw.Text('(.................................................................)', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('นายจ้าง / ผู้มีอำนาจลงนาม / ประทับตรา', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
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

      await Printing.layoutPdf(
        onLayout: (_) => doc.save(),
        name: 'KorTor44_${investigation.eventNo}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการพิมพ์แบบ กท. ๔๔: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==========================================================================
  // 3. แบบ สปร. ๕ (แจ้งอุบัติภัยร้ายแรง ม.๓๔ ภายใน ๗ วัน)
  // ==========================================================================
  static Future<void> printPorSorRor5Document({
    required BuildContext context,
    required AccidentInvestigation investigation,
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
      final bizType = company?.businessCategoryTitle ?? "อุตสาหกรรมการผลิต";
      final fullAddress = _formatCompanyAddress(company);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('กรมสวัสดิการและคุ้มครองแรงงาน', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue900, width: 1.5), borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Text('แบบ สปร. ๕', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                pw.Center(
                  child: pw.Text('แบบแจ้งการเกิดอุบัติภัยร้ายแรงหรือการประสบอันตรายจากการทำงาน', style: pw.TextStyle(fontSize: 13.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                ),
                pw.Center(
                  child: pw.Text('(ตามมาตรา ๓๔ แห่งพระราชบัญญัติความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔)', style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800)),
                ),
                pw.SizedBox(height: 14),

                pw.Text('เรียน  พนักงานตรวจความปลอดภัย สำนักงานสวัสดิการและคุ้มครองแรงงาน', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),

                _buildInfoRow('๑. ชื่อสถานประกอบกิจการ', orgName),
                _buildInfoRow('ประเภทกิจการ', bizType),
                _buildInfoRow('สถานที่ตั้ง', fullAddress),
                _buildInfoRow('๒. วันเวลาที่เกิดเหตุ', '${investigation.incidentDate} เวลา ${investigation.incidentTime} น.'),
                _buildInfoRow('สถานที่เกิดเหตุ', investigation.incidentLocation),
                _buildInfoRow('๓. ผู้ประสบอันตราย', '${investigation.injuredPersonName ?? "-"} (ตำแหน่ง: ${investigation.injuredPersonPosition ?? "-"})'),
                _buildInfoRow('ลักษณะอันตรายที่เกิดขึ้น', investigation.incidentTitle),
                _buildInfoRow('๔. สาเหตุอันตรายที่เกิดขึ้น', investigation.rootCauseSummary ?? investigation.description5w1h ?? "-"),
                _buildInfoRow('๕. ความเสียหาย', 'ผู้บาดเจ็บ/เสียชีวิต: ${investigation.eventTypeLabel} | ค่าเสียหายทรัพย์สิน: ${investigation.propertyDamageCost.toStringAsFixed(2)} บาท'),
                _buildInfoRow('๖. การแก้ไขและป้องกันการเกิดซ้ำ', 'จัดทำมาตรการปรับปรุงด้านวิศวกรรม, ทบทวน SOP และจัดอบรมความปลอดภัยพนักงาน'),
                pw.Spacer(),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('วันที่แจ้ง: ${DateTime.now().toIso8601String().substring(0, 10)}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Column(
                      children: [
                        pw.Text('ลงชื่อ.................................................................', style: const pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 4),
                        pw.Text('(.................................................................)', style: const pw.TextStyle(fontSize: 8.5)),
                        pw.Text('นายจ้าง / ผู้มีอำนาจทำการแทนนายจ้าง', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) => doc.save(),
        name: 'PorSorRor5_${investigation.eventNo}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการพิมพ์แบบ สปร. ๕: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==========================================================================
  // 4. แบบ กท. ๑๖ (แบบแจ้งการประสบอันตรายและขอรับเงินทดแทน ภายใน ๑๕ วัน)
  // ==========================================================================
  static Future<void> printKorTor16Document({
    required BuildContext context,
    required AccidentInvestigation investigation,
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
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('สำนักงานประกันสังคม กองทุนเงินทดแทน', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue900, width: 1.5), borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Text('แบบ กท. ๑๖', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                pw.Center(
                  child: pw.Text('แบบแจ้งการประสบอันตราย เจ็บป่วย หรือสูญหาย และคำร้องขอรับเงินทดแทน', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                ),
                pw.Center(
                  child: pw.Text('(ตามพระราชบัญญัติเงินทดแทน พ.ศ. ๒๕๓๗ ภายใน ๑๕ วันนับแต่วันทราบเหตุ)', style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800)),
                ),
                pw.SizedBox(height: 14),

                _buildSectionTitle('ส่วนที่ ๑: ข้อมูลนายจ้างและสถานประกอบการ'),
                _buildInfoRow('ชื่อนายจ้าง/สถานประกอบการ', orgName),
                _buildInfoRow('เลขที่บัญชีประกันสังคม / เลขนิติบุคคล', company?.taxId ?? "-"),
                _buildInfoRow('ที่ตั้งสถานประกอบการ', fullAddress),
                pw.SizedBox(height: 8),

                _buildSectionTitle('ส่วนที่ ๒: ข้อมูลลูกจ้างผู้ประสบอันตราย'),
                _buildInfoRow('ชื่อ - นามสกุล ลูกจ้าง', '${investigation.injuredPersonName ?? "-"} (อายุ: ${investigation.injuredPersonAge ?? "-"} ปี)'),
                _buildInfoRow('เลขประจำตัวประชาชน', investigation.injuredPersonNationalId ?? "-"),
                _buildInfoRow('ตำแหน่ง / แผนก', '${investigation.injuredPersonPosition ?? "-"} / ${investigation.injuredPersonDepartment ?? "-"}'),
                _buildInfoRow('อัตราค่าจ้าง', '${investigation.injuredPersonWage != null ? investigation.injuredPersonWage!.toStringAsFixed(2) : "-"} บาท/เดือน'),
                pw.SizedBox(height: 8),

                _buildSectionTitle('ส่วนที่ ๓: รายละเอียดการประสบอันตรายและการรักษา'),
                _buildInfoRow('วันเวลาที่เกิดเหตุ', '${investigation.incidentDate} เวลา ${investigation.incidentTime} น.'),
                _buildInfoRow('ลักษณะการทำงานขณะเกิดเหตุ', investigation.workProcessInvolved ?? investigation.incidentTitle),
                _buildInfoRow('สาเหตุการประสบอันตราย', investigation.description5w1h ?? "-"),
                _buildInfoRow('อวัยวะที่ได้รับบาดเจ็บ', '${investigation.injuryNature ?? "-"} บริเวณ ${investigation.injuredBodyPart ?? "-"}'),
                _buildInfoRow('สถานพยาบาลที่เข้ารักษา', investigation.hospitalName ?? "-"),
                _buildInfoRow('การหยุดงานรักษาตัว', 'คาดว่าต้องหยุดพักรักษาตัวประมาณ ${investigation.daysLost} วัน'),
                pw.Spacer(),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('วันที่ยื่นคำร้อง: ${DateTime.now().toIso8601String().substring(0, 10)}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Column(
                      children: [
                        pw.Text('ลงชื่อ.................................................................', style: const pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 4),
                        pw.Text('(.................................................................)', style: const pw.TextStyle(fontSize: 8.5)),
                        pw.Text('นายจ้าง / ผู้รับมอบอำนาจ', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) => doc.save(),
        name: 'KorTor16_${investigation.eventNo}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการพิมพ์แบบ กท. ๑๖: $e'), backgroundColor: Colors.red),
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
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 140, child: pw.Text(label, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
          pw.Expanded(child: pw.Text(': $value', style: const pw.TextStyle(fontSize: 8.5))),
        ],
      ),
    );
  }
}
