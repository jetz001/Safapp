import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cpo_election_model.dart';
import '../../domain/enums/cpo_election_status.dart';
import '../providers/cpo_providers.dart';

class CpoCertificationDialog extends ConsumerStatefulWidget {
  final CpoElectionModel election;

  const CpoCertificationDialog({
    super.key,
    required this.election,
  });

  @override
  ConsumerState<CpoCertificationDialog> createState() => _CpoCertificationDialogState();
}

class _CandidateEditItem {
  final int id;
  final int candidateNo;
  final String fullName;
  final String? department;
  final String? positionTitle;
  final TextEditingController votesCtrl;
  final TextEditingController rankCtrl;
  bool isElected;

  _CandidateEditItem({
    required this.id,
    required this.candidateNo,
    required this.fullName,
    this.department,
    this.positionTitle,
    required this.votesCtrl,
    required this.rankCtrl,
    required this.isElected,
  });
}

class _CpoCertificationDialogState extends ConsumerState<CpoCertificationDialog> {
  late List<_CandidateEditItem> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = widget.election.candidates.map((c) {
      return _CandidateEditItem(
        id: c.id!,
        candidateNo: c.candidateNo,
        fullName: c.fullName,
        department: c.department,
        positionTitle: c.positionTitle,
        votesCtrl: TextEditingController(text: c.votesReceived.toString()),
        rankCtrl: TextEditingController(text: c.rankOrder > 0 ? c.rankOrder.toString() : ''),
        isElected: c.isElected,
      );
    }).toList();

    // Sort by candidate number by default
    _items.sort((a, b) => a.candidateNo.compareTo(b.candidateNo));
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.votesCtrl.dispose();
      item.rankCtrl.dispose();
    }
    super.dispose();
  }

  void _autoTally() {
    setState(() {
      // Sort by votes descending
      final sorted = List<_CandidateEditItem>.from(_items);
      sorted.sort((a, b) {
        final va = int.tryParse(a.votesCtrl.text.trim()) ?? 0;
        final vb = int.tryParse(b.votesCtrl.text.trim()) ?? 0;
        return vb.compareTo(va);
      });

      final quota = widget.election.requiredRepsCount;
      for (int i = 0; i < sorted.length; i++) {
        final item = sorted[i];
        final votes = int.tryParse(item.votesCtrl.text.trim()) ?? 0;
        final rank = i + 1;
        item.rankCtrl.text = rank.toString();
        item.isElected = rank <= quota && votes > 0;
      }
    });
  }

  void _clearAllElected() {
    setState(() {
      for (final item in _items) {
        item.isElected = false;
      }
    });
  }

  Future<void> _saveCertification() async {
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(cpoElectionsProvider.notifier);
      for (final item in _items) {
        final original = widget.election.candidates.firstWhere((c) => c.id == item.id);
        final votes = int.tryParse(item.votesCtrl.text.trim()) ?? 0;
        final rank = int.tryParse(item.rankCtrl.text.trim()) ?? 0;

        final updated = CpoCandidateModel(
          id: item.id,
          electionId: original.electionId,
          candidateNo: item.candidateNo,
          employeeId: original.employeeId,
          fullName: item.fullName,
          department: item.department,
          positionTitle: item.positionTitle,
          campaignPolicy: original.campaignPolicy,
          votesReceived: votes,
          rankOrder: rank,
          isElected: item.isElected,
          status: item.isElected ? 'ELECTED' : 'QUALIFIED',
          createdAt: original.createdAt,
        );

        await notifier.updateCandidate(updated);
      }

      // Update election status to completed if at least one person is certified
      final anyElected = _items.any((item) => item.isElected);
      if (anyElected && widget.election.status.index < CpoElectionStatus.completed.index) {
        final updatedElection = widget.election.copyWith(
          status: CpoElectionStatus.completed,
        );
        await notifier.saveElection(updatedElection);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกการปรับแก้และรับรองผลการเลือกตั้งสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final electedCount = _items.where((i) => i.isElected).length;
    final quota = widget.election.requiredRepsCount;
    final quotaMatched = electedCount == quota;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.verified_outlined, color: Colors.purple.shade800),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'จัดการ & ปรับแก้ผลการรับรองผู้แทน คปอ.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'รอบ: ${widget.election.electionCode} (${widget.election.electionTitle})',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 680,
        height: 520,
        child: Column(
          children: [
            // Status & Quota Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: quotaMatched ? Colors.green.shade50 : Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: quotaMatched ? Colors.green.shade200 : Colors.purple.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    quotaMatched ? Icons.check_circle : Icons.info_outline,
                    color: quotaMatched ? Colors.green.shade700 : Colors.purple.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'โควตาผู้แทนลูกจ้างตามกฎหมาย: $quota คน  •  รับรองผลแล้ว: $electedCount คน',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: quotaMatched ? Colors.green.shade900 : Colors.purple.shade900,
                          ),
                        ),
                        Text(
                          quotaMatched
                            ? '✓ จำนวนผู้ได้รับเลือกตั้งตรงตามเกณฑ์โควตาที่กำหนด'
                            : '⚠️ กรุณาเลือกรับรองผลให้ครบตามจำนวนโควตา ($quota คน) หรือปรับแก้ตามความเหมาะสม',
                          style: TextStyle(
                            fontSize: 11,
                            color: quotaMatched ? Colors.green.shade700 : Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _autoTally,
                    icon: const Icon(Icons.flash_on, size: 14),
                    label: const Text('จัดอันดับตามคะแนน', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple.shade800,
                      side: BorderSide(color: Colors.purple.shade400),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: _clearAllElected,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    child: const Text('ล้างทั้งหมด', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Candidates list
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('ยังไม่มีรายชื่อผู้สมัครในรอบนี้', style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (ctx, index) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final item = _items[i];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: item.isElected ? Colors.green.shade50.withValues(alpha: 0.6) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: item.isElected ? Colors.green.shade400 : Colors.grey.shade300,
                              width: item.isElected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: item.isElected ? Colors.green.shade700 : const Color(0xFF1E3A8A),
                                child: Text(
                                  '${item.candidateNo}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (item.isElected) ...[
                                          const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                                          const SizedBox(width: 4),
                                        ],
                                        Expanded(
                                          child: Text(
                                            item.fullName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: item.isElected ? Colors.green.shade900 : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'แผนก: ${item.department ?? "-"} ${item.positionTitle != null ? "• ${item.positionTitle}" : ""}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 95,
                                child: TextFormField(
                                  controller: item.votesCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    labelText: 'คะแนนเสียง',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 75,
                                child: TextFormField(
                                  controller: item.rankCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    labelText: 'อันดับที่',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilterChip(
                                selected: item.isElected,
                                selectedColor: Colors.green.shade600,
                                checkmarkColor: Colors.white,
                                label: Text(
                                  item.isElected ? 'ได้รับเลือกตั้งเป็น คปอ.' : 'ไม่ได้รับเลือก',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: item.isElected ? Colors.white : Colors.grey.shade700,
                                  ),
                                ),
                                onSelected: (val) {
                                  setState(() {
                                    item.isElected = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveCertification,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save, size: 16, color: Colors.white),
          label: const Text('บันทึกผลการรับรอง', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ],
    );
  }
}
