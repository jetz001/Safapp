import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/employee_models.dart';
import '../../services/employee_excel_service.dart';
import '../providers/employee_providers.dart';
import '../widgets/employee_form_dialog.dart';
import '../widgets/training_record_dialog.dart';
import '../widgets/committee_member_dialog.dart';
import '../widgets/certificate_viewer_dialog.dart';
import '../widgets/employee_profile_dialog.dart';
import '../../../../core/widgets/safapp_print_preview.dart';
import '../../services/employee_pdf_report_service.dart';
import '../../../risk_assessment/presentation/providers/risk_assessment_providers.dart';
import '../../../cpo/data/models/cpo_committee_model.dart';
import '../../../cpo/domain/enums/cpo_member_role.dart';
import '../../../cpo/presentation/providers/cpo_providers.dart';
import '../../../../core/constants/app_routes.dart';

class EmployeePage extends ConsumerStatefulWidget {
  final void Function(int index)? onNavigate;
  const EmployeePage({super.key, this.onNavigate});

  @override
  ConsumerState<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends ConsumerState<EmployeePage> {
  int _selectedTab = 0; // 0 = Employees, 1 = Training Records, 2 = Compliance, 3 = Safety Committee, 4 = Former Employees
  String _employeeSearchQuery = '';
  String? _employeeDeptFilter;
  bool _filterOnlyCpo = false; // Filter only CPO committee members in Tab 0
  String _resignedSearchQuery = '';
  String? _resignedDeptFilter;

  void _openEmployeeProfile(Employee employee) {
    showDialog(
      context: context,
      builder: (ctx) => EmployeeProfileDialog(employee: employee),
    );
  }

  void _openEmployeeDialog({Employee? employee}) {
    showDialog(
      context: context,
      builder: (ctx) => EmployeeFormDialog(existingEmployee: employee),
    );
  }

  void _openTrainingDialog({TrainingRecord? record, int? preselectedEmployeeId}) {
    showDialog(
      context: context,
      builder: (ctx) => TrainingRecordDialog(
        existingRecord: record,
        preselectedEmployeeId: preselectedEmployeeId,
      ),
    );
  }

  void _openCommitteeDialog({SafetyCommitteeMember? member}) {
    showDialog(
      context: context,
      builder: (ctx) => CommitteeMemberDialog(existingMember: member),
    );
  }

  CpoMemberModel? _getCpoMember(Employee e, List<CpoMemberModel> cpoMembers) {
    final eClean = e.fullName.replaceAll('นาย', '').replaceAll('นางสาว', '').replaceAll('น.ส.', '').replaceAll(' ', '').trim().toLowerCase();
    for (final m in cpoMembers) {
      if (m.employeeId != null && m.employeeId == e.id) return m;
      if (m.employeeCode != null && m.employeeCode!.isNotEmpty && m.employeeCode == e.employeeCode) return m;
      final mClean = m.fullName.replaceAll('นาย', '').replaceAll('นางสาว', '').replaceAll('น.ส.', '').replaceAll(' ', '').trim().toLowerCase();
      if (eClean == mClean || (eClean.isNotEmpty && mClean.isNotEmpty && (eClean.contains(mClean) || mClean.contains(eClean)))) {
        return m;
      }
    }
    return null;
  }

  Employee? _findEmployeeForCpoMember(CpoMemberModel m, List<Employee> allEmployees) {
    final mClean = m.fullName.replaceAll('นาย', '').replaceAll('นางสาว', '').replaceAll('น.ส.', '').replaceAll(' ', '').trim().toLowerCase();
    for (final e in allEmployees) {
      if (m.employeeId != null && m.employeeId == e.id) return e;
      if (m.employeeCode != null && m.employeeCode!.isNotEmpty && m.employeeCode == e.employeeCode) return e;
      final eClean = e.fullName.replaceAll('นาย', '').replaceAll('นางสาว', '').replaceAll('น.ส.', '').replaceAll(' ', '').trim().toLowerCase();
      if (eClean == mClean || (eClean.isNotEmpty && mClean.isNotEmpty && (eClean.contains(mClean) || mClean.contains(eClean)))) {
        return e;
      }
    }
    return null;
  }

  void _openCertViewer(TrainingRecord record) {
    if (record.certFilePath == null || record.certFilePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีไฟล์วุฒิบัตรที่แนบไว้')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => CertificateViewerDialog(
        filePath: record.certFilePath!,
        title: record.courseName ?? 'วุฒิบัตรการฝึกอบรม',
        employeeName: record.employeeName ?? '',
      ),
    );
  }

