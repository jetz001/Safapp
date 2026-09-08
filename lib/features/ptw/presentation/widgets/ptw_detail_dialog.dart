import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ptw_model.dart';
import '../../data/models/ptw_checklist_model.dart';
import '../../data/models/confined_role_model.dart';
import '../../data/models/gas_test_log_model.dart';
import '../../data/models/loto_isolation_model.dart';
import '../../domain/enums/ptw_status.dart';
import '../../domain/enums/high_risk_type.dart';
import '../../domain/services/ptw_workflow_engine.dart';
import '../notifiers/ptw_detail_notifier.dart';
import '../notifiers/ptw_list_notifier.dart';
import 'ptw_status_chip.dart';
import 'signature_pad_widget.dart';

/// Comprehensive Full-View Modal Dialog for PTW Permit Details & Workflow Actions
class PtwDetailDialog extends ConsumerStatefulWidget {
  final String ptwNumber;
  final VoidCallback? onPermitUpdated;

  const PtwDetailDialog({
    super.key,
    required this.ptwNumber,
    this.onPermitUpdated,
  });

  @override
  ConsumerState<PtwDetailDialog> createState() => _PtwDetailDialogState();
}

class _PtwDetailDialogState extends ConsumerState<PtwDetailDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleTransition(PtwStatus targetStatus, PtwModel permit) async {
    final requiredSigs = PtwWorkflowEngine.getRequiredSignatories(targetStatus, permit);

    // If closing or approving or extending, prompt for signature and remarks
    String? signatoryName;
    String? remarks;
    Uint8List? sigBytes;

