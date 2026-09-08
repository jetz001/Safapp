import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cpo_election_model.dart';
import '../../domain/enums/cpo_election_status.dart';
import '../providers/cpo_providers.dart';

class CpoBallotDialog extends ConsumerStatefulWidget {
  final CpoElectionModel election;

  const CpoBallotDialog({super.key, required this.election});

  @override
  ConsumerState<CpoBallotDialog> createState() => _CpoBallotDialogState();
}

class _CpoBallotDialogState extends ConsumerState<CpoBallotDialog> {
  final Map<int, TextEditingController> _voteCtrls = {};
  late TextEditingController _invalidCtrl;
  late TextEditingController _noVoteCtrl;
  int? _selectedCandidateIdForKiosk;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final c in widget.election.candidates) {
      _voteCtrls[c.id!] = TextEditingController(text: c.votesReceived.toString());
    }
    _invalidCtrl = TextEditingController(text: widget.election.invalidBallotsCount.toString());
    _noVoteCtrl = TextEditingController(text: widget.election.noVoteBallotsCount.toString());
  }

  @override
  void dispose() {
    for (final ctrl in _voteCtrls.values) {
      ctrl.dispose();
    }
    _invalidCtrl.dispose();
    _noVoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveTally() async {
    setState(() => _isSaving = true);
    try {
      int totalValid = 0;
      for (final c in widget.election.candidates) {
        final votes = int.tryParse(_voteCtrls[c.id!]?.text.trim() ?? '0') ?? 0;
        totalValid += votes;
        final updated = c.copyWith(votesReceived: votes);
        await ref.read(cpoElectionsProvider.notifier).updateCandidate(updated);
      }

      final invalid = int.tryParse(_invalidCtrl.text.trim()) ?? 0;
      final noVote = int.tryParse(_noVoteCtrl.text.trim()) ?? 0;
      final totalCast = totalValid + invalid + noVote;

      final updatedElection = widget.election.copyWith(
        validBallotsCount: totalValid,
        invalidBallotsCount: invalid,
        noVoteBallotsCount: noVote,
        totalBallotsCast: totalCast,
        status: CpoElectionStatus.tallying,
      );

      await ref.read(cpoElectionsProvider.notifier).saveElection(updatedElection);
      await ref.read(cpoElectionsProvider.notifier).tallyResults(widget.election.id!);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('นับคะแนนและจัดอันดับผลการเลือกตั้งสำเร็จแล้ว'), backgroundColor: Colors.green),
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

  Future<void> _castDigitalVote() async {
    if (_selectedCandidateIdForKiosk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกผู้สมัครที่ต้องการลงคะแนน หรือเลือกไม่ประสงค์ลงคะแนน'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_selectedCandidateIdForKiosk == -1) {
        // No vote
        final curNoVote = widget.election.noVoteBallotsCount + 1;
        final curCast = widget.election.totalBallotsCast + 1;
        final updated = widget.election.copyWith(
          noVoteBallotsCount: curNoVote,
          totalBallotsCast: curCast,
          status: CpoElectionStatus.voting,
        );
        await ref.read(cpoElectionsProvider.notifier).saveElection(updated);
      } else {
        final cand = widget.election.candidates.firstWhere((c) => c.id == _selectedCandidateIdForKiosk);
        final curVotes = cand.votesReceived + 1;
        await ref.read(cpoElectionsProvider.notifier).updateCandidate(cand.copyWith(votesReceived: curVotes));

        final curValid = widget.election.validBallotsCount + 1;
        final curCast = widget.election.totalBallotsCast + 1;
        final updated = widget.election.copyWith(
          validBallotsCount: curValid,
          totalBallotsCast: curCast,
          status: CpoElectionStatus.voting,
        );
        await ref.read(cpoElectionsProvider.notifier).saveElection(updated);
      }

      await ref.read(cpoElectionsProvider.notifier).tallyResults(widget.election.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกการลงคะแนนเสียงเรียบร้อย ขอบคุณสำหรับการใช้สิทธิ'), backgroundColor: Colors.green),
        );
        setState(() => _selectedCandidateIdForKiosk = null);
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
    final e = widget.election;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.ballot, color: Colors.purple.shade800),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('ระบบบันทึกคะแนน & คูหาเลือกตั้ง (${e.electionTitle})')),
        ],
      ),
      content: SizedBox(
        width: 700,
        height: 520,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                labelColor: Color(0xFF1E3A8A),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF1E3A8A),
                tabs: [
                  Tab(icon: Icon(Icons.touch_app), text: 'คูหาลงคะแนนดิจิทัล (Digital Kiosk)'),
                  Tab(icon: Icon(Icons.fact_check), text: 'กรอกผลคะแนนนับบัตรจริง (Paper Tally)'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Kiosk Mode
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFF1E3A8A), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ผู้มีสิทธิเลือกตั้ง ๑ คน สามารถคลิกเลือกผู้สมัคร ๑ ท่าน แล้วกดปุ่ม \"ยืนยันลงคะแนนเสียง\" ด้านล่าง',
                                  style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: e.candidates.isEmpty
                              ? const Center(child: Text('ยังไม่มีรายชื่อผู้สมัครรับเลือกตั้ง'))
                              : GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 2.6,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                                  itemCount: e.candidates.length + 1,
                                  itemBuilder: (ctx, i) {
                                    if (i == e.candidates.length) {
                                      // No vote option
                                      final isSelected = _selectedCandidateIdForKiosk == -1;
                                      return InkWell(
                                        onTap: () => setState(() => _selectedCandidateIdForKiosk = -1),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.grey.shade300 : Colors.grey.shade100,
                                            border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300, width: 2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: Colors.grey.shade600,
                                                child: const Icon(Icons.block, color: Colors.white, size: 20),
                                              ),
                                              const SizedBox(width: 12),
                                              const Expanded(
                                                child: Text('ไม่ประสงค์ลงคะแนนเสียง (Vote No)', style: TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    final cand = e.candidates[i];
                                    final isSelected = _selectedCandidateIdForKiosk == cand.id;

                                    return InkWell(
                                      onTap: () => setState(() => _selectedCandidateIdForKiosk = cand.id),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.blue.shade50 : Colors.white,
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
                                            width: isSelected ? 2.5 : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade700,
                                              child: Text('เบอร์ ${cand.candidateNo}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(cand.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                  Text('แผนก: ${cand.department ?? "-"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                                  Text('คะแนนสะสม: ${cand.votesReceived} เสียง', style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _castDigitalVote,
                            icon: const Icon(Icons.how_to_vote),
                            label: const Text('ยืนยันการลงคะแนนเสียง (Submit Vote)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Tab 2: Paper Tally
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('กรอกผลคะแนนจากใบนับคะแนน (ตามคู่มือ กสร. ๑/๒๕๖๑ หน้า ๒๗)', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Table(
                            border: TableBorder.all(color: Colors.grey.shade300),
                            columnWidths: const {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(3),
                              2: FlexColumnWidth(2),
                              3: FlexColumnWidth(2),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(color: Colors.grey.shade200),
                                children: const [
                                  Padding(padding: EdgeInsets.all(6), child: Text('เบอร์', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Padding(padding: EdgeInsets.all(6), child: Text('ชื่อผู้สมัคร', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Padding(padding: EdgeInsets.all(6), child: Text('แผนก', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Padding(padding: EdgeInsets.all(6), child: Text('คะแนนที่ได้', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                              ),
                              for (final cand in e.candidates)
                                TableRow(
                                  children: [
                                    Padding(padding: const EdgeInsets.all(8), child: Text('${cand.candidateNo}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    Padding(padding: const EdgeInsets.all(8), child: Text(cand.fullName)),
                                    Padding(padding: const EdgeInsets.all(8), child: Text(cand.department ?? '-')),
                                    Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: TextField(
                                        controller: _voteCtrls[cand.id!],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _invalidCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'จำนวนบัตรเสีย (ใบ)', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _noVoteCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'ไม่ประสงค์ลงคะแนน (ใบ)', border: OutlineInputBorder()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _saveTally,
                              icon: const Icon(Icons.calculate),
                              label: const Text('บันทึกผลการนับคะแนน & ประกาศผลเลือกตั้ง'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
      ],
    );
  }
}
