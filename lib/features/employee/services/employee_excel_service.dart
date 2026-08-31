import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/models/employee_models.dart';
import '../data/repositories/employee_repository.dart';

class EmployeeExcelService {
  /// สร้างและบันทึกไฟล์ Template สำหรับนำเข้าข้อมูลพนักงาน
  static Future<String?> downloadTemplate() async {
    final excel = Excel.createExcel();
    final sheetName = 'Employee_Template';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    // Header row
    sheet.appendRow([
      TextCellValue('รหัสพนักงาน (ห้ามซ้ำ) *'),
      TextCellValue('ชื่อ - นามสกุล *'),
      TextCellValue('แผนก / ฝ่าย *'),
      TextCellValue('ตำแหน่งงาน *'),
      TextCellValue('บทบาทด้านความปลอดภัย (GENERAL/SUPERVISOR_SAFETY/EXECUTIVE_SAFETY/COMMITTEE_MEMBER/ERT_FIREFIGHTER/FIRST_AIDER)'),
      TextCellValue('เลขประจำตัวประชาชน'),
      TextCellValue('วันที่เริ่มงาน (YYYY-MM-DD)'),
      TextCellValue('เบอร์โทรศัพท์'),
      TextCellValue('อีเมล'),
      TextCellValue('สถานะ (ACTIVE/RESIGNED)'),
    ]);

    // Sample rows
    sheet.appendRow([
      TextCellValue('EMP-001'),
      TextCellValue('สมศักดิ์ รักปลอดภัย'),
      TextCellValue('ฝ่ายผลิตและซ่อมบำรุง'),
      TextCellValue('หัวหน้าแผนกผลิต'),
      TextCellValue('SUPERVISOR_SAFETY'),
      TextCellValue('1100500123456'),
      TextCellValue('2022-01-15'),
      TextCellValue('081-234-5678'),
      TextCellValue('somsak@company.com'),
      TextCellValue('ACTIVE'),
    ]);

    sheet.appendRow([
      TextCellValue('EMP-002'),
      TextCellValue('วิภาดา มั่นคงดี'),
      TextCellValue('ฝ่ายทรัพยากรบุคคลและธุรการ'),
      TextCellValue('เจ้าหน้าที่บุคคล'),
      TextCellValue('COMMITTEE_MEMBER'),
      TextCellValue('3100600987654'),
      TextCellValue('2023-05-01'),
      TextCellValue('089-876-5432'),
      TextCellValue('wipada@company.com'),
      TextCellValue('ACTIVE'),
    ]);

    sheet.appendRow([
      TextCellValue('EMP-003'),
      TextCellValue('อนันต์ เชี่ยวชาญงานช่าง'),
      TextCellValue('ฝ่ายวิศวกรรมอาคาร'),
      TextCellValue('ช่างเทคนิคอาวุโส'),
      TextCellValue('ERT_FIREFIGHTER'),
      TextCellValue('1509900345678'),
      TextCellValue('2021-09-10'),
      TextCellValue('092-345-6789'),
      TextCellValue('anan@company.com'),
      TextCellValue('ACTIVE'),
    ]);

    final fileBytes = excel.save();
    if (fileBytes == null) return null;

    final appDocDir = await getApplicationDocumentsDirectory();
    final templateDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'templates'));
    if (!await templateDir.exists()) {
      await templateDir.create(recursive: true);
    }

    final targetPath = p.join(templateDir.path, 'SAFAPP_Employee_Template.xlsx');
    final file = File(targetPath);
    await file.writeAsBytes(fileBytes);

    return targetPath;
  }

  /// นำเข้าข้อมูลพนักงานจากไฟล์ Excel (.xlsx)
  static Future<int> importEmployeesFromExcel(String filePath, EmployeeRepository repo) async {
    final file = File(filePath);
    if (!await file.exists()) return 0;

    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    int count = 0;
    for (final table in excel.tables.keys) {
      final rows = excel.tables[table]!.rows;
      if (rows.length <= 1) continue; // Only header

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        String getCellVal(int idx) {
          if (idx >= row.length || row[idx] == null || row[idx]!.value == null) return '';
          return row[idx]!.value.toString().trim();
        }

        final empCode = getCellVal(0);
        final fullName = getCellVal(1);
        final department = getCellVal(2);
        final position = getCellVal(3);
        var safetyRole = getCellVal(4).toUpperCase();
        final nationalId = getCellVal(5);
        final hireDate = getCellVal(6);
        final phone = getCellVal(7);
        final email = getCellVal(8);
        var status = getCellVal(9).toUpperCase();

        if (empCode.isEmpty || fullName.isEmpty) continue;

        if (safetyRole.isEmpty ||
            !['GENERAL', 'SUPERVISOR_SAFETY', 'EXECUTIVE_SAFETY', 'COMMITTEE_MEMBER', 'ERT_FIREFIGHTER', 'FIRST_AIDER']
                .contains(safetyRole)) {
          safetyRole = 'GENERAL';
        }

        if (status.isEmpty || !['ACTIVE', 'RESIGNED', 'SUSPENDED'].contains(status)) {
          status = 'ACTIVE';
        }

        final emp = Employee(
          employeeCode: empCode,
          fullName: fullName,
          department: department.isEmpty ? 'ทั่วไป' : department,
          position: position.isEmpty ? 'พนักงาน' : position,
          safetyRole: safetyRole,
          nationalId: nationalId.isEmpty ? null : nationalId,
          hireDate: hireDate.isEmpty ? null : hireDate,
          phone: phone.isEmpty ? null : phone,
          email: email.isEmpty ? null : email,
          status: status,
        );

        await repo.saveEmployee(emp);
        count++;
      }
      break; // Import first valid sheet
    }
    return count;
  }

  /// ส่งออกทะเบียนพนักงานเป็นไฟล์ Excel (.xlsx)
  static Future<String?> exportEmployeesToExcel(List<Employee> employees) async {
    final excel = Excel.createExcel();
    final sheetName = 'Employees';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    // Header
    sheet.appendRow([
      TextCellValue('รหัสพนักงาน'),
      TextCellValue('ชื่อ - นามสกุล'),
      TextCellValue('แผนก / ฝ่าย'),
      TextCellValue('ตำแหน่งงาน'),
      TextCellValue('บทบาทด้านความปลอดภัย'),
      TextCellValue('ชั่วโมงการอบรมสะสม (ชม.)'),
      TextCellValue('หลักสูตรที่ผ่านการอบรม'),
      TextCellValue('เบอร์โทรศัพท์'),
      TextCellValue('อีเมล'),
      TextCellValue('สถานะ'),
    ]);

    for (final e in employees) {
      sheet.appendRow([
        TextCellValue(e.employeeCode),
        TextCellValue(e.fullName),
        TextCellValue(e.department),
        TextCellValue(e.position),
        TextCellValue(e.safetyRoleLabel),
        DoubleCellValue(e.totalTrainingHours),
        IntCellValue(e.validTrainingCount),
        TextCellValue(e.phone ?? '-'),
        TextCellValue(e.email ?? '-'),
        TextCellValue(e.status == 'ACTIVE' ? 'ปฏิบัติงาน' : 'พ้นสภาพ'),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes == null) return null;

    final appDocDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final filename = 'SAFAPP_Employee_Directory_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final targetPath = p.join(exportDir.path, filename);
    final file = File(targetPath);
    await file.writeAsBytes(fileBytes);

    return targetPath;
  }
}
