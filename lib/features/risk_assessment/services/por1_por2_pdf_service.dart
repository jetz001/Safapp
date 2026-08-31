import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/models/risk_assessment_models.dart';

class Por1Por2PdfService {
  /// สร้าง PDF แบบฟอร์มราชการเป๊ะๆ 100% ตามประกาศกระทรวงแรงงาน (ใบปะหน้า + แบบ ปอ. ๑ + แบบ ปอ. ๒)
  static Future<Uint8List> generateOfficialPorDocument({
    required CompanyProfile company,
    required RiskAssessmentSession session,
    required List<PorReportRowData> rows,
  }) async {
    final pdf = pw.Document();

    // โหลดฟอนต์ภาษาไทยสารบรรณ (Sarabun)
    final fontRegular = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();
    final fontItalic = await PdfGoogleFonts.sarabunItalic();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
    );

    // =========================================================================
    // 1. หน้าใบปะหน้า (Cover Sheet: แบบรายงานผลการประเมินอันตรายฯ ตามข้อ ๙)
    // =========================================================================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (context) {
          final isJsa = session.hazardIdMethod.contains('JSA') || session.hazardIdMethod.contains('Job Safety Analysis');
          final isStandard = session.hazardIdMethod.contains('มาตรฐานสากล') || session.hazardIdMethod.contains('International');
          final isGov = session.hazardIdMethod.contains('หน่วยงานราชการ');
          final isApproved = session.hazardIdMethod.contains('อธิบดี') || (session.hazardIdStandardApproved != null && session.hazardIdStandardApproved!.isNotEmpty);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Titles
              pw.Center(
                child: pw.Text(
                  'แบบรายงานผลการประเมินอันตราย การศึกษาผลกระทบของสภาพแวดล้อมในการทำงาน',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'ที่มีผลต่อลูกจ้าง แผนการดำเนินงานด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'และแผนควบคุมดูแลลูกจ้างและสถานประกอบกิจการ',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'ตามข้อ ๙ แห่งประกาศกระทรวงแรงงาน เรื่อง การประเมินอันตราย การศึกษาผลกระทบของสภาพแวดล้อม',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 10.5),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'ในการทำงาน และการจัดทำแผนควบคุมดูแลลูกจ้างและสถานประกอบกิจการ',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 10.5),
                ),
              ),
              pw.SizedBox(height: 12),

              // Section 1
              pw.Text(
                '๑. ข้าพเจ้า (นาย/นาง/นางสาว)  ${_val(company.employerName, 60)}  นายจ้าง',
                style: const pw.TextStyle(fontSize: 10.5),
              ),
              pw.SizedBox(height: 4),

              // Section 2
              pw.Text(
                '๒. ชื่อสถานประกอบกิจการ  ${_val(company.companyName, 70)}',
                style: const pw.TextStyle(fontSize: 10.5),
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.Text('    เลขทะเบียนนิติบุคคล  ${_val(company.taxId, 45)}', style: const pw.TextStyle(fontSize: 10.5)),
                  pw.Spacer(),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 6,
                    child: pw.Text('    ประเภทกิจการ  ${_val(company.businessCategoryTitle, 35)}', style: const pw.TextStyle(fontSize: 10.5)),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text('จำนวนลูกจ้าง  ${_val(company.employeeCount.toString(), 15)}  คน', style: const pw.TextStyle(fontSize: 10.5)),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),

              // Section 3
              pw.Text(
                '๓. ตั้งอยู่เลขที่  ${_val(company.addressNumber, 12)}  หมู่ที่  ${_val(company.moo, 10)}  ตรอก/ซอย  ${_val(company.soi, 20)}  ถนน  ${_val(company.road, 25)}',
                style: const pw.TextStyle(fontSize: 10.5),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '    ตำบล/แขวง  ${_val(company.subdistrict, 18)}  อำเภอ/เขต  ${_val(company.district, 18)}  จังหวัด  ${_val(company.province, 18)}  รหัสไปรษณีย์  ${_val(company.postalCode, 12)}',
                style: const pw.TextStyle(fontSize: 10.5),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '    โทรศัพท์  ${_val(company.phone, 20)}  โทรสาร  ${_val(company.fax, 20)}  โทรศัพท์มือถือ  ${_val(company.mobile, 22)}',
                style: const pw.TextStyle(fontSize: 10.5),
              ),
              pw.SizedBox(height: 8),

