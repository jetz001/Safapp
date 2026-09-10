import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cpo_meeting_model.dart';
import '../providers/cpo_providers.dart';
import 'cpo_action_item_dialog.dart';

class CpoAgendaEditorCard extends ConsumerStatefulWidget {
  final CpoAgendaModel agenda;
  final int meetingId;
  final int? previousMeetingId;
  final VoidCallback? onAgendaUpdated;

  const CpoAgendaEditorCard({
    super.key,
    required this.agenda,
    required this.meetingId,
    this.previousMeetingId,
    this.onAgendaUpdated,
  });

  @override
  ConsumerState<CpoAgendaEditorCard> createState() => _CpoAgendaEditorCardState();
}

class _CpoAgendaEditorCardState extends ConsumerState<CpoAgendaEditorCard> {
  late TextEditingController _discussionCtrl;
  late TextEditingController _resolutionCtrl;
  late TextEditingController _presenterCtrl;
  bool _isSaving = false;
  bool _isPulling = false;

  @override
  void initState() {
    super.initState();
    _discussionCtrl = TextEditingController(text: widget.agenda.discussionContent ?? '');
    _resolutionCtrl = TextEditingController(text: widget.agenda.resolutionContent ?? '');
    _presenterCtrl = TextEditingController(text: widget.agenda.presenterName ?? '');
  }

