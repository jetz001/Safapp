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

  Future<void> _selectTime(TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final initialTime = parts.length == 2
        ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts[1]) ?? 0)
        : const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      setState(() => ctrl.text = '$h:$m');
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
        status: widget.existingMeeting?.status ?? CpoMeetingStatus.draft,
        agendas: widget.existingMeeting?.agendas ?? const [],
        attendees: widget.existingMeeting?.attendees ?? const [],
      );

      if (widget.existingMeeting != null) {
        await ref.read(cpoMeetingsProvider.notifier).updateMeeting(model);
      } else {
        await ref.read(cpoMeetingsProvider.notifier).createMeetingWithStandardAgendas(
              model,
              termMembers: _populateMembers ? activeTerm?.members : null,
              seedAgendas: _seedAgendas,
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

  Future<void> _confirmDelete() async {
    final m = widget.existingMeeting;
    if (m == null || m.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันลบการประชุม'),
          ],
        ),
        content: Text(
          'คุณต้องการลบการประชุมครั้งที่ ${m.meetingNo}/${m.meetingYear} ("${m.meetingTitle}") ออกจากระบบหรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ยืนยันลบ'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(cpoMeetingsProvider.notifier).deleteMeeting(m.id!);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบการประชุมเรียบร้อยแล้ว'), backgroundColor: Colors.red),
        );
      }
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

    final isEdit = widget.existingMeeting != null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header Banner with Navy Gradient
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_calendar_rounded : Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'แก้ไขข้อมูลการประชุม คปอ.' : 'จัดนัดหมายการประชุม คปอ. ใหม่',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEdit
                              ? 'ปรับปรุงข้อมูลกำหนดการ สถานที่ และรายชื่อผู้รับผิดชอบ'
                              : 'กำหนดวัน เวลา สถานที่ และเตรียมความพร้อมการประชุม',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    tooltip: 'ปิด',
                    splashRadius: 18,
                  ),
                ],
              ),
            ),

            // 2. Scrollable Body with Clean Grouped Cards
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card 1: กำหนดการและวาระการประชุม
                      _buildSectionCard(
                        title: 'กำหนดการและหัวข้อการประชุม',
                        icon: Icons.calendar_today_rounded,
                        iconColor: const Color(0xFF1E3A8A),
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 110,
                                child: _buildTextField(
                                  controller: _noCtrl,
                                  label: 'ครั้งที่ *',
                                  hint: 'เช่น 1',
                                  keyboardType: TextInputType.number,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'ระบุครั้งที่' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 110,
                                child: _buildTextField(
                                  controller: _yearCtrl,
                                  label: 'ปี พ.ศ. *',
                                  hint: 'เช่น 2569',
                                  validator: (v) => v == null || v.trim().isEmpty ? 'ระบุปี' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTextField(
                                  controller: _titleCtrl,
                                  label: 'ชื่อหัวข้อการประชุม *',
                                  hint: 'เช่น การประชุม คปอ. ประจำเดือน',
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
                                child: _buildTextField(
                                  controller: _dateCtrl,
                                  label: 'วันที่จัดการประชุม *',
                                  readOnly: true,
                                  onTap: _selectDate,
                                  prefixIcon: Icons.event_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: _buildTextField(
                                  controller: _startCtrl,
                                  label: 'เวลาเริ่ม',
                                  readOnly: true,
                                  onTap: () => _selectTime(_startCtrl),
                                  prefixIcon: Icons.schedule_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: _buildTextField(
                                  controller: _endCtrl,
                                  label: 'สิ้นสุด',
                                  readOnly: true,
                                  onTap: () => _selectTime(_endCtrl),
                                  prefixIcon: Icons.schedule_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Card 2: สถานที่และผู้รับผิดชอบ
                      _buildSectionCard(
                        title: 'สถานที่และผู้รับผิดชอบการประชุม',
                        icon: Icons.location_on_outlined,
                        iconColor: const Color(0xFF1E3A8A),
                        children: [
                          _buildTextField(
                            controller: _locationCtrl,
                            label: 'สถานที่จัดการประชุม *',
                            hint: 'เช่น ห้องประชุมใหญ่ ชั้น ๒ อาคารสำนักงาน',
                            prefixIcon: Icons.apartment_rounded,
                            validator: (v) => v == null || v.trim().isEmpty ? 'ระบุสถานที่' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _chairCtrl,
                                  label: 'ประธานในที่ประชุม *',
                                  hint: 'ชื่อ-นามสกุล ประธาน คปอ.',
                                  prefixIcon: Icons.gavel_rounded,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'ระบุชื่อประธาน' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTextField(
                                  controller: _secCtrl,
                                  label: 'เลขานุการ คปอ. (ผู้จดรายงาน) *',
                                  hint: 'ชื่อ-นามสกุล เลขานุการ',
                                  prefixIcon: Icons.edit_note_rounded,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'ระบุชื่อเลขานุการ' : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Card 3: การเตรียมข้อมูลอัตโนมัติ (เฉพาะกรณีสร้างใหม่)
                      if (!isEdit)
                        _buildSectionCard(
                          title: 'การจัดเตรียมข้อมูลอัตโนมัติ',
                          icon: Icons.auto_awesome_rounded,
                          iconColor: const Color(0xFF059669),
                          backgroundColor: const Color(0xFFF0FDF4),
                          borderColor: const Color(0xFFBBF7D0),
                          children: [
                            _buildCheckboxTile(
                              value: _seedAgendas,
                              title: 'จัดเตรียม ๖ ระเบียบวาระมาตรฐาน คปอ. อัตโนมัติ',
                              subtitle: 'สร้างวาระที่ ๑ ถึง ๖ พร้อมหัวข้อและเนื้อหาเริ่มต้นตามมาตรฐานสากล',
                              onChanged: (v) => setState(() => _seedAgendas = v ?? true),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Divider(height: 1, color: Color(0xFFDCFCE7)),
                            ),
                            _buildCheckboxTile(
                              value: _populateMembers,
                              title: 'เติมรายชื่อผู้เข้าร่วมประชุมจากกรรมการ คปอ. ชุดปัจจุบัน',
                              subtitle: 'ดึงรายชื่อคณะกรรมการทั้งหมดเข้าสู่ตารางเช็คชื่อผู้เข้าร่วมประชุมทันที',
                              onChanged: (v) => setState(() => _populateMembers = v ?? true),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Footer Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: isEdit ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
                children: [
                  if (isEdit)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('ลบการประชุมนี้', style: TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: _confirmDelete,
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        ),
                        child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: Text(
                          _isSaving ? 'กำลังบันทึก...' : (isEdit ? 'บันทึกการแก้ไข' : 'บันทึกนัดหมายการประชุม'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                          elevation: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
    Color backgroundColor = const Color(0xFFF8FAFC),
    Color borderColor = const Color(0xFFE2E8F0),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: iconColor == const Color(0xFF059669) ? const Color(0xFF065F46) : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B)) : null,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required bool value,
    required String title,
    required String subtitle,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


