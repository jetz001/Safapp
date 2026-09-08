import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cpo_meeting_model.dart';
import '../../domain/enums/cpo_meeting_status.dart';
import '../providers/cpo_providers.dart';

class CpoMeetingEditDialog extends ConsumerStatefulWidget {
  final CpoMeetingModel? existingMeeting;

  const CpoMeetingEditDialog({super.key, this.existingMeeting});

  @override
  ConsumerState<CpoMeetingEditDialog> createState() => _CpoMeetingEditDialogState();
}

class _CpoMeetingEditDialogState extends ConsumerState<CpoMeetingEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _noCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _chairCtrl;
  late TextEditingController _secCtrl;

  CpoMeetingStatus _status = CpoMeetingStatus.draft;
  bool _seedAgendas = true;
  bool _populateMembers = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.existingMeeting;
    final now = DateTime.now();
    final yearTh = (now.year + 543).toString();

    _noCtrl = TextEditingController(text: m != null ? m.meetingNo.toString() : '1');
    _yearCtrl = TextEditingController(text: m?.meetingYear ?? yearTh);
    _titleCtrl = TextEditingController(text: m?.meetingTitle ?? 'การประชุม คปอ. ประจำเดือน');
    _dateCtrl = TextEditingController(text: m?.meetingDate ?? now.toIso8601String().substring(0, 10));
    _startCtrl = TextEditingController(text: m?.startTime ?? '09:00');
    _endCtrl = TextEditingController(text: m?.endTime ?? '12:00');
    _locationCtrl = TextEditingController(text: m?.location ?? 'ห้องประชุมใหญ่ ชั้น ๒');
    _chairCtrl = TextEditingController(text: m?.chairName ?? '');
    _secCtrl = TextEditingController(text: m?.secretaryName ?? '');

    if (m != null) {
      _status = m.status;
      _seedAgendas = false;
      _populateMembers = false;
    }
  }

  @override
  void dispose() {
    _noCtrl.dispose();
    _yearCtrl.dispose();
    _titleCtrl.dispose();
    _dateCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _locationCtrl.dispose();
    _chairCtrl.dispose();
    _secCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final cur = DateTime.tryParse(_dateCtrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: cur,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _dateCtrl.text = picked.toIso8601String().substring(0, 10));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final activeTerm = await ref.read(cpoActiveTermProvider.future);
      final meetingNo = int.tryParse(_noCtrl.text.trim()) ?? 1;

      final model = CpoMeetingModel(
        id: widget.existingMeeting?.id,
        meetingNo: meetingNo,
        meetingYear: _yearCtrl.text.trim(),
        meetingTitle: _titleCtrl.text.trim(),
        meetingDate: _dateCtrl.text.trim(),
        startTime: _startCtrl.text.trim(),
        endTime: _endCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        termId: activeTerm?.id,
        chairName: _chairCtrl.text.trim(),
        secretaryName: _secCtrl.text.trim(),
        status: _status,
        agendas: widget.existingMeeting?.agendas ?? const [],
        attendees: widget.existingMeeting?.attendees ?? const [],
      );

      if (widget.existingMeeting != null) {
        await ref.read(cpoMeetingsProvider.notifier).updateMeeting(model);
      } else {
        await ref.read(cpoMeetingsProvider.notifier).createMeetingWithStandardAgendas(
              model,
              termMembers: _populateMembers ? activeTerm?.members : null,
            );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingMeeting != null ? 'อัปเดตการประชุมสำเร็จ' : 'สร้างการประชุม คปอ. สำเร็จแล้ว'),
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
    final activeTermAsync = ref.watch(cpoActiveTermProvider);
    final activeTerm = activeTermAsync.asData?.value;

    // Auto-fill chair and secretary if empty
    if (_chairCtrl.text.isEmpty && activeTerm != null) {
      final chair = activeTerm.members.where((m) => m.cpoRole.name == 'chair').firstOrNull;
      if (chair != null) _chairCtrl.text = chair.fullName;
    }
    if (_secCtrl.text.isEmpty && activeTerm != null) {
      final sec = activeTerm.members.where((m) => m.cpoRole.name == 'secretary').firstOrNull;
      if (sec != null) _secCtrl.text = sec.fullName;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.indigo.shade100, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.calendar_month, color: Colors.indigo.shade800),
          ),
          const SizedBox(width: 12),
          Text(widget.existingMeeting != null ? 'แก้ไขการประชุม คปอ.' : 'จัดนัดหมายการประชุม คปอ. ใหม่'),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _noCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ครั้งที่ *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'ระบุครั้งที่' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _yearCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ปี พ.ศ. *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'ระบุปี' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อหัวข้อการประชุม *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'ระบุชื่อการประชุม' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _dateCtrl,
                        readOnly: true,
                        onTap: _selectDate,
                        decoration: const InputDecoration(
                          labelText: 'วันที่ประชุม *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _startCtrl,
                        decoration: const InputDecoration(
                          labelText: 'เริ่มเวลา',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _endCtrl,
                        decoration: const InputDecoration(
                          labelText: 'สิ้นสุด',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'สถานที่จัดการประชุม *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'ระบุสถานที่' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _chairCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ประธานในที่ประชุม *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.gavel),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'ระบุประธาน' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _secCtrl,
                        decoration: const InputDecoration(
                          labelText: 'เลขานุการ คปอ. (ผู้จดรายงาน) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.assignment_ind),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'ระบุเลขานุการ' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CpoMeetingStatus>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'สถานะการประชุม',
                    border: OutlineInputBorder(),
                  ),
                  items: CpoMeetingStatus.values.map((s) {
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
                    if (v != null) setState(() => _status = v);
                  },
                ),
                if (widget.existingMeeting == null) ...[
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _populateMembers,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('เติมรายชื่อผู้เข้าร่วมประชุมอัตโนมัติจากกรรมการ คปอ. ชุดปัจจุบัน', style: TextStyle(fontSize: 13)),
                    onChanged: (v) => setState(() => _populateMembers = v ?? true),
                  ),
                  CheckboxListTile(
                    value: _seedAgendas,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('สร้าง ๖ ระเบียบวาระมาตรฐานตามคู่มือ กสร. ๑/๒๕๖๑ อัตโนมัติ', style: TextStyle(fontSize: 13)),
                    onChanged: (v) => setState(() => _seedAgendas = v ?? true),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('บันทึกการประชุม', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
