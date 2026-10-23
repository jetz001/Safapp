import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/widgets/safapp_print_preview.dart';
import '../domain/models/chemical_sds_sor1_model.dart';

/// Official Statutory PDF Generator for Form สอ.๑
/// Strictly conforming to the Department of Labour Protection and Welfare (DLPW) Gazette Notification B.E. 2556
/// (ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง แบบบัญชีรายชื่อสารเคมีอันตรายและรายละเอียดข้อมูลความปลอดภัยของสารเคมีอันตราย แบบ สอ.๑).
class ChemicalSor1PdfService {
  /// Opens print preview dialog for Form สอ.๑
  static Future<void> printOrShare(
    BuildContext context,
    ChemicalSdsSor1Model item, {
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
  }) async {
    final bytes = await generatePdf(
      item,
      companyName: companyName,
      companyAddress: companyAddress,
      companyPhone: companyPhone,
      companyEmail: companyEmail,
    );
    if (!context.mounted) return;
    await SafappPrintPreview.showBytes(
      context,
      title: 'แบบบัญชีรายชื่อสารเคมีอันตรายและรายละเอียดข้อมูลความปลอดภัยฯ (สอ.๑)',
      subtitle: '${item.tradeName} (CAS: ${item.casNumber})',
      formCode: 'แบบ สอ.๑',
      fileName: 'Form_Sor1_${item.casNumber.replaceAll("-", "")}.pdf',
      pdfBytes: bytes,
      initialPageFormat: PdfPageFormat.a4,
    );
  }

