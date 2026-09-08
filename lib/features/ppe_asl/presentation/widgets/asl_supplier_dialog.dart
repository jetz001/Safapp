import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/asl_supplier_model.dart';
import '../providers/ppe_providers.dart';

class AslSupplierDialog extends ConsumerStatefulWidget {
  final AslSupplier? supplier;

  const AslSupplierDialog({super.key, this.supplier});

  @override
  ConsumerState<AslSupplierDialog> createState() => _AslSupplierDialogState();
}

class _AslSupplierDialogState extends ConsumerState<AslSupplierDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _taxIdCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _categoriesCtrl;
  late TextEditingController _certsCtrl;
  late TextEditingController _approvedDateCtrl;
  late TextEditingController _validUntilCtrl;
  late TextEditingController _notesCtrl;

  late AslStatus _status;
  double _rating = 5.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final sup = widget.supplier;
    _codeCtrl = TextEditingController(text: sup?.code ?? '');
    _nameCtrl = TextEditingController(text: sup?.companyName ?? '');
    _taxIdCtrl = TextEditingController(text: sup?.taxId ?? '');
    _contactCtrl = TextEditingController(text: sup?.contactPerson ?? '');
    _phoneCtrl = TextEditingController(text: sup?.phone ?? '');
    _emailCtrl = TextEditingController(text: sup?.email ?? '');
    _addressCtrl = TextEditingController(text: sup?.address ?? '');
    _categoriesCtrl = TextEditingController(text: sup?.suppliedCategories ?? 'หมวกนิรภัย, รองเท้าเซฟตี้, แว่นตานิรภัย');
    _certsCtrl = TextEditingController(text: sup?.standardCertificates ?? 'ISO 9001:2015, มอก.');
    _approvedDateCtrl = TextEditingController(text: sup?.approvedDate ?? DateTime.now().toIso8601String().substring(0, 10));
    _validUntilCtrl = TextEditingController(text: sup?.validUntil ?? DateTime.now().add(const Duration(days: 365)).toIso8601String().substring(0, 10));
    _notesCtrl = TextEditingController(text: sup?.notes ?? '');

    _status = sup?.evaluationStatus ?? AslStatus.approved;
    _rating = sup?.rating ?? 5.0;

    if (sup == null) {
      final rand = DateTime.now().millisecondsSinceEpoch.toString().substring(9);
      _codeCtrl.text = 'ASL-$rand';
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _taxIdCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _categoriesCtrl.dispose();
    _certsCtrl.dispose();
    _approvedDateCtrl.dispose();
    _validUntilCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(ppeRepositoryProvider);
      final supplier = AslSupplier(
        id: widget.supplier?.id,
        code: _codeCtrl.text.trim(),
        companyName: _nameCtrl.text.trim(),
        taxId: _taxIdCtrl.text.trim().isEmpty ? null : _taxIdCtrl.text.trim(),
        contactPerson: _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        suppliedCategories: _categoriesCtrl.text.trim(),
        standardCertificates: _certsCtrl.text.trim().isEmpty ? null : _certsCtrl.text.trim(),
        rating: _rating,
        evaluationStatus: _status,
        approvedDate: _approvedDateCtrl.text.trim().isEmpty ? null : _approvedDateCtrl.text.trim(),
        validUntil: _validUntilCtrl.text.trim().isEmpty ? null : _validUntilCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        status: widget.supplier?.status ?? 'ACTIVE',
      );

      if (widget.supplier == null) {
        await repo.insertSupplier(supplier);
      } else {
        await repo.updateSupplier(supplier);
      }

      ref.invalidate(aslSuppliersProvider);
      ref.invalidate(ppeDashboardMetricsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.supplier == null ? 'เพิ่มคู่ค้า ASL สำเร็จ' : 'แก้ไขข้อมูลคู่ค้าสำเร็จ'),
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
    final isEdit = widget.supplier != null;
    const primaryColor = Color(0xFF0D9488);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 660,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(isEdit ? Icons.edit_note : Icons.domain_add, color: primaryColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'แก้ไขทะเบียนคู่ค้า ASL' : 'ลงทะเบียนคู่ค้าที่ผ่านการรับรอง (ASL)',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Approved Supplier List สำหรับจัดหาอุปกรณ์ PPE ที่มีคุณภาพมาตรฐาน',
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
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 18),

                // Code & Company Name
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: _codeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'รหัสคู่ค้า (ASL Code) *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุรหัส' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 8,
                      child: TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อบริษัท / ผู้จัดจำหน่าย *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business, size: 20),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อบริษัท' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Tax ID & Contact Person
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _taxIdCtrl,
                        decoration: const InputDecoration(
                          labelText: 'เลขประจำตัวผู้เสียภาษี',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _contactCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ผู้ประสานงานหลัก',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Phone & Email
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'เบอร์โทรศัพท์ติดต่อ',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'อีเมล',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Address
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ที่อยู่สำนักงาน / โรงงาน',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.pin_drop_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 14),

                // Supplied categories & Certificates
                TextFormField(
                  controller: _categoriesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'หมวดหมู่อุปกรณ์ PPE ที่จัดจำหน่าย *',
                    hintText: 'เช่น หมวกนิรภัย, ถุงมือกันสารเคมี, รองเท้าเซฟตี้',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุหมวดหมู่' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _certsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'มาตรฐานและการรับรองของคู่ค้า (Certifications)',
                    hintText: 'เช่น ISO 9001:2015, มอก. 368, CE/EN, ANSI',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.verified_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 14),

                // Status & Rating
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<AslStatus>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'สถานะการประเมินคู่ค้า *',
                          border: OutlineInputBorder(),
                        ),
                        items: AslStatus.values.map((st) {
                          return DropdownMenuItem(
                            value: st,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(color: Color(st.colorValue), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Text(st.labelTh, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('คะแนนประเมินคู่ค้า (Rating)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              Text('${_rating.toStringAsFixed(1)} / 5.0 ⭐', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                            ],
                          ),
                          Slider(
                            value: _rating,
                            min: 1.0,
                            max: 5.0,
                            divisions: 8,
                            label: _rating.toStringAsFixed(1),
                            activeColor: const Color(0xFFD97706),
                            onChanged: (val) => setState(() => _rating = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Approval date & Valid Until
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _approvedDateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'วันที่ผ่านการรับรอง',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _validUntilCtrl,
                        decoration: const InputDecoration(
                          labelText: 'รับรองถึงวันที่ (Valid Until)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event_available, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Notes
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'หมายเหตุการประเมินคุณภาพ',
                    hintText: 'เช่น ตรวจประเมินโรงงานแล้ว ผลิตภัณฑ์ได้มาตรฐานสากล',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('ยกเลิก'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveSupplier,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: _isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save, size: 20),
                      label: Text(isEdit ? 'บันทึกการแก้ไข' : 'บันทึกคู่ค้า ASL'),
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
}
