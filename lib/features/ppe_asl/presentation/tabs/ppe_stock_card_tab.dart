import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/ppe_transaction_model.dart';
import '../providers/ppe_providers.dart';
import '../widgets/ppe_transaction_dialog.dart';
import '../../services/ppe_excel_exporter.dart';
import '../../services/ppe_pdf_exporter.dart';

class PpeStockCardTab extends ConsumerStatefulWidget {
  const PpeStockCardTab({super.key});

  @override
  ConsumerState<PpeStockCardTab> createState() => _PpeStockCardTabState();
}

class _PpeStockCardTabState extends ConsumerState<PpeStockCardTab> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(ppeTransactionsProvider);
    final selectedType = ref.watch(ppeTxTypeFilterProvider);

    return Column(
      children: [
        // ── Search & Filter Bar ──
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
                    hintText: 'ค้นหาเลขที่รายการ, ชื่อผู้รับ, แผนก, อุปกรณ์...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(ppeTxSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) {
                    ref.read(ppeTxSearchQueryProvider.notifier).state = val;
                  },
                ),
              ),
              const SizedBox(width: 14),

              // Filter Types Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedType,
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('ประเภททั้งหมด')),
                      DropdownMenuItem(value: 'IN', child: Text('เฉพาะรับเข้าคลัง (IN)')),
                      DropdownMenuItem(value: 'OUT', child: Text('เฉพาะเบิกจ่าย (OUT)')),
                      DropdownMenuItem(value: 'ADJUST', child: Text('ปรับปรุงยอด (ADJUST)')),
                      DropdownMenuItem(value: 'RETURN', child: Text('ส่งคืนอุปกรณ์ (RETURN)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(ppeTxTypeFilterProvider.notifier).state = val;
                      }
                    },
                  ),
                ),
              ),
              const Spacer(),

              // PDF Export: Individual Issue Card (ม.๒๒)
              OutlinedButton.icon(
                onPressed: () async {
                  final txs = transactionsAsync.asData?.value ?? [];
                  if (txs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ไม่มีประวัติการเบิกจ่ายสำหรับพิมพ์รายงาน')),
                    );
                    return;
                  }
                  await PpePdfExporter.exportIndividualIssueCard(txs, context);
                },
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Color(0xFFDC2626)),
                label: const Text('พิมพ์บัตรแจกจ่าย PPE (ม.๒๒)', style: TextStyle(color: Color(0xFFDC2626))),
              ),
              const SizedBox(width: 8),

              // Excel Export Button
              OutlinedButton.icon(
                onPressed: () async {
                  final txs = transactionsAsync.asData?.value ?? [];
                  if (txs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ไม่มีข้อมูล Stock Card สำหรับส่งออก')),
                    );
                    return;
                  }
                  await PpeExcelExporter.exportStockCard(txs, context);
                },
                icon: const Icon(Icons.table_view_outlined, size: 18, color: Color(0xFF16A34A)),
                label: const Text('Export Excel', style: TextStyle(color: Color(0xFF16A34A))),
              ),
              const SizedBox(width: 10),

              // New Transaction Button
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const PpeTransactionDialog(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('บันทึกรับเข้า-เบิกจ่าย', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Transactions Table List ──
        Expanded(
          child: transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'ยังไม่มีบันทึกการเคลื่อนไหวสต็อกการ์ด',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'คลิกปุ่ม "+ บันทึกรับเข้า-เบิกจ่าย" เพื่อสร้างรายการแรก',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 58,
                        columns: const [
                          DataColumn(label: Text('เลขที่รายการ')),
                          DataColumn(label: Text('วันที่')),
                          DataColumn(label: Text('ประเภท')),
                          DataColumn(label: Text('รหัสอุปกรณ์')),
                          DataColumn(label: Text('ชื่ออุปกรณ์ PPE')),
                          DataColumn(label: Text('จำนวน')),
                          DataColumn(label: Text('คงเหลือหลังทำรายการ')),
                          DataColumn(label: Text('ผู้รับมอบ / ผู้จำหน่าย')),
                          DataColumn(label: Text('แผนก')),
                          DataColumn(label: Text('อ้างอิง คปอ. / PTW')),
                          DataColumn(label: Text('ผู้บันทึก')),
                        ],
                        rows: transactions.map((tx) {
                          final typeColor = Color(tx.transactionType.colorValue);
                          final isOut = tx.transactionType == PpeTransactionType.stockOut;

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(tx.transactionNo, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              DataCell(Text(tx.transactionDate, style: const TextStyle(fontSize: 12))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: typeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isOut ? Icons.call_made : Icons.call_received,
                                        size: 12,
                                        color: typeColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        tx.transactionType.labelTh,
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: typeColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(tx.ppeCode, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    tx.ppeName,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${isOut ? "-" : "+"}${tx.quantity}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isOut ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${tx.balanceAfter}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              DataCell(
                                Text(
                                  tx.recipientName ?? tx.supplierName ?? '-',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              DataCell(
                                Text(tx.department ?? '-', style: const TextStyle(fontSize: 12)),
                              ),
                              DataCell(
                                Text(
                                  tx.cpoMeetingRef ?? tx.ptwRef ?? '-',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: (tx.cpoMeetingRef != null || tx.ptwRef != null) ? const Color(0xFF2563EB) : Colors.grey,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(tx.recordedBy ?? '-', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e', style: const TextStyle(color: Colors.red))),
          ),
        ),
      ],
    );
  }
}
