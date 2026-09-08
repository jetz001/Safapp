import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ptw_model.dart';
import '../../data/models/ptw_kpi_summary_model.dart';
import '../../domain/enums/high_risk_type.dart';
import '../../domain/enums/ptw_status.dart';
import '../notifiers/ptw_list_notifier.dart';
import '../notifiers/ptw_filter_notifier.dart';
import '../widgets/ptw_kpi_card.dart';
import '../widgets/ptw_status_chip.dart';
import '../widgets/ptw_detail_dialog.dart';

/// Tab 1: PTW Dashboard, KPI Metrics & Comprehensive Permit Register
class PtwDashboardTab extends ConsumerWidget {
  final VoidCallback? onCreatePermitRequested;

  const PtwDashboardTab({
    super.key,
    this.onCreatePermitRequested,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpiAsync = ref.watch(ptwKpiProvider);
    final permitsAsync = ref.watch(ptwListProvider);
    final departmentsAsync = ref.watch(ptwDepartmentsProvider);
    final filterState = ref.watch(ptwFilterProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(ptwListProvider.notifier).refresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Metrics Row
            kpiAsync.when(
              data: (kpi) => _buildKpiSection(context, kpi, ref),
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Center(child: Text('ไม่สามารถโหลด KPI ได้: $err')),
            ),
            const SizedBox(height: 18),

            // Search & Filter Bar
            _buildSearchAndFilterBar(context, ref, filterState, departmentsAsync),
            const SizedBox(height: 16),

            // Register Table / List View
            permitsAsync.when(
              data: (permits) {
                if (permits.isEmpty) {
                  return _buildEmptyState(context);
                }
                return _buildPermitTableAndCards(context, ref, permits);
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('เกิดข้อผิดพลาดในการโหลดรายการ: $err', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiSection(BuildContext context, PtwKpiSummaryModel kpi, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final double cardWidth = isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 12) / 2;

        return Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: PtwKpiCard(
                    title: 'ใบอนุญาตทั้งหมด',
                    value: '${kpi.totalPermits}',
                    subtitle: 'รวม 5 ประเภทความเสี่ยง',
                    icon: Icons.assignment_outlined,
                    color: const Color(0xFF1E3A8A),
                    onTap: () => ref.read(ptwFilterProvider.notifier).reset(),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: PtwKpiCard(
                    title: 'กำลังปฏิบัติงาน (Active)',
                    value: '${kpi.activeCount}',
                    subtitle: 'เปิดงานแล้วตามเวลา',
                    icon: Icons.play_circle_fill,
                    color: const Color(0xFF059669),
                    backgroundColor: const Color(0xFFD1FAE5),
                    onTap: () => ref.read(ptwFilterProvider.notifier).setStatus(PtwStatus.active),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: PtwKpiCard(
                    title: 'รออนุมัติ (Pending)',
                    value: '${kpi.pendingCount}',
                    subtitle: 'รอ จป./ผู้อนุญาตตรวจ',
                    icon: Icons.pending_actions,
                    color: const Color(0xFFD97706),
                    backgroundColor: const Color(0xFFFEF3C7),
                    onTap: () => ref.read(ptwFilterProvider.notifier).setStatus(PtwStatus.pendingApproval),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: PtwKpiCard(
                    title: 'เกินเวลา (Overdue Alert)',
                    value: '${kpi.overdueCount}',
                    subtitle: 'เกินกำหนดเวลาทำงาน',
                    icon: Icons.alarm_off_rounded,
                    color: const Color(0xFFDC2626),
                    backgroundColor: const Color(0xFFFEE2E2),
                    badgeText: kpi.overdueCount > 0 ? 'แจ้งเตือน' : null,
                    badgeColor: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Secondary High Risk Breakdown Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pie_chart_outline, size: 18, color: Color(0xFF475569)),
                  const SizedBox(width: 8),
                  const Text(
                    'จำแนกตามประเภทงานความเสี่ยงสูง:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildRiskCountChip('Hot Work: ${kpi.hotWorkCount}', const Color(0xFFEA580C)),
                          const SizedBox(width: 8),
                          _buildRiskCountChip('ที่อับอากาศ: ${kpi.confinedSpaceCount}', const Color(0xFF7C3AED)),
                          const SizedBox(width: 8),
                          _buildRiskCountChip('งานบนที่สูง: ${kpi.workingAtHeightCount}', const Color(0xFF0284C7)),
                          const SizedBox(width: 8),
                          _buildRiskCountChip('ไฟฟ้า & LOTO: ${kpi.electricalLotoCount}', const Color(0xFFEAB308)),
                          const SizedBox(width: 8),
                          _buildRiskCountChip('ขุดเจาะ/ยกย้าย: ${kpi.excavationLiftingCount}', const Color(0xFF16A34A)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ความสอดคล้อง: ${kpi.complianceRatePercent.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRiskCountChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(
    BuildContext context,
    WidgetRef ref,
    PtwFilterState filterState,
    AsyncValue<List<String>> departmentsAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: (val) {
                    ref.read(ptwFilterProvider.notifier).setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'ค้นหาเลขที่ PTW, ชื่องาน, สถานที่, ผู้ขออนุญาต...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF0D9488)),
                    suffixIcon: filterState.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => ref.read(ptwFilterProvider.notifier).setSearchQuery(''),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<HighRiskType?>(
                  value: filterState.riskType,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'ประเภทงานความเสี่ยง',
                    labelStyle: const TextStyle(fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('ทุกประเภทงานความเสี่ยง', overflow: TextOverflow.ellipsis)),
                    ...HighRiskType.values.map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(type.icon, size: 14, color: type.color),
                            const SizedBox(width: 6),
                            Expanded(child: Text(type.labelTh, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    ref.read(ptwFilterProvider.notifier).setRiskType(val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<PtwStatus?>(
                  value: filterState.status,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'สถานะใบอนุญาต',
                    labelStyle: const TextStyle(fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('ทุกสถานะใบอนุญาต', overflow: TextOverflow.ellipsis)),
                    ...PtwStatus.values.map(
                      (st) => DropdownMenuItem(
                        value: st,
                        child: Text(st.labelTh, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    ref.read(ptwFilterProvider.notifier).setStatus(val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              if (filterState.isFiltered)
                IconButton(
                  tooltip: 'ล้างตัวกรองทั้งหมด',
                  icon: const Icon(Icons.filter_alt_off_outlined, color: Color(0xFFDC2626)),
                  onPressed: () => ref.read(ptwFilterProvider.notifier).reset(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermitTableAndCards(BuildContext context, WidgetRef ref, List<PtwModel> permits) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: permits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final permit = permits[index];
        return _buildPermitCard(context, ref, permit);
      },
    );
  }

  Widget _buildPermitCard(BuildContext context, WidgetRef ref, PtwModel permit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: permit.isOverdue ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: permit.isOverdue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Primary Risk Icon, PTW Number, Status Chip, Overdue Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: permit.primaryRiskType.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: permit.primaryRiskType.color.withValues(alpha: 0.2)),
                ),
                child: Icon(permit.primaryRiskType.icon, color: permit.primaryRiskType.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          permit.ptwNumber,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        PtwStatusChip(status: permit.status, isCompact: true),
                        const SizedBox(width: 6),
                        HighRiskTypeChip(riskType: permit.primaryRiskType, isCompact: true),
                        if (permit.isOverdue) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFEF4444)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.alarm_off, size: 12, color: Color(0xFFDC2626)),
                                SizedBox(width: 4),
                                Text(
                                  'เกินเวลา (OVERDUE)',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      permit.workTitle,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),
              // View Details Action
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => PtwDetailDialog(
                      ptwNumber: permit.ptwNumber,
                      onPermitUpdated: () {
                        ref.read(ptwListProvider.notifier).refresh();
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('ดูรายละเอียด'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Bottom Meta Row: Location, Time Window, Applicant, Workers
          Wrap(
            spacing: 20,
            runSpacing: 6,
            children: [
              _buildMetaItem(Icons.location_on_outlined, '${permit.plantArea} • ${permit.specificLocation}'),
              _buildMetaItem(Icons.schedule, permit.formattedTimeWindowTh),
              _buildMetaItem(Icons.person_outline, '${permit.applicantName} (${permit.applicantDepartment})'),
              _buildMetaItem(Icons.group_outlined, '${permit.workerCount} คน'),
              if (permit.isConfinedSpaceWork)
                _buildComplianceBadge('4-Roles: ${permit.isConfinedSpaceCompliant ? "ครบ" : "ไม่ครบ"}', permit.isConfinedSpaceCompliant),
              if (permit.isElectricalLotoWork)
                _buildComplianceBadge('LOTO: ${permit.isLotoVerified ? "0V Pass" : "รอทดสอบ"}', permit.isLotoVerified),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  Widget _buildComplianceBadge(String text, bool isSuccess) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 54, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          const Text(
            'ไม่พบรายการใบอนุญาตทำงาน (PTW)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          const Text(
            'ยังไม่มีรายการคำขอในระบบ หรือไม่ตรงกับเงื่อนไขการค้นหา',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreatePermitRequested,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('ยื่นขอใบอนุญาตใหม่ (Create PTW)'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
