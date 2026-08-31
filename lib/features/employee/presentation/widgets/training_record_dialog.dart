import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/employee_models.dart';
import '../providers/employee_providers.dart';

class TrainingRecordDialog extends ConsumerStatefulWidget {
  final TrainingRecord? existingRecord;
  final int? preselectedEmployeeId;

  const TrainingRecordDialog({
    Key? key,
    this.existingRecord,
    this.preselectedEmployeeId,
  }) : super(key: key);

  @override
  ConsumerState<TrainingRecordDialog> createState() => _TrainingRecordDialogState();
}

class _TrainingRecordDialogState extends ConsumerState<TrainingRecordDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedEmployeeId;
  int? _selectedCourseId;

  late TextEditingController _trainingDateController;
  late TextEditingController _expiryDateController;
  late TextEditingController _organizerController;
  late TextEditingController _trainerController;
  late TextEditingController _certNoController;
  late TextEditingController _scoreController;
  late TextEditingController _notesController;

  bool _passed = true;
  String? _pickedCertPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.existingRecord;

    _selectedEmployeeId = r?.employeeId ?? widget.preselectedEmployeeId;
    _selectedCourseId = r?.courseId;

    _trainingDateController = TextEditingController(
      text: r?.trainingDate ?? DateTime.now().toIso8601String().substring(0, 10),
    );
    _expiryDateController = TextEditingController(text: r?.expiryDate ?? '');
    _organizerController = TextEditingController(text: r?.organizerName ?? 'อบรมภายในบริษัท (In-house Training)');
    _trainerController = TextEditingController(text: r?.trainerName ?? '');
    _certNoController = TextEditingController(text: r?.certNumber ?? '');
    _scoreController = TextEditingController(text: r?.score != null ? '${r!.score}' : '100');
    _notesController = TextEditingController(text: r?.notes ?? '');

    if (r != null) {
      _passed = r.passed;
      _pickedCertPath = r.certFilePath;
    }
  }

  @override
  void dispose() {
    _trainingDateController.dispose();
    _expiryDateController.dispose();
    _organizerController.dispose();
    _trainerController.dispose();
    _certNoController.dispose();
    _scoreController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onCourseChanged(int? courseId, List<TrainingCourse> courses) {
    if (courseId == null) return;
    setState(() {
      _selectedCourseId = courseId;
      final course = courses.firstWhere((c) => c.id == courseId, orElse: () => courses.first);
      if (course.validityYears > 0) {
        final trDate = DateTime.tryParse(_trainingDateController.text) ?? DateTime.now();
        final expDate = DateTime(trDate.year + course.validityYears, trDate.month, trDate.day);
        _expiryDateController.text = expDate.toIso8601String().substring(0, 10);
      } else {
        _expiryDateController.text = ''; // No expiry
      }
    });
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

  Future<void> _pickCertFile() async {
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกพนักงาน'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกหลักสูตรฝึกอบรม'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final record = TrainingRecord(
        id: widget.existingRecord?.id,
        employeeId: _selectedEmployeeId!,
        courseId: _selectedCourseId!,
        trainingDate: _trainingDateController.text.trim(),
        expiryDate: _expiryDateController.text.trim().isEmpty ? null : _expiryDateController.text.trim(),
        organizerName: _organizerController.text.trim().isEmpty ? null : _organizerController.text.trim(),
        trainerName: _trainerController.text.trim().isEmpty ? null : _trainerController.text.trim(),
        certNumber: _certNoController.text.trim().isEmpty ? null : _certNoController.text.trim(),
        certFilePath: _pickedCertPath,
        score: double.tryParse(_scoreController.text.trim()),
        passed: _passed,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final isNewCert = _pickedCertPath != null && _pickedCertPath != widget.existingRecord?.certFilePath;

      await ref.read(trainingRecordsProvider.notifier).saveRecord(
            record,
            newCertPath: isNewCert ? _pickedCertPath : null,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingRecord == null ? 'บันทึกประวัติการฝึกอบรมเรียบร้อย' : 'แก้ไขข้อมูลการฝึกอบรมเรียบร้อย'),
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
    final employeesAsync = ref.watch(employeesProvider);
    final coursesAsync = ref.watch(trainingCoursesProvider);
    final isEdit = widget.existingRecord != null;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_rounded, color: Color(0xFF0D9488), size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            isEdit ? 'แก้ไขประวัติการฝึกอบรม' : 'บันทึกการฝึกอบรมความปลอดภัย',
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
                _buildSectionHeader('๑. พนักงานและหลักสูตรฝึกอบรม'),
                // Employee selector
                employeesAsync.when(
                  data: (employees) {
                    if (_selectedEmployeeId == null && employees.isNotEmpty) {
                      _selectedEmployeeId = employees.first.id;
                    }
                    return DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _selectedEmployeeId,
                      decoration: _inputDecoration('เลือกพนักงานที่เข้ารับการอบรม *', icon: Icons.person),
                      items: employees.map((e) {
                        return DropdownMenuItem(
                          value: e.id,
                          child: Text('${e.employeeCode} - ${e.fullName} (${e.department})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedEmployeeId = v),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 12),

                // Course selector
                coursesAsync.when(
                  data: (courses) {
                    if (_selectedCourseId == null && courses.isNotEmpty) {
                      _selectedCourseId = courses.first.id;
                    }
                    return DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _selectedCourseId,
                      decoration: _inputDecoration('เลือกหลักสูตรฝึกอบรมความปลอดภัย *', icon: Icons.menu_book),
                      items: courses.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text('[${c.courseCode}] ${c.courseName} (${c.durationHours.toInt()} ชม.)', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (v) => _onCourseChanged(v, courses),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 16),

                _buildSectionHeader('๒. วันที่อบรมและอายุการรับรอง'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _trainingDateController,
                        readOnly: true,
                        onTap: () => _selectDate(_trainingDateController),
                        decoration: _inputDecoration('วันที่ฝึกอบรม *', icon: Icons.event_available),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุวันที่อบรม' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _expiryDateController,
                        readOnly: true,
                        onTap: () => _selectDate(_expiryDateController),
                        decoration: _inputDecoration('วันหมดอายุ / อบรมทบทวน', icon: Icons.event_busy),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _organizerController,
                        decoration: _inputDecoration('หน่วยงาน / สถาบันที่จัดอบรม', icon: Icons.business),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _trainerController,
                        decoration: _inputDecoration('วิทยากร / ผู้สอน', icon: Icons.person_pin),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildSectionHeader('๓. ผลการอบรมและวุฒิบัตร (Certificate)'),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _certNoController,
                        decoration: _inputDecoration('เลขที่ใบประกาศนียบัตร / วุฒิบัตร', icon: Icons.card_membership),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _scoreController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('คะแนนประเมิน (%)', icon: Icons.grade),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // File picker strip
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
                        _pickedCertPath != null ? Icons.verified_rounded : Icons.attach_file,
                        color: _pickedCertPath != null ? Colors.green : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _pickedCertPath != null
                              ? 'ไฟล์วุฒิบัตร: ${p.basename(_pickedCertPath!)}'
                              : 'ยังไม่ได้แนบไฟล์วุฒิบัตร / ใบประกาศ (PDF หรือ รูปภาพ)',
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
                        onPressed: _pickCertFile,
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: Text(_pickedCertPath != null ? 'เปลี่ยนไฟล์' : 'เลือกไฟล์'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildSectionHeader('๔. หมายเหตุ / รายละเอียดเพิ่มเติม'),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: _inputDecoration('หมายเหตุเพิ่มเติม', icon: Icons.notes),
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
          label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกการฝึกอบรม'),
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
