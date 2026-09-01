import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/environment_capa_model.dart';
import '../../domain/models/environment_standard_model.dart';
import '../providers/environment_providers.dart';
import '../widgets/add_edit_capa_dialog.dart';

/// Tab 2: CAPA Action Plan Tracker & Hearing Conservation Program (HCP) Module.
class EnvironmentCapaTab extends ConsumerWidget {
  const EnvironmentCapaTab({Key? key}) : super(key: key);

  void _openCreateCapaDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AddEditCapaDialog(),
    );
  }

  void _openEditCapaDialog(BuildContext context, WidgetRef ref, EnvironmentCapaModel capa) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEditCapaDialog(capaItem: capa),
    );
  }

  void _confirmCloseCapa(BuildContext context, WidgetRef ref, EnvironmentCapaModel capa) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('ยืนยันปิดงาน CAPA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณต้องการปิดแผนงาน "${capa.actionTitle}" ใช่หรือไม่?'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                hintText: 'ระบุหมายเหตุการปิดงาน / ผลการทวนสอบสภาพแวดล้อม...',
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final updated = capa.copyWith(
                status: 'COMPLETED',
                completedDate: DateTime.now().toIso8601String().substring(0, 10),
                notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : capa.notes,
              );
              await ref.read(envCapaListProvider.notifier).saveCapa(updated);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ปิดงาน CAPA สำเร็จ'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text('ยืนยันปิดงาน'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCapa(BuildContext context, WidgetRef ref, EnvironmentCapaModel capa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('ยืนยันการลบ CAPA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('คุณต้องการลบแผนงาน "${capa.actionTitle}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(envCapaListProvider.notifier).deleteCapa(capa.capaId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ลบแผนงาน CAPA แล้ว'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capasAsync = ref.watch(envCapaListProvider);
    final statusFilter = ref.watch(envCapaStatusFilterProvider);
    final pointsAsync = ref.watch(envPointListProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // --------------------------------------------------------------------
        // 1. Hearing Conservation Program (HCP) Banner (Clause 11)
        // --------------------------------------------------------------------
        pointsAsync.when(
          data: (points) {
            final hcpPoints = points.where((p) => p.requiresHearingConservation).toList();
            if (hcpPoints.isEmpty) return const SizedBox();

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF581C87), Color(0xFF6B21A8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF581C87).withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.hearing_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'โครงการอนุรักษ์การได้ยิน (Hearing Conservation Program - HCP)',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'ตามข้อ ๑๑ แห่งกฎกระทรวงฯ ๒๕๕๙: สถานประกอบการที่มีระดับเสียงเฉลี่ย 8 ชม. >= 85 dBA ต้องจัดทำโครงการอนุรักษ์การได้ยิน',
                              style: TextStyle(fontSize: 11.5, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${hcpPoints.length} จุดเฝ้าระวัง',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF581C87)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: hcpPoints.map((p) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.volume_up_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              '${p.pointId}: ${p.locationName} (${p.noiseMeasuredDba?.toStringAsFixed(1) ?? "-"} dBA)',
                              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),

        // --------------------------------------------------------------------
        // 2. Toolbar & Status Filter
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'ค้นหาแผน CAPA, หัวข้อ, สาเหตุรากเหง้า, หรือผู้รับผิดชอบ...',
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
                        ref.read(envCapaSearchQueryProvider.notifier).state = v;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: () => _openCreateCapaDialog(context, ref),
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: const Text('เปิดแผน CAPA ใหม่'),
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

              Row(
                children: [
                  const Text('สถานะแผนงาน:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _buildStatusChip(ref, 'ทั้งหมด', 'ALL', statusFilter),
                  const SizedBox(width: 6),
                  _buildStatusChip(ref, 'รอดำเนินการ', 'PENDING', statusFilter),
                  const SizedBox(width: 6),
                  _buildStatusChip(ref, 'กำลังดำเนินการ', 'IN_PROGRESS', statusFilter),
                  const SizedBox(width: 6),
                  _buildStatusChip(ref, 'เสร็จสิ้นแล้ว', 'COMPLETED', statusFilter),
                  const SizedBox(width: 6),
                  _buildStatusChip(ref, 'เกินกำหนด (Overdue)', 'OVERDUE', statusFilter),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --------------------------------------------------------------------
        // 3. CAPA Items List
        // --------------------------------------------------------------------
        capasAsync.when(
          data: (capas) {
            if (capas.isEmpty) {
              return _buildEmptyState(
                title: 'ไม่พบรายการแผนงาน CAPA',
                subtitle: 'ผลการตรวจวัดสอดคล้องตามเกณฑ์ หรือไม่มีรายการที่ตรงกับตัวกรอง',
                onReset: () {
                  ref.read(envCapaSearchQueryProvider.notifier).clear();
                  ref.read(envCapaStatusFilterProvider.notifier).reset();
                },
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: capas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final capa = capas[i];
                return _buildCapaCard(context, ref, capa);
              },
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
          error: (err, _) => Center(child: Text('เกิดข้อผิดพลาด: $err', style: const TextStyle(color: Colors.red))),
        ),
      ],
    );
  }

  Widget _buildStatusChip(WidgetRef ref, String label, String code, String currentCode) {
    final isSelected = currentCode == code;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => ref.read(envCapaStatusFilterProvider.notifier).state = code,
      selectedColor: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
      checkmarkColor: const Color(0xFF1E3A8A),
    );
  }

  Widget _buildCapaCard(BuildContext context, WidgetRef ref, EnvironmentCapaModel c) {
    final isDone = c.isCompleted;
    final isOverdue = c.isOverdue;

    Color statusColor;
    Color statusBg;
    if (isDone) {
      statusColor = const Color(0xFF166534);
      statusBg = const Color(0xFFDCFCE7);
    } else if (isOverdue) {
      statusColor = const Color(0xFF991B1B);
      statusBg = const Color(0xFFFEE2E2);
    } else if (c.status.toUpperCase() == 'IN_PROGRESS') {
      statusColor = const Color(0xFF1E40AF);
      statusBg = const Color(0xFFDBEAFE);
    } else {
      statusColor = const Color(0xFF854D0E);
      statusBg = const Color(0xFFFEF9C3);
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
              color: statusBg.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    c.capaId,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ปัจจัย: ${c.factorType.labelTh}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
                if (c.pointId != null) ...[
                  const SizedBox(width: 8),
                  Text('• จุดตรวจ: ${c.pointId}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    c.statusLabelTh,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
          ),

          // Main Card Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.actionTitle,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'สภาพปัญหา: ${c.hazardDescription}',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                Text(
                  'สาเหตุรากเหง้า: ${c.rootCause}',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),

                // 3-Tier Controls Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'มาตรการควบคุมตามลำดับขั้นความปลอดภัย (Hierarchy of Controls):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(height: 6),
                      if (c.engineeringControl != null && c.engineeringControl!.isNotEmpty)
                        _buildControlRow('๑. วิศวกรรม:', c.engineeringControl!, const Color(0xFF2563EB)),
                      if (c.administrativeControl != null && c.administrativeControl!.isNotEmpty)
                        _buildControlRow('๒. บริหารจัดการ:', c.administrativeControl!, const Color(0xFFD97706)),
                      if (c.ppeControl != null && c.ppeControl!.isNotEmpty)
                        _buildControlRow('๓. PPE:', c.ppeControl!, const Color(0xFF16A34A)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // PIC & Dates
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('ผู้รับผิดชอบ: ${c.picName}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'กำหนดเสร็จ: ${c.targetDate}${isOverdue ? " (เกินกำหนด)" : ""}',
                      style: TextStyle(fontSize: 12, color: isOverdue ? Colors.red : Colors.grey.shade700, fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal),
                    ),
                    if (c.completedDate != null && c.completedDate!.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text('เสร็จจริง: ${c.completedDate}', style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Actions Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isDone) ...[
                      ElevatedButton.icon(
                        onPressed: () => _confirmCloseCapa(context, ref, c),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('ปิดงาน CAPA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'แก้ไข',
                      onPressed: () => _openEditCapaDialog(context, ref, c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      tooltip: 'ลบ',
                      onPressed: () => _confirmDeleteCapa(context, ref, c),
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

  Widget _buildControlRow(String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(title, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
          ),
          Expanded(
            child: Text(desc, style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155))),
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
            const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF10B981)),
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