    if (targetStatus == PtwStatus.draft) {
      // Rejection reason prompt
      final reasonController = TextEditingController();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('ตีกลับคำขอให้แก้ไข (Return to Draft)'),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'ระบุเหตุผลหรือข้อเสนอแนะในการแก้ไข JSA/มาตรการความปลอดภัย...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
              child: const Text('ยืนยันตีกลับ'),
            ),
          ],
        ),
      );
      if (confirm != true || reasonController.text.trim().isEmpty) return;
      remarks = reasonController.text.trim();
    } else if (targetStatus == PtwStatus.closedCancelled && permit.status == PtwStatus.draft) {
      // Direct cancellation of draft
      remarks = 'ยกเลิกแบบร่างคำขอ';
    } else {
      // Open digital signature dialog
      sigBytes = await showSignatureDialog(
        context: context,
        title: 'ลงนามอนุมัติ / เปลี่ยนสถานะ: ${targetStatus.labelTh}',
        subtitle: requiredSigs.isNotEmpty ? requiredSigs.first : null,
        signatoryRole: targetStatus == PtwStatus.active ? 'SAFETY_OFFICER / AUTHORIZER' : 'INSPECTOR',
      );
      if (sigBytes == null) return;
      signatoryName = 'ผู้มีอำนาจลงนาม';
    }

    setState(() => _isProcessing = true);

    final result = await ref.read(ptwListProvider.notifier).transitionStatus(
          permit.ptwNumber,
          targetStatus,
          comments: remarks,
          approverName: signatoryName,
          approverRole: targetStatus.toDbCode(),
          signatureBytes: sigBytes,
          rejectionReason: remarks,
        );

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (result.isAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'เปลี่ยนสถานะเป็น ${targetStatus.labelTh} เรียบร้อย'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      widget.onPermitUpdated?.call();
      Navigator.of(context).pop();
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('ไม่สามารถเปลี่ยนสถานะได้'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message ?? 'ไม่ผ่านเงื่อนไขความปลอดภัยตามกฎหมาย:'),
              const SizedBox(height: 8),
              ...result.validationErrors.map((e) => Text('• $e', style: const TextStyle(color: Colors.red, fontSize: 12))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ตกลง')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(ptwDetailProvider(widget.ptwNumber));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: const Color(0xFFF8FAFC),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 950,
        height: 720,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: detailAsync.when(
          data: (permit) {
            if (permit == null) {
              return const Center(child: Text('ไม่พบข้อมูลใบอนุญาตทำงาน'));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(permit),
                if (permit.isOverdue) _buildOverdueBanner(permit),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGeneralInfoTab(permit),
                      _buildChecklistsTab(permit),
                      _buildConfinedRolesTab(permit),
                      _buildGasLogsTab(permit),
                      _buildLotoTab(permit),
                      _buildApprovalsTab(permit),
                    ],
                  ),
                ),
                _buildFooterActions(permit),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('ข้อผิดพลาด: $err', style: const TextStyle(color: Colors.red))),
        ),
      ),
    );
  }

  Widget _buildHeader(PtwModel permit) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: permit.primaryRiskType.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: permit.primaryRiskType.color.withValues(alpha: 0.3)),
            ),
            child: Icon(permit.primaryRiskType.icon, color: permit.primaryRiskType.color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      permit.ptwNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 10),
                    PtwStatusChip(status: permit.status),
                    const SizedBox(width: 8),
                    HighRiskTypeChip(riskType: permit.primaryRiskType, isCompact: true),
                    if (permit.secondaryRiskTypes.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      ...permit.secondaryRiskTypes.map(
                        (sec) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: HighRiskTypeChip(riskType: sec, isCompact: true),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  permit.workTitle,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueBanner(PtwModel permit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFFFEF2F2),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'แจ้งเตือน: ใบอนุญาตทำงานฉบับนี้เกินกำหนดเวลาที่ได้รับอนุญาตแล้ว (${permit.formattedTimeWindowTh}) กรุณาดำเนินการต่อเวลาหรือลงนามปิดงานทันที',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF0F172A),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF0D9488),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
        tabs: const [
          Tab(icon: Icon(Icons.info_outline, size: 16), text: 'ข้อมูลทั่วไป'),
          Tab(icon: Icon(Icons.checklist_rounded, size: 16), text: 'Checklist ความปลอดภัย'),
          Tab(icon: Icon(Icons.people_outline, size: 16), text: 'ผู้มีหน้าที่ 4 ฝ่าย'),
          Tab(icon: Icon(Icons.cloud_outlined, size: 16), text: 'ตรวจวัดก๊าซ'),
          Tab(icon: Icon(Icons.lock_outline, size: 16), text: 'LOTO / ตัดพลังงาน'),
          Tab(icon: Icon(Icons.history_edu, size: 16), text: 'ประวัติและลายเซ็น'),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Tab 1: General Info
  // --------------------------------------------------------------------------
  Widget _buildGeneralInfoTab(PtwModel permit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('ข้อมูลสถานที่และกำหนดเวลาปฏิบัติงาน', Icons.location_on_outlined),
          const SizedBox(height: 12),
          _buildInfoGrid([
            _InfoItem('โรงงาน / อาคาร / แผนก:', permit.plantArea),
            _InfoItem('ตำแหน่งเฉพาะเจาะจง:', permit.specificLocation),
            _InfoItem('วันเวลาเริ่มงาน:', '${permit.workStartDate} เวลา ${permit.workStartTime} น.'),
            _InfoItem('วันเวลาสิ้นสุดงาน:', '${permit.workEndDate} เวลา ${permit.workEndTime} น.'),
            _InfoItem('ชั่วโมงต่อเวลา:', '${permit.extensionHours} ชม. ${permit.extensionReason != null ? "(${permit.extensionReason})" : ""}'),
            _InfoItem('เลขที่อ้างอิง JSA:', permit.jsaReferenceNo ?? 'ไม่มีเอกสารแนบ'),
          ]),
          const SizedBox(height: 20),

          _buildSectionHeader('ข้อมูลผู้ขออนุญาตและทีมงาน', Icons.badge_outlined),
          const SizedBox(height: 12),
          _buildInfoGrid([
            _InfoItem('ชื่อผู้ขออนุญาต:', permit.applicantName),
            _InfoItem('ประเภทผู้ขอ:', permit.applicantType == 'INTERNAL_EMPLOYEE' ? 'พนักงานประจำ' : 'ผู้รับเหมา (Contractor)'),
            _InfoItem('แผนก / บริษัท:', permit.applicantDepartment),
            _InfoItem('เบอร์โทรศัพท์ติดต่อ:', permit.applicantPhone),
            _InfoItem('จำนวนผู้ปฏิบัติงานทั้งหมด:', '${permit.workerCount} คน'),
            _InfoItem('รายชื่อทีมงาน:', permit.workerNames.isNotEmpty ? permit.workerNames.join(', ') : '-'),
          ]),
          const SizedBox(height: 20),

          _buildSectionHeader('มาตรการควบคุมความปลอดภัยและแผนฉุกเฉิน', Icons.health_and_safety_outlined),
          const SizedBox(height: 12),
          _buildInfoGrid([
            _InfoItem('อุปกรณ์ PPE ที่ต้องสวมใส่:', permit.requiredPpeList, isFullWidth: true),
            _InfoItem('แผนการกู้ภัยฉุกเฉิน:', permit.emergencyRescuePlan, isFullWidth: true),
            if (permit.specialPrecautions.isNotEmpty)
              _InfoItem('มาตรการพิเศษเฉพาะหน้างาน:', permit.specialPrecautions, isFullWidth: true),
          ]),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Tab 2: Checklists
  // --------------------------------------------------------------------------
  Widget _buildChecklistsTab(PtwModel permit) {
    if (permit.checklistItems.isEmpty) {
      return const Center(child: Text('ไม่มีรายการ Checklist สำหรับใบอนุญาตนี้'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: permit.checklistItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, index) {
        final item = permit.checklistItems[index];
        final isPassed = item.result == 'YES';
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPassed ? const Color(0xFFF0FDF4) : (item.result == 'NO' ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isPassed ? const Color(0xFFBBF7D0) : (item.result == 'NO' ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPassed ? const Color(0xFF16A34A) : (item.result == 'NO' ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.result,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.isMandatory) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                            child: const Text('บังคับตามกฎหมาย', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text('[${item.checkCategory}]', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(item.questionTh, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                    if (item.remarks != null && item.remarks!.isNotEmpty)
                      Text('หมายเหตุ: ${item.remarks}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // Tab 3: Confined Roles
  // --------------------------------------------------------------------------
  Widget _buildConfinedRolesTab(PtwModel permit) {
    if (!permit.isConfinedSpaceWork && permit.confinedRoles.isEmpty) {
      return const Center(child: Text('งานนี้ไม่ใช่ประเภทที่อับอากาศ (ไม่มีการลงทะเบียน 4 ฝ่าย)'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: permit.confinedRoles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final role = permit.confinedRoles[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(role.roleType.icon, color: const Color(0xFF8B5CF6), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          role.roleType.labelTh,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: role.isCertificateValid ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            role.isCertificateValid ? 'ใบประกาศถูกต้อง' : 'ใบประกาศหมดอายุ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: role.isCertificateValid ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.personName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'เลขที่ใบประกาศ: ${role.certNumber} • สถาบัน: ${role.certInstitute} • หมดอายุ: ${role.certExpiryDate}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // Tab 4: Gas Logs
  // --------------------------------------------------------------------------
  Widget _buildGasLogsTab(PtwModel permit) {
    if (permit.gasTestLogs.isEmpty) {
      return const Center(child: Text('ยังไม่มีบันทึกการตรวจวัดก๊าซ'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: permit.gasTestLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final log = permit.gasTestLogs[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: log.isSafe ? Colors.white : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: log.isSafe ? const Color(0xFFE2E8F0) : const Color(0xFFFCA5A5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${log.testStage} - ${log.testTimestamp.replaceFirst('T', ' ')}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: log.isSafe ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      log.isSafe ? 'ผ่านเกณฑ์ปลอดภัย' : 'อันตรายเกินเกณฑ์',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: log.isSafe ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildGasBadge('O₂', '${log.oxygenPercent}%', log.oxygenPercent >= 19.5 && log.oxygenPercent <= 23.5),
                  const SizedBox(width: 8),
                  _buildGasBadge('LEL', '${log.combustiblePercentLel}%', log.combustiblePercentLel < 10.0),
                  const SizedBox(width: 8),
                  _buildGasBadge('CO', '${log.carbonMonoxidePpm} ppm', log.carbonMonoxidePpm < 25.0),
                  const SizedBox(width: 8),
                  _buildGasBadge('H₂S', '${log.hydrogenSulfidePpm} ppm', log.hydrogenSulfidePpm < 10.0),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'จุดตรวจ: ${log.locationPoint} • ผู้ตรวจ: ${log.testerName} (${log.detectorModel})',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGasBadge(String label, String value, bool isSafe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSafe ? const Color(0xFFF1F5F9) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSafe ? const Color(0xFF0F172A) : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Tab 5: LOTO Isolations
  // --------------------------------------------------------------------------
  Widget _buildLotoTab(PtwModel permit) {
    if (permit.lotoIsolations.isEmpty) {
      return const Center(child: Text('ไม่มีรายการตัดแยกพลังงาน LOTO สำหรับใบอนุญาตนี้'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: permit.lotoIsolations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final item = permit.lotoIsolations[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAB308).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.energyType.icon, color: const Color(0xFFCA8A04), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.equipmentTagNo,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'monospace'),
                        ),
                        const SizedBox(width: 8),
                        Text('• ${item.energyType.labelTh}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(item.equipmentName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(
                      'กุญแจ Tag: ${item.padlockTagNo} • วิธีทดสอบ Zero Energy: ${item.zeroEnergyTestMethod}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.isZeroEnergyVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.isZeroEnergyVerified ? 'Zero Energy: PASS' : 'ยังไม่ทดสอบ 0V',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: item.isZeroEnergyVerified ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.isDeIsolated ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.isDeIsolated ? 'ปลดล็อกคืนสภาพแล้ว' : 'ล็อกอยู่ (Locked)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: item.isDeIsolated ? const Color(0xFF0284C7) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // Tab 6: Approvals & Signatures History
  // --------------------------------------------------------------------------
  Widget _buildApprovalsTab(PtwModel permit) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('ลายเซ็นดิจิทัล 4 ฝ่ายและผู้ปิดงาน', Icons.draw_outlined),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildSigStatusCard('1. ผู้ขออนุญาต (Applicant)', permit.applicantName, permit.applicantSignedAt != null),
            _buildSigStatusCard('2. จป.วิชาชีพ ผู้ตรวจสอบ', permit.safetyOfficerName ?? '-', permit.safetyOfficerSignedAt != null),
            _buildSigStatusCard('3. ผู้อนุญาตตามกฎหมาย', permit.authorizerName ?? '-', permit.authorizerSignedAt != null),
            _buildSigStatusCard('4. ผู้รับมอบงาน/ต่อเวลา', permit.handoverSignedAt != null ? 'ลงนามแล้ว' : '-', permit.handoverSignedAt != null),
            _buildSigStatusCard('5. ผู้ปิดงาน (Closure)', permit.closureRemarks ?? '-', permit.closureSignedAt != null),
          ],
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('บันทึกประวัติการเปลี่ยนสถานะ (Audit Logs)', Icons.history),
        const SizedBox(height: 12),
        if (permit.approvalLogs.isEmpty)
          const Text('ยังไม่มีประวัติการบันทึกสถานะ', style: TextStyle(color: Color(0xFF94A3B8)))
        else
          ...permit.approvalLogs.map((log) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF0D9488), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${log.action} โดย ${log.approverName} (${log.approverRole})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        if (log.comments != null && log.comments!.isNotEmpty)
                          Text('ความเห็น: ${log.comments}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                      ],
                    ),
                  ),
                  Text(
                    log.timestamp.replaceFirst('T', ' ').substring(0, 16),
                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSigStatusCard(String title, String name, bool isSigned) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSigned ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSigned ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          Icon(
            isSigned ? Icons.verified : Icons.radio_button_unchecked,
            color: isSigned ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(PtwModel permit) {
    final allowedTargets = PtwWorkflowEngine.getAllowedTargetStatuses(permit.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('ปิดหน้าต่าง'),
          ),
          const Spacer(),

          if (_isProcessing) ...[
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            // Status Transitions based on allowed targets
            if (allowedTargets.contains(PtwStatus.pendingApproval))
              FilledButton.icon(
                onPressed: () => _handleTransition(PtwStatus.pendingApproval, permit),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('ยื่นคำขออนุมัติ (Submit)'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
              ),

            if (allowedTargets.contains(PtwStatus.active)) ...[
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _handleTransition(PtwStatus.active, permit),
                icon: const Icon(Icons.verified_user_outlined, size: 16),
                label: const Text('อนุมัติเปิดงาน (Approve to Active)'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669)),
              ),
            ],

            if (allowedTargets.contains(PtwStatus.draft) && permit.status == PtwStatus.pendingApproval) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _handleTransition(PtwStatus.draft, permit),
                icon: const Icon(Icons.replay_rounded, size: 16),
                label: const Text('ตีกลับให้แก้ไข (Return)'),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEA580C)),
              ),
            ],

            if (allowedTargets.contains(PtwStatus.extendedHandover)) ...[
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _handleTransition(PtwStatus.extendedHandover, permit),
                icon: const Icon(Icons.update_rounded, size: 16),
                label: const Text('ต่อเวลา/ส่งกะ (Extend)'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              ),
            ],

            if (allowedTargets.contains(PtwStatus.closedCancelled)) ...[
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _handleTransition(PtwStatus.closedCancelled, permit),
                icon: const Icon(Icons.task_alt_rounded, size: 16),
                label: Text(permit.status == PtwStatus.draft ? 'ยกเลิกคำขอ' : 'ปิดงานสมบูรณ์ (Close PTW)'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF475569)),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0D9488), size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildInfoGrid(List<_InfoItem> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 14,
        children: items.map((item) {
          return SizedBox(
            width: item.isFullWidth ? double.infinity : 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  final bool isFullWidth;
  _InfoItem(this.label, this.value, {this.isFullWidth = false});
}
