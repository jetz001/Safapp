import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/constants/app_routes.dart';
import '../../domain/models/dashboard_models.dart';
import '../providers/dashboard_providers.dart';

class DashboardPage extends ConsumerStatefulWidget {
  final Function(int index)? onNavigate;

  const DashboardPage({super.key, this.onNavigate});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final currentMetric = ref.watch(dashboardChartMetricProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'ภาพรวมความปลอดภัย (Safety Dashboard)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: Color(0xFF1E293B)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => ref.refresh(dashboardDataProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF1E3A8A)),
            label: const Text('อัปเดตข้อมูลสด', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
        ),
        error: (err, stack) => Center(
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text('ไม่สามารถโหลดข้อมูลแดชบอร์ดได้: $err', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(dashboardDataProvider),
                  child: const Text('ลองใหม่'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Sub-header with factory context ──────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.business_rounded, size: 16, color: Color(0xFF1E3A8A)),
                          const SizedBox(width: 6),
                          Text(
                            data.companyName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text(
                            'เกณฑ์ลูกจ้างรวม ${data.kpi.totalWorkforce} คน (SMS บัญชี ๒)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── TIER 1: Leading & Lagging Indicators Bar ─────────────
                _buildLeadingLaggingKpis(data.kpi),
                const SizedBox(height: 32),

                // ── TIER 2: Cross-Module Operational Grid ─────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'สถานะการดำเนินงานข้ามโมดูล (Cross-Module Operations)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      'คลิกที่การ์ดเพื่อเปิดดูและจัดการในโมดูลนั้นทันที',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModuleGrid(data.moduleSummaries),
                const SizedBox(height: 36),

                // ── TIER 3: Dynamic Monthly Trends Chart ──────────────────
                _buildMonthlyTrendsSection(data.monthlyTrends, currentMetric),
                const SizedBox(height: 36),

                // ── TIER 4: Statutory Action Center ───────────────────────
                _buildStatutoryActionCenter(data.alerts),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TIER 1: Leading & Lagging Indicators Banner
  // --------------------------------------------------------------------------
  Widget _buildLeadingLaggingKpis(SafetyOverviewKpi kpi) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWide ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isWide ? 2.1 : 1.8,
          children: [
            // 1. วันทำงานปลอดภัยสะสม
            _buildKpiHighlightCard(
              title: 'วันทำงานปลอดภัยสะสม',
              value: '${kpi.safeDaysCount}',
              unit: 'วัน',
              subtitle: 'เป้าหมาย Zero LTI ต่อเนื่อง 🛡️',
              icon: Icons.shield_rounded,
              gradientColors: [const Color(0xFF059669), const Color(0xFF10B981)],
              isSafeZero: true,
              onTap: () => widget.onNavigate?.call(AppRoutes.nearMiss), // NearMissFormPage (6)
            ),
            // 2. อุบัติเหตุหยุดงานปีนี้ (LTI)
            _buildKpiHighlightCard(
              title: 'อุบัติเหตุหยุดงานปีนี้ (LTI)',
              value: '${kpi.ltiCountThisYear}',
              unit: 'เคส',
              subtitle: kpi.ltiCountThisYear == 0 ? 'ปลอดภัย 100% • TRIR: 0.00' : 'TRIR: ${kpi.trirValue}',
              icon: Icons.health_and_safety_rounded,
              gradientColors: kpi.ltiCountThisYear == 0
                  ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                  : [const Color(0xFFDC2626), const Color(0xFFEF4444)],
              onTap: () => widget.onNavigate?.call(AppRoutes.nearMiss),
            ),
            // 3. Near Miss สะสมปีนี้
            _buildKpiHighlightCard(
              title: 'Near Miss สะสมปีนี้',
              value: '${kpi.nearMissCountThisYear}',
              unit: 'เหตุการณ์',
              subtitle: 'สอบสวน 5W1H & ป้องกันก่อนเกิดเหตุ',
              icon: Icons.warning_amber_rounded,
              gradientColors: [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
              onTap: () => widget.onNavigate?.call(AppRoutes.nearMiss),
            ),
            // 4. PTW เสี่ยงสูงเปิดงานวันนี้
            _buildKpiHighlightCard(
              title: 'PTW เปิดปฏิบัติงานวันนี้',
              value: '${kpi.activePtwToday}',
              unit: 'ใบอนุญาต',
              subtitle: 'งานเสี่ยงสูงมี Fire Watch & ควบคุม',
              icon: Icons.assignment_turned_in_rounded,
              gradientColors: [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
              onTap: () => widget.onNavigate?.call(AppRoutes.ptw), // PtwPage (4)
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiHighlightCard({
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    bool isSafeZero = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 72,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    Icon(icon, size: 20, color: Colors.white),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, height: 1.0),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      unit,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TIER 2: Cross-Module Operational Grid
  // --------------------------------------------------------------------------
  Widget _buildModuleGrid(List<ModuleSummaryItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.3,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildModuleCard(item);
          },
        );
      },
    );
  }

  Widget _buildModuleCard(ModuleSummaryItem item) {
    return InkWell(
      onTap: () => widget.onNavigate?.call(item.targetRouteIndex),
      borderRadius: BorderRadius.circular(16),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: item.color.withValues(alpha: 0.25)),
              ),
              child: Icon(item.icon, color: item.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.isAttentionNeeded
                              ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                              : item.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: item.isAttentionNeeded
                                ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                                : item.color.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          item.badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item.isAttentionNeeded ? const Color(0xFFDC2626) : item.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.mainValue,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subValue,
                    style: TextStyle(
                      fontSize: 11,
                      color: item.isAttentionNeeded ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                      fontWeight: item.isAttentionNeeded ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TIER 3: Dynamic Monthly Trends Chart (Dual Metric)
  // --------------------------------------------------------------------------
  Widget _buildMonthlyTrendsSection(List<MonthlyTrendSpot> trends, DashboardChartMetric metric) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric == DashboardChartMetric.trir
                        ? 'สถิติอัตราความถี่ความรุนแรง (TRIR Trend ๑๒ เดือน)'
                        : 'สถิติจำนวนเหตุการณ์สะสมรายเดือน (Incident & Near Miss)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metric == DashboardChartMetric.trir
                        ? 'สูตรมาตรฐาน: (จำนวนอุบัติเหตุ x ๒๐๐,๐๐๐) ÷ ชั่วโมงการทำงานรวม (Man-Hours)'
                        : 'ดึงข้อมูลจริงจากทะเบียน Near Miss และรายงานการสอบสวนอุบัติการณ์',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              // Metric Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton(
                      label: 'TRIR Rate',
                      icon: Icons.show_chart_rounded,
                      isSelected: metric == DashboardChartMetric.trir,
                      onTap: () {
                        ref.read(dashboardChartMetricProvider.notifier).setMetric(DashboardChartMetric.trir);
                      },
                    ),
                    _buildToggleButton(
                      label: 'จำนวนเคสจริง',
                      icon: Icons.bar_chart_rounded,
                      isSelected: metric == DashboardChartMetric.caseCounts,
                      onTap: () {
                        ref.read(dashboardChartMetricProvider.notifier).setMetric(DashboardChartMetric.caseCounts);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Line Chart
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          metric == DashboardChartMetric.trir
                              ? val.toStringAsFixed(1)
                              : val.toInt().toString(),
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < trends.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              trends[idx].monthName,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: metric == DashboardChartMetric.trir ? 3.0 : 5.0,
                lineBarsData: [
                  if (metric == DashboardChartMetric.trir)
                    LineChartBarData(
                      spots: trends.map((t) => FlSpot(t.monthIndex.toDouble(), t.trirRate)).toList(),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: const Color(0xFF10B981),
                      barWidth: 3.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: const Color(0xFF10B981),
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      ),
                    )
                  else ...[
                    // Near Miss Line (Blue)
                    LineChartBarData(
                      spots: trends.map((t) => FlSpot(t.monthIndex.toDouble(), t.nearMissCount.toDouble())).toList(),
                      isCurved: true,
                      color: const Color(0xFF3B82F6),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 3.5,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF3B82F6),
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                      ),
                    ),
                    // Accident Line (Red)
                    LineChartBarData(
                      spots: trends.map((t) => FlSpot(t.monthIndex.toDouble(), t.incidentCount.toDouble())).toList(),
                      isCurved: false,
                      color: const Color(0xFFEF4444),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: metric == DashboardChartMetric.trir
                ? [
                    _buildLegendItem('อัตรา TRIR รายเดือน (เป้าหมาย 0.00)', const Color(0xFF10B981)),
                  ]
                : [
                    _buildLegendItem('Near Miss (เหตุการณ์เกือบเกิดอุบัติเหตุ)', const Color(0xFF3B82F6)),
                    const SizedBox(width: 24),
                    _buildLegendItem('อุบัติเหตุ (LTI / Lost Time)', const Color(0xFFEF4444)),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TIER 4: Statutory Action Center
  // --------------------------------------------------------------------------
  Widget _buildStatutoryActionCenter(List<StatutoryAlertItem> alerts) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ศูนย์แจ้งเตือนมาตรการเร่งด่วนตามกฎหมาย (Statutory Action Center)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${alerts.length} ประเด็นที่ต้องเฝ้าระวัง',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alerts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: alert.urgencyColor.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: alert.urgencyColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: alert.urgencyColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(alert.icon, color: alert.urgencyColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: alert.urgencyColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  alert.urgencyLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: alert.urgencyColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                alert.category,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                              if (alert.dueDate != null && alert.dueDate!.isNotEmpty) ...[
                                const Spacer(),
                                Icon(Icons.schedule_rounded, size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  'กำหนด: ${alert.dueDate}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.title,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            alert.description,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => widget.onNavigate?.call(alert.targetRouteIndex),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alert.urgencyColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('จัดการ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
