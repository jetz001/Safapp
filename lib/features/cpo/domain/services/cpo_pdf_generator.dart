import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../data/models/cpo_meeting_model.dart';
import '../../data/models/cpo_election_model.dart';

/// PDF Exporter สำหรับเอกสารทางการ คปอ. ตามแบบฟอร์มคู่มือ กสร. ๑/๒๕๖๑
class CpoPdfGenerator {
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

  static String _cleanPdfContent(String? raw, {String fallback = ''}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final cleaned = raw.replaceAll(RegExp(r'<!--SUB_ITEMS_JSON:[\s\S]*?-->'), '').trim();
    return cleaned.isEmpty ? fallback : cleaned;
  }

  /// สร้างรายงานการประชุม คปอ. ฉบับสมบูรณ์ (๖ วาระ) ตามคู่มือ กสร. หน้า ๓๒-๓๖
  static Future<Uint8List> generateMeetingMinutesPdf(
    CpoMeetingModel meeting, {
    String companyName = 'สถานประกอบกิจการ',
    String? logoPath,
  }) async {
    final theme = await _buildTheme();
    final doc = pw.Document(
      theme: theme,
      title: 'รายงานการประชุม คปอ. ครั้งที่ ${meeting.meetingNumber}/${meeting.meetingYear}',
      author: meeting.secretaryName,
    );

    pw.MemoryImage? logoImage;
    if (logoPath != null && logoPath.isNotEmpty) {
      try {
        final file = File(logoPath);
        if (file.existsSync()) {
          logoImage = pw.MemoryImage(file.readAsBytesSync());
        }
      } catch (_) {}
    }

    final presentAttendees = meeting.attendees.where((a) => a.isPresent).toList();
    final absentAttendees = meeting.attendees.where((a) => !a.isPresent).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoImage != null && context.pageNumber == 1)
              pw.Container(
                height: 40,
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
            pw.Text(
              companyName,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'รายงานการประชุมคณะกรรมการความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน (คปอ.)',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'ครั้งที่ ${meeting.meetingNumber}/${meeting.meetingYear} (ตามแบบฟอร์มคู่มือ กสร. ๑/๒๕๖๑)',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 6),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'ระบบบริหารงานความปลอดภัย SAFAPP - โมดูล คปอ.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              'หน้า ${context.pageNumber} จาก ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (context) => [
          // ๑. รายละเอียดการประชุม
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('วัน/เดือน/ปี: ${meeting.meetingDate}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('เวลา: ${meeting.startTime} - ${meeting.endTime} น.', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('สถานที่: ${meeting.location}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('ประธานในที่ประชุม: ${meeting.chairmanName}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // ๒. ผู้เข้าร่วมประชุม (ตามแบบ กสร.)
          pw.Text('ผู้มาประชุม (${presentAttendees.length} คน):', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(28),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ลำดับ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ชื่อ - นามสกุล', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ตำแหน่งใน คปอ.', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('แผนก/สังกัด', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                ],
              ),
              for (int i = 0; i < presentAttendees.length; i++)
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(presentAttendees[i].attendeeName, style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(presentAttendees[i].roleLabel, style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(presentAttendees[i].department ?? "-", style: const pw.TextStyle(fontSize: 8))),
                  ],
                ),
            ],
          ),

          if (absentAttendees.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('ผู้ไม่มาประชุม (${absentAttendees.length} คน):', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(28),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ลำดับ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ชื่อ - นามสกุล', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ตำแหน่งใน คปอ.', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('เหตุผลการไม่มาประชุม', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                for (int i = 0; i < absentAttendees.length; i++)
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(absentAttendees[i].attendeeName, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(absentAttendees[i].roleLabel, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(absentAttendees[i].absenceReason ?? "ติดภารกิจงานประจำ", style: const pw.TextStyle(fontSize: 8))),
                    ],
                  ),
              ],
            ),
          ],

