import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/employee_models.dart';
import '../providers/employee_providers.dart';
import 'training_record_dialog.dart';
import 'certificate_viewer_dialog.dart';
import 'employee_form_dialog.dart';
import '../../../health_hygiene/presentation/providers/health_providers.dart';
import '../../../health_hygiene/services/health_official_pdf_service.dart';
import '../../../risk_assessment/presentation/providers/risk_assessment_providers.dart';

class EmployeeProfileDialog extends ConsumerStatefulWidget {
  final Employee employee;
  final int initialTab;

  const EmployeeProfileDialog({
    super.key,
    required this.employee,
    this.initialTab = 0,
  });

  @override
  ConsumerState<EmployeeProfileDialog> createState() => _EmployeeProfileDialogState();
}

class _EmployeeProfileDialogState extends ConsumerState<EmployeeProfileDialog> {
  late int _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  void _openTrainingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => TrainingRecordDialog(
        preselectedEmployeeId: widget.employee.id,
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
        employeeName: widget.employee.fullName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(trainingRecordsProvider);
    final healthRecordsAsync = ref.watch(healthRecordsProvider);
    final companyProfile = ref.watch(companyProfileNotifierProvider).asData?.value;
    final employee = widget.employee;
    final hasPhoto = employee.photoPath != null && File(employee.photoPath!).existsSync();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 840,
        height: 740,
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
                          'เลข ปชช.: ${HealthOfficialPdfService.formatNationalId(employee.nationalId)}  |  เริ่มงาน: ${HealthOfficialPdfService.formatThaiDate(employee.hireDate, short: true)}  |  โทร: ${employee.phone ?? "-"}',
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
            // 2. Segmented Tab Switcher (การฝึกอบรม vs ตรวจสุขภาพ & สมุดสุขภาพ)
            // ----------------------------------------------------------------
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _currentTab = 0),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _currentTab == 0 ? const Color(0xFF1E3A8A) : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school_rounded, size: 16, color: _currentTab == 0 ? Colors.white : Colors.grey.shade700),
                              const SizedBox(width: 6),
                              Text(
                                'ประวัติการฝึกอบรม & วุฒิบัตร',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _currentTab == 0 ? Colors.white : Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _currentTab = 1),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _currentTab == 1 ? const Color(0xFF0D9488) : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.medical_services_rounded, size: 16, color: _currentTab == 1 ? Colors.white : Colors.grey.shade700),
                              const SizedBox(width: 6),
                              Text(
                                'ตรวจสุขภาพ & สมุดสุขภาพ (Health Book)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _currentTab == 1 ? Colors.white : Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // ----------------------------------------------------------------
            // 3. Tab Body
            // ----------------------------------------------------------------
            if (_currentTab == 0) ...[
              // TAB 0: TRAINING RECORDS
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
                      onPressed: () => _openTrainingDialog(context),
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
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
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
                          statusText = '🔵 ผ่านการอบรม';
                        }

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            r.courseName ?? 'หลักสูตรความปลอดภัย',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
            ] else ...[
              // TAB 1: OCCUPATIONAL HEALTH & HEALTH BOOK
              healthRecordsAsync.when(
                data: (allHealthRecords) {
                  final empHealthRecords = allHealthRecords.where((r) =>
                    r.employeeId == employee.id ||
                    (r.employeeCode != null && r.employeeCode!.trim().toLowerCase() == employee.employeeCode.trim().toLowerCase())
                  ).toList();

                  final latest = empHealthRecords.isNotEmpty ? empHealthRecords.first : null;

                  return Expanded(
                    child: Column(
                      children: [
                        // Health KPI Ribbon
                        Container(
                          color: const Color(0xFFF8FAFC),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildKpiBox(
                                  title: 'ตรวจสุขภาพสะสม',
                                  value: '${empHealthRecords.length} ครั้ง',
                                  icon: Icons.history_rounded,
                                  color: const Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildKpiBox(
                                  title: 'ผลตรวจล่าสุด',
                                  value: latest?.overallResultPlainLabel ?? 'ยังไม่มีประวัติ',
                                  icon: Icons.health_and_safety_rounded,
                                  color: latest?.overallResult == 'NORMAL' ? const Color(0xFF10B981) : (latest?.overallResult == 'WATCH' ? Colors.amber.shade800 : Colors.red.shade700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildKpiBox(
                                  title: 'ความพร้อมปฏิบัติงาน (Fit for Duty)',
                                  value: latest?.fitnessLabel ?? 'ยังไม่ประเมิน',
                                  icon: Icons.fitness_center_rounded,
                                  color: latest?.fitnessToWork == 'FIT' ? const Color(0xFF0D9488) : Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ประวัติตรวจสุขภาพประจำปี & สมุดสุขภาพ (Health Book)',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: empHealthRecords.isNotEmpty
                                        ? () {
                                            HealthOfficialPdfService.printElectronicHealthBook(
                                              context: context,
                                              employee: employee,
                                              healthRecords: empHealthRecords,
                                              company: companyProfile,
                                            );
                                          }
                                        : null,
                                    icon: const Icon(Icons.menu_book_rounded, size: 16),
                                    label: const Text('พิมพ์สมุดสุขภาพ'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF1E3A8A),
                                      side: const BorderSide(color: Color(0xFF1E3A8A)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: latest != null
                                        ? () {
                                            HealthOfficialPdfService.printHealthSummaryCertificate(
                                              context: context,
                                              record: latest,
                                              company: companyProfile,
                                            );
                                          }
                                        : null,
                                    icon: const Icon(Icons.print_rounded, size: 16),
                                    label: const Text('พิมพ์ใบสรุปผลล่าสุด'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D9488),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: empHealthRecords.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.medical_services_outlined, size: 54, color: Colors.grey.shade300),
                                      const SizedBox(height: 10),
                                      Text(
                                        'พนักงานคนนี้ยังไม่มีประวัติการตรวจสุขภาพในระบบ',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'สามารถบันทึกหรือนำเข้าไฟล์ Excel ในเมนู "สุขภาพ" เพื่อเชื่อมโยงข้อมูลอัตโนมัติ',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  itemCount: empHealthRecords.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                                  itemBuilder: (ctx, idx) {
                                    final r = empHealthRecords[idx];
                                    final isNormal = r.overallResult == 'NORMAL';
                                    final isWatch = r.overallResult == 'WATCH';

                                    Color resBg = isNormal ? Colors.green.shade50 : (isWatch ? Colors.amber.shade50 : Colors.red.shade50);
                                    Color resFg = isNormal ? Colors.green.shade800 : (isWatch ? Colors.amber.shade900 : Colors.red.shade800);

                                    return Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.shade50,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      r.checkupTypeLabel,
                                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'วันที่ตรวจ: ${HealthOfficialPdfService.formatThaiDate(r.checkupDate)}',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: resBg,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: resFg.withValues(alpha: 0.3)),
                                                ),
                                                child: Text(
                                                  r.overallResultLabel,
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: resFg),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'สถานพยาบาล: ${r.hospitalName} ${r.doctorName != null ? " | แพทย์: ${r.doctorName}" : ""}',
                                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              _buildMiniPill('น้ำหนัก', '${r.weight ?? "-"} กก.'),
                                              _buildMiniPill('ส่วนสูง', '${r.height ?? "-"} ซม.'),
                                              _buildMiniPill('BMI', '${r.bmi?.toStringAsFixed(1) ?? "-"} (${HealthOfficialPdfService.interpretBmi(r.bmi)})'),
                                              _buildMiniPill('ความดัน (BP)', '${r.bpReading} ${HealthOfficialPdfService.interpretBp(r.bpSystolic, r.bpDiastolic)}'),
                                              _buildMiniPill('ชีพจร', '${r.pulse ?? "-"} bpm'),
                                              _buildMiniPill('ความพร้อมทำงาน', r.fitnessLabel, highlight: true),
                                            ],
                                          ),
                                          if (r.doctorOpinion != null && r.doctorOpinion!.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blueGrey.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'ความเห็นแพทย์: ${r.doctorOpinion}',
                                                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blueGrey.shade900),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () {
                                                  HealthOfficialPdfService.printHealthSummaryCertificate(
                                                    context: context,
                                                    record: r,
                                                    company: companyProfile,
                                                  );
                                                },
                                                icon: const Icon(Icons.print_outlined, size: 14),
                                                label: const Text('พิมพ์ใบสรุปผลรอบนี้', style: TextStyle(fontSize: 11)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Expanded(child: Center(child: Text('เกิดข้อผิดพลาด: $e'))),
              ),
            ],

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

  Widget _buildMiniPill(String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: highlight ? Colors.teal.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: highlight ? Colors.teal.shade300 : Colors.grey.shade300, width: 0.5),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          color: highlight ? Colors.teal.shade900 : const Color(0xFF334155),
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
