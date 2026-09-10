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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column: Meetings list (ALWAYS SHOWN from the start)
                    SizedBox(
                      width: 350,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(right: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: filtered.isEmpty
                            ? _buildLeftEmptyState(context, meetings.isEmpty)
                            : ListView.separated(
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

                    // Right column: Detailed view with Agendas or Full Placeholder
                    Expanded(
                      child: selectedMeeting != null
                          ? _buildMeetingDetailView(context, selectedMeeting, activeTerm?.members.length ?? 0)
                          : _buildRightPlaceholder(context, meetings.isEmpty),
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

  Widget _buildLeftEmptyState(BuildContext context, bool isTotalEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_note_outlined, size: 36, color: Color(0xFF0D9488)),
            ),
            const SizedBox(height: 14),
            Text(
              isTotalEmpty ? 'ยังไม่มีรอบการประชุม' : 'ไม่พบผลการค้นหา',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Text(
              isTotalEmpty
                  ? 'กฎหมายกำหนดให้ คปอ. ประชุมอย่างน้อยเดือนละ ๑ ครั้ง'
                  : 'ลองเปลี่ยนคำค้นหาหรือตัวกรองสถานะ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightPlaceholder(BuildContext context, bool isTotalEmpty) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.meeting_room_outlined, size: 48, color: Color(0xFF0D9488)),
              ),
              const SizedBox(height: 18),
              Text(
                isTotalEmpty ? 'ระบบบันทึกการประชุม คปอ. ๖ วาระตามกฎหมาย' : 'เลือกการประชุมจากรายการทางซ้าย',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isTotalEmpty
                    ? 'กฎกระทรวงความปลอดภัยฯ พ.ศ. ๒๕๖๕ กำหนดให้คณะกรรมการ คปอ. ต้องจัดประชุมอย่างน้อยเดือนละ ๑ ครั้ง '
                      'และบันทึกระเบียบวาระ ๖ วาระตามคู่มือแนวทางปฏิบัติ กสร. ๑/๒๕๖๑'
                    : 'คลิกเลือกรอบการประชุมจากคอลัมน์ด้านซ้ายเพื่อเปิดดูรายละเอียด องค์ประชุม บันทึกสาระสำคัญ และมติที่ประชุมในแต่ละวาระ',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 6 Statutory Agendas Overview Preview Cards
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.format_list_numbered, color: Color(0xFF0D9488), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'ระเบียบวาระการประชุมมาตรฐาน ๖ วาระ (กสร. ๑/๒๕๖๑)',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildPlaceholderAgendaItem('๑', 'เรื่องที่ประธานแจ้งให้ที่ประชุมทราบ', 'นโยบาย ข้อสั่งการ หรือข่าวสารด้านความปลอดภัยจากฝ่ายบริหาร'),
                    _buildPlaceholderAgendaItem('๒', 'พิจารณารับรองรายงานการประชุมครั้งที่ผ่านมา', 'ตรวจสอบความถูกต้องของรายงานการประชุมและมติรอบก่อนหน้า'),
                    _buildPlaceholderAgendaItem('๓', 'เรื่องสืบเนื่องจากการประชุมครั้งที่ผ่านมา', 'ติดตามความคืบหน้า Action Items ที่ได้มอบหมายไว้'),
                    _buildPlaceholderAgendaItem('๔', 'เรื่องเสนอเพื่อทราบ (สถิติอุบัติเหตุ/ผลการตรวจ)', 'รายงานสถิติประสบอันตรายและผลการตรวจความปลอดภัยประจำเดือน'),
                    _buildPlaceholderAgendaItem('๕', 'เรื่องเพื่อพิจารณา (แผนงาน/อบรม/แก้ไขจุดเสี่ยง)', 'พิจารณาข้อเสนอแนะ แผนงานอบรม และมาตรการป้องกันอันตราย'),
                    _buildPlaceholderAgendaItem('๖', 'เรื่องอื่นๆ (ถ้ามี)', 'ข้อปรึกษาหารือเพิ่มเติมของกรรมการทั้งฝ่ายนายจ้างและลูกจ้าง'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderAgendaItem(String no, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.12),
            child: Text(no, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 1),
                Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
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
        color: isSelected ? const Color(0xFF0D9488).withValues(alpha: 0.08) : Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    m.status.thaiLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade500),
                  padding: EdgeInsets.zero,
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0D9488)),
                          SizedBox(width: 8),
                          Text('แก้ไขรายละเอียด'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Text('ลบการประชุม', style: TextStyle(color: Colors.red.shade700)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (val) {
                    if (val == 'edit') {
                      _openEditMeetingDialog(context, m);
                    } else if (val == 'delete') {
                      _confirmDeleteMeeting(context, m);
                    }
                  },
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
                    m.location.isNotEmpty ? m.location : '-',
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
                                    color: const Color(0xFF0D9488).withValues(alpha: 0.1),
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
                                _buildIconLabel(Icons.access_time, 'เวลา: ${meeting.startTime} - ${meeting.endTime} น.'),
                                _buildIconLabel(Icons.room, 'สถานที่: ${meeting.location.isNotEmpty ? meeting.location : "-"}'),
                                _buildIconLabel(Icons.person, 'ประธาน: ${meeting.chairName.isNotEmpty ? meeting.chairName : "-"}'),
                                _buildIconLabel(Icons.edit_note, 'เลขานุการ: ${meeting.secretaryName.isNotEmpty ? meeting.secretaryName : "-"}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: const Color(0xFF0D9488),
                              side: const BorderSide(color: Color(0xFF0D9488)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 15),
                            label: const Text('แก้ไข', style: TextStyle(fontSize: 12)),
                            onPressed: () => _openEditMeetingDialog(context, meeting),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 15),
                            label: const Text('ลบการประชุม', style: TextStyle(fontSize: 12)),
                            onPressed: () => _confirmDeleteMeeting(context, meeting),
                          ),
                        ],
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
                  'รายชื่อกรรมการผู้เข้าร่วมประชุม ($presentCount/${meeting.attendees.length} คน)',
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

          // Agendas Section Header
          Row(
            children: [
              const Icon(Icons.list_alt, size: 20, color: Color(0xFF0D9488)),
              const SizedBox(width: 8),
              Text(
                'ระเบียบวาระการประชุม (${meeting.agendas.length} วาระ)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('เพิ่มวาระใหม่', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () => _openAddAgendaDialog(context, meeting),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Render Agendas using CpoAgendaEditorCard
          for (final agenda in meeting.agendas)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CpoAgendaEditorCard(
                agenda: agenda,
                meetingId: meeting.id!,
                onAgendaUpdated: () => ref.read(cpoMeetingsProvider.notifier).refresh(),
              ),
            ),

          // Button at bottom to add extra agenda
          const SizedBox(height: 4),
          Center(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D9488),
                side: const BorderSide(color: Color(0xFF0D9488)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('เพิ่มระเบียบวาระเพิ่มเติมในการประชุมนี้', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _openAddAgendaDialog(context, meeting),
            ),
          ),
          const SizedBox(height: 20),
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
    final messenger = ScaffoldMessenger.of(context);
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
      messenger.showSnackBar(
        const SnackBar(content: Text('เปลี่ยนสถานะการประชุมเป็นเสร็จสิ้นแล้ว')),
      );
    }
  }

  Future<void> _confirmDeleteMeeting(BuildContext context, CpoMeetingModel meeting) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันลบการประชุม'),
          ],
        ),
        content: Text(
          'คุณต้องการลบการประชุมครั้งที่ ${meeting.meetingNumber}/${meeting.meetingYear} '
          '("${meeting.meetingTitle}") ใช่หรือไม่?\n\n'
          '⚠️ ข้อมูลระเบียบวาระ, มติที่ประชุม, บันทึกการเข้าร่วม และ Action Items ทั้งหมดในการประชุมนี้จะถูกลบอย่างถาวร',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบการประชุม'),
          ),
        ],
      ),
    );

    if (confirm == true && meeting.id != null) {
      await ref.read(cpoMeetingsProvider.notifier).deleteMeeting(meeting.id!);
      setState(() {
        if (_selectedMeetingId == meeting.id) {
          _selectedMeetingId = null;
        }
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text('ลบการประชุมครั้งที่ ${meeting.meetingNumber}/${meeting.meetingYear} เรียบร้อยแล้ว'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _openAddAgendaDialog(BuildContext context, CpoMeetingModel meeting) async {
    final nextNo = (meeting.agendas.map((a) => a.agendaNo).fold<int>(0, (max, no) => no > max ? no : max)) + 1;
    final noCtrl = TextEditingController(text: nextNo.toString());
    final titleCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: Color(0xFF0D9488)),
            SizedBox(width: 8),
            Text('เพิ่มวาระการประชุม'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ลำดับวาระที่ (ตัวเลข) *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'ชื่อหัวข้อวาระ *', hintText: 'เช่น วาระพิเศษ การเตรียมรับการตรวจประเมิน ISO 45001', border: OutlineInputBorder()),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('เพิ่มวาระ'),
          ),
        ],
      ),
    );

    if (result == true && titleCtrl.text.trim().isNotEmpty && meeting.id != null) {
      final newAgenda = CpoAgendaModel(
        meetingId: meeting.id!,
        agendaNo: int.tryParse(noCtrl.text.trim()) ?? nextNo,
        agendaTitle: titleCtrl.text.trim(),
        sortOrder: int.tryParse(noCtrl.text.trim()) ?? nextNo,
      );
      await ref.read(cpoMeetingsProvider.notifier).addAgenda(newAgenda);
      messenger.showSnackBar(
        SnackBar(content: Text('เพิ่มวาระที่ ${newAgenda.agendaNo} เรียบร้อยแล้ว'), backgroundColor: Colors.green),
      );
    }
  }
}
