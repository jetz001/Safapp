import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/models/legal_compliance_stats_model.dart';
import '../../domain/models/legal_master_item_model.dart';
import '../providers/legal_register_providers.dart';

/// KPI Dashboard displaying comprehensive compliance statistics for the SAFAPP Legal Register:
/// - Basic Compliance Percentage (CI %)
/// - Risk-Weighted Compliance Percentage (WCI %)
/// - Circular / Radial Chart Visualizer
/// - Status count metrics (Compliant, Non-Compliant, In-Progress, N/A)
/// - CAPA Action Plan counters (Open CAPA, Overdue CAPA)
/// - High-Risk Non-Compliance Alert Banner
/// - 8 Statutory Categories Breakdown Cards
class LegalKpiDashboard extends ConsumerStatefulWidget {
  final VoidCallback? onResetFilter;

  const LegalKpiDashboard({
    Key? key,
    this.onResetFilter,
  }) : super(key: key);

  @override
  ConsumerState<LegalKpiDashboard> createState() => _LegalKpiDashboardState();
}

class _LegalKpiDashboardState extends ConsumerState<LegalKpiDashboard> {
  bool _showCategoryBreakdown = false;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(legalComplianceKpiProvider);
    final activeStatus = ref.watch(legalStatusFilterProvider);
    final activeCategory = ref.watch(legalCategoryFilterProvider);

