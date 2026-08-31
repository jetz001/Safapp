import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/contractor_models.dart';
import '../providers/contractor_providers.dart';

class ContractorCompanyDialog extends ConsumerStatefulWidget {
  final ContractorCompany? existingCompany;

  const ContractorCompanyDialog({
    Key? key,
    this.existingCompany,
  }) : super(key: key);

  @override
  ConsumerState<ContractorCompanyDialog> createState() => _ContractorCompanyDialogState();
}

class _ContractorCompanyDialogState extends ConsumerState<ContractorCompanyDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _taxIdController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _safetyOfficerNameController;
  late TextEditingController _safetyOfficerPhoneController;
  late TextEditingController _notesController;

  String _serviceType = 'งานติดตั้งเครื่องจักร & ซ่อมบำรุง';
  String _status = 'ACTIVE';
  int _safetyScore = 100;
  bool _isSaving = false;

  final List<String> _serviceTypes = [
    'งานติดตั้งเครื่องจักร & ซ่อมบำรุง',
    'งานก่อสร้าง & นั่งร้าน',
    'งานระบบไฟฟ้า & อิเล็กทรอนิกส์',
    'งานเชื่อม & งานที่เกิดประกายไฟ (Hot Work)',
    'งานทำความสะอาด & เก็บกวาดสารเคมี',
    'งานขนส่ง & รถยก/ปั้นจั่น',
    'งานรักษาความปลอดภัย & กายภาพ',
    'งานบริการอื่นๆ',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.existingCompany;

    _nameController = TextEditingController(text: c?.companyName ?? '');
    _taxIdController = TextEditingController(text: c?.taxId ?? '');
    _contactPersonController = TextEditingController(text: c?.contactPerson ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _safetyOfficerNameController = TextEditingController(text: c?.safetyOfficerName ?? '');
    _safetyOfficerPhoneController = TextEditingController(text: c?.safetyOfficerPhone ?? '');
    _notesController = TextEditingController(text: c?.notes ?? '');

    if (c != null) {
      if (_serviceTypes.contains(c.serviceType)) {
        _serviceType = c.serviceType;
      }
      _status = c.status;
      _safetyScore = c.safetyScore;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _safetyOfficerNameController.dispose();
    _safetyOfficerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final company = ContractorCompany(
        id: widget.existingCompany?.id,
        companyName: _nameController.text.trim(),
        taxId: _taxIdController.text.trim().isEmpty ? null : _taxIdController.text.trim(),
        serviceType: _serviceType,
        contactPerson: _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        safetyOfficerName: _safetyOfficerNameController.text.trim().isEmpty ? null : _safetyOfficerNameController.text.trim(),
        safetyOfficerPhone: _safetyOfficerPhoneController.text.trim().isEmpty ? null : _safetyOfficerPhoneController.text.trim(),
        safetyScore: _safetyScore,
        status: _status,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await ref.read(contractorCompaniesProvider.notifier).saveCompany(company);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingCompany == null ? 'ลงทะเบียนบริษัทผู้รับเหมาเรียบร้อย' : 'บันทึกข้อมูลบริษัทเรียบร้อย'),
            backgroundColor: Colors.green.shade700,
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingCompany != null;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.business_rounded, color: Color(0xFF1E3A8A), size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            isEdit ? 'แก้ไขข้อมูลบริษัทผู้รับเหมา' : 'ขึ้นทะเบียนบริษัทผู้รับเหมาใหม่',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader('๑. ข้อมูลทั่วไปของสถานประกอบการผู้รับเหมา'),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('ชื่อบริษัทผู้รับเหมา *', icon: Icons.domain),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อบริษัท' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _taxIdController,
                        decoration: _inputDecoration('เลขประจำตัวผู้เสียภาษี', icon: Icons.badge_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _serviceType,
                        decoration: _inputDecoration('ประเภทงาน / บริการ *', icon: Icons.category),
                        items: _serviceTypes.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _serviceType = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _status,
                        decoration: _inputDecoration('สถานะการอนุญาต *', icon: Icons.verified_user),
                        items: const [
                          DropdownMenuItem(value: 'ACTIVE', child: Text('🟢 อนุญาตเข้าทำงาน (Active)')),
                          DropdownMenuItem(value: 'SUSPENDED', child: Text('🟡 ระงับงานชั่วคราว (Suspended)')),
                          DropdownMenuItem(value: 'BLACKLISTED', child: Text('🔴 บัญชีดำ (Blacklisted)')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _status = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildSectionHeader('๒. ข้อมูลผู้ประสานงาน & จป. ผู้รับเหมา'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _contactPersonController,
                        decoration: _inputDecoration('ชื่อผู้ประสานงาน / ผู้ควบคุมงาน', icon: Icons.person_outline),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
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
                        controller: _safetyOfficerNameController,
                        decoration: _inputDecoration('ชื่อ จป. ประจำผู้รับเหมา (ถ้ามี)', icon: Icons.health_and_safety_outlined),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _safetyOfficerPhoneController,
                        decoration: _inputDecoration('เบอร์โทร จป. ผู้รับเหมา', icon: Icons.contact_phone_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildSectionHeader('๓. หมายเหตุ / ข้อมูลเพิ่มเติม'),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: _inputDecoration('หมายเหตุหรือประวัติสำคัญ', icon: Icons.notes),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกข้อมูลบริษัท'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade400, size: 18) : null,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
      ),
    );
  }
}
