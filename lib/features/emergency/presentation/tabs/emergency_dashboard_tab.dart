import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/emergency_providers.dart';
import '../../domain/enums/hazard_type.dart';

class EmergencyDashboardTab extends ConsumerWidget {
  final VoidCallback onNavigateToBuilder;
  final VoidCallback onNavigateToDrills;

  const EmergencyDashboardTab({
    super.key,
    required this.onNavigateToBuilder,
    required this.onNavigateToDrills,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpi = ref.watch(emergencyKpiProvider);
    final plansAsync = ref.watch(emergencyPlanListProvider);
    final drillsAsync = ref.watch(drillSessionListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Summary Header & Action Bar ──
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ศูนย์ควบคุมและประเมินความพร้อมรับมือภาวะฉุกเฉิน',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Multi-Hazard Emergency Management (กฎกระทรวงอัคคีภัย ๒๕๕๕ ข้อ ๔ & ข้อ ๓๐)',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onNavigateToDrills,
                        icon: const Icon(Icons.assignment_outlined, size: 16),
                        label: const Text('บันทึก/แนบรายงานฝึกซ้อม'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: onNavigateToBuilder,
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text('จัดทำ/ปรับปรุงแผนฉุกเฉิน'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // ── Row 1: Annual Drill Countdown SLA & KPI Cards (Responsive) ──
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 950;
              if (isNarrow) {
                return Column(
                  children: [
                    _buildAnnualDrillSlaCard(kpi),
                    const SizedBox(height: 16),
                    _buildMetricsGrid(kpi),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildAnnualDrillSlaCard(kpi),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: _buildMetricsGrid(kpi),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Row 2: Multi-Hazard Coverage Matrix ──
          const Text(
            'ความพร้อมรับมือจำแนกตามประเภทภัย (Multi-Hazard Readiness)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 10),
          plansAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
            error: (err, _) => Text('Error loading plans: $err'),
            data: (plans) => _buildMultiHazardGrid(plans, onNavigateToBuilder),
          ),

          const SizedBox(height: 24),

          // ── Row 3: Latest Drills & Recent Plans ──
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 800;
              if (isNarrow) {
                return Column(
                  children: [
                    _buildRecentDrillsCard(drillsAsync, onNavigateToDrills),
                    const SizedBox(height: 16),
                    _buildRecentPlansCard(plansAsync, onNavigateToBuilder),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildRecentDrillsCard(drillsAsync, onNavigateToDrills)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildRecentPlansCard(plansAsync, onNavigateToBuilder)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnnualDrillSlaCard(EmergencyKpiSummary kpi) {
    final days = kpi.daysUntilAnnualDrillDue;
    final isOverdue = kpi.isAnnualDrillOverdue;

    Color bgBadgeColor;
    Color textColor;
    String statusLabel;
    IconData statusIcon;

    if (isOverdue) {
      bgBadgeColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFDC2626);
      statusLabel = 'เกินกำหนด ๑ ปี';
      statusIcon = Icons.error_outline;
    } else if (days <= 60) {
      bgBadgeColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
      statusLabel = 'ใกล้ครบกำหนด';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      bgBadgeColor = const Color(0xFFD1FAE5);
      textColor = const Color(0xFF059669);
      statusLabel = 'อยู่ในเกณฑ์ปกติ';
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Text(
                'รอบการฝึกซ้อมประจำปี (SLA ๑ ปี)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bgBadgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: textColor),
                    const SizedBox(width: 4),
                    Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Column(
              children: [
                Text(
                  isOverdue ? 'เกินกำหนด' : '$days',
                  style: TextStyle(
                    fontSize: isOverdue ? 36 : 44,
                    fontWeight: FontWeight.w900,
                    color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  isOverdue ? 'ต้องจัดฝึกซ้อมตามกฎหมาย' : 'วัน ก่อนครบกำหนด ๑ ปี',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 6),
          Text(
            'กฎกระทรวงอัคคีภัย ๒๕๕๕ ข้อ ๓๐: นายจ้างต้องจัดให้ลูกจ้างทุกคนฝึกซ้อมดับเพลิงและอพยพหนีไฟพร้อมกันอย่างน้อยปีละ ๑ ครั้ง',
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(EmergencyKpiSummary kpi) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'แผนฉุกเฉินที่ดูแล',
                value: '${kpi.activePlansCount} แผน',
                subtitle: 'จากทั้งหมด ${kpi.totalPlansCount} ฉบับ',
                icon: Icons.shield_outlined,
                color: const Color(0xFF059669),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'ประวัติการฝึกซ้อม',
                value: '${kpi.totalDrillsConducted} ครั้ง',
                subtitle: 'ปีปัจจุบัน ${kpi.currentYearDrills} ครั้ง',
                icon: Icons.run_circle_outlined,
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'อัตราเข้าร่วมเฉลี่ย',
                value: '${kpi.averageParticipationRate.toStringAsFixed(1)}%',
                subtitle: 'เป้าหมายตามเกณฑ์ >= 90%',
                icon: Icons.groups_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'รอส่งแบบ สปร. ๔',
                value: '${kpi.pendingSpr4Submissions} รายการ',
                subtitle: 'ภายใน ๓๐ วันนับแต่วันซ้อม',
                icon: Icons.pending_actions_outlined,
                color: kpi.pendingSpr4Submissions > 0 ? const Color(0xFFD97706) : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                Text(subtitle, style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiHazardGrid(List<dynamic> plans, VoidCallback onNavigateToBuilder) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth;
        if (constraints.maxWidth > 1050) {
          itemWidth = (constraints.maxWidth - (10 * 4)) / 5;
        } else if (constraints.maxWidth > 650) {
          itemWidth = (constraints.maxWidth - 10) / 2;
        } else {
          itemWidth = constraints.maxWidth;
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: HazardType.values.map((hazard) {
            final matchingPlans = plans.where((p) => p.hazardType == hazard).toList();
            final hasPlan = matchingPlans.isNotEmpty;

            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasPlan ? hazard.color.withValues(alpha: 0.4) : Colors.grey.shade200,
                    width: hasPlan ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: hazard.color.withValues(alpha: 0.12),
                          child: Icon(hazard.icon, size: 14, color: hazard.color),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hazard.shortTitle,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          hasPlan ? 'พร้อมใช้งาน' : 'ยังไม่มีแผน',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: hasPlan ? const Color(0xFF059669) : Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          '${matchingPlans.length} ฉบับ',
                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRecentDrillsCard(AsyncValue<List<dynamic>> drillsAsync, VoidCallback onNavigateToDrills) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ประวัติการฝึกซ้อมและการแนบรายงาน', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: onNavigateToDrills,
                child: const Text('ดูทั้งหมด >', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          drillsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e'),
            data: (drills) {
              if (drills.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('ยังไม่มีประวัติการฝึกซ้อม', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ),
                );
              }
              return Column(
                children: drills.take(3).map((d) {
                  final hasReport = d.vendorReportPath != null && (d.vendorReportPath as String).isNotEmpty;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.drillTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('วันที่: ${d.drillDate} | ผู้ร่วม: ${d.participatedCount} คน', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
                              if (hasReport) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: const [
                                    Icon(Icons.attach_file, size: 12, color: Color(0xFF059669)),
                                    SizedBox(width: 2),
                                    Text('แนบเล่มรายงานเอกชนแล้ว', style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: d.spr4SubmissionStatus.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            d.spr4SubmissionStatus.label,
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: d.spr4SubmissionStatus.color),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPlansCard(AsyncValue<List<dynamic>> plansAsync, VoidCallback onNavigateToBuilder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('เล่มแผนฉุกเฉินที่ดูแล (ERP Plans)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: onNavigateToBuilder,
                child: const Text('จัดการแผน >', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          plansAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e'),
            data: (plans) {
              if (plans.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('ยังไม่มีเล่มแผนฉุกเฉิน', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ),
                );
              }
              return Column(
                children: plans.take(3).map((p) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: p.hazardType.color.withValues(alpha: 0.15),
                                child: Icon(p.hazardType.icon, size: 13, color: p.hazardType.color),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.planTitle, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                    Text('ฉบับที่ ${p.version} | ${p.companyName}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          p.status.label,
                          style: TextStyle(fontSize: 10, color: p.status.color, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
