import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/ppe_item_model.dart';
import '../providers/ppe_providers.dart';

class PpeQuickPickerDialog extends ConsumerStatefulWidget {
  const PpeQuickPickerDialog({super.key});

  @override
  ConsumerState<PpeQuickPickerDialog> createState() => _PpeQuickPickerDialogState();
}

class _PpeQuickPickerDialogState extends ConsumerState<PpeQuickPickerDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<PpeItem> _selectedItems = {};
  String _selectedCategory = 'ALL';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ppeItemsAsync = ref.watch(ppeItemsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 720,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield, color: Color(0xFF2563EB), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เลือกอุปกรณ์คุ้มครองความปลอดภัย (PPE) ตาม ม.๒๒',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'เลือกอุปกรณ์ที่ต้องสวมใส่เพื่อนำไปเป็นมาตรการควบคุมใน JSA / แผนงานความปลอดภัย',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Search Bar & Categories
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'ค้นหาชื่อ หรือ มาตรฐาน (มอก./EN)...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: [
                    const DropdownMenuItem(value: 'ALL', child: Text('ทุกหมวดหมู่')),
                    ...PpeCategory.values.map(
                      (c) => DropdownMenuItem(value: c.code, child: Text(c.labelTh)),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCategory = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Selected count badge
            if (_selectedItems.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'เลือกแล้ว ${_selectedItems.length} รายการ: ${_selectedItems.map((e) => e.name).join(", ")}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

            // List of PPE items with Checkboxes
            Expanded(
              child: ppeItemsAsync.when(
                data: (items) {
                  final filtered = items.where((it) {
                    final matchesSearch = _searchCtrl.text.isEmpty ||
                        it.name.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
                        it.code.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
                        it.standardCert.toLowerCase().contains(_searchCtrl.text.toLowerCase());
                    final matchesCat = _selectedCategory == 'ALL' || it.category.code == _selectedCategory;
                    return matchesSearch && matchesCat;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('ไม่พบรายการอุปกรณ์ PPE'));
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final item = filtered[idx];
                      final isSelected = _selectedItems.any((e) => e.id == item.id);

                      return CheckboxListTile(
                        value: isSelected,
                        activeColor: const Color(0xFF2563EB),
                        title: Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${item.code} | มาตรฐาน: ${item.standardCert} | คงเหลือ: ${item.currentStock} ${item.unit}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        secondary: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(item.category.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedItems.add(item);
                            } else {
                              _selectedItems.removeWhere((e) => e.id == item.id);
                            }
                          });
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() => _selectedItems.clear()),
                  child: const Text('ล้างการเลือกทั้งหมด'),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('ยกเลิก'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(_selectedItems.toList());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text('นำไปใช้ (${_selectedItems.length} รายการ)'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
