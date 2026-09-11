import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cpo_action_item_model.dart';
import '../../data/models/cpo_distribution_model.dart';
import '../../domain/enums/cpo_action_status.dart';
import '../providers/cpo_providers.dart';
import '../widgets/cpo_action_item_dialog.dart';
import '../widgets/cpo_distribution_dialog.dart';

class CpoActionTrackerTab extends ConsumerStatefulWidget {
  const CpoActionTrackerTab({super.key});

  @override
  ConsumerState<CpoActionTrackerTab> createState() => _CpoActionTrackerTabState();
}

class _CpoActionTrackerTabState extends ConsumerState<CpoActionTrackerTab> with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  String _searchQuery = '';
  CpoActionStatus? _statusFilter;
  bool _showOverdueOnly = false;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionsAsync = ref.watch(cpoActionItemsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _subTabController,
            labelColor: const Color(0xFF0D9488),
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: const Color(0xFF0D9488),
            tabs: const [
              Tab(icon: Icon(Icons.playlist_add_check, size: 18), text: 'รายการติดตามมติที่ประชุม (Action Items / CAPA)'),
              Tab(icon: Icon(Icons.forward_to_inbox, size: 18), text: 'ประวัติการแจกจ่ายรายงานการประชุม (Distribution Logs)'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _subTabController,
        children: [
          // Sub-tab 1: Action Items
          actionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('เกิดข้อผิดพลาด: $err')),
            data: (actions) {
              final filtered = actions.where((a) {
                final matchQuery = a.taskTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (a.assigneeName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                    (a.department?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                final matchStatus = _statusFilter == null || a.status == _statusFilter;
                final matchOverdue = !_showOverdueOnly || a.isOverdue;
                return matchQuery && matchStatus && matchOverdue;
              }).toList();

              return Column(
                children: [
                  _buildActionBar(context, actions),
                  Expanded(
                    child: filtered.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              return _buildActionItemCard(context, filtered[index]);
                            },
                          ),
                  ),
                ],
              );
            },
          ),

          // Sub-tab 2: Distribution Logs
          _buildDistributionLogsView(context),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, List<CpoActionItemModel> allActions) {
    final overdueCount = allActions.where((a) => a.isOverdue).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'ค้นหางาน (ชื่องาน, ผู้รับผิดชอบ, แผนก)',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<CpoActionStatus?>(
                value: _statusFilter,
                hint: const Text('ทุกสถานะ'),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('ทุกสถานะ')),
                  ...CpoActionStatus.values.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s.thaiLabel)),
                  ),
                ],
                onChanged: (val) => setState(() => _statusFilter = val),
              ),
              const SizedBox(width: 12),
              FilterChip(
                selected: _showOverdueOnly,
                avatar: Icon(Icons.warning, size: 14, color: _showOverdueOnly ? Colors.white : Colors.red),
                label: Text('เกินกำหนด ($overdueCount)'),
                selectedColor: Colors.red,
                labelStyle: TextStyle(
                  color: _showOverdueOnly ? Colors.white : Colors.red.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (val) => setState(() => _showOverdueOnly = val),
              ),
              const SizedBox(width: 16),
              // Button: Auto-Sync from Agendas 4-5
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('ดึงมติจากวาระ ๔-๕ อัตโนมัติ'),
                onPressed: () => _handleAutoSync(context),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('เพิ่ม Action Item'),
                onPressed: () => _openCreateActionDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAutoSync(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('กำลังดึงมติและงานจากวาระที่ ๔ และ ๕...'), duration: Duration(seconds: 1)),
    );
    try {
      final count = await ref.read(cpoActionItemsProvider.notifier).autoSyncFromAgendas();
      if (!mounted) return;
      if (count > 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('⚡ ดึงงานและมติจากวาระที่ ๔-๕ สำเร็จ $count รายการ'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('ไม่พบงานหรือมติใหม่ในวาระที่ ๔-๕ (หรือมีอยู่ในระบบครบแล้ว)'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('ไม่มีรายการติดตามมติที่ประชุม', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          Text(
            'สามารถกดดึงมติและงานจากวาระที่ ๔ และ ๕ มาสร้างเป็น Action Item ได้อัตโนมัติ',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('⚡ ดึงมติจากวาระที่ ๔-๕ อัตโนมัติ', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _handleAutoSync(context),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('เพิ่ม Action Item ใหม่'),
                onPressed: () => _openCreateActionDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItemCard(BuildContext context, CpoActionItemModel item) {
    final status = item.status;
    Color statusColor;
    switch (status) {
      case CpoActionStatus.pending:
        statusColor = Colors.orange;
        break;
      case CpoActionStatus.inProgress:
        statusColor = Colors.blue;
        break;
      case CpoActionStatus.completed:
        statusColor = Colors.green;
        break;
      case CpoActionStatus.overdue:
        statusColor = Colors.red;
        break;
      case CpoActionStatus.cancelled:
        statusColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: item.isOverdue ? Colors.red.shade300 : Colors.grey.shade200,
          width: item.isOverdue ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.isOverdue) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                              child: const Text('เกินกำหนด', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              item.taskTitle,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.thaiLabel,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 16,
                        children: [
                          _buildInfoRow(Icons.person_outline, 'ผู้รับผิดชอบ: ${item.assigneeName ?? "-"}'),
                          _buildInfoRow(Icons.business_outlined, 'แผนก: ${item.department ?? "-"}'),
                          _buildInfoRow(Icons.event_outlined, 'กำหนดเสร็จ: ${item.dueDate}'),
                          if (item.completedDate != null)
                            _buildInfoRow(Icons.check_circle_outline, 'แล้วเสร็จ: ${item.completedDate}'),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'แก้ไขรายละเอียด',
                  onPressed: () => _openEditActionDialog(context, item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  tooltip: 'ลบรายการ',
                  onPressed: () => _deleteActionItem(item),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Bar & Slider Quick Update
            Row(
              children: [
                Text('ความคืบหน้า: ${item.progressPercentage}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: item.progressPercentage / 100.0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        item.progressPercentage >= 100 ? Colors.green : const Color(0xFF0D9488),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  icon: const Icon(Icons.update, size: 14),
                  label: const Text('อัปเดตสถานะ', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showQuickStatusDialog(context, item),
                ),
              ],
            ),
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                child: Text('หมายเหตุ: ${item.notes}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildDistributionLogsView(BuildContext context) {
    final logsAsync = ref.watch(cpoDistributionLogsProvider);
    final meetingsAsync = ref.watch(cpoMeetingsProvider);
    final meetings = meetingsAsync.asData?.value ?? [];

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forward_to_inbox_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('ยังไม่มีบันทึกการแจกจ่ายรายงานการประชุม',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                Text('สามารถบันทึกการแจกจ่ายรายงานได้จากแท็บ "การประชุม คปอ."',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final log = logs[index];
            final meeting = meetings.where((m) => m.id == log.meetingId).firstOrNull;
            final meetingTitle = meeting != null ? meeting.meetingCode : 'การประชุมรหัส #${log.meetingId}';

            return Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  foregroundColor: const Color(0xFF0D9488),
                  child: const Icon(Icons.send, size: 18),
                ),
                title: Row(
                  children: [
                    Text(meetingTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (meeting != null && meeting.meetingTitle.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text('(${meeting.meetingTitle})',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, fontWeight: FontWeight.normal)),
                    ],
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                      child: Text(log.methodLabel,
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'แจกจ่ายเมื่อ: ${log.distributionDate} | ผู้รับ/กลุ่มเป้าหมาย: ${log.recipientGroup} | บันทึกโดย: ${log.senderName}\nหมายเหตุ: ${log.notes ?? "-"}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 19, color: Color(0xFF1E3A8A)),
                      tooltip: 'แก้ไขบันทึก',
                      splashRadius: 18,
                      onPressed: () => _editDistributionLog(context, log, meetingTitle),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, size: 19, color: Colors.red.shade700),
                      tooltip: 'ลบบันทึก',
                      splashRadius: 18,
                      onPressed: () => _deleteDistributionLog(log),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openCreateActionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const CpoActionItemDialog(),
    );
  }

  void _openEditActionDialog(BuildContext context, CpoActionItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => CpoActionItemDialog(existingItem: item),
    );
  }

  void _showQuickStatusDialog(BuildContext context, CpoActionItemModel item) {
    CpoActionStatus selectedStatus = item.status;
    double progress = item.progressPercentage.toDouble();
    final notesCtrl = TextEditingController(text: item.notes);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('อัปเดตสถานะ: ${item.taskTitle}'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<CpoActionStatus>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(labelText: 'สถานะการดำเนินงาน', border: OutlineInputBorder()),
                  items: CpoActionStatus.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.thaiLabel)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDlgState(() {
                        selectedStatus = val;
                        if (val == CpoActionStatus.completed) progress = 100;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text('ความคืบหน้า: ${progress.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Slider(
                  value: progress,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  activeColor: const Color(0xFF0D9488),
                  label: '${progress.toInt()}%',
                  onChanged: (val) {
                    setDlgState(() {
                      progress = val;
                      if (val == 100) selectedStatus = CpoActionStatus.completed;
                      if (val > 0 && val < 100 && selectedStatus == CpoActionStatus.pending) {
                        selectedStatus = CpoActionStatus.inProgress;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'บันทึกความคืบหน้า / ผลการดำเนินการ', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
              onPressed: () async {
                String? completedDt;
                if (selectedStatus == CpoActionStatus.completed) {
                  completedDt = DateTime.now().toIso8601String().substring(0, 10);
                }
                await ref.read(cpoActionItemsProvider.notifier).updateStatus(
                      item.id!,
                      selectedStatus.name,
                      progress: progress.toInt(),
                      notes: notesCtrl.text.trim(),
                      completedDate: completedDt,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteActionItem(CpoActionItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ Action Item'),
        content: Text('ต้องการลบรายการ "${item.taskTitle}" หรือไม่?'),
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

    if (confirm == true && item.id != null) {
      await ref.read(cpoActionItemsProvider.notifier).deleteItem(item.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบ Action Item เรียบร้อยแล้ว')));
      }
    }
  }

  void _editDistributionLog(BuildContext context, CpoDistributionModel log, String meetingCode) {
    showDialog(
      context: context,
      builder: (ctx) => CpoDistributionDialog(
        meetingId: log.meetingId,
        meetingCode: meetingCode,
        existingLog: log,
      ),
    );
  }

  Future<void> _deleteDistributionLog(CpoDistributionModel log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันลบบันทึกการแจกจ่าย'),
          ],
        ),
        content: Text('คุณต้องการลบบันทึกการแจกจ่าย (${log.methodLabel}) ออกจากระบบหรือไม่?'),
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

    if (confirm == true && log.id != null) {
      await ref.read(cpoDistributionLogsProvider.notifier).deleteLog(log.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบบันทึกการแจกจ่ายเรียบร้อยแล้ว'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
