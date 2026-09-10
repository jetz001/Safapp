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
import '../widgets/cpo_certification_dialog.dart';
import '../../../risk_assessment/presentation/providers/risk_assessment_providers.dart';
import '../../../risk_assessment/domain/models/risk_assessment_models.dart';
import '../../../employee/presentation/providers/employee_providers.dart';
import '../../domain/services/cpo_statutory_evaluator.dart';

class CpoElectionTab extends ConsumerStatefulWidget {
  const CpoElectionTab({super.key});

  @override
  ConsumerState<CpoElectionTab> createState() => _CpoElectionTabState();
}

class _CpoElectionTabState extends ConsumerState<CpoElectionTab> {
  String _searchQuery = '';
  CpoElectionStatus? _filterStatus;
  int? _selectedElectionId;

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
            final matchSelected = _selectedElectionId == null || e.id == _selectedElectionId;
            final matchQuery = e.electionTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                e.electionCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                e.termYear.contains(_searchQuery);
            final matchStatus = _filterStatus == null || e.status == _filterStatus;
            return matchSelected && matchQuery && matchStatus;
          }).toList();

          return Column(
            children: [
              _buildTopBar(context, theme, elections),
              _buildStatutoryGuideCard(context),
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

  Widget _buildTopBar(BuildContext context, ThemeData theme, List<CpoElectionModel> elections) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // 1. Selector Dropdown by Round
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<int?>(
              value: elections.any((e) => e.id == _selectedElectionId) ? _selectedElectionId : null,
              hint: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.how_to_vote, size: 16, color: Color(0xFF0D9488)),
                  SizedBox(width: 6),
                  Text('เลือกรอบการเลือกตั้ง (ทั้งหมด)', style: TextStyle(fontSize: 13)),
                ],
              ),
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.list_alt, size: 16, color: Colors.grey),
                      SizedBox(width: 6),
                      Text('แสดงทุกรอบการเลือกตั้ง', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                ...elections.map(
                  (e) => DropdownMenuItem<int?>(
                    value: e.id,
                    child: Text(
                      '${e.electionCode} • ${e.electionTitle.length > 25 ? "${e.electionTitle.substring(0, 25)}..." : e.electionTitle} (วาระ ${e.termYear})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _selectedElectionId = val),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Search Box
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

          // 3. Status Dropdown
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
          const SizedBox(width: 16),

          // 4. Create Round Button
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
            'ยังไม่มีรอบการเลือกตั้งผู้แทนลูกจ้าง (กกต.)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          Text(
            'แต่งตั้งคณะกรรมการ กกต. เพื่อดำเนินการเลือกตั้งผู้แทนลูกจ้างตามกฎหมาย และส่งรายชื่อเข้าเป็นกรรมการ คปอ.',
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
    final totalVotes = election.candidates.fold<int>(0, (sum, c) => sum + c.votesReceived);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ══════════════════════════════════════════════════════════════════
            // การ์ดใหญ่: ส่วนหัวแสดงข้อมูลรอบการเลือกตั้ง
            // ══════════════════════════════════════════════════════════════════
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.how_to_vote, color: Color(0xFF0D9488), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              election.electionTitle,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
                        'รหัส: ${election.electionCode}  |  วาระปี พ.ศ. ${election.termYear}  |  วันประกาศ: ${election.announcementDate ?? "-"}  |  วันลงคะแนน: ${election.votingDate.isEmpty ? "-" : election.votingDate}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                // Actions
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1E3A8A)),
                  tooltip: 'แก้ไขรายละเอียดรอบเลือกตั้ง',
                  onPressed: () => _openEditDialog(context, election, initialTabIndex: 0),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  tooltip: 'ลบรอบการเลือกตั้งนี้',
                  onPressed: () => _confirmDeleteElection(context, election),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Metrics Summary Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _buildInfoMetric(Icons.people_outline, 'ผู้มีสิทธิเลือกตั้ง', '${election.eligibleVotersCount} คน'),
                  const SizedBox(width: 24),
                  _buildInfoMetric(Icons.how_to_reg_outlined, 'โควตาผู้แทนลูกจ้าง', '${election.requiredRepsCount} คน'),
                  const SizedBox(width: 24),
                  _buildInfoMetric(Icons.badge_outlined, 'ผู้สมัครรับเลือกตั้ง', '${election.candidates.length} คน'),
                  const SizedBox(width: 24),
                  _buildInfoMetric(Icons.admin_panel_settings_outlined, 'กรรมการ กกต.', '${election.officers.length} คน'),
                  const Spacer(),
                  Text(
                    'ขั้นตอนการดำเนินงาน (๖ ขั้นตอนตามกฎหมาย):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ══════════════════════════════════════════════════════════════════
            // การ์ดเล็กด้านใน ๖ ใบ (Horizontal Workflow Sub-Cards)
            // ══════════════════════════════════════════════════════════════════
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStep1OfficerCard(context, election),
                  const SizedBox(width: 14),
                  _buildStep2CandidateCard(context, election),
                  const SizedBox(width: 14),
                  _buildStep3BallotCard(context, election, totalVotes),
                  const SizedBox(width: 14),
                  _buildStep4TallyCard(context, election, electedList),
                  const SizedBox(width: 14),
                  _buildStep5CertifyAndImportCard(context, election, electedList),
                  const SizedBox(width: 14),
                  _buildStep6CommitteeCard(context, election, electedList),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepSubCardWrapper({
    required String stepNum,
    required String stepTitle,
    required String stepSubtitle,
    required IconData icon,
    required Color primaryColor,
    required bool isDone,
    required Widget content,
    required Widget actionButton,
  }) {
    return Container(
      width: 250,
      height: 310,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? Colors.green.shade400 : primaryColor.withValues(alpha: 0.3),
          width: isDone ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: isDone ? Colors.green.shade700 : primaryColor,
                child: Text(
                  stepNum,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stepTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDone ? Colors.green.shade900 : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      stepSubtitle,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                isDone ? Icons.check_circle : icon,
                color: isDone ? Colors.green.shade600 : primaryColor.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 10),

          // Content
          Expanded(child: content),
          const SizedBox(height: 10),

          // Action Button(s)
          SizedBox(
            width: double.infinity,
            child: actionButton,
          ),
        ],
      ),
    );
  }

  Widget _buildStep1OfficerCard(BuildContext context, CpoElectionModel election) {
    final hasOfficers = election.officers.isNotEmpty;
    return _buildStepSubCardWrapper(
      stepNum: '๑',
      stepTitle: 'กกต. (ผู้จัดเลือกตั้ง)',
      stepSubtitle: 'คณะกรรมการการเลือกตั้ง',
      icon: Icons.admin_panel_settings_outlined,
      primaryColor: const Color(0xFF1E3A8A),
      isDone: hasOfficers,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasOfficers ? Colors.blue.shade50 : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              hasOfficers ? 'แต่งตั้งแล้ว ${election.officers.length} คน' : 'ยังไม่ได้แต่งตั้ง กกต.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: hasOfficers ? const Color(0xFF1E3A8A) : Colors.amber.shade900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (hasOfficers)
            Expanded(
              child: ListView(
                children: [
                  ...election.officers.take(3).map(
                    (o) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                            child: Text(
                              o.officerName.substring(0, 1),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${o.officerName} (${o.officerRoleLabel})',
                              style: const TextStyle(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (election.officers.length > 3)
                    Text(
                      '+ อีก ${election.officers.length - 3} คน',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                ],
              ),
            )
          else
            Expanded(
              child: Text(
                'ตามกฎหมาย กรมสวัสดิการฯ ต้องแต่งตั้ง กกต. เพื่อควบคุมการเลือกตั้งและเปิดรับสมัครลูกจ้าง',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.4),
              ),
            ),
        ],
      ),
      actionButton: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.person_add_alt_1, size: 16),
        label: Text(
          hasOfficers ? 'จัดการ กกต. (${election.officers.length})' : 'แต่งตั้ง กกต.',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _openEditDialog(context, election, initialTabIndex: 1),
      ),
    );
  }

  Widget _buildStep2CandidateCard(BuildContext context, CpoElectionModel election) {
    final hasCandidates = election.candidates.isNotEmpty;
    return _buildStepSubCardWrapper(
      stepNum: '๒',
      stepTitle: 'ผู้สมัครรับเลือกตั้ง',
      stepSubtitle: 'ตัวแทนลูกจ้างที่ลงสมัคร',
      icon: Icons.how_to_reg_outlined,
      primaryColor: const Color(0xFF0284C7),
      isDone: hasCandidates,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasCandidates ? Colors.lightBlue.shade50 : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              hasCandidates
                  ? 'ผู้สมัคร ${election.candidates.length} คน (โควตา ${election.requiredRepsCount} คน)'
                  : 'ยังไม่มีผู้สมัคร',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: hasCandidates ? const Color(0xFF0284C7) : Colors.amber.shade900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (hasCandidates)
            Expanded(
              child: ListView(
                children: [
                  ...election.candidates.take(3).map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: Colors.teal.shade700,
                            child: Text(
                              '${c.candidateNumber}',
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${c.candidateName} (${c.department ?? "-"})',
                              style: const TextStyle(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (election.candidates.length > 3)
                    Text(
                      '+ อีก ${election.candidates.length - 3} คน',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                ],
              ),
            )
          else
            Expanded(
              child: Text(
                'เปิดรับสมัครลูกจ้างลงแข่งขันเป็นผู้แทนใน คปอ. ตามโควตากฎหมาย (ต้องการ ${election.requiredRepsCount} คน)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.4),
              ),
            ),
        ],
      ),
      actionButton: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.badge_outlined, size: 16),
        label: Text(
          hasCandidates ? 'จัดการผู้สมัคร (${election.candidates.length})' : 'เพิ่มผู้สมัคร',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _openEditDialog(context, election, initialTabIndex: 2),
      ),
    );
  }

  Widget _buildStep3BallotCard(BuildContext context, CpoElectionModel election, int totalVotes) {
    final hasVoted = totalVotes > 0;
    return _buildStepSubCardWrapper(
      stepNum: '๓',
      stepTitle: 'ลงคะแนน & นับคะแนน',
      stepSubtitle: 'หีบบัตร & นับคะแนนเสียง',
      icon: Icons.touch_app_outlined,
      primaryColor: const Color(0xFF0D9488),
      isDone: hasVoted,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasVoted ? Colors.teal.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              hasVoted ? 'นับคะแนนแล้ว $totalVotes เสียง' : 'รอดำเนินการลงคะแนน',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: hasVoted ? const Color(0xFF0D9488) : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• วันลงคะแนน: ${election.votingDate.isEmpty ? "-" : election.votingDate}', style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                const SizedBox(height: 4),
                Text('• ผู้มีสิทธิเลือกตั้ง: ${election.eligibleVotersCount} คน', style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                const SizedBox(height: 4),
                Text('• ผู้สมัครในบัตร: ${election.candidates.length} คน', style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                const SizedBox(height: 8),
                Text(
                  'กดปุ่มด้านล่างเพื่อเปิดหน้าต่างลงคะแนนเสียง หรือบันทึกคะแนนจากหีบบัตร',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
      actionButton: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D9488),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.how_to_vote, size: 16),
        label: const Text('ลงคะแนน / นับคะแนน', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        onPressed: () => _openBallotDialog(context, election),
      ),
    );
  }

  Widget _buildStep4TallyCard(BuildContext context, CpoElectionModel election, List<CpoCandidateModel> electedList) {
    final isTallied = electedList.isNotEmpty;
    return _buildStepSubCardWrapper(
      stepNum: '๔',
      stepTitle: 'สรุปผล & รับรองผล',
      stepSubtitle: 'จัดอันดับตามโควตา',
      icon: Icons.analytics_outlined,
      primaryColor: const Color(0xFF7C3AED),
      isDone: isTallied,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _openCertificationDialog(context, election),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isTallied ? Colors.purple.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isTallied ? Colors.purple.shade300 : Colors.transparent),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isTallied ? 'รับรองผลแล้ว (${electedList.length} คน)' : 'ยังไม่ประมวลผล',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isTallied ? Colors.purple.shade800 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit_outlined, size: 12, color: isTallied ? Colors.purple.shade800 : Colors.grey.shade600),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (isTallied)
            Expanded(
              child: ListView(
                children: [
                  ...electedList.map(
                    (c) => InkWell(
                      onTap: () => _openCertificationDialog(context, election),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'เบอร์ ${c.candidateNumber}: ${c.candidateName} (${c.voteCount} เสียง)',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.edit_outlined, size: 11, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Text(
                'เมื่อนับคะแนนเสร็จสิ้น กดปุ่มประมวลผลเพื่อจัดอันดับผู้ได้คะแนนสูงสุด ${election.requiredRepsCount} อันดับแรกตามกฎหมาย หรือปรับแก้เอง',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.4),
              ),
            ),
        ],
      ),
      actionButton: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(isTallied ? Icons.edit_note : Icons.verified_outlined, size: 16),
        label: Text(isTallied ? 'แก้ไข & รับรองผล' : 'ประมวลผลรับรองผล', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        onPressed: () => _openCertificationDialog(context, election),
      ),
    );
  }

  Widget _buildStep5CertifyAndImportCard(BuildContext context, CpoElectionModel election, List<CpoCandidateModel> electedList) {
    final isCompleted = election.status == CpoElectionStatus.completed;
    return _buildStepSubCardWrapper(
      stepNum: '๕',
      stepTitle: 'ประกาศผล & โอนย้าย',
      stepSubtitle: 'ประกาศ กกต. & เข้า คปอ.',
      icon: Icons.group_add_outlined,
      primaryColor: const Color(0xFF16A34A),
      isDone: isCompleted,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: electedList.isNotEmpty ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              electedList.isNotEmpty ? 'พร้อมโอนย้าย (${electedList.length} คน)' : 'รอรับรองผลในขั้นที่ ๔',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: electedList.isNotEmpty ? const Color(0xFF16A34A) : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '๑. พิมพ์ประกาศผลการเลือกตั้ง กกต. ทางการ (PDF ภาษาไทยคมชัด)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.3),
                ),
                const SizedBox(height: 6),
                Text(
                  '๒. โอนย้ายรายชื่อผู้แทนลูกจ้างเข้าสู่แท็บ "คณะกรรมการ คปอ. (วาระ ๒ ปี)"',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
      actionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.print_outlined, size: 15),
              label: const Text('พิมพ์ประกาศ กกต.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () => _printElectionAnnouncement(context, election),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.group_add, size: 15),
              label: Text(
                'โอนเข้า คปอ. (${electedList.length})',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              onPressed: electedList.isEmpty ? null : () => _importElectedToCommittee(context, election, electedList),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep6CommitteeCard(BuildContext context, CpoElectionModel election, List<CpoCandidateModel> electedList) {
    final allTerms = ref.watch(cpoAllTermsProvider).asData?.value ?? [];
    final companyProfile = ref.watch(companyProfileNotifierProvider).asData?.value;
    final defaultEmployees = companyProfile?.employeeCount ?? 100;

    final term = allTerms.cast<CpoTermModel?>().firstWhere(
      (t) => t != null && (t.termCode == 'TERM-${election.termYear}' || t.termTitle.contains(election.termYear)),
      orElse: () => null,
    );

    final isFormed = term != null;
    final employeeCount = (term?.employeeCount ?? 0) > 0 ? term!.employeeCount : defaultEmployees;
    final quotaResult = isFormed
        ? CpoStatutoryEvaluator.evaluateQuota(
            employeeCount: employeeCount,
            members: term.members,
          )
        : null;

    final isCompliant = quotaResult?.isCompliant ?? false;
    final memberCount = term?.members.length ?? 0;
    final statutoryMin = quotaResult?.requiredTotal ?? (defaultEmployees >= 500 ? 11 : (defaultEmployees >= 100 ? 7 : 5));

    final secretary = term?.members.firstWhere(
      (m) => m.cpoRole == CpoMemberRole.secretary,
      orElse: () => CpoMemberModel(termId: 0, fullName: '', cpoRole: CpoMemberRole.secretary),
    );
    final hasSecretary = secretary != null && secretary.fullName.isNotEmpty;

    return _buildStepSubCardWrapper(
      stepNum: '๖',
      stepTitle: 'คณะกรรมการ คปอ.',
      stepSubtitle: 'วาระ ๒ ปี (พ.ศ. ${election.termYear})',
      icon: Icons.shield_outlined,
      primaryColor: const Color(0xFF0D9488),
      isDone: isCompliant,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCompliant
                  ? Colors.green.shade50
                  : (isFormed ? Colors.amber.shade50 : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCompliant
                      ? Icons.check_circle_outline
                      : (isFormed ? Icons.info_outline : Icons.help_outline),
                  size: 13,
                  color: isCompliant
                      ? Colors.green.shade700
                      : (isFormed ? Colors.amber.shade800 : Colors.grey.shade600),
                ),
                const SizedBox(width: 4),
                Text(
                  !isFormed
                      ? 'ยังไม่ได้จัดตั้ง'
                      : (isCompliant ? 'ครบตามเกณฑ์ ($memberCount/$statutoryMin คน)' : 'แต่งตั้งแล้ว ($memberCount/$statutoryMin คน)'),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isCompliant
                        ? Colors.green.shade800
                        : (isFormed ? Colors.amber.shade900 : Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: !isFormed
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'จัดตั้งโครงสร้าง คปอ. ประจำรอบนี้ ๔ ส่วนตามกฎหมาย:',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.3),
                      ),
                      const SizedBox(height: 4),
                      Text('• ประธาน (นายจ้าง/ผู้บริหาร)', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      Text('• ผู้แทนนายจ้างระดับบังคับบัญชา', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      Text('• ผู้แทนลูกจ้าง (จากการเลือกตั้ง)', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      Text('• เลขานุการ (จป. จากองค์กร)', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMiniRoleSummary(Icons.stars, 'ประธาน:', term.members.where((m) => m.cpoRole == CpoMemberRole.chair).length, 1),
                      const SizedBox(height: 3),
                      _buildMiniRoleSummary(Icons.business_center, 'ผู้แทนนายจ้าง:', term.members.where((m) => m.cpoRole == CpoMemberRole.employerRep).length, quotaResult?.requiredEmployerRep ?? 0),
                      const SizedBox(height: 3),
                      _buildMiniRoleSummary(Icons.how_to_vote, 'ผู้แทนลูกจ้าง:', term.members.where((m) => m.cpoRole == CpoMemberRole.employeeRep).length, quotaResult?.requiredEmployeeRep ?? 0),
                      const SizedBox(height: 3),
                      _buildMiniRoleSummary(
                        Icons.edit_note,
                        'เลขา คปอ.:',
                        hasSecretary ? 1 : 0,
                        1,
                        extraText: hasSecretary ? secretary.fullName : 'ยังไม่ระบุ',
                      ),
                    ],
                  ),
          ),
        ],
      ),
      actionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFormed && !hasSecretary && companyProfile?.safetyOfficerName != null && companyProfile!.safetyOfficerName!.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const Color(0xFF0D9488),
                  side: const BorderSide(color: Color(0xFF0D9488)),
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.flash_on, size: 13, color: Colors.amber),
                label: const Text('⚡ ดึง จป. เป็นเลขา', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await ref.read(cpoAllTermsProvider.notifier).autoAssignSecretaryFromProfile(term.id!, companyProfile);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('แต่งตั้ง จป. "${companyProfile.safetyOfficerName}" เป็นเลขานุการ คปอ. เรียบร้อยแล้ว'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 5),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: Icon(isFormed ? Icons.groups : Icons.add_circle_outline, size: 15),
              label: Text(
                !isFormed ? 'จัดตั้ง คปอ. รอบนี้' : 'จัดการ คปอ. ($memberCount/$statutoryMin)',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                if (!isFormed) {
                  await ref.read(cpoAllTermsProvider.notifier).findOrCreateTermForElection(
                    election,
                    employeeCount: defaultEmployees,
                  );
                } else {
                  _openCommitteeManagementDialog(context, election, electedList);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniRoleSummary(IconData icon, String title, int count, int req, {String? extraText}) {
    final isMet = count >= req && req > 0;
    return Row(
      children: [
        Icon(icon, size: 13, color: isMet ? Colors.green.shade600 : Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
        const SizedBox(width: 4),
        if (extraText != null)
          Expanded(
            child: Text(
              extraText,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isMet ? Colors.black87 : Colors.orange.shade800),
              overflow: TextOverflow.ellipsis,
            ),
          )
        else ...[
          Text(
            '$count/$req',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isMet ? Colors.green.shade800 : Colors.orange.shade800,
            ),
          ),
        ],
      ],
    );
  }

  void _openCommitteeManagementDialog(
    BuildContext context,
    CpoElectionModel election,
    List<CpoCandidateModel> electedList,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 1000,
          constraints: const BoxConstraints(maxHeight: 800),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shield_outlined, color: Color(0xFF0D9488), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'โครงสร้างคณะกรรมการ คปอ. (รอบการเลือกตั้ง พ.ศ. ${election.termYear})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'คณะกรรมการความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน (วาระ ๒ ปี)',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: _buildCommitteeStructureForElection(context, election, electedList),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatutoryGuideCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.how_to_vote, color: Color(0xFF1E3A8A), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ศูนย์จัดการเลือกตั้งผู้แทนลูกจ้าง (กกต. เฉพาะกิจ) ตามกฎหมาย',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'กกต. มีหน้าที่เฉพาะช่วงจัดการเลือกตั้ง เมื่อรับรองผลเสร็จสิ้น ให้โอนย้ายรายชื่อผู้แทนลูกจ้างเข้าสู่แท็บ "คณะกรรมการ คปอ. (วาระ ๒ ปี)"',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              final steps = [
                _buildGuideStep('๑', 'แต่งตั้ง กกต.', 'กำหนดคณะกรรมการ กกต. จัดการเลือกตั้ง'),
                _buildGuideStep('๒', 'รับสมัครผู้แทน', 'เปิดรับสมัครลูกจ้างและตรวจสอบคุณสมบัติ'),
                _buildGuideStep('๓', 'ลงคะแนนเสียง', 'ลูกจ้างลงคะแนนเสียงผ่านระบบหรือหีบบัตร'),
                _buildGuideStep('๔', 'ประมวลผลคะแนน', 'ระบบจัดอันดับผู้ได้คะแนนสูงสุดตามโควตา'),
                _buildGuideStep('๕', 'ประกาศผล & โอนย้าย', 'พิมพ์ประกาศ กกต. และโอนชื่อเข้าสู่ คปอ.'),
                _buildGuideStep('๖', 'คณะกรรมการ คปอ.', 'จัดตั้งโครงสร้าง ๔ ส่วนครบตามเกณฑ์กฎหมาย'),
              ];

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: steps
                      .map((s) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: s)))
                      .toList(),
                );
              } else {
                return Column(
                  children: steps.map((s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: s)).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF1E3A8A),
            child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3)),
              ],
            ),
          ),
        ],
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

  void _openEditDialog(BuildContext context, CpoElectionModel election, {int initialTabIndex = 0}) {
    showDialog(
      context: context,
      builder: (ctx) => CpoElectionWizardDialog(
        existingElection: election,
        initialTabIndex: initialTabIndex,
      ),
    );
  }

  Future<void> _confirmDeleteElection(BuildContext context, CpoElectionModel election) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันลบรอบการเลือกตั้ง'),
          ],
        ),
        content: Text(
          'คุณต้องการลบรอบการเลือกตั้ง "${election.electionTitle}" (${election.electionCode}) ใช่หรือไม่?\n\n'
          '⚠️ ข้อมูลคณะกรรมการ กกต., รายชื่อผู้สมัคร และคะแนนเสียงทั้งหมดในรอบนี้จะถูกลบอย่างถาวร',
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
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบข้อมูล'),
          ),
        ],
      ),
    );

    if (confirm == true && election.id != null) {
      await ref.read(cpoElectionsProvider.notifier).deleteElection(election.id!);
      messenger.showSnackBar(
        SnackBar(
          content: Text('ลบรอบการเลือกตั้ง "${election.electionTitle}" เรียบร้อยแล้ว'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _openBallotDialog(BuildContext context, CpoElectionModel election) {
    if (election.candidates.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('ยังไม่มีรายชื่อผู้สมัคร'),
            ],
          ),
          content: const Text(
            'รอบการเลือกตั้งนี้ยังไม่มีรายชื่อผู้สมัครรับเลือกตั้ง กรุณาเพิ่มรายชื่อผู้แทนลูกจ้างที่ลงสมัครก่อนทำการลงคะแนนหรือนับคะแนนเสียง',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ปิด')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _openEditDialog(context, election);
              },
              child: const Text('ไปเพิ่มผู้สมัครทันที'),
            ),
          ],
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => CpoBallotDialog(election: election),
    );
  }

  void _openCertificationDialog(BuildContext context, CpoElectionModel election) {
    if (election.candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ยังไม่มีรายชื่อผู้สมัครในรอบนี้ กรุณาเพิ่มผู้สมัครก่อนรับรองผล'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => CpoCertificationDialog(election: election),
    );
  }

  Future<void> _printElectionAnnouncement(BuildContext context, CpoElectionModel election) async {
    final messenger = ScaffoldMessenger.of(context);
    if (election.candidates.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('ยังไม่มีรายชื่อผู้สมัคร จึงยังไม่มีผลการเลือกตั้งให้จัดพิมพ์'), backgroundColor: Colors.orange),
      );
      return;
    }
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
    final messenger = ScaffoldMessenger.of(context);
    final companyProfile = ref.read(companyProfileNotifierProvider).asData?.value;
    final term = await ref.read(cpoAllTermsProvider.notifier).findOrCreateTermForElection(
      election,
      employeeCount: companyProfile?.employeeCount ?? 100,
    );
    if (!context.mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('โอนย้ายผู้ได้รับเลือกตั้งเข้าเป็นกรรมการ คปอ.'),
        content: Text(
          'ต้องการเพิ่มรายชื่อผู้ได้รับเลือกตั้งจำนวน ${electedList.length} คน '
          'เข้าสู่วาระ คปอ. "${term.termTitle}" ในฐานะ "ผู้แทนลูกจ้าง" หรือไม่?',
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
        final alreadyMember = term.members.any((m) => m.fullName == cand.candidateName);
        if (!alreadyMember) {
          final member = CpoMemberModel(
            termId: term.id!,
            employeeId: cand.employeeId,
            fullName: cand.candidateName,
            department: cand.department,
            cpoRole: CpoMemberRole.employeeRep,
            appointmentType: 'ELECTED',
            votesReceived: cand.voteCount,
            status: 'ACTIVE',
          );
          await ref.read(cpoAllTermsProvider.notifier).addMember(member);
          imported++;
        }
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('โอนย้ายผู้แทนลูกจ้างเข้าสู่คณะกรรมการ คปอ. เรียบร้อยแล้ว ($imported คน)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // โครงสร้างคณะกรรมการ คปอ. ประจำรอบการเลือกตั้ง (วาระ ๒ ปี)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCommitteeStructureForElection(
    BuildContext context,
    CpoElectionModel election,
    List<CpoCandidateModel> electedList,
  ) {
    final allTerms = ref.watch(cpoAllTermsProvider).asData?.value ?? [];
    final companyProfile = ref.watch(companyProfileNotifierProvider).asData?.value;
    final defaultEmployees = companyProfile?.employeeCount ?? 100;

    final term = allTerms.cast<CpoTermModel?>().firstWhere(
      (t) => t != null && (t.termCode == 'TERM-${election.termYear}' || t.termTitle.contains(election.termYear)),
      orElse: () => null,
    );

    if (term == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D9488).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.diversity_3_outlined, color: Color(0xFF0D9488), size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'โครงสร้างคณะกรรมการ คปอ. ประจำรอบการเลือกตั้งนี้ (วาระ ๒ ปี: พ.ศ. ${election.termYear})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'จัดตั้งโครงสร้าง คปอ. ๔ ส่วนตามกฎกระทรวง ๒๕๖๕ (ประธาน, ผู้แทนนายจ้าง, ผู้แทนลูกจ้างจากการเลือกตั้งรอบนี้, เลขา คปอ.)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('จัดตั้งโครงสร้าง คปอ. รอบนี้', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: () async {
                await ref.read(cpoAllTermsProvider.notifier).findOrCreateTermForElection(
                  election,
                  employeeCount: defaultEmployees,
                );
              },
            ),
          ],
        ),
      );
    }

    final employeeCount = term.employeeCount > 0 ? term.employeeCount : defaultEmployees;
    final quotaResult = CpoStatutoryEvaluator.evaluateQuota(
      employeeCount: employeeCount,
      members: term.members,
    );

    final chairs = term.members.where((m) => m.cpoRole == CpoMemberRole.chair).toList();
    final employerReps = term.members.where((m) => m.cpoRole == CpoMemberRole.employerRep).toList();
    final employeeReps = term.members.where((m) => m.cpoRole == CpoMemberRole.employeeRep).toList();
    final secretaries = term.members.where((m) => m.cpoRole == CpoMemberRole.secretary).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D9488).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFF0D9488), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'คณะกรรมการ คปอ. ประจำรอบนี้: ${term.termTitle}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('วาระ ๒ ปี', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ช่วงเวลา: ${term.startDate} ถึง ${term.endDate} • เกณฑ์พนักงาน: $employeeCount คน',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const Color(0xFF0D9488),
                  side: const BorderSide(color: Color(0xFF0D9488)),
                ),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('แก้ไขวาระ', style: TextStyle(fontSize: 12)),
                onPressed: () => _openTermDialog(context, term, employeeCount),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.person_add_alt_1, size: 14),
                label: const Text('แต่งตั้งกรรมการเพิ่ม', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () => _openMemberDialog(context, term.id!, null, profile: companyProfile),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Statutory Quota Compliance Banner
        _buildComplianceBanner(context, quotaResult),
        const SizedBox(height: 14),

        // Notice to import newly elected candidates if not yet imported
        if (electedList.isNotEmpty && electedList.any((cand) => !term.members.any((m) => m.fullName == cand.candidateName))) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.how_to_reg, color: Colors.green.shade800, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'มีผู้แทนลูกจ้างที่ได้รับเลือกตั้งในรอบนี้ ${electedList.length} คน พร้อมโอนเข้าคณะกรรมการ คปอ.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.group_add, size: 14),
                  label: const Text('โอนเข้า คปอ. ทันที', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _importElectedToCommittee(context, election, electedList),
                ),
              ],
            ),
          ),
        ],

        // 4 Statutory Role Groups
        _buildRoleGroup(
          context,
          term.id!,
          '๑. ประธานคณะกรรมการ คปอ. (นายจ้างหรือผู้แทนนายจ้างระดับบริหาร)',
          chairs,
          CpoMemberRole.chair,
          Icons.stars,
          companyProfile,
        ),
        const SizedBox(height: 12),
        _buildRoleGroup(
          context,
          term.id!,
          '๒. กรรมการผู้แทนนายจ้างระดับบังคับบัญชา',
          employerReps,
          CpoMemberRole.employerRep,
          Icons.business_center_outlined,
          companyProfile,
        ),
        const SizedBox(height: 12),
        _buildRoleGroup(
          context,
          term.id!,
          '๓. กรรมการผู้แทนลูกจ้าง (ที่มาจากการเลือกตั้งในรอบนี้)',
          employeeReps,
          CpoMemberRole.employeeRep,
          Icons.how_to_vote_outlined,
          companyProfile,
          election: election,
        ),
        const SizedBox(height: 12),
        _buildRoleGroup(
          context,
          term.id!,
          '๔. เลขานุการคณะกรรมการ คปอ. (จป.วิชาชีพ หรือผู้ได้รับมอบหมาย)',
          secretaries,
          CpoMemberRole.secretary,
          Icons.edit_note_outlined,
          companyProfile,
        ),
      ],
    );
  }

  Widget _buildComplianceBanner(BuildContext context, CpoComplianceResult quota) {
    Color bg;
    Color border;
    Color textCol;
    IconData icon;

    if (quota.isCompliant) {
      bg = const Color(0xFFF0FDF4);
      border = const Color(0xFFBBF7D0);
      textCol = const Color(0xFF166534);
      icon = Icons.check_circle;
    } else {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFECACA);
      textCol = const Color(0xFF991B1B);
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textCol, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quota.summaryText,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildQuotaChip('ลูกจ้างทั้งหมด', '${quota.employeeCount} คน', Colors.blueGrey),
              _buildQuotaChip('ประธาน คปอ.', '${quota.actualChair}/${quota.requiredChair}', quota.actualChair >= quota.requiredChair ? Colors.teal : Colors.red),
              _buildQuotaChip('ผู้แทนนายจ้าง', '${quota.actualEmployerRep}/${quota.requiredEmployerRep}', quota.actualEmployerRep >= quota.requiredEmployerRep ? Colors.teal : Colors.red),
              _buildQuotaChip('ผู้แทนลูกจ้าง', '${quota.actualEmployeeRep}/${quota.requiredEmployeeRep}', quota.actualEmployeeRep >= quota.requiredEmployeeRep ? Colors.teal : Colors.red),
              _buildQuotaChip('เลขานุการ (จป.)', '${quota.actualSecretary}/${quota.requiredSecretary}', quota.actualSecretary >= quota.requiredSecretary ? Colors.teal : Colors.red),
              _buildQuotaChip('กรรมการรวม', '${quota.actualTotal}/${quota.requiredTotal}', quota.actualTotal >= quota.requiredTotal ? Colors.teal : Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaChip(String label, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.shade800)),
        ],
      ),
    );
  }

  Widget _buildRoleGroup(
    BuildContext context,
    int termId,
    String title,
    List<CpoMemberModel> members,
    CpoMemberRole defaultRole,
    IconData icon,
    CompanyProfile? companyProfile, {
    CpoElectionModel? election,
  }) {
    final isSecretary = defaultRole == CpoMemberRole.secretary;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF0D9488)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isSecretary && companyProfile != null && companyProfile.safetyOfficerName != null && companyProfile.safetyOfficerName!.isNotEmpty) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.bolt, size: 14),
                    label: Text(
                      'ดึงอัตโนมัติจาก จป. (${companyProfile.safetyOfficerName})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      await ref.read(cpoAllTermsProvider.notifier).autoAssignSecretaryFromProfile(termId, companyProfile);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('ดึง "${companyProfile.safetyOfficerName}" จากโมดูลองค์กรเป็นเลขานุการ คปอ. เรียบร้อยแล้ว'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                ],
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.add, size: 15),
                  label: Text(isSecretary ? 'ระบุชื่อเอง' : 'เพิ่มในส่วนนี้', style: const TextStyle(fontSize: 12)),
                  onPressed: () => _openMemberDialog(context, termId, null, initialRole: defaultRole, profile: companyProfile),
                ),
              ],
            ),
            const Divider(height: 16),
            if (members.isEmpty) ...[
              if (isSecretary && companyProfile != null && companyProfile.safetyOfficerName != null && companyProfile.safetyOfficerName!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Color(0xFF0D9488), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ยังไม่ได้แต่งตั้งเลขานุการ คปอ. (ตามกฎหมายกำหนดให้เป็น จป.วิชาชีพ หรือผู้ได้รับมอบหมาย)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'พบข้อมูล จป. ในโมดูลองค์กร: ${companyProfile.safetyOfficerName} (${companyProfile.safetyOfficerLevel ?? "จป.วิชาชีพ"}) โทร: ${companyProfile.safetyOfficerPhone ?? "-"}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.bolt, size: 16),
                        label: const Text('ดึง จป. ทันที', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          await ref.read(cpoAllTermsProvider.notifier).autoAssignSecretaryFromProfile(termId, companyProfile);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('ดึง "${companyProfile.safetyOfficerName}" จากโมดูลองค์กรเป็นเลขานุการ คปอ. สำเร็จ'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      'ยังไม่มีกรรมการในตำแหน่งนี้ (โปรดแต่งตั้งให้ครบตามเกณฑ์กฎหมาย)',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
            ] else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (ctx, i) {
                  final m = members[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
                      foregroundColor: const Color(0xFF0D9488),
                      child: Text(m.fullName.isNotEmpty ? m.fullName.substring(0, 1) : '?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    title: Row(
                      children: [
                        Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        if (m.companyPosition != null && m.companyPosition!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text('(${m.companyPosition})', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                        if (m.appointmentType == 'ELECTED') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('มาจากการเลือกตั้ง', style: TextStyle(color: Colors.green.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      'แผนก: ${m.department ?? "-"} | โทร: ${m.phone ?? "-"}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 17, color: Color(0xFF1E3A8A)),
                          tooltip: 'แก้ไขข้อมูล',
                          onPressed: () => _openMemberDialog(context, termId, m, profile: companyProfile),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 17, color: Colors.redAccent),
                          tooltip: 'ลบออกจาก คปอ.',
                          onPressed: () => _deleteMember(context, m),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openTermDialog(BuildContext context, CpoTermModel? term, int defaultEmployees) {
    final titleCtrl = TextEditingController(text: term?.termTitle ?? 'คณะกรรมการ คปอ. ชุดประจำปี ${(DateTime.now().year + 543)} - ${(DateTime.now().year + 545)}');
    final startCtrl = TextEditingController(text: term?.startDate ?? DateTime.now().toIso8601String().substring(0, 10));
    final endCtrl = TextEditingController(
      text: term?.endDate ??
          DateTime(DateTime.now().year + 2, DateTime.now().month, DateTime.now().day).toIso8601String().substring(0, 10),
    );
    final empCountCtrl = TextEditingController(text: (term != null ? term.employeeCount : defaultEmployees).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(term == null ? 'จัดตั้งวาระ คปอ. ใหม่ (วาระ ๒ ปี)' : 'แก้ไขข้อมูลวาระ คปอ.'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อวาระ คปอ. *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startCtrl,
                      decoration: const InputDecoration(labelText: 'วันเริ่มต้นวาระ (YYYY-MM-DD)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      decoration: const InputDecoration(labelText: 'วันสิ้นสุดวาระ (YYYY-MM-DD)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: empCountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'จำนวนลูกจ้างทั้งหมดในสถานประกอบการ (คน) *',
                  helperText: 'ระบบจะนำตัวเลขนี้ไปคำนวณเกณฑ์สัดส่วน คปอ. ตามกฎกระทรวง ๒๕๖๕',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
            onPressed: () async {
              final newTerm = CpoTermModel(
                id: term?.id,
                termCode: term?.termCode ?? 'TERM-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
                termTitle: titleCtrl.text.trim(),
                startDate: startCtrl.text.trim(),
                endDate: endCtrl.text.trim(),
                employeeCount: int.tryParse(empCountCtrl.text.trim()) ?? defaultEmployees,
                status: 'ACTIVE',
                members: term?.members ?? const [],
              );
              await ref.read(cpoAllTermsProvider.notifier).saveTerm(newTerm);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _openMemberDialog(
    BuildContext context,
    int termId,
    CpoMemberModel? member, {
    CpoMemberRole? initialRole,
    CompanyProfile? profile,
  }) {
    final nameCtrl = TextEditingController(text: member?.fullName ?? '');
    final deptCtrl = TextEditingController(text: member?.department ?? '');
    final posCtrl = TextEditingController(text: member?.companyPosition ?? '');
    final phoneCtrl = TextEditingController(text: member?.phone ?? '');
    final emailCtrl = TextEditingController(text: member?.email ?? '');
    final dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));

    CpoMemberRole selectedRole = member?.cpoRole ?? initialRole ?? CpoMemberRole.employerRep;
    int? selectedEmpId = member?.employeeId;

    final employeesAsync = ref.read(employeesProvider);
    final allEmployees = employeesAsync.asData?.value ?? [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            title: Text(member == null ? 'แต่งตั้งกรรมการ คปอ. ใหม่' : 'แก้ไขข้อมูลกรรมการ คปอ.'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Auto-pull from Organization Safety Officer if Secretary
                    if (selectedRole == CpoMemberRole.secretary &&
                        profile != null &&
                        profile.safetyOfficerName != null &&
                        profile.safetyOfficerName!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined, color: Color(0xFF0D9488), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('พบข้อมูล จป. ในโมดูลองค์กร (ผู้ประเมินหลัก):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                                  Text('${profile.safetyOfficerName} (${profile.safetyOfficerLevel ?? "จป.วิชาชีพ"})  โทร: ${profile.safetyOfficerPhone ?? "-"}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D9488),
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              icon: const Icon(Icons.bolt, size: 14),
                              label: const Text('ดึงข้อมูลนี้', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                setDlgState(() {
                                  nameCtrl.text = profile.safetyOfficerName ?? '';
                                  posCtrl.text = profile.safetyOfficerLevel ?? 'จป.วิชาชีพ';
                                  phoneCtrl.text = profile.safetyOfficerPhone ?? '';
                                  deptCtrl.text = 'ความปลอดภัยและอาชีวอนามัย (EHS)';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (allEmployees.isNotEmpty && member == null) ...[
                      DropdownButtonFormField<int?>(
                        decoration: const InputDecoration(
                          labelText: 'เลือกจากรายชื่อพนักงานในระบบ (หรือพิมพ์เองด้านล่าง)',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: selectedEmpId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('-- พิมพ์ชื่อเอง / ไม่เลือก --')),
                          ...allEmployees.map((e) => DropdownMenuItem(
                                value: e.id,
                                child: Text('${e.fullName} (${e.department})'),
                              )),
                        ],
                        onChanged: (val) {
                          setDlgState(() {
                            selectedEmpId = val;
                            if (val != null) {
                              final emp = allEmployees.firstWhere((e) => e.id == val);
                              nameCtrl.text = emp.fullName;
                              deptCtrl.text = emp.department;
                              posCtrl.text = emp.position;
                              phoneCtrl.text = emp.phone ?? '';
                              emailCtrl.text = emp.email ?? '';
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'ชื่อ - นามสกุล *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CpoMemberRole>(
                      decoration: const InputDecoration(labelText: 'ตำแหน่งใน คปอ. ตามกฎหมาย *', border: OutlineInputBorder()),
                      initialValue: selectedRole,
                      items: CpoMemberRole.values
                          .map((r) => DropdownMenuItem(value: r, child: Text(r.thaiLabel)))
                          .toList(),
                      onChanged: (r) {
                        if (r != null) setDlgState(() => selectedRole = r);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: deptCtrl,
                            decoration: const InputDecoration(labelText: 'แผนก/หน่วยงาน', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: posCtrl,
                            decoration: const InputDecoration(labelText: 'ตำแหน่งงานในบริษัท', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: phoneCtrl,
                            decoration: const InputDecoration(labelText: 'เบอร์โทรศัพท์', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: emailCtrl,
                            decoration: const InputDecoration(labelText: 'อีเมล', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateCtrl,
                      decoration: const InputDecoration(labelText: 'วันที่ได้รับการแต่งตั้ง (YYYY-MM-DD)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;

                  final m = CpoMemberModel(
                    id: member?.id,
                    termId: termId,
                    employeeId: selectedEmpId,
                    fullName: nameCtrl.text.trim(),
                    department: deptCtrl.text.trim().isNotEmpty ? deptCtrl.text.trim() : null,
                    companyPosition: posCtrl.text.trim().isNotEmpty ? posCtrl.text.trim() : null,
                    phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                    email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                    cpoRole: selectedRole,
                    status: 'ACTIVE',
                  );

                  if (member == null) {
                    await ref.read(cpoAllTermsProvider.notifier).addMember(m);
                  } else {
                    await ref.read(cpoAllTermsProvider.notifier).updateMember(m);
                  }

                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('บันทึก'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteMember(BuildContext context, CpoMemberModel member) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบรายชื่อกรรมการ คปอ.'),
        content: Text('คุณต้องการลบ "${member.fullName}" (${member.cpoRole.thaiLabel}) ออกจากคณะกรรมการ คปอ. หรือไม่?'),
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

    if (confirm == true && member.id != null) {
      await ref.read(cpoAllTermsProvider.notifier).deleteMember(member.id!);
      messenger.showSnackBar(
        const SnackBar(content: Text('ลบรายชื่อกรรมการเรียบร้อยแล้ว')),
      );
    }
  }
}
