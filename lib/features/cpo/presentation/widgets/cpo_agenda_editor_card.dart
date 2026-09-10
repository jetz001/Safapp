import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cpo_meeting_model.dart';
import '../providers/cpo_providers.dart';
import 'cpo_action_item_dialog.dart';

class _SubTopicItem {
  final TextEditingController titleCtrl;
  final TextEditingController discussionCtrl;
  final TextEditingController resolutionCtrl;
  final TextEditingController presenterCtrl;

  _SubTopicItem({
    String title = '',
    String discussion = '',
    String resolution = '',
    String presenter = '',
  })  : titleCtrl = TextEditingController(text: title),
        discussionCtrl = TextEditingController(text: discussion),
        resolutionCtrl = TextEditingController(text: resolution),
        presenterCtrl = TextEditingController(text: presenter);

  void dispose() {
    titleCtrl.dispose();
    discussionCtrl.dispose();
    resolutionCtrl.dispose();
    presenterCtrl.dispose();
  }

  Map<String, dynamic> toJson(String subNo) => {
        'sub_no': subNo,
        'title': titleCtrl.text.trim(),
        'discussion': discussionCtrl.text.trim(),
        'resolution': resolutionCtrl.text.trim(),
        'presenter': presenterCtrl.text.trim(),
      };
}

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
  final List<_SubTopicItem> _subItems = [];
  bool _isSaving = false;
  bool _isPulling = false;

  @override
  void initState() {
    super.initState();
    _initSubItems();
  }

  @override
  void didUpdateWidget(covariant CpoAgendaEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agenda != widget.agenda) {
      _disposeSubItems();
      _initSubItems();
    }
  }

  void _disposeSubItems() {
    for (final item in _subItems) {
      item.dispose();
    }
    _subItems.clear();
  }

  void _initSubItems() {
    final disc = widget.agenda.discussionContent ?? '';
    final match = RegExp(r'<!--SUB_ITEMS_JSON:(.*?)-->', dotAll: true).firstMatch(disc);

    if (match != null) {
      try {
        final jsonString = match.group(1)!;
        final List<dynamic> list = jsonDecode(jsonString);
        if (list.isNotEmpty) {
          for (final item in list) {
            final m = item as Map<String, dynamic>;
            _subItems.add(_SubTopicItem(
              title: m['title']?.toString() ?? '',
              discussion: m['discussion']?.toString() ?? '',
              resolution: m['resolution']?.toString() ?? '',
              presenter: m['presenter']?.toString() ?? '',
            ));
          }
          return;
        }
      } catch (_) {}
    }

    // Fallback / legacy format
    final cleanDisc = disc.replaceAll(RegExp(r'<!--SUB_ITEMS_JSON:[\s\S]*?-->'), '').trim();
    _subItems.add(_SubTopicItem(
      title: '',
      discussion: cleanDisc,
      resolution: widget.agenda.resolutionContent ?? '',
      presenter: widget.agenda.presenterName ?? '',
    ));
  }

  @override
  void dispose() {
    _disposeSubItems();
    super.dispose();
  }

  void _addSubTopic() {
    setState(() {
      _subItems.add(_SubTopicItem());
    });
  }

  Future<void> _confirmDeleteSubTopic(int index) async {
    final item = _subItems[index];
    final subNo = '${widget.agenda.agendaNo}.${index + 1}';
    final hasContent = item.titleCtrl.text.trim().isNotEmpty ||
        item.discussionCtrl.text.trim().isNotEmpty ||
        item.resolutionCtrl.text.trim().isNotEmpty;

    if (hasContent) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('ยืนยันลบเรื่องย่อย'),
            ],
          ),
          content: Text('คุณต้องการลบเรื่องย่อย $subNo ออกจากวาระนี้หรือไม่?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ยืนยันลบ'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() {
      final removed = _subItems.removeAt(index);
      removed.dispose();
      if (_subItems.isEmpty) {
        _subItems.add(_SubTopicItem());
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final List<Map<String, dynamic>> jsonList = [];
      final StringBuffer displayDisc = StringBuffer();
      final StringBuffer displayRes = StringBuffer();
      final List<String> presenters = [];

      final hasMultiple = _subItems.length > 1;

      for (int i = 0; i < _subItems.length; i++) {
        final item = _subItems[i];
        final subNo = '${widget.agenda.agendaNo}.${i + 1}';
        final title = item.titleCtrl.text.trim();
        final discussion = item.discussionCtrl.text.trim();
        final resolution = item.resolutionCtrl.text.trim();
        final presenter = item.presenterCtrl.text.trim();

        jsonList.add(item.toJson(subNo));

        if (presenter.isNotEmpty && !presenters.contains(presenter)) {
          presenters.add(presenter);
        }

        if (hasMultiple || title.isNotEmpty) {
          if (displayDisc.isNotEmpty) displayDisc.writeln('\n');
          displayDisc.writeln('$subNo ${title.isNotEmpty ? title : "เรื่องย่อยที่ ${i + 1}"}');
          if (discussion.isNotEmpty) displayDisc.writeln(discussion);
          if (presenter.isNotEmpty) displayDisc.writeln('(ผู้รายงาน: $presenter)');

          if (displayRes.isNotEmpty) displayRes.writeln();
          displayRes.write('$subNo: ${resolution.isNotEmpty ? resolution : "รับทราบ"}');
        } else {
          // Single item without sub-title
          displayDisc.write(discussion);
          displayRes.write(resolution);
        }
      }

      final metadata = '<!--SUB_ITEMS_JSON:${jsonEncode(jsonList)}-->';
      final savedDiscussion = displayDisc.isEmpty && jsonList.isEmpty
          ? null
          : '${displayDisc.toString().trim()}\n\n$metadata'.trim();

      final savedResolution = displayRes.isEmpty ? null : displayRes.toString().trim();
      final savedPresenter = presenters.isEmpty ? null : presenters.join(', ');

      final updated = widget.agenda.copyWith(
        discussionContent: savedDiscussion,
        resolutionContent: savedResolution,
        presenterName: savedPresenter,
      );

      await ref.read(cpoMeetingsProvider.notifier).updateAgenda(updated);
      widget.onAgendaUpdated?.call();

      if (mounted) {
        final countText = _subItems.length > 1 ? ' (${_subItems.length} เรื่องย่อย)' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกระเบียบวาระที่ ${widget.agenda.agendaNo} เรียบร้อยแล้ว$countText'),
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
        if (_subItems.length == 1 &&
            _subItems.first.discussionCtrl.text.isEmpty &&
            _subItems.first.titleCtrl.text.isEmpty) {
          _subItems.first.titleCtrl.text = 'ติดตามงานจากการประชุมครั้งก่อนหน้า';
          _subItems.first.discussionCtrl.text = text;
          _subItems.first.resolutionCtrl.text = 'รับทราบความคืบหน้า';
        } else {
          _subItems.add(_SubTopicItem(
            title: 'ติดตามงานจากการประชุมครั้งก่อนหน้า',
            discussion: text,
            resolution: 'รับทราบความคืบหน้า',
          ));
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
        if (_subItems.length == 1 &&
            _subItems.first.discussionCtrl.text.isEmpty &&
            _subItems.first.titleCtrl.text.isEmpty) {
          _subItems.first.titleCtrl.text = 'รายงานสถิติความปลอดภัยและอุบัติเหตุประจำเดือน';
          _subItems.first.discussionCtrl.text = summaryText;
          _subItems.first.resolutionCtrl.text = 'รับทราบรายงานสถิติ';
          _subItems.first.presenterCtrl.text = 'จป.วิชาชีพ';
        } else {
          _subItems.add(_SubTopicItem(
            title: 'รายงานสถิติความปลอดภัยและอุบัติเหตุประจำเดือน',
            discussion: summaryText,
            resolution: 'รับทราบรายงานสถิติ',
            presenter: 'จป.วิชาชีพ',
          ));
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
            // Top Agenda Header Row
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
            const SizedBox(height: 14),

            // Sub-topics List
            for (int i = 0; i < _subItems.length; i++) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: headerColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${ag.agendaNo}.${i + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: headerColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _subItems[i].titleCtrl,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              labelText: 'หัวข้อเรื่องย่อย (${ag.agendaNo}.${i + 1})',
                              hintText: 'ระบุหัวข้อเรื่อง เช่น ติดตามการซ่อมแซมจุดเสี่ยง, เสนอจัดซื้อ...',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        if (_subItems.length > 1) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, size: 20, color: Colors.red.shade400),
                            tooltip: 'ลบเรื่องย่อยนี้',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _confirmDeleteSubTopic(i),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _subItems[i].discussionCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'ข้อความหารือ / สรุปสาระสำคัญ (${ag.agendaNo}.${i + 1})',
                        hintText: 'บันทึกการรายงาน ความเห็นของกรรมการ หรือข้อเสนอแนะด้านความปลอดภัย',
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _subItems[i].resolutionCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'มติที่ประชุมเฉพาะเรื่องนี้',
                              hintText: 'เช่น รับทราบ, อนุมัติงบประมาณ ๕๐,๐๐๐ บาท',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _subItems[i].presenterCtrl,
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'ผู้เสนอ/ผู้รายงาน',
                              hintText: 'เช่น จป.วิชาชีพ / ตัวแทนฝ่ายผลิต',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline, size: 18),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 4),
            // Bottom Action Row: Add Sub-Topic and Save Agenda
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _addSubTopic,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    '+ เพิ่มเรื่องย่อย (เช่น ${ag.agendaNo}.${_subItems.length + 1})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: headerColor,
                    side: BorderSide(color: headerColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(
                    _subItems.length > 1
                        ? 'บันทึกวาระที่ ${ag.agendaNo} (${_subItems.length} เรื่องย่อย)'
                        : 'บันทึกวาระที่ ${ag.agendaNo}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