          pw.SizedBox(height: 14),
          pw.Text('เริ่มประชุมเวลา ${meeting.startTime} น.', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          for (final ag in meeting.agendas) ...[
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ระเบียบวาระที่ ${ag.agendaOrder}: ${ag.title}',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.SizedBox(height: 4),
                  pw.Text('ข้อความหารือ/รายละเอียด:',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8, top: 2, bottom: 4),
                    child: pw.Text(
                      _cleanPdfContent(ag.discussionContent, fallback: 'ไม่มีข้อหารือเพิ่มเติม'),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: const pw.BoxDecoration(color: PdfColors.white),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('มติที่ประชุม: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                        pw.Expanded(
                          child: pw.Text(
                            _cleanPdfContent(ag.resolutionContent, fallback: 'รับทราบ'),
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.SizedBox(height: 30),
                  pw.Text('ลงชื่อ .....................................................', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('( ${meeting.secretaryName.isNotEmpty ? meeting.secretaryName : "....................................................."} )', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('เลขานุการ คปอ. / ผู้จดรายงานการประชุม', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Column(
                children: [
                  pw.SizedBox(height: 30),
                  pw.Text('ลงชื่อ .....................................................', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('( ${meeting.chairmanName.isNotEmpty ? meeting.chairmanName : "....................................................."} )', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('ประธาน คปอ. / ผู้รับรองรายงานการประชุม', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// สร้างหนังสือเชิญประชุม คปอ. และระเบียบวาระ
  static Future<Uint8List> generateMeetingNoticePdf(
    CpoMeetingModel meeting, {
    String companyName = 'สถานประกอบกิจการ',
    String? logoPath,
    List<CpoAttendeeModel>? committeeMembers,
  }) async {
    final theme = await _buildTheme();
    final doc = pw.Document(
      theme: theme,
      title: 'หนังสือเชิญประชุม คปอ. ครั้งที่ ${meeting.meetingNumber}/${meeting.meetingYear}',
    );

    pw.MemoryImage? logoImage;
    if (logoPath != null && logoPath.isNotEmpty) {
      try {
        final file = File(logoPath);
        if (file.existsSync()) {
          logoImage = pw.MemoryImage(file.readAsBytesSync());
        }
      } catch (_) {}
    }

    final rawMembers = (committeeMembers != null && committeeMembers.isNotEmpty)
        ? committeeMembers
        : meeting.attendees;

    final sortedMembers = List<CpoAttendeeModel>.from(rawMembers);
    int roleRank(String role) {
      if (role.contains('ประธาน')) return 1;
      if (role.contains('นายจ้าง')) return 2;
      if (role.contains('ลูกจ้าง')) return 3;
      if (role.contains('เลขา')) return 4;
      return 5;
    }
    sortedMembers.sort((a, b) => roleRank(a.roleLabel).compareTo(roleRank(b.roleLabel)));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (context) => [
          if (logoImage != null)
            pw.Center(
              child: pw.Container(
                height: 50,
                margin: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
            ),
          pw.Center(
            child: pw.Text(companyName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text('หนังสือเชิญประชุมคณะกรรมการความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน (คปอ.)',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Center(
            child: pw.Text('ครั้งที่ ${meeting.meetingNumber}/${meeting.meetingYear}', style: const pw.TextStyle(fontSize: 11)),
          ),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 10),
          pw.Text('เรียน  คณะกรรมการความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน (คปอ.) ทุกท่าน',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(
            '  ด้วยคณะกรรมการความปลอดภัยฯ จะจัดให้มีการประชุมประจำเดือน ครั้งที่ ${meeting.meetingNumber}/${meeting.meetingYear} '
            'ในวัน ${meeting.meetingDate} เวลา ${meeting.startTime} - ${meeting.endTime} น. '
            'ณ ${meeting.location} เพื่อติดตามผลการดำเนินงานและพิจารณาข้อเสนอแนะด้านความปลอดภัยในการทำงาน โดยมีรายนามกรรมการที่เชิญเข้าร่วมประชุมและระเบียบวาระดังต่อไปนี้',
            style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
          ),
          pw.SizedBox(height: 12),

          if (sortedMembers.isNotEmpty) ...[
            pw.Text(
              'รายนามคณะกรรมการ คปอ. ที่เชิญเข้าร่วมประชุม:',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(28),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      child: pw.Text('ลำดับ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      child: pw.Text('ชื่อ - นามสกุล', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      child: pw.Text('ตำแหน่งใน คปอ.', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      child: pw.Text('แผนก/ฝ่าย', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                for (int i = 0; i < sortedMembers.length; i++)
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: i.isEven ? PdfColors.white : PdfColors.grey50),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 8.5), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: pw.Text(sortedMembers[i].attendeeName, style: const pw.TextStyle(fontSize: 8.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: pw.Text(sortedMembers[i].roleLabel, style: const pw.TextStyle(fontSize: 8.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: pw.Text(sortedMembers[i].department ?? '-', style: const pw.TextStyle(fontSize: 8.5)),
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 12),
          ],

          pw.Text('ระเบียบวาระการประชุมมีดังนี้:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          for (final ag in meeting.agendas)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
              child: pw.Text('ระเบียบวาระที่ ${ag.agendaOrder}: ${ag.title}', style: const pw.TextStyle(fontSize: 9)),
            ),
          pw.SizedBox(height: 14),
          pw.Text('จึงเรียนมาเพื่อโปรดเข้าร่วมการประชุมตามวัน เวลา และสถานที่ดังกล่าวข้างต้นโดยพร้อมเพรียงกัน',
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 28),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('ลงชื่อ .....................................................', style: const pw.TextStyle(fontSize: 9)),
                pw.Text(
                  '( ${meeting.chairmanName.isNotEmpty ? meeting.chairmanName : "....................................................."} )',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text('ประธานคณะกรรมการ คปอ.', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// สร้างประกาศผลการเลือกตั้งผู้แทนลูกจ้าง คปอ. ตามแบบฟอร์มทางการ
  static Future<Uint8List> generateElectionAnnouncementPdf(
    CpoElectionModel election, {
    String companyName = 'สถานประกอบกิจการ',
  }) async {
    final theme = await _buildTheme();
    final doc = pw.Document(
      theme: theme,
      title: 'ประกาศผลการเลือกตั้งผู้แทนลูกจ้าง คปอ. ${election.termYear}',
    );

    final electedCandidates = election.candidates.where((c) => c.isElected).toList();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(companyName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text('ประกาศคณะกรรมการการเลือกตั้ง (กกต.)', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Center(
              child: pw.Text('เรื่อง ผลการเลือกตั้งผู้แทนลูกจ้างเป็นกรรมการความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Center(
              child: pw.Text('ประจำวาระปี พ.ศ. ${election.termYear}', style: const pw.TextStyle(fontSize: 11)),
            ),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 10),
            pw.Text(
              '  ตามที่คณะกรรมการการเลือกตั้งได้ดำเนินการจัดการเลือกตั้งผู้แทนลูกจ้างเป็นกรรมการ คปอ. '
              'เมื่อวันที่ ${election.votingDate} โดยมีผู้มีสิทธิเลือกตั้งจำนวน ${election.eligibleVotersCount} คน '
              'และกำหนดให้มีผู้แทนลูกจ้างจำนวน ${election.requiredRepsCount} คน นั้น',
              style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '  บัดนี้ การนับคะแนนเสียงเลือกตั้งได้เสร็จสิ้นเรียบร้อยแล้ว กกต. จึงขอประกาศรายชื่อผู้ได้รับเลือกตั้งเป็นผู้แทนลูกจ้าง คปอ. ดังนี้:',
              style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('ลำดับ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('หมายเลข', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('ชื่อ - นามสกุล', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('แผนก/ฝ่าย', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('คะแนนที่ได้', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                for (int i = 0; i < electedCandidates.length; i++)
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('เบอร์ ${electedCandidates[i].candidateNumber}', style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(electedCandidates[i].candidateName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(electedCandidates[i].department ?? '-', style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${electedCandidates[i].voteCount} คะแนน', style: const pw.TextStyle(fontSize: 9))),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Text('ประกาศ ณ วันที่ ${election.announcementDate ?? "-"}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 30),
            pw.Text('คณะกรรมการการเลือกตั้ง (กกต.):', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            for (final off in election.officers)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
                child: pw.Text('• ${off.officerName} (${off.officerRoleLabel})', style: const pw.TextStyle(fontSize: 9)),
              ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  /// บันทึก PDF ลงโฟลเดอร์เครื่อง
  static Future<String> saveMeetingMinutesPdf(
    CpoMeetingModel meeting, {
    String companyName = 'สถานประกอบกิจการ',
  }) async {
    final bytes = await generateMeetingMinutesPdf(meeting, companyName: companyName);
    final appDocDir = await getApplicationDocumentsDirectory();
    final cpoFolder = Directory('${appDocDir.path}/SafetySuperapp/cpo_minutes');
    if (!await cpoFolder.exists()) {
      await cpoFolder.create(recursive: true);
    }
    final filePath = '${cpoFolder.path}/cpo_meeting_${meeting.meetingNumber}_${meeting.meetingYear}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }
}
