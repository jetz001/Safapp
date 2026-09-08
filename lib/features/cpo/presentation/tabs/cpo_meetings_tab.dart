import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../data/models/cpo_meeting_model.dart';
import '../../domain/enums/cpo_meeting_status.dart';
import '../../domain/services/cpo_statutory_evaluator.dart';
import '../../domain/services/cpo_pdf_generator.dart';
import '../providers/cpo_providers.dart';
import '../widgets/cpo_meeting_edit_dialog.dart';
import '../widgets/cpo_agenda_editor_card.dart';
import '../widgets/cpo_distribution_dialog.dart';
import '../../../risk_assessment/presentation/providers/risk_assessment_providers.dart';

class CpoMeetingsTab extends ConsumerStatefulWidget {
  const CpoMeetingsTab({super.key});

  @override
  ConsumerState<CpoMeetingsTab> createState() => _CpoMeetingsTabState();
}

class _CpoMeetingsTabState extends ConsumerState<CpoMeetingsTab> {
  int? _selectedMeetingId;
  String _searchQuery = '';
  CpoMeetingStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meetingsAsync = ref.watch(cpoMeetingsProvider);
    final activeTerm = ref.watch(cpoActiveTermProvider).asData?.value;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: meetingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('เกิดข้อผิดพลาด: $err')),
        data: (meetings) {
          final filtered = meetings.where((m) {
            final matchQuery = m.meetingTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                '${m.meetingNumber}/${m.meetingYear}'.contains(_searchQuery) ||
                m.meetingDate.contains(_searchQuery);
            final matchStatus = _filterStatus == null || m.status == _filterStatus;
            return matchQuery && matchStatus;
          }).toList();

          // Auto-select first meeting if not set
          if (_selectedMeetingId == null && filtered.isNotEmpty) {
            _selectedMeetingId = filtered.first.id;
          }

          CpoMeetingModel? selectedMeeting;
          if (_selectedMeetingId != null) {
            final found = filtered.where((m) => m.id == _selectedMeetingId);
            selectedMeeting = found.isNotEmpty ? found.first : (filtered.isNotEmpty ? filtered.first : null);
          }

          return Column(
            children: [
              _buildTopBar(context, theme, meetings.length),
              Expanded(
                child: meetings.isEmpty
                    ? _buildEmptyState(context)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column: Meetings list
                          SizedBox(
                            width: 340,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(right: BorderSide(color: Colors.grey.shade200)),
                              ),
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: filtered.length,
                                separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade100),
                                itemBuilder: (context, index) {
                                  final m = filtered[index];
                                  final isSelected = m.id == _selectedMeetingId;
                                  return _buildMeetingListItem(context, m, isSelected);
                                },
                              ),
                            ),
                          ),

                          // Right column: Detailed view with 6 Agendas & Attendees
                          Expanded(
                            child: selectedMeeting == null
                                ? const Center(child: Text('เลือกการประชุมจากรายการทางซ้ายเพื่อดูและบันทึกรายละเอียด'))
                                : _buildMeetingDetailView(context, selectedMeeting, activeTerm?.members.length ?? 0),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ThemeData theme, int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: 'ค้นหาการประชุม (ครั้งที่, หัวข้อ, วันที่)',
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
                DropdownButton<CpoMeetingStatus?>(
                  value: _filterStatus,
                  hint: const Text('ทุกสถานะ'),
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('ทุกสถานะ')),
                    ...CpoMeetingStatus.values.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.thaiLabel)),
                    ),
                  ],
                  onChanged: (val) => setState(() => _filterStatus = val),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('นัดหมายการประชุมใหม่', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _openCreateMeetingDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('ยังไม่มีการประชุม คปอ.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          Text('กฎหมายกำหนดให้ คปอ. ประชุมอย่างน้อยเดือนละ ๑ ครั้ง (๑๒ ครั้งต่อปี)', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add),
            label: const Text('นัดหมายการประชุมครั้งแรก'),
            onPressed: () => _openCreateMeetingDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingListItem(BuildContext context, CpoMeetingModel m, bool isSelected) {
    Color statusColor;
    switch (m.status) {
      case CpoMeetingStatus.draft:
        statusColor = Colors.blueGrey;
        break;
      case CpoMeetingStatus.scheduled:
        statusColor = Colors.blue;
        break;
      case CpoMeetingStatus.inProgress:
        statusColor = Colors.orange;
        break;
      case CpoMeetingStatus.completed:
        statusColor = Colors.green;
        break;
      case CpoMeetingStatus.cancelled:
        statusColor = Colors.grey;
        break;
    }

    return InkWell(
      onTap: () => setState(() => _selectedMeetingId = m.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        color: isSelected ? const Color(0xFF0D9488).withOpacity(0.08) : Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ครั้งที่ ${m.meetingNumber}/${m.meetingYear}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    m.status.thaiLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              m.meetingTitle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF0D9488) : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(m.meetingDate, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(width: 10),
                Icon(Icons.place_outlined, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    m.location ?? '-',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingDetailView(BuildContext context, CpoMeetingModel meeting, int totalCommitteeMembers) {
    final isQuorumMet = CpoStatutoryEvaluator.evaluateQuorum(
      totalMembers: totalCommitteeMembers > 0 ? totalCommitteeMembers : meeting.attendees.length,
      attendees: meeting.attendees,
    );

    final presentCount = meeting.attendees.where((a) => a.isPresent).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
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
                                Text(
                                  meeting.meetingTitle,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D9488).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ครั้งที่ ${meeting.meetingNumber}/${meeting.meetingYear}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 16,
                              children: [
                                _buildIconLabel(Icons.calendar_month, 'วันที่: ${meeting.meetingDate}'),
                                _buildIconLabel(Icons.access_time, 'เวลา: ${meeting.startTime ?? "-"} - ${meeting.endTime ?? "-"} น.'),
                                _buildIconLabel(Icons.room, 'สถานที่: ${meeting.location ?? "-"}'),
                                _buildIconLabel(Icons.person, 'ประธาน: ${meeting.chairmanName ?? "-"}'),
                                _buildIconLabel(Icons.edit_note, 'เลขานุการ: ${meeting.secretaryName ?? "-"}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'แก้ไขรายละเอียดการประชุม',
                        onPressed: () => _openEditMeetingDialog(context, meeting),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Quorum & Action Bar
                  Row(
                    children: [
                      // Quorum status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isQuorumMet ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isQuorumMet ? Colors.green.shade200 : Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isQuorumMet ? Icons.check_circle : Icons.warning_amber_rounded,
                                size: 16, color: isQuorumMet ? Colors.green.shade800 : Colors.red.shade800),
                            const SizedBox(width: 6),
                            Text(
                              isQuorumMet
                                  ? 'องค์ประชุมครบตามกฎหมาย (มา $presentCount/${meeting.attendees.length} คน)'
                                  : 'องค์ประชุมไม่ครบ (ต้องไม่น้อยกว่ากึ่งหนึ่งและมีตัวแทนทั้ง ๒ ฝ่าย)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isQuorumMet ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Action buttons
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                        icon: const Icon(Icons.mail_outline, size: 16),
                        label: const Text('พิมพ์หนังสือเชิญประชุม'),
                        onPressed: () => _printMeetingNotice(context, meeting),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                        icon: const Icon(Icons.forward_to_inbox_outlined, size: 16),
                        label: const Text('บันทึกแจกจ่ายรายงาน'),
                        onPressed: () => _openDistributionDialog(context, meeting),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.print_outlined, size: 16),
                        label: const Text('สร้าง/พิมพ์รายงาน (PDF)'),
                        onPressed: () => _printMeetingMinutes(context, meeting),
                      ),
                      if (meeting.status != CpoMeetingStatus.completed) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('ปิดการประชุม'),
                          onPressed: () => _markMeetingCompleted(context, meeting),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Attendees Accordion / Expansion
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.people_outline, color: Color(0xFF0D9488)),
                title: Text(
                  'รายชื่อกรรมการผู้เข้าร่วมประชุม (${presentCount}/${meeting.attendees.length} คน)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: meeting.attendees.map((a) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Checkbox(
                            value: a.isPresent,
                            activeColor: const Color(0xFF0D9488),
                            onChanged: (val) async {
                              final updated = a.copyWith(isPresent: val ?? true);
                              await ref.read(cpoMeetingsProvider.notifier).saveAttendee(updated);
                            },
                          ),
                          title: Text(a.attendeeName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('${a.roleLabel} | แผนก: ${a.department ?? "-"}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          trailing: !a.isPresent
                              ? SizedBox(
                                  width: 200,
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      hintText: 'ระบุเหตุผลที่ลาประชุม...',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      border: OutlineInputBorder(),
                                    ),
                                    controller: TextEditingController(text: a.absenceReason),
                                    style: const TextStyle(fontSize: 11),
                                    onSubmitted: (val) async {
                                      final updated = a.copyWith(absenceReason: val);
                                      await ref.read(cpoMeetingsProvider.notifier).saveAttendee(updated);
                                    },
                                  ),
                                )
                              : const Text('มาประชุม', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 6 Agendas Section Header
          Row(
            children: [
              const Icon(Icons.list_alt, size: 20, color: Color(0xFF0D9488)),
              const SizedBox(width: 8),
              const Text(
                'ระเบียบวาระการประชุม ๖ วาระ (ตามคู่มือ กสร. ๑/๒๕๖๑)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text('บันทึกรายละเอียดและมติของแต่ละวาระด้านล่าง', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 12),

          // Render 6 Agendas using CpoAgendaEditorCard
          for (final agenda in meeting.agendas)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CpoAgendaEditorCard(agenda: agenda, meetingId: meeting.id!),
            ),
        ],
      ),
    );
  }

  Widget _buildIconLabel(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  void _openCreateMeetingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const CpoMeetingEditDialog(),
    );
  }

  void _openEditMeetingDialog(BuildContext context, CpoMeetingModel meeting) {
    showDialog(
      context: context,
      builder: (ctx) => CpoMeetingEditDialog(existingMeeting: meeting),
    );
  }

  void _openDistributionDialog(BuildContext context, CpoMeetingModel meeting) {
    showDialog(
      context: context,
      builder: (ctx) => CpoDistributionDialog(
        meetingId: meeting.id!,
        meetingCode: meeting.meetingCode,
      ),
    );
  }

  Future<void> _printMeetingNotice(BuildContext context, CpoMeetingModel meeting) async {
    final companyName = ref.read(companyProfileNotifierProvider).asData?.value?.companyName ?? 'สถานประกอบกิจการ';
    await Printing.layoutPdf(
      onLayout: (format) => CpoPdfGenerator.generateMeetingNoticePdf(meeting, companyName: companyName),
    );
  }

  Future<void> _printMeetingMinutes(BuildContext context, CpoMeetingModel meeting) async {
    final companyName = ref.read(companyProfileNotifierProvider).asData?.value?.companyName ?? 'สถานประกอบกิจการ';
    await Printing.layoutPdf(
      onLayout: (format) => CpoPdfGenerator.generateMeetingMinutesPdf(meeting, companyName: companyName),
    );
  }

  Future<void> _markMeetingCompleted(BuildContext context, CpoMeetingModel meeting) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการปิดการประชุม'),
        content: Text(
          'ต้องการเปลี่ยนสถานะการประชุมครั้งที่ ${meeting.meetingNumber}/${meeting.meetingYear} '
          'เป็น "ดำเนินการประชุมเสร็จสิ้น (Completed)" หรือไม่?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ยืนยันปิดการประชุม'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updated = meeting.copyWith(status: CpoMeetingStatus.completed);
      await ref.read(cpoMeetingsProvider.notifier).updateMeeting(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เปลี่ยนสถานะการประชุมเป็นเสร็จสิ้นแล้ว')),
        );
      }
    }
  }
}
