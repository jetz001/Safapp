import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/contractor_models.dart';
import '../providers/contractor_providers.dart';

class ContractorWorkerDialog extends ConsumerStatefulWidget {
  final ContractorWorker? existingWorker;
  final int? preselectedContractorId;

  const ContractorWorkerDialog({
    Key? key,
    this.existingWorker,
    this.preselectedContractorId,
  }) : super(key: key);

  @override
  ConsumerState<ContractorWorkerDialog> createState() => _ContractorWorkerDialogState();
}

class _ContractorWorkerDialogState extends ConsumerState<ContractorWorkerDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _idCardController;
  late TextEditingController _inductionDateController;
  late TextEditingController _validUntilController;
  late TextEditingController _notesController;

  int? _selectedContractorId;
  String _jobRole = 'ช่างประกอบนั่งร้าน (Scaffolder)';
  String _status = 'ACTIVE';

  String? _pickedPhotoPath;
  String? _pickedCertPath;
  bool _isSaving = false;

  final List<String> _jobRoles = [
    'หัวหน้างาน / ผู้ควบคุมงาน (Supervisor)',
    'ช่างประกอบนั่งร้าน (Scaffolder)',
    'ช่างเชื่อม & Hot Work (Welder)',
    'ช่างไฟฟ้า & อิเล็กทรอนิกส์ (Electrician)',
    'ผู้ปฏิบัติงานบนที่สูง (Work at Height)',
    'ผู้ปฏิบัติงานในที่อับอากาศ (Confined Space)',
    'ช่างเครื่องกล & ไฮดรอลิก (Mechanic)',
    'พนักงานขับรถยก / ปั้นจั่น (Operator)',
    'คนงานทั่วไป (General Worker)',
  ];

  @override
  void initState() {
    super.initState();
    final w = widget.existingWorker;

    _nameController = TextEditingController(text: w?.workerName ?? '');
    _idCardController = TextEditingController(text: w?.nationalIdOrPassport ?? '');
    _inductionDateController = TextEditingController(
      text: w?.inductionDate ?? DateTime.now().toIso8601String().substring(0, 10),
    );

    // Default +1 year validity for safety induction
    final defaultValidUntil = DateTime.now().add(const Duration(days: 365)).toIso8601String().substring(0, 10);
    _validUntilController = TextEditingController(text: w?.inductionValidUntil ?? defaultValidUntil);
    _notesController = TextEditingController(text: w?.notes ?? '');

    _selectedContractorId = w?.contractorId ?? widget.preselectedContractorId;
    if (w != null) {
      if (_jobRoles.contains(w.jobRole)) {
        _jobRole = w.jobRole;
      }
      _status = w.status;
      _pickedPhotoPath = w.photoPath;
      _pickedCertPath = w.certFilePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardController.dispose();
    _inductionDateController.dispose();
    _validUntilController.dispose();
    _notesController.dispose();
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

  Future<void> _pickCert() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedCertPath = result.files.single.path;
      });
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedContractorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกสังกัดบริษัทผู้รับเหมา'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final worker = ContractorWorker(
        id: widget.existingWorker?.id,
        contractorId: _selectedContractorId!,
        workerName: _nameController.text.trim(),
        nationalIdOrPassport: _idCardController.text.trim().isEmpty ? null : _idCardController.text.trim(),
        jobRole: _jobRole,
        photoPath: _pickedPhotoPath,
        inductionDate: _inductionDateController.text.trim(),
        inductionValidUntil: _validUntilController.text.trim().isEmpty ? null : _validUntilController.text.trim(),
        certFilePath: _pickedCertPath,
        status: _status,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final isNewPhoto = _pickedPhotoPath != null && _pickedPhotoPath != widget.existingWorker?.photoPath;
      final isNewCert = _pickedCertPath != null && _pickedCertPath != widget.existingWorker?.certFilePath;

      await ref.read(contractorWorkersProvider.notifier).saveWorker(
            worker,
            newPhotoPath: isNewPhoto ? _pickedPhotoPath : null,
            newCertPath: isNewCert ? _pickedCertPath : null,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingWorker == null ? 'เพิ่มคนงานและออกบัตรเรียบร้อย' : 'แก้ไขข้อมูลคนงานเรียบร้อย'),
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
    final companiesAsync = ref.watch(contractorCompaniesProvider);
    final isEdit = widget.existingWorker != null;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.engineering_rounded, color: Color(0xFF0D9488), size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            isEdit ? 'แก้ไขข้อมูลคนงานผู้รับเหมา' : 'ลงทะเบียนคนงาน & อบรม Safety Induction',
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
                // 1. บริษัท & รูปถ่าย
                _buildSectionHeader('๑. สังกัดบริษัทผู้รับเหมาและรูปถ่าย'),
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

                    // Company & Name Inputs
                    Expanded(
                      child: Column(
                        children: [
                          companiesAsync.when(
                            data: (companies) {
                              if (_selectedContractorId == null && companies.isNotEmpty) {
                                _selectedContractorId = companies.first.id;
                              }
                              return DropdownButtonFormField<int>(
                                isExpanded: true,
                                value: _selectedContractorId,
                                decoration: _inputDecoration('สังกัดบริษัทผู้รับเหมา *', icon: Icons.business),
                                items: companies.map((c) {
                                  return DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.companyName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _selectedContractorId = v);
                                },
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (_, __) => const SizedBox(),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameController,
                            decoration: _inputDecoration('ชื่อ - นามสกุล คนงาน *', icon: Icons.person),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อคนงาน' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. ตำแหน่ง & ข้อมูลประจำตัว
                _buildSectionHeader('๒. ตำแหน่งงาน & ข้อมูลระบุตัวตน'),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _jobRole,
                        decoration: _inputDecoration('ตำแหน่ง / ทักษะเฉพาะทาง *', icon: Icons.handyman),
                        items: _jobRoles.map((r) {
                          return DropdownMenuItem(
                            value: r,
                            child: Text(r, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _jobRole = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _idCardController,
                        decoration: _inputDecoration('เลขบัตร ปชช. / พาสปอร์ต', icon: Icons.credit_card),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Safety Induction & ใบรับรอง
                _buildSectionHeader('๓. ข้อมูลการอบรมความปลอดภัย (Safety Induction)'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _inductionDateController,
                        readOnly: true,
                        onTap: () => _selectDate(_inductionDateController),
                        decoration: _inputDecoration('วันที่ผ่านการอบรม *', icon: Icons.event_available),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุวันที่อบรม' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _validUntilController,
                        readOnly: true,
                        onTap: () => _selectDate(_validUntilController),
                        decoration: _inputDecoration('วันหมดอายุบัตรอนุญาต', icon: Icons.event_busy),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Certificate upload button
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _pickedCertPath != null ? Icons.check_circle : Icons.attach_file,
                        color: _pickedCertPath != null ? Colors.green : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _pickedCertPath != null
                              ? 'ไฟล์ใบรับรอง/บัตร: ${p.basename(_pickedCertPath!)}'
                              : 'ยังไม่ได้แนบไฟล์ใบรับรองช่าง/ผลตรวจสุขภาพ (PDF หรือรูปภาพ)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: _pickedCertPath != null ? Colors.black87 : Colors.grey.shade600,
                            fontWeight: _pickedCertPath != null ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickCert,
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: Text(_pickedCertPath != null ? 'เปลี่ยนไฟล์' : 'เลือกไฟล์'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. หมายเหตุ
                _buildSectionHeader('๔. หมายเหตุ / ข้อจำกัดทางการแพทย์'),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: _inputDecoration('หมายเหตุ เช่น โรคประจำตัว, ประวัติการแพ้, อุปกรณ์ประจำตัว', icon: Icons.notes),
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
          label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกข้อมูลคนงาน'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D9488),
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
        borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
      ),
    );
  }
}
