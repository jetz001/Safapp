import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/employee_models.dart';
import '../providers/employee_providers.dart';

class EmployeeFormDialog extends ConsumerStatefulWidget {
  final Employee? existingEmployee;

  const EmployeeFormDialog({
    Key? key,
    this.existingEmployee,
  }) : super(key: key);

  @override
  ConsumerState<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends ConsumerState<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _nationalIdController;
  late TextEditingController _deptController;
  late TextEditingController _positionController;
  late TextEditingController _hireDateController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  String _safetyRole = 'GENERAL';
  String _status = 'ACTIVE';
  String? _pickedPhotoPath;
  bool _isSaving = false;

  final List<String> _departments = [
    'ฝ่ายผลิตและประกอบ (Production)',
    'ฝ่ายซ่อมบำรุงและวิศวกรรม (Maintenance)',
    'ฝ่ายคลังสินค้าและโลจิสติกส์ (Warehouse)',
    'ฝ่ายควบคุมคุณภาพ (QA/QC)',
    'ฝ่ายความปลอดภัยและสิ่งแวดล้อม (EHS)',
    'ฝ่ายทรัพยากรบุคคลและธุรการ (HR & Admin)',
    'ฝ่ายจัดซื้อและจัดหา (Procurement)',
    'ฝ่ายบริหารและสำนักงาน (Management)',
    'แผนกอื่นๆ',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existingEmployee;

    _codeController = TextEditingController(text: e?.employeeCode ?? '');
    _nameController = TextEditingController(text: e?.fullName ?? '');
    _nationalIdController = TextEditingController(text: e?.nationalId ?? '');
    _deptController = TextEditingController(text: e?.department ?? 'ฝ่ายผลิตและประกอบ (Production)');
    _positionController = TextEditingController(text: e?.position ?? '');
    _hireDateController = TextEditingController(text: e?.hireDate ?? DateTime.now().toIso8601String().substring(0, 10));
    _phoneController = TextEditingController(text: e?.phone ?? '');
    _emailController = TextEditingController(text: e?.email ?? '');

    if (e != null) {
      _safetyRole = e.safetyRole;
      _status = e.status;
      _pickedPhotoPath = e.photoPath;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _nationalIdController.dispose();
    _deptController.dispose();
    _positionController.dispose();
    _hireDateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedPhotoPath = result.files.single.path;
      });
    }
  }

  Future<void> _selectDate() async {
    DateTime initial = DateTime.tryParse(_hireDateController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _hireDateController.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final emp = Employee(
        id: widget.existingEmployee?.id,
        employeeCode: _codeController.text.trim(),
        fullName: _nameController.text.trim(),
        nationalId: _nationalIdController.text.trim().isEmpty ? null : _nationalIdController.text.trim(),
        department: _deptController.text.trim(),
        position: _positionController.text.trim(),
        safetyRole: _safetyRole,
        hireDate: _hireDateController.text.trim().isEmpty ? null : _hireDateController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        photoPath: _pickedPhotoPath,
        status: _status,
      );

      final isNewPhoto = _pickedPhotoPath != null && _pickedPhotoPath != widget.existingEmployee?.photoPath;

      await ref.read(employeesProvider.notifier).saveEmployee(
            emp,
            newPhotoPath: isNewPhoto ? _pickedPhotoPath : null,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingEmployee == null ? 'เพิ่มข้อมูลพนักงานเรียบร้อย' : 'แก้ไขข้อมูลพนักงานเรียบร้อย'),
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
    final isEdit = widget.existingEmployee != null;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.badge_rounded, color: Color(0xFF1E3A8A), size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            isEdit ? 'แก้ไขข้อมูลพนักงาน' : 'เพิ่มทะเบียนพนักงานใหม่',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader('๑. ข้อมูลระบุตัวตนและรูปถ่าย'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo Upload Box
                    InkWell(
                      onTap: _pickPhoto,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 100,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        ),
                        child: _pickedPhotoPath != null && File(_pickedPhotoPath!).existsSync()
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.file(File(_pickedPhotoPath!), fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, size: 28, color: Colors.blueGrey.shade400),
                                  const SizedBox(height: 6),
                                  const Text('แนบรูปถ่าย', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Code, Name, ID Card
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _codeController,
                                  decoration: _inputDecoration('รหัสพนักงาน *', icon: Icons.qr_code),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุรหัสพนักงาน' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _nationalIdController,
                                  decoration: _inputDecoration('เลขประจำตัวประชาชน', icon: Icons.credit_card),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameController,
                            decoration: _inputDecoration('ชื่อ - นามสกุล พนักงาน *', icon: Icons.person),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อพนักงาน' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildSectionHeader('๒. แผนก ตำแหน่งงาน และหน้าที่ด้านความปลอดภัย'),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Autocomplete<String>(
                        initialValue: TextEditingValue(text: _deptController.text),
                        optionsBuilder: (textVal) {
                          if (textVal.text.isEmpty) return _departments;
                          return _departments.where((d) => d.toLowerCase().contains(textVal.text.toLowerCase()));
                        },
                        onSelected: (selection) => _deptController.text = selection,
                        fieldViewBuilder: (ctx, controller, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: _inputDecoration('แผนก / ฝ่าย *', icon: Icons.domain),
                            onChanged: (v) => _deptController.text = v,
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุแผนก' : null,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _positionController,
                        decoration: _inputDecoration('ตำแหน่งงาน *', icon: Icons.work_outline),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุตำแหน่ง' : null,
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
                        value: _safetyRole,
                        decoration: _inputDecoration('บทบาท / หน้าที่ด้านความปลอดภัย *', icon: Icons.security),
                        items: const [
                          DropdownMenuItem(value: 'GENERAL', child: Text('👤 พนักงานทั่วไป (General Staff)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'SUPERVISOR_SAFETY', child: Text('🛡️ จป.ระดับหัวหน้างาน (Supervisor)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'EXECUTIVE_SAFETY', child: Text('👔 จป.ระดับบริหาร (Executive)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'COMMITTEE_MEMBER', child: Text('📋 กรรมการความปลอดภัย (คปอ.)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'ERT_FIREFIGHTER', child: Text('🚒 ทีมผจญเพลิง / ERT', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'FIRST_AIDER', child: Text('🩹 ผู้ช่วยเหลือปฐมพยาบาล First Aid', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _safetyRole = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _status,
                        decoration: _inputDecoration('สถานะพนักงาน *', icon: Icons.toggle_on_outlined),
                        items: const [
                          DropdownMenuItem(value: 'ACTIVE', child: Text('🟢 ปฏิบัติงานอยู่ (Active)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'RESIGNED', child: Text('⚪ พ้นสภาพ / ลาออก (Resigned)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'SUSPENDED', child: Text('🟡 พักงาน (Suspended)', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _status = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildSectionHeader('๓. ข้อมูลการติดต่อและวันเริ่มงาน'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hireDateController,
                        readOnly: true,
                        onTap: _selectDate,
                        decoration: _inputDecoration('วันที่เริ่มงาน', icon: Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: _inputDecoration('เบอร์โทรศัพท์ติดต่อ', icon: Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration('อีเมล', icon: Icons.email_outlined),
                      ),
                    ),
                  ],
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
          label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกข้อมูลพนักงาน'),
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
