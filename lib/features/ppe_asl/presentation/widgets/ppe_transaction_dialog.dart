import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/ppe_item_model.dart';
import '../../domain/models/ppe_transaction_model.dart';
import '../providers/ppe_providers.dart';

class PpeTransactionDialog extends ConsumerStatefulWidget {
  final PpeItem? preselectedItem;
  final PpeTransactionType initialType;
  final String? cpoMeetingRef;
  final String? ptwRef;

  const PpeTransactionDialog({
    super.key,
    this.preselectedItem,
    this.initialType = PpeTransactionType.stockOut,
    this.cpoMeetingRef,
    this.ptwRef,
  });

  @override
  ConsumerState<PpeTransactionDialog> createState() => _PpeTransactionDialogState();
}

class _PpeTransactionDialogState extends ConsumerState<PpeTransactionDialog> {
  final _formKey = GlobalKey<FormState>();

  late PpeTransactionType _txType;
  PpeItem? _selectedItem;

  late TextEditingController _qtyCtrl;
  late TextEditingController _recipientNameCtrl;
  late TextEditingController _deptCtrl;
  late TextEditingController _supplierNameCtrl;
  late TextEditingController _notesCtrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _txType = widget.initialType;
    _selectedItem = widget.preselectedItem;

    _qtyCtrl = TextEditingController(text: '1');
    _recipientNameCtrl = TextEditingController();
    _deptCtrl = TextEditingController(text: 'ฝ่ายผลิต');
    _supplierNameCtrl = TextEditingController(text: widget.preselectedItem?.preferredSupplierName ?? '');
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _recipientNameCtrl.dispose();
    _deptCtrl.dispose();
    _supplierNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกอุปกรณ์ PPE'), backgroundColor: Colors.red),
      );
      return;
    }

    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('จำนวนต้องมากกว่า 0'), backgroundColor: Colors.red),
      );
      return;
    }

    // Check stock for OUT
    if (_txType == PpeTransactionType.stockOut && qty > _selectedItem!.currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ยอดคงเหลือมีเพียง ${_selectedItem!.currentStock} ${_selectedItem!.unit} ไม่พอสำหรับการเบิกจ่าย'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final repo = ref.read(ppeRepositoryProvider);
      final tx = PpeTransaction(
        transactionNo: '',
        ppeId: _selectedItem!.id!,
        ppeCode: _selectedItem!.code,
        ppeName: _selectedItem!.name,
        transactionType: _txType,
        quantity: qty,
        balanceAfter: 0,
        transactionDate: todayStr,
        recipientType: 'พนักงานประจำ',
        recipientName: _txType == PpeTransactionType.stockOut ? _recipientNameCtrl.text.trim() : null,
        department: _txType == PpeTransactionType.stockOut ? _deptCtrl.text.trim() : null,
        cpoMeetingRef: widget.cpoMeetingRef,
        ptwRef: widget.ptwRef,
        supplierName: _txType == PpeTransactionType.stockIn ? _supplierNameCtrl.text.trim() : null,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        recordedBy: 'จป.วิชาชีพ',
      );

      await repo.recordTransaction(tx);

      ref.invalidate(ppeItemsProvider);
      ref.invalidate(ppeTransactionsProvider);
      ref.invalidate(ppeDashboardMetricsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_txType == PpeTransactionType.stockOut
                ? 'เบิกจ่าย ${_selectedItem!.name} จำนวน $qty ${_selectedItem!.unit} เรียบร้อย'
                : 'รับเข้า ${_selectedItem!.name} จำนวน $qty ${_selectedItem!.unit} เรียบร้อย'),
            backgroundColor: Color(_txType.colorValue),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ppeItemsAsync = ref.watch(ppeItemsProvider);
    final isOut = _txType == PpeTransactionType.stockOut;
    final actionColor = isOut ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      backgroundColor: Colors.white,
      child: Container(
        width: 480,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clean Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: actionColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(isOut ? Icons.call_made : Icons.call_received, color: actionColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isOut ? 'เบิกจ่ายอุปกรณ์ PPE' : 'รับเข้าคลังอุปกรณ์ PPE',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade500, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Simple Toggle between OUT / IN (เฉพาะเมื่อไม่ได้เจาะจงมาจากปุ่ม)
              if (widget.preselectedItem == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _txType = PpeTransactionType.stockOut),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isOut ? const Color(0xFFFEE2E2) : Colors.transparent,
                          side: BorderSide(color: isOut ? const Color(0xFFDC2626) : Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(Icons.call_made, size: 16, color: isOut ? const Color(0xFFDC2626) : Colors.grey),
                        label: Text(
                          'เบิกจ่าย (OUT)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isOut ? FontWeight.bold : FontWeight.normal,
                            color: isOut ? const Color(0xFFDC2626) : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _txType = PpeTransactionType.stockIn),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: !isOut ? const Color(0xFFDCFCE7) : Colors.transparent,
                          side: BorderSide(color: !isOut ? const Color(0xFF16A34A) : Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(Icons.call_received, size: 16, color: !isOut ? const Color(0xFF16A34A) : Colors.grey),
                        label: Text(
                          'รับเข้า (IN)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: !isOut ? FontWeight.bold : FontWeight.normal,
                            color: !isOut ? const Color(0xFF16A34A) : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Equipment Info Box / Selector
              if (widget.preselectedItem != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield, size: 20, color: Color(0xFF2563EB)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedItem!.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            Text(
                              '${_selectedItem!.code} | มาตรฐาน: ${_selectedItem!.standardCert}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'คงเหลือ: ${_selectedItem!.currentStock} ${_selectedItem!.unit}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ] else ...[
                // Item Dropdown
                ppeItemsAsync.when(
                  data: (items) {
                    if (items.isEmpty) return const Text('ไม่มีรายการอุปกรณ์');
                    if (_selectedItem == null && items.isNotEmpty) _selectedItem = items.first;
                    return DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _selectedItem?.id,
                      decoration: InputDecoration(
                        labelText: 'เลือกอุปกรณ์ PPE *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                      ),
                      items: items.map((it) {
                        return DropdownMenuItem(
                          value: it.id,
                          child: Text(
                            '${it.name} (คงเหลือ: ${it.currentStock} ${it.unit})',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (id) {
                        if (id != null) {
                          setState(() {
                            _selectedItem = items.firstWhere((x) => x.id == id);
                            if (_selectedItem?.preferredSupplierName != null) {
                              _supplierNameCtrl.text = _selectedItem!.preferredSupplierName!;
                            }
                          });
                        }
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 14),
              ],

              // Quantity Field
              TextFormField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'จำนวน (${_selectedItem?.unit ?? "หน่วย"}) *',
                  hintText: 'กรอกจำนวน',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: true,
                  prefixIcon: const Icon(Icons.numbers, size: 18),
                ),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุจำนวน' : null,
              ),
              const SizedBox(height: 12),

              // If OUT (เบิกจ่าย): Recipient Name & Department
              if (isOut) ...[
                TextFormField(
                  controller: _recipientNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'ชื่อพนักงานผู้รับมอบ *',
                    hintText: 'เช่น นายสมชาย ปลอดภัยดี',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                    prefixIcon: const Icon(Icons.person_outline, size: 18),
                  ),
                  style: const TextStyle(fontSize: 13),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อผู้รับ' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deptCtrl,
                  decoration: InputDecoration(
                    labelText: 'แผนก / ฝ่าย',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                    prefixIcon: const Icon(Icons.apartment, size: 18),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ],

              // If IN (รับเข้า): Supplier Name
              if (!isOut) ...[
                TextFormField(
                  controller: _supplierNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'ชื่อผู้จัดจำหน่าย / คู่ค้า ASL *',
                    hintText: 'เช่น บริษัท ไทยเซฟตี้โพรดักส์ จำกัด',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                    prefixIcon: const Icon(Icons.business_outlined, size: 18),
                  ),
                  style: const TextStyle(fontSize: 13),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุผู้จัดจำหน่าย' : null,
                ),
              ],
              const SizedBox(height: 12),

              // Notes (Optional)
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: 'หมายเหตุ (ถ้ามี)',
                  hintText: isOut ? 'เช่น เบิกแรกเข้า, ชำรุดตามการใช้งาน' : 'เช่น สั่งซื้อตามรอบ PO#123',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isOut ? 'ยืนยันเบิกจ่าย' : 'ยืนยันรับเข้า'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
