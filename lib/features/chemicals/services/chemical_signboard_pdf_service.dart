import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/widgets/safapp_print_preview.dart';
import '../domain/models/chemical_inventory_model.dart';
import '../domain/models/chemical_sds_sor1_model.dart';
import '../presentation/widgets/ghs_diamond_widget.dart';
import '../presentation/widgets/nfpa_diamond_widget.dart';

/// Professional Statutory & International GHS Chemical Storage & Container Signboard Service.
///
/// Produces official workplace chemical safety labels and storage area warning signboards
/// strictly conforming to:
/// - Ministerial Regulation on Hazardous Chemicals B.E. 2556 (ม. ๕, ๗, ๘, ๙)
/// - UN Globally Harmonized System (GHS) Rev. 9
/// - NFPA 704 Standard System for the Identification of the Hazards of Materials
class ChemicalSignboardPdfService {
  /// Opens print preview dialog for the chemical safety signboard.
  static Future<void> printOrShare(
    BuildContext context,
    ChemicalInventoryItem item, {
    ChemicalSdsSor1Model? sdsModel,
    String? companyName,
    String? emergencyContact,
    bool isLandscape = true,
  }) async {
    // Generate PDF document bytes
    final bytes = await generateSignboardPdf(
      item,
      sdsModel: sdsModel,
      companyName: companyName,
      emergencyContact: emergencyContact,
      isLandscape: isLandscape,
    );

    if (!context.mounted) return;

    final formatLabel = isLandscape ? 'A4 แนวนอน (ติดผนัง/จุดจัดเก็บ)' : 'A4 แนวตั้ง (ติดภาชนะ/ถัง)';
    await SafappPrintPreview.showBytes(
      context,
      title: 'ป้ายชี้บ่งสารเคมีอันตรายและจุดจัดเก็บ ($formatLabel)',
      subtitle: '${item.tradeName} (CAS: ${item.casNumber}) • ${item.storageLocation}',
      formCode: 'GHS / NFPA 704',
      fileName: 'Signboard_${item.casNumber.replaceAll("-", "")}_${isLandscape ? "Landscape" : "Portrait"}.pdf',
      pdfBytes: bytes,
      initialPageFormat: isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
    );
  }

  /// Builds the complete PDF bytes.
  static Future<Uint8List> generateSignboardPdf(
    ChemicalInventoryItem item, {
    ChemicalSdsSor1Model? sdsModel,
    String? companyName,
    String? emergencyContact,
    bool isLandscape = true,
  }) async {
    final doc = pw.Document();

    pw.Font fontRegular;
    pw.Font fontBold;
    pw.Font fontItalic;

    try {
      final regData = await rootBundle.load('google_fonts/Prompt-Regular.ttf');
      final boldData = await rootBundle.load('google_fonts/Prompt-Bold.ttf');
      final medData = await rootBundle.load('google_fonts/Prompt-Medium.ttf');
      fontRegular = pw.Font.ttf(regData);
      fontBold = pw.Font.ttf(boldData);
      fontItalic = pw.Font.ttf(medData);
    } catch (_) {
      try {
        fontRegular = await PdfGoogleFonts.sarabunRegular();
        fontBold = await PdfGoogleFonts.sarabunBold();
        fontItalic = await PdfGoogleFonts.sarabunItalic();
      } catch (_) {
        fontRegular = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
        fontItalic = pw.Font.helveticaOblique();
      }
    }

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
    );

    // Pre-render high-resolution GHS diamonds to PNG bytes
    final List<Uint8List> ghsPngList = [];
    for (final code in item.ghsPictograms) {
      try {
        final png = await GhsDiamondWidget.renderToPng(code, size: 240);
        ghsPngList.add(png);
      } catch (_) {}
    }

    // Pre-render NFPA diamond to PNG bytes
    Uint8List? nfpaPng;
    try {
      nfpaPng = await NfpaDiamondWidget.renderToPng(
        health: item.nfpaHealth ?? sdsModel?.nfpaHealth ?? 0,
        flammability: item.nfpaFlammability ?? sdsModel?.nfpaFlammability ?? 0,
        instability: item.nfpaInstability ?? sdsModel?.nfpaInstability ?? 0,
        special: item.nfpaSpecial ?? sdsModel?.nfpaSpecial,
        size: 260,
      );
    } catch (_) {}