              // Section 4
              pw.Text(
                '๔. การรับรองโดยผู้มีคุณสมบัติเป็นผู้ชำนาญการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อม',
                style: const pw.TextStyle(fontSize: 10.5),
              ),
              pw.Text(
                '    ในการทำงานที่ได้รับใบอนุญาตจากกรมสวัสดิการและคุ้มครองแรงงาน',
                style: const pw.TextStyle(fontSize: 10.5),
              ),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(4.5),
                  1: pw.FlexColumnWidth(3.0),
                  2: pw.FlexColumnWidth(4.5),
                },
                children: [
                  pw.TableRow(
                    children: [
                      _headerCell('ชื่อ - นามสกุล\nผู้ชำนาญการฯ'),
                      _headerCell('เลขที่ใบอนุญาต'),
                      _headerCell('ระยะเวลาที่ได้รับใบอนุญาต\nตั้งแต่วันเดือนปี ถึง วันเดือนปี'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _bodyCell('๑) ${company.safetyExpertName ?? ""}'),
                      _bodyCell(company.safetyExpertLicenseNo ?? '', align: pw.TextAlign.center),
                      _bodyCell(
                        (company.safetyExpertValidFrom != null && company.safetyExpertValidTo != null)
                            ? '${company.safetyExpertValidFrom} ถึง ${company.safetyExpertValidTo}'
                            : '',
                        align: pw.TextAlign.center,
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _bodyCell('๒)'),
                      _bodyCell(''),
                      _bodyCell(''),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // Section 5
              pw.Text(
                '๕. วิธีการชี้บ่งอันตราย และวิธีการวิเคราะห์โอกาสและความรุนแรงเพื่อประเมินคะแนนความเป็นอันตราย',
                style: const pw.TextStyle(fontSize: 10.5),
              ),
              pw.Text(
                '    พร้อมทั้งจัดระดับอันตราย',
                style: const pw.TextStyle(fontSize: 10.5),
              ),
              pw.SizedBox(height: 4),

              // Radio Option 1
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(isJsa ? '( ✓ ) ' : '(   ) ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5)),
                  pw.Expanded(
                    child: pw.Text(
                      'วิธีการที่ใช้ (โปรดระบุ)  ${isJsa ? session.hazardIdMethod : "................................................................................................."}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 24),
                child: pw.Text(
                  isJsa && session.hazardIdMethodOther != null && session.hazardIdMethodOther!.isNotEmpty
                      ? session.hazardIdMethodOther!
                      : '........................................................................................................................................',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 2),

              // Radio Option 2
              pw.Row(
                children: [
                  pw.Text(isStandard ? '( ✓ ) ' : '(   ) ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5)),
                  pw.Expanded(
                    child: pw.Text(
                      'วิธีการอื่นใดที่เป็นไปตามมาตรฐานสากล (โปรดระบุ)  ${isStandard ? (session.hazardIdMethodOther ?? "") : "....................................................."}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),

              // Radio Option 3
              pw.Row(
                children: [
                  pw.Text(isGov ? '( ✓ ) ' : '(   ) ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5)),
                  pw.Expanded(
                    child: pw.Text(
                      'วิธีการอื่นที่หน่วยงานราชการยอมรับ (โปรดระบุ)  ${isGov ? (session.hazardIdMethodOther ?? "") : "..........................................................."}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),

              // Radio Option 4
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(isApproved ? '( ✓ ) ' : '(   ) ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5)),
                  pw.Expanded(
                    child: pw.Text(
                      'วิธีการอื่นใดที่อธิบดีกรมสวัสดิการและคุ้มครองแรงงานหรือผู้ซึ่งอธิบดีมอบหมายให้ความเห็นชอบ',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 24),
                child: pw.Text(
                  '(โปรดระบุ)  ${isApproved ? (session.hazardIdStandardApproved ?? session.hazardIdMethodOther ?? "") : "..................................................................................................................."}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 24),
                child: pw.Text(
                  'ได้รับความเห็นชอบวิธีการประเมินอันตราย จากอธิบดีหรือผู้ซึ่งอธิบดีมอบหมาย',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 24),
                child: pw.Text(
                  'ตามหนังสือ...................................เลขที่.................................ลงวันที่...................................',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 24),
                child: pw.Text(
                  'โดยได้แนบเอกสารให้ความเห็นชอบมาด้วยแล้ว',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('ลงชื่อ ..............................................................', style: const pw.TextStyle(fontSize: 10.5)),
                      pw.SizedBox(height: 2),
                      pw.Text('( ${_val(company.safetyExpertName, 30)} )', style: const pw.TextStyle(fontSize: 10.5)),
                      pw.SizedBox(height: 2),
                      pw.Text('ผู้ชำนาญการด้านความปลอดภัย', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('อาชีวอนามัย และสภาพแวดล้อมในการทำงาน', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('ลงชื่อ ..............................................................', style: const pw.TextStyle(fontSize: 10.5)),
                      pw.SizedBox(height: 2),
                      pw.Text('( ${_val(company.employerName, 30)} )', style: const pw.TextStyle(fontSize: 10.5)),
                      pw.SizedBox(height: 2),
                      pw.Text('นายจ้าง', style: const pw.TextStyle(fontSize: 10)),
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

    // =========================================================================
    // 2. แบบ ปอ. ๑ (Landscape A4: ตารางรายงานผลการประเมินอันตราย)
    // =========================================================================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('แบบ ปอ. ๑', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ],
              ),
              pw.Center(
                child: pw.Text(
                  'แบบรายงานผลการประเมินอันตรายและการศึกษาผลกระทบของสภาพแวดล้อมในการทำงานที่มีผลต่อลูกจ้าง',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 6),
              if (context.pageNumber == 1) ...[
                pw.Text(
                  '๑. วัน เดือน ปี ที่ดำเนินการประเมินอันตราย  ${_val(session.assessmentDate, 80)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 2),
                pw.Text('๒. ผู้ทำหน้าที่ในการประเมินอันตราย ประกอบด้วย', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  '    ๒.๑ ชื่อ-นามสกุล  ${_val(session.assessor1Name, 40)}  ตำแหน่ง  ${_val(session.assessor1Position, 45)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  '    ๒.๒ ชื่อ-นามสกุล  ${_val(session.assessor2Name, 40)}  ตำแหน่ง  ${_val(session.assessor2Position, 45)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '๓. วิธีการชี้บ่งอันตราย คือ  ${_val("${session.hazardIdMethod} ${session.hazardIdMethodOther ?? ''}", 80)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '๔. วิธีการวิเคราะห์โอกาสและความรุนแรงเพื่อประเมินระดับคะแนนความเป็นอันตราย พร้อมทั้งจัดระดับอันตราย คือ  ${_val("ตารางเมทริกซ์ ๓x๓ ตามประกาศกระทรวงแรงงาน ๒๕๖๗", 60)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 2),
                pw.Text('๕. ผลการประเมินอันตราย', style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 4),
              ],
            ],
          );
        },
        build: (context) {
          final displayRows = List<PorReportRowData>.from(rows);
          // ถ้ามีน้อยกว่า 5 แถว ให้เติมแถวว่างให้เหมือนแบบฟอร์มจริง
          final emptyCount = 5 - displayRows.length;

          return [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(0.8), // ลำดับที่
                1: pw.FlexColumnWidth(2.2), // พื้นที่ปฏิบัติงาน
                2: pw.FlexColumnWidth(2.2), // ขั้นตอนงาน
                3: pw.FlexColumnWidth(2.0), // สิ่งอันตราย
                4: pw.FlexColumnWidth(2.0), // ผลกระทบ
                5: pw.FlexColumnWidth(2.0), // มาตรการป้องกันเดิม
                6: pw.FlexColumnWidth(2.0), // ข้อเสนอแนะ
                7: pw.FlexColumnWidth(0.9), // โอกาส
                8: pw.FlexColumnWidth(0.9), // รุนแรง
                9: pw.FlexColumnWidth(1.1), // คะแนน
                10: pw.FlexColumnWidth(1.2), // ระดับอันตราย
              },
              children: [
                // Header Tier 1
                pw.TableRow(
                  children: [
                    _por1Th('ลำดับที่'),
                    _por1Th('พื้นที่ปฏิบัติงาน\n(แผนก/ฝ่าย) /\nจำนวนลูกจ้าง (คน)'),
                    _por1Th('ขั้นตอน\nและวิธีการปฏิบัติงาน'),
                    _por1Th('สิ่งและลักษณะ\nอันตราย'),
                    _por1Th('ผลกระทบ\nที่อาจเกิดขึ้น'),
                    _por1Th('มาตรการป้องกัน\nและควบคุม\nอันตราย'),
                    _por1Th('ข้อเสนอแนะ'),
                    _por1ThSub('การประเมินความเป็นอันตราย', colspan: 4),
                  ],
                ),
                // Header Tier 2
                pw.TableRow(
                  children: [
                    _emptyHeaderCell(),
                    _emptyHeaderCell(),
                    _emptyHeaderCell(),
                    _emptyHeaderCell(),
                    _emptyHeaderCell(),
                    _emptyHeaderCell(),
                    _emptyHeaderCell(),
                    _por1Th('โอกาส'),
                    _por1Th('ความ\nรุนแรง'),
                    _por1Th('ผลคะแนน\nความเป็น\nอันตราย'),
                    _por1Th('ระดับ\nอันตราย'),
                  ],
                ),
                // Data Rows
                ...displayRows.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final r = entry.value;

                  return pw.TableRow(
                    children: [
                      _por1Cell('$idx', align: pw.TextAlign.center),
                      _por1Cell('${r.workstation.stationName}\n(${r.workstation.departmentName} / ${r.workstation.employeeCount} คน)'),
                      _por1Cell(r.stepItem.stepName),
                      _por1Cell(r.hazard.hazardItemTitle),
                      _por1Cell(r.hazard.potentialConsequences),
                      _por1Cell(r.hazard.existingControlMeasures ?? '-'),
                      _por1Cell(r.hazard.recommendation ?? '-'),
                      _por1Cell('${r.hazard.likelihoodScore}', align: pw.TextAlign.center),
                      _por1Cell('${r.hazard.severityScore}', align: pw.TextAlign.center),
                      _por1Cell('${r.hazard.riskScore}', align: pw.TextAlign.center),
                      _por1Cell(r.hazard.riskLevelThai, align: pw.TextAlign.center),
                    ],
                  );
                }),
                if (emptyCount > 0)
                  ...List.generate(emptyCount, (index) {
                    return pw.TableRow(
                      children: List.generate(11, (_) => _por1Cell('')),
                    );
                  }),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'หมายเหตุ ข้อมูลและรายละเอียดการประเมินอันตรายและการศึกษาผลกระทบ สามารถจัดทำเป็นเอกสารแนบได้',
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'สรุปความเห็นของผู้ชำนาญการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน  ${_val(session.expertOpinion, 90)}',
              style: const pw.TextStyle(fontSize: 9.5),
            ),
            pw.Text(
              '....................................................................................................................................................................................................',
              style: const pw.TextStyle(fontSize: 9.5),
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('รับรองโดย ลงชื่อ..............................................................', style: const pw.TextStyle(fontSize: 9.5)),
                    pw.SizedBox(height: 2),
                    pw.Text('( ${_val(company.safetyExpertName, 35)} )', style: const pw.TextStyle(fontSize: 9.5)),
                    pw.SizedBox(height: 2),
                    pw.Text('ผู้ชำนาญการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ลงชื่อ..............................................................', style: const pw.TextStyle(fontSize: 9.5)),
                    pw.SizedBox(height: 2),
                    pw.Text('( ${_val(company.employerName, 35)} )', style: const pw.TextStyle(fontSize: 9.5)),
                    pw.SizedBox(height: 2),
                    pw.Text('นายจ้าง', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    // =========================================================================
    // 3. แบบ ปอ. ๒ (Landscape A4: แผนดำเนินงานด้านความปลอดภัยฯ)
    // =========================================================================
    final por2Rows = rows.where((r) => r.hazard.requiresPor2).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('แบบ ปอ. ๒', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ],
              ),
              pw.Center(
                child: pw.Text('แบบรายงาน', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
              pw.Center(
                child: pw.Text(
                  'แผนดำเนินงานด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน และแผนการควบคุมดูแลลูกจ้างและสถานประกอบกิจการ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 6),
              if (context.pageNumber == 1) ...[
                pw.Text(
                  'วัน เดือน ปี ที่ทำการศึกษาทบทวนแผนการดำเนินงานของสถานประกอบกิจการ  ${_val(session.assessmentDate, 70)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
              ],
            ],
          );
        },
        build: (context) {
          final displayRows = List<PorReportRowData>.from(por2Rows);
          final emptyCount = 5 - displayRows.length;

          return [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(0.8), // ลำดับที่
                1: pw.FlexColumnWidth(2.5), // พื้นที่ปฏิบัติงาน
                2: pw.FlexColumnWidth(2.5), // ขั้นตอนงาน
                3: pw.FlexColumnWidth(1.5), // ระดับอันตราย
                4: pw.FlexColumnWidth(4.5), // แผนการดำเนินงานเพื่อลดอันตราย
                5: pw.FlexColumnWidth(2.2), // ระยะเวลาดำเนินการ
                6: pw.FlexColumnWidth(1.8), // ผู้รับผิดชอบ
                7: pw.FlexColumnWidth(1.8), // ผู้ตรวจติดตาม
              },
              children: [
                pw.TableRow(
                  children: [
                    _por2Th('ลำดับที่'),
                    _por2Th('พื้นที่ปฏิบัติงาน (แผนก/ฝ่าย) /\nจำนวนลูกจ้าง (คน)'),
                    _por2Th('ขั้นตอน\nและวิธีการปฏิบัติงาน'),
                    _por2Th('ระดับอันตราย'),
                    _por2Th('แผนการดำเนินงานเพื่อลดและควบคุมความเป็นอันตราย\n(มาตรการ/กิจกรรม หรือขั้นตอนเพื่อลดความเป็นอันตราย\nและหลักเกณฑ์หรือมาตรฐานที่ใช้ควบคุม)'),
                    _por2Th('ระยะเวลาดำเนินการ\n(ตั้งแต่.....ถึง......)'),
                    _por2Th('ผู้รับผิดชอบ'),
                    _por2Th('ผู้ตรวจติดตาม'),
                  ],
                ),
                ...displayRows.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final r = entry.value;

                  return pw.TableRow(
                    children: [
                      _por2Cell('$idx', align: pw.TextAlign.center),
                      _por2Cell('${r.workstation.stationName}\n(${r.workstation.departmentName} / ${r.workstation.employeeCount} คน)'),
                      _por2Cell(r.stepItem.stepName),
                      _por2Cell(r.hazard.riskLevelThai, align: pw.TextAlign.center),
                      _por2Cell(r.plan?.controlPlanDescription ?? r.hazard.recommendation ?? '-'),
                      _por2Cell(((r.plan?.startDate != null && r.plan?.endDate != null) ? '${r.plan!.startDate}\nถึง ${r.plan!.endDate}' : '-'), align: pw.TextAlign.center),
                      _por2Cell(r.plan?.responsiblePerson ?? '-', align: pw.TextAlign.center),
                      _por2Cell(r.plan?.supervisorMonitor ?? '-', align: pw.TextAlign.center),
                    ],
                  );
                }),
                if (emptyCount > 0)
                  ...List.generate(emptyCount, (index) {
                    return pw.TableRow(
                      children: List.generate(8, (_) => _por2Cell('')),
                    );
                  }),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'หมายเหตุ ข้อมูลและรายละเอียดแผนดำเนินงานด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน และแผนควบคุมดูแลลูกจ้างและสถานประกอบกิจการ สามารถจัดทำเป็นเอกสารแนบได้',
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'สรุปความเห็นของผู้ชำนาญการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน  ${_val(session.expertOpinion, 90)}',
              style: const pw.TextStyle(fontSize: 9.5),
            ),
            pw.Text(
              '....................................................................................................................................................................................................',
              style: const pw.TextStyle(fontSize: 9.5),
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('รับรองโดย ลงชื่อ..............................................................', style: const pw.TextStyle(fontSize: 9.5)),
                    pw.SizedBox(height: 2),
                    pw.Text('( ${_val(company.safetyExpertName, 35)} )', style: const pw.TextStyle(fontSize: 9.5)),
                    pw.SizedBox(height: 2),
                    pw.Text('ผู้ชำนาญการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ลงชื่อ..............................................................', style: const pw.TextStyle(fontSize: 9.5)),
                    pw.SizedBox(height: 2),
                    pw.Text('( ${_val(company.employerName, 35)} )', style: const pw.TextStyle(fontSize: 9.5)),
                    pw.SizedBox(height: 2),
                    pw.Text('นายจ้าง', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // --------------------------------------------------------------------------
  // HELPER WIDGETS
  // --------------------------------------------------------------------------
  static String _val(String? val, int dotCount) {
    if (val != null && val.trim().isNotEmpty) {
      return val.trim();
    }
    return '.' * dotCount;
  }

  static pw.Widget _headerCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
      ),
    );
  }

  static pw.Widget _bodyCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      alignment: align == pw.TextAlign.center ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(fontSize: 9.5),
      ),
    );
  }

  static pw.Widget _por1Th(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5),
      ),
    );
  }

  static pw.Widget _por1ThSub(String text, {int colspan = 1}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5),
      ),
    );
  }

  static pw.Widget _emptyHeaderCell() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      alignment: pw.Alignment.center,
    );
  }

  static pw.Widget _por1Cell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: align == pw.TextAlign.center ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(fontSize: 8.5),
      ),
    );
  }

  static pw.Widget _por2Th(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5),
      ),
    );
  }

  static pw.Widget _por2Cell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: align == pw.TextAlign.center ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(fontSize: 8.5),
      ),
    );
  }
}
