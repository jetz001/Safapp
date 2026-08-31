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

class EmployeePage extends ConsumerStatefulWidget {
  const EmployeePage({Key? key}) : super(key: key);

  @override
  ConsumerState<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends ConsumerState<EmployeePage> {
  int _selectedTab = 0; // 0 = Employees, 1 = Training Records, 2 = Compliance, 3 = Safety Committee

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

    final employees = employeesAsync.asData?.value ?? [];
    final records = recordsAsync.asData?.value ?? [];
    final committee = committeeAsync.asData?.value ?? [];

    final totalHours = employees.fold<double>(0.0, (sum, e) => sum + e.totalTrainingHours);
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
              onExportExcel: () => _handleExportExcel(employees),
            ),
            const SizedBox(height: 20),

            // ----------------------------------------------------------------
            // 2. Stat Overview Row
            // ----------------------------------------------------------------
            _buildStatOverview(
              totalEmployees: employees.length,
              totalHours: totalHours,
              totalRecords: records.length,
              expiringCount: expiringCount,
              committeeCount: committee.length,
            ),
            const SizedBox(height: 20),

            // ----------------------------------------------------------------
            // 3. Segmented Navigation Tabs (4 Tabs)
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
                      count: employees.length,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabButton(
                      index: 1,
                      label: '🎓 ประวัติการฝึกอบรม & วุฒิบัตร',
                      count: records.length,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabButton(
                      index: 2,
                      label: '⏳ ติดตามต่ออายุ & กฎหมาย',
                      count: expiringCount,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabButton(
                      index: 3,
                      label: '🛡️ ทำเนียบ คปอ. & ทีมฉุกเฉิน',
                      count: committee.length,
                      color: const Color(0xFF6366F1),
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
              _buildEmployeesTab(employeesAsync)
            else if (_selectedTab == 1)
              _buildTrainingRecordsTab(recordsAsync)
            else if (_selectedTab == 2)
              _buildComplianceTab(recordsAsync, employees)
            else
              _buildSafetyCommitteeTab(committeeAsync),
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
  Widget _buildEmployeesTab(AsyncValue<List<Employee>> employeesAsync) {
    return employeesAsync.when(
      data: (employees) {
        if (employees.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_alt_outlined,
            title: 'ยังไม่มีข้อมูลพนักงานในระบบ',
            subtitle: 'เพิ่มข้อมูลพนักงานรายบุคคล หรือนำเข้าไฟล์ Excel ได้ทันที',
            btnLabel: 'เพิ่มพนักงานแรก',
            onAction: () => _openEmployeeDialog(),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: employees.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, idx) {
            final e = employees[idx];
            final hasPhoto = e.photoPath != null && File(e.photoPath!).existsSync();

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
          separatorBuilder: (_, __) => const SizedBox(height: 10),
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
  // TAB 4: SAFETY COMMITTEE (คปอ.) & ERT
  // ==========================================================================
  Widget _buildSafetyCommitteeTab(AsyncValue<List<SafetyCommitteeMember>> committeeAsync) {
    return committeeAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return _buildEmptyState(
            icon: Icons.groups_outlined,
            title: 'ยังไม่มีรายชื่อคณะกรรมการ คปอ. ในระบบ',
            subtitle: 'แต่งตั้งคณะกรรมการความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน (วาระ ๒ ปี ตามกฎหมาย)',
            btnLabel: 'แต่งตั้งกรรมการแรก',
            onAction: () => _openCommitteeDialog(),
          );
        }

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
              separatorBuilder: (_, __) => const SizedBox(height: 10),
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
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
    );
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