  @override
  void didUpdateWidget(covariant CpoAgendaEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agenda != widget.agenda) {
      _discussionCtrl.text = widget.agenda.discussionContent ?? '';
      _resolutionCtrl.text = widget.agenda.resolutionContent ?? '';
      _presenterCtrl.text = widget.agenda.presenterName ?? '';
    }
  }

  @override
  void dispose() {
    _discussionCtrl.dispose();
    _resolutionCtrl.dispose();
    _presenterCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final updated = widget.agenda.copyWith(
        discussionContent: _discussionCtrl.text.trim(),
        resolutionContent: _resolutionCtrl.text.trim(),
        presenterName: _presenterCtrl.text.trim().isEmpty ? null : _presenterCtrl.text.trim(),
      );

      await ref.read(cpoMeetingsProvider.notifier).updateAgenda(updated);
      widget.onAgendaUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกระเบียบวาระที่ ${widget.agenda.agendaNo} เรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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

  Future<void> _pullPreviousPendingItems() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isPulling = true);
    try {
      final repo = ref.read(cpoRepositoryProvider);
      final text = await repo.getRolledForwardAgenda3Content(widget.previousMeetingId);
      setState(() {
        if (_discussionCtrl.text.isNotEmpty && !_discussionCtrl.text.contains('ติดตามความคืบหน้า')) {
          _discussionCtrl.text = '${_discussionCtrl.text}\n\n$text';
        } else {
          _discussionCtrl.text = text;
        }
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('ดึงเรื่องสืบเนื่องจากรอบก่อนหน้าสำเร็จ'), backgroundColor: Colors.teal),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('ดึงข้อมูลไม่สำเร็จ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isPulling = false);
    }
  }

  Future<void> _pullMonthlySafetyStats() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isPulling = true);
    try {
      final repo = ref.read(cpoRepositoryProvider);
      final stats = await repo.fetchMonthlySafetyStats(DateTime.now().toIso8601String());
      final summaryText = stats['summary_text'] as String? ?? '';
      setState(() {
        if (_discussionCtrl.text.isNotEmpty) {
          _discussionCtrl.text = '${_discussionCtrl.text}\n\n$summaryText';
        } else {
          _discussionCtrl.text = summaryText;
        }
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('ดึงสถิติความปลอดภัยประจำเดือนสำเร็จ'), backgroundColor: Colors.indigo),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('ดึงสถิติไม่สำเร็จ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isPulling = false);
    }
  }

  void _openAddActionItemDialog() {
    showDialog(
      context: context,
      builder: (ctx) => CpoActionItemDialog(
        meetingId: widget.meetingId,
        agendaNo: widget.agenda.agendaNo,
      ),
    );
  }

  Future<void> _editAgendaTitle() async {
    final titleCtrl = TextEditingController(text: widget.agenda.agendaTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('แก้ไขชื่อวาระที่ ${widget.agenda.agendaNo}'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            labelText: 'ชื่อหัวข้อวาระ *',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, titleCtrl.text.trim()),
            child: const Text('บันทึกชื่อวาระ'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != widget.agenda.agendaTitle) {
      final updated = widget.agenda.copyWith(agendaTitle: newTitle);
      await ref.read(cpoMeetingsProvider.notifier).updateAgenda(updated);
      widget.onAgendaUpdated?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('แก้ไขชื่อหัวข้อวาระสำเร็จ'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _confirmDeleteAgenda() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันลบวาระการประชุม'),
          ],
        ),
        content: Text(
          'คุณต้องการลบ "วาระที่ ${widget.agenda.agendaNo} ${widget.agenda.agendaTitle}" '
          'ออกจากการประชุมนี้หรือไม่?\n\n'
          '⚠️ สาระสำคัญและมติที่ประชุมในวาระนี้จะถูกลบออก',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ยืนยันลบวาระ'),
          ),
        ],
      ),
    );

    if (confirm == true && widget.agenda.id != null) {
      await ref.read(cpoMeetingsProvider.notifier).deleteAgenda(widget.agenda.id!);
      widget.onAgendaUpdated?.call();
      messenger.showSnackBar(
        SnackBar(
          content: Text('ลบวาระที่ ${widget.agenda.agendaNo} เรียบร้อยแล้ว'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ag = widget.agenda;

    Color headerColor;
    switch (ag.agendaNo) {
      case 1:
        headerColor = Colors.blue.shade800;
        break;
      case 2:
        headerColor = Colors.indigo.shade800;
        break;
      case 3:
        headerColor = Colors.teal.shade800;
        break;
      case 4:
        headerColor = Colors.amber.shade900;
        break;
      case 5:
        headerColor = Colors.green.shade800;
        break;
      case 6:
      default:
        headerColor = Colors.purple.shade800;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: headerColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: headerColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'วาระที่ ${ag.agendaNo}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: headerColor, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _editAgendaTitle,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              ag.agendaTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.edit_outlined, size: 15, color: Colors.grey.shade500),
                        ],
                      ),
                    ),
                  ),
                ),
                // Helper buttons based on agenda type
                if (ag.agendaNo == 3)
                  ElevatedButton.icon(
                    onPressed: _isPulling ? null : _pullPreviousPendingItems,
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('ดึงเรื่องสืบเนื่อง', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade50,
                      foregroundColor: Colors.teal.shade800,
                      elevation: 0,
                    ),
                  ),
                if (ag.agendaNo == 4)
                  ElevatedButton.icon(
                    onPressed: _isPulling ? null : _pullMonthlySafetyStats,
                    icon: const Icon(Icons.query_stats, size: 16),
                    label: const Text('ดึงสถิติ SAFAPP', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade50,
                      foregroundColor: Colors.indigo.shade800,
                      elevation: 0,
                    ),
                  ),
                if (ag.agendaNo == 5)
                  ElevatedButton.icon(
                    onPressed: _openAddActionItemDialog,
                    icon: const Icon(Icons.add_task, size: 16),
                    label: const Text('มอบหมาย Action Item', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green.shade800,
                      elevation: 0,
                    ),
                  ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                  tooltip: 'ลบวาระที่ ${ag.agendaNo}',
                  visualDensity: VisualDensity.compact,
                  onPressed: _confirmDeleteAgenda,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _discussionCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'ข้อความหารือ / สรุปสาระสำคัญในที่ประชุม',
                hintText: 'บันทึกการรายงาน ความเห็นของกรรมการ หรือข้อเสนอแนะด้านความปลอดภัย',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _resolutionCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'มติที่ประชุม (Resolution)',
                      hintText: 'เช่น รับทราบ, รับรองรายงาน, หรือมีมติอนุมัติงบประมาณและมอบหมายงาน',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.check_circle_outline, color: Colors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _presenterCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ผู้เสนอ/ผู้รายงาน (ถ้ามี)',
                      hintText: 'เช่น จป.วิชาชีพ / ตัวแทนฝ่ายผลิต',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save, size: 18),
                    label: const Text('บันทึกวาระ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
