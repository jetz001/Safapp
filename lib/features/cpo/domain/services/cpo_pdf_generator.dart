import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../data/models/cpo_meeting_model.dart';
import '../../data/models/cpo_election_model.dart';

class _PdfSubTopic {
  final String subNo;
  final String title;
  final String discussion;
  final String resolution;
  final String presenter;

  _PdfSubTopic({
    required this.subNo,
    required this.title,
    required this.discussion,
    required this.resolution,
    required this.presenter,
  });
}

/// PDF Exporter สำหรับเอกสารทางการ คปอ.
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

  static int _getAttendeeRank(String roleLabel) {
    final r = roleLabel.trim();
    if (r.contains('ประธาน')) return 1;
    if (r.contains('นายจ้าง')) return 2;
    if (r.contains('ลูกจ้าง')) return 3;
    if (r.contains('กรรมการ')) return 4;
    if (r.contains('เลขา')) return 99; // สุดท้าย เลขานุการ!
    return 10;
  }

  static pw.Widget _buildCoverInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 130,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10.5, color: PdfColors.grey900),
          ),
        ),
      ],
    );
  }

  static List<_PdfSubTopic> _extractSubTopics(CpoAgendaModel ag) {
    final disc = ag.discussionContent ?? '';
    final res = ag.resolutionContent ?? '';

    // 1. Try to extract from structured JSON metadata if present
    final match = RegExp(r'<!--SUB_ITEMS_JSON:(.*?)-->', dotAll: true).firstMatch(disc);
    if (match != null) {
      try {
        final jsonString = match.group(1)!;
        final List<dynamic> list = jsonDecode(jsonString);
        if (list.isNotEmpty) {
          return list.map((item) {
            final m = item as Map<String, dynamic>;
            return _PdfSubTopic(
              subNo: m['sub_no']?.toString() ?? '',
              title: m['title']?.toString() ?? '',
              discussion: m['discussion']?.toString() ?? '',
              resolution: m['resolution']?.toString() ?? '',
              presenter: m['presenter']?.toString() ?? '',
            );
          }).toList();
        }
      } catch (_) {}
    }

    // 2. Try to parse numbered sub-topics in text (e.g. "5.1 หัวข้อ\nรายละเอียด...")
    final cleanDisc = _cleanPdfContent(disc);
    final pattern = RegExp(r'(?:^|\n\s*\n)(\d+\.\d+)\s+([^\n]+)\n([\s\S]*?)(?=(?:\n\s*\n\d+\.\d+)|$)', multiLine: true);
    final matches = pattern.allMatches(cleanDisc).toList();

    if (matches.isNotEmpty) {
      final list = <_PdfSubTopic>[];
      for (final m in matches) {
        final subNo = m.group(1) ?? '';
        final title = (m.group(2) ?? '').trim();
        final body = (m.group(3) ?? '').trim();

        // Extract presenter if present: (ผู้รายงาน: ...)
        final presMatch = RegExp(r'\(ผู้รายงาน:\s*([^\)]+)\)').firstMatch(body);
        final presenter = presMatch?.group(1)?.trim() ?? '';
        final cleanBody = body.replaceAll(RegExp(r'\(ผู้รายงาน:\s*[^\)]+\)'), '').trim();

        // Find resolution corresponding to this subNo, e.g. "5.1: อนุมัติ"
        final resMatch = RegExp(RegExp.escape(subNo) + r'\s*:\s*([^\n]+)').firstMatch(res);
        final subRes = resMatch != null ? resMatch.group(1)!.trim() : res.trim();

        list.add(_PdfSubTopic(
          subNo: subNo,
          title: title,
          discussion: cleanBody,
          resolution: subRes.isNotEmpty ? subRes : 'รับทราบ',
          presenter: presenter,
        ));
      }
      return list;
    }

    // 3. Fallback: single agenda item
    return [
      _PdfSubTopic(
        subNo: '',
        title: '',
        discussion: cleanDisc.isNotEmpty ? cleanDisc : 'ไม่มีข้อหารือเพิ่มเติม',
        resolution: res.isNotEmpty ? res : 'รับทราบ',
        presenter: ag.presenterName ?? '',
      ),
    ];
  }

  static List<pw.Widget> _buildAgendaSubTopics(CpoAgendaModel ag) {
    final subTopics = _extractSubTopics(ag);
    final widgets = <pw.Widget>[];

    for (int i = 0; i < subTopics.length; i++) {
      final st = subTopics[i];
      final isSub = subTopics.length > 1 || st.title.isNotEmpty;

      widgets.add(
        pw.Container(
          margin: pw.EdgeInsets.only(bottom: i < subTopics.length - 1 ? 8 : 2),
          padding: const pw.EdgeInsets.all(7),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Sub-topic title if multiple or named
              if (isSub) ...[
                pw.Text(
                  '${st.subNo.isNotEmpty ? st.subNo : "${ag.agendaOrder}.${i + 1}"} ${st.title.isNotEmpty ? st.title : "เรื่องย่อยที่ ${i + 1}"}',
                  style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
                ),
                pw.SizedBox(height: 3),
              ],
              pw.Text(
                'ข้อความหารือ / รายละเอียด:',
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 6, top: 2, bottom: 4),
                child: pw.Text(
                  st.discussion.isNotEmpty ? st.discussion : 'ไม่มีข้อหารือเพิ่มเติม',
                  style: const pw.TextStyle(fontSize: 8.5, height: 1.3),
                ),
              ),
              if (st.presenter.isNotEmpty) ...[
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 6, bottom: 4),
                  child: pw.Text(
                    '(ผู้รายงาน: ${st.presenter})',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ),
              ],
              // มติที่ประชุม อยู่ใต้ข้อใครข้อมัน!
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                  border: pw.Border.all(color: PdfColors.green200, width: 0.5),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'มติที่ประชุม: ',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        st.resolution.isNotEmpty ? st.resolution : 'รับทราบ',
                        style: pw.TextStyle(fontSize: 8.5, color: PdfColors.green900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  /// สร้างรายงานการประชุม คปอ. ฉบับสมบูรณ์ (๖ วาระ) พร้อมหน้าปก ๑ หน้า
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

    // ๑. จัดเรียงผู้เข้าร่วมประชุมตามลำดับชั้นกฎหมาย:
    // ประธานขึ้นก่อน (Rank 1) -> กรรมการฝ่ายนายจ้าง/ลูกจ้าง (Rank 2, 3) -> เลขานุการ สุดท้าย (Rank 99)
    final presentAttendees = meeting.attendees.where((a) => a.isPresent).toList();
    presentAttendees.sort((a, b) => _getAttendeeRank(a.roleLabel).compareTo(_getAttendeeRank(b.roleLabel)));

    final absentAttendees = meeting.attendees.where((a) => !a.isPresent).toList();
    absentAttendees.sort((a, b) => _getAttendeeRank(a.roleLabel).compareTo(_getAttendeeRank(b.roleLabel)));

    // ==========================================
    // ๑. หน้าปกรายงานการประชุม คปอ. (Cover Page - 1 Full Page)
    // ==========================================
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => pw.Container(
          width: double.infinity,
          height: double.infinity,
          padding: const pw.EdgeInsets.all(28),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blue900, width: 2),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header: Logo & Company Name
              pw.Column(
                children: [
                  if (logoImage != null)
                    pw.Container(
                      height: 70,
                      margin: const pw.EdgeInsets.only(bottom: 14),
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    )
                  else
                    pw.SizedBox(height: 25),
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    width: 200,
                    height: 2,
                    color: PdfColors.blue800,
                  ),
                ],
              ),

              // Title: รายงานการประชุม คปอ.
              pw.Column(
                children: [
                  pw.Text(
                    'รายงานการประชุม',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'คณะกรรมการความปลอดภัย อาชีวอนามัย\nและสภาพแวดล้อมในการทำงาน (คปอ.)',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 18),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                      border: pw.Border.all(color: PdfColors.blue800, width: 1),
                    ),
                    child: pw.Text(
                      'ครั้งที่ ${meeting.meetingNumber}/${meeting.meetingYear}',
                      style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                  ),
                ],
              ),

              // Info Summary Box
              pw.Container(
                width: 400,
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildCoverInfoRow('วันที่ประชุม:', meeting.meetingDate),
                    pw.SizedBox(height: 5),
                    _buildCoverInfoRow('เวลา:', '${meeting.startTime} - ${meeting.endTime} น.'),
                    pw.SizedBox(height: 5),
                    _buildCoverInfoRow('สถานที่ประชุม:', meeting.location.isNotEmpty ? meeting.location : '-'),
                    pw.SizedBox(height: 5),
                    _buildCoverInfoRow('ประธานในที่ประชุม:', meeting.chairmanName.isNotEmpty ? meeting.chairmanName : '-'),
                    pw.SizedBox(height: 5),
                    _buildCoverInfoRow('เลขานุการ คปอ.:', meeting.secretaryName.isNotEmpty ? meeting.secretaryName : '-'),
                  ],
                ),
              ),

              // Footer: Organization & Attribution
              pw.Column(
                children: [
                  pw.Text(
                    'จัดทำโดย คณะกรรมการความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'เอกสารบันทึกรายงานการประชุมตามข้อกำหนดมาตรฐานความปลอดภัยในการทำงาน',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // ==========================================
    // ๒. เนื้อหารายงานการประชุม (Minutes Content - MultiPage)
    // ==========================================
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              companyName,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'รายงานการประชุมคณะกรรมการความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน (คปอ.)',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'ครั้งที่ ${meeting.meetingNumber}/${meeting.meetingYear}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Divider(thickness: 0.8),
            pw.SizedBox(height: 4),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
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

          // ๒. ผู้เข้าร่วมประชุม (เรียง: ประธาน -> กรรมการ -> เลขานุการ สุดท้าย)
          // ๓ คอลัมน์คลีนๆ (ลำดับ | ชื่อ - นามสกุล | ตำแหน่งใน คปอ.) ไม่มีช่องแผนก
          pw.Text('ผู้มาประชุม (${presentAttendees.length} คน):', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(30),
              1: const pw.FlexColumnWidth(4),
              2: const pw.FlexColumnWidth(4),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('ลำดับ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('ชื่อ - นามสกุล', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('ตำแหน่งใน คปอ.', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                ],
              ),
              for (int i = 0; i < presentAttendees.length; i++)
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(presentAttendees[i].attendeeName, style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(presentAttendees[i].roleLabel, style: const pw.TextStyle(fontSize: 8))),
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
                0: const pw.FixedColumnWidth(30),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('ลำดับ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('ชื่อ - นามสกุล', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('ตำแหน่งใน คปอ.', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('เหตุผลการไม่มาประชุม', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                for (int i = 0; i < absentAttendees.length; i++)
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(absentAttendees[i].attendeeName, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(absentAttendees[i].roleLabel, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(absentAttendees[i].absenceReason ?? "ติดภารกิจงานประจำ", style: const pw.TextStyle(fontSize: 8))),
                    ],
                  ),
              ],
            ),
          ],

          pw.SizedBox(height: 14),
          pw.Text('เริ่มประชุมเวลา ${meeting.startTime} น.', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          // ๓. ระเบียบวาระการประชุม (มติที่ประชุม อยู่ใต้ข้อใครข้อมัน)
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
                  pw.SizedBox(height: 6),
                  ..._buildAgendaSubTopics(ag),
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
    sortedMembers.sort((a, b) => _getAttendeeRank(a.roleLabel).compareTo(_getAttendeeRank(b.roleLabel)));

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
                0: const pw.FixedColumnWidth(32),
                1: const pw.FlexColumnWidth(5),
                2: const pw.FlexColumnWidth(5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: pw.Text('ลำดับ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: pw.Text('ชื่อ - นามสกุล', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: pw.Text('ตำแหน่งใน คปอ.', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                for (int i = 0; i < sortedMembers.length; i++)
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: i.isEven ? PdfColors.white : PdfColors.grey50),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 8.5), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: pw.Text(sortedMembers[i].attendeeName, style: const pw.TextStyle(fontSize: 8.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: pw.Text(sortedMembers[i].roleLabel, style: const pw.TextStyle(fontSize: 8.5)),
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
