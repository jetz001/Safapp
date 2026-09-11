import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/cpo_meeting_model.dart';
import '../providers/cpo_providers.dart';
import 'cpo_action_item_dialog.dart';

class _SubTopicItem {
  final TextEditingController titleCtrl;
  final TextEditingController discussionCtrl;
  final TextEditingController resolutionCtrl;
  final TextEditingController presenterCtrl;
  List<String> images;

  _SubTopicItem({
    String title = '',
    String discussion = '',
    String resolution = '',
    String presenter = '',
    List<String>? images,
  })  : titleCtrl = TextEditingController(text: title),
        discussionCtrl = TextEditingController(text: discussion),
        resolutionCtrl = TextEditingController(text: resolution),
        presenterCtrl = TextEditingController(text: presenter),
        images = images != null ? List<String>.from(images) : [];

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
        'images': images,
      };
}

class CpoAgendaEditorCard extends ConsumerStatefulWidget {
  final CpoAgendaModel agenda;
  final int meetingId;
  final int? previousMeetingId;
  final VoidCallback? onAgendaUpdated;
  final bool? isExpanded;
  final VoidCallback? onToggleExpand;

  const CpoAgendaEditorCard({
    super.key,
    required this.agenda,
    required this.meetingId,
    this.previousMeetingId,
    this.onAgendaUpdated,
    this.isExpanded,
    this.onToggleExpand,
  });

  @override
  ConsumerState<CpoAgendaEditorCard> createState() => _CpoAgendaEditorCardState();
}

