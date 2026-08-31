import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/employee_models.dart';
import '../providers/employee_providers.dart';
import 'training_record_dialog.dart';
import 'certificate_viewer_dialog.dart';
import 'employee_form_dialog.dart';

class EmployeeProfileDialog extends ConsumerWidget {
  final Employee employee;

  const EmployeeProfileDialog({
    Key? key,
    required this.employee,
  }) : super(key: key);

  void _openTrainingDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => TrainingRecordDialog(
        preselectedEmployeeId: employee.id,
      ),
    );
  }

  void _openCertViewer(BuildContext context, TrainingRecord record) {
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
        employeeName: employee.fullName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(trainingRecordsProvider);
    final hasPhoto = employee.photoPath != null && File(employee.photoPath!).existsSync();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 800,
        height: 720,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // ----------------------------------------------------------------
            // 1. Header Banner
            // ----------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 86,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white30, width: 1.5),
                    ),
                    child: hasPhoto
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.file(File(employee.photoPath!), fit: BoxFit.cover),
                          )
                        : const Icon(Icons.person, size: 48, color: Colors.white70),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${employee.employeeCode} - ${employee.fullName}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            _buildRoleBadge(employee.safetyRole),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'แผนก: ${employee.department}  |  ตำแหน่ง: ${employee.position}',
                          style: TextStyle(fontSize: 13, color: Colors.blue.shade100),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'เลข ปชช.: ${employee.nationalId ?? "-"}  |  เริ่มงาน: ${employee.hireDate ?? "-"}  |  โทร: ${employee.phone ?? "-"}',
                          style: TextStyle(fontSize: 11.5, color: Colors.blue.shade200),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ----------------------------------------------------------------
            // 2. Summary KPI Ribbon
            // ----------------------------------------------------------------
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildKpiBox(
                      title: 'ชั่วโมงอบรมสะสม',
                      value: '${employee.totalTrainingHours.toInt()} ชั่วโมง',
                      icon: Icons.timer_outlined,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiBox(
                      title: 'หลักสูตรที่ผ่านการอบรม',
                      value: '${employee.validTrainingCount} หลักสูตร',
                      icon: Icons.verified_user_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiBox(
                      title: 'ต้องต่ออายุ/หมดอายุ',
                      value: '${employee.expiredTrainingCount} หลักสูตร',
                      icon: Icons.warning_amber_rounded,
                      color: employee.expiredTrainingCount > 0 ? const Color(0xFFEF4444) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ----------------------------------------------------------------
            // 3. Training Records List
            // ----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ประวัติการฝึกอบรมความปลอดภัย & วุฒิบัตร (Training Records)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openTrainingDialog(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('บันทึกอบรมเพิ่ม'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: recordsAsync.when(
                data: (allRecords) {
                  final empRecords = allRecords.where((r) => r.employeeId == employee.id).toList();

                  if (empRecords.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_outlined, size: 54, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text(
                            'พนักงานคนนี้ยังไม่มีประวัติการฝึกอบรม',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'กดปุ่ม "บันทึกอบรมเพิ่ม" ด้านบนเพื่อบันทึกหลักสูตรและแนบวุฒิบัตร',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: empRecords.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final r = empRecords[idx];
                      final isExp = r.status == 'EXPIRED';
                      final isSoon = r.status == 'EXPIRING_SOON';
                      final hasCert = r.certFilePath != null && r.certFilePath!.isNotEmpty;

                      Color statusBg;
                      Color statusFg;
                      String statusText;

                      if (isExp) {
                        statusBg = Colors.red.shade50;
                        statusFg = Colors.red.shade800;
                        statusText = '🔴 หมดอายุ';
                      } else if (isSoon) {
                        statusBg = Colors.amber.shade50;
                        statusFg = Colors.amber.shade900;
                        statusText = '🟡 ใกล้หมดอายุ';
                      } else if (r.status == 'VALID') {
                        statusBg = Colors.green.shade50;
                        statusFg = Colors.green.shade800;
                        statusText = '🟢 มีผลสมบูรณ์';
                      } else {
                        statusBg = Colors.blue.shade50;
                        statusFg = Colors.blue.shade800;
                        statusText = '🔵 ตลอดชีพ';
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.school_rounded, color: Color(0xFF0D9488), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          r.courseName ?? "หลักสูตรฝึกอบรม",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(4)),
                                        child: Text(statusText, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: statusFg)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
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
                            if (hasCert) ...[
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _openCertViewer(context, r),
                                icon: const Icon(Icons.visibility_rounded, size: 14),
                                label: const Text('ดูวุฒิบัตร', style: TextStyle(fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D9488),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
              ),
            ),

            // ----------------------------------------------------------------
            // 4. Footer Actions
            // ----------------------------------------------------------------
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (ctx) => EmployeeFormDialog(existingEmployee: employee),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('แก้ไขข้อมูลพนักงาน'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('ปิดหน้าต่าง'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiBox({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color fg;
    String label;

    switch (role) {
      case 'SUPERVISOR_SAFETY':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        label = '🛡️ จป.หัวหน้างาน';
        break;
      case 'EXECUTIVE_SAFETY':
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade900;
        label = '👔 จป.บริหาร';
        break;
      case 'COMMITTEE_MEMBER':
        bg = Colors.indigo.shade100;
        fg = Colors.indigo.shade900;
        label = '📋 คปอ.';
        break;
      case 'ERT_FIREFIGHTER':
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        label = '🚒 ทีม ERT';
        break;
      case 'FIRST_AIDER':
        bg = Colors.teal.shade100;
        fg = Colors.teal.shade900;
        label = '🩹 First Aid';
        break;
      case 'GENERAL':
      default:
        bg = Colors.white24;
        fg = Colors.white;
        label = '👤 พนักงานทั่วไป';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
