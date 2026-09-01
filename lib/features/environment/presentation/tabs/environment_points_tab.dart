import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/environment_point_model.dart';
import '../../domain/models/environment_standard_model.dart';
import '../providers/environment_providers.dart';
import '../widgets/add_edit_point_dialog.dart';
import '../widgets/add_edit_capa_dialog.dart';

/// Tab 1: Interactive Sampling & Measurement Points Table (แสงสว่าง, เสียง, ความร้อน WBGT)
class EnvironmentPointsTab extends ConsumerWidget {
  const EnvironmentPointsTab({Key? key}) : super(key: key);

  void _openAddPointDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AddEditPointDialog(),
    );
  }

  void _openEditPointDialog(BuildContext context, WidgetRef ref, EnvironmentPointModel point) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEditPointDialog(point: point),
    );
  }

  void _openCreateCapaFromPoint(BuildContext context, WidgetRef ref, EnvironmentPointModel point) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEditCapaDialog(linkedPoint: point),
    );
  }

  void _confirmDeletePoint(BuildContext context, WidgetRef ref, EnvironmentPointModel point) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('ยืนยันการลบจุดตรวจวัด', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('คุณต้องการลบจุดตรวจวัด "${point.pointId}" (${point.locationName}) หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(envPointListProvider.notifier).deletePoint(point.pointId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ลบจุดตรวจวัดเรียบร้อยแล้ว'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('ลบข้อมูล'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsAsync = ref.watch(envPointListProvider);
    final factorFilter = ref.watch(envFactorFilterProvider);
    final statusFilter = ref.watch(envStatusFilterProvider);
    final searchQuery = ref.watch(envSearchQueryProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // --------------------------------------------------------------------
        // 1. Search & Filter Bar
        // --------------------------------------------------------------------
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input & Add Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'ค้นหาจุดตรวจวัด, แผนก, พื้นที่, หรือลักษณะงาน...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onChanged: (v) {
                        ref.read(envSearchQueryProvider.notifier).state = v;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: () => _openAddPointDialog(context, ref),
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: const Text('เพิ่มจุดตรวจวัดใหม่'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Filter Chips Row
              Row(
                children: [
                  const Text('ปัจจัยตรวจวัด:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _buildFactorFilterChip(ref, 'ทั้งหมด', 'ALL', factorFilter),
                  const SizedBox(width: 6),
                  _buildFactorFilterChip(ref, 'แสงสว่าง (Light)', 'LIGHT', factorFilter),
                  const SizedBox(width: 6),
                  _buildFactorFilterChip(ref, 'เสียง (Noise)', 'NOISE', factorFilter),
                  const SizedBox(width: 6),
                  _buildFactorFilterChip(ref, 'ความร้อน (Heat)', 'HEAT', factorFilter),

                  const Spacer(),

                  const Text('สถานะผล:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip(ref, 'ทั้งหมด', 'ALL', statusFilter),
                  const SizedBox(width: 6),
                  _buildStatusFilterChip(ref, 'ผ่านเกณฑ์', 'PASS', statusFilter),
                  const SizedBox(width: 6),
                  _buildStatusFilterChip(ref, 'เฝ้าระวัง Action Level', 'ACTION_LEVEL', statusFilter),
                  const SizedBox(width: 6),
                  _buildStatusFilterChip(ref, 'เกินเกณฑ์', 'FAIL', statusFilter),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --------------------------------------------------------------------
        // 2. Measurement Points List
        // --------------------------------------------------------------------
        pointsAsync.when(
          data: (points) {
            if (points.isEmpty) {
              return _buildEmptyState(
                title: 'ไม่พบรายการจุดตรวจวัดที่ค้นหา',
                subtitle: 'ลองเปลี่ยนคำค้นหา ปรับตัวกรอง หรือคลิก "+ เพิ่มจุดตรวจวัดใหม่"',
                onReset: () {
                  ref.read(envSearchQueryProvider.notifier).clear();
                  ref.read(envFactorFilterProvider.notifier).reset();
                  ref.read(envStatusFilterProvider.notifier).reset();
                },
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: points.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final pt = points[i];
                return _buildPointCard(context, ref, pt);
              },
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
          error: (err, _) => Center(child: Text('เกิดข้อผิดพลาด: $err', style: const TextStyle(color: Colors.red))),
        ),
      ],
    );
  }

  Widget _buildFactorFilterChip(WidgetRef ref, String label, String code, String currentCode) {
    final isSelected = currentCode == code;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => ref.read(envFactorFilterProvider.notifier).state = code,
      selectedColor: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
      checkmarkColor: const Color(0xFF1E3A8A),
    );
  }

  Widget _buildStatusFilterChip(WidgetRef ref, String label, String code, String currentCode) {
    final isSelected = currentCode == code;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => ref.read(envStatusFilterProvider.notifier).state = code,
      selectedColor: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
      checkmarkColor: const Color(0xFF1E3A8A),
    );
  }

  Widget _buildPointCard(BuildContext context, WidgetRef ref, EnvironmentPointModel pt) {
    Color badgeBg;
    Color badgeText;
    IconData badgeIcon;

    switch (pt.evaluationStatus) {
      case EnvironmentEvaluationStatus.pass:
        badgeBg = const Color(0xFFDCFCE7);
        badgeText = const Color(0xFF166534);
        badgeIcon = Icons.check_circle_rounded;
        break;
      case EnvironmentEvaluationStatus.actionLevel:
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFF92400E);
        badgeIcon = Icons.warning_amber_rounded;
        break;
      case EnvironmentEvaluationStatus.fail:
        badgeBg = const Color(0xFFFEE2E2);
        badgeText = const Color(0xFF991B1B);
        badgeIcon = Icons.cancel_rounded;
        break;
    }

    Color factorColor;
    IconData factorIcon;
    switch (pt.factorType) {
      case EnvironmentFactorType.light:
        factorColor = const Color(0xFFD97706);
        factorIcon = Icons.lightbulb_outline_rounded;
        break;
      case EnvironmentFactorType.noise:
        factorColor = const Color(0xFF2563EB);
        factorIcon = Icons.volume_up_rounded;
        break;
      case EnvironmentFactorType.heat:
        factorColor = const Color(0xFFDC2626);
        factorIcon = Icons.thermostat_rounded;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: factorColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(factorIcon, size: 16, color: factorColor),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: factorColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    pt.pointId,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  pt.factorType.labelTh,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: factorColor),
                ),
                const SizedBox(width: 8),
                Text('• ${pt.department} - ${pt.locationName}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeText.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 14, color: badgeText),
                      const SizedBox(width: 4),
                      Text(
                        pt.evaluationStatus.labelTh,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: badgeText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Details Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Value Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ผลการตรวจวัดจริง:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            pt.summaryValueDisplay,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Task & Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ลักษณะงาน / เครื่องจักร: ${pt.taskOrMachineName ?? pt.lightTaskDescription ?? "-"}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          if (pt.factorType == EnvironmentFactorType.light && pt.lightSurroundingLux != null)
                            Text('แสงสว่างรอบข้าง: ${pt.lightSurroundingLux} Lux', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          if (pt.factorType == EnvironmentFactorType.heat)
                            Text('NWB: ${pt.heatNwbCelsius}°C | GT: ${pt.heatGtCelsius}°C | DB: ${pt.heatDbCelsius}°C | ภาระงาน: ${pt.heatWorkloadType?.labelTh}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          if (pt.notes != null && pt.notes!.isNotEmpty)
                            Text('หมายเหตุ: ${pt.notes}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                ),

                // HCP Badge if applicable
                if (pt.requiresHearingConservation) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD8B4FE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hearing_rounded, color: Color(0xFF6B21A8), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'จุดนี้เข้าข่ายโครงการอนุรักษ์การได้ยิน (Hearing Conservation Program) ตามข้อ ๑๑ กฎกระทรวงฯ ๒๕๕๙',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF6B21A8), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Actions Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (pt.requiresCapa) ...[
                      OutlinedButton.icon(
                        onPressed: () => _openCreateCapaFromPoint(context, ref, pt),
                        icon: const Icon(Icons.add_task_rounded, size: 16),
                        label: const Text('เปิดแผน CAPA'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD97706),
                          side: const BorderSide(color: Color(0xFFF59E0B)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'แก้ไข',
                      onPressed: () => _openEditPointDialog(context, ref, pt),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      tooltip: 'ลบ',
                      onPressed: () => _confirmDeletePoint(context, ref, pt),
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

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required VoidCallback onReset,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onReset,
              child: const Text('ล้างตัวกรองทั้งหมด'),
            ),
          ],
        ),
      ),
    );
  }
}
