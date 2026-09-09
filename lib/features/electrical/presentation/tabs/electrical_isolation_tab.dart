import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/circuit_breaker_model.dart';
import '../notifiers/electrical_providers.dart';

class ElectricalIsolationTab extends ConsumerStatefulWidget {
  const ElectricalIsolationTab({super.key});

  @override
  ConsumerState<ElectricalIsolationTab> createState() => _ElectricalIsolationTabState();
}

class _ElectricalIsolationTabState extends ConsumerState<ElectricalIsolationTab> {
  void _showAddEditBreakerDialog([CircuitBreakerModel? existing]) {
    final tagCtrl = TextEditingController(text: existing?.equipmentTag ?? '');
    final nameCtrl = TextEditingController(text: existing?.equipmentName ?? '');
    final bldCtrl = TextEditingController(text: existing?.locationBuilding ?? '');
    final floorCtrl = TextEditingController(text: existing?.locationFloor ?? '');
    final typeCtrl = TextEditingController(text: existing?.breakerType ?? 'Air Circuit Breaker (ACB)');
    final ampCtrl = TextEditingController(text: existing?.ratedCurrentAmp?.toString() ?? '1000');
    final upstreamCtrl = TextEditingController(text: existing?.upstreamSource ?? '');
    final operatorCtrl = TextEditingController(text: existing?.authorizedOperator ?? '');
    final sldCtrl = TextEditingController(text: existing?.singleLineDiagramRef ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    String voltageLevel = existing?.voltageLevel ?? 'LOW_VOLTAGE';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bolt, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 12),
              Text(existing == null ? 'เพิ่มจุดตัดแยกพลังงาน / เบรกเกอร์' : 'แก้ไขข้อมูลเบรกเกอร์'),
            ],
          ),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tagCtrl,
                          decoration: const InputDecoration(
                            labelText: 'รหัสอุปกรณ์ (Equipment Tag) *',
                            hintText: 'e.g. MDB-01-ACB',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: voltageLevel,
                          decoration: const InputDecoration(
                            labelText: 'ระดับแรงดันไฟฟ้า',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'LOW_VOLTAGE', child: Text('แรงต่ำ (< 1,000V)')),
                            DropdownMenuItem(value: 'HIGH_VOLTAGE', child: Text('แรงสูง (>= 1,000V)')),
                          ],
                          onChanged: (v) {
                            if (v != null) setDlgState(() => voltageLevel = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อตู้ / เบรกเกอร์ / อุปกรณ์ *',
                      hintText: 'e.g. ตู้สวิตช์บอร์ดหลัก อาคารผลิต 1',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: bldCtrl,
                          decoration: const InputDecoration(
                            labelText: 'อาคาร / โรงงาน *',
                            hintText: 'e.g. อาคารผลิต 1',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: floorCtrl,
                          decoration: const InputDecoration(
                            labelText: 'ชั้น / ห้องควบคุม',
                            hintText: 'e.g. ชั้น 1 ห้อง MDB',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: typeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'ประเภทเบรกเกอร์ (Breaker Type)',
                            hintText: 'e.g. ACB, MCCB, MCB, VCB',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: ampCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'พิกัดกระแส (Rated Amp)',
                            hintText: 'e.g. 1600 A',
                            border: OutlineInputBorder(),
                            suffixText: 'A',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: upstreamCtrl,
                    decoration: const InputDecoration(
                      labelText: 'แหล่งจ่ายไฟต้นทาง (Upstream Source)',
                      hintText: 'e.g. หม้อแปลง TR-01 (1,000 kVA)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: operatorCtrl,
                          decoration: const InputDecoration(
                            labelText: 'ผู้มีสิทธิ์สั่งสับปลดวงจร',
                            hintText: 'e.g. วิศวกรไฟฟ้า / ช่างเทคนิคอาวุโส',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: sldCtrl,
                          decoration: const InputDecoration(
                            labelText: 'รหัสผังวงจร (Single Line Ref)',
                            hintText: 'e.g. SLD-DWG-001',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'หมายเหตุ / ข้อกำหนดความปลอดภัย',
                      hintText: 'e.g. ต้องสวมชุด Arc Flash Class 2 ก่อนเปิดตู้',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
              onPressed: () async {
                if (tagCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty || bldCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณากรอกรหัสอุปกรณ์ ชื่อ และอาคารที่ตั้ง'), backgroundColor: Colors.red),
                  );
                  return;
                }

                final breaker = CircuitBreakerModel(
                  id: existing?.id,
                  equipmentTag: tagCtrl.text.trim(),
                  equipmentName: nameCtrl.text.trim(),
                  locationBuilding: bldCtrl.text.trim(),
                  locationFloor: floorCtrl.text.trim().isEmpty ? null : floorCtrl.text.trim(),
                  voltageLevel: voltageLevel,
                  ratedCurrentAmp: double.tryParse(ampCtrl.text.trim()),
                  breakerType: typeCtrl.text.trim(),
                  upstreamSource: upstreamCtrl.text.trim().isEmpty ? null : upstreamCtrl.text.trim(),
                  isLocked: existing?.isLocked ?? false,
                  lockoutTagNo: existing?.lockoutTagNo,
                  lockedBy: existing?.lockedBy,
                  lockedAt: existing?.lockedAt,
                  zeroEnergyVerified: existing?.zeroEnergyVerified ?? false,
                  authorizedOperator: operatorCtrl.text.trim().isEmpty ? null : operatorCtrl.text.trim(),
                  singleLineDiagramRef: sldCtrl.text.trim().isEmpty ? null : sldCtrl.text.trim(),
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                );

                await ref.read(circuitBreakerListProvider.notifier).saveBreaker(breaker);
                if (!mounted) return;
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('บันทึกข้อมูลเบรกเกอร์สำเร็จ'), backgroundColor: Color(0xFF16A34A)),
                );
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLotoActionDialog(CircuitBreakerModel breaker) {
    final isCurrentlyLocked = breaker.isLocked;
    final tagCtrl = TextEditingController(text: breaker.lockoutTagNo ?? 'LOTO-${breaker.equipmentTag}-${DateTime.now().millisecondsSinceEpoch % 10000}');
    final nameCtrl = TextEditingController(text: breaker.lockedBy ?? 'ช่างเทคนิคไฟฟ้า');
    bool verifyZero = breaker.zeroEnergyVerified;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isCurrentlyLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                color: isCurrentlyLocked ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              ),
              const SizedBox(width: 10),
              Text(isCurrentlyLocked ? 'ปลดล็อค LOTO (Restore)' : 'คล้องกุญแจล็อค LOTO'),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${breaker.equipmentTag} : ${breaker.equipmentName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('ตำแหน่ง: ${breaker.locationBuilding} ${breaker.locationFloor ?? ""}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      Text('พิกัด: ${breaker.breakerType} ${breaker.ratedCurrentAmp != null ? "${breaker.ratedCurrentAmp}A" : ""}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!isCurrentlyLocked) ...[
                  TextField(
                    controller: tagCtrl,
                    decoration: const InputDecoration(
                      labelText: 'หมายเลขแม่กุญแจ / ป้าย LOTO (Padlock & Tag No.) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อผู้ลงกุญแจและป้ายเตือน *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: verifyZero,
                    onChanged: (v) => setDlgState(() => verifyZero = v ?? false),
                    title: const Text('ตรวจสอบพลังงานตกค้างเป็นศูนย์แล้ว (Zero Energy)'),
                    subtitle: const Text('วัดแรงดันไฟฟ้าด้วยมัลติมิเตอร์ยืนยัน 0 Volt'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ] else ...[
                  const Text('ต้องการปลดกุญแจ LOTO และจ่ายพลังงานไฟฟ้าคืนสู่ระบบหรือไม่?'),
                  const SizedBox(height: 8),
                  Text('กุญแจที่ล็อคอยู่: ${breaker.lockoutTagNo ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('ผู้ล็อคไว้: ${breaker.lockedBy ?? "-"} (${breaker.lockedAt?.substring(0, 16) ?? "-"})'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isCurrentlyLocked ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              ),
              onPressed: () async {
                if (breaker.id == null) return;
                await ref.read(circuitBreakerListProvider.notifier).toggleLock(
                  id: breaker.id!,
                  isLocked: !isCurrentlyLocked,
                  lockoutTagNo: !isCurrentlyLocked ? tagCtrl.text.trim() : null,
                  lockedBy: !isCurrentlyLocked ? nameCtrl.text.trim() : null,
                  zeroEnergyVerified: !isCurrentlyLocked ? verifyZero : false,
                );
                if (!mounted) return;
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(!isCurrentlyLocked ? 'ล็อค LOTO สำเร็จ' : 'ปลดล็อค LOTO เรียบร้อยแล้ว'),
                    backgroundColor: !isCurrentlyLocked ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  ),
                );
              },
              child: Text(isCurrentlyLocked ? 'ยืนยันปลดล็อค' : 'ยืนยันคล้องกุญแจ LOTO'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteBreaker(CircuitBreakerModel breaker) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันลบข้อมูลเบรกเกอร์'),
          ],
        ),
        content: Text('ต้องการลบจุดตัดแยก ${breaker.equipmentTag} (${breaker.equipmentName}) ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบรายการ'),
          ),
        ],
      ),
    );

    if (ok == true && breaker.id != null) {
      await ref.read(circuitBreakerListProvider.notifier).deleteBreaker(breaker.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบรายการสำเร็จ')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final breakersAsync = ref.watch(circuitBreakerListProvider);

    return breakersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
      data: (breakers) {
        final totalCount = breakers.length;
        final lockedCount = breakers.where((b) => b.isLocked).length;
        final safeCount = totalCount - lockedCount;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock_rounded, color: Color(0xFFD97706), size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'การตัดแยกพลังงานไฟฟ้า & แผนผังวงจร (LOTO & Isolation Map)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF92400E)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ทะเบียนจุดตัดแยกกระแสไฟหลัก (Main Breakers) และระบบปฏิบัติการ Lockout / Tagout ตามกฎกระทรวงความปลอดภัยเกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘ ข้อ ๒๐',
                          style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary Stats KPI Cards
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'จุดตัดแยกทั้งหมด',
                    value: '$totalCount จุด',
                    icon: Icons.power_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'กำลังล็อค LOTO อยู่',
                    value: '$lockedCount จุด',
                    icon: Icons.lock_rounded,
                    color: lockedCount > 0 ? const Color(0xFFDC2626) : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'จ่ายกระแสไฟฟ้าปกติ',
                    value: '$safeCount จุด',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Header & Add Breaker Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ทะเบียนจุดตัดไฟหลัก & ตู้สวิตช์บอร์ด (Breakers Inventory)',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'กดปุ่ม "LOTO" เพื่อสั่งคล้องกุญแจล็อคจุดตัดไฟ หรือกดแก้ไขข้อมูลจุดติดตั้ง',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _showAddEditBreakerDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('เพิ่มจุดตัดแยกพลังงาน'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Breakers List Cards
            if (breakers.isEmpty)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
                child: const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.power_off_rounded, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('ยังไม่มีจุดตัดแยกพลังงานในระบบ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('กดปุ่ม "เพิ่มจุดตัดแยกพลังงาน" เพื่อเริ่มสร้างผังควบคุม', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...breakers.map((b) => _buildBreakerCard(b)),

            const SizedBox(height: 20),

            // 6-step LOTO guideline
            _buildLotoGuidelineCard(),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakerCard(CircuitBreakerModel b) {
    final isLocked = b.isLocked;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isLocked ? const Color(0xFFF87171) : Colors.grey.shade200,
          width: isLocked ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isLocked ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isLocked ? Icons.lock_rounded : Icons.power_rounded,
                    color: isLocked ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              b.equipmentTag,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isLocked ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isLocked ? '🔒 กำลังล็อค LOTO' : '⚡ จ่ายไฟปกติ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: isLocked ? const Color(0xFFDC2626) : const Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(b.equipmentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        'ที่ตั้ง: ${b.locationBuilding} ${b.locationFloor != null ? "• ${b.locationFloor}" : ""}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showLotoActionDialog(b),
                      icon: Icon(isLocked ? Icons.lock_open : Icons.lock, size: 16),
                      label: Text(isLocked ? 'ปลดล็อค' : 'คล้องกุญแจ LOTO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLocked ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showAddEditBreakerDialog(b),
                      tooltip: 'แก้ไขข้อมูล',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      onPressed: () => _confirmDeleteBreaker(b),
                      tooltip: 'ลบรายการ',
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            // Technical specs row
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _buildSpecItem('ประเภท', b.breakerType),
                if (b.ratedCurrentAmp != null) _buildSpecItem('พิกัดกระแส', '${b.ratedCurrentAmp} A'),
                if (b.upstreamSource != null) _buildSpecItem('แหล่งจ่ายต้นทาง', b.upstreamSource!),
                if (b.authorizedOperator != null) _buildSpecItem('ผู้มีสิทธิ์สับปลด', b.authorizedOperator!),
                if (b.singleLineDiagramRef != null) _buildSpecItem('ผัง SLD', b.singleLineDiagramRef!),
              ],
            ),
            if (isLocked) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'กุญแจหมายเลข: ${b.lockoutTagNo ?? "-"} • ผู้ล็อค: ${b.lockedBy ?? "-"} • สถานะพลังงานศูนย์: ${b.zeroEnergyVerified ? "✓ ยืนยันแล้ว (0V)" : "⚠ ยังไม่ยืนยัน"}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildLotoGuidelineCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.rule_rounded, color: Color(0xFFD97706)),
                SizedBox(width: 8),
                Text('กฎเหล็ก 6 ขั้นตอน Lockout / Tagout (LOTO)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            Divider(height: 20),
            Text('1. แจ้งเตือนผู้เกี่ยวข้องและขออนุมัติใบงาน PTW งานไฟฟ้าแรงสูง', style: TextStyle(fontSize: 12.5)),
            SizedBox(height: 4),
            Text('2. ปิดสวิตช์และสับปลดวงจร (De-energize)', style: TextStyle(fontSize: 12.5)),
            SizedBox(height: 4),
            Text('3. คล้องกุญแจล็อค (Lockout) และแขวนป้ายเตือนอันตราย (Tagout)', style: TextStyle(fontSize: 12.5)),
            SizedBox(height: 4),
            Text('4. ตรวจวัดและคายประจุตกค้าง (Verify Zero Energy 0 Volt)', style: TextStyle(fontSize: 12.5)),
            SizedBox(height: 4),
            Text('5. ปฏิบัติงานด้วยความปลอดภัยตามใบอนุญาต', style: TextStyle(fontSize: 12.5)),
            SizedBox(height: 4),
            Text('6. ตรวจความพร้อม ถอดกุญแจ และจ่ายกระแสไฟคืนระบบอย่างปลอดภัย', style: TextStyle(fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}
