import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/models/health_models.dart';
import '../../risk_assessment/domain/models/risk_assessment_models.dart';
import '../../employee/domain/models/employee_models.dart';
import '../../contractor/domain/models/contractor_models.dart';

class HealthOfficialPdfService {
  // ==========================================================================
  // 1. แบบ จผส. ๑ (แบบแจ้งผลการตรวจสุขภาพของลูกจ้างที่ผิดปกติหรือที่มีอาการหรือเจ็บป่วยเนื่องจากการทำงาน
  //    การให้การรักษาพยาบาล และการป้องกันแก้ไข ตามกฎกระทรวงตรวจสุขภาพฯ พ.ศ. ๒๕๖๓)
  //    ประกาศกรมสวัสดิการและคุ้มครองแรงงาน ราชกิจจานุเบกษา เล่ม ๑๓๘ ตอนพิเศษ ๒๓๑ ง วันที่ ๒๗ ก.ย. ๒๕๖๔
  // ==========================================================================
  static Future<void> printJorPhorSor1Report({
    required BuildContext context,
    List<EmployeeHealthRecord>? allRecords,
    required List<EmployeeHealthRecord> abnormalRecords,
    required List<MedicalSurveillanceFollowup> followups,
    CompanyProfile? company,
    String? checkupYear,
    ContractorCompany? contractorService,
    List<ContractorCompany>? contractorCompanies,
  }) async {
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

      final now = DateTime.now();
      const thaiMonths = [
        '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
        'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
      ];
      final reportDay = '${now.day}';
      final reportMonth = thaiMonths[now.month];
      final reportYear = checkupYear ?? '${now.year + 543}';

      final employerName = company?.employerName?.trim() ?? '';
      final companyName = (company?.companyName.trim().isNotEmpty == true) ? company!.companyName.trim() : '';
      final taxId = company?.taxId?.trim() ?? '';
      final businessType = company?.businessCategoryTitle?.trim() ?? '';

      final addressNo = company?.addressNumber?.trim() ?? '';
      final moo = company?.moo?.trim() ?? '';
      final soi = company?.soi?.trim() ?? '';
      final road = company?.road?.trim() ?? '';
      final subdistrict = company?.subdistrict?.trim() ?? '';
      final district = company?.district?.trim() ?? '';
      final province = company?.province?.trim() ?? '';
      final postalCode = company?.postalCode?.trim() ?? '';
      final phone = company?.phone?.trim() ?? '';
      final fax = company?.fax?.trim() ?? '';
      final mobile = company?.mobile?.trim() ?? '';

      // Determine dataset
      final effectiveRecords = (allRecords != null && allRecords.isNotEmpty) ? allRecords : abnormalRecords;

      // Checkup types
      final hasPreEmployment = effectiveRecords.any((r) => r.checkupType == 'PRE_EMPLOYMENT');
      final hasJobChange = effectiveRecords.any((r) => r.checkupType == 'JOB_CHANGE');
      final hasRiskSurveillance = effectiveRecords.any((r) => r.checkupType == 'RISK_BASED');
      final hasAnnual = effectiveRecords.any((r) => r.checkupType == 'ANNUAL') ||
          (!hasPreEmployment && !hasJobChange && !hasRiskSurveillance);

      // Checkup date range
      final checkupDates = effectiveRecords.map((r) => r.checkupDate.trim()).where((d) => d.isNotEmpty).toSet().toList();
      String checkupDateDisplay = '';
      if (checkupDates.length == 1) {
        checkupDateDisplay = formatThaiDate(checkupDates.first);
      } else if (checkupDates.length > 1) {
        checkupDates.sort();
        checkupDateDisplay = '${formatThaiDate(checkupDates.first, short: true)} ถึง ${formatThaiDate(checkupDates.last, short: true)}';
      }

      // Doctors
      final doctors = <({String name, String license})>[];
      for (final r in effectiveRecords) {
        if (r.doctorName != null && r.doctorName!.trim().isNotEmpty) {
          final dName = r.doctorName!.trim();
          final dLic = r.doctorLicenseNo?.trim() ?? '';
          if (!doctors.any((d) => d.name == dName)) {
            doctors.add((name: dName, license: dLic));
          }
        }
      }
      final doc1Name = doctors.isNotEmpty ? doctors[0].name : '';
      final doc1License = doctors.isNotEmpty ? doctors[0].license : '';
      final doc2Name = doctors.length > 1 ? doctors[1].name : '';
      final doc2License = doctors.length > 1 ? doctors[1].license : '';
      final doc3Name = doctors.length > 2 ? doctors[2].name : '';
      final doc3License = doctors.length > 2 ? doctors[2].license : '';

      // Hospitals & Contractor Resolution (Section ๕)
      final hospitalNames = effectiveRecords.map((r) => r.hospitalName.trim()).where((h) => h.isNotEmpty).toSet().toList();
      final hospitalName = hospitalNames.isNotEmpty ? hospitalNames.join(', ') : '';

      ContractorCompany? matchedContractor = contractorService;
      if (matchedContractor == null && contractorCompanies != null && contractorCompanies.isNotEmpty) {
        if (hospitalName.isNotEmpty) {
          final hLower = hospitalName.toLowerCase();
          for (final c in contractorCompanies) {
            final cLower = c.companyName.toLowerCase();
            if (hLower.contains(cLower) || cLower.contains(hLower)) {
              matchedContractor = c;
              break;
            }
          }
        }
        matchedContractor ??= contractorCompanies.where((c) {
          final st = c.serviceType.toLowerCase();
          final cn = c.companyName.toLowerCase();
          return st.contains('ตรวจสุขภาพ') || st.contains('โรงพยาบาล') || st.contains('แพทย์') ||
                 cn.contains('โรงพยาบาล') || cn.contains('คลินิก') || cn.contains('ศูนย์แพทย์');
        }).firstOrNull;
      }

      final s5HospitalName = matchedContractor?.companyName.trim().isNotEmpty == true
          ? matchedContractor!.companyName.trim()
          : hospitalName;
      final s5TaxId = matchedContractor?.taxId?.trim() ?? '';
      final s5Phone = matchedContractor?.phone?.trim() ?? '';
      final s5Mobile = matchedContractor?.safetyOfficerPhone?.trim().isNotEmpty == true
          ? matchedContractor!.safetyOfficerPhone!.trim()
          : (matchedContractor?.phone?.trim() ?? '');

      final parsedAddr = _parseAddressText(matchedContractor?.notes);
      final s5AddressNo = matchedContractor?.addressNumber?.trim().isNotEmpty == true
          ? matchedContractor!.addressNumber!.trim()
          : (parsedAddr['addressNo'] ?? '');
      final s5Moo = matchedContractor?.moo?.trim().isNotEmpty == true
          ? matchedContractor!.moo!.trim()
          : (parsedAddr['moo'] ?? '');
      final s5Soi = matchedContractor?.soi?.trim().isNotEmpty == true
          ? matchedContractor!.soi!.trim()
          : (parsedAddr['soi'] ?? '');
      final s5Road = matchedContractor?.road?.trim().isNotEmpty == true
          ? matchedContractor!.road!.trim()
          : (parsedAddr['road'] ?? '');
      final s5Subdistrict = matchedContractor?.subdistrict?.trim().isNotEmpty == true
          ? matchedContractor!.subdistrict!.trim()
          : (parsedAddr['subdistrict'] ?? '');
      final s5District = matchedContractor?.district?.trim().isNotEmpty == true
          ? matchedContractor!.district!.trim()
          : (parsedAddr['district'] ?? '');
      final s5Province = matchedContractor?.province?.trim().isNotEmpty == true
          ? matchedContractor!.province!.trim()
          : (parsedAddr['province'] ?? '');
      final s5PostalCode = matchedContractor?.postalCode?.trim().isNotEmpty == true
          ? matchedContractor!.postalCode!.trim()
          : (parsedAddr['postalCode'] ?? '');

      // Page 2: Department aggregation
      final Map<String, List<EmployeeHealthRecord>> allDeptMap = {};
      for (final r in effectiveRecords) {
        final d = r.department?.trim().isNotEmpty == true ? r.department!.trim() : 'ฝ่ายผลิตหลัก';
        allDeptMap.putIfAbsent(d, () => []).add(r);
      }

      final List<Map<String, dynamic>> deptSummaryList = [];
      allDeptMap.forEach((dept, deptRecords) {
        final testedCount = deptRecords.length;
        final normalCount = deptRecords.where((r) => r.overallResult == 'NORMAL').length;
        final abnormalCount = deptRecords.where((r) => r.overallResult != 'NORMAL').length;

        // Extract tested risk factors
        final riskSet = deptRecords.expand((r) => r.riskFactorsTested).where((rf) => rf.trim().isNotEmpty).toSet().toList();
        if (riskSet.isEmpty) {
          for (final r in deptRecords) {
            riskSet.addAll(r.riskFactorResults.keys.where((k) => k.trim().isNotEmpty));
          }
        }
        if (riskSet.isEmpty) {
          riskSet.addAll(['สารเคมีอันตราย', 'เสียงดัง', 'ฝุ่นละออง']);
        }

        // Followups / Actions
        final deptFollowups = followups.where((f) => deptRecords.any((r) => r.id == f.healthRecordId)).toList();
        final treatmentText = deptFollowups.isNotEmpty && deptFollowups.any((f) => f.actionDetails.isNotEmpty)
            ? deptFollowups.map((f) => f.actionDetails).where((a) => a.isNotEmpty).toSet().join('; ')
            : (abnormalCount > 0 ? 'ส่งตรวจซ้ำทางห้องปฏิบัติการ และส่งพบแพทย์อาชีวเวชศาสตร์เพื่อรับการรักษา' : '-');

        final envText = abnormalCount > 0
            ? 'ตรวจวัดสภาพแวดล้อมในการทำงาน (เสียง/สารเคมี) และบำรุงรักษาเครื่องจักร'
            : '-';

        final protText = abnormalCount > 0
            ? 'จัดและควบคุมดูแลให้สวมใส่อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล (PPE)'
            : '-';

        deptSummaryList.add({
          'dept': dept,
          'risks': riskSet.take(3).toList(),
          'testedCount': testedCount,
          'normalCount': normalCount,
          'abnormalCount': abnormalCount,
          'treatment': treatmentText,
          'environment': envText,
          'protection': protText,
        });
      });

      final totalTested = deptSummaryList.fold<int>(0, (sum, d) => sum + (d['testedCount'] as int));
      final totalNormal = deptSummaryList.fold<int>(0, (sum, d) => sum + (d['normalCount'] as int));
      final totalAbnormal = deptSummaryList.fold<int>(0, (sum, d) => sum + (d['abnormalCount'] as int));

      // ----------------------------------------------------------------------
      // PAGE 1: ข้อ ๑ - ๕ (แนวนอน ราชกิจจานุเบกษา)
      // ----------------------------------------------------------------------
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          theme: theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 38, vertical: 28),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Right: แบบ จผส. ๑
                pw.Align(
                  alignment: pw.Alignment.topRight,
                  child: pw.Text(
                    'แบบ จผส. ๑',
                    style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 10),

                // Title
                pw.Center(
                  child: pw.Text(
                    'แบบแจ้งผลการตรวจสุขภาพของลูกจ้างที่ผิดปกติหรือที่มีอาการหรือเจ็บป่วยเนื่องจากการทำงาน การให้การรักษาพยาบาล และการป้องกันแก้ไข',
                    style: pw.TextStyle(fontSize: 12.5, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 12),

                // Date (bulletproof baseline row without Stack wrapping)
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('วันที่ ', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(
                        reportDay.isNotEmpty ? reportDay : '-',
                        style: pw.TextStyle(fontSize: 10, fontWeight: reportDay.isNotEmpty ? pw.FontWeight.bold : pw.FontWeight.normal),
                      ),
                      pw.Text(' เดือน ', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(
                        reportMonth.isNotEmpty ? reportMonth : '-',
                        style: pw.TextStyle(fontSize: 10, fontWeight: reportMonth.isNotEmpty ? pw.FontWeight.bold : pw.FontWeight.normal),
                      ),
                      pw.Text(' พ.ศ. ', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(
                        reportYear.isNotEmpty ? reportYear : '-',
                        style: pw.TextStyle(fontSize: 10, fontWeight: reportYear.isNotEmpty ? pw.FontWeight.bold : pw.FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // ข้อ ๑
                pw.Row(
                  children: [
                    _buildJorPhorSor1DottedField(
                      label: '๑. ข้าพเจ้า (นาย/นาง/นางสาว) ',
                      value: employerName,
                      suffix: ' นายจ้าง/ผู้มีอำนาจกระทำการแทน',
                      flex: 1,
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // ข้อ ๒
                pw.Row(
                  children: [
                    _buildJorPhorSor1DottedField(label: '๒. ชื่อสถานประกอบกิจการ ', value: companyName, flex: 4),
                    pw.SizedBox(width: 8),
                    _buildJorPhorSor1DottedField(label: 'เลขทะเบียนนิติบุคคล ', value: taxId, flex: 3),
                    pw.SizedBox(width: 8),
                    _buildJorPhorSor1DottedField(label: 'ประกอบกิจการ ', value: businessType, flex: 6),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    _buildJorPhorSor1DottedField(label: '    ตั้งอยู่เลขที่ ', value: addressNo, flex: 2),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'หมู่ที่ ', value: moo, flex: 1),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'ตรอก/ซอย ', value: soi, flex: 2),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'ถนน ', value: road, flex: 2),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'ตำบล/แขวง ', value: subdistrict, flex: 3),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'อำเภอ/เขต ', value: district, flex: 3),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    _buildJorPhorSor1DottedField(label: '    จังหวัด ', value: province, flex: 3),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'รหัสไปรษณีย์ ', value: postalCode, flex: 2),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'โทรศัพท์ ', value: phone, flex: 3),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'โทรสาร ', value: fax, flex: 2),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'โทรศัพท์มือถือ ', value: mobile, flex: 3),
                  ],
                ),
                pw.SizedBox(height: 10),

                // ข้อ ๓
                pw.Text('๓. การดำเนินการตรวจสุขภาพของลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง', style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    pw.SizedBox(width: 14),
                    _buildJorPhorSor1RadioCircle(hasPreEmployment, 'ตรวจสุขภาพครั้งแรก (ให้เสร็จสิ้นภายใน ๓๐ วัน นับแต่วันที่รับลูกจ้างเข้าทำงาน)'),
                    pw.SizedBox(width: 14),
                    _buildJorPhorSor1RadioCircle(hasAnnual, 'ตรวจประจำปี'),
                    pw.SizedBox(width: 14),
                    _buildJorPhorSor1RadioCircle(hasJobChange, 'ตรวจเมื่อเปลี่ยนงาน'),
                    pw.SizedBox(width: 14),
                    _buildJorPhorSor1RadioCircle(hasRiskSurveillance, 'ตรวจเฝ้าระวังตามความจำเป็น'),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    _buildJorPhorSor1DottedField(label: '    วันที่ตรวจสุขภาพ ', value: checkupDateDisplay, flex: 1),
                  ],
                ),
                pw.SizedBox(height: 10),

                // ข้อ ๔
                pw.Text('๔. แพทย์ผู้ทำการตรวจสุขภาพ', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  '   (แพทย์ซึ่งได้รับวุฒิบัตรหรือหนังสืออนุมัติสาขาวิชาเวชศาสตร์ป้องกัน แขนงอาชีวเวชศาสตร์/แพทย์ซึ่งผ่านการอบรมด้านอาชีวเวชศาสตร์ตามหลักสูตรที่กระทรวงสาธารณสุขรับรอง)',
                  style: const pw.TextStyle(fontSize: 8.8, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    _buildJorPhorSor1DottedField(label: '    ๔.๑ ชื่อ-นามสกุล ', value: doc1Name, flex: 1),
                    pw.SizedBox(width: 14),
                    _buildJorPhorSor1DottedField(label: 'เลขที่ใบประกอบวิชาชีพ ', value: doc1License, flex: 1),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    _buildJorPhorSor1DottedField(label: '    ๔.๒ ชื่อ-นามสกุล ', value: doc2Name, flex: 1),
                    pw.SizedBox(width: 14),
                    _buildJorPhorSor1DottedField(label: 'เลขที่ใบประกอบวิชาชีพ ', value: doc2License, flex: 1),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    _buildJorPhorSor1DottedField(label: '    ๔.๓ ชื่อ-นามสกุล ', value: doc3Name, flex: 1),
                    pw.SizedBox(width: 14),
                    _buildJorPhorSor1DottedField(label: 'เลขที่ใบประกอบวิชาชีพ ', value: doc3License, flex: 1),
                  ],
                ),
                pw.SizedBox(height: 10),

                // ข้อ ๕
                pw.Row(
                  children: [
                    _buildJorPhorSor1DottedField(label: '๕. ชื่อหน่วยบริการตรวจสุขภาพ ', value: s5HospitalName, flex: 3),
                    pw.SizedBox(width: 14),
                    _buildJorPhorSor1DottedField(label: 'เลขทะเบียนหน่วยบริการ ', value: s5TaxId, flex: 2),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    _buildJorPhorSor1DottedField(label: '    ตั้งอยู่เลขที่ ', value: s5AddressNo, flex: 2),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'หมู่ที่ ', value: s5Moo, flex: 1),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'ตรอก/ซอย ', value: s5Soi, flex: 2),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'ถนน ', value: s5Road, flex: 2),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'ตำบล/แขวง ', value: s5Subdistrict, flex: 3),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'อำเภอ/เขต ', value: s5District, flex: 3),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    _buildJorPhorSor1DottedField(label: '    จังหวัด ', value: s5Province, flex: 3),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'รหัสไปรษณีย์ ', value: s5PostalCode, flex: 2),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'โทรศัพท์ ', value: s5Phone, flex: 3),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'โทรสาร ', value: '', flex: 2),
                    pw.SizedBox(width: 6),
                    _buildJorPhorSor1DottedField(label: 'โทรศัพท์มือถือ ', value: s5Mobile, flex: 3),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // ----------------------------------------------------------------------
      // PAGE 2: ข้อ ๖ (ตารางผลการตรวจสุขภาพฯ ๘ คอลัมน์ ๒ ชั้น แนวนอน)
      // ----------------------------------------------------------------------
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          theme: theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 38, vertical: 28),
          build: (pw.Context ctx) {
            // Build table rows
            final tableRows = <pw.TableRow>[];

            for (int i = 0; i < deptSummaryList.length; i++) {
              final item = deptSummaryList[i];
              final risks = item['risks'] as List<dynamic>;

              tableRows.add(
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        '${_toThaiDigit(i + 1)}. ${item['dept']}',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          for (int rIdx = 0; rIdx < risks.length; rIdx++)
                            pw.Text(
                              '${_toThaiDigit(rIdx + 1)}. ${risks[rIdx]}',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Center(
                        child: pw.Text('${item['testedCount']}', style: const pw.TextStyle(fontSize: 8.5)),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Center(
                        child: pw.Text('${item['normalCount']}', style: const pw.TextStyle(fontSize: 8.5)),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Center(
                        child: pw.Text(
                          '${item['abnormalCount']}',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: (item['abnormalCount'] as int) > 0 ? pw.FontWeight.bold : pw.FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('${item['treatment']}', style: const pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('${item['environment']}', style: const pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('${item['protection']}', style: const pw.TextStyle(fontSize: 8)),
                    ),
                  ],
                ),
              );
            }

            // Fill placeholder rows if fewer than 3 departments (matching gazette form)
            for (int emptyIdx = deptSummaryList.length; emptyIdx < 3; emptyIdx++) {
              tableRows.add(
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('${_toThaiDigit(emptyIdx + 1)}. -', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey500)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('๑. -', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                          pw.Text('๒. -', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                          pw.Text('๓. -', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                        ],
                      ),
                    ),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Center(child: pw.Text('', style: const pw.TextStyle(fontSize: 8.5)))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Center(child: pw.Text('', style: const pw.TextStyle(fontSize: 8.5)))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Center(child: pw.Text('', style: const pw.TextStyle(fontSize: 8.5)))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('', style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('', style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('', style: const pw.TextStyle(fontSize: 8))),
                  ],
                ),
              );
            }

            // Summary row: รวมจำนวนลูกจ้าง (คน)
            tableRows.add(
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'รวมจำนวนลูกจ้าง (คน)',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('', style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Center(
                      child: pw.Text('$totalTested', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Center(
                      child: pw.Text('$totalNormal', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Center(
                      child: pw.Text('$totalAbnormal', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    ),
                  ),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('', style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('', style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('', style: const pw.TextStyle(fontSize: 8))),
                ],
              ),
            );

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title
                pw.Text(
                  '๖. ผลการตรวจสุขภาพของลูกจ้างที่ผิดปกติหรือที่มีอาการหรือเจ็บป่วยเนื่องจากการทำงาน การให้การรักษาพยาบาล และการป้องกันแก้ไข',
                  style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),

                // 2-Tier Header Box (Aligned flex 14, 16, 13, 7, 7, 21, 21, 21 = 120 total)
                pw.Container(
                  height: 44,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.black, width: 0.5),
                      left: pw.BorderSide(color: PdfColors.black, width: 0.5),
                      right: pw.BorderSide(color: PdfColors.black, width: 0.5),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      // แผนก
                      pw.Expanded(
                        flex: 14,
                        child: pw.Center(
                          child: pw.Text('แผนก', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                      ),
                      // งานเกี่ยวกับปัจจัยเสี่ยง๑.
                      pw.Expanded(
                        flex: 16,
                        child: pw.Container(
                          decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: PdfColors.black, width: 0.5))),
                          child: pw.Center(
                            child: pw.Text('งานเกี่ยวกับ\nปัจจัยเสี่ยง๑.', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                          ),
                        ),
                      ),
                      // จำนวนลูกจ้างแต่ละแผนกที่ได้รับการตรวจสุขภาพ (คน)
                      pw.Expanded(
                        flex: 13,
                        child: pw.Container(
                          decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: PdfColors.black, width: 0.5))),
                          child: pw.Center(
                            child: pw.Text('จำนวนลูกจ้างแต่ละแผนก\nที่ได้รับการตรวจสุขภาพ\n(คน)', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7.8, fontWeight: pw.FontWeight.bold)),
                          ),
                        ),
                      ),
                      // จำนวนลูกจ้างที่ตรวจ (ปกติ | ผิดปกติ)
                      pw.Expanded(
                        flex: 14,
                        child: pw.Container(
                          decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: PdfColors.black, width: 0.5))),
                          child: pw.Column(
                            children: [
                              pw.Container(
                                height: 18,
                                decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.5))),
                                child: pw.Center(child: pw.Text('จำนวนลูกจ้างที่ตรวจ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                              ),
                              pw.Expanded(
                                child: pw.Row(
                                  children: [
                                    pw.Expanded(
                                      flex: 7,
                                      child: pw.Center(child: pw.Text('ปกติ\n(คน)', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                    ),
                                    pw.Expanded(
                                      flex: 7,
                                      child: pw.Container(
                                        decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: PdfColors.black, width: 0.5))),
                                        child: pw.Center(child: pw.Text('ผิดปกติ\n(คน)', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // การดำเนินการ (การให้การรักษา๒. | การแก้ไขสภาพแวดล้อม๓. | การป้องกันที่ตัวลูกจ้าง๔.)
                      pw.Expanded(
                        flex: 63,
                        child: pw.Container(
                          decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: PdfColors.black, width: 0.5))),
                          child: pw.Column(
                            children: [
                              pw.Container(
                                height: 18,
                                decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.5))),
                                child: pw.Center(child: pw.Text('การดำเนินการ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                              ),
                              pw.Expanded(
                                child: pw.Row(
                                  children: [
                                    pw.Expanded(
                                      flex: 21,
                                      child: pw.Center(child: pw.Text('การให้การรักษา๒.\n(โปรดระบุรายละเอียด)', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                                    ),
                                    pw.Expanded(
                                      flex: 21,
                                      child: pw.Container(
                                        decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: PdfColors.black, width: 0.5))),
                                        child: pw.Center(child: pw.Text('การแก้ไขสภาพแวดล้อม๓.\n(โปรดระบุรายละเอียด)', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                                      ),
                                    ),
                                    pw.Expanded(
                                      flex: 21,
                                      child: pw.Container(
                                        decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: PdfColors.black, width: 0.5))),
                                        child: pw.Center(child: pw.Text('การป้องกันที่ตัวลูกจ้าง๔.\n(โปรดระบุรายละเอียด)', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Data Body
                pw.Table(
                  border: pw.TableBorder(
                    top: const pw.BorderSide(color: PdfColors.black, width: 0.5),
                    bottom: const pw.BorderSide(color: PdfColors.black, width: 0.5),
                    left: const pw.BorderSide(color: PdfColors.black, width: 0.5),
                    right: const pw.BorderSide(color: PdfColors.black, width: 0.5),
                    horizontalInside: const pw.BorderSide(color: PdfColors.black, width: 0.5),
                    verticalInside: const pw.BorderSide(color: PdfColors.black, width: 0.5),
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(14),
                    1: pw.FlexColumnWidth(16),
                    2: pw.FlexColumnWidth(13),
                    3: pw.FlexColumnWidth(7),
                    4: pw.FlexColumnWidth(7),
                    5: pw.FlexColumnWidth(21),
                    6: pw.FlexColumnWidth(21),
                    7: pw.FlexColumnWidth(21),
                  },
                  children: tableRows,
                ),
                pw.SizedBox(height: 14),

                // Signature Box (Right-aligned)
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: 250,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('ลงชื่อ..............................................................', style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          employerName.isNotEmpty ? '($employerName)' : '(............................................................)',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('นายจ้าง/ผู้มีอำนาจกระทำการแทน', style: const pw.TextStyle(fontSize: 9.5)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 12),

                // Footnotes (Left-aligned)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('หมายเหตุ ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '๑. งานเกี่ยวกับปัจจัยเสี่ยง หมายถึง งานที่ลูกจ้างทำ ตามกฎกระทรวงกำหนดมาตรฐานการตรวจสุขภาพลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง พ.ศ. ๒๕๖๓',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            '๒. การให้การรักษา (โปรดระบุรายละเอียด) เช่น การส่งตัวลูกจ้างเข้ารับการตรวจสุขภาพซ้ำ การส่งลูกจ้างเข้ารับการรักษาพยาบาล เป็นต้น',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            '๓. การแก้ไขสภาพแวดล้อม (โปรดระบุรายละเอียด) เช่น การบำรุงรักษาเครื่องจักร การปรับปรุงแก้ไขเครื่องจักร เป็นต้น',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            '๔. การป้องกันที่ตัวลูกจ้าง (โปรดระบุรายละเอียด) เช่น จัดและควบคุมดูแลให้ลูกจ้างสวมใส่ปลั๊กลดเสียงหรือที่ครอบหูลดเสียง การเปลี่ยนงาน เป็นต้น',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) => doc.save(),
        name: 'แบบ_จผส_๑_$reportYear',
        format: PdfPageFormat.a4.landscape,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการพิมพ์แบบ จผส. ๑: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Helper for radio circle
  static pw.Widget _buildJorPhorSor1RadioCircle(bool isChecked, String label) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 9.5,
          height: 9.5,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: PdfColors.black, width: 0.8),
          ),
          child: isChecked
              ? pw.Center(
                  child: pw.Container(
                    width: 5,
                    height: 5,
                    decoration: const pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColors.black,
                    ),
                  ),
                )
              : null,
        ),
        pw.SizedBox(width: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9.5)),
      ],
    );
  }

  // Helper to parse address text from notes if dedicated fields are not available
  static Map<String, String> _parseAddressText(String? raw) {
    if (raw == null || raw.trim().isEmpty) return {};
    final text = raw.trim();

    String addressNo = '';
    String moo = '';
    String soi = '';
    String road = '';
    String subdistrict = '';
    String district = '';
    String province = '';
    String postalCode = '';

    final postMatch = RegExp(r'\b(1[0-9]{4}|2[0-9]{4}|3[0-9]{4}|4[0-9]{4}|5[0-9]{4}|6[0-9]{4}|7[0-9]{4}|8[0-9]{4}|9[0-9]{4})\b').firstMatch(text);
    if (postMatch != null) postalCode = postMatch.group(0)!;

    final noMatch = RegExp(r'(?:เลขที่|บ้านเลขที่|\bno\.?)\s*([0-9]+(/[0-9]+)?)', caseSensitive: false).firstMatch(text) ??
        RegExp(r'^([0-9]+(/[0-9]+)?)').firstMatch(text);
    if (noMatch != null) addressNo = noMatch.group(1)!;

    final mooMatch = RegExp(r'(?:หมู่ที่|หมู่|ม\.)\s*([0-9]+)').firstMatch(text);
    if (mooMatch != null) moo = mooMatch.group(1)!;

    final soiMatch = RegExp(r'(?:ตรอก|ซอย|ซ\.)\s*([^\s,]+(?: [^\s,]+)*?)(?=\s+(?:ถนน|ถ\.|ตำบล|ต\.|แขวง|อำเภอ|อ\.|เขต|จังหวัด|จ\.|\d{5}|$))').firstMatch(text);
    if (soiMatch != null) soi = soiMatch.group(1)!;

    final roadMatch = RegExp(r'(?:ถนน|ถ\.)\s*([^\s,]+(?: [^\s,]+)*?)(?=\s+(?:ตำบล|ต\.|แขวง|อำเภอ|อ\.|เขต|จังหวัด|จ\.|\d{5}|$))').firstMatch(text);
    if (roadMatch != null) road = roadMatch.group(1)!;

    final subMatch = RegExp(r'(?:ตำบล|ต\.|แขวง)\s*([^\s,]+)').firstMatch(text);
    if (subMatch != null) subdistrict = subMatch.group(1)!;

    final distMatch = RegExp(r'(?:อำเภอ|อ\.|เขต)\s*([^\s,]+)').firstMatch(text);
    if (distMatch != null) district = distMatch.group(1)!;

    final provMatch = RegExp(r'(?:จังหวัด|จ\.)\s*([^\s,]+)').firstMatch(text);
    if (provMatch != null) province = provMatch.group(1)!;

    return {
      'addressNo': addressNo,
      'moo': moo,
      'soi': soi,
      'road': road,
      'subdistrict': subdistrict,
      'district': district,
      'province': province,
      'postalCode': postalCode,
    };
  }

  // Helper for fill-in field (clean official format without trailing dots, full width to text)
  static pw.Widget _buildJorPhorSor1DottedField({
    required String label,
    required String value,
    String? suffix,
    int flex = 1,
    double fontSize = 10,
  }) {
    final hasVal = value.trim().isNotEmpty && value != '-';
    final trimmedVal = value.trim();
    // Dynamic font scaling: ensure longer text fits comfortably without being clipped
    final effectiveFontSize = (trimmedVal.length > 40)
        ? 7.5
        : (trimmedVal.length > 25 ? 8.2 : fontSize);

    return pw.Expanded(
      flex: flex,
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: effectiveFontSize)),
          pw.Expanded(
            child: pw.Text(
              hasVal ? trimmedVal : '-',
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                fontSize: effectiveFontSize,
                fontWeight: hasVal ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: hasVal ? PdfColors.black : PdfColors.grey500,
              ),
            ),
          ),
          if (suffix != null) ...[
            pw.SizedBox(width: 2),
            pw.Text(suffix, style: pw.TextStyle(fontSize: effectiveFontSize)),
          ],
        ],
      ),
    );
  }

  // Helper for Thai numerals
  static String _toThaiDigit(int number) {
    const arabic = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const thai = ['๐', '๑', '๒', '๓', '๔', '๕', '๖', '๗', '๘', '๙'];
    String s = number.toString();
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(arabic[i], thai[i]);
    }
    return s;
  }

  // ==========================================================================
  // 2. สมุดสุขภาพประจำตัวของลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง (Electronic Health Book)
  // ==========================================================================
  static Future<void> printElectronicHealthBook({
    required BuildContext context,
    required Employee employee,
    required List<EmployeeHealthRecord> healthRecords,
    CompanyProfile? company,
  }) async {
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

      final orgName = (company?.companyName.isNotEmpty == true) ? company!.companyName : 'สถานประกอบกิจการ';
      final fullAddress = _formatCompanyAddress(company);

      // Load worker photo if available
      pw.MemoryImage? employeePhoto;
      if (employee.photoPath != null && employee.photoPath!.isNotEmpty) {
        try {
          final file = File(employee.photoPath!);
          if (file.existsSync()) {
            final bytes = file.readAsBytesSync();
            employeePhoto = pw.MemoryImage(bytes);
          }
        } catch (_) {}
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 20),
          header: (pw.Context ctx) {
            return pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 6),
              margin: const pw.EdgeInsets.only(bottom: 6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue900, width: 1.5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue900,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Text(
                          'SAFAPP EHS',
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'กระทรวงแรงงาน • กรมสวัสดิการและคุ้มครองแรงงาน (กฎกระทรวงตรวจสุขภาพฯ พ.ศ. ๒๕๖๓)',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      border: pw.Border.all(color: PdfColors.blue300, width: 0.8),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Text('รหัสพนักงาน: ', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                        pw.Text(
                          employee.employeeCode,
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          footer: (pw.Context ctx) {
            return pw.Container(
              padding: const pw.EdgeInsets.only(top: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'สมุดสุขภาพประจำตัวของลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง (Electronic Health Book)',
                    style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'หน้า ${ctx.pageNumber} จาก ${ctx.pagesCount}',
                    style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                  ),
                ],
              ),
            );
          },
          build: (pw.Context ctx) {
            return [
              // ==============================================================
              // COVER TITLE BANNER
              // ==============================================================
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'สมุดสุขภาพประจำตัวของลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง',
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 1.5),
                    pw.Text(
                      '(ตามกฎกระทรวงกำหนดมาตรฐานการตรวจสุขภาพลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง พ.ศ. ๒๕๖๓)',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'ออกตามความในพระราชบัญญัติความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔',
                      style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey600),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // ==============================================================
              // SECTION 1: PERSONAL & WORKPLACE PROFILE
              // ==============================================================
              _buildModernSectionHeader('ส่วนที่ ๑: ข้อมูลประวัติส่วนตัวและประวัติการทำงาน', 'Personal & Employment Profile'),
              _buildPersonalInfoCard(
                employee: employee,
                orgName: orgName,
                fullAddress: fullAddress,
                company: company,
                photo: employeePhoto,
              ),
              pw.SizedBox(height: 8),

              // ==============================================================
              // SECTION 2: HEALTH & SURVEILLANCE CHECKUPS
              // ==============================================================
              _buildModernSectionHeader('ส่วนที่ ๒: ประวัติการตรวจสุขภาพและการตรวจตามปัจจัยเสี่ยง', 'Occupational Health & Surveillance Records'),
              if (healthRecords.isEmpty)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Center(
                    child: pw.Text('ยังไม่มีประวัติการบันทึกตรวจสุขภาพในระบบ', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                  ),
                )
              else
                ...healthRecords.map((r) => _buildHealthRecordCard(r)),

              pw.SizedBox(height: 8),

              // ==============================================================
              // SECTION 3: SIGNATURES & CERTIFICATION
              // ==============================================================
              _buildModernSectionHeader('ส่วนที่ ๓: การรับรองสมุดสุขภาพ', 'Certification & Endorsement'),
              pw.SizedBox(height: 4),
              _buildSignatureBoxes(employee),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) => doc.save(),
        name: 'HealthBook_${employee.employeeCode}',
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการพิมพ์สมุดสุขภาพ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==========================================================================
  // 3. ใบสรุปผลการตรวจสุขภาพรายบุคคล (Individual Health Summary Certificate)
  // ==========================================================================
  static Future<void> printHealthSummaryCertificate({
    required BuildContext context,
    required EmployeeHealthRecord record,
    CompanyProfile? company,
  }) async {
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

      final orgName = (company?.companyName.isNotEmpty == true) ? company!.companyName : 'สถานประกอบกิจการ';
      final formattedCheckupDate = formatThaiDate(record.checkupDate);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 20),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Banner Header
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue900, width: 1.5)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.blue900,
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                            child: pw.Text(
                              'ฝ่ายอาชีวอนามัยและความปลอดภัย',
                              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            orgName,
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          border: pw.Border.all(color: PdfColors.blue300, width: 0.8),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Text('วันที่ตรวจ: ', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                            pw.Text(
                              formattedCheckupDate,
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Title
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'ใบสรุปผลการตรวจสุขภาพและประเมินความพร้อมในการทำงาน',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 1.5),
                      pw.Text(
                        'OCCUPATIONAL HEALTH & FITNESS FOR DUTY CERTIFICATE',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        '(ออกตามข้อกำหนดมาตรฐานการตรวจสุขภาพลูกจ้างตามกฎกระทรวง พ.ศ. ๒๕๖๓)',
                        style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey600),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // 1. Employee Profile Card
                _buildModernSectionHeader('ข้อมูลผู้รับการตรวจสุขภาพ', 'Employee & Workplace Profile'),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildModernInfoRow('ชื่อ - นามสกุล', '${record.employeeName ?? "-"} (รหัส: ${record.employeeCode ?? "-"})', isBold: true),
                            pw.SizedBox(height: 2),
                            _buildModernInfoRow('สังกัดแผนก / ตำแหน่ง', '${record.department ?? "-"} / ${record.position ?? "-"}'),
                            pw.SizedBox(height: 2),
                            _buildModernInfoRow('เลขประจำตัวประชาชน', formatNationalId(record.nationalId)),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildModernInfoRow('สถานประกอบการ', orgName, isBold: true),
                            pw.SizedBox(height: 2),
                            _buildModernInfoRow('ประเภทการตรวจ', record.checkupTypeLabel),
                            pw.SizedBox(height: 2),
                            _buildModernInfoRow('หน่วยบริการตรวจสุขภาพ', record.hospitalName),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 7),

                // 2. Physical & Vitals
                _buildModernSectionHeader('ผลการตรวจร่างกายและสัญญาณชีพ', 'Physical Examination & Vital Signs'),
                pw.Row(
                  children: [
                    _buildMetricPill('น้ำหนัก', '${record.weight ?? "-"} กก.', null),
                    pw.SizedBox(width: 4),
                    _buildMetricPill('ส่วนสูง', '${record.height ?? "-"} ซม.', null),
                    pw.SizedBox(width: 4),
                    _buildMetricPill('BMI', record.bmi?.toStringAsFixed(1) ?? '-', interpretBmi(record.bmi)),
                    pw.SizedBox(width: 4),
                    _buildMetricPill('ความดัน (BP)', record.bpReading, interpretBp(record.bpSystolic, record.bpDiastolic)),
                    pw.SizedBox(width: 4),
                    _buildMetricPill('ชีพจร (Pulse)', '${record.pulse ?? "-"} bpm', record.pulse != null ? 'ครั้ง/นาที' : null),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: record.physicalExamResult == 'NORMAL' ? PdfColors.green50 : PdfColors.amber50,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(
                      color: record.physicalExamResult == 'NORMAL' ? PdfColors.green200 : PdfColors.amber300,
                      width: 0.5,
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text('การตรวจร่างกายทั่วไป: ', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text(
                        record.physicalExamResult == 'NORMAL' ? 'ปกติ สมบูรณ์ดี' : 'พบความผิดปกติ (${record.physicalExamNotes ?? "-"})',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          color: record.physicalExamResult == 'NORMAL' ? PdfColors.green900 : PdfColors.amber900,
                          fontWeight: record.physicalExamResult == 'NORMAL' ? pw.FontWeight.normal : pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 7),

                // 3. Lab & Diagnostics Table
                _buildModernSectionHeader('ผลการตรวจทางห้องปฏิบัติการและเครื่องมือพิเศษ', 'Laboratory & Diagnostic Examinations'),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1.4),
                      1: const pw.FlexColumnWidth(1.2),
                      2: const pw.FlexColumnWidth(1.4),
                      3: const pw.FlexColumnWidth(1.2),
                    },
                    children: [
                      _buildLabTableRow(
                        'เอกซเรย์ปอด (Chest X-Ray)', record.chestXrayResult,
                        'ตรวจการได้ยิน (Audiogram)', record.audiogramResult,
                        isHeader: false, isEven: true,
                      ),
                      _buildLabTableRow(
                        'สมรรถภาพปอด (Spirometry)', record.spirometryResult,
                        'การมองเห็น/สายตา (Vision)', record.visionTestResult,
                        isHeader: false, isEven: false,
                      ),
                      _buildLabTableRow(
                        'ความสมบูรณ์เม็ดเลือด (CBC)', record.bloodCbcResult,
                        'ระดับน้ำตาลในเลือด (FBS)', record.bloodSugarResult,
                        isHeader: false, isEven: true,
                      ),
                      _buildLabTableRow(
                        'การทำงานของตับ (Liver)', record.liverFunctionResult,
                        'การทำงานของไต (Kidney)', record.kidneyFunctionResult,
                        isHeader: false, isEven: false,
                      ),
                      _buildLabTableRow(
                        'ตรวจปัสสาวะ (Urine Exam)', record.urineExamResult,
                        'สารเสพติด (Drug Screen)', record.drugScreeningResult,
                        isHeader: false, isEven: true,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 7),

                // 4. Doctor Conclusion & Fitness Box
                _buildModernSectionHeader('สรุปผลการตรวจและความเห็นทางการแพทย์', 'Medical Assessment & Fitness for Duty'),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: record.overallResult == 'NORMAL' ? PdfColors.green50 : (record.overallResult == 'WATCH' ? PdfColors.amber50 : PdfColors.red50),
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(
                      color: record.overallResult == 'NORMAL' ? PdfColors.green300 : (record.overallResult == 'WATCH' ? PdfColors.amber300 : PdfColors.red300),
                      width: 0.8,
                    ),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 7,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                pw.Text('ผลตรวจสุขภาพภาพรวม: ', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                                pw.Text(
                                  record.overallResultPlainLabel,
                                  style: pw.TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: record.overallResult == 'NORMAL' ? PdfColors.green900 : (record.overallResult == 'WATCH' ? PdfColors.amber900 : PdfColors.red900),
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text('คำแนะนำของแพทย์ / Doctor\'s Recommendation:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                            pw.Text(
                              (record.doctorOpinion != null && record.doctorOpinion!.isNotEmpty)
                                  ? record.doctorOpinion!
                                  : (record.overallResult == 'NORMAL' ? 'ผลตรวจร่างกายทั่วไปอยู่ในเกณฑ์ปกติ สุขภาพแข็งแรงดี ปฏิบัติงานได้ตามปกติ' : 'ควรเฝ้าระวังและปฏิบัติตามคำแนะนำของแพทย์อย่างต่อเนื่อง'),
                              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.blueGrey800),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        flex: 5,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('ความพร้อมในการปฏิบัติงาน:', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                            pw.SizedBox(height: 2),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: pw.BoxDecoration(
                                color: record.fitnessToWork == 'FIT'
                                    ? PdfColors.green100
                                    : (record.fitnessToWork == 'FIT_WITH_RESTRICTION' ? PdfColors.amber100 : PdfColors.red100),
                                borderRadius: pw.BorderRadius.circular(4),
                                border: pw.Border.all(
                                  color: record.fitnessToWork == 'FIT'
                                      ? PdfColors.green700
                                      : (record.fitnessToWork == 'FIT_WITH_RESTRICTION' ? PdfColors.amber700 : PdfColors.red700),
                                  width: 0.6,
                                ),
                              ),
                              child: pw.Text(
                                record.fitnessLabel,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: record.fitnessToWork == 'FIT'
                                      ? PdfColors.green900
                                      : (record.fitnessToWork == 'FIT_WITH_RESTRICTION' ? PdfColors.amber900 : PdfColors.red900),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),

                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('หน่วยงานตรวจสุขภาพ: ${record.hospitalName}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
                        pw.Text('แพทย์ผู้ทำการตรวจ: ${record.doctorName ?? "แพทย์อาชีวเวชศาสตร์"}', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                        pw.Text('เลขที่ใบประกอบวิชาชีพเวชกรรม: ${record.doctorLicenseNo ?? "ว.XXXXX"}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('ลงชื่อ.................................................................', style: const pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(height: 2),
                        pw.Text('( ${record.doctorName ?? "................................................................."} )', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text('แพทย์ผู้ตรวจ / ประทับตราสถานพยาบาล', style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey700)),
                        pw.SizedBox(height: 1),
                        pw.Text('วันที่ .......... / .......... / ..............', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) => doc.save(),
        name: 'HealthSummary_${record.employeeCode}_${record.checkupDate}',
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการพิมพ์ใบสรุปผลตรวจสุขภาพ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==========================================================================
  // SHARED UI HELPERS & FORMATTERS
  // ==========================================================================

  /// จัดการแปลงวันที่ให้อ่านง่ายเป็นภาษาไทย เช่น "14 ธันวาคม 2567"
  static String formatThaiDate(String? rawDate, {bool short = false}) {
    if (rawDate == null || rawDate.isEmpty || rawDate == '-') return '-';
    try {
      DateTime dt;
      if (rawDate.contains('T')) {
        dt = DateTime.parse(rawDate).toLocal();
      } else if (rawDate.contains('-')) {
        final parts = rawDate.trim().split('-');
        if (parts.length == 3) {
          int year = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int day = int.parse(parts[2].split(' ')[0]);
          if (year > 2400) year -= 543;
          dt = DateTime(year, month, day);
        } else {
          return rawDate.replaceAll(RegExp(r'T[\d:.]+(Z)?'), '');
        }
      } else if (rawDate.contains('/')) {
        final parts = rawDate.trim().split('/');
        if (parts.length == 3) {
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2].split(' ')[0]);
          if (year > 2400) year -= 543;
          dt = DateTime(year, month, day);
        } else {
          return rawDate;
        }
      } else {
        return rawDate;
      }

      final thaiYear = dt.year > 2400 ? dt.year : dt.year + 543;
      const thaiMonthsLong = [
        '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
        'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
      ];
      const thaiMonthsShort = [
        '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
        'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
      ];

      final mName = short ? thaiMonthsShort[dt.month] : thaiMonthsLong[dt.month];
      return '${dt.day} $mName $thaiYear';
    } catch (_) {
      return rawDate.replaceAll(RegExp(r'T[\d:.]+(Z)?'), '');
    }
  }

  /// จัดการแปลงเลขบัตรประชาชน 13 หลักให้มีขีดคั่น: x-xxxx-xxxxx-xx-x
  static String formatNationalId(String? id) {
    if (id == null || id.isEmpty || id == '-') return '-';
    final clean = id.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 13) {
      return '${clean[0]}-${clean.substring(1, 5)}-${clean.substring(5, 10)}-${clean.substring(10, 12)}-${clean[12]}';
    }
    return id;
  }

  /// แปลผลตรวจแล็บเป็นภาษาไทยให้อ่านง่าย
  static String translateLabResult(String? res) {
    if (res == null || res.isEmpty || res == 'NOT_TESTED') return 'ไม่ได้ตรวจ';
    if (res == 'NORMAL') return 'ปกติ (Normal)';
    if (res == 'ABNORMAL') return 'ผิดปกติ (Abnormal)';
    if (res == 'WATCH') return 'เฝ้าระวัง (Watch)';
    if (res == 'NEGATIVE') return 'ไม่พบสารเสพติด (Negative)';
    if (res == 'POSITIVE') return 'ตรวจพบสารเสพติด (Positive)';
    return res;
  }

  /// แปลผล BMI
  static String interpretBmi(double? bmi) {
    if (bmi == null) return '';
    if (bmi < 18.5) return 'น้ำหนักน้อย/ผอม';
    if (bmi < 23.0) return 'น้ำหนักปกติ';
    if (bmi < 25.0) return 'น้ำหนักเกิน/ท้วม';
    if (bmi < 30.0) return 'อ้วนระดับ 1';
    return 'อ้วนระดับ 2';
  }

  /// แปลผลความดันโลหิต
  static String interpretBp(int? sys, int? dia) {
    if (sys == null || dia == null) return '';
    if (sys < 120 && dia < 80) return 'ปกติ';
    if (sys < 130 && dia < 80) return 'เริ่มสูง';
    if (sys < 140 || dia < 90) return 'เฝ้าระวัง';
    return 'ความดันสูง';
  }

  static String _formatCompanyAddress(CompanyProfile? company) {
    if (company == null) return '-';
    final parts = [
      company.addressNumber != null ? 'เลขที่ ${company.addressNumber}' : null,
      company.moo != null ? 'หมู่ ${company.moo}' : null,
      company.soi != null ? 'ซอย ${company.soi}' : null,
      company.road != null ? 'ถนน ${company.road}' : null,
      company.subdistrict != null ? 'ตำบล/แขวง ${company.subdistrict}' : null,
      company.district != null ? 'อำเภอ/เขต ${company.district}' : null,
      company.province != null ? 'จังหวัด ${company.province}' : null,
      company.postalCode,
    ].where((p) => p != null && p.isNotEmpty).toList();

    return parts.isEmpty ? '-' : parts.join(' ');
  }

  static pw.Widget _buildModernSectionHeader(String title, String subtitle) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4, bottom: 3),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          ),
          pw.Text(
            subtitle,
            style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.blue100),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPersonalInfoCard({
    required Employee employee,
    required String orgName,
    required String fullAddress,
    CompanyProfile? company,
    pw.MemoryImage? photo,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (photo != null) ...[
            pw.Container(
              width: 44,
              height: 55,
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(3),
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 3,
                verticalRadius: 3,
                child: pw.Image(photo, fit: pw.BoxFit.cover),
              ),
            ),
            pw.SizedBox(width: 8),
          ],
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildModernInfoRow('ชื่อ - นามสกุล', employee.fullName, isBold: true),
                pw.SizedBox(height: 1.5),
                _buildModernInfoRow('เลขประจำตัวประชาชน', formatNationalId(employee.nationalId)),
                pw.SizedBox(height: 1.5),
                _buildModernInfoRow('แผนก / ตำแหน่ง', '${employee.department}  |  ${employee.position}'),
                pw.SizedBox(height: 1.5),
                _buildModernInfoRow('วันที่เริ่มเข้าทำงาน', formatThaiDate(employee.hireDate)),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildModernInfoRow('สถานประกอบกิจการ', orgName, isBold: true),
                pw.SizedBox(height: 1.5),
                _buildModernInfoRow('เลขทะเบียนนิติบุคคล', company?.taxId ?? '-'),
                pw.SizedBox(height: 1.5),
                _buildModernInfoRow('ที่ตั้งสถานประกอบการ', fullAddress),
                pw.SizedBox(height: 1.5),
                _buildModernInfoRow('เบอร์โทรศัพท์', company?.phone ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildModernInfoRow(String label, String value, {bool isBold = false}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 7.2, color: PdfColors.grey700),
          ),
        ),
        pw.Text(': ', style: const pw.TextStyle(fontSize: 7.2, color: PdfColors.grey700)),
        pw.Expanded(
          child: pw.Text(
            value.isNotEmpty ? value : '-',
            style: pw.TextStyle(
              fontSize: 7.2,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isBold ? PdfColors.blue900 : PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildHealthRecordCard(EmployeeHealthRecord r) {
    PdfColor resultColor;
    PdfColor resultBg;
    PdfColor resultBorder;
    String resultText;

    switch (r.overallResult) {
      case 'NORMAL':
        resultColor = PdfColors.green900;
        resultBg = PdfColors.green50;
        resultBorder = PdfColors.green300;
        resultText = 'ผลตรวจปกติ (Normal)';
        break;
      case 'WATCH':
        resultColor = PdfColors.amber900;
        resultBg = PdfColors.amber50;
        resultBorder = PdfColors.amber300;
        resultText = 'เฝ้าระวัง (Watch)';
        break;
      case 'ABNORMAL':
        resultColor = PdfColors.red900;
        resultBg = PdfColors.red50;
        resultBorder = PdfColors.red300;
        resultText = 'ผิดปกติ (Abnormal)';
        break;
      default:
        resultColor = PdfColors.grey800;
        resultBg = PdfColors.grey100;
        resultBorder = PdfColors.grey300;
        resultText = 'รอผลตรวจ (Pending)';
    }

    final formattedDate = formatThaiDate(r.checkupDate);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // 1. Header Bar
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 5,
                      height: 5,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue900,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Text(
                      r.checkupTypeLabel,
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'วันที่ตรวจ: $formattedDate',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: pw.BoxDecoration(
                    color: resultBg,
                    borderRadius: pw.BorderRadius.circular(3),
                    border: pw.Border.all(color: resultBorder, width: 0.6),
                  ),
                  child: pw.Text(
                    resultText,
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: resultColor),
                  ),
                ),
              ],
            ),
          ),

          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Hospital & Physician
                pw.Row(
                  children: [
                    pw.Text('สถานพยาบาล: ', style: const pw.TextStyle(fontSize: 7.2, color: PdfColors.grey700)),
                    pw.Text(r.hospitalName.isNotEmpty ? r.hospitalName : '-', style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 10),
                    pw.Text('แพทย์ผู้ตรวจ: ', style: const pw.TextStyle(fontSize: 7.2, color: PdfColors.grey700)),
                    pw.Text(r.doctorName ?? 'แพทย์เวชศาสตร์ครอบครัว/อาชีวเวชศาสตร์', style: const pw.TextStyle(fontSize: 7.2)),
                    if (r.doctorLicenseNo != null && r.doctorLicenseNo!.isNotEmpty)
                      pw.Text(' (${r.doctorLicenseNo})', style: const pw.TextStyle(fontSize: 7.2, color: PdfColors.grey700)),
                  ],
                ),
                pw.SizedBox(height: 4),

                // Vitals & Metrics 5 Boxes
                pw.Row(
                  children: [
                    _buildMetricPill('น้ำหนัก', '${r.weight ?? "-"} กก.', null),
                    pw.SizedBox(width: 3.5),
                    _buildMetricPill('ส่วนสูง', '${r.height ?? "-"} ซม.', null),
                    pw.SizedBox(width: 3.5),
                    _buildMetricPill('BMI', r.bmi?.toStringAsFixed(1) ?? '-', interpretBmi(r.bmi)),
                    pw.SizedBox(width: 3.5),
                    _buildMetricPill('ความดัน (BP)', r.bpReading, interpretBp(r.bpSystolic, r.bpDiastolic)),
                    pw.SizedBox(width: 3.5),
                    _buildMetricPill('ชีพจร (Pulse)', '${r.pulse ?? "-"} bpm', r.pulse != null ? 'ครั้ง/นาที' : null),
                  ],
                ),
                pw.SizedBox(height: 5),

                // Lab & Diagnostic Test Grid
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1.4),
                      1: const pw.FlexColumnWidth(1.2),
                      2: const pw.FlexColumnWidth(1.4),
                      3: const pw.FlexColumnWidth(1.2),
                    },
                    children: [
                      _buildLabTableRow(
                        'เอกซเรย์ปอด (Chest X-Ray)', r.chestXrayResult,
                        'ตรวจการได้ยิน (Audiogram)', r.audiogramResult,
                        isHeader: false, isEven: true,
                      ),
                      _buildLabTableRow(
                        'สมรรถภาพปอด (Spirometry)', r.spirometryResult,
                        'การมองเห็น/สายตา (Vision)', r.visionTestResult,
                        isHeader: false, isEven: false,
                      ),
                      _buildLabTableRow(
                        'ความสมบูรณ์เม็ดเลือด (CBC)', r.bloodCbcResult,
                        'ระดับน้ำตาลในเลือด (FBS)', r.bloodSugarResult,
                        isHeader: false, isEven: true,
                      ),
                      _buildLabTableRow(
                        'การทำงานของตับ (Liver)', r.liverFunctionResult,
                        'การทำงานของไต (Kidney)', r.kidneyFunctionResult,
                        isHeader: false, isEven: false,
                      ),
                      _buildLabTableRow(
                        'ตรวจปัสสาวะ (Urine Exam)', r.urineExamResult,
                        'สารเสพติด (Drug Screen)', r.drugScreeningResult,
                        isHeader: false, isEven: true,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),

                // Doctor Assessment & Fitness Box
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.blue200, width: 0.5),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 7,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'ความเห็นและคำแนะนำของแพทย์:',
                              style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                            ),
                            pw.Text(
                              (r.doctorOpinion != null && r.doctorOpinion!.isNotEmpty)
                                  ? r.doctorOpinion!
                                  : (r.overallResult == 'NORMAL' ? 'ผลตรวจร่างกายทั่วไปอยู่ในเกณฑ์ปกติ สุขภาพแข็งแรงดี' : 'ควรเฝ้าระวังและปฏิบัติตามคำแนะนำของแพทย์'),
                              style: const pw.TextStyle(fontSize: 7.2, color: PdfColors.blueGrey800),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Expanded(
                        flex: 5,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'ความพร้อมทำงาน (Fitness):',
                              style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                            ),
                            pw.SizedBox(height: 1.5),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: pw.BoxDecoration(
                                color: r.fitnessToWork == 'FIT'
                                    ? PdfColors.green100
                                    : (r.fitnessToWork == 'FIT_WITH_RESTRICTION' ? PdfColors.amber100 : PdfColors.red100),
                                borderRadius: pw.BorderRadius.circular(3),
                                border: pw.Border.all(
                                  color: r.fitnessToWork == 'FIT'
                                      ? PdfColors.green700
                                      : (r.fitnessToWork == 'FIT_WITH_RESTRICTION' ? PdfColors.amber700 : PdfColors.red700),
                                  width: 0.5,
                                ),
                              ),
                              child: pw.Text(
                                r.fitnessLabel,
                                style: pw.TextStyle(
                                  fontSize: 7.2,
                                  fontWeight: pw.FontWeight.bold,
                                  color: r.fitnessToWork == 'FIT'
                                      ? PdfColors.green900
                                      : (r.fitnessToWork == 'FIT_WITH_RESTRICTION' ? PdfColors.amber900 : PdfColors.red900),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricPill(String title, String value, String? sub) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 3),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.circular(3),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 6.2, color: PdfColors.grey700)),
            pw.SizedBox(height: 0.5),
            pw.Text(value, style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            if (sub != null && sub.isNotEmpty)
              pw.Text(sub, style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey600), maxLines: 1),
          ],
        ),
      ),
    );
  }

  static pw.TableRow _buildLabTableRow(
    String test1, String res1,
    String test2, String res2, {
    required bool isHeader,
    required bool isEven,
  }) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isEven ? PdfColors.white : PdfColors.grey50,
      ),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: pw.Text(test1, style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey800)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: _buildLabResultBadge(res1),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: pw.Text(test2, style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey800)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: _buildLabResultBadge(res2),
        ),
      ],
    );
  }

  static pw.Widget _buildLabResultBadge(String rawResult) {
    final label = translateLabResult(rawResult);
    final isAbnormal = rawResult == 'ABNORMAL' || rawResult == 'POSITIVE';
    final isWatch = rawResult == 'WATCH';
    final isNotTested = rawResult == 'NOT_TESTED' || rawResult.isEmpty;

    PdfColor textColor = PdfColors.green900;
    if (isAbnormal) {
      textColor = PdfColors.red900;
    } else if (isWatch) {
      textColor = PdfColors.amber900;
    } else if (isNotTested) {
      textColor = PdfColors.grey600;
    }

    return pw.Text(
      label,
      style: pw.TextStyle(
        fontSize: 6.8,
        fontWeight: isAbnormal ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: textColor,
      ),
    );
  }

  static pw.Widget _buildSignatureBoxes(Employee employee) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Left Box: Employee
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(7),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(5),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'ลูกจ้างผู้ถือสมุดสุขภาพ',
                  style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'ลงชื่อ.................................................................',
                  style: const pw.TextStyle(fontSize: 7.2),
                ),
                pw.SizedBox(height: 1.5),
                pw.Text(
                  '( ${employee.fullName} )',
                  style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'ตำแหน่ง: ${employee.position}',
                  style: const pw.TextStyle(fontSize: 6.2, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 1.5),
                pw.Text(
                  'วันที่ .......... / .......... / ..............',
                  style: const pw.TextStyle(fontSize: 6.2, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),

        // Right Box: Employer / OSH Officer
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(7),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(5),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'นายจ้าง / แพทย์ผู้ตรวจ / เจ้าหน้าที่ความปลอดภัย',
                  style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'ลงชื่อ.................................................................',
                  style: const pw.TextStyle(fontSize: 7.2),
                ),
                pw.SizedBox(height: 1.5),
                pw.Text(
                  '( ................................................................. )',
                  style: const pw.TextStyle(fontSize: 7.2),
                ),
                pw.Text(
                  'เจ้าหน้าที่ความปลอดภัยในการทำงานระดับวิชาชีพ / นายจ้าง',
                  style: const pw.TextStyle(fontSize: 6.2, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 1.5),
                pw.Text(
                  'วันที่ .......... / .......... / ..............',
                  style: const pw.TextStyle(fontSize: 6.2, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
