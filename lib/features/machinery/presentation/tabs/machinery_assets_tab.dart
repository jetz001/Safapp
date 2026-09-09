import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/machinery_asset_model.dart';
import '../notifiers/machinery_providers.dart';

class MachineryAssetsTab extends ConsumerStatefulWidget {
  const MachineryAssetsTab({super.key});

  @override
  ConsumerState<MachineryAssetsTab> createState() => _MachineryAssetsTabState();
}

class _MachineryAssetsTabState extends ConsumerState<MachineryAssetsTab> {
  String _selectedCategory = 'ALL';

  void _showAddEditAssetDialog([MachineryAssetModel? existing]) {
    final formKey = GlobalKey<FormState>();
    final tagCtrl = TextEditingController(text: existing?.assetTag ?? '');
    final nameCtrl = TextEditingController(text: existing?.assetName ?? '');
    final capCtrl = TextEditingController(text: existing?.ratedCapacity ?? '');
    final locCtrl = TextEditingController(text: existing?.location ?? '');
    final brandCtrl = TextEditingController(text: existing?.manufacturerBrand ?? '');
    final serialCtrl = TextEditingController(text: existing?.serialNo ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    String category = existing?.category ?? 'SLING_WIRE';
    String status = existing?.status ?? 'READY';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDlgState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.handyman_outlined, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Text(existing == null ? 'เพิ่มทะเบียนเครื่องจักร / อุปกรณ์ช่วยยก' : 'แก้ไขข้อมูลอุปกรณ์'),
            ],
          ),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration: const InputDecoration(labelText: 'หมวดหมู่อุปกรณ์ *', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'CRANE', child: Text('ปั้นจั่น (Crane)')),
                              DropdownMenuItem(value: 'HOIST', child: Text('รอกไฟฟ้า / กว้าน (Hoist)')),
                              DropdownMenuItem(value: 'SLING_WIRE', child: Text('ลวดสลิงยกของ (Wire Rope Sling)')),
                              DropdownMenuItem(value: 'SLING_WEBBING', child: Text('สายรัดผ้าใบ (Webbing Sling)')),
                              DropdownMenuItem(value: 'CHAIN', child: Text('โซ่ยกของ (Lifting Chain)')),
                              DropdownMenuItem(value: 'SHACKLE', child: Text('สะเก็น / ห่วงคล้อง (Shackle)')),
                              DropdownMenuItem(value: 'MACHINE_GUARD', child: Text('การ์ดป้องกันจุดอันตราย (Machine Guard)')),
                            ],
                            onChanged: (v) {
                              if (v != null) setDlgState(() => category = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: status,
                            decoration: const InputDecoration(labelText: 'สถานะความพร้อม *', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'READY', child: Text('พร้อมใช้งาน (READY)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                              DropdownMenuItem(value: 'DEFECTIVE', child: Text('ชำรุดห้ามใช้ (DEFECTIVE)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                              DropdownMenuItem(value: 'IN_REPAIR', child: Text('อยู่ระหว่างซ่อม (IN REPAIR)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                              DropdownMenuItem(value: 'RETIRED', child: Text('ปลดระวาง (RETIRED)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                            ],
                            onChanged: (v) {
                              if (v != null) setDlgState(() => status = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: tagCtrl,
                            decoration: const InputDecoration(labelText: 'รหัสอุปกรณ์ (Asset Tag) *', hintText: 'e.g. SLING-01', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุรหัส' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(labelText: 'ชื่อและรายละเอียดอุปกรณ์ *', hintText: 'e.g. ลวดสลิงถัก 4 ขา 16 มม.', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อ' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: capCtrl,
                            decoration: const InputDecoration(labelText: 'พิกัดน้ำหนักปลอดภัย (WLL / Capacity)', hintText: 'e.g. WLL 5.0 Ton', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: locCtrl,
                            decoration: const InputDecoration(labelText: 'สถานที่ติดตั้ง / จัดเก็บ *', hintText: 'e.g. อาคารผลิต 1', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุสถานที่' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: brandCtrl,
                            decoration: const InputDecoration(labelText: 'ยี่ห้อ / ผู้ผลิต (Brand)', hintText: 'e.g. Crosby, KISWIRE', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: serialCtrl,
                            decoration: const InputDecoration(labelText: 'Serial No. / Tag Code', hintText: 'e.g. SN-99812', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'หมายเหตุ / เงื่อนไขการใช้งาน', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final asset = MachineryAssetModel(
                  id: existing?.id,
                  assetTag: tagCtrl.text.trim(),
                  assetName: nameCtrl.text.trim(),
                  category: category,
                  ratedCapacity: capCtrl.text.trim().isEmpty ? null : capCtrl.text.trim(),
                  location: locCtrl.text.trim(),
                  manufacturerBrand: brandCtrl.text.trim().isEmpty ? null : brandCtrl.text.trim(),
                  serialNo: serialCtrl.text.trim().isEmpty ? null : serialCtrl.text.trim(),
                  status: status,
                  lastInspectedDate: DateTime.now().toIso8601String().substring(0, 10),
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  createdAt: existing?.createdAt,
                );

                await ref.read(machineryAssetListProvider.notifier).saveAsset(asset);
                if (!mounted) return;
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('บันทึกข้อมูลอุปกรณ์สำเร็จ'), backgroundColor: Color(0xFF16A34A)),
                );
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(machineryAssetListProvider);

    return assetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
      data: (assets) {
        final filteredAssets = _selectedCategory == 'ALL'
            ? assets
            : assets.where((a) => a.category == _selectedCategory).toList();

        final total = assets.length;
        final ready = assets.where((a) => a.status == 'READY').length;
        final defective = assets.where((a) => a.status == 'DEFECTIVE').length;
        final inRepair = assets.where((a) => a.status == 'IN_REPAIR').length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // KPI Bar
            Row(
              children: [
                _buildMetricCard('อุปกรณ์ทั้งหมด', '$total ชิ้น', Icons.category_outlined, const Color(0xFF0284C7)),
                const SizedBox(width: 12),
                _buildMetricCard('พร้อมใช้งาน (READY)', '$ready ชิ้น', Icons.check_circle_outline, const Color(0xFF16A34A)),
                const SizedBox(width: 12),
                _buildMetricCard('ชำรุดห้ามใช้ (DEFECTIVE)', '$defective ชิ้น', Icons.cancel_outlined, const Color(0xFFDC2626)),
                const SizedBox(width: 12),
                _buildMetricCard('กำลังซ่อมบำรุง', '$inRepair ชิ้น', Icons.build_outlined, const Color(0xFFF59E0B)),
              ],
            ),
            const SizedBox(height: 16),

            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ทั้งหมด', 'ALL'),
                  _buildFilterChip('ปั้นจั่น (Crane)', 'CRANE'),
                  _buildFilterChip('รอกไฟฟ้า (Hoist)', 'HOIST'),
                  _buildFilterChip('สลิงยก (Wire Rope)', 'SLING_WIRE'),
                  _buildFilterChip('สายรัดผ้าใบ (Webbing)', 'SLING_WEBBING'),
                  _buildFilterChip('โซ่ยก (Chain)', 'CHAIN'),
                  _buildFilterChip('สะเก็น (Shackle)', 'SHACKLE'),
                  _buildFilterChip('การ์ดเครื่องจักร (Guard)', 'MACHINE_GUARD'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Header & Add
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รายการอุปกรณ์ (${filteredAssets.length} รายการ)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                FilledButton.icon(
                  onPressed: () => _showAddEditAssetDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('เพิ่มอุปกรณ์'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (filteredAssets.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: const Text('ไม่พบรายการอุปกรณ์ในหมวดหมู่นี้', style: TextStyle(color: Colors.grey)),
              )
            else
              ...filteredAssets.map((a) => _buildAssetCard(a)),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String code) {
    final isSelected = _selectedCategory == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
        checkmarkColor: const Color(0xFF0284C7),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? const Color(0xFF0284C7) : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => setState(() => _selectedCategory = code),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetCard(MachineryAssetModel asset) {
    Color statusColor = Colors.green;
    if (asset.status == 'DEFECTIVE') statusColor = Colors.red;
    if (asset.status == 'IN_REPAIR') statusColor = Colors.orange;
    if (asset.status == 'RETIRED') statusColor = Colors.grey;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.handyman, color: statusColor, size: 24),
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
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Text(asset.assetTag, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Text(asset.categoryTh, style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600)),
                      const Spacer(),
                      DropdownButton<String>(
                        value: asset.status,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'READY', child: Text('พร้อมใช้งาน', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'DEFECTIVE', child: Text('ชำรุดห้ามใช้', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'IN_REPAIR', child: Text('อยู่ระหว่างซ่อม', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'RETIRED', child: Text('ปลดระวาง', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))),
                        ],
                        onChanged: (newStat) {
                          if (newStat != null && asset.id != null) {
                            ref.read(machineryAssetListProvider.notifier).setStatus(asset.id!, newStat);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(asset.assetName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (asset.ratedCapacity != null) ...[
                        Icon(Icons.scale, size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('พิกัด: ${asset.ratedCapacity}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        const SizedBox(width: 16),
                      ],
                      Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(asset.location, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      if (asset.manufacturerBrand != null) ...[
                        const SizedBox(width: 16),
                        Text('ยี่ห้อ: ${asset.manufacturerBrand}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      ],
                    ],
                  ),
                  if (asset.notes != null && asset.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('หมายเหตุ: ${asset.notes}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
              onPressed: () => _showAddEditAssetDialog(asset),
              tooltip: 'แก้ไข',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('ยืนยันการลบ'),
                    content: Text('ต้องการลบอุปกรณ์ ${asset.assetName} หรือไม่?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
                      FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('ลบ')),
                    ],
                  ),
                );
                if (ok == true && asset.id != null) {
                  await ref.read(machineryAssetListProvider.notifier).deleteAsset(asset.id!);
                }
              },
              tooltip: 'ลบ',
            ),
          ],
        ),
      ),
    );
  }
}
