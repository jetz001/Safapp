import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../data/models/manual_chapter_model.dart';

class SafetyManualPdfExporter {
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

  static Future<String> _getExportDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }

  // =========================================================================
  // 1. TIER 1: MASTER SAFETY MANUAL (เล่มรวมข้อบังคับความปลอดภัย)
  // =========================================================================
  static Future<Uint8List> generateMasterManualBytes({
    required List<ManualChapterModel> chapters,
    String companyName = 'สถานประกอบกิจการ',
  }) async {
    final doc = pw.Document(
      title: 'คู่มือและข้อบังคับความปลอดภัยฯ - $companyName',
      author: 'Safapp EHS System (มาตรา ๑๓)',
    );

    final theme = await _buildTheme();

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        ),
        header: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 6),
          margin: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue800, width: 1.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'คู่มือและข้อบังคับว่าด้วยความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
              ),
              pw.Text(
                companyName,
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 6),
          margin: const pw.EdgeInsets.only(top: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'พ.ร.บ. ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔ มาตรา ๑๓',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'หน้า ${ctx.pageNumber} จาก ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (ctx) => [
          // Cover Banner
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.blue300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  companyName,
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'คู่มือและข้อบังคับว่าด้วยความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Occupational Safety, Health and Environment Manual & Statutory Regulations',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'จัดทำขึ้นตามมาตรา ๑๓ แห่งพระราชบัญญัติความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔ และกฎหมายที่เกี่ยวข้อง ลูกจ้างทุกระดับ ผู้รับเหมา และผู้มาติดต่อต้องปฏิบัติตามโดยเคร่งครัด',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Chapters
          ...chapters.map((ch) => _buildChapterBlock(ch)),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildChapterBlock(ManualChapterModel ch) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Chapter Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'บทที่ ${ch.chapterNumber}: ${ch.titleTh}',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          if (ch.titleEn.isNotEmpty)
            pw.Text(
              ch.titleEn,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          pw.SizedBox(height: 6),
          pw.Text(
            ch.content,
            style: const pw.TextStyle(fontSize: 9.5, height: 1.35, color: PdfColors.grey900),
          ),
          if (ch.keyRules.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'ข้อกำหนดสำคัญ (Key Safety Requirements):',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
            ),
            pw.SizedBox(height: 4),
            ...ch.keyRules.map(
              (r) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 8, bottom: 3),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                    pw.Expanded(
                      child: pw.Text(r, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 0.5, color: PdfColors.grey300),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. TIER 2: EMPLOYEE SAFETY HANDBOOK (คู่มือฉบับพนักงาน/กระเป๋าเสื้อ)
  // =========================================================================
  static Future<Uint8List> generateEmployeeHandbookBytes({
    required List<ManualChapterModel> chapters,
    String companyName = 'สถานประกอบกิจการ',
  }) async {
    final doc = pw.Document(
      title: 'คู่มือความปลอดภัยฉบับพนักงาน - $companyName',
      author: 'Safapp EHS System',
    );

    final theme = await _buildTheme();

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        ),
        header: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 6),
          margin: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.amber800, width: 1.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'คู่มือความปลอดภัยฉบับพนักงาน (Employee Pocket Safety Handbook)',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
              ),
              pw.Text(
                companyName,
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 6),
          margin: const pw.EdgeInsets.only(top: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'พกติดตัวหรือเก็บบนโต๊ะทำงาน ปฏิบัติตามกฎเพื่อตนเองและเพื่อนร่วมงาน',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'หน้า ${ctx.pageNumber} จาก ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (ctx) => [
          // Banner
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.amber300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'คู่มือความปลอดภัยประจำตัวพนักงาน',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '$companyName | "กลับบ้านปลอดภัยทุกวัน คือเป้าหมายสูงสุดของเรา"',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          ...chapters.map((ch) => _buildHandbookSection(ch)),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildHandbookSection(ManualChapterModel ch) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            ch.titleTh,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            ch.content,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
          ),
          if (ch.keyRules.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            ...ch.keyRules.map(
              (r) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 6, bottom: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('✓ ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    pw.Expanded(
                      child: pw.Text(r, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // 3. TIER 3: 1-PAGE SAFETY INDUCTION CARD (ใบสรุปความปลอดภัย 1 หน้า + ใบฉีก)
  // =========================================================================
  static Future<Uint8List> generateInductionLeafletBytes({
    required ManualChapterModel leaflet,
    String companyName = 'สถานประกอบกิจการ',
  }) async {
    final doc = pw.Document(
      title: 'ใบสรุปความปลอดภัยปฐมนิเทศ - $companyName',
      author: 'Safapp EHS System',
    );

    final theme = await _buildTheme();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Top Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      companyName,
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.Text(
                      'ใบสรุปกฎระเบียบความปลอดภัยสำหรับพนักงานใหม่และผู้รับเหมา (1-Page Safety Induction)',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: PdfColors.red300),
                  ),
                  child: pw.Text(
                    'เอกสารแจกจ่าย',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1.5, color: PdfColors.blue800),
            pw.SizedBox(height: 8),

            // Main Content Section
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                leaflet.content,
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900),
              ),
            ),
            pw.SizedBox(height: 10),

            // Golden Rules List
            pw.Text(
              'กฎระเบียบและข้อควรปฏิบัติที่ต้องทราบทันทีก่อนเข้าพื้นที่:',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 6),
            ...leaflet.keyRules.map(
              (r) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 4, bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('■ ', style: pw.TextStyle(fontSize: 8, color: PdfColors.blue700)),
                    pw.Expanded(
                      child: pw.Text(r, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900)),
                    ),
                  ],
                ),
              ),
            ),

            pw.Spacer(),

            // PERFORATED TEAR-OFF SLIP (ใบฉีกเซ็นรับทราบกฎความปลอดภัย)
            pw.Row(
              children: [
                pw.Text('✂ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'ใบฉีกเซ็นรับทราบและยินยอมปฏิบัติตามกฎความปลอดภัย (Tear-off Acknowledgement Slip)',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      ),
                      pw.Text(
                        'ส่งคืนฝ่ายบุคคล/จป. หลังปฐมนิเทศ',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'ข้าพเจ้าได้รับฟังการปฐมนิเทศและได้รับเอกสารสรุปกฎความปลอดภัยฉบับนี้แล้ว ข้าพเจ้ายินยอมปฏิบัติตามกฎความปลอดภัยของ $companyName อย่างเคร่งครัด หากฝ่าฝืนยินยอมรับมาตรการทางวินัยหรือการระงับสิทธิการเข้าพื้นที่',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('ชื่อ-นามสกุล (ตัวบรรจง): __________________________________', style: const pw.TextStyle(fontSize: 8)),
                          pw.SizedBox(height: 6),
                          pw.Text('ตำแหน่ง/สังกัด/ชื่อบริษัทผู้รับเหมา: ____________________________', style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('ลายมือชื่อ: _____________________________', style: const pw.TextStyle(fontSize: 8)),
                          pw.SizedBox(height: 6),
                          pw.Text('วันที่: ________ / ________ / ____________', style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // =========================================================================
  // PRINTING & FILE SAVING HELPERS
  // =========================================================================
  static Future<String> savePdfFile(Uint8List bytes, String fileName) async {
    final dir = await _getExportDirectory();
    final file = File(p.join(dir, fileName));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static Future<void> printOrPreviewPdf(Uint8List bytes, String title) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: title,
    );
  }
}
