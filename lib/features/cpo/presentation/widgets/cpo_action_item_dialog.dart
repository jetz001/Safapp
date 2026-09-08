import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cpo_action_item_model.dart';
import '../../domain/enums/cpo_action_status.dart';
import '../providers/cpo_providers.dart';
import '../../../employee/presentation/providers/employee_providers.dart';

class CpoActionItemDialog extends ConsumerStatefulWidget {
  final int? meetingId;
  final int agendaNo;
  final CpoActionItemModel? existingItem;

  const CpoActionItemDialog({
    super.key,
    this.meetingId,
    this.agendaNo = 5,
    this.existingItem,
  });

  @override
  ConsumerState<CpoActionItemDialog> createState() => _CpoActionItemDialogState();
}

class _CpoActionItemDialogState extends ConsumerState<CpoActionItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _detailCtrl;
  late TextEditingController _picCtrl;
  late TextEditingController _deptCtrl;
  late TextEditingController _dueDateCtrl;
  late TextEditingController _notesCtrl;

  String _priority = 'MEDIUM';
  CpoActionStatus _status = CpoActionStatus.pending;
  int _progress = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _titleCtrl = TextEditingController(text: item?.title ?? '');
    _detailCtrl = TextEditingController(text: item?.actionDetail ?? '');
    _picCtrl = TextEditingController(text: item?.responsiblePerson ?? '');
    _deptCtrl = TextEditingController(text: item?.department ?? '');
    final defaultDue = DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10);
    _dueDateCtrl = TextEditingController(text: item?.dueDate ?? defaultDue);
    _notesCtrl = TextEditingController(text: item?.resolutionNotes ?? '');

    if (item != null) {
      _priority = item.priority;
      _status = item.status;
      _progress = item.progressPercent;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _detailCtrl.dispose();
    _picCtrl.dispose();
    _deptCtrl.dispose();
    _dueDateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final cur = DateTime.tryParse(_dueDateCtrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: cur,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _dueDateCtrl.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final itemCode = widget.existingItem?.itemCode ??
          'CPO-ACT-${now.year}-${now.millisecondsSinceEpoch.toString().substring(8)}';

      final model = CpoActionItemModel(
        id: widget.existingItem?.id,
        itemCode: itemCode,
        meetingId: widget.existingItem?.meetingId ?? widget.meetingId ?? 1,
        agendaNo: widget.agendaNo,
        title: _titleCtrl.text.trim(),
        actionDetail: _detailCtrl.text.trim(),
        responsiblePerson: _picCtrl.text.trim(),
        department: _deptCtrl.text.trim().isEmpty ? null : _deptCtrl.text.trim(),
        dueDate: _dueDateCtrl.text.trim(),
        priority: _priority,
        status: _status,
        progressPercent: _progress,
        resolutionNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        completedDate: _status == CpoActionStatus.completed
            ? (widget.existingItem?.completedDate ?? now.toIso8601String().substring(0, 10))
            : null,
      );

      await ref.read(cpoActionItemsProvider.notifier).saveActionItem(model);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingItem != null ? 'อัปเดตงานตามมติเรียบร้อย' : 'เพิ่มงานตามมติเรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
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
    final employees = employeesAsync.asData?.value ?? [];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.assignment_turned_in, color: Colors.blue.shade800),
          ),
          const SizedBox(width: 12),
          Text(widget.existingItem != null ? 'แก้ไขงานตามมติที่ประชุม คปอ.' : 'มอบหมายงานตามมติที่ประชุม (Action Item)'),
        ],
      ),
      content: SizedBox(
        width: 550,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'หัวข้องาน / มาตรการความปลอดภัย *',
                    hintText: 'เช่น ติดตั้งการ์ดป้องกันสายพาน, ซ่อมแซมไฟฉุกเฉิน',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุหัวข้องาน' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _detailCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียดการปฏิบัติและมติที่ประชุม *',
                    hintText: 'ระบุขั้นตอนการดำเนินการ เป้าหมายความปลอดภัย หรือข้อกำหนดตามมติ คปอ.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุรายละเอียด' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Autocomplete<String>(
                        initialValue: TextEditingValue(text: _picCtrl.text),
                        optionsBuilder: (textVal) {
                          if (textVal.text.isEmpty) return const [];
                          return employees
                              .map((e) => e.fullName)
                              .where((name) => name.toLowerCase().contains(textVal.text.toLowerCase()));
                        },
                        onSelected: (val) {
                          _picCtrl.text = val;
                          final match = employees.firstWhere((e) => e.fullName == val, orElse: () => employees.first);
                          if (match.department != null && match.department!.isNotEmpty) {
                            setState(() => _deptCtrl.text = match.department!);
                          }
                        },
                        fieldViewBuilder: (ctx, ctrl, focus, onSub) {
                          ctrl.addListener(() => _picCtrl.text = ctrl.text);
                          return TextFormField(
                            controller: ctrl,
                            focusNode: focus,
                            decoration: const InputDecoration(
                              labelText: 'ผู้รับผิดชอบ (PIC) *',
                              hintText: 'พิมพ์หรือเลือกพนักงาน',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุผู้รับผิดชอบ' : null,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _deptCtrl,
                        decoration: const InputDecoration(
                          labelText: 'แผนก/ฝ่าย',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.apartment),
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
                        controller: _dueDateCtrl,
                        readOnly: true,
                        onTap: _selectDate,
                        decoration: const InputDecoration(
                          labelText: 'กำหนดแล้วเสร็จ (Due Date) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: const InputDecoration(
                          labelText: 'ความสำคัญ (Priority)',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'LOW', child: Text('ปกติ (Low)')),
                          DropdownMenuItem(value: 'MEDIUM', child: Text('ปานกลาง (Medium)')),
                          DropdownMenuItem(value: 'HIGH', child: Text('สำคัญสูง (High)')),
                          DropdownMenuItem(value: 'URGENT', child: Text('เร่งด่วนมาก (Urgent)')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _priority = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<CpoActionStatus>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'สถานะการดำเนินงาน',
                          border: OutlineInputBorder(),
                        ),
                        items: CpoActionStatus.values.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                Text(s.labelTh),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _status = v;
                              if (v == CpoActionStatus.completed) _progress = 100;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ความคืบหน้า: $_progress%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Slider(
                            value: _progress.toDouble(),
                            min: 0,
                            max: 100,
                            divisions: 20,
                            label: '$_progress%',
                            onChanged: (val) {
                              setState(() {
                                _progress = val.toInt();
                                if (_progress == 100) {
                                  _status = CpoActionStatus.completed;
                                } else if (_progress > 0 && _status == CpoActionStatus.pending) {
                                  _status = CpoActionStatus.inProgress;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'บันทึกผลการติดตาม / หมายเหตุการปิดงาน',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('บันทึกงานตามมติ', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
