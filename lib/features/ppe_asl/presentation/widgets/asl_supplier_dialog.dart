import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/asl_supplier_model.dart';
import '../providers/ppe_providers.dart';
import '../../../../core/widgets/thai_address_cascade_widget.dart';

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

  late TextEditingController _addressNumberCtrl;
  late TextEditingController _mooCtrl;
  late TextEditingController _soiCtrl;
  late TextEditingController _roadCtrl;
  late TextEditingController _subdistrictCtrl;
  late TextEditingController _districtCtrl;
  late TextEditingController _provinceCtrl;
  late TextEditingController _postalCodeCtrl;

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

    _addressNumberCtrl = TextEditingController(text: sup?.addressNumber ?? '');
    _mooCtrl = TextEditingController(text: sup?.moo ?? '');
    _soiCtrl = TextEditingController(text: sup?.soi ?? '');
    _roadCtrl = TextEditingController(text: sup?.road ?? '');
    _subdistrictCtrl = TextEditingController(text: sup?.subdistrict ?? '');
    _districtCtrl = TextEditingController(text: sup?.district ?? '');
    _provinceCtrl = TextEditingController(text: sup?.province ?? '');
    _postalCodeCtrl = TextEditingController(text: sup?.postalCode ?? '');

    // Parse legacy address if structured fields are blank
    if (sup != null && _addressNumberCtrl.text.isEmpty && sup.address != null && sup.address!.isNotEmpty) {
      _addressNumberCtrl.text = sup.address!;
    }

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

    _addressNumberCtrl.dispose();
    _mooCtrl.dispose();
    _soiCtrl.dispose();
    _roadCtrl.dispose();
    _subdistrictCtrl.dispose();
    _districtCtrl.dispose();
    _provinceCtrl.dispose();
    _postalCodeCtrl.dispose();

    _categoriesCtrl.dispose();
    _certsCtrl.dispose();
    _approvedDateCtrl.dispose();
    _validUntilCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12.5),
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
      prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFF0D9488)) : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
    );
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final addressParts = <String>[];
      if (_addressNumberCtrl.text.trim().isNotEmpty) addressParts.add('เลขที่ ${_addressNumberCtrl.text.trim()}');
      if (_mooCtrl.text.trim().isNotEmpty) addressParts.add('หมู่ ${_mooCtrl.text.trim()}');
      if (_soiCtrl.text.trim().isNotEmpty) addressParts.add('ซอย ${_soiCtrl.text.trim()}');
      if (_roadCtrl.text.trim().isNotEmpty) addressParts.add('ถนน ${_roadCtrl.text.trim()}');
      if (_subdistrictCtrl.text.trim().isNotEmpty) addressParts.add('ต.${_subdistrictCtrl.text.trim()}');
      if (_districtCtrl.text.trim().isNotEmpty) addressParts.add('อ.${_districtCtrl.text.trim()}');
      if (_provinceCtrl.text.trim().isNotEmpty) addressParts.add('จ.${_provinceCtrl.text.trim()}');
      if (_postalCodeCtrl.text.trim().isNotEmpty) addressParts.add(_postalCodeCtrl.text.trim());
      final fullAddress = addressParts.isNotEmpty ? addressParts.join(' ') : null;

      final repo = ref.read(ppeRepositoryProvider);
      final supplier = AslSupplier(
        id: widget.supplier?.id,
        code: _codeCtrl.text.trim(),
        companyName: _nameCtrl.text.trim(),
        taxId: _taxIdCtrl.text.trim().isEmpty ? null : _taxIdCtrl.text.trim(),
        contactPerson: _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        address: fullAddress ?? widget.supplier?.address,
        addressNumber: _addressNumberCtrl.text.trim().isEmpty ? null : _addressNumberCtrl.text.trim(),
        moo: _mooCtrl.text.trim().isEmpty ? null : _mooCtrl.text.trim(),
        soi: _soiCtrl.text.trim().isEmpty ? null : _soiCtrl.text.trim(),
        road: _roadCtrl.text.trim().isEmpty ? null : _roadCtrl.text.trim(),
        subdistrict: _subdistrictCtrl.text.trim().isEmpty ? null : _subdistrictCtrl.text.trim(),
        district: _districtCtrl.text.trim().isEmpty ? null : _districtCtrl.text.trim(),
        province: _provinceCtrl.text.trim().isEmpty ? null : _provinceCtrl.text.trim(),
        postalCode: _postalCodeCtrl.text.trim().isEmpty ? null : _postalCodeCtrl.text.trim(),
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
        width: 700,
        constraints: const BoxConstraints(maxHeight: 760),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(isEdit ? Icons.edit_note_rounded : Icons.domain_add_rounded, color: primaryColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'แก้ไขทะเบียนคู่ค้า ASL' : 'ลงทะเบียนคู่ค้าที่ผ่านการรับรอง (ASL)',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Approved Supplier List สำหรับจัดหาอุปกรณ์ PPE ที่มีคุณภาพมาตรฐาน',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),

              // Scrollable Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── ๑. ข้อมูลทั่วไป ──
                      _buildSectionHeader('๑. ข้อมูลทั่วไปของคู่ค้า / ผู้จัดจำหน่าย (ASL)'),
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              controller: _codeCtrl,
                              decoration: _inputDecoration('รหัสคู่ค้า (ASL Code) *', icon: Icons.qr_code_rounded),
                              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุรหัส' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 7,
                            child: TextFormField(
                              controller: _nameCtrl,
                              decoration: _inputDecoration('ชื่อบริษัท / ผู้จัดจำหน่าย *', icon: Icons.business_rounded),
                              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อบริษัท' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _taxIdCtrl,
                              decoration: _inputDecoration('เลขประจำตัวผู้เสียภาษี', icon: Icons.badge_outlined, hint: '13 หลัก'),
                            ),
                          ),
                        ],
                      ),

                      // ── ๒. ที่ตั้งสถานประกอบการ ──
                      _buildSectionHeader('๒. ที่ตั้งสถานประกอบการ / สำนักงาน / คลังสินค้า'),
                      ThaiAddressCascadeWidget(
                        addressNumberController: _addressNumberCtrl,
                        mooController: _mooCtrl,
                        soiController: _soiCtrl,
                        roadController: _roadCtrl,
                        subdistrictController: _subdistrictCtrl,
                        districtController: _districtCtrl,
                        provinceController: _provinceCtrl,
                        postalCodeController: _postalCodeCtrl,
                        showContactFields: false,
                        showCountry: false,
                      ),

                      // ── ๓. ข้อมูลผู้ติดต่อ & การติดต่อ ──
                      _buildSectionHeader('๓. ข้อมูลผู้ประสานงาน & การติดต่อ'),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _contactCtrl,
                              decoration: _inputDecoration('ผู้ประสานงานหลัก', icon: Icons.person_outline_rounded),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              decoration: _inputDecoration('เบอร์โทรศัพท์ติดต่อ', icon: Icons.phone_outlined),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailCtrl,
                              decoration: _inputDecoration('อีเมลติดต่อ', icon: Icons.email_outlined),
                            ),
                          ),
                        ],
                      ),

                      // ── ๔. หมวดหมู่อุปกรณ์ PPE & มาตรฐานรับรอง ──
                      _buildSectionHeader('๔. หมวดหมู่อุปกรณ์ PPE & มาตรฐานรับรอง'),
                      TextFormField(
                        controller: _categoriesCtrl,
                        decoration: _inputDecoration(
                          'หมวดหมู่อุปกรณ์ PPE ที่จัดจำหน่าย *',
                          icon: Icons.category_outlined,
                          hint: 'เช่น หมวกนิรภัย, ถุงมือกันสารเคมี, รองเท้าเซฟตี้',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุหมวดหมู่' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _certsCtrl,
                        decoration: _inputDecoration(
                          'มาตรฐานและการรับรองของคู่ค้า (Certifications)',
                          icon: Icons.verified_outlined,
                          hint: 'เช่น ISO 9001:2015, มอก. 368, CE/EN, ANSI',
                        ),
                      ),

                      // ── ๕. การประเมินผล & สถานะการรับรอง ──
                      _buildSectionHeader('๕. การประเมินผล & สถานะการรับรอง'),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<AslStatus>(
                              value: _status,
                              decoration: _inputDecoration('สถานะการประเมินคู่ค้า *', icon: Icons.verified_user_outlined),
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
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
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                    ),
                                    child: Slider(
                                      value: _rating,
                                      min: 1.0,
                                      max: 5.0,
                                      divisions: 8,
                                      label: _rating.toStringAsFixed(1),
                                      activeColor: const Color(0xFFD97706),
                                      onChanged: (val) => setState(() => _rating = val),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _approvedDateCtrl,
                              readOnly: true,
                              decoration: _inputDecoration('วันที่ผ่านการรับรอง', icon: Icons.calendar_today_outlined),
                              onTap: () async {
                                final now = DateTime.now();
                                final parsed = DateTime.tryParse(_approvedDateCtrl.text) ?? now;
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: parsed,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setState(() => _approvedDateCtrl.text = picked.toIso8601String().substring(0, 10));
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _validUntilCtrl,
                              readOnly: true,
                              decoration: _inputDecoration('รับรองถึงวันที่ (Valid Until)', icon: Icons.event_available_outlined),
                              onTap: () async {
                                final now = DateTime.now();
                                final parsed = DateTime.tryParse(_validUntilCtrl.text) ?? now.add(const Duration(days: 365));
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: parsed,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setState(() => _validUntilCtrl.text = picked.toIso8601String().substring(0, 10));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: _inputDecoration(
                          'หมายเหตุการประเมินคุณภาพ',
                          icon: Icons.notes_rounded,
                          hint: 'เช่น ตรวจประเมินโรงงานแล้ว ผลิตภัณฑ์ได้มาตรฐานสากล',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('ยกเลิก'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveSupplier,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 1,
                    ),
                    icon: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(
                      isEdit ? 'บันทึกการแก้ไข' : 'บันทึกคู่ค้า ASL',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
