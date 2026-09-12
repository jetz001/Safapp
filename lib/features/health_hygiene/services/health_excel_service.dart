import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/models/health_models.dart';
import '../data/repositories/health_repository.dart';
import '../../employee/data/repositories/employee_repository.dart';
import '../../employee/domain/models/employee_models.dart';

class HealthImportResult {
  final int totalRows;
  final int successCount;
  final int failedCount;
  final List<String> errorMessages;

  const HealthImportResult({
    required this.totalRows,
    required this.successCount,
    required this.failedCount,
    required this.errorMessages,
  });
}

class HealthExcelService {
  /// สร้างและดาวน์โหลดไฟล์ Template Excel สำหรับกรอกผลตรวจสุขภาพพนักงานรายปี
  static Future<String?> downloadTemplate({int? year}) async {
    final excel = Excel.createExcel();
    final sheetName = 'Health_Checkup_Template';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    final currentYearCe = year ?? DateTime.now().year;
    final currentYearBe = currentYearCe + 543;

    // Header row (28 คอลัมน์ ครอบคลุมผลตรวจตามมาตรฐาน รพ. และกฎกระทรวง)
    sheet.appendRow([
      TextCellValue('รหัสพนักงาน (Employee Code) *'),
      TextCellValue('ชื่อ - นามสกุล *'),
      TextCellValue('ปีตรวจสุขภาพ (พ.ศ. หรือ ค.ศ.) *'),
      TextCellValue('วันที่ตรวจ (YYYY-MM-DD) *'),
      TextCellValue('ประเภทการตรวจ (ANNUAL/PRE_EMPLOYMENT/RISK_BASED)'),
      TextCellValue('โรงพยาบาล/คลินิกที่ตรวจ *'),
      TextCellValue('ชื่อแพทย์ผู้ตรวจ'),
      TextCellValue('เลขที่ใบอนุญาตแพทย์'),
      TextCellValue('ผลตรวจภาพรวม (NORMAL/WATCH/ABNORMAL) *'),
      TextCellValue('น้ำหนัก (กก.)'),
      TextCellValue('ส่วนสูง (ซม.)'),
      TextCellValue('ความดันโลหิต (เช่น 120/80 หรือตัวบน)'),
      TextCellValue('ความดันตัวล่าง (Diastolic)'),
      TextCellValue('ชีพจร (ครั้ง/นาที)'),
      TextCellValue('การตรวจร่างกายทั่วไป (NORMAL/ABNORMAL)'),
      TextCellValue('เอ็กซเรย์ปอด Chest X-Ray (NORMAL/ABNORMAL/NOT_TESTED)'),
      TextCellValue('การได้ยิน Audiogram (NORMAL/ABNORMAL/NOT_TESTED)'),
      TextCellValue('สมรรถภาพปอด Spirometry (NORMAL/ABNORMAL/NOT_TESTED)'),
      TextCellValue('สายตาและการมองเห็น Vision Test (NORMAL/ABNORMAL/NOT_TESTED)'),
      TextCellValue('ความสมบูรณ์ของเม็ดเลือด CBC (NORMAL/ABNORMAL/NOT_TESTED)'),
      TextCellValue('น้ำตาลในเลือด FBS (NORMAL/ABNORMAL/NOT_TESTED)'),
      TextCellValue('การทำงานของตับ LFT (NORMAL/ABNORMAL/NOT_TESTED)'),
      TextCellValue('การทำงานของไต BUN/Cr (NORMAL/ABNORMAL/NOT_TESTED)'),
      TextCellValue('ตรวจปัสสาวะ Urine Exam (NORMAL/ABNORMAL/NOT_TESTED)'),
      TextCellValue('สารเสพติด Drug Screen (NEGATIVE/POSITIVE/NOT_TESTED)'),
      TextCellValue('ความพร้อมทำงาน (FIT/FIT_WITH_RESTRICTION/UNFIT)'),
      TextCellValue('ความเห็นแพทย์ / คำแนะนำ'),
      TextCellValue('หมายเหตุการตรวจร่างกาย'),
    ]);

    // Sample Row 1: ตรวจสุขภาพประจำปี ปกติ (Fit for Duty)
    sheet.appendRow([
      TextCellValue('EMP-001'),
      TextCellValue('สมศักดิ์ รักปลอดภัย'),
      TextCellValue('$currentYearBe'),
      TextCellValue('$currentYearCe-02-15'),
      TextCellValue('ANNUAL'),
      TextCellValue('โรงพยาบาลสุขุมวิทอินเตอร์เนชั่นแนล'),
      TextCellValue('นพ. ธีรภัทร ชาญเวช'),
      TextCellValue('ว. 45678'),
      TextCellValue('NORMAL'),
      TextCellValue('68.5'),
      TextCellValue('172.0'),
      TextCellValue('118'),
      TextCellValue('76'),
      TextCellValue('72'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NEGATIVE'),
      TextCellValue('FIT'),
      TextCellValue('สุขภาพแข็งแรงดี พร้อมปฏิบัติงานได้ตามปกติ'),
      TextCellValue('ไม่มีอาการผิดปกติ'),
    ]);

    // Sample Row 2: เฝ้าระวังความดัน/น้ำตาล (Watch)
    sheet.appendRow([
      TextCellValue('EMP-002'),
      TextCellValue('วิภาดา มั่นคงดี'),
      TextCellValue('$currentYearBe'),
      TextCellValue('$currentYearCe-02-15'),
      TextCellValue('ANNUAL'),
      TextCellValue('โรงพยาบาลสุขุมวิทอินเตอร์เนชั่นแนล'),
      TextCellValue('พญ. ณิชากานต์ สุขใจ'),
      TextCellValue('ว. 51234'),
      TextCellValue('WATCH'),
      TextCellValue('62.0'),
      TextCellValue('158.0'),
      TextCellValue('135'),
      TextCellValue('88'),
      TextCellValue('78'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('ABNORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NEGATIVE'),
      TextCellValue('FIT_WITH_RESTRICTION'),
      TextCellValue('น้ำตาลในเลือดสูงเล็กน้อย (FBS 112 mg/dL) ควรควบคุมอาหารหวานและออกกำลังกาย'),
      TextCellValue('นัดติดตามผลน้ำตาลซ้ำ ๓ เดือน'),
    ]);

    // Sample Row 3: ตรวจตามปัจจัยเสี่ยงเสียงดัง หูตึงเล็กน้อย (Abnormal)
    sheet.appendRow([
      TextCellValue('EMP-003'),
      TextCellValue('อนันต์ เชี่ยวชาญงานช่าง'),
      TextCellValue('$currentYearBe'),
      TextCellValue('$currentYearCe-02-16'),
      TextCellValue('RISK_BASED'),
      TextCellValue('โรงพยาบาลสุขุมวิทอินเตอร์เนชั่นแนล'),
      TextCellValue('นพ. ธีรภัทร ชาญเวช'),
      TextCellValue('ว. 45678'),
      TextCellValue('ABNORMAL'),
      TextCellValue('75.0'),
      TextCellValue('168.0'),
      TextCellValue('124'),
      TextCellValue('82'),
      TextCellValue('74'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('ABNORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NORMAL'),
      TextCellValue('NEGATIVE'),
      TextCellValue('FIT_WITH_RESTRICTION'),
      TextCellValue('พบการได้ยินลดลงที่ความถี่ 4000 Hz ต้องสวมใส่อุปกรณ์ครอบหูลดเสียง (Earmuffs) ตลอดเวลาในพื้นที่ปฏิบัติงาน'),
      TextCellValue('ส่งพบแพทย์อาชีวเวชศาสตร์ติดตามอาการ'),
    ]);

    final fileBytes = excel.save();
    if (fileBytes == null) return null;

    final appDocDir = await getApplicationDocumentsDirectory();
    final templateDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'templates'));
    if (!await templateDir.exists()) {
      await templateDir.create(recursive: true);
    }

    final targetPath = p.join(templateDir.path, 'SAFAPP_Health_Checkup_Template_$currentYearBe.xlsx');
    final file = File(targetPath);
    await file.writeAsBytes(fileBytes);

    return targetPath;
  }

  /// นำเข้าข้อมูลผลตรวจสุขภาพจากไฟล์ Excel (.xlsx)
  static Future<HealthImportResult> importHealthRecordsFromExcel(
    String filePath,
    HealthRepository healthRepo,
    EmployeeRepository employeeRepo, {
    int? defaultYear,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return const HealthImportResult(
        totalRows: 0,
        successCount: 0,
        failedCount: 0,
        errorMessages: ['ไม่พบไฟล์ที่เลือก'],
      );
    }

    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    // 1. ดึงรายชื่อพนักงานทั้งหมดเพื่อทำ Map สำหรับค้นหาอย่างรวดเร็ว
    final employees = await employeeRepo.getAllEmployees();
    final empByCode = <String, Employee>{};
    final empByName = <String, Employee>{};
    final empByIdCard = <String, Employee>{};

    for (final emp in employees) {
      final code = emp.employeeCode.trim().toLowerCase();
      if (code.isNotEmpty) empByCode[code] = emp;

      final name = emp.fullName.trim().toLowerCase();
      if (name.isNotEmpty) empByName[name] = emp;

      final idCard = emp.nationalId?.trim() ?? '';
      if (idCard.isNotEmpty) empByIdCard[idCard] = emp;
    }

    int success = 0;
    int failed = 0;
    int total = 0;
    final errors = <String>[];

    for (final table in excel.tables.keys) {
      final rows = excel.tables[table]!.rows;
      if (rows.length <= 1) continue; // มีแค่ header

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        total++;
        final rowNum = i + 1;

        try {
          final empCodeRaw = _cellValue(row, 0);
          final empNameRaw = _cellValue(row, 1);
          final yearRaw = _cellValue(row, 2);
          final dateRaw = _cellValue(row, 3);
          final typeRaw = _cellValue(row, 4);
          final hospitalRaw = _cellValue(row, 5);

          // ถ้าไม่มีข้อมูลสำคัญข้ามแถวว่าง
          if (empCodeRaw.isEmpty && empNameRaw.isEmpty && hospitalRaw.isEmpty) {
            total--;
            continue;
          }

          // 2. ค้นหาพนักงาน
          Employee? matchedEmp;
          if (empCodeRaw.isNotEmpty && empByCode.containsKey(empCodeRaw.toLowerCase())) {
            matchedEmp = empByCode[empCodeRaw.toLowerCase()];
          } else if (empNameRaw.isNotEmpty && empByName.containsKey(empNameRaw.toLowerCase())) {
            matchedEmp = empByName[empNameRaw.toLowerCase()];
          }

          // ถ้ายังไม่พบพนักงาน แต่มีรหัสและชื่อพนักงานครบ ให้สร้างพนักงานใหม่อัตโนมัติ
          if (matchedEmp == null) {
            if (empCodeRaw.isNotEmpty && empNameRaw.isNotEmpty) {
              final newEmp = Employee(
                employeeCode: empCodeRaw,
                fullName: empNameRaw,
                department: 'ฝ่ายผลิตและปฏิบัติการ',
                position: 'พนักงาน',
                status: 'ACTIVE',
              );
              final newId = await employeeRepo.saveEmployee(newEmp);
              matchedEmp = newEmp.copyWith(id: newId);
              empByCode[empCodeRaw.toLowerCase()] = matchedEmp;
              empByName[empNameRaw.toLowerCase()] = matchedEmp;
            } else {
              failed++;
              errors.add('แถว $rowNum: ไม่พบข้อมูลพนักงานรหัส "$empCodeRaw" หรือชื่อ "$empNameRaw" ในระบบ');
              continue;
            }
          }

          // 3. จัดการวันที่ตรวจสุขภาพ
          String finalCheckupDate = _parseDate(dateRaw, yearRaw: yearRaw, fallbackYear: defaultYear);
          if (finalCheckupDate.isEmpty) {
            finalCheckupDate = DateTime.now().toIso8601String().substring(0, 10);
          }

          // 4. จัดการประเภทการตรวจ
          final checkupType = _parseCheckupType(typeRaw);

          // 5. โรงพยาบาล
          final hospitalName = hospitalRaw.isNotEmpty ? hospitalRaw : 'โรงพยาบาล/หน่วยตรวจสุขภาพเคลื่อนที่';

          // 6. ข้อมูลแพทย์
          final doctorName = _cellValue(row, 6).isNotEmpty ? _cellValue(row, 6) : null;
          final doctorLicense = _cellValue(row, 7).isNotEmpty ? _cellValue(row, 7) : null;

          // 7. ผลตรวจภาพรวม
          final overallResult = _parseOverallResult(_cellValue(row, 8));

          // 8. สัญญาณชีพและสัดส่วน
          final weight = double.tryParse(_cellValue(row, 9));
          final height = double.tryParse(_cellValue(row, 10));
          double? bmi;
          if (weight != null && height != null && height > 0) {
            final heightM = height / 100.0;
            bmi = double.parse((weight / (heightM * heightM)).toStringAsFixed(1));
          }

          // ความดันโลหิต (รองรับทั้งช่องเดียว 120/80 หรือแยกช่อง)
          int? bpSystolic;
          int? bpDiastolic;
          final bpRaw1 = _cellValue(row, 11);
          final bpRaw2 = _cellValue(row, 12);

          if (bpRaw1.contains('/')) {
            final parts = bpRaw1.split('/');
            bpSystolic = int.tryParse(parts[0].trim());
            if (parts.length > 1) {
              bpDiastolic = int.tryParse(parts[1].trim());
            }
          } else {
            bpSystolic = int.tryParse(bpRaw1);
            bpDiastolic = int.tryParse(bpRaw2);
          }

          final pulse = int.tryParse(_cellValue(row, 13));

          // 9. ผลตรวจทั่วไปและแล็บ
          final physicalExam = _parseExamResult(_cellValue(row, 14));
          final chestXray = _parseExamResult(_cellValue(row, 15));
          final audiogram = _parseExamResult(_cellValue(row, 16));
          final spirometry = _parseExamResult(_cellValue(row, 17));
          final visionTest = _parseExamResult(_cellValue(row, 18));
          final bloodCbc = _parseExamResult(_cellValue(row, 19));
          final bloodSugar = _parseExamResult(_cellValue(row, 20));
          final liverFunc = _parseExamResult(_cellValue(row, 21));
          final kidneyFunc = _parseExamResult(_cellValue(row, 22));
          final urineExam = _parseExamResult(_cellValue(row, 23));
          final drugScreen = _parseDrugResult(_cellValue(row, 24));

          // 10. ความพร้อมทำงานและความเห็นแพทย์
          final fitnessToWork = _parseFitness(_cellValue(row, 25));
          final doctorOpinion = _cellValue(row, 26).isNotEmpty ? _cellValue(row, 26) : null;
          final physicalNotes = _cellValue(row, 27).isNotEmpty ? _cellValue(row, 27) : null;

          final record = EmployeeHealthRecord(
            employeeId: matchedEmp.id!,
            checkupType: checkupType,
            checkupDate: finalCheckupDate,
            hospitalName: hospitalName,
            doctorName: doctorName,
            doctorLicenseNo: doctorLicense,
            overallResult: overallResult,
            weight: weight,
            height: height,
            bmi: bmi,
            bpSystolic: bpSystolic,
            bpDiastolic: bpDiastolic,
            pulse: pulse,
            physicalExamResult: physicalExam,
            physicalExamNotes: physicalNotes,
            chestXrayResult: chestXray,
            audiogramResult: audiogram,
            spirometryResult: spirometry,
            visionTestResult: visionTest,
            bloodCbcResult: bloodCbc,
            bloodSugarResult: bloodSugar,
            liverFunctionResult: liverFunc,
            kidneyFunctionResult: kidneyFunc,
            urineExamResult: urineExam,
            drugScreeningResult: drugScreen,
            doctorOpinion: doctorOpinion,
            fitnessToWork: fitnessToWork,
          );

          await healthRepo.saveHealthRecord(record);
          success++;
        } catch (e) {
          failed++;
          errors.add('แถว $rowNum: เกิดข้อผิดพลาดในการบันทึก ($e)');
        }
      }
    }

    return HealthImportResult(
      totalRows: total,
      successCount: success,
      failedCount: failed,
      errorMessages: errors,
    );
  }

