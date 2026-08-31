import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/contractor_models.dart';
import '../providers/contractor_providers.dart';
import '../widgets/contractor_company_dialog.dart';
import '../widgets/contractor_worker_dialog.dart';
import '../widgets/contractor_violation_dialog.dart';
import '../widgets/safety_pass_dialog.dart';
import '../../services/safety_violation_pdf_service.dart';
import '../../../risk_assessment/domain/models/contractor_jsa_models.dart';
import '../../../risk_assessment/presentation/providers/risk_assessment_providers.dart';
import '../../../risk_assessment/presentation/widgets/contractor_doc_upload_dialog.dart';
import '../../../risk_assessment/presentation/pages/contractor_doc_viewer_page.dart';

class ContractorPage extends ConsumerStatefulWidget {
  const ContractorPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ContractorPage> createState() => _ContractorPageState();
}

class _ContractorPageState extends ConsumerState<ContractorPage> {
  int _selectedTab = 0; // 0 = Companies, 1 = Workers, 2 = Documents, 3 = Violations

  void _openCompanyDialog({ContractorCompany? company}) {
    showDialog(
      context: context,
      builder: (ctx) => ContractorCompanyDialog(existingCompany: company),
    );
  }

  void _openWorkerDialog({ContractorWorker? worker, int? preselectedContractorId}) {
    showDialog(
      context: context,
      builder: (ctx) => ContractorWorkerDialog(
        existingWorker: worker,
        preselectedContractorId: preselectedContractorId,
      ),
    );
  }

  void _openViolationDialog({int? preselectedContractorId}) {
    showDialog(
      context: context,
      builder: (ctx) => ContractorViolationDialog(preselectedContractorId: preselectedContractorId),
    );
  }