    return statsAsync.when(
      data: (stats) => _buildDashboard(context, stats, activeStatus, activeCategory),
      loading: () => _buildLoadingCard(),
      error: (err, stack) => _buildErrorCard(err.toString()),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: SizedBox(
          height: 36,
          width: 36,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF87171)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ไม่สามารถโหลดสถิติความสอดคล้องทางกฎหมายได้: $error',
              style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(legalComplianceKpiProvider),
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    LegalComplianceStatsModel stats,
    String activeStatus,
    String activeCategory,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final basicPct = stats.basicCompliancePercent;
    final weightedPct = stats.riskWeightedCompliancePercent;
    final openCapas = stats.pendingCapaCount + stats.inProgressCapaCount;

    Color basicColor;
    if (basicPct >= 90) {
      basicColor = const Color(0xFF10B981);
    } else if (basicPct >= 75) {
      basicColor = const Color(0xFFF59E0B);
    } else {
      basicColor = const Color(0xFFEF4444);
    }

    Color weightedColor;
    if (weightedPct >= 90) {
      weightedColor = const Color(0xFF0D9488);
    } else if (weightedPct >= 75) {
      weightedColor = const Color(0xFFD97706);
    } else {
      weightedColor = const Color(0xFFDC2626);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header & High-Risk Alert
          if (stats.highRiskNonCompliantCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(19),
                  topRight: Radius.circular(19),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'แจ้งเตือนสำคัญ: พบข้อกำหนดกฎหมายที่มีความเสี่ยงสูง (High Risk) ไม่สอดคล้อง ${stats.highRiskNonCompliantCount} รายการ ต้องเร่งจัดทำ CAPA ทันที!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      ref.read(legalStatusFilterProvider.notifier).state = 'NON_COMPLIANT';
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ดูรายการ',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Color(0xFF0D9488),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ดัชนีชี้วัดความสอดคล้องทางกฎหมาย (Legal Compliance KPIs)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ครอบคลุมกฎกระทรวงความปลอดภัย ๘ ฉบับหลัก (รวม ${stats.totalItems} ข้อกำหนด, ประเมินแล้ว ${stats.applicableItems} ข้อที่เกี่ยวข้อง)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message: 'คำนวณตามมาตรฐานสากล: \n'
                          '1. Basic CI = (สอดคล้อง / ที่เกี่ยวข้อง) x 100%\n'
                          '2. Risk-Weighted WCI = ถ่วงน้ำหนักตามระดับความเสี่ยง (High=3, Medium=2, Low=1)',
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Dual KPI Gauges & Breakdown Card
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 650;
                    if (isNarrow) {
                      return Column(
                        children: [
                          _buildGaugeCard(
                            title: 'ความสอดคล้องพื้นฐาน (CI)',
                            subtitle: 'Basic Compliance Index',
                            percent: basicPct,
                            color: basicColor,
                            compliantCount: stats.compliantCount,
                            applicableCount: stats.applicableItems,
                            icon: Icons.fact_check_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildGaugeCard(
                            title: 'ความสอดคล้องถ่วงน้ำหนักความเสี่ยง (WCI)',
                            subtitle: 'Risk-Weighted Compliance Index',
                            percent: weightedPct,
                            color: weightedColor,
                            compliantCount: stats.compliantCount,
                            applicableCount: stats.applicableItems,
                            icon: Icons.shield_rounded,
                            isWeighted: true,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: _buildGaugeCard(
                            title: 'ความสอดคล้องพื้นฐาน (CI)',
                            subtitle: 'Basic Compliance Index',
                            percent: basicPct,
                            color: basicColor,
                            compliantCount: stats.compliantCount,
                            applicableCount: stats.applicableItems,
                            icon: Icons.fact_check_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildGaugeCard(
                            title: 'ความสอดคล้องถ่วงน้ำหนักความเสี่ยง (WCI)',
                            subtitle: 'Risk-Weighted Compliance Index',
                            percent: weightedPct,
                            color: weightedColor,
                            compliantCount: stats.compliantCount,
                            applicableCount: stats.applicableItems,
                            icon: Icons.shield_rounded,
                            isWeighted: true,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),

                // Interactive Status Count Chips
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildMetricChip(
                      label: 'สอดคล้อง (Compliant)',
                      count: stats.compliantCount,
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFFECFDF5),
                      icon: Icons.check_circle_rounded,
                      isActive: activeStatus == 'COMPLIANT',
                      onTap: () {
                        final next = activeStatus == 'COMPLIANT' ? 'ALL' : 'COMPLIANT';
                        ref.read(legalStatusFilterProvider.notifier).state = next;
                      },
                    ),
                    _buildMetricChip(
                      label: 'ไม่สอดคล้อง (Non-Compliant)',
                      count: stats.nonCompliantCount,
                      color: const Color(0xFFEF4444),
                      bgColor: const Color(0xFFFEF2F2),
                      icon: Icons.cancel_rounded,
                      isActive: activeStatus == 'NON_COMPLIANT',
                      onTap: () {
                        final next = activeStatus == 'NON_COMPLIANT' ? 'ALL' : 'NON_COMPLIANT';
                        ref.read(legalStatusFilterProvider.notifier).state = next;
                      },
                    ),
                    _buildMetricChip(
                      label: 'อยู่ระหว่างดำเนินการ (In-Progress)',
                      count: stats.inProgressCount,
                      color: const Color(0xFFF59E0B),
                      bgColor: const Color(0xFFFFFBEB),
                      icon: Icons.pending_actions_rounded,
                      isActive: activeStatus == 'IN_PROGRESS',
                      onTap: () {
                        final next = activeStatus == 'IN_PROGRESS' ? 'ALL' : 'IN_PROGRESS';
                        ref.read(legalStatusFilterProvider.notifier).state = next;
                      },
                    ),
                    _buildMetricChip(
                      label: 'ไม่เกี่ยวข้อง (N/A)',
                      count: stats.notApplicableCount,
                      color: const Color(0xFF6B7280),
                      bgColor: const Color(0xFFF3F4F6),
                      icon: Icons.do_not_disturb_on_rounded,
                      isActive: activeStatus == 'NOT_APPLICABLE',
                      onTap: () {
                        final next = activeStatus == 'NOT_APPLICABLE' ? 'ALL' : 'NOT_APPLICABLE';
                        ref.read(legalStatusFilterProvider.notifier).state = next;
                      },
                    ),
                    _buildMetricChip(
                      label: 'CAPA รอแก้ไข (Open)',
                      count: openCapas,
                      color: const Color(0xFF3B82F6),
                      bgColor: const Color(0xFFEFF6FF),
                      icon: Icons.assignment_late_rounded,
                      isActive: false,
                      onTap: () {
                        // Switch to CAPA tab
                        ref.read(legalSelectedTabProvider.notifier).state = 2;
                        ref.read(legalCapaStatusFilterProvider.notifier).state = 'PENDING';
                      },
                    ),
                    if (stats.overdueCapaCount > 0)
                      _buildMetricChip(
                        label: 'CAPA เกินกำหนด (Overdue)',
                        count: stats.overdueCapaCount,
                        color: const Color(0xFFDC2626),
                        bgColor: const Color(0xFFFEF2F2),
                        icon: Icons.warning_rounded,
                        isActive: false,
                        onTap: () {
                          // Switch to CAPA tab with Overdue filter
                          ref.read(legalSelectedTabProvider.notifier).state = 2;
                          ref.read(legalCapaStatusFilterProvider.notifier).state = 'OVERDUE';
                        },
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Toggle 8 Categories Breakdown
                InkWell(
                  onTap: () {
                    setState(() {
                      _showCategoryBreakdown = !_showCategoryBreakdown;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showCategoryBreakdown
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: const Color(0xFF0D9488),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showCategoryBreakdown
                              ? 'ซ่อนรายละเอียดแยกตาม ๘ กฎหมาย'
                              : 'ดูความสอดคล้องแยกตาม ๘ กฎหมายราชกิจจานุเบกษา',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0D9488),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showCategoryBreakdown) ...[
                  const SizedBox(height: 14),
                  _buildCategoriesGrid(stats.categoryBreakdown, activeCategory),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeCard({
    required String title,
    required String subtitle,
    required double percent,
    required Color color,
    required int compliantCount,
    required int applicableCount,
    required IconData icon,
    bool isWeighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Circular Progress Pie
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: 270,
                    sectionsSpace: 0,
                    centerSpaceRadius: 24,
                    sections: [
                      PieChartSectionData(
                        value: percent,
                        color: color,
                        radius: 8,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: 100.0 - percent,
                        color: color.withValues(alpha: 0.15),
                        radius: 8,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isWeighted
                            ? 'ดัชนีความเสี่ยง WCI: ${percent.toStringAsFixed(1)}%'
                            : 'สอดคล้อง $compliantCount จาก $applicableCount ข้อ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(
    List<CategoryComplianceStats> breakdown,
    String activeCategory,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 550 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.3,
          ),
          itemCount: breakdown.length,
          itemBuilder: (context, index) {
            final item = breakdown[index];
            final catEnum = item.categoryEnum;
            final isSelected = activeCategory == item.category;

            return InkWell(
              onTap: () {
                final next = isSelected ? 'ALL' : item.category;
                ref.read(legalCategoryFilterProvider.notifier).state = next;
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? catEnum.primaryColor.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? catEnum.primaryColor
                        : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(catEnum.icon, size: 16, color: catEnum.primaryColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.categoryTitleTh,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? catEnum.primaryColor
                                  : Colors.grey.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${item.basicCompliancePercent.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: item.basicCompliancePercent >= 80
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item.applicableItems > 0
                            ? (item.compliantCount / item.applicableItems)
                            : 1.0,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          item.basicCompliancePercent >= 80
                              ? const Color(0xFF10B981)
                              : (item.basicCompliancePercent >= 50
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFEF4444)),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'สอดคล้อง: ${item.compliantCount}/${item.applicableItems}',
                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                        ),
                        if (item.nonCompliantCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ไม่ผ่าน ${item.nonCompliantCount}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
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
    );
  }
}
