import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';

import '../../data/models/cpo_action_item_model.dart';
import '../../data/models/cpo_committee_model.dart';
import '../../domain/enums/cpo_action_status.dart';
import '../../domain/enums/cpo_member_role.dart';
import '../../domain/services/cpo_pdf_generator.dart';
import '../../domain/services/cpo_statutory_evaluator.dart';
import '../providers/cpo_providers.dart';
import '../widgets/cpo_action_item_dialog.dart';
import '../../../risk_assessment/presentation/providers/risk_assessment_providers.dart';

enum CpoPeriodFilter {
  thisMonth,
  lastMonth,
  thisQuarter,
  thisYear,
  allTime,
  custom,
}

class CpoDashboardTab extends ConsumerStatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const CpoDashboardTab({super.key, this.onNavigateToTab});

  @override
  ConsumerState<CpoDashboardTab> createState() => _CpoDashboardTabState();
}

class _CpoDashboardTabState extends ConsumerState<CpoDashboardTab> {
  CpoPeriodFilter _selectedPeriod = CpoPeriodFilter.thisMonth;
  DateTimeRange? _customRange;
  int _detailTab = 0; // 0 = อะไรไม่เสร็จ/งานคั่งค้าง, 1 = งานที่เสร็จแล้ว
  bool _isSyncing = false;

  static const _thaiMonthsShort = [
    '',
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];

  static const _thaiMonthsFull = [
    '',
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];

  String _formatThaiDate(DateTime d) {
    return '${d.day} ${_thaiMonthsShort[d.month]} ${d.year + 543}';
  }

