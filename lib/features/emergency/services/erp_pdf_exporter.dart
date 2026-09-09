import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../data/models/emergency_plan_model.dart';

class ErpPdfExporter {
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

  Future<Uint8List> generatePdf(EmergencyPlanModel plan) async {
    final regularFont = await _loadFont('google_fonts/Prompt-Regular.ttf');
    final boldFont = await _loadFont('google_fonts/Prompt-Bold.ttf');

    final doc = pw.Document(
      title: plan.planTitle,
      author: plan.companyName,
      subject: 'Emergency Response Plan - ${plan.hazardType.titleTh}',
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
        header: (context) => _buildHeader(plan),
        footer: (context) => _buildFooter(context, plan),
        build: (context) => [
          _buildCoverSection(plan),
          pw.SizedBox(height: 16),
          _buildPillar1Inspection(plan),
          pw.SizedBox(height: 14),
          _buildPillar2Training(plan),
          pw.SizedBox(height: 14),
          _buildPillar3Campaign(plan),
          pw.SizedBox(height: 14),
          _buildPillar4Suppression(plan),
          pw.SizedBox(height: 14),
          _buildPillar5Evacuation(plan),
          pw.SizedBox(height: 14),
          _buildPillar6Relief(plan),
          pw.SizedBox(height: 20),
          _buildSignatures(plan),
        ],
      ),
    );