    final pageFormat = isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        theme: theme,
        margin: const pw.EdgeInsets.all(18),
        build: (pw.Context ctx) {
          if (isLandscape) {
            return _buildLandscapeLayout(
              item: item,
              sdsModel: sdsModel,
              ghsPngList: ghsPngList,
              nfpaPng: nfpaPng,
              companyName: companyName,
              emergencyContact: emergencyContact,
            );
          } else {
            return _buildPortraitLayout(
              item: item,
              sdsModel: sdsModel,
              ghsPngList: ghsPngList,
              nfpaPng: nfpaPng,
              companyName: companyName,
              emergencyContact: emergencyContact,
            );
          }
        },
      ),
    );

    return doc.save();
  }

  // =========================================================================
  // LANDSCAPE LAYOUT (Ideal for Wall / Racks / Warehouse Storage Area Sign)
  // =========================================================================
  static pw.Widget _buildLandscapeLayout({
    required ChemicalInventoryItem item,
    ChemicalSdsSor1Model? sdsModel,
    required List<Uint8List> ghsPngList,
    Uint8List? nfpaPng,
    String? companyName,
    String? emergencyContact,
  }) {
    final signalWord = _resolveSignalWord(item, sdsModel);
    final isDanger = signalWord.toUpperCase().contains('DANGER') || signalWord.contains('อันตราย');

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue900, width: 2.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // 1. TOP HEADER BANNER
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ป้ายชี้บ่งสารเคมีอันตรายและจุดจัดเก็บ (CHEMICAL IDENTIFICATION & STORAGE SIGNBOARD)',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'มาตรฐานระบบสากล GHS (Rev. 9) • กฎกระทรวงสารเคมีอันตราย พ.ศ. ๒๕๕๖ • NFPA 704 Standard',
                      style: const pw.TextStyle(color: PdfColors.blue100, fontSize: 8),
                    ),
                  ],
                ),
                if (companyName != null && companyName.isNotEmpty)
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),

          // 2. PROMINENT STORAGE LOCATION BOX ("แปะที่อยู่ได้")
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              border: pw.Border.all(color: PdfColors.amber700, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.amber800,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Text(
                    'จุดจัดเก็บ / ที่อยู่สารเคมี',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Text(
                    item.storageLocation,
                    style: pw.TextStyle(color: PdfColors.blue900, fontSize: 13, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),

          // 3. MAIN 2-COLUMN BODY
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // === LEFT COLUMN (Identity, GHS Diamonds, NFPA, Signal Word) ===
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400, width: 1),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Trade Name
                        pw.Text(
                          item.tradeName,
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                        // Chemical Name (TH / EN)
                        pw.Text(
                          '${item.chemicalNameTh} (${item.chemicalNameEn})',
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800, fontStyle: pw.FontStyle.italic),
                        ),
                        pw.SizedBox(height: 6),

                        // CAS No. & UN No. Badges
                        pw.Row(
                          children: [
                            _buildInfoBadge('CAS No.', item.casNumber, PdfColors.blue800),
                            pw.SizedBox(width: 8),
                            _buildInfoBadge('UN No.', item.unNumber ?? '-', PdfColors.purple800),
                            pw.SizedBox(width: 8),
                            _buildInfoBadge('สถานะ', item.physicalState, PdfColors.teal800),
                          ],
                        ),
                        pw.SizedBox(height: 10),

                        // SIGNAL WORD BANNER (อันตราย / ระวัง)
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(vertical: 6),
                          alignment: pw.Alignment.center,
                          decoration: pw.BoxDecoration(
                            color: isDanger ? PdfColors.red800 : PdfColors.orange800,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                          ),
                          child: pw.Text(
                            signalWord.toUpperCase(),
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.SizedBox(height: 10),

                        // DIAMONDS ROW (GHS Pictograms + NFPA Diamond)
                        pw.Expanded(
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              // GHS Pictograms (Authentic UN Red Diamonds)
                              if (ghsPngList.isNotEmpty)
                                pw.Expanded(
                                  flex: 6,
                                  child: pw.Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: pw.WrapAlignment.center,
                                    children: ghsPngList.map((png) {
                                      return pw.Image(
                                        pw.MemoryImage(png),
                                        width: 58,
                                        height: 58,
                                      );
                                    }).toList(),
                                  ),
                                )
                              else
                                pw.Expanded(
                                  flex: 6,
                                  child: pw.Center(
                                    child: pw.Text('ไม่มีสัญลักษณ์อันตราย GHS', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                                  ),
                                ),

                              pw.Container(width: 1, color: PdfColors.grey300, margin: const pw.EdgeInsets.symmetric(horizontal: 6)),

                              // NFPA 704 Diamond
                              if (nfpaPng != null)
                                pw.Expanded(
                                  flex: 4,
                                  child: pw.Column(
                                    mainAxisAlignment: pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Image(
                                        pw.MemoryImage(nfpaPng),
                                        width: 80,
                                        height: 80,
                                      ),
                                      pw.SizedBox(height: 4),
                                      pw.Text('NFPA 704 Standard', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Manufacturer / Supplier
                        if (item.manufacturerSupplier != null && item.manufacturerSupplier!.isNotEmpty) ...[
                          pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                          pw.Text(
                            'ผู้ผลิต/ผู้จัดจำหน่าย: ${item.manufacturerSupplier}',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                            maxLines: 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),

                // === RIGHT COLUMN (Hazards, Precautions, PPE, First Aid) ===
                pw.Expanded(
                  flex: 6,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400, width: 1),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Hazard Statements (H-Statements)
                        _buildSectionTitle('ข้อความแสดงความเป็นอันตราย (Hazard Statements)', PdfColors.red900),
                        pw.SizedBox(height: 3),
                        ..._resolveHazardStatements(item, sdsModel).map((h) => _buildBulletText(h, isRed: true)),
                        pw.SizedBox(height: 8),

                        // Precautionary Statements (P-Statements)
                        _buildSectionTitle('ข้อควรระวังและคำแนะนำในการใช้งาน (Safety Precautions)', PdfColors.blue900),
                        pw.SizedBox(height: 3),
                        ..._resolvePrecautionaryStatements(item, sdsModel).map((p) => _buildBulletText(p)),
                        pw.SizedBox(height: 8),

                        // Required PPE Checklist
                        _buildSectionTitle('อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคลที่ต้องสวมใส่ (Required PPE)', PdfColors.teal900),
                        pw.SizedBox(height: 3),
                        _buildPpeChecklistRow(item, sdsModel),
                        pw.SizedBox(height: 8),

                        // Emergency First-Aid Measures
                        _buildSectionTitle('การปฐมพยาบาลเบื้องต้นกรณีฉุกเฉิน (First-Aid Measures)', PdfColors.orange900),
                        pw.SizedBox(height: 3),
                        _buildFirstAidSummary(item, sdsModel),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),

          // 4. BOTTOM EMERGENCY HOTLINE BAR
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'เบอร์โทรแจ้งเหตุด่วนฉุกเฉิน: จป.วิชาชีพ / ERT: ${emergencyContact ?? sdsModel?.emergencyPhone ?? "02-xxx-xxxx"} • สายด่วนกู้ชีพ/ดับเพลิง: 199 / 1669',
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                ),
                pw.Text(
                  'วันที่ออกป้าย: ${item.registerDate} • รอบทบทวน SDS ทุก ${item.sdsExpiryYears} ปี',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PORTRAIT LAYOUT (Ideal for Drum Label / IBC Tote Sticker / Container Label)
  // =========================================================================
  static pw.Widget _buildPortraitLayout({
    required ChemicalInventoryItem item,
    ChemicalSdsSor1Model? sdsModel,
    required List<Uint8List> ghsPngList,
    Uint8List? nfpaPng,
    String? companyName,
    String? emergencyContact,
  }) {
    final signalWord = _resolveSignalWord(item, sdsModel);
    final isDanger = signalWord.toUpperCase().contains('DANGER') || signalWord.contains('อันตราย');

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue900, width: 2.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'ฉลากชี้บ่งสารเคมีอันตรายและจุดจัดเก็บ (HAZARDOUS CHEMICAL LABEL)',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                if (companyName != null && companyName.isNotEmpty)
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),

          // STORAGE LOCATION BOX ("แปะที่อยู่ได้")
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              border: pw.Border.all(color: PdfColors.amber700, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text('จุดจัดเก็บ / ที่อยู่ภาชนะ: ', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                    pw.Expanded(
                      child: pw.Text(item.storageLocation, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),

          // Chemical Identity
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(item.tradeName, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.Text('${item.chemicalNameTh} (${item.chemicalNameEn})', style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800, fontStyle: pw.FontStyle.italic)),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    _buildInfoBadge('CAS No.', item.casNumber, PdfColors.blue800),
                    pw.SizedBox(width: 6),
                    _buildInfoBadge('UN No.', item.unNumber ?? '-', PdfColors.purple800),
                    pw.SizedBox(width: 6),
                    _buildInfoBadge('สถานะ', item.physicalState, PdfColors.teal800),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),

          // SIGNAL WORD BANNER
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 5),
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: isDanger ? PdfColors.red800 : PdfColors.orange800,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Text(
              signalWord.toUpperCase(),
              style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 6),

          // GHS & NFPA DIAMONDS ROW
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              // GHS Diamonds
              if (ghsPngList.isNotEmpty)
                pw.Expanded(
                  flex: 6,
                  child: pw.Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: pw.WrapAlignment.center,
                    children: ghsPngList.map((png) {
                      return pw.Image(pw.MemoryImage(png), width: 50, height: 50);
                    }).toList(),
                  ),
                ),
              if (nfpaPng != null) ...[
                pw.SizedBox(width: 10),
                pw.Image(pw.MemoryImage(nfpaPng), width: 68, height: 68),
              ],
            ],
          ),
          pw.SizedBox(height: 6),

          // Hazards & Precautions
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('ข้อความแสดงความเป็นอันตราย (Hazard Statements)', PdfColors.red900),
                  pw.SizedBox(height: 2),
                  ..._resolveHazardStatements(item, sdsModel).take(4).map((h) => _buildBulletText(h, isRed: true)),
                  pw.SizedBox(height: 6),

                  _buildSectionTitle('ข้อควรระวังและวิธีปฏิบัติ (Safety Precautions)', PdfColors.blue900),
                  pw.SizedBox(height: 2),
                  ..._resolvePrecautionaryStatements(item, sdsModel).take(4).map((p) => _buildBulletText(p)),
                  pw.SizedBox(height: 6),

                  _buildSectionTitle('อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคลที่ต้องใช้ (PPE)', PdfColors.teal900),
                  pw.SizedBox(height: 2),
                  _buildPpeChecklistRow(item, sdsModel),
                  pw.SizedBox(height: 6),

                  _buildSectionTitle('การปฐมพยาบาลเบื้องต้น (First-Aid Measures)', PdfColors.orange900),
                  pw.SizedBox(height: 2),
                  _buildFirstAidSummary(item, sdsModel),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 6),

          // Bottom Emergency Bar
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'เบอร์ฉุกเฉิน จป./โรงงาน: ${emergencyContact ?? sdsModel?.emergencyPhone ?? "02-xxx-xxxx"} • สายด่วน: 199 / 1669',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                ),
                pw.Text(
                  'แบบ สอ.๑ / GHS Standard',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // HELPER BUILDERS & DATA RESOLVERS
  // =========================================================================
  static pw.Widget _buildInfoBadge(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('$label: ', style: pw.TextStyle(fontSize: 8, color: color, fontWeight: pw.FontWeight.bold)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8.5, color: PdfColors.black, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(width: 3.5, height: 10, color: color),
        pw.SizedBox(width: 4),
        pw.Text(title, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static pw.Widget _buildBulletText(String text, {bool isRed = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 4, bottom: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('• ', style: pw.TextStyle(fontSize: 8, color: isRed ? PdfColors.red800 : PdfColors.blue900, fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
            child: pw.Text(text, style: pw.TextStyle(fontSize: 8, color: isRed ? PdfColors.red900 : PdfColors.black)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPpeChecklistRow(ChemicalInventoryItem item, ChemicalSdsSor1Model? sds) {
    // Standard chemical PPE items
    final ppeList = [
      'แว่นตานิรภัย/กระบังหน้า',
      'ถุงมือกันสารเคมี',
      'หน้ากากกรองไอระเหย',
      'รองเท้านิรภัย/บู๊ต',
      'ผ้ากันเปื้อน/ชุดสารเคมี',
    ];

    return pw.Wrap(
      spacing: 6,
      runSpacing: 4,
      children: ppeList.map((ppe) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: pw.BoxDecoration(
            color: PdfColors.teal50,
            border: pw.Border.all(color: PdfColors.teal600, width: 0.6),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                width: 7,
                height: 7,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.teal700,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Text(ppe, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.teal900)),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildFirstAidSummary(ChemicalInventoryItem item, ChemicalSdsSor1Model? sds) {
    final eye = sds?.eyeContactFirstAid ?? 'ล้างด้วยน้ำสะอาดทันทีอย่างน้อย 15 นาที และนำส่งแพทย์';
    final skin = sds?.skinContactFirstAid ?? 'ถอดเสื้อผ้าที่เปื้อนออก ล้างผิวหนังด้วยน้ำและสบู่ปริมาณมาก';
    final inhale = sds?.inhalationFirstAid ?? 'ย้ายผู้ประสบเหตุไปที่อากาศถ่ายเทสะดวก หากหายใจติดขัดให้ใช้ออกซิเจน';
    final ingest = sds?.ingestionFirstAid ?? 'ห้ามทำให้อาเจียน ให้ดื่มน้ำสะอาดปริมาณมาก และนำส่งแพทย์ทันที';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildBulletText('สัมผัสตา: $eye'),
        _buildBulletText('สัมผัสผิวหนัง: $skin'),
        _buildBulletText('การสูดดม: $inhale'),
        _buildBulletText('การกลืนกิน: $ingest'),
      ],
    );
  }

  static String _resolveSignalWord(ChemicalInventoryItem item, ChemicalSdsSor1Model? sds) {
    if (sds != null && sds.signalWord.isNotEmpty && sds.signalWord != 'NONE') {
      if (sds.signalWord == 'DANGER') return 'อันตราย / DANGER';
      if (sds.signalWord == 'WARNING') return 'ระวัง / WARNING';
      return sds.signalWord;
    }

    // Fallback from GHS pictograms
    final hasHighRisk = item.ghsPictograms.any((c) => ['GHS01', 'GHS02', 'GHS05', 'GHS06', 'GHS08'].contains(c));
    return hasHighRisk ? 'อันตราย / DANGER' : 'ระวัง / WARNING';
  }

  static List<String> _resolveHazardStatements(ChemicalInventoryItem item, ChemicalSdsSor1Model? sds) {
    if (sds != null && sds.hazardStatements.isNotEmpty) {
      return sds.hazardStatements;
    }

    // Default intelligent fallbacks derived from selected GHS pictograms
    final List<String> list = [];
    if (item.ghsPictograms.contains('GHS01')) list.add('H200: วัตถุระเบิดไม่เสถียร อาจเกิดการระเบิดรุนแรง');
    if (item.ghsPictograms.contains('GHS02')) list.add('H225: ของเหลวและไอระเหยไวไฟสูงยิ่ง เก็บห่างจากเปลวไฟและความร้อน');
    if (item.ghsPictograms.contains('GHS03')) list.add('H270: อาจทำให้เกิดเพลิงไหม้หรือเร่งการลุกไหม้ สารออกซิไดซ์แรง');
    if (item.ghsPictograms.contains('GHS04')) list.add('H280: บรรจุก๊าซภายใต้ความดัน อาจระเบิดได้หากได้รับความร้อน');
    if (item.ghsPictograms.contains('GHS05')) list.add('H314: ทำให้ผิวหนังไหม้อย่างรุนแรงและทำลายดวงตา');
    if (item.ghsPictograms.contains('GHS06')) list.add('H301+H311+H331: มีพิษถึงแก่ชีวิตเมื่อกลืนกิน สัมผัสผิวหนัง หรือสูดดม');
    if (item.ghsPictograms.contains('GHS07')) list.add('H319: ระคายเคืองต่อดวงตาและผิวหนังอย่างรุนแรง');
    if (item.ghsPictograms.contains('GHS08')) list.add('H350: สารอาจก่อมะเร็งหรือเป็นอันตรายต่อระบบทางเดินหายใจ');
    if (item.ghsPictograms.contains('GHS09')) list.add('H411: เป็นพิษต่อสิ่งมีชีวิตในน้ำ และมีผลกระทบระยะยาว');

    if (list.isEmpty) {
      list.add('สารเคมีสำหรับใช้ในกระบวนการผลิตและซ่อมบำรุงตามมาตรฐานความปลอดภัย');
    }
    return list;
  }

  static List<String> _resolvePrecautionaryStatements(ChemicalInventoryItem item, ChemicalSdsSor1Model? sds) {
    if (sds != null && sds.precautionaryStatements.isNotEmpty) {
      return sds.precautionaryStatements;
    }

    return [
      'P210: เก็บให้ห่างจากความร้อน ประกายไฟ เปลวไฟ และพื้นผิวที่ร้อน ห้ามสูบบุหรี่',
      'P233: ปิดฝาภาชนะบรรจุให้สนิททุกครั้งเมื่อไม่ได้ใช้งาน',
      'P280: สวมใส่อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล (ถุงมือ แว่นตา หน้ากาก)',
      'P403+P235: จัดเก็บในสถานที่ที่มีอากาศถ่ายเทสะดวกและมีอุณหภูมิเย็น',
    ];
  }
}
