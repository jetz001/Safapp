import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/factory_scope_model.dart';
import '../notifiers/manual_providers.dart';

class FactoryScopeDialog extends ConsumerWidget {
  const FactoryScopeDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scopeAsync = ref.watch(factoryScopeProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ตั้งค่าขอบเขตความเสี่ยงโรงงาน',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Factory Risk & Machinery Scope',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: scopeAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $err', style: const TextStyle(color: Colors.red)),
          ),
          data: (scope) {
            final activeCount = scope.activeCount;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'บางโรงงานอาจไม่มีหม้อน้ำ ปั้นจั่น หรือพื้นที่อับอากาศ การปิดสวิตช์จะทำให้ระบบ "ตัดบทกฎเกณฑ์และ SOPs" ของอุปกรณ์นั้นออกจากคู่มือทั้ง 3 เล่มทันทีโดยอัตโนมัติ (ปัจจุบันเปิดใช้งาน $activeCount / 8 หมวด)',
                            style: TextStyle(color: Colors.blueGrey.shade800, fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSwitchTile(
                    context: context,
                    ref: ref,
                    field: 'hasBoiler',
                    value: scope.hasBoiler,
                    icon: Icons.soup_kitchen_rounded,
                    title: 'หม้อน้ำและหม้อต้ม (Boilers & Steam Generators)',
                    subtitle: 'ระบบหม้อน้ำความดันสูง หม้อต้มที่ใช้ของเหลวเป็นสื่อนำความร้อน',
                    color: const Color(0xFFDC2626),
                  ),
                  _buildSwitchTile(
                    context: context,
                    ref: ref,
                    field: 'hasCrane',
                    value: scope.hasCrane,
                    icon: Icons.precision_manufacturing_rounded,
                    title: 'ปั้นจั่น ลิฟต์ และรอกยกของ (Cranes & Lifting Equipment)',
                    subtitle: 'ปั้นจั่นเหนือศีรษะ ปั้นจั่นขาสูง ลิฟต์ขนส่งสินค้า และอุปกรณ์ช่วยยก',
                    color: const Color(0xFFD97706),
                  ),
                  _buildSwitchTile(
                    context: context,
                    ref: ref,
                    field: 'hasChemical',
                    value: scope.hasChemical,
                    icon: Icons.science_rounded,
                    title: 'สารเคมีอันตรายและวัตถุไวไฟ (Hazardous Chemicals & GHS)',
                    subtitle: 'คลังสารเคมี ระบบจ่ายสารเคมี ถังเก็บ และเอกสาร SDS',
                    color: const Color(0xFF9333EA),
                  ),
                  _buildSwitchTile(
                    context: context,
                    ref: ref,
                    field: 'hasConfinedSpace',
                    value: scope.hasConfinedSpace,
                    icon: Icons.door_sliding_rounded,
                    title: 'ที่อับอากาศ (Confined Spaces)',
                    subtitle: 'ถัง ไซโล อุโมงค์ ท่อ บ่อพักน้ำเสีย และระบบขออนุญาตทำงาน (PTW)',
                    color: const Color(0xFFEA580C),
                  ),
                  _buildSwitchTile(
                    context: context,
                    ref: ref,
                    field: 'hasWorkingAtHeight',
                    value: scope.hasWorkingAtHeight,
                    icon: Icons.stairs_rounded,
                    title: 'งานบนที่สูงและนั่งร้าน (Work at Heights & Scaffolding)',
                    subtitle: 'การทำงานที่มีระดับความต่างตั้งแต่ 2 เมตรขึ้นไป และนั่งร้านมาตรฐาน',
                    color: const Color(0xFF0284C7),
                  ),
                  _buildSwitchTile(
                    context: context,
                    ref: ref,
                    field: 'hasElectricalLoto',
                    value: scope.hasElectricalLoto,
                    icon: Icons.electrical_services_rounded,
                    title: 'ระบบไฟฟ้าและตัดแยกพลังงาน LOTO (Electrical & Energy Isolation)',
                    subtitle: 'ตู้ MDB หม้อแปลงไฟฟ้า ห้องควบคุมไฟฟ้า และกุญแจตัดแยกพลังงาน',
                    color: const Color(0xFFCA8A04),
                  ),
                  _buildSwitchTile(
                    context: context,
                    ref: ref,
                    field: 'hasEmergencyFire',
                    value: scope.hasEmergencyFire,
                    icon: Icons.local_fire_department_rounded,
                    title: 'แผนป้องกันและระงับอัคคีภัย (Fire Prevention & Emergency)',
                    subtitle: 'ถังดับเพลิง สายฉีดน้ำดับเพลิง เส้นทางหนีไฟ และการซ้อมอพยพประจำปี',
                    color: const Color(0xFFE11D48),
                  ),
                  _buildSwitchTile(
                    context: context,
                    ref: ref,
                    field: 'hasPpe',
                    value: scope.hasPpe,
                    icon: Icons.shield_rounded,
                    title: 'อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล (PPE Standards)',
                    subtitle: 'หมวกนิรภัย แว่นตา ที่อุดหู ถุงมือ และรองเท้าหัวเหล็กตาม มอก.',
                    color: const Color(0xFF16A34A),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            ref.read(factoryScopeProvider.notifier).updateScope(
                  const FactoryScopeModel(
                    hasBoiler: true,
                    hasCrane: true,
                    hasChemical: true,
                    hasConfinedSpace: true,
                    hasWorkingAtHeight: true,
                    hasElectricalLoto: true,
                    hasEmergencyFire: true,
                    hasPpe: true,
                  ),
                );
          },
          icon: const Icon(Icons.select_all, size: 18),
          label: const Text('เปิดใช้งานทั้งหมด (Default)'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('เสร็จสิ้น'),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required WidgetRef ref,
    required String field,
    required bool value,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: value ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value ? color.withValues(alpha: 0.3) : Colors.grey.shade300,
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: (val) {
          ref.read(factoryScopeProvider.notifier).toggleField(field, val);
        },
        activeThumbColor: color,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (value ? color : Colors.grey).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: value ? color : Colors.grey, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: value ? const Color(0xFF0F172A) : Colors.grey.shade600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: value ? Colors.blueGrey.shade700 : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}