  /// คำนวณช่วงวันที่ตามตัวกรองที่เลือก
  DateTimeRange _resolveDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case CpoPeriodFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case CpoPeriodFilter.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case CpoPeriodFilter.thisQuarter:
        final q = ((now.month - 1) ~/ 3) + 1;
        final startMonth = (q - 1) * 3 + 1;
        final start = DateTime(now.year, startMonth, 1);
        final end = DateTime(now.year, startMonth + 3, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case CpoPeriodFilter.thisYear:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case CpoPeriodFilter.custom:
        if (_customRange != null) return _customRange!;
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case CpoPeriodFilter.allTime:
        return DateTimeRange(start: DateTime(2000, 1, 1), end: DateTime(2100, 12, 31));
    }
  }

  String _getPeriodLabel(DateTimeRange range) {
    switch (_selectedPeriod) {
      case CpoPeriodFilter.thisMonth:
        final now = DateTime.now();
        return 'ประจำเดือน ${_thaiMonthsFull[now.month]} ${now.year + 543} (${_formatThaiDate(range.start)} - ${_formatThaiDate(range.end)})';
      case CpoPeriodFilter.lastMonth:
        final prev = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
        return 'ประจำเดือน ${_thaiMonthsFull[prev.month]} ${prev.year + 543} (${_formatThaiDate(range.start)} - ${_formatThaiDate(range.end)})';
      case CpoPeriodFilter.thisQuarter:
        final q = ((DateTime.now().month - 1) ~/ 3) + 1;
        return 'ไตรมาสที่ $q/${DateTime.now().year + 543} (${_formatThaiDate(range.start)} - ${_formatThaiDate(range.end)})';
      case CpoPeriodFilter.thisYear:
        return 'ประจำปี พ.ศ. ${DateTime.now().year + 543}';
      case CpoPeriodFilter.allTime:
        return 'ข้อมูลสะสมทั้งหมด (All-Time Records)';
      case CpoPeriodFilter.custom:
        return 'ระหว่างวันที่ ${_formatThaiDate(range.start)} ถึง ${_formatThaiDate(range.end)}';
    }
  }

  /// กรอง Action Items ตามช่วงเวลา
  List<CpoActionItemModel> _filterActions(List<CpoActionItemModel> all, DateTimeRange range) {
    if (_selectedPeriod == CpoPeriodFilter.allTime) return all;

    return all.where((a) {
      // ๑. งานที่เสร็จแล้ว ให้ดูจาก completedDate หรือ updatedAt หรือ createdAt
      if (a.status == CpoActionStatus.completed) {
        final dateStr = a.completedDate ?? a.updatedAt?.substring(0, 10) ?? a.createdAt?.substring(0, 10);
        if (dateStr != null) {
          final dt = DateTime.tryParse(dateStr);
          if (dt != null) {
            return dt.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
                dt.isBefore(range.end.add(const Duration(seconds: 1)));
          }
        }
        return true;
      }

      // ๒. งานที่ยังไม่เสร็จ (Pending/InProgress/Overdue):
      // ถือว่าอยู่ในช่วงการติดตามถ้างวดที่เลือกทับซ้อนกับอายุของงาน
      final createdStr = a.createdAt?.substring(0, 10);
      final createdDt = createdStr != null ? DateTime.tryParse(createdStr) : null;
      if (createdDt != null && createdDt.isAfter(range.end)) {
        return false; // งานนี้สร้างหลังช่วงเวลานี้
      }

      return true;
    }).toList();
  }

  void _printReport(List<CpoActionItemModel> actions, String periodLabel, CpoTermModel? term) async {
    final companyProfile = ref.read(companyProfileNotifierProvider).asData?.value;
    final companyName = companyProfile?.companyName ?? 'สถานประกอบกิจการ';
    final logoPath = companyProfile?.logoPath;

    final secretary = term?.members
            .where((m) => m.cpoRole == CpoMemberRole.secretary)
            .firstOrNull
            ?.fullName ??
        companyProfile?.safetyOfficerName ??
        'เลขานุการ คปอ.';

    final chairman = term?.members
            .where((m) => m.cpoRole == CpoMemberRole.chair)
            .firstOrNull
            ?.fullName ??
        companyProfile?.employerName ??
        'ประธาน คปอ.';

    await Printing.layoutPdf(
      name: 'CPO_Action_Tracking_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      onLayout: (format) => CpoPdfGenerator.generateActionTrackingReportPdf(
        allActions: actions,
        periodLabel: periodLabel,
        companyName: companyName,
        logoPath: logoPath,
        term: term,
        secretaryName: secretary,
        chairmanName: chairman,
      ),
    );
  }

  void _autoSyncAgendas() async {
    setState(() => _isSyncing = true);
    try {
      final count = await ref.read(cpoActionItemsProvider.notifier).autoSyncFromAgendas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? '⚡ ดึงและอัปเดตมติจากวาระที่ ๔-๕ สำเร็จ $count รายการ'
                : '✅ ข้อมูลมติที่ประชุมใน Action Items เป็นปัจจุบันแล้ว (ไม่มีรายการใหม่)',
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการดึงมติ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(cpoDashboardSummaryProvider);
    final allActionsAsync = ref.watch(cpoActionItemsProvider);

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
      data: (summaryData) {
        final activeTerm = summaryData['active_term'] as CpoTermModel?;
        final compliance = summaryData['compliance_result'] as CpoComplianceResult?;
        final frequency = summaryData['frequency_result'] as Map<String, dynamic>?;
        final monthlyStats = summaryData['monthly_safety_stats'] as Map<String, dynamic>? ?? {};

        final completedMeetings = frequency?['completed_count'] as int? ?? 0;
        final targetMeetings = frequency?['target_count'] as int? ?? 12;

        return allActionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('เกิดข้อผิดพลาดในการโหลดรายการงาน: $e')),
          data: (allActions) {
            final range = _resolveDateRange();
            final periodLabel = _getPeriodLabel(range);
            final filteredActions = _filterActions(allActions, range);

            // คำนวณสถิติงานในงวด
            final totalCount = filteredActions.length;
            final completedActions = filteredActions.where((a) => a.status == CpoActionStatus.completed).toList();
            final inProgressActions = filteredActions.where((a) => a.status == CpoActionStatus.inProgress).toList();
            final pendingActions = filteredActions.where((a) => a.status == CpoActionStatus.pending).toList();
            final overdueActions = filteredActions.where((a) => a.isOverdue).toList();
            final unfinishedActions = filteredActions
                .where((a) => a.status != CpoActionStatus.completed && a.status != CpoActionStatus.cancelled)
                .toList();

            // เรียงงานค้าง: เกินกำหนดขึ้นก่อน แล้วตามด้วยวันกำหนดส่ง
            unfinishedActions.sort((a, b) {
              if (a.isOverdue && !b.isOverdue) return -1;
              if (!a.isOverdue && b.isOverdue) return 1;
              return a.dueDate.compareTo(b.dueDate);
            });

            final completionRate = totalCount > 0 ? (completedActions.length / totalCount) * 100.0 : 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ๑. Header Banner & Action Buttons
                  _buildHeaderBanner(activeTerm, filteredActions, periodLabel),
                  const SizedBox(height: 18),

                  // ๒. แถบเลือกระยะเวลา (Period Filter Bar)
                  _buildPeriodFilterBar(range),
                  const SizedBox(height: 18),

                  // ๓. การ์ดสถิติ ๕ กล่องหลัก (เสร็จกี่งาน / อะไรไม่เสร็จ)
                  _buildKpiMetricsRow(
                    totalCount: totalCount,
                    completedCount: completedActions.length,
                    inProgressCount: inProgressActions.length,
                    pendingCount: pendingActions.length,
                    overdueCount: overdueActions.length,
                    completionRate: completionRate,
                  ),
                  const SizedBox(height: 20),

                  // ๔. กราฟิกวิเคราะห์ผล (Donut Chart & Priority Breakdown)
                  _buildChartsSection(
                    completedCount: completedActions.length,
                    inProgressCount: inProgressActions.length,
                    pendingCount: pendingActions.length,
                    overdueCount: overdueActions.length,
                    completionRate: completionRate,
                    totalCount: totalCount,
                    filteredActions: filteredActions,
                  ),
                  const SizedBox(height: 24),

                  // ๕. รายการแจกแจงละเอียด: "อะไรไม่เสร็จ" vs "งานที่เสร็จสิ้น"
                  _buildDetailedTasksSection(
                    unfinishedActions: unfinishedActions,
                    completedActions: completedActions,
                  ),
                  const SizedBox(height: 24),

                  // ๖. แถบสรุปสัดส่วน คปอ. & ความถี่ประชุมตามกฎหมาย (Statutory OSH Summary)
                  _buildStatutorySummaryStrip(
                    compliance: compliance,
                    completedMeetings: completedMeetings,
                    targetMeetings: targetMeetings,
                    monthlyStats: monthlyStats,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // ๑. Header Banner with Direct Print & Sync Buttons
  // ---------------------------------------------------------------------------
  Widget _buildHeaderBanner(CpoTermModel? activeTerm, List<CpoActionItemModel> actions, String periodLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E3A8A).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ศูนย์ติดตามงานและมติที่ประชุม คปอ. (Action Tracking & Performance)',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeTerm != null
                          ? 'วาระปัจจุบัน: ${activeTerm.termTitle} (${activeTerm.startDate} ถึง ${activeTerm.endDate}) • คงเหลือ ${activeTerm.remainingDays} วัน'
                          : 'ยังไม่ได้จัดตั้งวาระ คปอ. (คลิกเพื่อจัดตั้งตามกฎหมาย)',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Action Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // ปุ่มดึงมติอัตโนมัติ
                  ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _autoSyncAgendas,
                    icon: _isSyncing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.bolt, size: 18),
                    label: const Text('ดึงมติวาระ ๔-๕', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                  ),

                  // ปุ่มพิมพ์รายงาน
                  ElevatedButton.icon(
                    onPressed: () => _printReport(actions, periodLabel, activeTerm),
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('พิมพ์รายงานสรุป (PDF)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 3,
                    ),
                  ),

                  // ปุ่มเพิ่มงานใหม่
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const CpoActionItemDialog(),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('เพิ่มงาน', style: TextStyle(color: Colors.white, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ๒. Period Filter Bar
  // ---------------------------------------------------------------------------
  Widget _buildPeriodFilterBar(DateTimeRange activeRange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range_rounded, color: Color(0xFF1E3A8A), size: 20),
          const SizedBox(width: 8),
          const Text('เลือกระยะเวลา:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip('เดือนนี้ (ค่าเริ่มต้น)', CpoPeriodFilter.thisMonth),
                  const SizedBox(width: 8),
                  _buildPeriodChip('เดือนที่แล้ว', CpoPeriodFilter.lastMonth),
                  const SizedBox(width: 8),
                  _buildPeriodChip('ไตรมาสนี้', CpoPeriodFilter.thisQuarter),
                  const SizedBox(width: 8),
                  _buildPeriodChip('ปีนี้', CpoPeriodFilter.thisYear),
                  const SizedBox(width: 8),
                  _buildPeriodChip('ทั้งหมด (All-Time)', CpoPeriodFilter.allTime),
                  const SizedBox(width: 8),
                  _buildCustomDateChip(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Badge แสดงช่วงวันที่จริง
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event, size: 14, color: Color(0xFF0284C7)),
                const SizedBox(width: 6),
                Text(
                  _selectedPeriod == CpoPeriodFilter.allTime
                      ? 'สะสมทั้งหมด'
                      : '${_formatThaiDate(activeRange.start)} - ${_formatThaiDate(activeRange.end)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, CpoPeriodFilter filter) {
    final isSelected = _selectedPeriod == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedPeriod = filter);
      },
      selectedColor: const Color(0xFF1E3A8A),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : Colors.grey.shade800,
      ),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300, width: 0.8),
    );
  }

  Widget _buildCustomDateChip() {
    final isSelected = _selectedPeriod == CpoPeriodFilter.custom;
    return ActionChip(
      avatar: const Icon(Icons.edit_calendar, size: 16),
      label: Text(_customRange != null ? 'กำหนดเอง (${_customRange!.duration.inDays + 1} วัน)' : 'กำหนดช่วงวันที่...'),
      backgroundColor: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : Colors.grey.shade800,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300, width: 0.8),
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
          initialDateRange: _customRange ?? DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
          helpText: 'เลือกช่วงวันที่สำหรับติดตามผลงาน คปอ.',
          cancelText: 'ยกเลิก',
          confirmText: 'ตกลง',
        );
        if (picked != null) {
          setState(() {
            _customRange = picked;
            _selectedPeriod = CpoPeriodFilter.custom;
          });
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // ๓. 5 Main KPI Cards (งานสถิติ: เดือนนี้เสร็จกี่งาน อะไรไม่เสร็จ)
  // ---------------------------------------------------------------------------
  Widget _buildKpiMetricsRow({
    required int totalCount,
    required int completedCount,
    required int inProgressCount,
    required int pendingCount,
    required int overdueCount,
    required double completionRate,
  }) {
    return Row(
      children: [
        // ๑. งานทั้งหมด
        Expanded(
          child: _buildMetricTile(
            title: 'งานทั้งหมดในงวด',
            value: '$totalCount',
            unit: 'รายการ',
            subtitle: 'มติที่ต้องดำเนินการ',
            color: const Color(0xFF334155),
            icon: Icons.assignment_outlined,
          ),
        ),
        const SizedBox(width: 12),

        // ๒. เสร็จแล้ว (เสร็จกี่งาน)
        Expanded(
          child: _buildMetricTile(
            title: 'ดำเนินการเสร็จสิ้น',
            value: '$completedCount',
            unit: 'รายการ',
            subtitle: 'สำเร็จ ${completionRate.toStringAsFixed(1)}%',
            color: const Color(0xFF16A34A),
            icon: Icons.check_circle_outline,
            isHighlighted: true,
          ),
        ),
        const SizedBox(width: 12),

        // ๓. กำลังดำเนินการ
        Expanded(
          child: _buildMetricTile(
            title: 'กำลังดำเนินการ',
            value: '$inProgressCount',
            unit: 'รายการ',
            subtitle: 'อยู่ระหว่างแก้ไข/จัดทำ',
            color: const Color(0xFF0284C7),
            icon: Icons.pending_actions,
          ),
        ),
        const SizedBox(width: 12),

        // ๔. รอดำเนินการ
        Expanded(
          child: _buildMetricTile(
            title: 'รอดำเนินการ',
            value: '$pendingCount',
            unit: 'รายการ',
            subtitle: 'ยังไม่เริ่มลงมือ',
            color: const Color(0xFFD97706),
            icon: Icons.hourglass_empty_rounded,
          ),
        ),
        const SizedBox(width: 12),

        // ๕. งานเกินกำหนด / ล่าช้า (อะไรไม่เสร็จ)
        Expanded(
          child: _buildMetricTile(
            title: 'เกินกำหนด / ล่าช้า',
            value: '$overdueCount',
            unit: 'รายการ',
            subtitle: overdueCount > 0 ? '⚠️ ต้องเร่งติดตามด่วน!' : 'ไม่มีงานล่าช้า',
            color: overdueCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
            icon: Icons.warning_amber_rounded,
            alert: overdueCount > 0,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required Color color,
    required IconData icon,
    bool isHighlighted = false,
    bool alert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alert ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alert ? const Color(0xFFEF4444) : (isHighlighted ? color.withValues(alpha: 0.3) : Colors.grey.shade200),
          width: alert ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(width: 6),
              Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: alert ? FontWeight.bold : FontWeight.normal,
              color: alert ? const Color(0xFFDC2626) : Colors.grey.shade500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ๔. Visual Charts Section (Donut Chart & Priority Breakdown)
  // ---------------------------------------------------------------------------
  Widget _buildChartsSection({
    required int completedCount,
    required int inProgressCount,
    required int pendingCount,
    required int overdueCount,
    required double completionRate,
    required int totalCount,
    required List<CpoActionItemModel> filteredActions,
  }) {
    // นับตามระดับความสำคัญ
    final urgentTotal = filteredActions.where((a) => a.priority == 'URGENT').length;
    final urgentDone = filteredActions.where((a) => a.priority == 'URGENT' && a.status == CpoActionStatus.completed).length;

    final highTotal = filteredActions.where((a) => a.priority == 'HIGH').length;
    final highDone = filteredActions.where((a) => a.priority == 'HIGH' && a.status == CpoActionStatus.completed).length;

    final medTotal = filteredActions.where((a) => a.priority == 'MEDIUM').length;
    final medDone = filteredActions.where((a) => a.priority == 'MEDIUM' && a.status == CpoActionStatus.completed).length;

    final lowTotal = filteredActions.where((a) => a.priority == 'LOW').length;
    final lowDone = filteredActions.where((a) => a.priority == 'LOW' && a.status == CpoActionStatus.completed).length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // กราฟที่ ๑: สัดส่วนสถานะงาน (Donut Chart)
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF1E3A8A), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text('สัดส่วนสถานะงาน (Task Status Breakdown)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Text('รวม $totalCount รายการ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Donut Chart
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 48,
                              sections: totalCount == 0
                                  ? [
                                      PieChartSectionData(
                                        color: Colors.grey.shade200,
                                        value: 1,
                                        showTitle: false,
                                        radius: 20,
                                      ),
                                    ]
                                  : [
                                      if (completedCount > 0)
                                        PieChartSectionData(
                                          color: const Color(0xFF16A34A),
                                          value: completedCount.toDouble(),
                                          title: '$completedCount',
                                          radius: 24,
                                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      if (inProgressCount > 0)
                                        PieChartSectionData(
                                          color: const Color(0xFF0284C7),
                                          value: inProgressCount.toDouble(),
                                          title: '$inProgressCount',
                                          radius: 24,
                                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      if (pendingCount > 0)
                                        PieChartSectionData(
                                          color: const Color(0xFFD97706),
                                          value: pendingCount.toDouble(),
                                          title: '$pendingCount',
                                          radius: 24,
                                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      if (overdueCount > 0)
                                        PieChartSectionData(
                                          color: const Color(0xFFDC2626),
                                          value: overdueCount.toDouble(),
                                          title: '$overdueCount',
                                          radius: 28,
                                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                    ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${completionRate.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: completionRate >= 80 ? const Color(0xFF16A34A) : const Color(0xFF1E3A8A),
                                ),
                              ),
                              Text('ปิดงานสำเร็จ', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Legend Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendRow('ดำเนินการเสร็จสิ้น (Completed)', completedCount, totalCount, const Color(0xFF16A34A)),
                          const SizedBox(height: 8),
                          _buildLegendRow('กำลังดำเนินการ (In Progress)', inProgressCount, totalCount, const Color(0xFF0284C7)),
                          const SizedBox(height: 8),
                          _buildLegendRow('รอดำเนินการ (Pending)', pendingCount, totalCount, const Color(0xFFD97706)),
                          const SizedBox(height: 8),
                          _buildLegendRow('เกินกำหนด / ล่าช้า (Overdue)', overdueCount, totalCount, const Color(0xFFDC2626)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // กราฟที่ ๒: จำแนกตามระดับความสำคัญ (Priority Progress Breakdown)
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: const Color(0xFFD97706).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.bar_chart_rounded, color: Color(0xFFD97706), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text('การปิดงานตามระดับความสำคัญ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPriorityBar('🔴 ด่วนมาก (URGENT)', urgentDone, urgentTotal, const Color(0xFFDC2626)),
                const SizedBox(height: 12),
                _buildPriorityBar('🟠 ความสำคัญสูง (HIGH)', highDone, highTotal, const Color(0xFFEA580C)),
                const SizedBox(height: 12),
                _buildPriorityBar('🟡 ปานกลาง (MEDIUM)', medDone, medTotal, const Color(0xFFD97706)),
                const SizedBox(height: 12),
                _buildPriorityBar('🟢 ทั่วไป (LOW)', lowDone, lowTotal, const Color(0xFF16A34A)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendRow(String label, int count, int total, Color color) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        const SizedBox(width: 6),
        Text('($pct%)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildPriorityBar(String label, int done, int total, Color color) {
    final progress = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('สำเร็จ $done จาก $total รายการ', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ๕. รายการแจกแจงละเอียด: "อะไรไม่เสร็จ" vs "งานที่เสร็จสิ้น"
  // ---------------------------------------------------------------------------
  Widget _buildDetailedTasksSection({
    required List<CpoActionItemModel> unfinishedActions,
    required List<CpoActionItemModel> completedActions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-Tab Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                // Tab 0: อะไรไม่เสร็จ
                InkWell(
                  onTap: () => setState(() => _detailTab = 0),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _detailTab == 0 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: _detailTab == 0 ? Border.all(color: Colors.grey.shade300) : null,
                      boxShadow: _detailTab == 0 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)] : null,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 18, color: unfinishedActions.isNotEmpty ? const Color(0xFFDC2626) : Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'รายการที่ยังไม่แล้วเสร็จ / คั่งค้าง (อะไรไม่เสร็จ)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _detailTab == 0 ? const Color(0xFFDC2626) : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: unfinishedActions.isNotEmpty ? const Color(0xFFFEE2E2) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${unfinishedActions.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: unfinishedActions.isNotEmpty ? const Color(0xFFDC2626) : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tab 1: งานที่เสร็จแล้ว
                InkWell(
                  onTap: () => setState(() => _detailTab = 1),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _detailTab == 1 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: _detailTab == 1 ? Border.all(color: Colors.grey.shade300) : null,
                      boxShadow: _detailTab == 1 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)] : null,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        Text(
                          'รายการที่ดำเนินการแล้วเสร็จในงวด',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _detailTab == 1 ? const Color(0xFF16A34A) : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${completedActions.length}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sub-Tab Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: _detailTab == 0
                ? _buildUnfinishedList(unfinishedActions)
                : _buildCompletedList(completedActions),
          ),
        ],
      ),
    );
  }

  Widget _buildUnfinishedList(List<CpoActionItemModel> items) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Column(
          children: const [
            Icon(Icons.task_alt, color: Color(0xFF16A34A), size: 42),
            SizedBox(height: 8),
            Text('ยอดเยี่ยมมาก! ไม่มีงานคั่งค้างในรอบเวลานี้', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
            SizedBox(height: 4),
            Text('มติการประชุมและข้อสั่งการ คปอ. ได้รับการแก้ไขและปิดงานครบถ้วน ๑๐๐%', style: TextStyle(fontSize: 12, color: Color(0xFF166534))),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final isOver = item.isOverdue;

        // คำนวณวันเกินกำหนด หรือวันที่เหลือ
        String dueNotice = '';
        Color noticeColor = Colors.grey.shade700;
        try {
          final due = DateTime.parse(item.dueDate);
          final diff = due.difference(DateTime.now()).inDays;
          if (isOver) {
            dueNotice = 'เกินกำหนด ${diff.abs()} วัน!';
            noticeColor = const Color(0xFFDC2626);
          } else if (diff == 0) {
            dueNotice = 'ครบกำหนดวันนี้!';
            noticeColor = const Color(0xFFEA580C);
          } else {
            dueNotice = 'เหลือเวลาอีก $diff วัน';
            noticeColor = const Color(0xFF0284C7);
          }
        } catch (_) {}

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isOver ? const Color(0xFFFEF2F2).withValues(alpha: 0.6) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isOver ? const Color(0xFFFCA5A5) : Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Code, Agenda Origin, Priority, Due Notice
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(item.itemCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('วาระที่ ${item.agendaNo}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                  ),
                  const SizedBox(width: 8),
                  _buildPriorityTag(item.priority),
                  const Spacer(),
                  // Badge แจ้งเตือนวัน
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: noticeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: noticeColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isOver ? Icons.warning_amber_rounded : Icons.schedule, size: 14, color: noticeColor),
                        const SizedBox(width: 4),
                        Text(dueNotice, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: noticeColor)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 2: Title & Action Detail
              Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              if (item.actionDetail.isNotEmpty && item.actionDetail != item.title) ...[
                const SizedBox(height: 4),
                Text(item.actionDetail, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
              const SizedBox(height: 12),

              // Row 3: Assignee, Due Date, Progress, Edit button
              Row(
                children: [
                  // ผู้รับผิดชอบ
                  Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${item.responsiblePerson}${item.department?.isNotEmpty == true ? ' (${item.department})' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                  const SizedBox(width: 16),

                  // กำหนดส่ง
                  Icon(Icons.calendar_today_outlined, size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('กำหนดเสร็จ: ${item.dueDate}', style: TextStyle(fontSize: 12, color: isOver ? const Color(0xFFDC2626) : Colors.grey.shade800)),
                  const Spacer(),

                  // หลอด Progress Bar
                  SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('คืบหน้า ${item.progressPercent}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: (item.progressPercent / 100.0).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(isOver ? const Color(0xFFDC2626) : const Color(0xFF0284C7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // ปุ่มอัปเดตความคืบหน้า
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => CpoActionItemDialog(existingItem: item),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('อัปเดตสถานะ', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildCompletedList(List<CpoActionItemModel> items) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, color: Colors.grey.shade400, size: 40),
            const SizedBox(height: 8),
            Text('ยังไม่มีงานที่บันทึกว่าแล้วเสร็จในรอบเวลานี้', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(item.itemCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF16A34A))),
                        const SizedBox(width: 8),
                        Text('วาระที่ ${item.agendaNo}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        const Spacer(),
                        Text(
                          'เสร็จเมื่อ: ${item.completedDate ?? item.updatedAt?.substring(0, 10) ?? "-"}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    if (item.resolutionNotes?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text('ผลการดำเนินงาน: ${item.resolutionNotes}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                    const SizedBox(height: 8),
                    Text('ผู้รับผิดชอบ: ${item.responsiblePerson} ${item.department != null ? "(${item.department})" : ""}',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => CpoActionItemDialog(existingItem: item),
                  );
                },
                tooltip: 'ดูรายละเอียดงาน',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriorityTag(String priority) {
    Color bg;
    Color fg;
    String label;
    switch (priority) {
      case 'URGENT':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = 'ด่วนมาก';
        break;
      case 'HIGH':
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFFEA580C);
        label = 'สูง';
        break;
      case 'MEDIUM':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'ปานกลาง';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        label = 'ทั่วไป';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  // ---------------------------------------------------------------------------
  // ๖. แถบสรุปสัดส่วน คปอ. & ความถี่ประชุมตามกฎหมาย (Statutory OSH Strip)
  // ---------------------------------------------------------------------------
  Widget _buildStatutorySummaryStrip({
    required CpoComplianceResult? compliance,
    required int completedMeetings,
    required int targetMeetings,
    required Map<String, dynamic> monthlyStats,
  }) {
    final quotaPass = compliance?.isCompliant == true;
    final meetingPass = completedMeetings >= targetMeetings;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.shield_outlined, color: Color(0xFF1E3A8A), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('สถานะความสอดคล้องตามกฎกระทรวง จป./คปอ. พ.ศ. ๒๕๖๕', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  'สัดส่วนกรรมการ: ${compliance?.actualTotal ?? 0}/${compliance?.requiredTotal ?? 5} คน (${quotaPass ? "ผ่านเกณฑ์" : "ยังไม่ครบ"}) • การประชุม: $completedMeetings/$targetMeetings ครั้ง (${meetingPass ? "ครบถ้วน" : "เป้าหมาย ๑ ครั้ง/เดือน"})',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Cross-module data summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.sync_alt, size: 14, color: Color(0xFF0284C7)),
                const SizedBox(width: 6),
                Text(
                  'ข้อมูลเชื่อมโยง: อุบัติเหตุ ${monthlyStats["incident_count"] ?? 0} • Near-miss ${monthlyStats["near_miss_count"] ?? 0} • PTW ${monthlyStats["ptw_count"] ?? 0}',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