  void _openUploadDocDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const ContractorDocUploadDialog(),
    );
  }

  void _showSafetyPass(ContractorWorker worker) {
    showDialog(
      context: context,
      builder: (ctx) => SafetyPassDialog(worker: worker),
    );
  }

  Future<void> _deleteCompany(ContractorCompany company) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบสถานประกอบการผู้รับเหมา'),
        content: Text('ต้องการลบบริษัท "${company.companyName}" รวมทั้งข้อมูลคนงานและประวัติทั้งหมดใช่หรือไม่?'),
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

    if (confirm == true && company.id != null) {
      await ref.read(contractorCompaniesProvider.notifier).deleteCompany(company.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบข้อมูลบริษัทเรียบร้อยแล้ว')),
        );
      }
    }
  }

  Future<void> _deleteWorker(ContractorWorker worker) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบข้อมูลคนงาน'),
        content: Text('ต้องการลบคนงาน "${worker.workerName}" ใช่หรือไม่?'),
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

    if (confirm == true && worker.id != null) {
      await ref.read(contractorWorkersProvider.notifier).deleteWorker(worker.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบข้อมูลคนงานเรียบร้อยแล้ว')),
        );
      }
    }
  }

  Future<void> _deleteViolation(ContractorViolation violation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบบันทึกการตักเตือน'),
        content: const Text('ต้องการลบบันทึกการตักเตือนนี้ใช่หรือไม่?'),
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

    if (confirm == true && violation.id != null) {
      await ref.read(contractorViolationsProvider.notifier).deleteViolation(violation.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบบันทึกการตักเตือนเรียบร้อยแล้ว')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(contractorCompaniesProvider);
    final workersAsync = ref.watch(contractorWorkersProvider);
    final violationsAsync = ref.watch(contractorViolationsProvider);
    final docsAsync = ref.watch(contractorJsaProvider);

    final companies = companiesAsync.asData?.value ?? [];
    final workers = workersAsync.asData?.value ?? [];
    final violations = violationsAsync.asData?.value ?? [];
    final docs = docsAsync.asData?.value ?? [];

    final validPassesCount = workers.where((w) => w.inductionStatus == 'VALID').length;
    final expiredPassesCount = workers.where((w) => w.inductionStatus == 'EXPIRED' || w.inductionStatus == 'EXPIRING_SOON').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------------------
            // 1. Header Banner & Actions
            // ----------------------------------------------------------------
            _buildHeaderBanner(
              onAddCompany: () => _openCompanyDialog(),
              onAddWorker: () => _openWorkerDialog(),
              onAddViolation: () => _openViolationDialog(),
              onUploadDoc: () => _openUploadDocDialog(),
            ),
            const SizedBox(height: 20),

            // ----------------------------------------------------------------
            // 2. Stat Overview Row
            // ----------------------------------------------------------------
            _buildStatOverview(
              totalCompanies: companies.length,
              totalWorkers: workers.length,
              validPasses: validPassesCount,
              expiredPasses: expiredPassesCount,
              totalViolations: violations.length,
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
                      label: '🏢 ทะเบียนบริษัทผู้รับเหมา',
                      count: companies.length,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabButton(
                      index: 1,
                      label: '👷 ทะเบียนคนงาน & Induction',
                      count: workers.length,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabButton(
                      index: 2,
                      label: '📁 เอกสาร & JSA ผู้รับเหมา',
                      count: docs.length,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabButton(
                      index: 3,
                      label: '⚠️ บันทึกตักเตือน & ฝ่าฝืน',
                      count: violations.length,
                      color: const Color(0xFFDC2626),
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
              _buildCompaniesTab(companiesAsync)
            else if (_selectedTab == 1)
              _buildWorkersTab(workersAsync, companies)
            else if (_selectedTab == 2)
              _buildDocumentsTab(docsAsync)
            else
              _buildViolationsTab(violationsAsync),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // HEADER BANNER WIDGET
  // ==========================================================================
  Widget _buildHeaderBanner({
    required VoidCallback onAddCompany,
    required VoidCallback onAddWorker,
    required VoidCallback onAddViolation,
    required VoidCallback onUploadDoc,
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
            child: const Icon(Icons.engineering_rounded, color: Colors.amber, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ระบบบริหารจัดการความปลอดภัยผู้รับเหมา (Contractor Safety Management)',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'ควบคุมการเข้าปฏิบัติงาน, ตรวจสอบบัตร Safety Induction, จัดเก็บเอกสาร JSA และประเมินคะแนนความปลอดภัย',
                  style: TextStyle(color: Colors.blue.shade100, fontSize: 12),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('เพิ่มคนงาน & ออกบัตร', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: onAddWorker,
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade500,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_business_rounded, size: 18),
                label: const Text('ลงทะเบียนบริษัท', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: onAddCompany,
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
    required int totalCompanies,
    required int totalWorkers,
    required int validPasses,
    required int expiredPasses,
    required int totalViolations,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final items = [
          _StatCardItem('บริษัทที่ลงทะเบียน', '$totalCompanies แห่ง', Icons.domain_rounded, const Color(0xFF3B82F6)),
          _StatCardItem('คนงานในระบบ', '$totalWorkers คน', Icons.people_alt_rounded, const Color(0xFF0D9488)),
          _StatCardItem('ผ่านการอบรม (Active)', '$validPasses คน', Icons.verified_user_rounded, const Color(0xFF10B981)),
          _StatCardItem('หมดอายุ/ใกล้หมด', '$expiredPasses คน', Icons.warning_amber_rounded, const Color(0xFFF59E0B)),
          _StatCardItem('ประวัติตักเตือน', '$totalViolations ครั้ง', Icons.report_problem_rounded, const Color(0xFFEF4444)),
        ];

        if (isNarrow) {
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: items.map((i) => _buildStatCard(i)).toList(),
          );
        }

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
      },
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
  // TAB 1: COMPANIES DIRECTORY
  // ==========================================================================
  Widget _buildCompaniesTab(AsyncValue<List<ContractorCompany>> companiesAsync) {
    return companiesAsync.when(
      data: (companies) {
        if (companies.isEmpty) {
          return _buildEmptyState(
            icon: Icons.business_outlined,
            title: 'ยังไม่มีสถานประกอบการผู้รับเหมาที่ลงทะเบียน',
            subtitle: 'เริ่มต้นด้วยการขึ้นทะเบียนบริษัทผู้รับเหมาที่เข้ามาปฏิบัติงานในพื้นที่',
            btnLabel: 'ขึ้นทะเบียนบริษัทแรก',
            onAction: () => _openCompanyDialog(),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: companies.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, idx) {
            final c = companies[idx];
            final scoreColor = c.safetyScore >= 90
                ? Colors.green.shade700
                : c.safetyScore >= 75
                    ? Colors.blue.shade700
                    : c.safetyScore >= 60
                        ? Colors.amber.shade800
                        : Colors.red.shade700;

            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business_rounded, color: Color(0xFF1E3A8A), size: 28),
                    ),
                    const SizedBox(width: 16),

                    // Info Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                c.companyName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Text(c.serviceType, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                              ),
                              const SizedBox(width: 8),
                              _buildCompanyStatusBadge(c.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ผู้ประสานงาน: ${c.contactPerson ?? "-"} (${c.phone ?? "-"})  |  จป.ผู้รับเหมา: ${c.safetyOfficerName ?? "-"} (${c.safetyOfficerPhone ?? "-"})',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: scoreColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'คะแนนความปลอดภัย: ${c.safetyScore}/100 (${c.safetyGrade})',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: scoreColor),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'คนงาน: ${c.workerCount ?? 0} คน  |  ประวัติตักเตือน: ${c.violationCount ?? 0} ครั้ง',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
                        OutlinedButton.icon(
                          onPressed: () => _openWorkerDialog(preselectedContractorId: c.id),
                          icon: const Icon(Icons.person_add, size: 16),
                          label: const Text('เพิ่มคนงาน'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0D9488),
                            side: const BorderSide(color: Color(0xFF0D9488)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (val) {
                            if (val == 'edit') {
                              _openCompanyDialog(company: c);
                            } else if (val == 'violation') {
                              _openViolationDialog(preselectedContractorId: c.id);
                            } else if (val == 'delete') {
                              _deleteCompany(c);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'edit', child: Text('แก้ไขข้อมูลบริษัท')),
                            const PopupMenuItem(value: 'violation', child: Text('ออกใบตักเตือนความปลอดภัย')),
                            const PopupMenuItem(value: 'delete', child: Text('ลบบริษัทนี้', style: TextStyle(color: Colors.red))),
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
  // TAB 2: WORKERS DIRECTORY & INDUCTION PASSES
  // ==========================================================================
  Widget _buildWorkersTab(AsyncValue<List<ContractorWorker>> workersAsync, List<ContractorCompany> companies) {
    return workersAsync.when(
      data: (workers) {
        if (workers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline_rounded,
            title: 'ยังไม่มีคนงานผู้รับเหมาในระบบ',
            subtitle: 'บันทึกรายชื่อคนงาน พร้อมวันผ่านการอบรม Safety Induction เพื่อออกบัตร Safety Pass',
            btnLabel: 'เพิ่มคนงานคนแรก',
            onAction: () => _openWorkerDialog(),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: workers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, idx) {
            final w = workers[idx];
            final status = w.inductionStatus;
            final hasPhoto = w.photoPath != null && File(w.photoPath!).existsSync();

            Color statusBg;
            Color statusFg;
            String statusText;

            switch (status) {
              case 'VALID':
                statusBg = Colors.green.shade50;
                statusFg = Colors.green.shade800;
                statusText = '🟢 บัตรอนุญาตพร้อมใช้งาน';
                break;
              case 'EXPIRING_SOON':
                statusBg = Colors.amber.shade50;
                statusFg = Colors.amber.shade900;
                statusText = '🟡 ใกล้หมดอายุ (30 วัน)';
                break;
              case 'EXPIRED':
                statusBg = Colors.red.shade50;
                statusFg = Colors.red.shade800;
                statusText = '🔴 บัตรหมดอายุ';
                break;
              case 'PENDING':
              default:
                statusBg = Colors.grey.shade100;
                statusFg = Colors.grey.shade800;
                statusText = '⚪ ยังไม่อบรม';
                break;
            }

            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          ? ClipOval(child: Image.file(File(w.photoPath!), fit: BoxFit.cover))
                          : const Icon(Icons.person, color: Colors.grey, size: 30),
                    ),
                    const SizedBox(width: 14),

                    // Worker Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                w.workerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(w.jobRole, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: statusFg.withValues(alpha: 0.3)),
                                ),
                                child: Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusFg)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'บริษัท: ${w.contractorName ?? "-"}  |  เลขประจำตัว: ${w.nationalIdOrPassport ?? "-"}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'วันที่อบรม Induction: ${w.inductionDate ?? "-"}  |  ใช้ได้ถึง: ${w.inductionValidUntil ?? "-"}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showSafetyPass(w),
                          icon: const Icon(Icons.badge_rounded, size: 16),
                          label: const Text('Safety Pass'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (val) {
                            if (val == 'edit') {
                              _openWorkerDialog(worker: w);
                            } else if (val == 'delete') {
                              _deleteWorker(w);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'edit', child: Text('แก้ไขข้อมูลคนงาน')),
                            const PopupMenuItem(value: 'delete', child: Text('ลบคนงานนี้', style: TextStyle(color: Colors.red))),
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
  // TAB 3: CONTRACTOR DOCUMENTS & JSA
  // ==========================================================================
  Widget _buildDocumentsTab(AsyncValue<List<ContractorJsaDocument>> docsAsync) {
    return docsAsync.when(
      data: (docs) {
        if (docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.folder_shared_outlined,
            title: 'ยังไม่มีเอกสารความปลอดภัยและ JSA ของผู้รับเหมา',
            subtitle: 'อัปโหลดเอกสาร PDF หรือรูปถ่ายสแกน Hard copy ที่ผู้รับเหมานำส่ง',
            btnLabel: 'อัปโหลดเอกสารแรก',
            onAction: () => _openUploadDocDialog(),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, idx) {
            final doc = docs[idx];
            final pdfCount = doc.filePaths.where((f) => p.extension(f).toLowerCase() == '.pdf').length;
            final imgCount = doc.filePaths.where((f) => p.extension(f).toLowerCase() != '.pdf').length;

            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.description_rounded, color: Color(0xFF6366F1), size: 24),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                doc.contractorName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(doc.documentType, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo.shade800)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text('ชื่องาน: ${doc.projectTitle}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          const SizedBox(height: 2),
                          Text('วันที่จัดทำ: ${doc.assessmentDate}  |  ผู้ประเมิน: ${doc.assessorName ?? "-"}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: [
                              if (pdfCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: Text('PDF $pdfCount ไฟล์', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                                ),
                              if (imgCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: Text('ภาพสแกน $imgCount รูป', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ContractorDocViewerPage(document: doc)),
                        );
                      },
                      icon: const Icon(Icons.visibility_rounded, size: 16),
                      label: const Text('เปิดดูเอกสาร'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
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
  // TAB 4: SAFETY VIOLATIONS & WARNINGS
  // ==========================================================================
  Widget _buildViolationsTab(AsyncValue<List<ContractorViolation>> violationsAsync) {
    return violationsAsync.when(
      data: (violations) {
        if (violations.isEmpty) {
          return _buildEmptyState(
            icon: Icons.verified_user_rounded,
            title: 'ไม่มีประวัติการฝ่าฝืนกฎความปลอดภัย',
            subtitle: 'ผู้รับเหมาทุกรายปฏิบัติตามมาตรฐานความปลอดภัยอย่างเคร่งครัด (Zero Violations)',
            btnLabel: 'ออกใบตักเตือนใหม่',
            onAction: () => _openViolationDialog(),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: violations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, idx) {
            final v = violations[idx];
            Color sevBg;
            Color sevFg;
            String sevText;

            switch (v.severityLevel) {
              case 'CRITICAL':
                sevBg = Colors.red.shade100;
                sevFg = Colors.red.shade900;
                sevText = '🔴 วิกฤต';
                break;
              case 'SEVERE':
                sevBg = Colors.orange.shade100;
                sevFg = Colors.orange.shade900;
                sevText = '🟠 ร้ายแรง';
                break;
              case 'MODERATE':
                sevBg = Colors.amber.shade100;
                sevFg = Colors.amber.shade900;
                sevText = '🟡 ปานกลาง';
                break;
              case 'MINOR':
              default:
                sevBg = Colors.blue.shade100;
                sevFg = Colors.blue.shade900;
                sevText = '🟢 เล็กน้อย';
                break;
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
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 24),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                v.contractorName ?? "ผู้รับเหมา",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                              if (v.workerName != null) ...[
                                const SizedBox(width: 6),
                                Text('(${v.workerName})', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                              ],
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: sevBg, borderRadius: BorderRadius.circular(6)),
                                child: Text(sevText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sevFg)),
                              ),
                              if (v.scoreDeducted > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                                  child: Text('-${v.scoreDeducted} คะแนน', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('ข้อหา/ประเภท: ${v.violationType}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          const SizedBox(height: 2),
                          Text('รายละเอียด: ${v.description}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                          const SizedBox(height: 2),
                          Text('มาตรการดำเนินการ: ${v.actionTaken}', style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text('วันที่ตรวจพบ: ${v.incidentDate}  |  ผู้ตรวจ: ${v.inspectorName ?? "-"}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),

                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.print_rounded, size: 16),
                          label: const Text('พิมพ์ใบตักเตือน'),
                          onPressed: () async {
                            final profile = ref.read(companyProfileNotifierProvider).asData?.value;
                            await SafetyViolationPdfService.printViolationNotice(
                              context: context,
                              violation: v,
                              companyProfile: profile,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                          tooltip: 'ลบบันทึกตักเตือนนี้',
                          onPressed: () => _deleteViolation(v),
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

  Widget _buildCompanyStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'ACTIVE':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = '🟢 อนุญาตทำงาน';
        break;
      case 'SUSPENDED':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = '🟡 ระงับงานชั่วคราว';
        break;
      case 'BLACKLISTED':
      default:
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        label = '🔴 บัญชีดำ';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
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
