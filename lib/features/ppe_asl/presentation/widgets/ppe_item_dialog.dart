import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/ppe_item_model.dart';
import '../providers/ppe_providers.dart';

class PpeItemDialog extends ConsumerStatefulWidget {
  final PpeItem? item;

  const PpeItemDialog({super.key, this.item});

  @override
  ConsumerState<PpeItemDialog> createState() => _PpeItemDialogState();
}

class _PpeItemDialogState extends ConsumerState<PpeItemDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _certCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _currentStockCtrl;
  late TextEditingController _minStockCtrl;
  late TextEditingController _unitCostCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _cycleDaysCtrl;
  late TextEditingController _supplierNameCtrl;

  late PpeCategory _selectedCategory;
  bool _showAdvanced = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _codeCtrl = TextEditingController(text: it?.code ?? '');
    _nameCtrl = TextEditingController(text: it?.name ?? '');
    _certCtrl = TextEditingController(text: it?.standardCert ?? 'มอก. / ANSI / EN');
    _descCtrl = TextEditingController(text: it?.description ?? '');
    _unitCtrl = TextEditingController(text: it?.unit ?? 'ชิ้น');
    _currentStockCtrl = TextEditingController(text: it != null ? it.currentStock.toString() : '0');
    _minStockCtrl = TextEditingController(text: it != null ? it.minStock.toString() : '5');
    _unitCostCtrl = TextEditingController(text: it != null ? it.unitCost.toString() : '0');
    _locationCtrl = TextEditingController(text: it?.storageLocation ?? '');
    _cycleDaysCtrl = TextEditingController(text: it?.replacementCycleDays?.toString() ?? '365');
    _supplierNameCtrl = TextEditingController(text: it?.preferredSupplierName ?? '');

    _selectedCategory = it?.category ?? PpeCategory.head;

    if (it == null) {
      _generateDefaultCode();
    } else {
      if (it.unitCost > 0 || (it.storageLocation != null && it.storageLocation!.isNotEmpty) || (it.description != null && it.description!.isNotEmpty)) {
        _showAdvanced = true;
      }
    }
  }

  void _generateDefaultCode() {
    final prefix = _selectedCategory.code.substring(0, 2);
    final rand = DateTime.now().millisecondsSinceEpoch.toString().substring(9);
    _codeCtrl.text = 'PPE-$prefix-$rand';
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _certCtrl.dispose();
    _descCtrl.dispose();
    _unitCtrl.dispose();
    _currentStockCtrl.dispose();
    _minStockCtrl.dispose();
    _unitCostCtrl.dispose();
    _locationCtrl.dispose();
    _cycleDaysCtrl.dispose();
    _supplierNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(ppeRepositoryProvider);

      final newItem = PpeItem(
        id: widget.item?.id,
        code: _codeCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        category: _selectedCategory,
        standardCert: _certCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        unit: _unitCtrl.text.trim().isEmpty ? 'ชิ้น' : _unitCtrl.text.trim(),
        currentStock: int.tryParse(_currentStockCtrl.text.trim()) ?? 0,
        minStock: int.tryParse(_minStockCtrl.text.trim()) ?? 5,
        unitCost: double.tryParse(_unitCostCtrl.text.trim()) ?? 0.0,
        storageLocation: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        replacementCycleDays: int.tryParse(_cycleDaysCtrl.text.trim()),
        preferredSupplierName: _supplierNameCtrl.text.trim().isEmpty ? null : _supplierNameCtrl.text.trim(),
        status: widget.item?.status ?? 'ACTIVE',
      );

      if (widget.item == null) {
        await repo.insertPpeItem(newItem);
      } else {
        await repo.updatePpeItem(newItem);
      }

      ref.invalidate(ppeItemsProvider);
      ref.invalidate(ppeDashboardMetricsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.item == null ? 'เพิ่มรายการ PPE สำเร็จ' : 'แก้ไขข้อมูล PPE สำเร็จ'),
            backgroundColor: const Color(0xFF16A34A),
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
    final isEdit = widget.item != null;
    const primaryColor = Color(0xFF2563EB);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      backgroundColor: Colors.white,
      child: Container(
        width: 560,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(isEdit ? Icons.edit_note : Icons.shield_outlined, color: primaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEdit ? 'แก้ไขข้อมูลอุปกรณ์ PPE' : 'ลงทะเบียนอุปกรณ์ PPE ใหม่',
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

                // 1. หมวดหมู่อุปกรณ์
                DropdownButtonFormField<PpeCategory>(
                  isExpanded: true,
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'หมวดหมู่อุปกรณ์ *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  items: PpeCategory.values.map((cat) {
                    return DropdownMenuItem<PpeCategory>(
                      value: cat,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: Color(cat.colorValue), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(cat.labelTh, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newCat) {
                    if (newCat != null) {
                      setState(() {
                        _selectedCategory = newCat;
                        if (!isEdit) _generateDefaultCode();
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // 2. รหัส และ ชื่ออุปกรณ์
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: _codeCtrl,
                        decoration: InputDecoration(
                          labelText: 'รหัสอุปกรณ์ *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'ระบุรหัส' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 8,
                      child: TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'ชื่ออุปกรณ์ PPE *',
                          hintText: 'เช่น หมวกนิรภัย ABS สีขาว',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                        validator: (v) => v == null || v.trim().isEmpty ? 'ระบุชื่ออุปกรณ์' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. มาตรฐานรับรอง
                TextFormField(
                  controller: _certCtrl,
                  decoration: InputDecoration(
                    labelText: 'มาตรฐานรับรองตามกฎหมาย (มอก./EN/ANSI) *',
                    hintText: 'เช่น มอก. 368-2554, ANSI Z89.1',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                  validator: (v) => v == null || v.trim().isEmpty ? 'ระบุมาตรฐาน' : null,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    _buildPill('มอก. 368'),
                    _buildPill('มอก. 523'),
                    _buildPill('ANSI Z87.1'),
                    _buildPill('ANSI S3.19'),
                    _buildPill('EN 361'),
                    _buildPill('EN 388'),
                  ],
                ),
                const SizedBox(height: 14),

                // 4. สต็อกคงเหลือ, จุดเตือน, หน่วยนับ
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _currentStockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'จำนวนเริ่มต้น *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                        validator: (v) => v == null || v.trim().isEmpty ? 'ระบุยอด' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _minStockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'จุดเตือน Min *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                        validator: (v) => v == null || v.trim().isEmpty ? 'ระบุ Min' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _unitCtrl,
                        decoration: InputDecoration(
                          labelText: 'หน่วยนับ *',
                          hintText: 'ชิ้น/คู่/ชุด',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                        validator: (v) => v == null || v.trim().isEmpty ? 'ระบุหน่วย' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Toggle Additional Details (ซ่อนฟิลด์ไม่จำเป็น เพื่อไม่ให้รก)
                InkWell(
                  onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(_showAdvanced ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 20, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          _showAdvanced ? 'ซ่อนรายละเอียดเพิ่มเติม' : '+ เพิ่มเติม (ราคา, ที่เก็บ, ผู้จัดจำหน่าย)',
                          style: const TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showAdvanced) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _unitCostCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'ราคาต่อหน่วย (฿)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _locationCtrl,
                          decoration: InputDecoration(
                            labelText: 'สถานที่จัดเก็บ',
                            hintText: 'เช่น ตู้ A1',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _cycleDaysCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'รอบเปลี่ยน (วัน)',
                            hintText: 'เช่น 365',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _supplierNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'ผู้จัดจำหน่าย (Supplier)',
                      hintText: 'เช่น บริษัท ไทยเซฟตี้โพรดักส์ จำกัด',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'หมายเหตุ / คุณสมบัติการใช้งาน',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(10),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isEdit ? 'บันทึก' : 'ลงทะเบียน PPE'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String label) {
    return InkWell(
      onTap: () {
        final current = _certCtrl.text.trim();
        if (current.isEmpty || current == 'มอก. / ANSI / EN') {
          _certCtrl.text = label;
        } else if (!current.contains(label)) {
          _certCtrl.text = '$current, $label';
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ),
    );
  }
}
