import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/health_models.dart';
import '../providers/health_providers.dart';

class FollowupActionDialog extends ConsumerStatefulWidget {
  final int healthRecordId;
  final int employeeId;
  final String? initialSymptom;
  final MedicalSurveillanceFollowup? existingFollowup;

  const FollowupActionDialog({
    Key? key,
    required this.healthRecordId,
    required this.employeeId,
    this.initialSymptom,
    this.existingFollowup,
  }) : super(key: key);

  @override
  ConsumerState<FollowupActionDialog> createState() => _FollowupActionDialogState();
}

class _FollowupActionDialogState extends ConsumerState<FollowupActionDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _symptomController;
  late String _actionType;
  late TextEditingController _detailsController;
  late TextEditingController _hospitalController;
  late TextEditingController _targetDateController;
  late String _status;
  late TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final f = widget.existingFollowup;
    _symptomController = TextEditingController(text: f?.abnormalSymptom ?? widget.initialSymptom ?? 'ผลการได้ยินลดลงที่ความถี่สูง / ความดันโลหิตสูง');
    _actionType = f?.followupActionType ?? 'REPEAT_TEST';
    _detailsController = TextEditingController(text: f?.actionDetails ?? 'นัดตรวจซ้ำ (Repeat Audiogram) ภายใน 30 วัน และจัดให้สวมใส่ Ear Muff');
    _hospitalController = TextEditingController(text: f?.treatmentHospital ?? 'แผนกอาชีวเวชศาสตร์ โรงพยาบาล');
    _targetDateController = TextEditingController(
      text: f?.targetDate ?? DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10),
    );
    _status = f?.status ?? 'OPEN';
    _notesController = TextEditingController(text: f?.notes ?? '');
  }

  @override
  void dispose() {
    _symptomController.dispose();
    _detailsController.dispose();
    _hospitalController.dispose();
    _targetDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final followup = MedicalSurveillanceFollowup(
        id: widget.existingFollowup?.id,
        healthRecordId: widget.healthRecordId,
        employeeId: widget.employeeId,
        abnormalSymptom: _symptomController.text.trim(),
        followupActionType: _actionType,
        actionDetails: _detailsController.text.trim(),
        treatmentHospital: _hospitalController.text.trim().isEmpty ? null : _hospitalController.text.trim(),
        targetDate: _targetDateController.text.trim(),
        completedDate: _status == 'RESOLVED' ? DateTime.now().toIso8601String().substring(0, 10) : null,
        status: _status,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await ref.read(medicalFollowupsProvider.notifier).saveFollowup(followup);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingFollowup != null ? 'อัปเดตการติดตามอาการเรียบร้อย' : 'บันทึกการติดตามอาการและส่งตรวจซ้ำเรียบร้อย'),
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
    final isEdit = widget.existingFollowup != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.medical_information_rounded, color: Colors.red.shade700, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            isEdit ? 'แก้ไขการติดตามอาการทางการแพทย์' : 'บันทึกการติดตามอาการ & ส่งตรวจซ้ำ (Medical Surveillance)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _symptomController,
                  decoration: _inputDecoration('อาการหรือผลตรวจที่ผิดปกติที่ต้องติดตาม *', icon: Icons.warning_amber_rounded),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุอาการที่ผิดปกติ' : null,
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _actionType,
                  decoration: _inputDecoration('ประเภทมาตรการการดูแลสุขภาพ *', icon: Icons.medical_services_outlined),
                  items: const [
                    DropdownMenuItem(value: 'REPEAT_TEST', child: Text('🔄 ๑. ส่งตรวจซ้ำ (Repeat Test / Re-check)')),
                    DropdownMenuItem(value: 'MEDICAL_TREATMENT', child: Text('💊 ๒. ส่งรักษาพยาบาล / ติดตามการรักษา')),
                    DropdownMenuItem(value: 'JOB_TRANSFER', child: Text('🔁 ๓. ปรับเปลี่ยนหน้าที่งาน / ย้ายออกจากจุดเสี่ยง')),
                    DropdownMenuItem(value: 'WORK_ENVIRONMENT_FIX', child: Text('🛠️ ๔. ปรับปรุงสภาพแวดล้อมการทำงาน / เครื่องจักร')),
                    DropdownMenuItem(value: 'SPECIALIST_CONSULT', child: Text('👨‍⚕️ ๕. ส่งปรึกษาแพทย์อาชีวเวชศาสตร์เฉพาะทาง')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _actionType = v);
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _detailsController,
                  maxLines: 3,
                  decoration: _inputDecoration('รายละเอียดแผนการดูแลและข้อปฏิบัติ *', icon: Icons.description),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุรายละเอียด' : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _hospitalController,
                        decoration: _inputDecoration('สถานพยาบาล / คลินิกที่นัดตรวจ', icon: Icons.local_hospital),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _targetDateController,
                        decoration: _inputDecoration('วันนัดติดตามผล *', icon: Icons.calendar_today),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _status,
                  decoration: _inputDecoration('สถานะการติดตามอาการ', icon: Icons.task_alt),
                  items: const [
                    DropdownMenuItem(value: 'OPEN', child: Text('🔴 อยู่ระหว่างเฝ้าระวัง (Open)')),
                    DropdownMenuItem(value: 'IN_PROGRESS', child: Text('🟡 กำลังรักษา/รอผลตรวจซ้ำ (In Progress)')),
                    DropdownMenuItem(value: 'RESOLVED', child: Text('🟢 หายดี/ปิดการเฝ้าระวังแล้ว (Resolved)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _notesController,
                  decoration: _inputDecoration('บันทึกผลการติดตาม / หมายเหตุ', icon: Icons.notes),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(), child: const Text('ยกเลิก')),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle_outline, size: 18),
          label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกข้อมูล'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
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