    return doc.save();
  }

  Future<String> savePdf(EmergencyPlanModel plan) async {
    final bytes = await generatePdf(plan);
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/emergency_plans');
    if (!exportDir.existsSync()) exportDir.createSync(recursive: true);
    final fileName = 'ERP_${plan.hazardType.code}_v${plan.version.replaceAll('.', '_')}.pdf';
    final file = File('${exportDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  pw.Widget _buildHeader(EmergencyPlanModel plan) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 6),
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.red800, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'แผนป้องกันและระงับเหตุฉุกเฉิน (Emergency Response Plan)',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
              ),
              pw.Text(
                plan.companyName.isNotEmpty ? plan.companyName : 'สถานประกอบกิจการ',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('ประเภท: ${plan.hazardType.shortTitle}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text('ฉบับที่: ${plan.version} | สถานะ: ${plan.status.label}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, EmergencyPlanModel plan) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      margin: const pw.EdgeInsets.only(top: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('อ้างอิง: ${plan.hazardType.legalBasis}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
          pw.Text('หน้า ${context.pageNumber} จาก ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _buildCoverSection(EmergencyPlanModel plan) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            plan.planTitle,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(child: _infoCell('ประเภทสถานประกอบการ', plan.businessType.label)),
              pw.Expanded(child: _infoCell('จำนวนพนักงานทั้งหมด', '${plan.totalEmployees} คน (ชาย ${plan.maleCount} / หญิง ${plan.femaleCount})')),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _infoCell('ผู้อำนวยการระงับเหตุ', '${plan.fireCommanderName} (${plan.commanderPhone})')),
              pw.Expanded(child: _infoCell('ผู้ช่วยผู้อำนวยการ', plan.deputyCommanderName)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _infoCell('วันที่มีผลบังคับใช้', plan.effectiveDate)),
              pw.Expanded(child: _infoCell('รอบการทบทวนถัดไป', plan.reviewDate)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _infoCell(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.Text(value.isNotEmpty ? value : '-', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _sectionTitle(String number, String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      margin: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        color: PdfColors.red700,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Text(
        '$number $title',
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      ),
    );
  }

  pw.Widget _buildPillar1Inspection(EmergencyPlanModel plan) {
    final items = plan.inspectionPlan.items;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('๑.', 'แผนการตรวจตรา (Inspection Plan)'),
        pw.Text('ความถี่และขั้นตอน: ${plan.inspectionPlan.frequencyDescription}', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 4),
        if (items.isEmpty)
          pw.Text('- ไม่มีรายการตรวจตรา -', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))
        else
          pw.TableHelper.fromTextArray(
            headers: ['ลำดับ', 'หมวดหมู่อุปกรณ์/จุดเสี่ยง', 'พื้นที่รับผิดชอบ', 'ความถี่', 'ผู้ตรวจตรา'],
            data: List.generate(items.length, (i) {
              final it = items[i];
              return ['${i + 1}', it.category, it.area, it.frequency, it.inspectorRole];
            }),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(3),
          ),
      ],
    );
  }

  pw.Widget _buildPillar2Training(EmergencyPlanModel plan) {
    final courses = plan.trainingPlan.courses;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('๒.', 'แผนการอบรม (Training Plan)'),
        pw.Text('เป้าหมายการอบรมดับเพลิงขั้นต้นตามกฎหมาย: ไม่น้อยกว่าร้อยละ ${plan.trainingPlan.basicFireQuotaPercent}% ของลูกจ้างทุกแผนก | เป้าหมายซ้อมใหญ่: เดือน${plan.trainingPlan.annualDrillTargetMonth}', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 4),
        if (courses.isEmpty)
          pw.Text('- ไม่พบหลักสูตรอบรม -', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))
        else
          pw.TableHelper.fromTextArray(
            headers: ['ลำดับ', 'ชื่อหลักสูตรอบรม', 'กลุ่มเป้าหมาย', 'ผู้ดำเนินการจัดอบรม', 'ความถี่'],
            data: List.generate(courses.length, (i) {
              final c = courses[i];
              return ['${i + 1}', c.courseName, c.targetAudience, c.provider, c.frequency];
            }),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(3),
          ),
      ],
    );
  }

  pw.Widget _buildPillar3Campaign(EmergencyPlanModel plan) {
    final acts = plan.campaignPlan.activities;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('๓.', 'แผนการรณรงค์ป้องกันอัคคีภัย/สาธารณภัย (Campaign Plan)'),
        pw.Text('นโยบายการควบคุมการสูบบุหรี่: ${plan.campaignPlan.smokingControlPolicy}', style: const pw.TextStyle(fontSize: 8)),
        pw.Text('มาตรการงานประกายไฟ/ความร้อน: ${plan.campaignPlan.hotWorkSafetyReminder}', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 4),
        pw.Text('กิจกรรมรณรงค์:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ...acts.map((a) => pw.Padding(
          padding: const pw.EdgeInsets.only(left: 8, top: 1),
          child: pw.Text('• $a', style: const pw.TextStyle(fontSize: 8)),
        )),
      ],
    );
  }

  pw.Widget _buildPillar4Suppression(EmergencyPlanModel plan) {
    final team = plan.suppressionPlan.regularShiftTeam;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('๔.', 'แผนการดับเพลิง / ระงับเหตุ (Suppression & Incident Command)'),
        pw.Text('ขั้นตอนเมื่อพบเหตุขั้นต้น: ${plan.suppressionPlan.initialResponseProtocol}', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 2),
        pw.Text('ขั้นตอนเมื่อเกิดเหตุขั้นรุนแรง: ${plan.suppressionPlan.majorEmergencyProtocol}', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 4),
        pw.Text('โครงสร้างหน่วยงานป้องกันระงับเหตุ (กะปฏิบัติงานปกติ):', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        if (team.isEmpty)
          pw.Text('- ไม่ได้ระบุรายชื่อทีมงาน -', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))
        else
          pw.TableHelper.fromTextArray(
            headers: ['ตำแหน่งในทีมฉุกเฉิน', 'ผู้รับผิดชอบ', 'เบอร์ติดต่อ', 'หน้าที่สำคัญ'],
            data: team.map((t) => [t.roleTitle, t.assignedPerson, t.contactNumber, t.keyDuties]).toList(),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(3),
          ),
      ],
    );
  }

  pw.Widget _buildPillar5Evacuation(EmergencyPlanModel plan) {
    final points = plan.evacuationPlan.assemblyPoints;
    final teams = plan.evacuationPlan.evacuationTeams;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('๕.', 'แผนอพยพหนีไฟ / อพยพภัยพิบัติ (Evacuation Plan)'),
        pw.Text('สัญญาณเตือนภัยอพยพ: ${plan.evacuationPlan.alarmSoundSignal}', style: const pw.TextStyle(fontSize: 8)),
        pw.Text('วิธีการตรวจนับยอดพนักงาน: ${plan.evacuationPlan.headcountMethod}', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 4),
        pw.Text('โครงสร้างทีมอพยพและผู้นำทางหนีไฟ (${teams.length} ทีม):', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        if (teams.isEmpty)
          pw.Text('- ยังไม่ได้กำหนดทีมอพยพ -', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))
        else
          pw.TableHelper.fromTextArray(
            headers: ['ชื่อทีม / พื้นที่', 'หัวหน้า / รองหัวหน้า', 'รายชื่อสมาชิกในทีม', 'จุดรวมพล', 'หน้าที่'],
            data: teams.map((t) => [
              '${t.teamName}\n(${t.areaFloor})',
              'หัวหน้า: ${t.leaderName}\nรอง: ${t.deputyLeaderName}',
              t.members.isEmpty ? '-' : t.members.join(', '),
              t.assignedAssemblyPoint,
              t.duties,
            ]).toList(),
            headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellPadding: const pw.EdgeInsets.all(3),
          ),
        pw.SizedBox(height: 4),
        pw.Text('จุดรวมพล (Assembly Points):', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        if (points.isEmpty)
          pw.Text('- ยังไม่ได้กำหนดจุดรวมพล -', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))
        else
          pw.TableHelper.fromTextArray(
            headers: ['จุดรวมพล', 'ที่ตั้ง/ลักษณะพื้นที่', 'แผนกที่กำหนดให้มารวมพล', 'ความจุ (คน)'],
            data: points.map((p) => [p.pointName, p.location, p.assignedDepartments, '${p.capacity}']).toList(),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(3),
          ),
      ],
    );
  }

  pw.Widget _buildPillar6Relief(EmergencyPlanModel plan) {
    final contacts = plan.reliefPlan.governmentContacts;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('๖.', 'แผนบรรเทาทุกข์และฟื้นฟู (Relief & Recovery Plan)'),
        pw.Text('การค้นหาและช่วยชีวิต: ${plan.reliefPlan.searchAndRescueProtocol}', style: const pw.TextStyle(fontSize: 8)),
        pw.Text('การสำรวจความเสียหาย: ${plan.reliefPlan.damageAssessmentProtocol}', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 4),
        pw.Text('รายชื่อและหมายเลขโทรศัพท์ติดต่อหน่วยงานฉุกเฉินภายนอก:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        if (contacts.isEmpty)
          pw.Text('- ไม่มีข้อมูลหน่วยงานภายนอก -', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))
        else
          pw.TableHelper.fromTextArray(
            headers: ['หน่วยงาน', 'เบอร์โทรศัพท์ฉุกเฉิน', 'ผู้ประสานงาน'],
            data: contacts.map((c) => [c.agencyName, c.phoneNumber, c.contactPerson]).toList(),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(3),
          ),
      ],
    );
  }

  pw.Widget _buildSignatures(EmergencyPlanModel plan) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Container(width: 140, height: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),
              pw.Text('ลงชื่อ .................................................', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('( ${plan.fireCommanderName} )', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('ผู้อำนวยการดับเพลิง / ผู้จัดการโรงงาน', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
            ],
          ),
          pw.Column(
            children: [
              pw.Container(width: 140, height: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),
              pw.Text('ลงชื่อ .................................................', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('เจ้าหน้าที่ความปลอดภัยในการทำงานระดับวิชาชีพ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('ผู้จัดทำและตรวจสอบแผน', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
            ],
          ),
        ],
      ),
    );
  }
}
