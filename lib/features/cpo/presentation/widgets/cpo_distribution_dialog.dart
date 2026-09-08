import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cpo_distribution_model.dart';
import '../providers/cpo_providers.dart';

class CpoDistributionDialog extends ConsumerStatefulWidget {
  final int meetingId;
  final String meetingCode;

  const CpoDistributionDialog({
    super.key,
    required this.meetingId,
    required this.meetingCode,
  });

  @override
  ConsumerState<CpoDistributionDialog> createState() => _CpoDistributionDialogState();
}

class _CpoDistributionDialogState extends ConsumerState<CpoDistributionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateCtrl;
  late TextEditingController _groupCtrl;
  late TextEditingController _senderCtrl;
  late TextEditingController _notesCtrl;

  String _method = 'NOTICE_BOARD';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    _groupCtrl = TextEditingController(text: 'พนักงานทุกแผนก และคณะกรรมการ คปอ.');
    _senderCtrl = TextEditingController(text: 'เลขานุการ คปอ.');
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _groupCtrl.dispose();
    _senderCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final log = CpoDistributionModel(
        meetingId: widget.meetingId,
        distributionDate: _dateCtrl.text.trim(),
        distributionMethod: _method,
        recipientGroup: _groupCtrl.text.trim(),
        senderName: _senderCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      final repo = ref.read(cpoRepositoryProvider);
      await repo.addDistributionLog(log);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกการแจกจ่าย/แจ้งเวียนรายงานการประชุมเรียบร้อย'), backgroundColor: Colors.green),
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.teal.shade100, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.send_rounded, color: Colors.teal.shade800),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('บันทึกการแจกจ่าย/แจ้งเวียน ${widget.meetingCode}')),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'วันที่ดำเนินการแจกจ่าย/ปิดประกาศ *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุวันที่' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _method,
                decoration: const InputDecoration(
                  labelText: 'ช่องทางการเผยแพร่/แจกจ่าย *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'NOTICE_BOARD', child: Text('ปิดประกาศ ณ บอร์ดประชาสัมพันธ์ความปลอดภัย')),
                  DropdownMenuItem(value: 'EMAIL', child: Text('ส่งจดหมายอิเล็กทรอนิกส์ (Email แจ้งเวียน)')),
                  DropdownMenuItem(value: 'PRINT_COPY', child: Text('ส่งมอบเอกสารฉบับพิมพ์รายแผนก')),
                  DropdownMenuItem(value: 'SAFETY_TALK', child: Text('สื่อสารในการประชุม Safety Talk / Morning Talk')),
                  DropdownMenuItem(value: 'INTRANET', child: Text('อัปโหลดระบบเครือข่ายภายใน (Intranet / Share Drive)')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _method = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _groupCtrl,
                decoration: const InputDecoration(
                  labelText: 'กลุ่มผู้รับเอกสาร / กลุ่มเป้าหมาย *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุกลุ่มผู้รับ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _senderCtrl,
                decoration: const InputDecoration(
                  labelText: 'ผู้ดำเนินการเผยแพร่/ส่งมอบ *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุผู้ดำเนินการ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'หมายเหตุเพิ่มเติม (ถ้ามี)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('บันทึกการแจกจ่าย', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