class _CpoAgendaEditorCardState extends ConsumerState<CpoAgendaEditorCard> {
  final List<_SubTopicItem> _subItems = [];
  bool _isSaving = false;
  bool _isPulling = false;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded ?? true;
    _initSubItems();
  }

  @override
  void didUpdateWidget(covariant CpoAgendaEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != null && widget.isExpanded != oldWidget.isExpanded) {
      _isExpanded = widget.isExpanded!;
    }
    if (oldWidget.agenda != widget.agenda) {
      _disposeSubItems();
      _initSubItems();
    }
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onToggleExpand?.call();
  }

  String _buildCollapsedSummary() {
    if (_subItems.isEmpty) return 'ยังไม่มีรายละเอียดเรื่องย่อย';
    final titles = _subItems
        .map((s) => s.titleCtrl.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (titles.isNotEmpty) {
      return titles.join('  •  ');
    }
    final firstDisc = _subItems.first.discussionCtrl.text.trim();
    if (firstDisc.isNotEmpty) {
      return firstDisc.replaceAll('\n', ' ');
    }
    return '${_subItems.length} เรื่องย่อย (ยังไม่ได้ระบุหัวข้อ)';
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
            final rawImages = m['images'];
            final List<String> imgs = [];
            if (rawImages is List) {
              for (final img in rawImages) {
                if (img != null && img.toString().isNotEmpty) {
                  imgs.add(img.toString());
                }
              }
            }
            _subItems.add(_SubTopicItem(
              title: m['title']?.toString() ?? '',
              discussion: m['discussion']?.toString() ?? '',
              resolution: m['resolution']?.toString() ?? '',
              presenter: m['presenter']?.toString() ?? '',
              images: imgs,
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

  Future<void> _pickImagesForSubTopic(int index) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) return;

      final appDocDir = await getApplicationDocumentsDirectory();
      final targetFolder = Directory('${appDocDir.path}/SafetySuperapp/cpo_attachments');
      if (!await targetFolder.exists()) {
        await targetFolder.create(recursive: true);
      }

      final newPaths = <String>[];
      for (final file in result.files) {
        if (file.path != null && file.path!.isNotEmpty) {
          final original = File(file.path!);
          if (await original.exists()) {
            final ext = p.extension(file.path!).toLowerCase();
            final safeExt = ext.isNotEmpty ? ext : '.jpg';
            final fileName = 'cpo_${widget.meetingId}_ag${widget.agenda.agendaNo}_sub${index + 1}_${DateTime.now().millisecondsSinceEpoch}_${newPaths.length}$safeExt';
            final targetPath = '${targetFolder.path}/$fileName';
            await original.copy(targetPath);
            newPaths.add(targetPath);
          }
        }
      }

      if (newPaths.isNotEmpty && mounted) {
        setState(() {
          _subItems[index].images.addAll(newPaths);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการแนบรูปภาพ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeImage(int subTopicIndex, int imageIndex) {
    setState(() {
      _subItems[subTopicIndex].images.removeAt(imageIndex);
    });
  }

  void _showImagePreviewDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              clipBehavior: Clip.none,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      color: Colors.white,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('ไม่พบไฟล์รูปภาพ', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton.filled(
                icon: const Icon(Icons.close, size: 20),
                style: IconButton.styleFrom(backgroundColor: Colors.black54, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnailCard(int subTopicIndex, int imageIndex, Color headerColor) {
    final imagePath = _subItems[subTopicIndex].images[imageIndex];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: () => _showImagePreviewDialog(imagePath),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.grey.shade100,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, size: 28, color: Colors.grey),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      'รูปที่ ${imageIndex + 1}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: InkWell(
            onTap: () => _removeImage(subTopicIndex, imageIndex),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
                ],
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
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

      // Auto-sync action items for Agenda 4 and 5
      int autoActionCount = 0;
      if (widget.agenda.agendaNo == 4 || widget.agenda.agendaNo == 5) {
        autoActionCount = await ref.read(cpoActionItemsProvider.notifier).autoSyncFromAgendas(meetingId: widget.meetingId);
      }

      if (mounted) {
        final countText = _subItems.length > 1 ? ' (${_subItems.length} เรื่องย่อย)' : '';
        final actionText = autoActionCount > 0 ? ' (ซิงค์ Action Items อัตโนมัติ $autoActionCount รายการ)' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกระเบียบวาระที่ ${widget.agenda.agendaNo} เรียบร้อยแล้ว$countText$actionText'),
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

  Widget _buildQuickChip(int index, String text) {
    return InkWell(
      onTap: () {
        setState(() {
          _subItems[index].resolutionCtrl.text = text;
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Text(
          '+ $text',
          style: TextStyle(
            fontSize: 11,
            color: Colors.green.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Agenda Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: headerColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: headerColor.withValues(alpha: 0.25)),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: Color(0xFF0F172A)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.edit_outlined, size: 15, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                ),
                // Helper buttons based on agenda type
                if (ag.agendaNo == 3)
                  ElevatedButton.icon(
                    onPressed: _isPulling ? null : _pullPreviousPendingItems,
                    icon: const Icon(Icons.sync, size: 15),
                    label: const Text('ดึงเรื่องสืบเนื่อง', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade50,
                      foregroundColor: Colors.teal.shade800,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: Colors.teal.shade200),
                      ),
                    ),
                  ),
                if (ag.agendaNo == 4) ...[
                  ElevatedButton.icon(
                    onPressed: _isPulling ? null : _pullMonthlySafetyStats,
                    icon: const Icon(Icons.query_stats, size: 15),
                    label: const Text('ดึงสถิติ SAFAPP', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade50,
                      foregroundColor: Colors.indigo.shade800,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: Colors.indigo.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                if (ag.agendaNo == 4 || ag.agendaNo == 5)
                  ElevatedButton.icon(
                    onPressed: _openAddActionItemDialog,
                    icon: const Icon(Icons.add_task, size: 15),
                    label: const Text('มอบหมาย Action Item', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ag.agendaNo == 4 ? Colors.amber.shade50 : Colors.green.shade50,
                      foregroundColor: ag.agendaNo == 4 ? Colors.amber.shade900 : Colors.green.shade800,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: ag.agendaNo == 4 ? Colors.amber.shade200 : Colors.green.shade200),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                  tooltip: 'ลบวาระที่ ${ag.agendaNo}',
                  visualDensity: VisualDensity.compact,
                  onPressed: _confirmDeleteAgenda,
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: const Color(0xFF475569),
                  ),
                  tooltip: _isExpanded ? 'ย่อวาระ' : 'ขยายวาระ',
                  visualDensity: VisualDensity.compact,
                  onPressed: _toggleExpand,
                ),
              ],
            ),

            if (!_isExpanded) ...[
              InkWell(
                onTap: _toggleExpand,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notes_rounded, size: 16, color: headerColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _buildCollapsedSummary(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: headerColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_subItems.length} เรื่องย่อย',
                          style: TextStyle(fontSize: 11, color: headerColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.unfold_more_rounded, size: 18, color: headerColor),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 14),

            // Sub-topics List
            for (int i = 0; i < _subItems.length; i++) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub-topic Header & Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: headerColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: headerColor.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            '${ag.agendaNo}.${i + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: headerColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _subItems[i].titleCtrl,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF1E293B)),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              hintText: 'หัวข้อเรื่องย่อย เช่น ติดตามการซ่อมแซมจุดเสี่ยง, เสนอจัดซื้ออุปกรณ์...',
                              hintStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: headerColor, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        if (_subItems.length > 1) ...[
                          const SizedBox(width: 6),
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, size: 20, color: Colors.red.shade400),
                            tooltip: 'ลบเรื่องย่อยนี้',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _confirmDeleteSubTopic(i),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Discussion / Content Section
                    Row(
                      children: [
                        Icon(Icons.notes_rounded, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'ข้อความหารือ / สรุปสาระสำคัญ',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _subItems[i].discussionCtrl,
                      minLines: 2,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 13.5, height: 1.4, color: Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'บันทึกการรายงาน ความเห็นของกรรมการ หรือข้อเสนอแนะด้านความปลอดภัย...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: headerColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Image Attachments Section
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.photo_library_outlined, size: 15, color: headerColor),
                              const SizedBox(width: 6),
                              Text(
                                'รูปภาพประกอบ (${_subItems[i].images.length} รูป)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                              ),
                              const Spacer(),
                              OutlinedButton.icon(
                                onPressed: () => _pickImagesForSubTopic(i),
                                icon: const Icon(Icons.add_photo_alternate_outlined, size: 15),
                                label: const Text('แนบรูปภาพ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: headerColor,
                                  side: BorderSide(color: headerColor.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                          if (_subItems[i].images.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (int imgIdx = 0; imgIdx < _subItems[i].images.length; imgIdx++)
                                  _buildImageThumbnailCard(i, imgIdx, headerColor),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _pickImagesForSubTopic(i),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined, size: 16, color: Colors.grey.shade400),
                                    const SizedBox(width: 6),
                                    Text(
                                      'คลิกเพื่อแนบรูปภาพประกอบ (เช่น ภาพการตรวจสภาพแวดล้อม, จุดเสี่ยง, หรือกิจกรรม)',
                                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Resolution & Presenter Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Resolution
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.green.shade700),
                                  const SizedBox(width: 6),
                                  Text(
                                    'มติที่ประชุม',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                  ),
                                  const Spacer(),
                                  _buildQuickChip(i, 'รับทราบ'),
                                  const SizedBox(width: 4),
                                  _buildQuickChip(i, 'เห็นชอบ'),
                                  const SizedBox(width: 4),
                                  _buildQuickChip(i, 'อนุมัติ'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _subItems[i].resolutionCtrl,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: 'เช่น รับทราบ, อนุมัติงบประมาณ ๕๐,๐๐๐ บาท...',
                                  hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.green.shade600, width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Presenter
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ผู้เสนอ / ผู้รายงาน',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _subItems[i].presenterCtrl,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: 'เช่น จป.วิชาชีพ / ตัวแทนฝ่ายผลิต',
                                  hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: headerColor, width: 1.5),
                                  ),
                                ),
                              ),
                            ],
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
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'เพิ่มเรื่องย่อย (${ag.agendaNo}.${_subItems.length + 1})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: headerColor,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: headerColor.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    _subItems.length > 1
                        ? 'บันทึกวาระที่ ${ag.agendaNo} (${_subItems.length} เรื่องย่อย)'
                        : 'บันทึกวาระที่ ${ag.agendaNo}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }
}
