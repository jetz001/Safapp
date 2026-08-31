import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/models/contractor_models.dart';

class SafetyPassPdfService {
  /// สร้าง PDF บัตร Safety Pass และสั่งพิมพ์ผ่าน Windows Print Dialog / Preview ทันที
  static Future<void> printSafetyPass(BuildContext context, ContractorWorker worker) async {
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

      // Load worker photo if exists
      pw.MemoryImage? workerPhoto;
      if (worker.photoPath != null) {
        final photoFile = File(worker.photoPath!);
        if (photoFile.existsSync()) {
          try {
            final bytes = photoFile.readAsBytesSync();
            workerPhoto = pw.MemoryImage(bytes);
          } catch (_) {}
        }
      }

      // Card dimensions: Standard CR-80 ID Card / Badge (85.6mm x 54mm or 242pt x 153pt) on A4
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title Header on Paper
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ระบบพิมพ์บัตรอนุญาตเข้าปฏิบัติงาน (Safety Induction Pass)',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.Text(
                      'SAFAPP Safety Superapp',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 16),

                pw.Text(
                  'ตัดตามเส้นประเพื่อใส่ซองบัตรประจำตัว (CR-80 Badge Size):',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 12),

                // Front & Back Cards Side by Side
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    // --------------------------------------------------------
                    // 1. FRONT SIDE BADGE (ด้านหน้าบัตร)
                    // --------------------------------------------------------
                    _buildFrontBadge(worker, workerPhoto),
                    pw.SizedBox(width: 24),

                    // --------------------------------------------------------
                    // 2. BACK SIDE BADGE (ด้านหลังบัตร - ข้อกำหนดความปลอดภัย)
                    // --------------------------------------------------------
                    _buildBackBadge(worker),
                  ],
                ),

                pw.SizedBox(height: 30),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'คำแนะนำสำหรับเจ้าหน้าที่ความปลอดภัย (จป.) / ผู้ควบคุมงาน:',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('๑. ตรวจสอบบัตรนี้ร่วมกับบัตรประจำตัวประชาชนหรือใบอนุญาตทำงานก่อนเข้าพื้นที่', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('๒. หากบัตรหมดอายุ หรือพบการฝ่าฝืนมาตรการความปลอดภัย เจ้าหน้าที่มีสิทธิ์ระงับการทำงานทันที', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('๓. บัตรนี้เป็นกรรมสิทธิ์ของสถานประกอบการ ต้องส่งคืนเมื่อสิ้นสุดระยะเวลาสัญญาจ้าง', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Trigger Windows / Native Print Preview directly
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'SafetyPass_${worker.workerName.replaceAll(" ", "_")}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการพิมพ์บัตร: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static pw.Widget _buildFrontBadge(ContractorWorker worker, pw.MemoryImage? photo) {
    final status = worker.inductionStatus;
    final statusColor = status == 'VALID'
        ? PdfColors.green700
        : status == 'EXPIRING_SOON'
            ? PdfColors.orange700
            : PdfColors.red700;

    final statusLabel = status == 'VALID'
        ? 'ผ่านการอบรมความปลอดภัย (ACTIVE)'
        : status == 'EXPIRING_SOON'
            ? 'ใกล้หมดอายุ (EXPIRING SOON)'
            : 'บัตรหมดอายุ (EXPIRED)';

    return pw.Container(
      width: 230,
      height: 330,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.blue900, width: 1.5),
      ),
      child: pw.Column(
        children: [
          // Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'SAFETY PASS',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.amber),
                ),
                pw.Text(
                  'บัตรอนุญาตเข้าปฏิบัติงานผู้รับเหมา',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
              ],
            ),
          ),

          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              children: [
                // Photo box
                pw.Container(
                  width: 75,
                  height: 90,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: photo != null
                      ? pw.ClipRRect(
                          horizontalRadius: 5,
                          verticalRadius: 5,
                          child: pw.Image(photo, fit: pw.BoxFit.cover),
                        )
                      : pw.Center(
                          child: pw.Text('รูปถ่าย\nผู้รับเหมา', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        ),
                ),
                pw.SizedBox(height: 8),

                // Name & Role
                pw.Text(
                  worker.workerName,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                ),
                pw.SizedBox(height: 2),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.blue200),
                  ),
                  child: pw.Text(
                    worker.jobRole,
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                ),
                pw.SizedBox(height: 6),

                // Company & ID
                pw.Text(
                  'บริษัท: ${worker.contractorName ?? "ผู้รับเหมา"}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                ),
                if (worker.nationalIdOrPassport != null)
                  pw.Text(
                    'ID: ${worker.nationalIdOrPassport}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                pw.SizedBox(height: 8),

                // Status Strip
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: statusColor,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    statusLabel,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  ),
                ),
                pw.SizedBox(height: 6),

                // Dates
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('อบรม: ${worker.inductionDate ?? "-"}', style: const pw.TextStyle(fontSize: 7.5)),
                    pw.Text('หมดอายุ: ${worker.inductionValidUntil ?? "-"}', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBackBadge(ContractorWorker worker) {
    return pw.Container(
      width: 230,
      height: 330,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.blue900, width: 1.5),
      ),
      child: pw.Column(
        children: [
          // Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey800,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Center(
              child: pw.Text(
                'ข้อปฏิบัติความปลอดภัย (SAFETY RULES)',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              ),
            ),
          ),

          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildRuleItem('๑. ติดบัตรนี้ไว้ในตำแหน่งที่มองเห็นได้ชัดเจนตลอดเวลา'),
                _buildRuleItem('๒. สวมใส่อุปกรณ์ PPE (หมวกนิรภัย, รองเท้านิรภัย, แว่นตา) ครบถ้วน'),
                _buildRuleItem('๓. งานอันตรายสูงต้องมีใบอนุญาตทำงาน (PTW) ก่อนเริ่มงาน'),
                _buildRuleItem('๔. ห้ามสูบบุหรี่ หรือก่อประกายไฟในพื้นที่หวงห้ามเด็ดขาด'),
                _buildRuleItem('๕. หากเกิดเหตุฉุกเฉิน ให้ปฏิบัติตามสัญญาณเตือนภัยทันที'),
                pw.SizedBox(height: 12),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 6),

                // Emergency Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.red200),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('เบอร์โทรฉุกเฉินโรงงาน (EMERGENCY):', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                      pw.SizedBox(height: 2),
                      pw.Text('• ห้องพยาบาล / จป. ประจำโรงงาน', style: const pw.TextStyle(fontSize: 7.5)),
                      pw.Text('• แจ้งเหตุด่วน / เพลิงไหม้: โทร ๑๙๙ / ๑๖๖๙', style: const pw.TextStyle(fontSize: 7.5)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // Barcode / QR placeholder
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: 'SAFAPP-${worker.id ?? 1000}',
                    width: 130,
                    height: 28,
                    drawText: true,
                    textStyle: const pw.TextStyle(fontSize: 7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRuleItem(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
      ),
    );
  }
}
