import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/ppe_transaction_model.dart';
import '../providers/ppe_providers.dart';
import '../widgets/ppe_transaction_dialog.dart';

class PpeDashboardTab extends ConsumerWidget {
  const PpeDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(ppeDashboardMetricsProvider);
    final ppeItemsAsync = ref.watch(ppeItemsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI Metric Cards Row ──
          metricsAsync.when(
            data: (metrics) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      _buildMetricCard(
                        'รายการอุปกรณ์ PPE',
                        '${metrics['totalItems'] ?? 0} รายการ',
                        'รวม 8 หมวดหมู่อุปกรณ์',
                        Icons.shield_outlined,
                        const Color(0xFF2563EB),
                      ),
                      _buildMetricCard(
                        'ยอดคงเหลือในคลัง',
                        '${metrics['totalUnits'] ?? 0} หน่วย',
                        'มูลค่ารวม ฿${(metrics['totalValue'] ?? 0.0).toStringAsFixed(0)}',
                        Icons.inventory_2_outlined,
                        const Color(0xFF0D9488),
                      ),
                      _buildMetricCard(
                        'อุปกรณ์ที่สต็อกต่ำ (Alert)',
                        '${metrics['lowStockCount'] ?? 0} รายการ',
                        'ต่ำกว่าเกณฑ์ Min Stock',
                        Icons.warning_amber_rounded,
                        (metrics['lowStockCount'] ?? 0) > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      ),
                      _buildMetricCard(
                        'คู่ค้าที่รับรอง (ASL)',
                        '${metrics['approvedSupplierCount'] ?? 0} บริษัท',
                        'Approved Supplier List',
                        Icons.business_outlined,
                        const Color(0xFF7C3AED),
                      ),
                      _buildMetricCard(
                        'ยอดเบิกจ่ายเดือนนี้',
                        '${metrics['monthlyIssuedCount'] ?? 0} หน่วย',
                        'แจกจ่ายให้พนักงาน/แผนก',
                        Icons.call_made,
                        const Color(0xFFEA580C),
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 24),

          // ── Statutory Law Banner (มาตรา ๒๒ พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔) ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.gavel, color: Color(0xFF2563EB), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ข้อกำหนดตามกฎหมาย: พระราชบัญญัติความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔ มาตรา ๒๒',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '• วรรคหนึ่ง: ให้นายจ้างจัดและดูแลให้ลูกจ้างสวมใส่อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคลที่ได้มาตรฐานตามที่อธิบดีประกาศกำหนด (มอก./EN/ANSI)\n'
                        '• วรรคสอง: ลูกจ้างมีหน้าที่สวมใส่และดูแลรักษาอุปกรณ์ให้สามารถใช้งานได้ตามสภาพและลักษณะของงานตลอดระยะเวลาทำงาน\n'
                        '• วรรคสาม: ในกรณีที่ลูกจ้างไม่สวมใส่อุปกรณ์ ให้นายจ้างสั่งให้ลูกจ้างหยุดการทำงานนั้นจนกว่าจะสวมใส่อุปกรณ์ดังกล่าว',
                        style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF93C5FD)),
                        ),
                        child: const Text(
                          '💡 ระบบ Safapp บันทึก Stock Card และพิมพ์ "ใบบันทึกการแจกจ่าย PPE รายบุคคล" เพื่อใช้เป็นหลักฐานแสดงต่อพนักงานตรวจความปลอดภัย',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Reorder Alert Section ──
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined, color: Color(0xFFDC2626), size: 22),
              const SizedBox(width: 8),
              const Text(
                'รายการที่ต้องสั่งซื้อด่วน (Reorder Alert: คงเหลือ ≤ Min Stock)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ppeItemsAsync.when(
            data: (items) {
              final lowStockItems = items.where((e) => e.isLowStock).toList();
              if (lowStockItems.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 24),
                      SizedBox(width: 12),
                      Text(
                        'ระดับสต็อกอุปกรณ์ PPE ทุกรายการอยู่ในเกณฑ์ปลอดภัย (ไม่มีรายการต่ำกว่า Min Stock)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: lowStockItems.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${item.code} - ${item.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                'มาตรฐาน: ${item.standardCert} | ผู้จำหน่าย: ${item.preferredSupplierName ?? "ไม่ระบุ"}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'คงเหลือ: ${item.currentStock} / ขั้นต่ำ: ${item.minStock} ${item.unit}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626), fontSize: 13),
                            ),
                            Text(
                              'ขาดอีก: ${item.minStock - item.currentStock + 10} ${item.unit} (แนะนำ)',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => PpeTransactionDialog(
                                preselectedItem: item,
                                initialType: PpeTransactionType.stockIn,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('สั่งซื้อ/รับเข้า', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
