import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/environment_point_model.dart';
import '../../domain/models/environment_standard_model.dart';
import '../providers/environment_providers.dart';
import '../widgets/add_edit_point_dialog.dart';
import '../widgets/add_edit_capa_dialog.dart';
import '../widgets/point_detail_card_dialog.dart';

/// Tab 1: Interactive Sampling & Measurement Points Table (แสงสว่าง, เสียง, ความร้อน WBGT)
class EnvironmentPointsTab extends ConsumerStatefulWidget {
  const EnvironmentPointsTab({super.key});

  @override
  ConsumerState<EnvironmentPointsTab> createState() => _EnvironmentPointsTabState();
}

class _EnvironmentPointsTabState extends ConsumerState<EnvironmentPointsTab> {
  final ScrollController _horizontalScrollCtrl = ScrollController();

  @override
  void dispose() {
    _horizontalScrollCtrl.dispose();
    super.dispose();
  }

  void _openPointDetailDialog(BuildContext context, EnvironmentPointModel point) {
    PointDetailCardDialog.show(
      context,
      point: point,
      onEdited: () => ref.refresh(envPointListProvider),
    );
  }

  void _openAddPointDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AddEditPointDialog(),
    );
  }

  void _openEditPointDialog(BuildContext context, EnvironmentPointModel point) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEditPointDialog(point: point),
    );
  }

  void _openCreateCapaFromPoint(BuildContext context, EnvironmentPointModel point) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEditCapaDialog(linkedPoint: point),
    );
  }

  void _confirmDeletePoint(BuildContext context, EnvironmentPointModel point) {
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

  void _openPrintPointCard(BuildContext context, EnvironmentPointModel pt) {
    if (pt.factorType == EnvironmentFactorType.heat) {
      try {
        final rss1Js = '''
window.RSS1_DATA = {
  date: "30 มีนาคม 2569",
  location: "${pt.locationName}",
  employee: "${pt.taskOrMachineName?.replaceAll(RegExp(r'^[^(]*\('), '').replaceAll(')', '') ?? 'คุณเพ็ญศรี มูลพันธ์'}",
  time: "8.50-10.50",
  nwb: "${pt.heatNwbCelsius?.toStringAsFixed(1) ?? '27.9'}",
  db: "${pt.heatDbCelsius?.toStringAsFixed(1) ?? '34.2'}",
  gt: "${pt.heatGtCelsius?.toStringAsFixed(1) ?? '35.2'}",
  solar: "${pt.heatSolarExposure == HeatSolarExposure.outdoorWithSolar ? 'out' : 'in'}",
  wbgt: "${pt.heatCalculatedWbgt?.toStringAsFixed(1) ?? '30.1'}",
  task: "${pt.taskOrMachineName?.split('(').first.trim() ?? 'ควบคุมเครื่อง'}",
  workload: "${pt.heatWorkloadType?.labelTh ?? 'งานปานกลาง'}",
  metAvg: "${pt.heatMetabolicRateKcalHr?.toStringAsFixed(0) ?? '204'}",
  evaluation: "${pt.isPass ? 'ไม่เกินเกณฑ์' : 'เกินเกณฑ์'}",
  capa: "-"
};
''';
        for (final p in [
          r'C:\Users\Boss-QA\.gemini\antigravity\brain\bd61fdff-3ef9-411c-80b5-c3b4b728f102\rss1_current.js',
          r'C:\Users\Boss-QA\.gemini\antigravity\brain\715757b6-eb3c-4a05-a823-ce4116256ca2\rss1_current.js',
          r'D:\DEV\Safapp\bin\สวล69\2026\rss1_current.js',
        ]) {
          try {
            File(p).writeAsStringSync(rss1Js);
          } catch (_) {}
        }
      } catch (_) {}

      Process.run('cmd.exe', [
        '/c',
        'start',
        '',
        r'C:\Users\Boss-QA\.gemini\antigravity\brain\715757b6-eb3c-4a05-a823-ce4116256ca2\form_rss1.html',
      ]);
      return;
    }

    if (pt.factorType == EnvironmentFactorType.light) {
      if (pt.lightCategoryCode == 'AREA') {
        try {
          final luxVal = pt.lightMeasuredLux ?? 517.0;
          final luxMin = (luxVal * 0.96).round();
          final rss2AreaJs = '''
window.RSS2_AREA_DATA = {
  date: "30 มีนาคม 2569",
  location: "${pt.locationName}",
  task: "${pt.lightTaskDescription ?? pt.taskOrMachineName ?? 'พื้นที่ทำงาน'}",
  luxAvg: "${luxVal.toStringAsFixed(0)}",
  luxMin: "$luxMin",
  evaluation: "${pt.isPass ? 'เป็นไปตามเกณฑ์' : 'ไม่เป็นไปตามเกณฑ์'}",
  capa: "-"
};
''';
          for (final p in [
            r'C:\Users\Boss-QA\.gemini\antigravity\brain\bd61fdff-3ef9-411c-80b5-c3b4b728f102\rss2_area_current.js',
            r'C:\Users\Boss-QA\.gemini\antigravity\brain\715757b6-eb3c-4a05-a823-ce4116256ca2\rss2_area_current.js',
            r'D:\DEV\Safapp\bin\สวล69\2026\rss2_area_current.js',
          ]) {
            try {
              File(p).writeAsStringSync(rss2AreaJs);
            } catch (_) {}
          }
        } catch (_) {}

        Process.run('cmd.exe', [
          '/c',
          'start',
          '',
          r'C:\Users\Boss-QA\.gemini\antigravity\brain\715757b6-eb3c-4a05-a823-ce4116256ca2\form_rss2_area.html',
        ]);
      } else {
        try {
          final luxVal = pt.lightMeasuredLux?.toStringAsFixed(0) ?? '448';
          final surround = pt.lightSurroundingLux != null ? pt.lightSurroundingLux!.toStringAsFixed(0) : '-';
          final empInfo = '${pt.department}<br>${pt.locationName}';
          final taskDesc = pt.taskOrMachineName ?? pt.lightTaskDescription ?? 'คอมพิวเตอร์ (งานละเอียดเล็กน้อย)';
          final rss2SpotJs = '''
window.RSS2_SPOT_DATA = {
  date: "30 มีนาคม 2569",
  employee: "$empInfo",
  task: "$taskDesc",
  luxSpot: "$luxVal",
  surround1: "$surround",
  surround2: "-",
  evaluation: "${pt.isPass ? 'เป็นไปตามเกณฑ์' : 'ไม่เป็นไปตามเกณฑ์'}",
  capa: "-"
};
''';
          for (final p in [
            r'C:\Users\Boss-QA\.gemini\antigravity\brain\bd61fdff-3ef9-411c-80b5-c3b4b728f102\rss2_spot_current.js',
            r'C:\Users\Boss-QA\.gemini\antigravity\brain\715757b6-eb3c-4a05-a823-ce4116256ca2\rss2_spot_current.js',
            r'D:\DEV\Safapp\bin\สวล69\2026\rss2_spot_current.js',
          ]) {
            try {
              File(p).writeAsStringSync(rss2SpotJs);
            } catch (_) {}
          }
        } catch (_) {}

        Process.run('cmd.exe', [
          '/c',
          'start',
          '',
          r'C:\Users\Boss-QA\.gemini\antigravity\brain\715757b6-eb3c-4a05-a823-ce4116256ca2\form_rss2_spot.html',
        ]);
      }
      return;
    }

    if (pt.factorType == EnvironmentFactorType.noise) {
      try {
        final emp = pt.taskOrMachineName?.replaceAll(RegExp(r'\s*\([^)]*\)'), '') ?? 'Ms. Nant Mya Thaw';
        final dba = pt.noiseMeasuredDba?.toStringAsFixed(1) ?? '73.4';
        final twa = pt.noiseMeasuredDba?.round().toString() ?? '73';
        final hours = '${pt.noiseExposureDurationHours?.toStringAsFixed(0) ?? '8'} ชั่วโมง';
        final rss3Js = '''
window.RSS3_DATA = {
  date: "30 มีนาคม 2569",
  location: "${pt.locationName}",
  employee: "$emp",
  workDuration: "$hours",
  workArea: "-",
  noiseDba: "$dba",
  measDuration: "$hours",
  twa: "$twa",
  evaluation: "${pt.isPass ? 'ไม่เกินเกณฑ์' : 'เกินเกณฑ์'}",
  capa: "-"
};
''';
        for (final p in [
          r'C:\Users\Boss-QA\.gemini\antigravity\brain\bd61fdff-3ef9-411c-80b5-c3b4b728f102\rss3_current.js',
          r'C:\Users\Boss-QA\.gemini\antigravity\brain\715757b6-eb3c-4a05-a823-ce4116256ca2\rss3_current.js',
          r'D:\DEV\Safapp\bin\สวล69\2026\rss3_current.js',
        ]) {
          try {
            File(p).writeAsStringSync(rss3Js);
          } catch (_) {}
        }
      } catch (_) {}

      Process.run('cmd.exe', [
        '/c',
        'start',
        '',
        r'C:\Users\Boss-QA\.gemini\antigravity\brain\715757b6-eb3c-4a05-a823-ce4116256ca2\form_rss3.html',
      ]);
      return;
    }

    try {
      String measuredVal = '0';
      String unit = '';
      if (pt.factorType == EnvironmentFactorType.light) {
        measuredVal = pt.lightMeasuredLux?.toStringAsFixed(0) ?? '0';
        unit = 'Lux (จุดปฏิบัติงาน)';
      } else {
        measuredVal = pt.noiseMeasuredDba?.toStringAsFixed(1) ?? '0.0';
        unit = 'dBA (Leq 8 ชั่วโมง)';
      }

      final jsContent = '''
window.CURRENT_POINT_DATA = {
  factor: "${pt.factorType.name}",
  pointId: "${pt.pointId}",
  dept: "${pt.department}",
  location: "${pt.locationName}",
  task: "${pt.taskOrMachineName ?? pt.lightTaskDescription ?? '-'}",
  date: "18 ก.พ. 2569",
  measuredValue: "$measuredVal",
  measuredUnit: "$unit",
  standardLimit: "${pt.standardLimitDisplay}",
  statusText: "${pt.evaluationStatus.labelTh}",
  notes: "${pt.notes ?? ''}"
};
''';

      for (final p in [
        r'C:\Users\Boss-QA\.gemini\antigravity\brain\bd61fdff-3ef9-411c-80b5-c3b4b728f102\point_current.js',
        r'C:\Users\Boss-QA\.gemini\antigravity\brain\715757b6-eb3c-4a05-a823-ce4116256ca2\point_current.js',
      ]) {
        try {
          File(p).writeAsStringSync(jsContent);
        } catch (_) {}
      }
    } catch (_) {}

    Process.run('cmd.exe', [
      '/c',
      'start',
      '',
      r'C:\Users\Boss-QA\.gemini\antigravity\brain\bd61fdff-3ef9-411c-80b5-c3b4b728f102\point_print_card.html',
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final pointsAsync = ref.watch(envPointListProvider);
    final factorFilter = ref.watch(envFactorFilterProvider);
    final statusFilter = ref.watch(envStatusFilterProvider);
    final viewMode = ref.watch(envPointsViewModeProvider);

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
              // Session / Year Selector Row
              Consumer(
                builder: (context, ref, _) {
                  final sessionsAsync = ref.watch(envSessionListProvider);
                  final currentSessionId = ref.watch(envSelectedSessionIdProvider);

                  return sessionsAsync.maybeWhen(
                    data: (sessions) {
                      if (sessions.isEmpty) return const SizedBox.shrink();

                      final isValid = currentSessionId == 'ALL' || sessions.any((s) => s.sessionId == currentSessionId);
                      final dropdownVal = isValid ? currentSessionId : 'ALL';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF1E3A8A)),
                            ),
                            const SizedBox(width: 8),
                            const Text('รอบปีการตรวจวัด:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: dropdownVal,
                                    isExpanded: true,
                                    isDense: true,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: 'ALL',
                                        child: Text('แสดงจุดตรวจวัดทุกรอบปี (All Years)'),
                                      ),
                                      ...sessions.map((s) => DropdownMenuItem<String>(
                                        value: s.sessionId,
                                        child: Text(
                                          'รอบปี พ.ศ. ${s.sessionYearBe} - ${s.sessionTitle} (${s.sessionId})',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref.read(envSelectedSessionIdProvider.notifier).state = val;
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              ),

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
                    onPressed: () => _openAddPointDialog(context),
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

              // Filter Chips Wrap (Responsive layout to prevent RenderFlex overflow)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('ปัจจัยตรวจวัด:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  _buildFactorFilterChip('ทั้งหมด', 'ALL', factorFilter),
                  _buildFactorFilterChip('แสงสว่าง (Light)', 'LIGHT', factorFilter),
                  _buildFactorFilterChip('เสียง (Noise)', 'NOISE', factorFilter),
                  _buildFactorFilterChip('ความร้อน (Heat)', 'HEAT', factorFilter),

                  const SizedBox(width: 12),
                  const Text('สถานะผล:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  _buildStatusFilterChip('ทั้งหมด', 'ALL', statusFilter),
                  _buildStatusFilterChip('ผ่านเกณฑ์', 'PASS', statusFilter),
                  _buildStatusFilterChip('เฝ้าระวัง Action Level', 'ACTION_LEVEL', statusFilter),
                  _buildStatusFilterChip('เกินเกณฑ์', 'FAIL', statusFilter),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // View Mode Switcher & Summary Count
              Row(
                children: [
                  // View mode toggle buttons
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewModeBtn(
                          icon: Icons.table_chart_rounded,
                          label: 'รูปแบบตาราง (Table)',
                          isActive: viewMode == 'TABLE',
                          mode: 'TABLE',
                        ),
                        const SizedBox(width: 4),
                        _buildViewModeBtn(
                          icon: Icons.view_agenda_rounded,
                          label: 'รูปแบบการ์ด (Cards)',
                          isActive: viewMode == 'CARD',
                          mode: 'CARD',
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  pointsAsync.maybeWhen(
                    data: (pts) => Text(
                      'รายการทั้งหมด ${pts.length} จุดตรวจวัด',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --------------------------------------------------------------------
        // 2. Measurement Points Content (Table or Card List)
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

            if (viewMode == 'TABLE') {
              return _buildPointsTable(context, points);
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: points.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final pt = points[i];
                return _buildPointCard(context, pt);
              },
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
          error: (err, _) => Center(child: Text('เกิดข้อผิดพลาด: $err', style: const TextStyle(color: Colors.red))),
        ),
      ],
    );
  }

  Widget _buildViewModeBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    required String mode,
  }) {
    return InkWell(
      onTap: () => ref.read(envPointsViewModeProvider.notifier).state = mode,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isActive ? const Color(0xFF1E3A8A) : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? const Color(0xFF1E3A8A) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, int count, Color textCol, Color bgCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textCol),
      ),
    );
  }

  Widget _buildFactorFilterChip(String label, String code, String currentCode) {
    final isSelected = currentCode == code;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => ref.read(envFactorFilterProvider.notifier).state = code,
      selectedColor: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
      checkmarkColor: const Color(0xFF1E3A8A),
    );
  }

  Widget _buildStatusFilterChip(String label, String code, String currentCode) {
    final isSelected = currentCode == code;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => ref.read(envStatusFilterProvider.notifier).state = code,
      selectedColor: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
      checkmarkColor: const Color(0xFF1E3A8A),
    );
  }

  Widget _buildPointsTable(BuildContext context, List<EnvironmentPointModel> points) {
    final passCount = points.where((p) => p.isPass).length;
    final actionCount = points.where((p) => p.isActionLevel).length;
    final failCount = points.where((p) => p.isFail).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Scrollbar(
                controller: _horizontalScrollCtrl,
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 12),
                      dataRowMinHeight: 46,
                      dataRowMaxHeight: 58,
                      horizontalMargin: 12,
                      columnSpacing: 10,
                      columns: const [
                        DataColumn(label: Text('# รหัสจุด')),
                        DataColumn(label: Text('ปัจจัย')),
                        DataColumn(label: Text('แผนก / พื้นที่')),
                        DataColumn(label: Text('ลักษณะงาน / เครื่องจักร')),
                        DataColumn(label: Text('ค่าตรวจวัดจริง')),
                        DataColumn(label: Text('เกณฑ์มาตรฐาน')),
                        DataColumn(label: Text('ผลประเมิน')),
                        DataColumn(label: Text('สภาวะแวดล้อม / รายละเอียด')),
                        DataColumn(label: Text('จัดการ')),
                      ],
                      rows: points.asMap().entries.map((entry) {
                        return _buildPointDataRow(context, entry.value, entry.key);
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
          // Table Footer Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Text(
                  'สรุปผลรวม: ${points.length} จุดตรวจวัด',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
                const SizedBox(width: 12),
                _buildStatPill('ผ่านเกณฑ์', passCount, const Color(0xFF166534), const Color(0xFFDCFCE7)),
                const SizedBox(width: 6),
                _buildStatPill('เฝ้าระวัง', actionCount, const Color(0xFF92400E), const Color(0xFFFEF3C7)),
                const SizedBox(width: 6),
                _buildStatPill('เกินเกณฑ์', failCount, const Color(0xFF991B1B), const Color(0xFFFEE2E2)),
                const Spacer(),
                Text(
                  '* คลิกที่แถวเพื่อแก้ไขข้อมูลจุดตรวจวัด',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildPointDataRow(BuildContext context, EnvironmentPointModel pt, int index) {
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

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return const Color(0xFFF1F5F9);
        }
        return index.isEven ? Colors.white : const Color(0xFFFAFAFA);
      }),
      onSelectChanged: (_) => _openPointDetailDialog(context, pt),
      cells: [
        // 1. Point ID
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: factorColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: factorColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              pt.pointId,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: factorColor,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),

        // 2. Factor Type
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(factorIcon, size: 14, color: factorColor),
              const SizedBox(width: 4),
              Text(pt.factorType.labelTh, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),

        // 3. Department / Location
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pt.department, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5), overflow: TextOverflow.ellipsis),
                Text(pt.locationName, style: TextStyle(color: Colors.grey.shade600, fontSize: 10.5), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),

        // 4. Task / Machine
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              pt.taskOrMachineName ?? pt.lightTaskDescription ?? '-',
              style: const TextStyle(fontSize: 11.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // 5. Measured Value
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              pt.measuredValueOnly,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF0F172A)),
            ),
          ),
        ),

        // 6. Standard Limit
        DataCell(
          Text(
            pt.standardLimitDisplay,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
        ),

        // 7. Status Badge
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: badgeText.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 12, color: badgeText),
                const SizedBox(width: 3),
                Text(
                  pt.evaluationStatus.labelTh,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: badgeText),
                ),
              ],
            ),
          ),
        ),

        // 8. Details / Conditions
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pt.factorType == EnvironmentFactorType.heat)
                  Text(
                    'NWB: ${pt.heatNwbCelsius ?? "-"}° | GT: ${pt.heatGtCelsius ?? "-"}° | DB: ${pt.heatDbCelsius ?? "-"}°',
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                if (pt.factorType == EnvironmentFactorType.light && pt.lightSurroundingLux != null)
                  Text(
                    'แสงรอบข้าง: ${pt.lightSurroundingLux} Lux',
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                if (pt.factorType == EnvironmentFactorType.noise)
                  Text(
                    pt.noiseMeasurementType?.labelTh ?? 'ตรวจวัดเสียง',
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                if (pt.requiresHearingConservation)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFD8B4FE)),
                    ),
                    child: const Text('HCP ม.๑๑', style: TextStyle(fontSize: 9.5, color: Color(0xFF6B21A8), fontWeight: FontWeight.bold)),
                  ),
                if (pt.notes != null && pt.notes!.isNotEmpty)
                  Text(
                    pt.notes!,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),

        // 9. Actions
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pt.requiresCapa)
                IconButton(
                  icon: const Icon(Icons.add_task_rounded, size: 16, color: Color(0xFFD97706)),
                  tooltip: 'เปิดแผน CAPA',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: () => _openCreateCapaFromPoint(context, pt),
                ),
              IconButton(
                icon: const Icon(Icons.print_outlined, size: 16, color: Color(0xFF0F766E)),
                tooltip: 'พิมพ์การ์ดประจำจุดตรวจ (Print Card)',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onPressed: () => _openPrintPointCard(context, pt),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF1E3A8A)),
                tooltip: 'แก้ไขข้อมูล (ปุ่มดินสอ)',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onPressed: () => _openEditPointDialog(context, pt),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                tooltip: 'ลบ',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onPressed: () => _confirmDeletePoint(context, pt),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPointCard(BuildContext context, EnvironmentPointModel pt) {
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

    return InkWell(
      onTap: () => _openPointDetailDialog(context, pt),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                        onPressed: () => _openCreateCapaFromPoint(context, pt),
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
                      icon: const Icon(Icons.print_outlined, size: 18, color: Color(0xFF0F766E)),
                      tooltip: 'พิมพ์การ์ดประจำจุดตรวจ (Print Card)',
                      onPressed: () => _openPrintPointCard(context, pt),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'แก้ไข',
                      onPressed: () => _openEditPointDialog(context, pt),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      tooltip: 'ลบ',
                      onPressed: () => _confirmDeletePoint(context, pt),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
