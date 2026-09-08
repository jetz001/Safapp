import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../data/models/cpo_election_model.dart';
import '../../data/models/cpo_committee_model.dart';
import '../../domain/enums/cpo_election_status.dart';
import '../../domain/enums/cpo_member_role.dart';
import '../../domain/services/cpo_pdf_generator.dart';
import '../providers/cpo_providers.dart';
import '../widgets/cpo_election_wizard_dialog.dart';
import '../widgets/cpo_ballot_dialog.dart';
import '../../../risk_assessment/presentation/providers/risk_assessment_providers.dart';

class CpoElectionTab extends ConsumerStatefulWidget {
  const CpoElectionTab({super.key});

  @override
  ConsumerState<CpoElectionTab> createState() => _CpoElectionTabState();
}

class _CpoElectionTabState extends ConsumerState<CpoElectionTab> {
  String _searchQuery = '';
  CpoElectionStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final electionsAsync = ref.watch(cpoElectionsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: electionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('เกิดข้อผิดพลาด: $err')),
        data: (elections) {
          final filtered = elections.where((e) {
            final matchQuery = e.electionTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                e.electionCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                e.termYear.contains(_searchQuery);
            final matchStatus = _filterStatus == null || e.status == _filterStatus;
            return matchQuery && matchStatus;
          }).toList();

          return Column(
            children: [
              _buildTopBar(context, theme, elections.length),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _buildElectionCard(context, filtered[index]);
                        },
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      hintText: 'ค้นหารอบการเลือกตั้ง กกต. (รหัส, ชื่อรอบ, ปี พ.ศ.)',
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
                DropdownButton<CpoElectionStatus?>(
                  value: _filterStatus,
                  hint: const Text('ทุกสถานะ'),
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('ทุกสถานะ')),
                    ...CpoElectionStatus.values.map(
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
            icon: const Icon(Icons.how_to_vote, size: 20),
            label: const Text('จัดการรอบเลือกตั้งใหม่', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _openCreateDialog(context),
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
          Icon(Icons.how_to_vote_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'ยังไม่มีรอบการเลือกตั้ง กกต.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          Text(
            'แต่งตั้งคณะกรรมการการเลือกตั้ง (กกต.) เพื่อดำเนินการเลือกตั้งผู้แทนลูกจ้างตามกฎหมาย',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add),
            label: const Text('สร้างรอบการเลือกตั้งแรก'),
            onPressed: () => _openCreateDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildElectionCard(BuildContext context, CpoElectionModel election) {
    final theme = Theme.of(context);
    final status = election.status;
    Color statusBgColor;
    Color statusTextColor;

    switch (status) {
      case CpoElectionStatus.draft:
        statusBgColor = Colors.grey.shade100;
        statusTextColor = Colors.grey.shade800;
        break;
      case CpoElectionStatus.nominating:
        statusBgColor = Colors.blue.shade50;
        statusTextColor = Colors.blue.shade800;
        break;
      case CpoElectionStatus.voting:
        statusBgColor = Colors.orange.shade50;
        statusTextColor = Colors.orange.shade800;
        break;
      case CpoElectionStatus.tallying:
        statusBgColor = Colors.purple.shade50;
        statusTextColor = Colors.purple.shade800;
        break;
      case CpoElectionStatus.completed:
        statusBgColor = Colors.green.shade50;
        statusTextColor = Colors.green.shade800;
        break;
      case CpoElectionStatus.cancelled:
        statusBgColor = Colors.red.shade50;
        statusTextColor = Colors.red.shade800;
        break;
    }

    final electedList = election.candidates.where((c) => c.isElected).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.how_to_vote, color: Color(0xFF0D9488), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            election.electionTitle,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.thaiLabel,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusTextColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'รหัส: ${election.electionCode} | วาระปี พ.ศ. ${election.termYear} | วันลงคะแนน: ${election.votingDate ?? "-"}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'แก้ไขข้อมูลและผู้สมัคร',
                  onPressed: () => _openEditDialog(context, election),
                ),
              ],
            ),
            const Divider(height: 24),

            // Metrics Summary Row
            Row(
              children: [
                _buildInfoMetric(Icons.people_outline, 'ผู้มีสิทธิเลือกตั้ง', '${election.eligibleVotersCount} คน'),
                const SizedBox(width: 24),
                _buildInfoMetric(Icons.how_to_reg_outlined, 'ผู้แทนลูกจ้างที่ต้องการ', '${election.requiredRepsCount} คน'),
                const SizedBox(width: 24),
                _buildInfoMetric(Icons.badge_outlined, 'ผู้สมัครทั้งหมด', '${election.candidates.length} คน'),
                const SizedBox(width: 24),
                _buildInfoMetric(Icons.admin_panel_settings_outlined, 'กรรมการ กกต.', '${election.officers.length} คน'),
              ],
            ),
            const SizedBox(height: 16),

            // Officers (กกต.) badges
            if (election.officers.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('คณะกรรมการ กกต.:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  ...election.officers.map(
                    (o) => Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: CircleAvatar(
                        backgroundColor: Colors.teal.shade100,
                        child: Text(o.officerName.substring(0, 1), style: const TextStyle(fontSize: 10)),
                      ),
                      label: Text('${o.officerName} (${o.officerRoleLabel})', style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Candidates Preview
            if (election.candidates.isNotEmpty) ...[
              Text('รายชื่อผู้สมัครรับเลือกตั้งและคะแนนเสียง:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(60),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(2),
                    3: FixedColumnWidth(100),
                    4: FixedColumnWidth(110),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: const [
                        Padding(padding: EdgeInsets.all(8), child: Text('เบอร์', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('ชื่อ - นามสกุล', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('แผนก/ฝ่าย', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('คะแนนที่ได้', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('ผลการเลือกตั้ง', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    ...election.candidates.map(
                      (c) => TableRow(
                        decoration: BoxDecoration(
                          color: c.isElected ? Colors.green.shade50.withOpacity(0.5) : Colors.transparent,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.teal.shade700,
                              child: Text('${c.candidateNumber}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Padding(padding: const EdgeInsets.all(8), child: Text(c.candidateName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(c.department ?? '-', style: const TextStyle(fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(8), child: Text('${c.voteCount} คะแนน', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: c.isElected
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'ได้รับเลือกตั้ง',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                                      ),
                                    ),
                                  )
                                : const Text('-', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons Bar
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                // Button 1: Vote / Tally
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D9488),
                    side: const BorderSide(color: Color(0xFF0D9488)),
                  ),
                  icon: const Icon(Icons.touch_app, size: 18),
                  label: const Text('ลงคะแนน / นับคะแนน'),
                  onPressed: () => _openBallotDialog(context, election),
                ),

                // Button 2: Tally and Certify
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  label: const Text('ประมวลผล & รับรองผล กกต.'),
                  onPressed: () => _tallyAndCertify(context, election),
                ),

                // Button 3: Print Announcement PDF
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade800,
                  ),
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('พิมพ์ประกาศผล กกต.'),
                  onPressed: () => _printElectionAnnouncement(context, election),
                ),

                // Button 4: Import Elected to Committee
                if (electedList.isNotEmpty)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.group_add, size: 18),
                    label: Text('โอนย้ายผู้ชนะ (${electedList.length} คน) เข้า คปอ.'),
                    onPressed: () => _importElectedToCommittee(context, election, electedList),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoMetric(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  void _openCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const CpoElectionWizardDialog(),
    );
  }

  void _openEditDialog(BuildContext context, CpoElectionModel election) {
    showDialog(
      context: context,
      builder: (ctx) => CpoElectionWizardDialog(existingElection: election),
    );
  }

  void _openBallotDialog(BuildContext context, CpoElectionModel election) {
    showDialog(
      context: context,
      builder: (ctx) => CpoBallotDialog(election: election),
    );
  }

  Future<void> _tallyAndCertify(BuildContext context, CpoElectionModel election) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการประมวลผลและรับรองผลการเลือกตั้ง'),
        content: Text(
          'ระบบจะจัดอันดับคะแนนเสียงของผู้สมัคร และกำหนดให้ผู้ที่ได้คะแนนสูงสุด ${election.requiredRepsCount} อันดับแรก '
          'เป็นผู้ได้รับเลือกตั้งเป็นผู้แทนลูกจ้างใน คปอ. ตามเกณฑ์กฎหมาย',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ประมวลผลทันที'),
          ),
        ],
      ),
    );

    if (confirm == true && election.id != null) {
      await ref.read(cpoElectionsProvider.notifier).tallyResults(
            election.id!,
            requiredReps: election.requiredRepsCount,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ประมวลผลและรับรองผลการเลือกตั้งเรียบร้อยแล้ว')),
        );
      }
    }
  }

  Future<void> _printElectionAnnouncement(BuildContext context, CpoElectionModel election) async {
    final companyName = ref.read(companyProfileNotifierProvider).asData?.value?.companyName ?? 'สถานประกอบกิจการ';
    await Printing.layoutPdf(
      onLayout: (format) => CpoPdfGenerator.generateElectionAnnouncementPdf(election, companyName: companyName),
    );
  }

  Future<void> _importElectedToCommittee(
    BuildContext context,
    CpoElectionModel election,
    List<CpoCandidateModel> electedList,
  ) async {
    final activeTerm = await ref.read(cpoActiveTermProvider.future);
    if (activeTerm == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ยังไม่มีวาระ คปอ. ที่เปิดใช้งาน โปรดสร้างวาระ คปอ. ในแท็บ "โครงสร้าง คปอ." ก่อน')),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('โอนย้ายผู้ได้รับเลือกตั้งเข้าเป็นกรรมการ คปอ.'),
        content: Text(
          'ต้องการเพิ่มรายชื่อผู้ได้รับเลือกตั้งจำนวน ${electedList.length} คน '
          'เข้าสู่วาระ คปอ. "${activeTerm.termTitle}" ในฐานะ "ผู้แทนลูกจ้าง" หรือไม่?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ยืนยันโอนย้าย'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      int imported = 0;
      for (final cand in electedList) {
        // Check if already in members
        final alreadyMember = activeTerm.members.any((m) => m.fullName == cand.candidateName);
        if (!alreadyMember) {
          final member = CpoMemberModel(
            termId: activeTerm.id!,
            employeeId: cand.employeeId,
            fullName: cand.candidateName,
            department: cand.department,
            cpoRole: CpoMemberRole.employeeRep,
            appointmentType: 'ELECTED',
            votesReceived: cand.voteCount,
            status: 'ACTIVE',
          );
          await ref.read(cpoActiveTermProvider.notifier).addMember(member);
          imported++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โอนย้ายผู้แทนลูกจ้างเข้าสู่คณะกรรมการ คปอ. เรียบร้อยแล้ว ($imported คน)')),
        );
      }
    }
  }
}
