import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/models/chemical_sds_sor1_model.dart';

/// Official Statutory PDF Generator for Form สอ.๑ (SDS 16 Sections)
/// Conforming to DLPW Notification B.E. 2556 (แบบ สอ.๑).
class ChemicalSor1PdfService {
  /// Generates the complete multi-page PDF document as bytes.
  static Future<Uint8List> generatePdf(
    ChemicalSdsSor1Model item, {
    String? companyName,
    String? companyAddress,
  }) async {
    final doc = pw.Document();

    final fontRegular = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();
    final fontItalic = await PdfGoogleFonts.sarabunItalic();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
    );

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
                  pw.Text(
                    'กรมสวัสดิการและคุ้มครองแรงงาน (กฎกระทรวงสารเคมีอันตราย พ.ศ. ๒๕๕๖)',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blue900, width: 1),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'แบบ สอ.๑',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
            ],
          );
        },
        footer: (pw.Context ctx) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('แบบ สอ.๑: ${item.tradeName} (CAS: ${item.casNumber})', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('หน้าที่ ${ctx.pageNumber} จาก ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
        build: (pw.Context ctx) {
          return [
            // Title Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'แบบบัญชีรายชื่อสารเคมีอันตรายและรายละเอียดข้อมูลความปลอดภัยของสารเคมีอันตราย\n(SAFETY DATA SHEET - แบบ สอ.๑)',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'ชื่อสารเคมี / ชื่อทางการค้า: ${item.tradeName}  |  CAS Number: ${item.casNumber}  |  UN Number: ${item.unNumber ?? "-"}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // SECTION 1
            _buildSectionHeader(1, 'ข้อมูลเกี่ยวกับสารเคมีอันตรายและบริษัทผู้ผลิตหรือจำหน่าย (Identification)'),
            _buildInfoRow('ชื่อผลิตภัณฑ์ / ชื่อทางการค้า', item.tradeName),
            _buildInfoRow('สูตรทางเคมี (Formula)', item.chemicalFormula ?? '-'),
            _buildInfoRow('CAS Number / UN Number', '${item.casNumber} / ${item.unNumber ?? "-"}'),
            _buildInfoRow('ผู้ผลิต / ผู้นำเข้า / ผู้แทนจำหน่าย', item.manufacturerImporterInfo.isNotEmpty ? item.manufacturerImporterInfo : (companyName ?? '-')),
            _buildInfoRow('เบอร์โทรศัพท์ฉุกเฉิน 24 ชม.', item.emergencyPhone ?? '-'),
            _buildInfoRow('การใช้งานที่แนะนำและข้อจำกัด', item.recommendedUse ?? '-'),
            pw.SizedBox(height: 8),

            // SECTION 2
            _buildSectionHeader(2, 'การบ่งชี้ความเป็นอันตราย (Hazard Identification)'),
            _buildInfoRow('การจำแนกประเภทความเป็นอันตราย GHS', item.ghsClassification ?? '-'),
            _buildInfoRow('คำสัญญาณ (Signal Word)', item.signalWord == 'DANGER' ? 'อันตราย (DANGER)' : item.signalWord == 'WARNING' ? 'ระวัง (WARNING)' : 'ไม่มี'),
            _buildInfoRow('สัญลักษณ์แสดงความเป็นอันตราย GHS', item.ghsPictograms.isNotEmpty ? item.ghsPictograms.join(', ') : 'ไม่มี'),
            _buildInfoRow('ระดับความเป็นอันตราย NFPA 704', 'สุขภาพ: ${item.nfpaHealth} | ไวไฟ: ${item.nfpaFlammability} | ไวต่อปฏิกิริยา: ${item.nfpaInstability} ${item.nfpaSpecial != null && item.nfpaSpecial!.isNotEmpty ? "| พิเศษ: ${item.nfpaSpecial}" : ""}'),
            _buildInfoRow('ข้อความแสดงความเป็นอันตราย (H-Statements)', item.hazardStatements.isNotEmpty ? item.hazardStatements.join('; ') : '-'),
            _buildInfoRow('ข้อควรระวัง (P-Statements)', item.precautionaryStatements.isNotEmpty ? item.precautionaryStatements.join('; ') : '-'),
            pw.SizedBox(height: 8),

            // SECTION 3
            _buildSectionHeader(3, 'ส่วนประกอบและข้อมูลเกี่ยวกับส่วนผสม (Composition / Ingredients)'),
            if (item.ingredients.isEmpty)
              _buildInfoRow('สารเดี่ยว / สารผสม', 'สารเดี่ยวบริสุทธิ์ (Pure Substance) CAS: ${item.casNumber}')
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('ลำดับ', isHeader: true, flex: 1),
                      _buildTableCell('ชื่อสารเคมีส่วนประกอบ', isHeader: true, flex: 4),
                      _buildTableCell('CAS Number', isHeader: true, flex: 3),
                      _buildTableCell('ร้อยละโดยน้ำหนัก (%wt)', isHeader: true, flex: 2),
                    ],
                  ),
                  ...item.ingredients.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final ing = entry.value;
                    return pw.TableRow(
                      children: [
                        _buildTableCell('$idx', flex: 1),
                        _buildTableCell(ing.chemicalName, flex: 4),
                        _buildTableCell(ing.casNumber, flex: 3),
                        _buildTableCell('${ing.percentage} %', flex: 2),
                      ],
                    );
                  }),
                ],
              ),
            pw.SizedBox(height: 8),

            // SECTION 4
            _buildSectionHeader(4, 'มาตรการปฐมพยาบาล (First-Aid Measures)'),
            _buildInfoRow('กรณีสูดดม (Inhalation)', item.inhalationFirstAid ?? 'ย้ายผู้ป่วยไปยังที่อากาศบริสุทธิ์ ให้ออกซิเจนหากหายใจลำบาก นำส่งแพทย์ทันที'),
            _buildInfoRow('กรณีสัมผัสผิวหนัง (Skin Contact)', item.skinContactFirstAid ?? 'ถอดเสื้อผ้าที่ปนเปื้อน ล้างผิวหนังด้วยน้ำสะอาดและสบู่ปริมาณมากอย่างน้อย 15 นาที'),
            _buildInfoRow('กรณีสัมผัสดวงตา (Eye Contact)', item.eyeContactFirstAid ?? 'ล้างตาทันทีด้วยน้ำสะอาดปริมาณมากอย่างน้อย 15 นาที เปิดเปลือกตาบนและล่าง'),
            _buildInfoRow('กรณีกลืนกิน (Ingestion)', item.ingestionFirstAid ?? 'ห้ามทำให้อาเจียน ให้ดื่มน้ำสะอาด นำส่งแพทย์พร้อมฉลากหรือ SDS ทันที'),
            _buildInfoRow('อาการสำคัญและผลกระทบ', item.symptomsEffects ?? '-'),
            pw.SizedBox(height: 8),

            // SECTION 5
            _buildSectionHeader(5, 'มาตรการผจญเพลิง (Fire-Fighting Measures)'),
            _buildInfoRow('สารดับเพลิงที่เหมาะสม', item.suitableExtinguishingMedia ?? 'ผงเคมีแห้ง (Dry Chemical), โฟมทนแอลกอฮอล์, คาร์บอนไดออกไซด์ (CO2)'),
            _buildInfoRow('สารดับเพลิงที่ไม่เหมาะสม/ห้ามใช้', item.unsuitableExtinguishingMedia ?? 'ห้ามฉีดน้ำเป็นลำตรง (Water Jet)'),
            _buildInfoRow('อันตรายเฉพาะจากสารเคมี', item.specificFireHazards ?? 'ไอระเหยหนักกว่าอากาศ อาจไหลไปสู่แหล่งจุดติดไฟได้'),
            _buildInfoRow('อุปกรณ์ป้องกันสำหรับนักผจญเพลิง', item.protectiveEquipmentFirefighters ?? 'ชุดผจญเพลิงเต็มรูปแบบ พร้อมเครื่องช่วยหายใจ SCBA'),
            pw.SizedBox(height: 8),

            // SECTION 6
            _buildSectionHeader(6, 'มาตรการจัดการเมื่อหกรั่วไหล (Accidental Release Measures)'),
            _buildInfoRow('ข้อควรระวังส่วนบุคคลและอุปกรณ์', item.personalPrecautions ?? 'อพยพผู้ไม่เกี่ยวข้อง สวมอุปกรณ์ PPE กำจัดประกายไฟทุกชนิด'),
            _buildInfoRow('ข้อควรระวังด้านสิ่งแวดล้อม', item.environmentalPrecautions ?? 'ป้องกันไม่ให้สารเคมีไหลลงสู่แหล่งน้ำสาธารณะ ท่อระบายน้ำ หรือดิน'),
            _buildInfoRow('วิธีการกักเก็บและทำความสะอาด', item.containmentCleanUp ?? 'ดูดซับด้วยทรายแห้งหรือวัสดุดูดซับเฉื่อย เก็บในภาชนะปิดเพื่อกำจัด'),
            pw.SizedBox(height: 8),

            // SECTION 7
            _buildSectionHeader(7, 'การขนถ่าย เคลื่อนย้าย ใช้งาน และการเก็บรักษา (Handling & Storage)'),
            _buildInfoRow('ข้อควรระวังในการขนถ่าย/ใช้งาน', item.handlingPrecautions ?? 'ใช้งานในพื้นที่ระบายอากาศดี ต่อสายดินป้องกันไฟฟ้าสถิต ห้ามสูบบุหรี่'),
            _buildInfoRow('สภาวะและเงื่อนไขการจัดเก็บ', item.storageConditions ?? 'เก็บในที่แห้ง เย็น อากาศถ่ายเท ปิดภาชนะให้แน่น ห่างจากความร้อน'),
            pw.SizedBox(height: 8),

            // SECTION 8
            _buildSectionHeader(8, 'การควบคุมการรับสัมผัสและการป้องกันส่วนบุคคล (Exposure Controls & PPE)'),
            _buildInfoRow('ค่าขีดจำกัดความเข้มข้น (TLV/PEL)', item.exposureLimits ?? 'ตามประกาศกรมสวัสดิการและคุ้มครองแรงงาน (๓๒๔ รายการ)'),
            _buildInfoRow('การควบคุมทางวิศวกรรม', item.engineeringControls ?? 'ระบบระบายอากาศเฉพาะที่ (Local Exhaust Ventilation) ป้องกันการฟุ้งกระจาย'),
            _buildInfoRow('อุปกรณ์ป้องกันระบบหายใจ', item.respiratoryProtection ?? 'หน้ากากไส้กรองสารเคมีและไอระเหยอินทรีย์ (Organic Vapor Cartridge)'),
            _buildInfoRow('การป้องกันผิวหนังและมือ', item.skinHandProtection ?? 'ถุงมือทนสารเคมี (Nitrile/Neoprene), ชุดกาวน์ทนสารเคมี'),
            _buildInfoRow('การป้องกันดวงตาและใบหน้า', item.eyeProtection ?? 'แว่นครอบตานิรภัยป้องกันสารเคมีกระเด็น (Chemical Splash Goggles)'),
            pw.SizedBox(height: 8),

            // SECTION 9
            _buildSectionHeader(9, 'คุณสมบัติทางกายภาพและเคมี (Physical & Chemical Properties)'),
            _buildInfoRow('ลักษณะภายนอกและกลิ่น', '${item.appearance ?? "-"} | กลิ่น: ${item.odor ?? "-"}'),
            _buildInfoRow('ค่า pH / จุดเดือด (°C)', '${item.phValue ?? "N/A"} / ${item.boilingPoint ?? "-"}'),
            _buildInfoRow('จุดวาบไฟ (°C) / ความถ่วงจำเพาะ', '${item.flashPoint ?? "-"} / ${item.relativeDensity ?? "-"}'),
            _buildInfoRow('ความสามารถในการละลาย / ความดันไอ', '${item.solubility ?? "-"} / ${item.vaporPressure ?? "-"}'),
            pw.SizedBox(height: 8),

            // SECTION 10
            _buildSectionHeader(10, 'ความเสถียรและความไวต่อปฏิกิริยา (Stability & Reactivity)'),
            _buildInfoRow('ความคงตัวทางเคมี', item.chemicalStability ?? 'เสถียรภายใต้สภาวะการจัดเก็บและการใช้งานตามปกติ'),
            _buildInfoRow('สภาวะที่ต้องหลีกเลี่ยง', item.conditionsToAvoid ?? 'ความร้อน ประกายไฟ เปลวไฟ และแสงแดดโดยตรง'),
            _buildInfoRow('สารที่เข้ากันไม่ได้', item.incompatibleMaterials ?? 'สารออกซิไดซ์เข้มข้น, กรดแก่, ด่างแก่'),
            _buildInfoRow('สารสลายตัวอันตราย', item.hazardousDecompositionProducts ?? 'คาร์บอนมอนอกไซด์ (CO), คาร์บอนไดออกไซด์ (CO2)'),
            pw.SizedBox(height: 8),

            // SECTION 11
            _buildSectionHeader(11, 'ข้อมูลด้านพิษวิทยา (Toxicological Information)'),
            _buildInfoRow('ความเป็นพิษเฉียบพลัน (LD50/LC50)', item.acuteToxicity ?? '-'),
            _buildInfoRow('การกัดกร่อน / ระคายเคือง', item.skinCorrosionIrritation ?? '-'),
            _buildInfoRow('การก่อมะเร็ง (Carcinogenicity)', item.carcinogenicity ?? 'ไม่จัดเป็นสารก่อมะเร็งตามมาตรฐานสากล'),
            _buildInfoRow('ความเป็นพิษต่ออวัยวะเป้าหมาย', item.targetOrganToxicity ?? '-'),
            pw.SizedBox(height: 8),

            // SECTION 12
            _buildSectionHeader(12, 'ข้อมูลผลกระทบต่อระบบนิเวศน์ (Ecological Information)'),
            _buildInfoRow('ความเป็นพิษต่อสิ่งแวดล้อมทางน้ำ', item.ecotoxicity ?? '-'),
            _buildInfoRow('การตกค้างและการย่อยสลาย', item.persistenceDegradability ?? '-'),
            _buildInfoRow('การสะสมทางชีวภาพ (Bioaccumulation)', item.bioaccumulativePotential ?? '-'),
            pw.SizedBox(height: 8),

            // SECTION 13
            _buildSectionHeader(13, 'ข้อพิจารณาในการกำจัด (Disposal Considerations)'),
            _buildInfoRow('วิธีกำจัดของเสียสารเคมี', item.wasteTreatmentMethods ?? 'ส่งกำจัดโดยผู้รับบำบัดกำจัดกากอุตสาหกรรมที่ได้รับอนุญาตตามกฎหมายกรมโรงงานฯ'),
            _buildInfoRow('การกำจัดบรรจุภัณฑ์ปนเปื้อน', item.contaminatedPackaging ?? 'กำจัดเช่นเดียวกับของเสียสารเคมีอันตราย ห้ามนำกลับมาใช้ใหม่'),
            pw.SizedBox(height: 8),

            // SECTION 14
            _buildSectionHeader(14, 'ข้อมูลการขนส่ง (Transport Information)'),
            _buildInfoRow('UN Number / Proper Shipping Name', '${item.unNumber ?? "-"} / ${item.unProperShippingName ?? item.tradeName}'),
            _buildInfoRow('Transport Hazard Class / Packing Group', 'Class ${item.transportHazardClass ?? "-"} / ${item.packingGroup ?? "-"}'),
            _buildInfoRow('มลพิษทางทะเล (Marine Pollutant)', item.marinePollutant ?? 'ไม่ใช่'),
            pw.SizedBox(height: 8),

            // SECTION 15
            _buildSectionHeader(15, 'ข้อมูลด้านกฎหมายและข้อบังคับ (Regulatory Information)'),
            _buildInfoRow('กฎหมายและข้อกำหนดที่เกี่ยวข้อง', item.safetyHealthRegulations ?? 'พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔, กฎกระทรวงสารเคมีอันตราย ๒๕๕๖, พ.ร.บ. วัตถุอันตราย'),
            _buildInfoRow('ประเภทวัตถุอันตราย', item.hazardousSubstanceType ?? '-'),
            pw.SizedBox(height: 8),

            // SECTION 16
            _buildSectionHeader(16, 'ข้อมูลอื่นๆ (Other Information)'),
            _buildInfoRow('วันที่จัดทำ / ทบทวนล่าสุด', item.revisionDate ?? '-'),
            _buildInfoRow('ครั้งที่แก้ไข (Revision No.)', item.versionNo ?? '1.0'),
            _buildInfoRow('ผู้จัดทำ / ผู้รับรองข้อมูล', item.preparedBy ?? 'เจ้าหน้าที่ความปลอดภัยในการทำงานระดับวิชาชีพ (จป.วิชาชีพ)'),
            _buildInfoRow('เอกสารอ้างอิง', item.referencesList ?? 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน, ACGIH, NIOSH, UN GHS Rev.8'),
            pw.SizedBox(height: 20),

            // Signatures block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  width: 220,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('ลงชื่อ .....................................................', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 4),
                      pw.Text('( ${item.preparedBy?.isNotEmpty == true ? item.preparedBy : "....................................................."} )', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('เจ้าหน้าที่ความปลอดภัยในการทำงาน (จป.)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.Text('วันที่: ${item.revisionDate ?? "......./......./......."}', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
                pw.Container(
                  width: 220,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('ลงชื่อ .....................................................', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 4),
                      pw.Text('( ..................................................... )', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('นายจ้าง / ผู้มีอำนาจลงนามผูกพันนิติบุคคล', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.Text('วันที่: ....... / ....... / .......', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return await doc.save();
  }

  /// Displays the interactive print preview and PDF exporter dialog.
  static Future<void> printOrShare(
    BuildContext context,
    ChemicalSdsSor1Model item, {
    String? companyName,
    String? companyAddress,
  }) async {
    final bytes = await generatePdf(item, companyName: companyName, companyAddress: companyAddress);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Form_SorOr1_${item.casNumber.replaceAll("-", "")}.pdf',
    );
  }

  static pw.Widget _buildSectionHeader(int sectionNo, String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4, bottom: 4),
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Text(
        'หมวดที่ $sectionNo: $title',
        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 175,
            child: pw.Text('• $label:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
          ),
          pw.Expanded(
            child: pw.Text(value.isNotEmpty ? value : '-', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, int flex = 1}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: isHeader ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blue900 : PdfColors.black,
        ),
      ),
    );
  }
}
