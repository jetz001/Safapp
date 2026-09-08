import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cpo_providers.dart';
import '../../domain/services/cpo_statutory_evaluator.dart';
import '../../data/models/cpo_committee_model.dart';
import '../widgets/cpo_meeting_edit_dialog.dart';
import '../widgets/cpo_election_wizard_dialog.dart';

class CpoDashboardTab extends ConsumerWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const CpoDashboardTab({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(cpoDashboardSummaryProvider);

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('เกิดข้อผิดพลาดในการโหลดแดชบอร์ด: $e')),
      data: (data) {
        final activeTerm = data['active_term'] as CpoTermModel?;
        final compliance = data['compliance_result'] as CpoComplianceResult?;
        final frequency = data['frequency_result'] as Map<String, dynamic>?;
        final totalActions = data['total_actions'] as int? ?? 0;
        final completedActions = data['completed_actions'] as int? ?? 0;
        final pendingActions = data['pending_actions'] as int? ?? 0;
        final overdueActions = data['overdue_actions'] as int? ?? 0;
        final completionRate = data['completion_rate'] as double? ?? 0.0;
        final monthlyStats = data['monthly_safety_stats'] as Map<String, dynamic>? ?? {};

        final completedMeetings = frequency?['completed_count'] as int? ?? 0;
        final targetMeetings = frequency?['target_count'] as int? ?? 12;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.shade900.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.shield_outlined, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ระบบบริหารงานคณะกรรมการ คปอ. (Safety Committee System)',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activeTerm != null
                                ? 'วาระปัจจุบัน: ${activeTerm.termTitle} (${activeTerm.startDate} ถึง ${activeTerm.endDate}) • คงเหลือ ${activeTerm.remainingDays} วัน'
                                : 'ยังไม่ได้จัดตั้งวาระ คปอ. (คลิกแท็บ \"โครงสร้าง คปอ.\" เพื่อเริ่มจัดตั้งตามกฎหมาย)',
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => showDialog(context: context, builder: (ctx) => const CpoMeetingEditDialog()),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('นัดประชุมใหม่'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1E3A8A)),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => showDialog(context: context, builder: (ctx) => const CpoElectionWizardDialog()),
                          icon: const Icon(Icons.how_to_vote, size: 18),
                          label: const Text('จัดตั้ง กกต.'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade400, foregroundColor: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // KPI Row: Statutory Compliance & Meeting Targets
              Row(
                children: [
                  // KPI 1: Statutory Quota Check
                  Expanded(
                    child: _buildKpiCard(
                      title: 'สัดส่วนกรรมการ คปอ.',
                      subtitle: compliance?.isCompliant == true ? 'ผ่านเกณฑ์กฎหมาย ๒๕๖๕' : 'ยังไม่ครบเกณฑ์กฎหมาย',
                      value: '${compliance?.actualTotal ?? 0} / ${compliance?.requiredTotal ?? 5} คน',
                      progress: compliance != null && compliance.requiredTotal > 0
                          ? (compliance.actualTotal / compliance.requiredTotal).clamp(0.0, 1.0)
                          : 0.0,
                      color: compliance?.isCompliant == true ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      icon: Icons.groups,
                      onTap: () => onNavigateToTab?.call(2),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // KPI 2: Meeting Frequency (12 meetings/year)
                  Expanded(
                    child: _buildKpiCard(
                      title: 'การประชุมประจำปี (กม. ข้อ ๒๖)',
                      subtitle: 'เป้าหมายอย่างน้อย ๑ ครั้ง/เดือน',
                      value: '$completedMeetings / $targetMeetings ครั้ง',
                      progress: (completedMeetings / targetMeetings).clamp(0.0, 1.0),
                      color: completedMeetings >= targetMeetings ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                      icon: Icons.event_available,
                      onTap: () => onNavigateToTab?.call(3),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // KPI 3: Action Items Closed %
                  Expanded(
                    child: _buildKpiCard(
                      title: 'การปิดมติที่ประชุม (Action Items)',
                      subtitle: 'สำเร็จ $completedActions จาก $totalActions รายการ',
                      value: '${completionRate.toStringAsFixed(1)}%',
                      progress: completionRate / 100.0,
                      color: completionRate >= 80.0 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                      icon: Icons.task_alt,
                      onTap: () => onNavigateToTab?.call(4),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // KPI 4: Overdue Actions
                  Expanded(
                    child: _buildKpiCard(
                      title: 'งานที่คั่งค้าง / ล่าช้า',
                      subtitle: 'รอดำเนินการ $pendingActions ข้อ',
                      value: '$overdueActions รายการ',
                      progress: totalActions > 0 ? (overdueActions / totalActions).clamp(0.0, 1.0) : 0.0,
                      color: overdueActions > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      icon: Icons.warning_amber_rounded,
                      onTap: () => onNavigateToTab?.call(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Detail Section: Statutory Quota Breakdown & Monthly Cross-Module Sync
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Quota Breakdown Card
                  Expanded(
                    flex: 3,
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.balance, color: Color(0xFF1E3A8A)),
                                const SizedBox(width: 8),
                                const Text('การประเมินสัดส่วนตามกฎกระทรวง จป./คปอ. พ.ศ. ๒๕๖๕', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              compliance?.summaryText ?? 'ยังไม่มีข้อมูลการประเมิน',
                              style: TextStyle(
                                fontSize: 13,
                                color: compliance?.isCompliant == true ? Colors.green.shade800 : Colors.red.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildQuotaRow('ประธาน คปอ. (ผู้แทนนายจ้างระดับบริหาร)', compliance?.actualChair ?? 0, compliance?.requiredChair ?? 1),
                            const Divider(height: 16),
                            _buildQuotaRow('ผู้แทนนายจ้างระดับบังคับบัญชา', compliance?.actualEmployerRep ?? 0, compliance?.requiredEmployerRep ?? 2),
                            const Divider(height: 16),
                            _buildQuotaRow('ผู้แทนลูกจ้าง (มาจากการเลือกตั้ง)', compliance?.actualEmployeeRep ?? 0, compliance?.requiredEmployeeRep ?? 2),
                            const Divider(height: 16),
                            _buildQuotaRow('กรรมการและเลขานุการ (จป.วิชาชีพ)', compliance?.actualSecretary ?? 0, compliance?.requiredSecretary ?? 1),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Right: Cross-module Safety Sync
                  Expanded(
                    flex: 2,
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.sync_alt, color: Color(0xFF0284C7)),
                                const SizedBox(width: 8),
                                const Text('ข้อมูลความปลอดภัยประจำเดือน (SAFAPP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text('ข้อมูลที่พร้อมนำเข้าสู่วาระที่ ๔ (เรื่องเพื่อทราบ) อัตโนมัติ:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 12),
                            _buildStatChip('อุบัติเหตุในรอบเดือน', '${monthlyStats['incident_count'] ?? 0} ครั้ง', Colors.red),
                            const SizedBox(height: 8),
                            _buildStatChip('เหตุการณ์ Near-Miss', '${monthlyStats['near_miss_count'] ?? 0} ครั้ง', Colors.orange),
                            const SizedBox(height: 8),
                            _buildStatChip('ใบอนุญาต PTW ที่เปิดใช้', '${monthlyStats['ptw_count'] ?? 0} ฉบับ', Colors.blue),
                            const SizedBox(height: 8),
                            _buildStatChip('มติ คปอ. ที่อยู่ระหว่างดำเนินการ', '${monthlyStats['open_capa_count'] ?? 0} รายการ', Colors.purple),
                          ],
                        ),
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

  Widget _buildKpiCard({
    required String title,
    required String subtitle,
    required String value,
    required double progress,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  Icon(icon, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: progress, backgroundColor: color.withOpacity(0.15), valueColor: AlwaysStoppedAnimation(color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotaRow(String label, int actual, int required) {
    final pass = actual >= required;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Row(
          children: [
            Text('$actual / $required คน', style: TextStyle(fontWeight: FontWeight.bold, color: pass ? Colors.green.shade800 : Colors.red.shade800)),
            const SizedBox(width: 8),
            Icon(pass ? Icons.check_circle : Icons.cancel, color: pass ? Colors.green : Colors.red, size: 18),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        ],
      ),
    );
  }
}
