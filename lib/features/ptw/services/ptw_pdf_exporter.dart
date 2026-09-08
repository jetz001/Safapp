import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../data/models/ptw_model.dart';
import '../domain/enums/high_risk_type.dart';

/// Official PTW PDF Generator Service
/// Generates a structured, print-ready PDF for the Permit to Work
class PtwPdfExporter {
  /// Generate PDF bytes from a [PtwModel]
  Future<Uint8List> generatePdf(PtwModel ptw) async {
    final doc = pw.Document(
      title: 'ใบอนุญาตทำงาน ${ptw.ptwNumber}',
      author: ptw.applicantName,
      subject: 'Permit to Work - ${ptw.workTitle}',
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        ),
        header: (context) => _buildHeader(ptw),
        footer: (context) => _buildFooter(context, ptw),
        build: (context) => [
          _buildGeneralInfo(ptw),
          pw.SizedBox(height: 12),
          _buildWorkersSection(ptw),
          pw.SizedBox(height: 12),
          _buildSafetyControlsSection(ptw),
          pw.SizedBox(height: 12),
          _buildChecklistSection(ptw),
          pw.SizedBox(height: 12),
          _buildSignaturesSection(ptw),
        ],
      ),
    );

    return doc.save();
  }

  /// Save PDF to app documents directory and return file path
  Future<String> savePdf(PtwModel ptw) async {
    final bytes = await generatePdf(ptw);
    final dir = await getApplicationDocumentsDirectory();
    final ptwDir = Directory('${dir.path}/ptw_pdfs');
    if (!ptwDir.existsSync()) ptwDir.createSync(recursive: true);
    final sanitizedNumber = ptw.ptwNumber.replaceAll(RegExp(r'[^\w\-]'), '_');
    final file = File('${ptwDir.path}/PTW_$sanitizedNumber.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // ── Header ────────────────────────────────────────────────────────────────

  pw.Widget _buildHeader(PtwModel ptw) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.orange700, width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: Title block
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ใบอนุญาตทำงาน (Permit to Work)',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange700,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  ptw.workTitle,
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    _headerChip('เลขที่', ptw.ptwNumber),
                    pw.SizedBox(width: 10),
                    _headerChip('สถานะ', ptw.status.labelEn),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          // Right: QR Code
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              _buildQrCode(ptw.ptwNumber, size: 64),
              pw.SizedBox(height: 4),
              pw.Text(ptw.ptwNumber, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _headerChip(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.orange200),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$label: ', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.TextSpan(
                text: value,
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
          ],
        ),
      ),
    );
  }

  // ── QR Code Generator ─────────────────────────────────────────────────────

  pw.Widget _buildQrCode(String data, {double size = 80}) {
    // Generate QR matrix using the qr package
    try {
      // We use a simple URL-safe approach: encode the PTW number into a QR-like grid
      // Since direct qr package integration needs code generation, we build a visual QR placeholder
      // In production, use qr_flutter or pw.BarcodeWidget for actual QR
      final qrData = 'PTW:$data';
      return pw.BarcodeWidget(
        barcode: pw.Barcode.qrCode(),
        data: qrData,
        width: size,
        height: size,
        drawText: false,
        color: PdfColors.black,
      );
    } catch (e) {
      // Fallback: text-only placeholder if QR generation fails
      return pw.Container(
        width: size,
        height: size,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Center(
          child: pw.Text('QR\n${data.length > 12 ? data.substring(0, 12) : data}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              textAlign: pw.TextAlign.center),
        ),
      );
    }
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  pw.Widget _buildFooter(pw.Context context, PtwModel ptw) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'PTW: ${ptw.ptwNumber} | ${ptw.primaryRiskType.labelEn} | ${ptw.applicantDepartment}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'หน้าที่ ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'พิมพ์เมื่อ: ${DateTime.now().toIso8601String().substring(0, 16).replaceAll('T', ' ')}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // ── Section 1: General Information ───────────────────────────────────────

  pw.Widget _buildGeneralInfo(PtwModel ptw) {
    final riskColor = _pdfColorForRisk(ptw.primaryRiskType);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('1. ข้อมูลทั่วไป (General Information)', riskColor),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            _tableRow('ประเภทงาน', ptw.primaryRiskType.labelTh, 'กฎหมายที่เกี่ยวข้อง', ptw.primaryRiskType.legalRefTh),
            _tableRow('สถานที่', ptw.plantArea, 'ตำแหน่ง', ptw.specificLocation),
            _tableRow(
              'วันเริ่มต้น',
              '${ptw.workStartDate} ${ptw.workStartTime} น.',
              'วันสิ้นสุด',
              '${ptw.workEndDate} ${ptw.workEndTime} น.',
            ),
            _tableRow('ผู้ขออนุญาต', ptw.applicantName, 'แผนก/บริษัท', ptw.applicantDepartment),
            _tableRow('โทรศัพท์', ptw.applicantPhone, 'ประเภทผู้ขอ',
                ptw.applicantType == 'CONTRACTOR' ? 'ผู้รับเหมา' : 'พนักงานบริษัท'),
            _tableRow('เลขอ้างอิง JSA', ptw.jsaReferenceNo ?? '-', 'วันที่ขอ', ptw.requestDate),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('รายละเอียดงาน:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 3),
              pw.Text(ptw.workDescription, style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
        if (ptw.secondaryRiskTypes.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Text('ความเสี่ยงร่วม: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ...ptw.secondaryRiskTypes.map((r) => pw.Container(
                    margin: const pw.EdgeInsets.only(right: 4),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.orange100,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Text(r.labelTh, style: const pw.TextStyle(fontSize: 8)),
                  )),
            ],
          ),
        ],
      ],
    );
  }

  // ── Section 2: Workers ────────────────────────────────────────────────────

  pw.Widget _buildWorkersSection(PtwModel ptw) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('2. ผู้ปฏิบัติงาน (Personnel)', PdfColors.blue700),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Row(
            children: [
              pw.Text('จำนวนผู้ปฏิบัติงานทั้งหมด: ', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.Text('${ptw.workerCount} คน', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        if (ptw.workerNames.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Wrap(
            spacing: 6,
            runSpacing: 4,
            children: ptw.workerNames.asMap().entries.map((e) {
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue200),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text('${e.key + 1}. ${e.value}', style: const pw.TextStyle(fontSize: 9)),
              );
            }).toList(),
          ),
        ],
        // Confined roles
        if (ptw.confinedRoles.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text('ผู้มีหน้าที่ 4 ฝ่าย (ที่อับอากาศ):',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.purple100),
                children: ['บทบาท', 'ชื่อ-สกุล', 'เลขที่ใบรับรอง', 'วันหมดอายุ'].map((h) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(h, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  );
                }).toList(),
              ),
              ...ptw.confinedRoles.map((r) {
                return pw.TableRow(
                  children: [
                    r.roleType.labelTh,
                    r.personName,
                    r.certNumber,
                    r.certExpiryDate,
                  ].map((cell) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(cell, style: const pw.TextStyle(fontSize: 8)),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ],
      ],
    );
  }

  // ── Section 3: Safety Controls ─────────────────────────────────────────────

  pw.Widget _buildSafetyControlsSection(PtwModel ptw) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('3. มาตรการควบคุมความปลอดภัย (Safety Controls)', PdfColors.green700),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {0: const pw.FlexColumnWidth(1), 1: const pw.FlexColumnWidth(2)},
          children: [
            _tableRow2('แผนฉุกเฉิน', ptw.emergencyRescuePlan),
            _tableRow2('รายการ PPE ที่จำเป็น', ptw.requiredPpeList),
            if (ptw.specialPrecautions.isNotEmpty) _tableRow2('มาตรการพิเศษ', ptw.specialPrecautions),
          ],
        ),
        // Gas Test Summary
        if (ptw.gasTestLogs.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text('ผลการตรวจวัดก๊าซล่าสุด:',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 3),
          () {
            final last = ptw.gasTestLogs.last;
            return pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: last.isSafe ? PdfColors.green50 : PdfColors.red50,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: last.isSafe ? PdfColors.green200 : PdfColors.red200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _gasReading('O₂', '${last.oxygenPercent}%', last.oxygenPercent >= 19.5 && last.oxygenPercent <= 23.5),
                  _gasReading('LEL', '${last.combustiblePercentLel}%', last.combustiblePercentLel < 10),
                  _gasReading('CO', '${last.carbonMonoxidePpm}ppm', last.carbonMonoxidePpm < 25),
                  _gasReading('H₂S', '${last.hydrogenSulfidePpm}ppm', last.hydrogenSulfidePpm < 10),
                  pw.Text(
                    last.isSafe ? 'ปลอดภัย ✓' : 'อันตราย ✗',
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: last.isSafe ? PdfColors.green700 : PdfColors.red700),
                  ),
                ],
              ),
            );
          }(),
        ],
        // LOTO Summary
        if (ptw.lotoIsolations.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text('จุดตัดแยกพลังงาน LOTO:',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 3),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.amber100),
                children: ['Tag No.', 'ชื่ออุปกรณ์', 'พลังงาน', 'ยืนยัน'].map((h) => pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(h, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    )).toList(),
              ),
              ...ptw.lotoIsolations.map((l) => pw.TableRow(
                    children: [
                      l.equipmentTagNo,
                      l.equipmentName,
                      l.energyType.labelEn,
                      l.isZeroEnergyVerified ? 'YES ✓' : 'NO ✗',
                    ].map((cell) => pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(cell, style: const pw.TextStyle(fontSize: 8)),
                        )).toList(),
                  )),
            ],
          ),
        ],
      ],
    );
  }

  pw.Widget _gasReading(String label, String value, bool isOk) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold, color: isOk ? PdfColors.green700 : PdfColors.red700)),
      ],
    );
  }

  // ── Section 4: Checklist ──────────────────────────────────────────────────

  pw.Widget _buildChecklistSection(PtwModel ptw) {
    if (ptw.checklistItems.isEmpty) return pw.SizedBox();

    final passed = ptw.checklistItems.where((c) => c.result == 'YES').length;
    final total = ptw.checklistItems.length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('4. รายการตรวจสอบ ($passed/$total ผ่าน)', PdfColors.indigo700),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FixedColumnWidth(70),
            1: const pw.FlexColumnWidth(4),
            2: const pw.FixedColumnWidth(40),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.indigo100),
              children: ['รหัส', 'รายการตรวจสอบ', 'ผล'].map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(h, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  )).toList(),
            ),
            ...ptw.checklistItems.map((item) {
              final resultColor = item.result == 'YES'
                  ? PdfColors.green700
                  : item.result == 'NO'
                      ? PdfColors.red700
                      : PdfColors.grey;

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: item.result == 'YES'
                      ? PdfColors.green50
                      : item.result == 'NO'
                          ? PdfColors.red50
                          : null,
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(item.itemId, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(item.questionTh, style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(item.questionEn, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      item.result ?? '-',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: resultColor),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  // ── Section 5: Signatures ─────────────────────────────────────────────────

  pw.Widget _buildSignaturesSection(PtwModel ptw) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('5. ลายมือชื่อผู้เกี่ยวข้อง 4 ฝ่าย (Signatures)', PdfColors.deepPurple700),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.deepPurple50),
              children: [
                _signatureCell(
                  role: '1. ผู้ขออนุญาต',
                  name: ptw.applicantName,
                  signedAt: ptw.applicantSignedAt,
                  hasSignature: ptw.applicantSignaturePath != null,
                ),
                _signatureCell(
                  role: '2. จป.วิชาชีพ',
                  name: ptw.safetyOfficerName ?? '-',
                  signedAt: ptw.safetyOfficerSignedAt,
                  hasSignature: ptw.safetyOfficerSignaturePath != null,
                ),
                _signatureCell(
                  role: '3. ผู้อนุญาต',
                  name: ptw.authorizerName ?? '-',
                  signedAt: ptw.authorizerSignedAt,
                  hasSignature: ptw.authorizerSignaturePath != null,
                ),
                _signatureCell(
                  role: '4. ผู้รับมอบงาน',
                  name: '-',
                  signedAt: ptw.handoverSignedAt,
                  hasSignature: ptw.handoverSignaturePath != null,
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.orange50,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.orange200),
          ),
          child: pw.Text(
            'เอกสารฉบับนี้ออกโดยระบบ SAFAPP — ระบบใบอนุญาตทำงาน (PTW) ตามมาตรฐานความปลอดภัยไทย พ.ร.บ. ๒๕๕๔ และกฎกระทรวงที่เกี่ยวข้อง\n'
            'Document generated by SAFAPP PTW System | PTW: ${ptw.ptwNumber} | '
            'Risk: ${ptw.primaryRiskType.labelEn} | Status: ${ptw.status.labelEn}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.orange900),
          ),
        ),
      ],
    );
  }

  pw.Widget _signatureCell({
    required String role,
    required String name,
    required String? signedAt,
    required bool hasSignature,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(role, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 30), // Signature space
          pw.Container(
            height: 1,
            width: double.infinity,
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(name, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(
            hasSignature ? (signedAt?.substring(0, 10) ?? '(ลงนามแล้ว)') : '(ยังไม่ลงนาม)',
            style: pw.TextStyle(
              fontSize: 8,
              color: hasSignature ? PdfColors.green700 : PdfColors.red400,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Methods ────────────────────────────────────────────────────────

  pw.Widget _sectionTitle(String title, PdfColor color) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
      ),
    );
  }

  pw.TableRow _tableRow(String label1, String val1, String label2, String val2) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(label1, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(val1, style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(label2, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(val2, style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    );
  }

  pw.TableRow _tableRow2(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    );
  }

  PdfColor _pdfColorForRisk(HighRiskType risk) {
    switch (risk) {
      case HighRiskType.hotWork:
        return PdfColors.red700;
      case HighRiskType.confinedSpace:
        return PdfColors.purple700;
      case HighRiskType.workingAtHeight:
        return PdfColors.blue700;
      case HighRiskType.electricalLoto:
        return PdfColors.amber700;
      case HighRiskType.excavationLifting:
        return PdfColors.green700;
    }
  }
}
