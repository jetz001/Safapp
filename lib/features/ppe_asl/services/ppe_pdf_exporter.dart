import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/models/ppe_transaction_model.dart';

class PpePdfExporter {
  static Future<String> _getExportDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }

  /// สร้างใบบันทึกการแจกจ่าย PPE รายบุคคล ตาม พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ มาตรา ๒๒
  static Future<void> exportIndividualIssueCard(
    List<PpeTransaction> txs,
    BuildContext context, {
    String companyName = 'สถานประกอบกิจการ',
  }) async {
    try {
      final doc = pw.Document(
        title: 'ใบบันทึกการแจกจ่ายอุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล (PPE)',
        author: 'เจ้าหน้าที่ความปลอดภัยในการทำงาน (จป.)',
      );

      final outTransactions = txs.where((t) => t.transactionType == PpeTransactionType.stockOut).toList();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                companyName,
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'ใบบันทึกการแจกจ่ายอุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล (PPE Individual Issue Record)',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'หลักฐานการจัดหาและดูแลการสวมใส่ ตามพระราชบัญญัติความปลอดภัยฯ พ.ศ. ๒๕๕๔ มาตรา ๒๒',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),
            ],
          ),
          footer: (ctx) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'ระบบบริหารความปลอดภัย SAFAPP - โมดูล PPE & ASL (มาตรา ๒๒)',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
              pw.Text(
                'หน้า ${ctx.pageNumber} จาก ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          build: (ctx) => [
            // Statutory notice box
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                color: PdfColors.blue50,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ข้อกำหนด พ.ร.บ. ความปลอดภัยฯ พ.ศ. ๒๕๕๔ มาตรา ๒๒:',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                  pw.Text(
                    'นายจ้างมีหน้าที่จัดหาอุปกรณ์ PPE ที่ได้มาตรฐาน และลูกจ้างมีหน้าที่สวมใส่ตลอดเวลาปฏิบัติงาน หากไม่สวมใส่นายจ้างมีอำนาจสั่งหยุดงานได้',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue800),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Summary table of issuances
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2), // Date
                1: const pw.FlexColumnWidth(1.5), // Recipient
                2: const pw.FlexColumnWidth(1.2), // Dept
                3: const pw.FlexColumnWidth(2.5), // PPE Item
                4: const pw.FlexColumnWidth(0.8), // Qty
                5: const pw.FlexColumnWidth(1.5), // Ref (CPO/PTW)
                6: const pw.FlexColumnWidth(1.3), // Signature
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cellHeader('วันที่'),
                    _cellHeader('ชื่อผู้รับมอบ'),
                    _cellHeader('แผนก'),
                    _cellHeader('รายการอุปกรณ์ PPE'),
                    _cellHeader('จำนวน'),
                    _cellHeader('อ้างอิง'),
                    _cellHeader('ลงชื่อผู้รับ'),
                  ],
                ),
                ...outTransactions.map((tx) {
                  return pw.TableRow(
                    children: [
                      _cellText(tx.transactionDate),
                      _cellText(tx.recipientName ?? '-'),
                      _cellText(tx.department ?? '-'),
                      _cellText('${tx.ppeCode} ${tx.ppeName}'),
                      _cellText('${tx.quantity}', alignCenter: true),
                      _cellText(tx.cpoMeetingRef ?? tx.ptwRef ?? '-'),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: pw.Center(
                          child: pw.Text(
                            '...........................',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),

            // Signatures block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.SizedBox(height: 24),
                    pw.Text('ลงชื่อ ...........................................................', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 4),
                    pw.Text('(...........................................................)', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 2),
                    pw.Text('ผู้จ่ายอุปกรณ์ / เจ้าหน้าที่คลัง', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.Text('วันที่ ......./......./...........', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.SizedBox(height: 24),
                    pw.Text('ลงชื่อ ...........................................................', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 4),
                    pw.Text('(...........................................................)', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 2),
                    pw.Text('เจ้าหน้าที่ความปลอดภัยในการทำงาน (จป.วิชาชีพ)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.Text('วันที่ ......./......./...........', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      final dirPath = await _getExportDirectory();
      final fileName = 'PPE_Issue_Card_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(p.join(dirPath, fileName));
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('สร้างไฟล์เอกสาร PDF สำเร็จ: ${file.path}'),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้าง PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static pw.Widget _cellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _cellText(String text, {bool alignCenter = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8),
        textAlign: alignCenter ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }
}
