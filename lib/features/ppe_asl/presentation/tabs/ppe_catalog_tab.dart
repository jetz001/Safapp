import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/ppe_item_model.dart';
import '../../domain/models/ppe_transaction_model.dart';
import '../providers/ppe_providers.dart';
import '../widgets/ppe_item_dialog.dart';
import '../widgets/ppe_transaction_dialog.dart';
import '../../services/ppe_excel_exporter.dart';

class PpeCatalogTab extends ConsumerStatefulWidget {
  const PpeCatalogTab({super.key});

  @override
  ConsumerState<PpeCatalogTab> createState() => _PpeCatalogTabState();
}

class _PpeCatalogTabState extends ConsumerState<PpeCatalogTab> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ppeItemsAsync = ref.watch(ppeItemsProvider);
    final selectedCategory = ref.watch(ppeCategoryFilterProvider);
    final isLowStockOnly = ref.watch(ppeLowStockFilterProvider);

    return Column(
      children: [
        // ── Top Search & Action Bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: Colors.white,
          child: Row(
            children: [
              // Search Input
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'ค้นหาชื่ออุปกรณ์, รหัส, มาตรฐาน (มอก./ANSI)...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(ppeSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) {
                    ref.read(ppeSearchQueryProvider.notifier).state = val;
                  },
                ),
              ),
              const SizedBox(width: 14),

              // Low Stock Toggle
              FilterChip(
                selected: isLowStockOnly,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: isLowStockOnly ? Colors.white : Colors.amber.shade800,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'เฉพาะของใกล้หมด (Low Stock)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isLowStockOnly ? Colors.white : Colors.black87,
                        fontWeight: isLowStockOnly ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                selectedColor: const Color(0xFFDC2626),
                backgroundColor: Colors.grey.shade100,
                onSelected: (val) {
                  ref.read(ppeLowStockFilterProvider.notifier).state = val;
                },
              ),
              const Spacer(),

              // Export Excel Button
              OutlinedButton.icon(
                onPressed: () async {
                  final items = ppeItemsAsync.asData?.value ?? [];
                  if (items.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ไม่มีข้อมูล PPE สำหรับส่งออก')),
                    );
                    return;
                  }
                  await PpeExcelExporter.exportPpeCatalog(items, context);
                },
                icon: const Icon(Icons.file_download_outlined, size: 18, color: Color(0xFF16A34A)),
                label: const Text('Export Excel', style: TextStyle(color: Color(0xFF16A34A))),
              ),
              const SizedBox(width: 10),

              // Add New PPE Button
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const PpeItemDialog(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('ลงทะเบียน PPE ใหม่', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // ── Categories Horizontal Filter Chips ──
        Container(
          height: 48,
          color: Colors.white,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildCategoryChip('ALL', 'ทั้งหมด (All Categories)', null, selectedCategory == 'ALL'),
              ...PpeCategory.values.map((cat) {
                return _buildCategoryChip(cat.code, cat.labelTh, cat.colorValue, selectedCategory == cat.code);
              }),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── PPE Items List ──
        Expanded(
          child: ppeItemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'ไม่พบรายการอุปกรณ์ PPE ในเงื่อนไขที่เลือก',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'คลิกปุ่ม "+ ลงทะเบียน PPE ใหม่" เพื่อเพิ่มอุปกรณ์เข้าสู่คลัง',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, idx) => _buildPpeCard(items[idx]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e', style: const TextStyle(color: Colors.red))),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String code, String label, int? colorVal, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 8),
      child: ChoiceChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (colorVal != null) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: Color(colorVal), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        selectedColor: colorVal != null ? Color(colorVal) : const Color(0xFF2563EB),
        backgroundColor: Colors.grey.shade100,
        onSelected: (val) {
          if (val) {
            ref.read(ppeCategoryFilterProvider.notifier).state = code;
          }
        },
      ),
    );
  }

  Widget _buildPpeCard(PpeItem item) {
    final catColor = Color(item.category.colorValue);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isOutOfStock
              ? Colors.red.shade300
              : item.isLowStock
                  ? Colors.amber.shade300
                  : Colors.grey.shade200,
          width: item.isLowStock ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon/Category Badge
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.shield, color: catColor, size: 28),
          ),
          const SizedBox(width: 16),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.code,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: catColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category.labelTh,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),

                // Standard Cert & Specs
                Row(
                  children: [
                    const Icon(Icons.verified, size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 4),
                    Text(
                      item.standardCert,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                    ),
                    if (item.storageLocation != null) ...[
                      const SizedBox(width: 14),
                      Icon(Icons.pin_drop_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(item.storageLocation!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                    if (item.preferredSupplierName != null) ...[
                      const SizedBox(width: 14),
                      Icon(Icons.business, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(item.preferredSupplierName!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ],
                ),
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Stock Badge & Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: item.isOutOfStock
                      ? const Color(0xFFFEE2E2)
                      : item.isLowStock
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.isOutOfStock
                        ? const Color(0xFFEF4444)
                        : item.isLowStock
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF22C55E),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isOutOfStock
                          ? Icons.cancel
                          : item.isLowStock
                              ? Icons.warning_amber
                              : Icons.check_circle,
                      size: 14,
                      color: item.isOutOfStock
                          ? const Color(0xFFDC2626)
                          : item.isLowStock
                              ? const Color(0xFFD97706)
                              : const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'คงเหลือ: ${item.currentStock} ${item.unit}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: item.isOutOfStock
                            ? const Color(0xFFDC2626)
                            : item.isLowStock
                                ? const Color(0xFFD97706)
                                : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Min: ${item.minStock} ${item.unit} | ฿${item.unitCost.toStringAsFixed(0)}/${item.unit}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 10),

              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick Dispense Button
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => PpeTransactionDialog(
                          preselectedItem: item,
                          initialType: PpeTransactionType.stockOut,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.call_made, size: 14),
                    label: const Text('เบิกจ่าย', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 6),

                  // Quick Stock In Button
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => PpeTransactionDialog(
                          preselectedItem: item,
                          initialType: PpeTransactionType.stockIn,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16A34A),
                      side: const BorderSide(color: Color(0xFF16A34A)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.call_received, size: 14),
                    label: const Text('รับเข้า', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 6),

                  // Edit Button
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'แก้ไข',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => PpeItemDialog(item: item),
                      );
                    },
                  ),

                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    tooltip: 'ลบ',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('ยืนยันการลบรายการ PPE'),
                          content: Text('คุณต้องการลบ "${item.name}" ออกจากทะเบียนใช่หรือไม่?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('ลบ'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(ppeRepositoryProvider).deletePpeItem(item.id!);
                        ref.invalidate(ppeItemsProvider);
                        ref.invalidate(ppeDashboardMetricsProvider);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
