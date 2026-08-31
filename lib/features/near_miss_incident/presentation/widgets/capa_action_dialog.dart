import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/accident_models.dart';
import '../providers/accident_providers.dart';

class CapaActionDialog extends ConsumerStatefulWidget {
  final int investigationId;
  final AccidentCapaAction? existingAction;

  const CapaActionDialog({
    Key? key,
    required this.investigationId,
    this.existingAction,
  }) : super(key: key);

  @override
  ConsumerState<CapaActionDialog> createState() => _CapaActionDialogState();
}

class _CapaActionDialogState extends ConsumerState<CapaActionDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _controlHierarchy;
  late TextEditingController _actionDescController;
  late TextEditingController _responsibleController;
  late TextEditingController _targetDateController;
  late TextEditingController _notesController;
  late String _status;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existingAction;
    _controlHierarchy = a?.controlHierarchy ?? 'ENGINEERING';
    _actionDescController = TextEditingController(text: a?.actionDescription ?? '');
    _responsibleController = TextEditingController(text: a?.responsiblePerson ?? 'หัวหน้าแผนก / ฝ่ายวิศวกรรม');
    _targetDateController = TextEditingController(
      text: a?.targetDate ?? DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10),
    );
    _notesController = TextEditingController(text: a?.notes ?? '');
    _status = a?.status ?? 'OPEN';
  }

  @override
  void dispose() {
    _actionDescController.dispose();
    _responsibleController.dispose();
    _targetDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final action = AccidentCapaAction(
        id: widget.existingAction?.id,
        investigationId: widget.investigationId,
        controlHierarchy: _controlHierarchy,
        actionDescription: _actionDescController.text.trim(),
        responsiblePerson: _responsibleController.text.trim(),
        targetDate: _targetDateController.text.trim(),
        completedDate: _status == 'COMPLETED' ? DateTime.now().toIso8601String().substring(0, 10) : null,
        status: _status,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await ref.read(accidentCapaProvider.notifier).saveAction(action);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingAction != null ? 'อัปเดตมาตรการเรียบร้อย' : 'เพิ่มมาตรการแก้ไขป้องกันเรียบร้อย'),
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
    final isEdit = widget.existingAction != null;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.security_rounded, color: Color(0xFF1E3A8A), size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            isEdit ? 'แก้ไขมาตรการแก้ไขป้องกัน (CAPA)' : 'เพิ่มมาตรการแก้ไขป้องกัน ๔ ระดับ (CAPA)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _controlHierarchy,
                  decoration: _inputDecoration('ระดับการควบคุม (Hierarchy of Controls) *', icon: Icons.layers),
                  items: const [
                    DropdownMenuItem(value: 'ENGINEERING', child: Text('🛠️ ๑. ด้านวิศวกรรม (Engineering Controls - ฝาครอบ, Guard, Interlock)')),
                    DropdownMenuItem(value: 'ADMINISTRATIVE', child: Text('📋 ๒. ด้านบริหารจัดการ (Administrative Controls - SOP, JSA, ป้ายเตือน)')),
                    DropdownMenuItem(value: 'TRAINING', child: Text('🎓 ๓. ด้านการฝึกอบรม (Training Controls - อบรมทบทวน, Safety Talk)')),
                    DropdownMenuItem(value: 'PPE', child: Text('🦺 ๔. อุปกรณ์ PPE (Personal Protective Equipment)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _controlHierarchy = v);
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _actionDescController,
                  maxLines: 3,
                  decoration: _inputDecoration('รายละเอียดการปรับปรุงแก้ไข / แผนงานปฏิบัติการ *', icon: Icons.description),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุรายละเอียดมาตรการ' : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _responsibleController,
                        decoration: _inputDecoration('ผู้รับผิดชอบดำเนินการ *', icon: Icons.person),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุผู้รับผิดชอบ' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _targetDateController,
                        decoration: _inputDecoration('กำหนดเสร็จ *', icon: Icons.calendar_today),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุวันที่' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _status,
                  decoration: _inputDecoration('สถานะการดำเนินงาน', icon: Icons.task_alt),
                  items: const [
                    DropdownMenuItem(value: 'OPEN', child: Text('🔴 รอดำเนินการ (Open)')),
                    DropdownMenuItem(value: 'IN_PROGRESS', child: Text('🟡 กำลังดำเนินการ (In Progress)')),
                    DropdownMenuItem(value: 'COMPLETED', child: Text('🟢 ดำเนินการเสร็จสิ้นแล้ว (Completed)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _notesController,
                  decoration: _inputDecoration('หมายเหตุ / หลักฐานการปิดงาน (ถ้ามี)', icon: Icons.notes),
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
          label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกมาตรการ'),
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