  /// Generates the complete 4-page official statutory PDF conforming strictly to the gazette.
  static Future<Uint8List> generatePdf(
    ChemicalSdsSor1Model item, {
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
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

    // =========================================================================
    // PAGE 1: หมวด ๑, ๒, ๓
    // =========================================================================
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.only(left: 36, right: 36, top: 28, bottom: 24),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Form header: แบบ สอ.๑ on top right
              pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Text('แบบ สอ.๑', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 6),

              // Title
              pw.Center(
                child: pw.Text(
                  'แบบบัญชีรายชื่อสารเคมีอันตรายและรายละเอียดข้อมูลความปลอดภัยของสารเคมีอันตราย',
                  style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 4),

              // Date line
              pw.Center(
                child: pw.Text(
                  'วันที่ ${(item.revisionDate ?? item.createdAt ?? "").isNotEmpty ? (item.revisionDate ?? item.createdAt!) : "......... เดือน......................... พ.ศ. .........."}',
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
              ),
              pw.SizedBox(height: 8),

              // ๑. ข้อมูลเกี่ยวกับสารเคมีอันตราย
              _buildMajorHeader('๑. ข้อมูลเกี่ยวกับสารเคมีอันตราย (Identification of the Hazardous Substance)'),
              pw.SizedBox(height: 2),

              _buildSubHeader('๑.๑ ข้อบ่งชี้สารเคมี'),
              pw.Row(
                children: [
                  _buildInlineDotted('ชื่อทางการค้า', item.tradeName, flex: 4),
                  pw.SizedBox(width: 8),
                  _buildInlineDotted('ชื่อสารเคมี', item.tradeName, flex: 4),
                  pw.SizedBox(width: 8),
                  _buildInlineDotted('ชื่ออื่น', '-', flex: 3),
                ],
              ),
              _buildFullDotted('สูตรเคมี', item.chemicalFormula ?? '-'),
              _buildFullDotted('CAS No.', item.casNumber + (item.unNumber != null && item.unNumber!.isNotEmpty ? '  (UN No. ${item.unNumber})' : '')),

              _buildSubHeader('๑.๒ ผู้ผลิต/ผู้นำเข้า/ตัวแทนจำหน่าย'),
              _buildFullDotted('ผู้ผลิต/ผู้นำเข้า', item.manufacturerImporterInfo),
              _buildFullDotted('ที่อยู่', companyAddress ?? item.manufacturerImporterInfo),
              pw.Row(
                children: [
                  _buildInlineDotted('โทรศัพท์', '-', flex: 3),
                  pw.SizedBox(width: 6),
                  _buildInlineDotted('โทรสาร', '-', flex: 3),
                  pw.SizedBox(width: 6),
                  _buildInlineDotted('โทรศัพท์ฉุกเฉิน', item.emergencyPhone ?? '-', flex: 3),
                ],
              ),
              _buildFullDotted('Email', '-'),

              _buildFullDotted('๑.๓ ข้อแนะนำและข้อจำกัดในการใช้', item.recommendedUse ?? '-'),
              _buildFullDotted('๑.๔ การใช้ประโยชน์', item.recommendedUse ?? 'ใช้ในกระบวนการผลิตและซ่อมบำรุง'),
              _buildFullDotted('      ปริมาณสูงสุดที่มีไว้ในครอบครอง', '-'),
              _buildFullDotted('๑.๕ อื่นๆ', '-'),
              pw.SizedBox(height: 6),

              // ๒. การบ่งชี้ความเป็นอันตราย
              _buildMajorHeader('๒. การบ่งชี้ความเป็นอันตราย (Hazards Identification)'),
              pw.SizedBox(height: 2),

              _buildSubHeader('๒.๑ การจำแนกประเภท'),
              _buildFullDotted('ความเป็นอันตรายทางกายภาพ', item.ghsClassification ?? (item.ghsPictograms.contains('GHS02') ? 'ของเหลวไวไฟ' : '-')),
              _buildFullDotted('ความเป็นอันตรายต่อสุขภาพ', item.ghsClassification ?? (item.ghsPictograms.contains('GHS07') ? 'ระคายเคืองต่อดวงตาและผิวหนัง' : '-')),
              _buildFullDotted('ความเป็นอันตรายต่อสิ่งแวดล้อม', item.ghsPictograms.contains('GHS09') ? 'เป็นพิษต่อระบบนิเวศทางน้ำ' : '-'),
              _buildFullDotted('ความเป็นอันตรายอื่น', '-'),

              _buildSubHeader('๒.๒ องค์ประกอบตามฉลาก'),
              _buildFullDotted('รูปสัญลักษณ์', item.ghsPictograms.isNotEmpty ? item.ghsPictograms.join(', ') : '-'),
              _buildFullDotted('คำสัญญาณ', item.signalWord == 'DANGER' ? 'อันตราย (DANGER)' : (item.signalWord == 'WARNING' ? 'ระวัง (WARNING)' : item.signalWord)),
              _buildFullDotted('ข้อความแสดงอันตราย', item.hazardStatements.isNotEmpty ? item.hazardStatements.join('; ') : '-'),
              _buildFullDotted('ข้อควรระวังหรือข้อปฏิบัติเพื่อป้องกันอันตราย', item.precautionaryStatements.isNotEmpty ? item.precautionaryStatements.join('; ') : '-'),
              _buildFullDotted('๒.๓ อื่นๆ', 'NFPA 704 (สุขภาพ: ${item.nfpaHealth}, ไฟ: ${item.nfpaFlammability}, ทำปฏิกิริยา: ${item.nfpaInstability}, พิเศษ: ${item.nfpaSpecial ?? "-"})'),
              pw.SizedBox(height: 6),

              // ๓. องค์ประกอบและข้อมูลเกี่ยวกับส่วนผสม
              _buildMajorHeader('๓. องค์ประกอบและข้อมูลเกี่ยวกับส่วนผสม (Composition / Information on Ingredients)'),
              pw.SizedBox(height: 3),
              _buildIngredientsTable(item),
            ],
          );
        },
      ),
    );

    // =========================================================================
    // PAGE 2: หมวด ๔, ๕, ๖, ๗, ๘, ๙ (๙.๑ - ๙.๒)
    // =========================================================================
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.only(left: 36, right: 36, top: 28, bottom: 24),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('-๒-', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 6),

              // ๔. มาตรการปฐมพยาบาล
              _buildMajorHeader('๔. มาตรการปฐมพยาบาล (First Aid Measures)'),
              _buildFullDotted('๔.๑ กรณีได้รับทางการหายใจ', item.inhalationFirstAid ?? 'ย้ายผู้ป่วยไปยังที่ที่มีอากาศบริสุทธิ์ หากไม่หายใจให้ช่วยผายปอด'),
              _buildFullDotted('๔.๒ กรณีได้รับทางผิวหนังหรือดวงตา', '${item.skinContactFirstAid ?? "ล้างด้วยน้ำสะอาดและสบู่"} / ${item.eyeContactFirstAid ?? "ล้างด้วยน้ำสะอาดทันทีอย่างน้อย 15 นาที"}'),
              _buildFullDotted('๔.๓ กรณีได้รับทางการกลืนกิน', item.ingestionFirstAid ?? 'ห้ามทำให้อาเจียน ให้ดื่มน้ำสะอาดและนำส่งแพทย์ทันที'),
              _buildFullDotted('๔.๔ อื่นๆ', item.symptomsEffects ?? '-'),
              pw.SizedBox(height: 6),

              // ๕. มาตรการผจญเพลิง
              _buildMajorHeader('๕. มาตรการผจญเพลิง (Fire Fighting Measures)'),
              _buildFullDotted('๕.๑ สารดับเพลิงที่ห้ามใช้และสารดับเพลิงที่เหมาะสม', (item.suitableExtinguishingMedia ?? 'ผงเคมีแห้ง, โฟม, คาร์บอนไดออกไซด์') + (item.unsuitableExtinguishingMedia != null ? ' (ห้ามใช้: ${item.unsuitableExtinguishingMedia})' : '')),
              _buildFullDotted('๕.๒ ความเป็นอันตรายเฉพาะที่เกิดขึ้นจากสารเคมี', item.specificFireHazards ?? '-'),
              _buildFullDotted('๕.๓ อุปกรณ์พิเศษสำหรับนักผจญเพลิง', item.protectiveEquipmentFirefighters ?? 'ชุดผจญเพลิงมาตรฐานและเครื่องช่วยหายใจ SCBA'),
              _buildFullDotted('๕.๔ อื่นๆ', '-'),
              pw.SizedBox(height: 6),

              // ๖. มาตรการจัดการเมื่อมีการหก รั่วไหล
              _buildMajorHeader('๖. มาตรการจัดการเมื่อมีการหก รั่วไหล (Accidental Release Measures)'),
              _buildFullDotted('๖.๑ ข้อควรระวังส่วนบุคคล อุปกรณ์ป้องกันอันตราย และขั้นตอนการปฏิบัติงานฉุกเฉิน', item.personalPrecautions ?? 'สวมใส่อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล หลีกเลี่ยงการสูดดมไอระเหย'),
              _buildFullDotted('๖.๒ วิธีการ และวัสดุสำหรับกักเก็บและทำความสะอาด', item.containmentCleanUp ?? 'ใช้ทราย ดิน หรือวัสดุดูดซับสารเคมีที่ไม่ติดไฟกักเก็บและเก็บลงในภาชนะที่ปิดมิดชิด'),
              _buildFullDotted('๖.๓ ข้อควรระวังด้านสิ่งแวดล้อม', item.environmentalPrecautions ?? 'ป้องกันไม่ให้ไหลลงสู่แหล่งน้ำสาธารณะหรือระบบระบายน้ำเสีย'),
              _buildFullDotted('๖.๔ อื่นๆ', '-'),
              pw.SizedBox(height: 6),

              // ๗. การขนถ่าย เคลื่อนย้าย และการจัดเก็บ
              _buildMajorHeader('๗. การขนถ่าย เคลื่อนย้าย และการจัดเก็บ (Handling and Storage)'),
              _buildFullDotted('๗.๑ ข้อควรระวังและหลีกเลี่ยง', item.handlingPrecautions ?? 'ใช้ในสถานที่ที่มีการระบายอากาศดี หลีกเลี่ยงความร้อนและเปลวไฟ'),
              _buildFullDotted('๗.๒ วิธีการจัดเก็บอย่างปลอดภัย', item.storageConditions ?? 'จัดเก็บในภาชนะบรรจุเดิมที่ปิดสนิท ในสถานที่เย็น แห้ง และมีอากาศถ่ายเทสะดวก'),
              _buildFullDotted('๗.๓ อื่นๆ', item.storageTemperature != null ? 'อุณหภูมิจัดเก็บ: ${item.storageTemperature}' : '-'),
              pw.SizedBox(height: 6),

              // ๘. การควบคุมการรับสัมผัสและการป้องกันส่วนบุคคล
              _buildMajorHeader('๘. การควบคุมการรับสัมผัสและการป้องกันส่วนบุคคล (Exposure Controls and Personal Protection)'),
              _buildSubHeader('๘.๑ ค่าขีดจำกัดความเข้มข้นของสารเคมีอันตราย (TLV)'),
              _buildFullDotted('กฎหมายว่าด้วยความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน', item.exposureLimits ?? '-'),
              pw.Row(
                children: [
                  _buildInlineDotted('OSHA', item.exposureLimits ?? '-', flex: 3),
                  pw.SizedBox(width: 8),
                  _buildInlineDotted('NIOSH', '-', flex: 3),
                  pw.SizedBox(width: 8),
                  _buildInlineDotted('ACGIH', item.exposureLimits ?? '-', flex: 3),
                ],
              ),
              _buildFullDotted('อื่นๆ', '-'),
              _buildFullDotted('๘.๒ การควบคุมทางวิศวกรรมที่เหมาะสม', item.engineeringControls ?? 'ระบบดูดอากาศเฉพาะที่ (Local Exhaust Ventilation)'),
              _buildSubHeader('๘.๓ อุปกรณ์ป้องกันอันตรายส่วนบุคคล'),
              _buildFullDotted('ระบบหายใจ', item.respiratoryProtection ?? 'หน้ากากกรองไอระเหยสารอินทรีย์ที่ได้มาตรฐาน'),
              _buildFullDotted('ตา', item.eyeProtection ?? 'แว่นตานิรภัยป้องกันสารเคมีกระเด็น (Chemical Safety Goggles)'),
              _buildFullDotted('ผิวหนัง', item.skinHandProtection ?? 'ถุงมือทนสารเคมี (Nitrile/Neoprene) และเสื้อคลุมป้องกันสารเคมี'),
              _buildFullDotted('๘.๔ อื่นๆ', 'จุดล้างตาฉุกเฉินและฝักบัวฉุกเฉินในบริเวณใกล้เคียง'),
              pw.SizedBox(height: 6),

              // ๙. คุณสมบัติทางกายภาพและทางเคมี (เริ่ม ๙.๑ - ๙.๒)
              _buildMajorHeader('๙. คุณสมบัติทางกายภาพและทางเคมี (Physical and Chemical Properties)'),
              _buildFullDotted('๙.๑ ลักษณะทั่วไป', item.appearance ?? '-'),
              _buildFullDotted('๙.๒ กลิ่น', item.odor ?? '-'),
            ],
          );
        },
      ),
    );

    // =========================================================================
    // PAGE 3: หมวด ๙ (๙.๓ - ๙.๑๘), ๑๐, ๑๑, ๑๒ (๑๒.๑ - ๑๒.๒)
    // =========================================================================
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.only(left: 36, right: 36, top: 28, bottom: 24),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('-๓-', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 6),

              // ๙.๓ - ๙.๑๘
              _buildFullDotted('๙.๓ ค่าความเป็นกรดด่าง (pH)', item.phValue ?? '-'),
              _buildFullDotted('๙.๔ จุดหลอมเหลวและจุดเยือกแข็ง', '-'),
              _buildFullDotted('๙.๕ จุดเดือด', item.boilingPoint ?? '-'),
              _buildFullDotted('๙.๖ จุดวาบไฟ', item.flashPoint ?? '-'),
              _buildFullDotted('๙.๗ อัตราการระเหย', '-'),
              _buildFullDotted('๙.๘ ความสามารถในการลุกติดไฟ', item.flammabilityLimits ?? '-'),
              _buildFullDotted('๙.๑๐ ค่าขีดจำกัดสูงสุดและต่ำสุดของความไวไฟหรือของการระเบิด', item.flammabilityLimits ?? '-'),
              _buildFullDotted('๙.๑๑ ความดันไอ', item.vaporPressure ?? '-'),
              _buildFullDotted('๙.๑๒ ความหนาแน่นไอ', '-'),
              _buildFullDotted('๙.๑๓ ความหนาแน่นสัมพัทธ์', item.relativeDensity ?? '-'),
              _buildFullDotted('๙.๑๔ ความถ่วงจำเพาะ', item.relativeDensity ?? '-'),
              _buildFullDotted('๙.๑๕ ความสามารถในการละลายได้', item.solubility ?? '-'),
              _buildFullDotted('๙.๑๖ อุณหภูมิที่ลุกติดไฟได้เอง', '-'),
              _buildFullDotted('๙.๑๗ มวลโมเลกุล', '-'),
              _buildFullDotted('๙.๑๘ อื่นๆ', '-'),
              pw.SizedBox(height: 6),

              // ๑๐. ความเสถียร และการไวต่อปฏิกิริยา
              _buildMajorHeader('๑๐. ความเสถียร และการไวต่อปฏิกิริยา (Stability and Reactivity)'),
              _buildFullDotted('๑๐.๑ ความเสถียรทางเคมี', item.chemicalStability ?? 'เสถียรภายใต้สภาวะการเก็บรักษาและการใช้งานปกติ'),
              _buildFullDotted('๑๐.๒ สิ่งที่เข้ากันไม่ได้', item.incompatibleMaterials ?? 'สารออกซิไดซ์แรง, กรดแก่, ด่างแก่'),
              _buildFullDotted('๑๐.๓ วัตถุอื่นๆ ที่ควรหลีกเลี่ยง', item.incompatibleMaterials ?? '-'),
              _buildFullDotted('๑๐.๔ สภาวะที่ควรหลีกเลี่ยง', item.conditionsToAvoid ?? 'ความร้อนสูง ประกายไฟ แหล่งกำเนิดไฟ และแสงแดดโดยตรง'),
              _buildFullDotted('๑๐.๕ สารเคมีอันตรายหากเกิดการสลายตัว', item.hazardousDecompositionProducts ?? 'คาร์บอนมอนอกไซด์, คาร์บอนไดออกไซด์'),
              _buildFullDotted('๑๐.๖ อื่นๆ', item.reactivity ?? '-'),
              pw.SizedBox(height: 6),

              // ๑๑. ข้อมูลด้านพิษวิทยา
              _buildMajorHeader('๑๑. ข้อมูลด้านพิษวิทยา (Toxicological Information)'),
              _buildSubHeader('๑๑.๑ LD50/ LC50'),
              _buildFullDotted('โดยทางปาก (mg/kg)', item.acuteToxicity ?? '-'),
              _buildFullDotted('โดยทางผิวหนัง (mg/kg)', '-'),
              _buildFullDotted('โดยทางสูดหายใจ (mg/l)', '-'),
              _buildSubHeader('๑๑.๒ ความเป็นพิษ'),
              _buildFullDotted('การสูดหายใจ', item.inhalationFirstAid ?? '-'),
              _buildFullDotted('สัมผัสถูกผิวหนัง', item.skinCorrosionIrritation ?? '-'),
              _buildFullDotted('๑๑.๓ จัดอยู่ในกลุ่มสารก่อมะเร็ง/ก่อกลายพันธุ์ตาม', item.carcinogenicity ?? 'ไม่ได้จัดเป็นสารก่อมะเร็ง (IARC / OSHA)'),
              _buildFullDotted('๑๑.๔ อื่นๆ', item.reproductiveToxicity != null ? 'ความเป็นพิษต่อระบบสืบพันธุ์: ${item.reproductiveToxicity}' : '-'),
              pw.SizedBox(height: 6),

              // ๑๒. ข้อมูลผลกระทบต่อระบบนิเวศน์
              _buildMajorHeader('๑๒. ข้อมูลผลกระทบต่อระบบนิเวศน์ (Ecological Information)'),
              _buildFullDotted('๑๒.๑ ความเป็นพิษต่อระบบนิเวศน์', item.ecotoxicity ?? '-'),
              _buildFullDotted('๑๒.๒ การตกค้างยาวนาน', item.persistenceDegradability ?? '-'),
            ],
          );
        },
      ),
    );

    // =========================================================================
    // PAGE 4: หมวด ๑๒ (๑๒.๓), ๑๓, ๑๔, ๑๕, ๑๖ และลายมือชื่อ
    // =========================================================================
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.only(left: 36, right: 36, top: 28, bottom: 24),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('-๔-', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 6),

              _buildFullDotted('๑๒.๓ ผลกระทบอื่นๆ', item.bioaccumulativePotential != null ? 'ศักยภาพการสะสมทางชีวภาพ: ${item.bioaccumulativePotential}' : '-'),
              pw.SizedBox(height: 4),

              // ๑๓. ข้อพิจารณาในการกำจัด
              _buildMajorHeader('๑๓. ข้อพิจารณาในการกำจัด (Disposal Considerations)'),
              _buildFullDotted('การกำจัดสารเคมีและภาชนะบรรจุ', item.wasteTreatmentMethods ?? 'กำจัดตามกฎหมายว่าด้วยโรงงานและระเบียบการจัดการของเสียอันตราย ห้ามทิ้งลงสู่ท่อน้ำสาธารณะ'),
              pw.SizedBox(height: 4),

              // ๑๔. ข้อมูลเกี่ยวกับการขนส่ง
              _buildMajorHeader('๑๔. ข้อมูลเกี่ยวกับการขนส่ง (Transport Information)'),
              _buildFullDotted('๑๔.๑ หมายเลขสหประชาชาติ (UN Number)', item.unNumber ?? '-'),
              _buildFullDotted('๑๔.๒ ชื่อในการขนส่ง :', item.unProperShippingName ?? item.tradeName),
              _buildFullDotted('๑๔.๓ ประเภทความเป็นอันตรายสำหรับการขนส่ง (Transport Hazard Class)', item.transportHazardClass ?? '-'),
              _buildFullDotted('๑๔.๔ กลุ่มการบรรจุ (Packing Group)', item.packingGroup ?? '-'),
              _buildFullDotted('๑๔.๕ การขนส่งด้วยภาชนะขนาดใหญ่', item.marinePollutant ?? '-'),
              _buildFullDotted('๑๔.๖ อื่นๆ', item.specialPrecautionsTransport ?? '-'),
              pw.SizedBox(height: 4),

              // ๑๕. ข้อมูลเกี่ยวกับกฎ ระเบียบ ข้อบังคับของหน่วยงานที่เกี่ยวข้อง
              _buildMajorHeader('๑๕. ข้อมูลเกี่ยวกับกฎ ระเบียบ ข้อบังคับของหน่วยงานที่เกี่ยวข้อง (Regulatory Information)'),
              _buildFullDotted('๑๕.๑ กระทรวงแรงงาน', 'กฎกระทรวงสารเคมีอันตราย พ.ศ. ๒๕๕๖, ประกาศกรมสวัสดิการฯ เรื่อง แบบ สอ.๑'),
              _buildFullDotted('๑๕.๒ กระทรวงอุตสาหกรรม', item.hazardousSubstanceType != null ? 'พ.ร.บ. วัตถุอันตราย พ.ศ. ๒๕๓๕ (${item.hazardousSubstanceType})' : 'พ.ร.บ. วัตถุอันตราย พ.ศ. ๒๕๓๕'),
              _buildFullDotted('๑๕.๓ กระทรวงสาธารณสุข', '-'),
              _buildFullDotted('๑๕.๔ กระทรวงทรัพยากรธรรมชาติและสิ่งแวดล้อม', '-'),
              _buildFullDotted('๑๕.๕ กระทรวงคมนาคม', item.unNumber != null ? 'ข้อกำหนดการขนส่งสินค้าอันตรายทางถนนของประเทศไทย (ADR)' : '-'),
              _buildFullDotted('๑๕.๖ อื่นๆ', item.safetyHealthRegulations ?? '-'),
              pw.SizedBox(height: 4),

              // ๑๖. ข้อมูลอื่นๆ
              _buildMajorHeader('๑๖. ข้อมูลอื่นๆ (Other Information)'),
              _buildFullDotted('๑๖.๑ สัญลักษณ์ NFPA', 'สุขภาพ: ${item.nfpaHealth}, ไวไฟ: ${item.nfpaFlammability}, ความไม่เสถียร: ${item.nfpaInstability}, พิเศษ: ${item.nfpaSpecial ?? "-"}'),
              _buildFullDotted('๑๖.๒ แหล่งข้อมูลและเอกสารที่ใช้ทำรายละเอียดข้อมูลความปลอดภัยของสารเคมีอันตราย', item.referencesList ?? 'เอกสาร SDS จากผู้ผลิต / ผู้จัดจำหน่าย, ฐานข้อมูลความปลอดภัยสารเคมีสากล'),
              _buildFullDotted('๑๖.๓ อื่นๆ', item.versionNo != null ? 'ฉบับที่: ${item.versionNo}  |  ปรับปรุงล่าสุด: ${item.revisionDate ?? "-"}' : '-'),
              pw.SizedBox(height: 16),

              // Official Gazette Signature Block
              pw.Row(
                children: [
                  pw.Expanded(child: pw.Container()),
                  pw.SizedBox(
                    width: 250,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('ลงชื่อ..............................................................', style: const pw.TextStyle(fontSize: 9.5)),
                        pw.SizedBox(height: 4),
                        pw.Text('(.............................................................)', style: const pw.TextStyle(fontSize: 9.5)),
                        pw.SizedBox(height: 4),
                        pw.Text('ตำแหน่ง...............................................................', style: const pw.TextStyle(fontSize: 9.5)),
                        pw.SizedBox(height: 2),
                        pw.Text('นายจ้าง/ผู้แทน', style: const pw.TextStyle(fontSize: 9.5)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // Employer Company & Address Footer
              _buildFullDotted('บริษัท', companyName ?? item.manufacturerImporterInfo),
              _buildFullDotted('ที่อยู่', companyAddress ?? item.manufacturerImporterInfo),
              pw.Row(
                children: [
                  _buildInlineDotted('โทรศัพท์/โทรสาร', companyPhone ?? '-', flex: 4),
                  pw.SizedBox(width: 8),
                  _buildInlineDotted('E-mail', companyEmail ?? '-', flex: 4),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // =========================================================================
  // STATUTORY FORMATTING HELPERS
  // =========================================================================
  static pw.Widget _buildMajorHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2, bottom: 1),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
      ),
    );
  }

  static pw.Widget _buildSubHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 10, top: 1, bottom: 1),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
      ),
    );
  }

  static pw.Widget _buildFullDotted(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('$label ', style: const pw.TextStyle(fontSize: 8.5)),
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.5, style: pw.BorderStyle.dotted),
                ),
              ),
              child: pw.Text(
                value.isNotEmpty && value != '-' ? value : ' ',
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInlineDotted(String label, String value, {int flex = 1}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('$label ', style: const pw.TextStyle(fontSize: 8.5)),
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.5, style: pw.BorderStyle.dotted),
                ),
              ),
              child: pw.Text(
                value.isNotEmpty && value != '-' ? value : ' ',
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildIngredientsTable(ChemicalSdsSor1Model item) {
    final ingredients = item.ingredients;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(60),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(1.5),
        5: pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header Row 1
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(3),
              alignment: pw.Alignment.center,
              child: pw.Text('องค์ประกอบ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(3),
              alignment: pw.Alignment.center,
              child: pw.Text('ชื่อสารเคมี', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(3),
              alignment: pw.Alignment.center,
              child: pw.Text('CAS. No.', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(3),
              alignment: pw.Alignment.center,
              child: pw.Text('ปริมาณโดยน้ำหนัก\n(% by weight)', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(3),
              alignment: pw.Alignment.center,
              child: pw.Text('TLV', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(3),
              alignment: pw.Alignment.center,
              child: pw.Text('LD50', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
            ),
          ],
        ),

        // Rows ๑, ๒, ๓, ๔
        ...List.generate(4, (index) {
          final thaiNum = ['๑.', '๒.', '๓.', '๔.'][index];
          final ing = index < ingredients.length ? ingredients[index] : null;

          return pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(thaiNum, style: const pw.TextStyle(fontSize: 8)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(ing?.chemicalName ?? (index == 0 ? item.tradeName : '-'), style: const pw.TextStyle(fontSize: 8)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(ing?.casNumber ?? (index == 0 ? item.casNumber : '-'), style: const pw.TextStyle(fontSize: 8)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(ing != null ? '${ing.percentage}%' : (index == 0 ? '100%' : '-'), style: const pw.TextStyle(fontSize: 8)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(ing?.tlvPel ?? (index == 0 && item.exposureLimits != null ? item.exposureLimits! : '-'), style: const pw.TextStyle(fontSize: 7.5)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(index == 0 && item.acuteToxicity != null ? item.acuteToxicity! : '-', style: const pw.TextStyle(fontSize: 7.5)),
              ),
            ],
          );
        }),
      ],
    );
  }
}
