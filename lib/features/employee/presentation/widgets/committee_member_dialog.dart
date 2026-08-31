import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/employee_models.dart';
import '../providers/employee_providers.dart';

class CommitteeMemberDialog extends ConsumerStatefulWidget {
  final SafetyCommitteeMember? existingMember;

  const CommitteeMemberDialog({
    Key? key,
    this.existingMember,
  }) : super(key: key);

  @override
  ConsumerState<CommitteeMemberDialog> createState() => _CommitteeMemberDialogState();
}

class _CommitteeMemberDialogState extends ConsumerState<CommitteeMemberDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedEmployeeId;
  late TextEditingController _termYearController;
  late TextEditingController _appointedDateController;
  late TextEditingController _termEndDateController;

  String _committeePosition = 'EMPLOYEE_REP';
  String _status = 'ACTIVE';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.existingMember;

    _selectedEmployeeId = m?.employeeId;
    _termYearController = TextEditingController(text: m?.termYear ?? '2567-2569 (วาระ ๒ ปี)');
    _appointedDateController = TextEditingController(
      text: m?.appointedDate ?? DateTime.now().toIso8601String().substring(0, 10),
    );
    final defaultEnd = DateTime.now().add(const Duration(days: 730)).toIso8601String().substring(0, 10);
    _termEndDateController = TextEditingController(text: m?.termEndDate ?? defaultEnd);

    if (m != null) {
      _committeePosition = m.committeePosition;
      _status = m.status;
    }
  }

  @override
  void dispose() {
    _termYearController.dispose();
    _appointedDateController.dispose();
    _termEndDateController.dispose();
    super.dispose();
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
    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกพนักงาน'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final member = SafetyCommitteeMember(
        id: widget.existingMember?.id,
        termYear: _termYearController.text.trim(),
        employeeId: _selectedEmployeeId!,
        committeePosition: _committeePosition,
        appointedDate: _appointedDateController.text.trim(),
        termEndDate: _termEndDateController.text.trim(),
        status: _status,
      );

      await ref.read(safetyCommitteeProvider.notifier).saveMember(member);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingMember == null ? 'แต่งตั้งกรรมการ คปอ. เรียบร้อย' : 'แก้ไขข้อมูล คปอ. เรียบร้อย'),
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
    final isEdit = widget.existingMember != null;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.groups_rounded, color: Color(0xFF6366F1), size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            isEdit ? 'แก้ไขข้อมูลกรรมการ คปอ.' : 'แต่งตั้งคณะกรรมการความปลอดภัย (คปอ.)',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
                _buildSectionHeader('๑. พนักงานและตำแหน่งในคณะกรรมการ'),
                employeesAsync.when(
                  data: (employees) {
                    if (_selectedEmployeeId == null && employees.isNotEmpty) {
                      _selectedEmployeeId = employees.first.id;
                    }
                    return DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _selectedEmployeeId,
                      decoration: _inputDecoration('เลือกพนักงาน *', icon: Icons.person),
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

                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _committeePosition,
                  decoration: _inputDecoration('ตำแหน่งใน คปอ. *', icon: Icons.assignment_ind),
                  items: const [
                    DropdownMenuItem(value: 'CHAIR_EMPLOYER_REP', child: Text('👑 ประธาน คปอ. (ผู้แทนนายจ้างระดับบริหาร)', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'EMPLOYER_REP', child: Text('👔 กรรมการ คปอ. (ผู้แทนนายจ้างระดับบังคับบัญชา)', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'EMPLOYEE_REP', child: Text('👥 กรรมการ คปอ. (ผู้แทนลูกจ้างจากการเลือกตั้ง)', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'SECRETARY_SAFETY_OFFICER', child: Text('📝 เลขานุการ คปอ. (จป.วิชาชีพ)', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _committeePosition = v);
                  },
                ),
                const SizedBox(height: 16),

                _buildSectionHeader('๒. วาระการดำรงตำแหน่ง (วาระ ๒ ปี ตามกฎหมาย)'),
                TextFormField(
                  controller: _termYearController,
                  decoration: _inputDecoration('วาระ คปอ. *', icon: Icons.event_note),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุวาระ' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _appointedDateController,
                        readOnly: true,
                        onTap: () => _selectDate(_appointedDateController),
                        decoration: _inputDecoration('วันที่เริ่มดำรงตำแหน่ง *', icon: Icons.event_available),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _termEndDateController,
                        readOnly: true,
                        onTap: () => _selectDate(_termEndDateController),
                        decoration: _inputDecoration('วันสิ้นสุดวาระ', icon: Icons.event_busy),
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
          label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกแต่งตั้ง'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
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
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
      ),
    );
  }
}
