import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cpo_election_model.dart';
import '../../domain/enums/cpo_election_status.dart';
import '../providers/cpo_providers.dart';
import '../../../employee/presentation/providers/employee_providers.dart';

class CpoElectionWizardDialog extends ConsumerStatefulWidget {
  final CpoElectionModel? existingElection;

  const CpoElectionWizardDialog({super.key, this.existingElection});

  @override
  ConsumerState<CpoElectionWizardDialog> createState() => _CpoElectionWizardDialogState();
}

class _CpoElectionWizardDialogState extends ConsumerState<CpoElectionWizardDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _annDateCtrl;
  late TextEditingController _voteDateCtrl;
  late TextEditingController _repsCtrl;
  late TextEditingController _votersCtrl;

  // New Officer form
  final _officerNameCtrl = TextEditingController();
  final _officerDeptCtrl = TextEditingController();
  String _officerRole = 'MEMBER';

  // New Candidate form
  final _candNameCtrl = TextEditingController();
  final _candDeptCtrl = TextEditingController();
  final _candPolicyCtrl = TextEditingController();

  CpoElectionStatus _status = CpoElectionStatus.draft;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existingElection;
    final now = DateTime.now();
    final yearTh = (now.year + 543).toString();

    _codeCtrl = TextEditingController(text: e?.electionCode ?? 'ELC-${now.year}-${now.millisecondsSinceEpoch.toString().substring(9)}');
    _titleCtrl = TextEditingController(text: e?.electionTitle ?? 'การเลือกตั้งผู้แทนลูกจ้างเป็นกรรมการ คปอ. วาระปี $yearTh');
    _yearCtrl = TextEditingController(text: e?.termYear ?? yearTh);
    _annDateCtrl = TextEditingController(text: e?.announcementDate ?? now.toIso8601String().substring(0, 10));
    final defaultVote = now.add(const Duration(days: 15)).toIso8601String().substring(0, 10);
    _voteDateCtrl = TextEditingController(text: e?.votingDate ?? defaultVote);
    _repsCtrl = TextEditingController(text: e != null ? e.requiredRepsCount.toString() : '2');
    _votersCtrl = TextEditingController(text: e != null ? e.eligibleVotersCount.toString() : '150');

    if (e != null) {
      _status = e.status;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _titleCtrl.dispose();
    _yearCtrl.dispose();
    _annDateCtrl.dispose();
    _voteDateCtrl.dispose();
    _repsCtrl.dispose();
    _votersCtrl.dispose();
    _officerNameCtrl.dispose();
    _officerDeptCtrl.dispose();
    _candNameCtrl.dispose();
    _candDeptCtrl.dispose();
    _candPolicyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveElection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final reps = int.tryParse(_repsCtrl.text.trim()) ?? 2;
      final voters = int.tryParse(_votersCtrl.text.trim()) ?? 0;

      final model = CpoElectionModel(
        id: widget.existingElection?.id,
        electionCode: _codeCtrl.text.trim(),
        electionTitle: _titleCtrl.text.trim(),
        termYear: _yearCtrl.text.trim(),
        announcementDate: _annDateCtrl.text.trim(),
        votingDate: _voteDateCtrl.text.trim(),
        requiredRepsCount: reps,
        eligibleVotersCount: voters,
        status: _status,
        officers: widget.existingElection?.officers ?? const [],
        candidates: widget.existingElection?.candidates ?? const [],
      );

      final id = await ref.read(cpoElectionsProvider.notifier).saveElection(model);

      if (mounted) {
        Navigator.pop(context, id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลการเลือกตั้ง กกต. สำเร็จ'), backgroundColor: Colors.green),
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

  Future<void> _addOfficer() async {
    if (_officerNameCtrl.text.trim().isEmpty) return;
    final electionId = widget.existingElection?.id;
    if (electionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากดบันทึกการเลือกตั้งก่อนเพิ่ม กกต.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final officer = CpoElectionOfficerModel(
      electionId: electionId,
      officerName: _officerNameCtrl.text.trim(),
      department: _officerDeptCtrl.text.trim().isEmpty ? null : _officerDeptCtrl.text.trim(),
      officerRole: _officerRole,
    );

    await ref.read(cpoElectionsProvider.notifier).addOfficer(officer);
    _officerNameCtrl.clear();
    _officerDeptCtrl.clear();
    setState(() {});
  }

  Future<void> _addCandidate() async {
    if (_candNameCtrl.text.trim().isEmpty) return;
    final electionId = widget.existingElection?.id;
    if (electionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากดบันทึกการเลือกตั้งก่อนเพิ่มผู้สมัคร'), backgroundColor: Colors.orange),
      );
      return;
    }

    final currentCandidates = widget.existingElection?.candidates ?? [];
    final nextNo = currentCandidates.isEmpty ? 1 : currentCandidates.map((c) => c.candidateNo).reduce((a, b) => a > b ? a : b) + 1;

    final candidate = CpoCandidateModel(
      electionId: electionId,
      candidateNo: nextNo,
      fullName: _candNameCtrl.text.trim(),
      department: _candDeptCtrl.text.trim().isEmpty ? null : _candDeptCtrl.text.trim(),
      campaignPolicy: _candPolicyCtrl.text.trim().isEmpty ? null : _candPolicyCtrl.text.trim(),
    );

    await ref.read(cpoElectionsProvider.notifier).addCandidate(candidate);
    _candNameCtrl.clear();
    _candDeptCtrl.clear();
    _candPolicyCtrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);
    final employees = employeesAsync.asData?.value ?? [];

    final election = widget.existingElection;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.how_to_vote, color: Colors.amber.shade900),
          ),
          const SizedBox(width: 12),
          Text(election != null ? 'จัดการการเลือกตั้ง & กกต. (${election.electionCode})' : 'จัดตั้งคณะกรรมการดำเนินการเลือกตั้ง (กกต.) & รอบเลือกตั้งใหม่'),
        ],
      ),
      content: SizedBox(
        width: 750,
        height: 580,
        child: Form(
          key: _formKey,
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Color(0xFF1E3A8A),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFF1E3A8A),
                  tabs: [
                    Tab(icon: Icon(Icons.info_outline), text: 'ข้อมูลรอบเลือกตั้ง'),
                    Tab(icon: Icon(Icons.badge_outlined), text: 'คณะกรรมการ กกต.'),
                    Tab(icon: Icon(Icons.person_add_alt), text: 'ผู้สมัครรับเลือกตั้ง'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: General Info
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: _codeCtrl,
                                    decoration: const InputDecoration(labelText: 'รหัสรอบเลือกตั้ง *', border: OutlineInputBorder()),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'ระบุรหัส' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: _yearCtrl,
                                    decoration: const InputDecoration(labelText: 'วาระปี พ.ศ. *', border: OutlineInputBorder()),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'ระบุปี' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _titleCtrl,
                              decoration: const InputDecoration(labelText: 'ชื่องานเลือกตั้ง *', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.trim().isEmpty ? 'ระบุชื่อ' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _annDateCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'วันที่ออกประกาศ กกต. *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.campaign),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _voteDateCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'วันลงคะแนนเสียงเลือกตั้ง *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.how_to_vote),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _repsCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'จำนวนผู้แทนลูกจ้างที่ต้องการเลือกตั้ง (คน) *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.people),
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'ระบุจำนวน' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _votersCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'จำนวนลูกจ้างผู้มีสิทธิเลือกตั้งทั้งหมด *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.groups),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<CpoElectionStatus>(
                              value: _status,
                              decoration: const InputDecoration(labelText: 'สถานะขั้นตอนการเลือกตั้ง', border: OutlineInputBorder()),
                              items: CpoElectionStatus.values.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Row(
                                    children: [
                                      Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      Text(s.labelTh),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _status = v);
                              },
                            ),
                          ],
                        ),
                      ),

                      // Tab 2: Officers (กกต.)
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Autocomplete<String>(
                                  optionsBuilder: (val) {
                                    if (val.text.isEmpty) return const [];
                                    return employees.map((e) => e.fullName).where((n) => n.toLowerCase().contains(val.text.toLowerCase()));
                                  },
                                  onSelected: (val) {
                                    _officerNameCtrl.text = val;
                                    final emp = employees.firstWhere((e) => e.fullName == val, orElse: () => employees.first);
                                    if (emp.department != null) _officerDeptCtrl.text = emp.department!;
                                  },
                                  fieldViewBuilder: (ctx, ctrl, focus, onSub) {
                                    ctrl.addListener(() => _officerNameCtrl.text = ctrl.text);
                                    return TextFormField(
                                      controller: ctrl,
                                      focusNode: focus,
                                      decoration: const InputDecoration(labelText: 'ชื่อกรรมการ กกต.', border: OutlineInputBorder(), isDense: true),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  value: _officerRole,
                                  decoration: const InputDecoration(labelText: 'หน้าที่', border: OutlineInputBorder(), isDense: true),
                                  items: const [
                                    DropdownMenuItem(value: 'CHAIR', child: Text('ประธาน กกต.')),
                                    DropdownMenuItem(value: 'SECRETARY', child: Text('เลขา กกต.')),
                                    DropdownMenuItem(value: 'MEMBER', child: Text('กรรมการ กกต.')),
                                  ],
                                  onChanged: (v) => setState(() => _officerRole = v ?? 'MEMBER'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _addOfficer,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
                                child: const Text('เพิ่ม กกต.', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: election == null || election.officers.isEmpty
                                ? const Center(child: Text('ยังไม่มีรายชื่อคณะกรรมการ กกต. (กดบันทึกรอบเลือกตั้งก่อนเพิ่ม)', style: TextStyle(color: Colors.grey)))
                                : ListView.builder(
                                    itemCount: election.officers.length,
                                    itemBuilder: (ctx, i) {
                                      final off = election.officers[i];
                                      return Card(
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: off.officerRole == 'CHAIR' ? Colors.amber.shade800 : Colors.blue.shade800,
                                            child: const Icon(Icons.person, color: Colors.white, size: 18),
                                          ),
                                          title: Text(off.officerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text('${off.roleLabel} • แผนก: ${off.department ?? "-"}'),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                            onPressed: () => ref.read(cpoElectionsProvider.notifier).deleteOfficer(off.id!),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),

                      // Tab 3: Candidates
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Autocomplete<String>(
                                  optionsBuilder: (val) {
                                    if (val.text.isEmpty) return const [];
                                    return employees.map((e) => e.fullName).where((n) => n.toLowerCase().contains(val.text.toLowerCase()));
                                  },
                                  onSelected: (val) {
                                    _candNameCtrl.text = val;
                                    final emp = employees.firstWhere((e) => e.fullName == val, orElse: () => employees.first);
                                    if (emp.department != null) _candDeptCtrl.text = emp.department!;
                                  },
                                  fieldViewBuilder: (ctx, ctrl, focus, onSub) {
                                    ctrl.addListener(() => _candNameCtrl.text = ctrl.text);
                                    return TextFormField(
                                      controller: ctrl,
                                      focusNode: focus,
                                      decoration: const InputDecoration(labelText: 'ชื่อผู้สมัครรับเลือกตั้ง', border: OutlineInputBorder(), isDense: true),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _candDeptCtrl,
                                  decoration: const InputDecoration(labelText: 'แผนก/ฝ่าย', border: OutlineInputBorder(), isDense: true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _addCandidate,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                                child: const Text('เพิ่มผู้สมัคร', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: election == null || election.candidates.isEmpty
                                ? const Center(child: Text('ยังไม่มีรายชื่อผู้สมัครรับเลือกตั้ง (กดบันทึกรอบเลือกตั้งก่อนเพิ่ม)', style: TextStyle(color: Colors.grey)))
                                : ListView.builder(
                                    itemCount: election.candidates.length,
                                    itemBuilder: (ctx, i) {
                                      final c = election.candidates[i];
                                      return Card(
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: c.isElected ? Colors.green : Colors.blueGrey,
                                            child: Text('เบอร์ ${c.candidateNo}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                          title: Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text('แผนก: ${c.department ?? "-"} • ได้คะแนน: ${c.votesReceived} เสียง ${c.isElected ? "(ได้รับเลือกตั้งเป็น คปอ.)" : ""}'),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                            onPressed: () => ref.read(cpoElectionsProvider.notifier).deleteCandidate(c.id!),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveElection,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('บันทึกรอบการเลือกตั้ง', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
