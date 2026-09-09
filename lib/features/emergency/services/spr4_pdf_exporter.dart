import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../data/models/drill_session_model.dart';
import '../data/models/emergency_plan_model.dart';
import '../domain/enums/emergency_enums.dart';

class Spr4PdfExporter {
  Future<pw.Font?> _loadFont(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        return pw.Font.ttf(bytes.buffer.asByteData());
      }
      final data = await rootBundle.load(path);
      return pw.Font.ttf(data);
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> generatePdf({
    required DrillSessionModel drill,
    EmergencyPlanModel? plan,
  }) async {
    final regularFont = await _loadFont('google_fonts/Prompt-Regular.ttf');
    final boldFont = await _loadFont('google_fonts/Prompt-Bold.ttf');

    final doc = pw.Document(
      title: 'แบบ สปร. ๔ - ${drill.drillTitle}',
      author: plan?.companyName ?? 'สถานประกอบกิจการ',
      subject: 'แบบรายงานผลการฝึกซ้อมดับเพลิงและฝึกซ้อมอพยพหนีไฟ',
    );

    final theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        ),
        header: (context) => _buildHeader(),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildFormTitle(drill),
          pw.SizedBox(height: 10),
          _buildCompanySection(drill, plan),
          pw.SizedBox(height: 10),
          _buildDrillDetailsSection(drill),
          pw.SizedBox(height: 10),
          _buildOrganizerSection(drill),
          pw.SizedBox(height: 10),
          _buildDrillResultsSection(drill),
          pw.SizedBox(height: 10),
          _buildProblemsAndImprovement(drill),
          pw.SizedBox(height: 16),
          _buildSignatures(drill, plan),
          if (drill.attachments.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildPhotoAnnex(drill),
          ],
        ],
      ),
    );

    return doc.save();
  }

  Future<String> savePdf({
    required DrillSessionModel drill,
    EmergencyPlanModel? plan,
  }) async {
    final bytes = await generatePdf(drill: drill, plan: plan);
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/spr4_reports');
    if (!exportDir.existsSync()) exportDir.createSync(recursive: true);
    final fileName = 'SPR4_${drill.drillYear}_Drill_${drill.id ?? 1}.pdf';
    final file = File('${exportDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      alignment: pw.Alignment.topRight,
      child: pw.Text(
        'แบบ สปร. ๔',
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('แบบรายงานตามประกาศกรมสวัสดิการและคุ้มครองแรงงาน (ส่งภายใน ๓๐ วันนับแต่วันซ้อม)', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
          pw.Text('หน้า ${context.pageNumber} จาก ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _buildFormTitle(DrillSessionModel drill) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            'แบบรายงานผลการฝึกซ้อมดับเพลิงและฝึกซ้อมอพยพหนีไฟ',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Center(
          child: pw.Text(
            'ตามกฎกระทรวงกำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย\nและสภาพแวดล้อมในการทำงานเกี่ยวกับการป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕ ข้อ ๓๐',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCompanySection(DrillSessionModel drill, EmergencyPlanModel? plan) {
    final name = plan?.companyName ?? 'บริษัท ตัวอย่างอุตสาหกรรม จำกัด';
    final address = plan?.companyAddress ?? '-';
    final total = drill.totalWorkersOnSite > 0 ? drill.totalWorkersOnSite : (plan?.totalEmployees ?? 0);
    final male = plan?.maleCount ?? 0;
    final female = plan?.femaleCount ?? 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('๑. ข้อมูลสถานประกอบกิจการ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text('ชื่อสถานประกอบกิจการ: $name', style: const pw.TextStyle(fontSize: 8)),
          pw.Text('ที่ตั้ง: $address', style: const pw.TextStyle(fontSize: 8)),
          pw.Text('จำนวนลูกจ้างทั้งหมด: $total คน (ชาย: $male คน, หญิง: $female คน)', style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  pw.Widget _buildDrillDetailsSection(DrillSessionModel drill) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('๒. วัน เวลา และสถานที่ทำการฝึกซ้อม', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text('วันที่ฝึกซ้อม: ${drill.drillDate} เวลา: ${drill.startTime} - ${drill.endTime} น.', style: const pw.TextStyle(fontSize: 8)),
          pw.Text('สถานที่ฝึกซ้อม: ${drill.incidentLocation.isNotEmpty ? drill.incidentLocation : "ภายในบริเวณสถานประกอบกิจการ"}', style: const pw.TextStyle(fontSize: 8)),
          pw.Text('หัวข้อการฝึกซ้อม: ${drill.drillTitle}', style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  pw.Widget _buildOrganizerSection(DrillSessionModel drill) {
    final isSelf = drill.organizerType == DrillOrganizerType.selfApproved;
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('๓. ผู้ดำเนินการฝึกซ้อม', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          if (isSelf) ...[
            pw.Text('นายจ้างจัดให้มีการฝึกซ้อมเอง โดยได้รับความเห็นชอบแผนและรายละเอียดการฝึกซ้อม', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('ตามหนังสือเลขที่: ${drill.approvalCertNo.isNotEmpty ? drill.approvalCertNo : "-"} ลงวันที่: ${drill.approvalDate.isNotEmpty ? drill.approvalDate : "-"}', style: const pw.TextStyle(fontSize: 8)),
          ] else ...[
            pw.Text('หน่วยงานที่ได้รับการขึ้นทะเบียนเพื่อให้บริการฝึกอบรมและฝึกซ้อมดับเพลิง (ตามมาตรา ๑๑)', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('ชื่อหน่วยงาน: ${drill.organizerName.isNotEmpty ? drill.organizerName : "-"} เลขทะเบียน: ${drill.approvalCertNo.isNotEmpty ? drill.approvalCertNo : "-"}', style: const pw.TextStyle(fontSize: 8)),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildDrillResultsSection(DrillSessionModel drill) {
    final rateStr = drill.participationRatePercent > 0
        ? '${drill.participationRatePercent.toStringAsFixed(1)}%'
        : drill.totalWorkersOnSite > 0
            ? '${((drill.participatedCount / drill.totalWorkersOnSite) * 100).toStringAsFixed(1)}%'
            : '100%';

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('๔. ผลการฝึกซ้อม', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text('๔.๑ จำนวนผู้เข้าร่วมฝึกซ้อม: รวม ${drill.participatedCount} คน (ชาย: ${drill.maleParticipants} คน, หญิง: ${drill.femaleParticipants} คน)', style: const pw.TextStyle(fontSize: 8)),
          pw.Text('     คิดเป็นร้อยละ: $rateStr ของจำนวนลูกจ้างทั้งหมดในวันที่ทำการฝึกซ้อม', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text('๔.๒ การจำลองสถานการณ์: ${drill.scenarioDescription.isNotEmpty ? drill.scenarioDescription : "จำลองเหตุเพลิงไหม้ขั้นต้น ณ โซนปฏิบัติการ และไม่สามารถดับได้ จึงสั่งอพยพ"}', style: const pw.TextStyle(fontSize: 8)),
          pw.Text('     แหล่งกำเนิดเพลิง: ${drill.fireOrHazardSource.isNotEmpty ? drill.fireOrHazardSource : "ไฟฟ้าลัดวงจร/ประกายไฟ"}', style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 2),
          pw.Text('๔.๓ สถิติเวลาในการปฏิบัติการ:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.Text('     - เวลาเข้าดับเพลิงขั้นต้น: ${drill.initialAttackTimeSec} วินาที', style: const pw.TextStyle(fontSize: 8)),
          pw.Text('     - เวลาที่ใช้อพยพทุกคนถึงจุดรวมพล: ${drill.evacuationTimeSec} วินาที (${(drill.evacuationTimeSec / 60).toStringAsFixed(1)} นาที)', style: const pw.TextStyle(fontSize: 8)),
          pw.Text('๔.๔ ผลการตรวจนับยอดพนักงาน ณ จุดรวมพล: ${drill.headcountStatus.label}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          if (drill.simulatedInjuriesCount > 0)
            pw.Text('     - มีการจำลองผู้บาดเจ็บ: ${drill.simulatedInjuriesCount} ราย (ทีมปฐมพยาบาลเข้าช่วยเหลือและนำส่ง รพ. จำลอง)', style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  pw.Widget _buildProblemsAndImprovement(DrillSessionModel drill) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('๕. ปัญหา อุปสรรค และข้อเสนอแนะในการปรับปรุง', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text('ปัญหาและอุปสรรค: ${drill.problemsAndObstacles.isNotEmpty ? drill.problemsAndObstacles : "ไม่มีปัญหาอุปสรรคสำคัญ พนักงานให้ความร่วมมือดี"}', style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 2),
          pw.Text('แนวทางแก้ไขและข้อเสนอแนะ: ${drill.improvementActions.isNotEmpty ? drill.improvementActions : "ทบทวนแผนและฝึกอบรมทบทวนผู้นำทางหนีไฟเป็นประจำทุกปี"}', style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 2),
          pw.Text('กำหนดส่งรายงาน สปร. ๔ ภายใน: ${drill.submissionDeadline} (๓๐ วันนับแต่วันฝึกซ้อม)', style: pw.TextStyle(fontSize: 8, color: PdfColors.red800)),
        ],
      ),
    );
  }

  pw.Widget _buildSignatures(DrillSessionModel drill, EmergencyPlanModel? plan) {
    final commander = plan?.fireCommanderName ?? drill.evaluatorName;
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Container(width: 140, height: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),
              pw.Text('ลงชื่อ .....................................................', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('( $commander )', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('นายจ้าง / ผู้มีอำนาจลงนามผูกพันนิติบุคคล', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
            ],
          ),
          pw.Column(
            children: [
              pw.Container(width: 140, height: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),
              pw.Text('ลงชื่อ .....................................................', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('( ${drill.evaluatorName.isNotEmpty ? drill.evaluatorName : "เจ้าหน้าที่ความปลอดภัยในการทำงาน"} )', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('ผู้ประเมินผลการฝึกซ้อม (จป.วิชาชีพ)', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPhotoAnnex(DrillSessionModel drill) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('เอกสารและรูปภาพประกอบการฝึกซ้อม (Annex)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text('พบรูปถ่ายหลักฐานการฝึกซ้อมจำนวน ${drill.attachments.length} รายการ', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ],
    );
  }
}