  /// ส่งออกข้อมูลผลตรวจสุขภาพพนักงานเป็นไฟล์ Excel
  static Future<String?> exportHealthRecordsToExcel(
    List<EmployeeHealthRecord> records, {
    String? yearLabel,
  }) async {
    if (records.isEmpty) return null;

    final excel = Excel.createExcel();
    final sheetName = 'Health_Records_${yearLabel ?? "All"}';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    sheet.appendRow([
      TextCellValue('ลำดับ'),
      TextCellValue('รหัสพนักงาน'),
      TextCellValue('ชื่อ - นามสกุล'),
      TextCellValue('แผนก / ฝ่าย'),
      TextCellValue('วันที่ตรวจ'),
      TextCellValue('ประเภทการตรวจ'),
      TextCellValue('โรงพยาบาล/สถานที่ตรวจ'),
      TextCellValue('ผลตรวจภาพรวม'),
      TextCellValue('ความพร้อมทำงาน'),
      TextCellValue('BMI'),
      TextCellValue('ความดันโลหิต'),
      TextCellValue('ชีพจร'),
      TextCellValue('เอ็กซเรย์ปอด'),
      TextCellValue('การได้ยิน'),
      TextCellValue('สมรรถภาพปอด'),
      TextCellValue('สายตา'),
      TextCellValue('เม็ดเลือด (CBC)'),
      TextCellValue('น้ำตาล (FBS)'),
      TextCellValue('การทำงานของตับ'),
      TextCellValue('การทำงานของไต'),
      TextCellValue('ตรวจปัสสาวะ'),
      TextCellValue('สารเสพติด'),
      TextCellValue('ความเห็นแพทย์'),
    ]);

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      sheet.appendRow([
        TextCellValue('${i + 1}'),
        TextCellValue(r.employeeCode ?? '-'),
        TextCellValue(r.employeeName ?? '-'),
        TextCellValue(r.department ?? '-'),
        TextCellValue(r.checkupDate),
        TextCellValue(r.checkupTypeLabel),
        TextCellValue(r.hospitalName),
        TextCellValue(r.overallResultPlainLabel),
        TextCellValue(r.fitnessLabel),
        TextCellValue(r.bmi?.toString() ?? '-'),
        TextCellValue(r.bpReading),
        TextCellValue(r.pulse?.toString() ?? '-'),
        TextCellValue(r.chestXrayResult),
        TextCellValue(r.audiogramResult),
        TextCellValue(r.spirometryResult),
        TextCellValue(r.visionTestResult),
        TextCellValue(r.bloodCbcResult),
        TextCellValue(r.bloodSugarResult),
        TextCellValue(r.liverFunctionResult),
        TextCellValue(r.kidneyFunctionResult),
        TextCellValue(r.urineExamResult),
        TextCellValue(r.drugScreeningResult),
        TextCellValue(r.doctorOpinion ?? '-'),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes == null) return null;

    final appDocDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final filename = 'Health_Checkup_Export_${yearLabel ?? DateTime.now().year}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final targetPath = p.join(exportDir.path, filename);
    final file = File(targetPath);
    await file.writeAsBytes(fileBytes);

    return targetPath;
  }

  // --------------------------------------------------------------------------
  // Helper Parsers
  // --------------------------------------------------------------------------

  static String _cellValue(List<Data?> row, int index) {
    if (index >= row.length || row[index] == null || row[index]?.value == null) {
      return '';
    }
    return row[index]!.value.toString().trim();
  }

  static String _parseDate(String dateRaw, {String? yearRaw, int? fallbackYear}) {
    if (dateRaw.isEmpty) {
      final y = fallbackYear ?? DateTime.now().year;
      return '$y-01-01';
    }

    // กรณีมีเครื่องหมาย / เช่น 15/02/2026 หรือ 15/02/2569
    if (dateRaw.contains('/')) {
      final parts = dateRaw.split('/');
      if (parts.length == 3) {
        int d = int.tryParse(parts[0].trim()) ?? 1;
        int m = int.tryParse(parts[1].trim()) ?? 1;
        int y = int.tryParse(parts[2].trim()) ?? (fallbackYear ?? DateTime.now().year);
        if (y > 2400) y -= 543; // แปลง พ.ศ. -> ค.ศ.
        final dStr = d.toString().padLeft(2, '0');
        final mStr = m.toString().padLeft(2, '0');
        return '$y-$mStr-$dStr';
      }
    }

    // กรณีมีเครื่องหมาย - เช่น 2026-02-15 หรือ 2569-02-15
    if (dateRaw.contains('-')) {
      final parts = dateRaw.split('-');
      if (parts.length == 3) {
        int y = int.tryParse(parts[0].trim()) ?? (fallbackYear ?? DateTime.now().year);
        if (y > 2400) y -= 543;
        final m = parts[1].trim().padLeft(2, '0');
        final d = parts[2].trim().padLeft(2, '0');
        return '$y-$m-$d';
      }
    }

    // กรณีใส่เฉพาะปี หรือปีแยกมา
    int? parsedYear = int.tryParse(yearRaw ?? '');
    if (parsedYear != null && parsedYear > 2400) parsedYear -= 543;
    final y = parsedYear ?? fallbackYear ?? DateTime.now().year;
    return '$y-01-01';
  }

  static String _parseCheckupType(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('pre') || lower.contains('ก่อน') || lower.contains('แรกเข้า')) {
      return 'PRE_EMPLOYMENT';
    }
    if (lower.contains('risk') || lower.contains('เสี่ยง')) {
      return 'RISK_BASED';
    }
    if (lower.contains('job') || lower.contains('เปลี่ยนงาน')) {
      return 'JOB_CHANGE';
    }
    if (lower.contains('return') || lower.contains('กลับเข้า')) {
      return 'RETURN_TO_WORK';
    }
    return 'ANNUAL';
  }