  Future<void> _handleDownloadTemplate() async {
    final path = await EmployeeExcelService.downloadTemplate();
    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึก Template Excel เรียบร้อยที่: $path'),
          backgroundColor: Colors.green.shade700,
          action: Platform.isWindows
              ? SnackBarAction(
                  label: 'เปิดโฟลเดอร์',
                  textColor: Colors.white,
                  onPressed: () {
                    Process.run('explorer.exe', ['/select,', path]);
                  },
                )
              : null,
        ),
      );
    }
  }

  Future<void> _handleImportExcel() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final repo = ref.read(employeeRepoProvider);
      final count = await EmployeeExcelService.importEmployeesFromExcel(filePath, repo);

      ref.invalidate(employeesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('นำเข้าข้อมูลพนักงานสำเร็จจำนวน $count รายการ'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    }
  }

  Future<void> _handleExportExcel(List<Employee> employees) async {
    if (employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีข้อมูลพนักงานสำหรับส่งออก')),
      );
      return;
    }

    final path = await EmployeeExcelService.exportEmployeesToExcel(employees);
    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ส่งออก Excel เรียบร้อยที่: $path'),
          backgroundColor: Colors.green.shade700,
          action: Platform.isWindows
              ? SnackBarAction(
                  label: 'เปิดโฟลเดอร์',
                  textColor: Colors.white,
                  onPressed: () {
                    Process.run('explorer.exe', ['/select,', path]);
                  },
                )
              : null,
        ),
      );
    }
  }

  Future<void> _handlePrintSummary(List<Employee> employees) async {
    if (employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีข้อมูลพนักงานสำหรับพิมพ์รายงาน')),
      );
      return;
    }
    final companyName = ref.read(companyProfileNotifierProvider).asData?.value?.companyName ?? 'สถานประกอบกิจการ';
    await SafappPrintPreview.show(
      context,
      title: 'รายงานสรุปทะเบียนพนักงานและประวัติการฝึกอบรมความปลอดภัย',
      subtitle: '$companyName • จำนวนพนักงานทั้งหมด ${employees.length} คน',
      formCode: 'แบบรายงาน OSH ทะเบียนพนักงาน',
      fileName: 'Employee_OSH_Summary_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      onLayout: (format) => EmployeePdfReportService.generateEmployeeSummaryReportPdf(
        employees: employees,
        companyName: companyName,
      ),
    );
  }

  Future<void> _handlePrintResignedSummary(List<Employee> resignedEmployees) async {
    if (resignedEmployees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีข้อมูลพนักงานเก่าสำหรับพิมพ์รายงาน')),
      );
      return;
    }
    final companyName = ref.read(companyProfileNotifierProvider).asData?.value?.companyName ?? 'สถานประกอบกิจการ';
    await SafappPrintPreview.show(
      context,
      title: 'รายงานทะเบียนประวัติพนักงานเก่าและพนักงานพ้นสภาพ',
      subtitle: '$companyName • จำนวนพนักงานพ้นสภาพ ${resignedEmployees.length} คน',
      formCode: 'แบบรายงาน OSH ทะเบียนพนักงานเก่า',
      fileName: 'Former_Employee_OSH_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      onLayout: (format) => EmployeePdfReportService.generateEmployeeSummaryReportPdf(
        employees: resignedEmployees,
        companyName: companyName,
        reportTitle: 'รายงานสรุปทะเบียนพนักงานเก่าและพนักงานพ้นสภาพ (Historical Register)',
        formCode: 'แบบรายงาน OSH ทะเบียนพนักงานเก่า',
      ),
    );
  }

  Future<void> _handleExportResignedExcel(List<Employee> resignedEmployees) async {
    if (resignedEmployees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีข้อมูลพนักงานเก่าสำหรับส่งออก')),
      );
      return;
    }
    final path = await EmployeeExcelService.exportEmployeesToExcel(
      resignedEmployees,
      fileNamePrefix: 'SAFAPP_Former_Employees',
    );
    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ส่งออก Excel ทะเบียนพนักงานเก่าเรียบร้อยที่: $path'),
          backgroundColor: Colors.green.shade700,
          action: Platform.isWindows
              ? SnackBarAction(
                  label: 'เปิดโฟลเดอร์',
                  textColor: Colors.white,
                  onPressed: () {
                    Process.run('explorer.exe', ['/select,', path]);
                  },
                )
              : null,
        ),
      );
    }
  }

  Future<void> _deleteEmployee(Employee emp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบข้อมูลพนักงาน'),
        content: Text('ต้องการลบพนักงาน "${emp.employeeCode} - ${emp.fullName}" และประวัติการฝึกอบรมทั้งหมดใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true && emp.id != null) {
      await ref.read(employeesProvider.notifier).deleteEmployee(emp.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบข้อมูลพนักงานเรียบร้อยแล้ว')),
        );
      }
    }
  }

  Future<void> _deleteRecord(TrainingRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบประวัติการอบรม'),
        content: Text('ต้องการลบประวัติการอบรม "${record.courseName}" ของ ${record.employeeName} ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true && record.id != null) {
      await ref.read(trainingRecordsProvider.notifier).deleteRecord(record.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบประวัติการฝึกอบรมเรียบร้อยแล้ว')),
        );
      }
    }
  }

  Future<void> _deleteCommitteeMember(SafetyCommitteeMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการถอนรายชื่อ คปอ.'),
        content: Text('ต้องการถอดถอน "${member.employeeName}" ออกจากตำแหน่ง คปอ. ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ถอนรายชื่อ'),
          ),
        ],
      ),
    );

    if (confirm == true && member.id != null) {
      await ref.read(safetyCommitteeProvider.notifier).deleteMember(member.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ถอนรายชื่อ คปอ. เรียบร้อยแล้ว')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);
    final recordsAsync = ref.watch(trainingRecordsProvider);
    final committeeAsync = ref.watch(safetyCommitteeProvider);

    // Live statutory CPO data from CPO module
    final cpoTerms = ref.watch(cpoAllTermsProvider).asData?.value ?? [];
    final activeCpoTerm = ref.watch(cpoActiveTermProvider).asData?.value ??
        (cpoTerms.where((t) => t.status == 'ACTIVE').isNotEmpty
            ? cpoTerms.firstWhere((t) => t.status == 'ACTIVE')
            : (cpoTerms.isNotEmpty ? cpoTerms.first : null));
    final cpoMembers = activeCpoTerm?.members ??
        (cpoTerms.isNotEmpty ? cpoTerms.expand((t) => t.members).toList() : <CpoMemberModel>[]);
    final legacyCommittee = committeeAsync.asData?.value ?? [];
    final totalCpoCount = cpoMembers.isNotEmpty ? cpoMembers.length : legacyCommittee.length;

    final allEmployees = employeesAsync.asData?.value ?? [];
    final activeEmployees = allEmployees.where((e) => e.status != 'RESIGNED').toList();
    final resignedEmployees = allEmployees.where((e) => e.status == 'RESIGNED').toList();
    final records = recordsAsync.asData?.value ?? [];

    final totalHours = activeEmployees.fold<double>(0.0, (sum, e) => sum + e.totalTrainingHours);
    final expiringCount = records.where((r) => r.status == 'EXPIRING_SOON' || r.status == 'EXPIRED').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------------------
            // 1. Header Banner & Action Bar
            // ----------------------------------------------------------------
            _buildHeaderBanner(
              onAddEmployee: () => _openEmployeeDialog(),
              onAddTraining: () => _openTrainingDialog(),
              onImportExcel: _handleImportExcel,
              onDownloadTemplate: _handleDownloadTemplate,
              onExportExcel: () => _handleExportExcel(activeEmployees),
              onPrintSummary: () => _handlePrintSummary(activeEmployees),
            ),
            const SizedBox(height: 20),

            // ----------------------------------------------------------------
            // 2. Stat Overview Row
            // ----------------------------------------------------------------
            _buildStatOverview(
              totalEmployees: activeEmployees.length,
              totalHours: totalHours,
              totalRecords: records.length,
              expiringCount: expiringCount,
              committeeCount: totalCpoCount,
            ),
            const SizedBox(height: 20),

            // ----------------------------------------------------------------
            // 3. Segmented Navigation Tabs (5 Tabs)
            // ----------------------------------------------------------------
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      index: 0,
                      label: '👥 ทะเบียนพนักงาน',
                      count: activeEmployees.length,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabButton(
                      index: 1,
                      label: '🎓 ประวัติฝึกอบรม',
                      count: records.length,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabButton(
                      index: 2,
                      label: '⏳ ติดตามต่ออายุ',
                      count: expiringCount,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabButton(
                      index: 3,
                      label: '🛡️ ทำเนียบ คปอ.',
                      count: totalCpoCount,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabButton(
                      index: 4,
                      label: '📁 ทะเบียนพนักงานเก่า',
                      count: resignedEmployees.length,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ----------------------------------------------------------------
            // 4. TAB CONTENTS
            // ----------------------------------------------------------------
            if (_selectedTab == 0)
              _buildEmployeesTab(employeesAsync, cpoMembers: cpoMembers)
            else if (_selectedTab == 1)
              _buildTrainingRecordsTab(recordsAsync)
            else if (_selectedTab == 2)
              _buildComplianceTab(recordsAsync, activeEmployees)
            else if (_selectedTab == 3)
              _buildSafetyCommitteeTab(
                cpoTerm: activeCpoTerm,
                cpoMembers: cpoMembers,
                allEmployees: allEmployees,
                legacyCommitteeAsync: committeeAsync,
              )
            else
              _buildResignedEmployeesTab(employeesAsync),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // HEADER BANNER WIDGET
  // ==========================================================================
  Widget _buildHeaderBanner({
    required VoidCallback onAddEmployee,
    required VoidCallback onAddTraining,
    required VoidCallback onImportExcel,
    required VoidCallback onDownloadTemplate,
    required VoidCallback onExportExcel,
    required VoidCallback onPrintSummary,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E3A8A).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.badge_rounded, color: Colors.amber, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ระบบบริหารจัดการทะเบียนพนักงานและการฝึกอบรมความปลอดภัย',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'ทะเบียนพนักงาน, บันทึกการฝึกอบรมตามกฎหมายความปลอดภัยฯ ๒๕๕๔, ติดตามวันหมดอายุ และทำเนียบ คปอ. (วาระ ๒ ปี)',
                  style: TextStyle(color: Colors.blue.shade100, fontSize: 12),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: const Text('Template Excel'),
                onPressed: onDownloadTemplate,
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: const Text('Import Excel'),
                onPressed: onImportExcel,
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.print_rounded, size: 16),
                label: const Text('พิมพ์รายงานสรุป (PDF)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: onPrintSummary,
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.school_rounded, size: 16),
                label: const Text('บันทึกอบรม'),
                onPressed: onAddTraining,
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade500,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('เพิ่มพนักงาน', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: onAddEmployee,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // STAT OVERVIEW ROW
  // ==========================================================================
  Widget _buildStatOverview({
    required int totalEmployees,
    required double totalHours,
    required int totalRecords,
    required int expiringCount,
    required int committeeCount,
  }) {
    final items = [
      _StatCardItem('พนักงานในระบบ', '$totalEmployees คน', Icons.people_alt_rounded, const Color(0xFF3B82F6)),
      _StatCardItem('ชั่วโมงอบรมสะสม', '${totalHours.toInt()} ชม.', Icons.timer_outlined, const Color(0xFF0D9488)),
      _StatCardItem('ประวัติการอบรม', '$totalRecords รายการ', Icons.school_rounded, const Color(0xFF10B981)),
      _StatCardItem('ต้องต่ออายุ/หมดอายุ', '$expiringCount รายการ', Icons.warning_amber_rounded, const Color(0xFFF59E0B)),
      _StatCardItem('กรรมการ คปอ.', '$committeeCount คน', Icons.groups_rounded, const Color(0xFF6366F1)),
    ];

    return Row(
      children: items
          .map(
            (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == items.last ? 0 : 12.0),
                child: _buildStatCard(i),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStatCard(_StatCardItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(item.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required int count,
    required Color color,
  }) {
    final isSelected = _selectedTab == index;

    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 1: EMPLOYEE DIRECTORY
  // ==========================================================================
  Widget _buildEmployeesTab(AsyncValue<List<Employee>> employeesAsync, {required List<CpoMemberModel> cpoMembers}) {
    return employeesAsync.when(
      data: (allEmployees) {
        final activeEmployees = allEmployees.where((e) => e.status != 'RESIGNED').toList();

        if (activeEmployees.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_alt_outlined,
            title: 'ยังไม่มีข้อมูลพนักงานปฏิบัติงานในระบบ',
            subtitle: 'เพิ่มข้อมูลพนักงานรายบุคคล หรือนำเข้าไฟล์ Excel ได้ทันที',
            btnLabel: 'เพิ่มพนักงานแรก',
            onAction: () => _openEmployeeDialog(),
          );
        }

        // Count active employees who are recognized as CPO committee members
        final cpoActiveEmployeesCount = activeEmployees.where((e) =>
          _getCpoMember(e, cpoMembers) != null || e.safetyRole == 'COMMITTEE_MEMBER'
        ).length;

        // Filter active employees by CPO filter, search query, and department
        var displayed = activeEmployees;
        if (_filterOnlyCpo) {
          displayed = displayed.where((e) =>
            _getCpoMember(e, cpoMembers) != null || e.safetyRole == 'COMMITTEE_MEMBER'
          ).toList();
        }
        if (_employeeSearchQuery.trim().isNotEmpty) {
          final q = _employeeSearchQuery.trim().toLowerCase();
          displayed = displayed.where((e) =>
            e.employeeCode.toLowerCase().contains(q) ||
            e.fullName.toLowerCase().contains(q) ||
            e.department.toLowerCase().contains(q) ||
            e.position.toLowerCase().contains(q) ||
            (e.phone ?? '').contains(q)
          ).toList();
        }
        if (_employeeDeptFilter != null && _employeeDeptFilter != 'ALL') {
          displayed = displayed.where((e) => e.department == _employeeDeptFilter).toList();
        }

        final departments = activeEmployees.map((e) => e.department).toSet().toList()..sort();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search & Filter Toolbar for Active Employees
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'ค้นหาด้วยรหัสพนักงาน, ชื่อ-นามสกุล, แผนก, ตำแหน่ง, เบอร์โทร...',
                        hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                        suffixIcon: _employeeSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setState(() => _employeeSearchQuery = ''),
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      onChanged: (val) => setState(() => _employeeSearchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // CPO Committee Filter Chip
                  FilterChip(
                    selected: _filterOnlyCpo,
                    showCheckmark: true,
                    checkmarkColor: Colors.white,
                    avatar: !_filterOnlyCpo ? const Icon(Icons.shield_rounded, size: 16, color: Color(0xFF6366F1)) : null,
                    label: Text(
                      'เฉพาะกรรมการ คปอ. ($cpoActiveEmployeesCount)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _filterOnlyCpo ? FontWeight.bold : FontWeight.normal,
                        color: _filterOnlyCpo ? Colors.white : const Color(0xFF4338CA),
                      ),
                    ),
                    backgroundColor: const Color(0xFFEEF2FF),
                    selectedColor: const Color(0xFF6366F1),
                    side: BorderSide(
                      color: _filterOnlyCpo ? const Color(0xFF6366F1) : const Color(0xFFC7D2FE),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onSelected: (val) => setState(() => _filterOnlyCpo = val),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _employeeDeptFilter ?? 'ALL',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                        items: [
                          const DropdownMenuItem(value: 'ALL', child: Text('ทุกแผนก / ฝ่าย')),
                          ...departments.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                        ],
                        onChanged: (v) => setState(() => _employeeDeptFilter = v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: const Text('เพิ่มพนักงาน'),
                    onPressed: () => _openEmployeeDialog(),
                  ),
                ],
              ),
            ),
            if (_filterOnlyCpo) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: Color(0xFF6366F1), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'กำลังกรองเฉพาะพนักงานที่เป็นกรรมการความปลอดภัยฯ (คปอ.) ที่เชื่อมโยงกับโมดูล คปอ. (พบ ${displayed.length} คน)',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF3730A3)),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4338CA),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('ล้างตัวกรอง คปอ.', style: TextStyle(fontSize: 12)),
                      onPressed: () => setState(() => _filterOnlyCpo = false),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            if (displayed.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text('ไม่พบข้อมูลพนักงานที่ค้นหา', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569))),
                    const SizedBox(height: 4),
                    Text(
                      _filterOnlyCpo
                          ? 'ไม่พบพนักงานในระบบที่ตรงกับรายชื่อกรรมการ คปอ.'
                          : 'ลองเปลี่ยนคำค้นหาหรือตัวกรองแผนก',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayed.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final e = displayed[idx];
                  final hasPhoto = e.photoPath != null && File(e.photoPath!).existsSync();
                  final cpoMember = _getCpoMember(e, cpoMembers);

                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openEmployeeProfile(e),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // Photo / Avatar
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: hasPhoto
                                  ? ClipOval(child: Image.file(File(e.photoPath!), fit: BoxFit.cover))
                                  : const Icon(Icons.person, color: Colors.grey, size: 30),
                            ),
                            const SizedBox(width: 14),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${e.employeeCode} - ${e.fullName}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(e.department, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildSafetyRoleBadge(e.safetyRole),
                                      if (cpoMember != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF2FF),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFF818CF8)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.shield_rounded, size: 12, color: Color(0xFF4F46E5)),
                                              const SizedBox(width: 4),
                                              Text(
                                                'คปอ. (${cpoMember.cpoRole.labelTh})',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (e.status == 'SUSPENDED') ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.amber.shade300),
                                          ),
                                          child: Text('🟡 พักงาน', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ตำแหน่ง: ${e.position}  |  เบอร์โทร: ${e.phone ?? "-"}  |  อีเมล: ${e.email ?? "-"}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.teal.shade200),
                                        ),
                                        child: Text(
                                          'ชั่วโมงอบรมสะสม: ${e.totalTrainingHours.toInt()} ชม. (${e.validTrainingCount} หลักสูตร)',
                                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                                        ),
                                      ),
                                      if (e.expiredTrainingCount > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.red.shade200),
                                          ),
                                          child: Text(
                                            'ต้องต่ออายุ ${e.expiredTrainingCount} หลักสูตร',
                                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Actions
                            Wrap(
                              spacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _openEmployeeProfile(e),
                                  icon: const Icon(Icons.badge_rounded, size: 16),
                                  label: const Text('ดูประวัติ'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _openTrainingDialog(preselectedEmployeeId: e.id),
                                  icon: const Icon(Icons.school_rounded, size: 16),
                                  label: const Text('บันทึกอบรม'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0D9488),
                                    side: const BorderSide(color: Color(0xFF0D9488)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (val) {
                                    if (val == 'profile') {
                                      _openEmployeeProfile(e);
                                    } else if (val == 'edit') {
                                      _openEmployeeDialog(employee: e);
                                    } else if (val == 'delete') {
                                      _deleteEmployee(e);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(value: 'profile', child: Text('ดูประวัติพนักงาน & การอบรม')),
                                    const PopupMenuItem(value: 'edit', child: Text('แก้ไขข้อมูลพนักงาน')),
                                    const PopupMenuItem(value: 'delete', child: Text('ลบพนักงานนี้', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
    );
  }

  // ==========================================================================
  // TAB 5: FORMER / RESIGNED EMPLOYEES REGISTER (ทะเบียนพนักงานเก่า)
  // ==========================================================================
  Widget _buildResignedEmployeesTab(AsyncValue<List<Employee>> employeesAsync) {
    return employeesAsync.when(
      data: (allEmployees) {
        final resigned = allEmployees.where((e) => e.status == 'RESIGNED').toList();

        if (resigned.isEmpty) {
          return _buildEmptyState(
            icon: Icons.assignment_ind_outlined,
            title: 'ไม่มีพนักงานที่พ้นสภาพหรือลาออก',
            subtitle: 'พนักงานทุกคนในระบบขณะนี้อยู่ในสถานะปฏิบัติงานปกติ หากมีการเปลี่ยนสถานะเป็น "พ้นสภาพ / ลาออก" รายชื่อจะถูกแยกมาแสดงที่นี่โดยอัตโนมัติ',
            btnLabel: 'ดูทะเบียนพนักงานปัจจุบัน',
            onAction: () => setState(() => _selectedTab = 0),
          );
        }

        // Filter by search & dept
        var displayed = resigned;
        if (_resignedSearchQuery.trim().isNotEmpty) {
          final q = _resignedSearchQuery.trim().toLowerCase();
          displayed = displayed.where((e) =>
            e.employeeCode.toLowerCase().contains(q) ||
            e.fullName.toLowerCase().contains(q) ||
            e.department.toLowerCase().contains(q) ||
            e.position.toLowerCase().contains(q) ||
            (e.phone ?? '').contains(q)
          ).toList();
        }
        if (_resignedDeptFilter != null && _resignedDeptFilter != 'ALL') {
          displayed = displayed.where((e) => e.department == _resignedDeptFilter).toList();
        }

        final departments = resigned.map((e) => e.department).toSet().toList()..sort();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notice banner for Former Employees
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF475569).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.archive_outlined, color: Color(0xFF475569), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ทำเนียบประวัติพนักงานเก่าและพนักงานพ้นสภาพ (Former Employees Register)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'จัดเก็บประวัติการทำงาน การฝึกอบรมความปลอดภัย และสมุดสุขภาพของพนักงานที่ลาออกหรือพ้นสภาพ เพื่อความสมบูรณ์ของบันทึกประวัติย้อนหลังตามกฎหมาย (พ้นสภาพแล้ว ${resigned.length} คน)',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFF94A3B8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Export Excel'),
                        onPressed: () => _handleExportResignedExcel(resigned),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF475569),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: const Text('พิมพ์รายงานพนักงานเก่า'),
                        onPressed: () => _handlePrintResignedSummary(resigned),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Search & Filter Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'ค้นหาด้วยรหัสพนักงาน, ชื่อ-นามสกุล, ตำแหน่งเดิม, เบอร์โทร...',
                        hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                        suffixIcon: _resignedSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setState(() => _resignedSearchQuery = ''),
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      onChanged: (val) => setState(() => _resignedSearchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _resignedDeptFilter ?? 'ALL',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                        items: [
                          const DropdownMenuItem(value: 'ALL', child: Text('ทุกแผนก / ฝ่าย')),
                          ...departments.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                        ],
                        onChanged: (v) => setState(() => _resignedDeptFilter = v),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (displayed.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text('ไม่พบข้อมูลพนักงานเก่าที่ค้นหา', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569))),
                    const SizedBox(height: 4),
                    Text('ลองเปลี่ยนคำค้นหาหรือตัวกรองแผนก', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayed.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final e = displayed[idx];
                  final hasPhoto = e.photoPath != null && File(e.photoPath!).existsSync();

                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    color: Colors.white,
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          // Photo with resigned indicator
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: hasPhoto
                                ? ClipOval(
                                    child: ColorFiltered(
                                      colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                                      child: Image.file(File(e.photoPath!), fit: BoxFit.cover),
                                    ),
                                  )
                                : const Icon(Icons.person_off_rounded, color: Colors.grey, size: 28),
                          ),
                          const SizedBox(width: 14),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${e.employeeCode} - ${e.fullName}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF334155)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.person_off_rounded, size: 11, color: Colors.red.shade800),
                                          const SizedBox(width: 4),
                                          Text('พ้นสภาพ / ลาออก', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(e.department, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildSafetyRoleBadge(e.safetyRole),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ตำแหน่งเดิม: ${e.position}  |  วันเริ่มงาน: ${e.hireDate ?? "-"}  |  เบอร์โทร: ${e.phone ?? "-"}  |  อีเมล: ${e.email ?? "-"}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.blueGrey.shade200),
                                      ),
                                      child: Text(
                                        'ประวัติอบรมสะสม: ${e.totalTrainingHours.toInt()} ชม. (${e.validTrainingCount} หลักสูตร)',
                                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Actions
                          Wrap(
                            spacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _openEmployeeProfile(e),
                                icon: const Icon(Icons.history_rounded, size: 16),
                                label: const Text('ดูประวัติ'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF475569),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _openEmployeeDialog(employee: e),
                                icon: const Icon(Icons.settings_backup_restore_rounded, size: 16),
                                label: const Text('แก้ไข / คืนสถานะ'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1E3A8A),
                                  side: const BorderSide(color: Color(0xFF1E3A8A)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (val) {
                                  if (val == 'profile') {
                                    _openEmployeeProfile(e);
                                  } else if (val == 'edit') {
                                    _openEmployeeDialog(employee: e);
                                  } else if (val == 'delete') {
                                    _deleteEmployee(e);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'profile', child: Text('ดูประวัติพนักงาน & การอบรม')),
                                  const PopupMenuItem(value: 'edit', child: Text('แก้ไขข้อมูล / คืนสถานะ')),
                                  const PopupMenuItem(value: 'delete', child: Text('ลบพนักงานนี้ถาวร', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
    );
  }

  // ==========================================================================
  // TAB 2: TRAINING RECORDS & CERTIFICATES
  // ==========================================================================
  Widget _buildTrainingRecordsTab(AsyncValue<List<TrainingRecord>> recordsAsync) {
    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return _buildEmptyState(
            icon: Icons.school_outlined,
            title: 'ยังไม่มีประวัติการฝึกอบรมในระบบ',
            subtitle: 'บันทึกประวัติการฝึกอบรมหลักสูตรตามกฎหมาย พร้อมแนบไฟล์วุฒิบัตร',
            btnLabel: 'บันทึกการอบรมแรก',
            onAction: () => _openTrainingDialog(),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (ctx, idx) {
            final r = records[idx];
            final hasCert = r.certFilePath != null && r.certFilePath!.isNotEmpty;
            final isExp = r.status == 'EXPIRED';
            final isSoon = r.status == 'EXPIRING_SOON';

            Color statusBg;
            Color statusFg;
            String statusText;

            if (isExp) {
              statusBg = Colors.red.shade50;
              statusFg = Colors.red.shade800;
              statusText = '🔴 หมดอายุ / ต้องต่ออายุ';
            } else if (isSoon) {
              statusBg = Colors.amber.shade50;
              statusFg = Colors.amber.shade900;
              statusText = '🟡 ใกล้หมดอายุ (30 วัน)';
            } else if (r.status == 'VALID') {
              statusBg = Colors.green.shade50;
              statusFg = Colors.green.shade800;
              statusText = '🟢 การรับรองมีผลสมบูรณ์';
            } else {
              statusBg = Colors.blue.shade50;
              statusFg = Colors.blue.shade800;
              statusText = '🔵 ไม่ระบุวันหมดอายุ';
            }

            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified_rounded, color: Color(0xFF0D9488), size: 24),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                r.courseName ?? "หลักสูตรฝึกอบรม",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                                child: Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusFg)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'ผู้เข้ารับการอบรม: ${r.employeeCode} - ${r.employeeName} (${r.department})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'วันที่อบรม: ${r.trainingDate} (${r.durationHours.toInt()} ชม.)  |  วันหมดอายุ: ${r.expiryDate ?? "-"}  |  สถาบัน: ${r.organizerName ?? "-"}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          if (r.certNumber != null && r.certNumber!.isNotEmpty)
                            Text(
                              'เลขที่วุฒิบัตร: ${r.certNumber}',
                              style: TextStyle(fontSize: 10.5, color: Colors.blueGrey.shade700),
                            ),
                        ],
                      ),
                    ),

                    Wrap(
                      spacing: 8,
                      children: [
                        if (hasCert)
                          ElevatedButton.icon(
                            onPressed: () => _openCertViewer(r),
                            icon: const Icon(Icons.visibility_rounded, size: 16),
                            label: const Text('ดูวุฒิบัตร'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (val) {
                            if (val == 'edit') {
                              _openTrainingDialog(record: r);
                            } else if (val == 'delete') {
                              _deleteRecord(r);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'edit', child: Text('แก้ไขประวัติการอบรม')),
                            const PopupMenuItem(value: 'delete', child: Text('ลบประวัตินี้', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
    );
  }

  // ==========================================================================
  // TAB 3: COMPLIANCE & EXPIRING ALERTS
  // ==========================================================================
  Widget _buildComplianceTab(AsyncValue<List<TrainingRecord>> recordsAsync, List<Employee> employees) {
    return recordsAsync.when(
      data: (records) {
        final expiredList = records.where((r) => r.status == 'EXPIRED').toList();
        final expiringSoonList = records.where((r) => r.status == 'EXPIRING_SOON').toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legal Compliance Summary Cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.gavel_rounded, color: Color(0xFF1E3A8A), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'ข้อกำหนดกฎหมายความปลอดภัยในการฝึกอบรม (พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  _buildComplianceRow('อบรมลูกจ้างเข้าใหม่ / เปลี่ยนงาน (6 ชม.)', 'มาตรา ๑๖', 'บังคับลูกจ้างทุกคน 100%'),
                  _buildComplianceRow('ฝึกซ้อมดับเพลิงและอพยพหนีไฟประจำปี', 'กฎกระทรวงอัคคีภัย', 'ไม่น้อยกว่า 40% ของพนักงานต่อปี'),
                  _buildComplianceRow('การอบรม คปอ. / จป.หัวหน้างาน / จป.บริหาร', 'กฎกระทรวง จป.', 'ภายใน 30 วันนับแต่วันแต่งตั้ง'),
                  _buildComplianceRow('งานที่อับอากาศ / ทำงานบนที่สูง / รถยก / ปั้นจั่น', 'งานเสี่ยงเฉพาะด้าน', 'ต้องมีใบรับรองและทบทวนตามกำหนด'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (expiredList.isEmpty && expiringSoonList.isEmpty)
              _buildEmptyState(
                icon: Icons.verified_rounded,
                title: 'ไม่มีหลักสูตรที่หมดอายุหรือใกล้หมดอายุ',
                subtitle: 'พนักงานทุกคนได้รับการฝึกอบรมถูกต้องและครบถ้วนตามรอบเวลา (100% Compliance)',
                btnLabel: 'บันทึกการอบรมเพิ่ม',
                onAction: () => _openTrainingDialog(),
              )
            else ...[
              if (expiredList.isNotEmpty) ...[
                _buildSectionHeader('🔴 รายการที่หมดอายุแล้ว (ต้องดำเนินการฝึกอบรมทบทวนทันที) - ${expiredList.length} รายการ'),
                const SizedBox(height: 8),
                ...expiredList.map((r) => _buildExpiringCard(r, isExpired: true)),
                const SizedBox(height: 16),
              ],
              if (expiringSoonList.isNotEmpty) ...[
                _buildSectionHeader('🟡 รายการที่ใกล้หมดอายุใน 30 วัน (เตรียมจัดอบรมต่ออายุ) - ${expiringSoonList.length} รายการ'),
                const SizedBox(height: 8),
                ...expiringSoonList.map((r) => _buildExpiringCard(r, isExpired: false)),
              ],
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
    );
  }

  Widget _buildExpiringCard(TrainingRecord r, {required bool isExpired}) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              isExpired ? Icons.cancel_rounded : Icons.warning_amber_rounded,
              color: isExpired ? Colors.red.shade700 : Colors.amber.shade800,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.courseName ?? "หลักสูตร",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    'พนักงาน: ${r.employeeCode} - ${r.employeeName} (${r.department})  |  วันหมดอายุ: ${r.expiryDate}',
                    style: TextStyle(fontSize: 11, color: isExpired ? Colors.red.shade800 : Colors.amber.shade900),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _openTrainingDialog(preselectedEmployeeId: r.employeeId),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('บันทึกต่ออายุ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isExpired ? Colors.red.shade700 : Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceRow(String title, String legal, String requirement) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text(legal, style: TextStyle(fontSize: 11, color: Colors.grey.shade600))),
          Expanded(flex: 2, child: Text(requirement, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)))),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 4: SAFETY COMMITTEE (คปอ.) - CONNECTED WITH CPO MODULE
  // ==========================================================================
  Widget _buildSafetyCommitteeTab({
    required CpoTermModel? cpoTerm,
    required List<CpoMemberModel> cpoMembers,
    required List<Employee> allEmployees,
    required AsyncValue<List<SafetyCommitteeMember>> legacyCommitteeAsync,
  }) {
    // If no CPO module members, check if legacy safety_committees has any
    if (cpoMembers.isEmpty) {
      final legacy = legacyCommitteeAsync.asData?.value ?? [];
      if (legacy.isNotEmpty) {
        return _buildLegacyCommitteeList(legacy);
      }

      return _buildEmptyState(
        icon: Icons.shield_outlined,
        title: 'ยังไม่มีรายชื่อคณะกรรมการ คปอ. ในระบบ',
        subtitle: 'แต่งตั้งหรือบันทึกผลการเลือกตั้งคณะกรรมการ คปอ. ผ่านโมดูล คปอ. (วาระ ๒ ปี ตามกฎหมาย)',
        btnLabel: 'เปิดโมดูล คปอ. เพื่อจัดการ',
        onAction: () => widget.onNavigate?.call(AppRoutes.cpo),
      );
    }

    // Sort CPO members by role priority: chair -> employerRep -> employeeRep -> secretary
    final sortedMembers = [...cpoMembers]..sort((a, b) {
      final orderA = _rolePriority(a.cpoRole);
      final orderB = _rolePriority(b.cpoRole);
      return orderA.compareTo(orderB);
    });

    final quota = cpoTerm?.requiredQuota ?? 5;
    final isCompliant = sortedMembers.length >= quota;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statutory Header Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4338CA).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.amber, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            cpoTerm?.termTitle ?? 'คณะกรรมการความปลอดภัย อาชีวอนามัยฯ (คปอ.)',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: isCompliant ? const Color(0xFF10B981) : Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isCompliant ? '✓ ครบตามเกณฑ์ ($quota คน)' : '⚠ ขาดอีก ${quota - sortedMembers.length} คน ($quota คน)',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'วาระ: ${cpoTerm?.startDate ?? "-"} ถึง ${cpoTerm?.endDate ?? "-"}  •  คงเหลือ: ${cpoTerm?.remainingDays ?? 0} วัน  •  เชื่อมโยงข้อมูลจากโมดูล คปอ. ตามกฎกระทรวง ๒๕๖๕',
                      style: TextStyle(color: Colors.indigo.shade100, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4338CA),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('เปิดโมดูล คปอ. จัดการเต็มรูปแบบ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    onPressed: () => widget.onNavigate?.call(AppRoutes.cpo),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section Title & Quick Info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'รายชื่อคณะกรรมการ คปอ. ทั้งหมด (${sortedMembers.length} คน)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
            ),
            Text(
              'นายจ้าง: ${cpoTerm?.employerRepCount ?? 2} คน • ลูกจ้าง: ${cpoTerm?.employeeRepCount ?? 2} คน • เลขานุการ: ${cpoTerm?.secretaryCount ?? 1} คน',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // CPO Member Cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedMembers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (ctx, idx) {
            final m = sortedMembers[idx];
            final emp = _findEmployeeForCpoMember(m, allEmployees);
            final hasPhoto = emp?.photoPath != null && File(emp!.photoPath!).existsSync();

            final roleBadgeStyle = _getCpoRoleBadgeStyle(m.cpoRole);

            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: roleBadgeStyle.borderColor.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Avatar / Photo
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: roleBadgeStyle.bgColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: roleBadgeStyle.borderColor, width: 2),
                      ),
                      child: hasPhoto
                          ? ClipOval(child: Image.file(File(emp.photoPath!), fit: BoxFit.cover))
                          : Center(
                              child: Icon(
                                _getCpoRoleIcon(m.cpoRole),
                                color: roleBadgeStyle.textColor,
                                size: 26,
                              ),
                            ),
                    ),
                    const SizedBox(width: 14),

                    // Information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                m.fullName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                              ),
                              if (m.employeeCode != null && m.employeeCode!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(m.employeeCode!, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: roleBadgeStyle.bgColor,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: roleBadgeStyle.borderColor),
                                ),
                                child: Text(
                                  m.cpoRole.labelTh,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleBadgeStyle.textColor),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: m.appointmentType == 'ELECTED' ? Colors.purple.shade50 : Colors.blueGrey.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  m.appointmentType == 'ELECTED' ? '🗳️ ได้รับเลือกตั้ง (${m.votesReceived} เสียง)' : '📋 แต่งตั้งโดยนายจ้าง',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: m.appointmentType == 'ELECTED' ? Colors.purple.shade800 : Colors.blueGrey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ตำแหน่งในองค์กร: ${m.companyPosition ?? emp?.position ?? "-"}  |  สังกัด/ฝ่าย: ${m.department ?? emp?.department ?? "-"}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'เบอร์โทร: ${m.phone ?? emp?.phone ?? "-"}  |  อีเมล: ${m.email ?? emp?.email ?? "-"}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    Wrap(
                      spacing: 8,
                      children: [
                        if (emp != null)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.badge_rounded, size: 15),
                            label: const Text('ดูประวัติพนักงาน', style: TextStyle(fontSize: 12)),
                            onPressed: () => _openEmployeeProfile(emp),
                          ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4338CA),
                            side: const BorderSide(color: Color(0xFFC7D2FE)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: const Text('โมดูล คปอ.', style: TextStyle(fontSize: 12)),
                          onPressed: () => widget.onNavigate?.call(AppRoutes.cpo),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegacyCommitteeList(List<SafetyCommitteeMember> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ทำเนียบคณะกรรมการความปลอดภัยฯ (คปอ.) ประจำสถานประกอบการ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
            ),
            ElevatedButton.icon(
              onPressed: () => _openCommitteeDialog(),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: const Text('แต่งตั้งกรรมการเพิ่ม'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: members.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (ctx, idx) {
            final m = members[idx];
            final hasPhoto = m.photoPath != null && File(m.photoPath!).existsSync();
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: hasPhoto
                          ? ClipOval(child: Image.file(File(m.photoPath!), fit: BoxFit.cover))
                          : const Icon(Icons.person, color: Colors.grey, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${m.employeeCode} - ${m.employeeName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(m.positionLabel, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'สังกัด: ${m.department} (${m.position})  |  วาระ: ${m.termYear}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'วันที่แต่งตั้ง: ${m.appointedDate ?? "-"}  |  สิ้นสุดวาระ: ${m.termEndDate ?? "-"}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                      tooltip: 'ถอนรายชื่อ คปอ.',
                      onPressed: () => _deleteCommitteeMember(m),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  int _rolePriority(CpoMemberRole role) {
    switch (role) {
      case CpoMemberRole.chair:
        return 1;
      case CpoMemberRole.employerRep:
        return 2;
      case CpoMemberRole.employeeRep:
        return 3;
      case CpoMemberRole.secretary:
        return 4;
    }
  }

  IconData _getCpoRoleIcon(CpoMemberRole role) {
    switch (role) {
      case CpoMemberRole.chair:
        return Icons.military_tech_rounded;
      case CpoMemberRole.employerRep:
        return Icons.business_center_rounded;
      case CpoMemberRole.employeeRep:
        return Icons.how_to_vote_rounded;
      case CpoMemberRole.secretary:
        return Icons.assignment_ind_rounded;
    }
  }

  ({Color bgColor, Color borderColor, Color textColor}) _getCpoRoleBadgeStyle(CpoMemberRole role) {
    switch (role) {
      case CpoMemberRole.chair:
        return (bgColor: const Color(0xFFFEF3C7), borderColor: const Color(0xFFF59E0B), textColor: const Color(0xFFB45309));
      case CpoMemberRole.employerRep:
        return (bgColor: const Color(0xFFEFF6FF), borderColor: const Color(0xFF3B82F6), textColor: const Color(0xFF1D4ED8));
      case CpoMemberRole.employeeRep:
        return (bgColor: const Color(0xFFECFDF5), borderColor: const Color(0xFF10B981), textColor: const Color(0xFF047857));
      case CpoMemberRole.secretary:
        return (bgColor: const Color(0xFFEEF2FF), borderColor: const Color(0xFF6366F1), textColor: const Color(0xFF4338CA));
    }
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String btnLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(btnLabel),
            onPressed: onAction,
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyRoleBadge(String role) {
    Color bg;
    Color fg;
    String label;

    switch (role) {
      case 'SUPERVISOR_SAFETY':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade900;
        label = '🛡️ จป.หัวหน้างาน';
        break;
      case 'EXECUTIVE_SAFETY':
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade900;
        label = '👔 จป.บริหาร';
        break;
      case 'COMMITTEE_MEMBER':
        bg = Colors.indigo.shade50;
        fg = Colors.indigo.shade900;
        label = '📋 คปอ.';
        break;
      case 'ERT_FIREFIGHTER':
        bg = Colors.red.shade50;
        fg = Colors.red.shade900;
        label = '🚒 ทีม ERT';
        break;
      case 'FIRST_AIDER':
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade900;
        label = '🩹 First Aid';
        break;
      case 'GENERAL':
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
        label = '👤 พนักงานทั่วไป';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
      ),
    );
  }
}

class _StatCardItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatCardItem(this.title, this.value, this.icon, this.color);
}