  static String _parseOverallResult(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('watch') || lower.contains('เฝ้าระวัง') || lower.contains('เตือน') || lower == '2') {
      return 'WATCH';
    }
    if (lower.contains('abnormal') || lower.contains('ผิดปกติ') || lower.contains('ไม่ผ่าน') || lower == '3') {
      return 'ABNORMAL';
    }
    if (lower.contains('pending') || lower.contains('รอ')) {
      return 'PENDING';
    }
    return 'NORMAL';
  }

  static String _parseExamResult(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('abnormal') || lower.contains('ผิดปกติ') || lower.contains('pos') || lower == '1') {
      return 'ABNORMAL';
    }
    if (lower.contains('not') || lower.contains('ไม่ได้ตรวจ') || lower == '-' || lower.isEmpty) {
      return 'NOT_TESTED';
    }
    return 'NORMAL';
  }

  static String _parseDrugResult(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('pos') || lower.contains('พบ') || lower.contains('บวก') || lower == '1') {
      return 'POSITIVE';
    }
    if (lower.contains('not') || lower.contains('ไม่ได้ตรวจ') || lower == '-' || lower.isEmpty) {
      return 'NOT_TESTED';
    }
    return 'NEGATIVE';
  }

  static String _parseFitness(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('restriction') || lower.contains('เงื่อนไข')) {
      return 'FIT_WITH_RESTRICTION';
    }
    if (lower.contains('unfit') || lower.contains('ไม่พร้อม')) {
      return 'UNFIT';
    }
    if (lower.contains('pending') || lower.contains('รอ')) {
      return 'PENDING';
    }
    return 'FIT';
  }
}
