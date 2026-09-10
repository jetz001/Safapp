import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cpo_election_model.dart';
import '../../domain/enums/cpo_election_status.dart';
import '../providers/cpo_providers.dart';
import '../../../employee/presentation/providers/employee_providers.dart';
import '../../../employee/domain/models/employee_models.dart';

class CpoElectionWizardDialog extends ConsumerStatefulWidget {
  final CpoElectionModel? existingElection;
  final int initialTabIndex;

  const CpoElectionWizardDialog({
    super.key,
    this.existingElection,
    this.initialTabIndex = 0,
  });

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
  int? _selectedOfficerEmpId;
  String? _officerPosition;
  int? _editingOfficerId;

  // New Candidate form
  final _candNameCtrl = TextEditingController();
  final _candDeptCtrl = TextEditingController();
  final _candPolicyCtrl = TextEditingController();
  int? _selectedCandEmpId;
  String? _candPosition;
  int? _editingCandId;

  CpoElectionStatus _status = CpoElectionStatus.draft;
  bool _isSaving = false;
  int? _electionId;

  @override
  void initState() {
    super.initState();
    final e = widget.existingElection;
    final now = DateTime.now();
    final yearTh = (now.year + 543).toString();

    _electionId = e?.id;
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

  Future<int?> _ensureElectionSaved() async {
    if (_electionId != null) return _electionId;
    final reps = int.tryParse(_repsCtrl.text.trim()) ?? 2;
    final voters = int.tryParse(_votersCtrl.text.trim()) ?? 0;

    final model = CpoElectionModel(
      id: _electionId,
      electionCode: _codeCtrl.text.trim(),
      electionTitle: _titleCtrl.text.trim(),
      termYear: _yearCtrl.text.trim(),
      announcementDate: _annDateCtrl.text.trim(),
      votingDate: _voteDateCtrl.text.trim(),
      requiredRepsCount: reps,
      eligibleVotersCount: voters,
      status: _status,
      officers: const [],
      candidates: const [],
    );
    _electionId = await ref.read(cpoElectionsProvider.notifier).saveElection(model);
    return _electionId;
  }

  Future<void> _saveElection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final reps = int.tryParse(_repsCtrl.text.trim()) ?? 2;
      final voters = int.tryParse(_votersCtrl.text.trim()) ?? 0;

      final currentElections = ref.read(cpoElectionsProvider).asData?.value ?? [];
      final existing = _electionId != null
          ? currentElections.firstWhere((e) => e.id == _electionId, orElse: () => widget.existingElection ?? const CpoElectionModel(electionCode: '', electionTitle: '', termYear: '', votingDate: ''))
          : widget.existingElection;

      final model = CpoElectionModel(
        id: _electionId,
        electionCode: _codeCtrl.text.trim(),
        electionTitle: _titleCtrl.text.trim(),
        termYear: _yearCtrl.text.trim(),
        announcementDate: _annDateCtrl.text.trim(),
        votingDate: _voteDateCtrl.text.trim(),
        requiredRepsCount: reps,
        eligibleVotersCount: voters,
        status: _status,
        officers: existing?.officers ?? const [],
        candidates: existing?.candidates ?? const [],
      );

      final id = await ref.read(cpoElectionsProvider.notifier).saveElection(model);
      _electionId = id;

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
    if (_officerNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ กรุณาเลือกพนักงานจากทะเบียน หรือระบุชื่อ-นามสกุล กกต. ก่อนกดเพิ่ม'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final electionId = await _ensureElectionSaved();
    if (electionId == null) return;

    if (_editingOfficerId != null) {
      final officer = CpoElectionOfficerModel(
        id: _editingOfficerId,
        electionId: electionId,
        employeeId: _selectedOfficerEmpId,
        officerName: _officerNameCtrl.text.trim(),
        department: _officerDeptCtrl.text.trim().isEmpty ? null : _officerDeptCtrl.text.trim(),
        positionTitle: _officerPosition,
        officerRole: _officerRole,
      );
      await ref.read(cpoElectionsProvider.notifier).updateOfficer(officer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('แก้ไขข้อมูล กกต. สำเร็จ'), backgroundColor: Colors.green),
        );
      }
      _editingOfficerId = null;
    } else {
      final officer = CpoElectionOfficerModel(
        electionId: electionId,
        employeeId: _selectedOfficerEmpId,
        officerName: _officerNameCtrl.text.trim(),
        department: _officerDeptCtrl.text.trim().isEmpty ? null : _officerDeptCtrl.text.trim(),
        positionTitle: _officerPosition,
        officerRole: _officerRole,
      );
      await ref.read(cpoElectionsProvider.notifier).addOfficer(officer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เพิ่มกรรมการ กกต. สำเร็จ'), backgroundColor: Colors.green),
        );
      }
    }

    _officerNameCtrl.clear();
    _officerDeptCtrl.clear();
    _selectedOfficerEmpId = null;
    _officerPosition = null;
    setState(() {});
  }

  Future<void> _addCandidate() async {
    if (_candNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ กรุณาเลือกพนักงานจากทะเบียน หรือระบุชื่อ-นามสกุล ผู้สมัครก่อนกดเพิ่ม'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final electionId = await _ensureElectionSaved();
    if (electionId == null) return;

    final currentElections = ref.read(cpoElectionsProvider).asData?.value ?? [];
    final current = currentElections.firstWhere((e) => e.id == electionId, orElse: () => widget.existingElection ?? const CpoElectionModel(electionCode: '', electionTitle: '', termYear: '', votingDate: ''));
    final currentCandidates = current.candidates;

    if (_editingCandId != null) {
      final existing = currentCandidates.firstWhere(
        (c) => c.id == _editingCandId,
        orElse: () => const CpoCandidateModel(electionId: 0, candidateNo: 1, fullName: ''),
      );
      final candidate = CpoCandidateModel(
        id: _editingCandId,
        electionId: electionId,
        candidateNo: existing.candidateNo,
        employeeId: _selectedCandEmpId,
        fullName: _candNameCtrl.text.trim(),
        department: _candDeptCtrl.text.trim().isEmpty ? null : _candDeptCtrl.text.trim(),
        positionTitle: _candPosition,
        campaignPolicy: _candPolicyCtrl.text.trim().isEmpty ? null : _candPolicyCtrl.text.trim(),
        votesReceived: existing.votesReceived,
        rankOrder: existing.rankOrder,
        isElected: existing.isElected,
        status: existing.status,
      );
      await ref.read(cpoElectionsProvider.notifier).updateCandidate(candidate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('แก้ไขข้อมูลผู้สมัครรับเลือกตั้งสำเร็จ'), backgroundColor: Colors.green),
        );
      }
      _editingCandId = null;
    } else {
      final nextNo = currentCandidates.isEmpty ? 1 : currentCandidates.map((c) => c.candidateNo).reduce((a, b) => a > b ? a : b) + 1;
      final candidate = CpoCandidateModel(
        electionId: electionId,
        candidateNo: nextNo,
        employeeId: _selectedCandEmpId,
        fullName: _candNameCtrl.text.trim(),
        department: _candDeptCtrl.text.trim().isEmpty ? null : _candDeptCtrl.text.trim(),
        positionTitle: _candPosition,
        campaignPolicy: _candPolicyCtrl.text.trim().isEmpty ? null : _candPolicyCtrl.text.trim(),
      );
      await ref.read(cpoElectionsProvider.notifier).addCandidate(candidate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เพิ่มผู้สมัครรับเลือกตั้งสำเร็จ'), backgroundColor: Colors.green),
        );
      }
    }

    _candNameCtrl.clear();
    _candDeptCtrl.clear();
    _candPolicyCtrl.clear();
    _selectedCandEmpId = null;
    _candPosition = null;
    setState(() {});
  }

  Future<void> _showEmployeeSearchDialog({
    required List<Employee> employees,
    required Function(Employee emp) onSelected,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = employees.where((e) {
              final q = query.toLowerCase().trim();
              if (q.isEmpty) return true;
              return e.fullName.toLowerCase().contains(q) ||
                  e.employeeCode.toLowerCase().contains(q) ||
                  (e.department.toLowerCase().contains(q)) ||
                  (e.position.toLowerCase().contains(q));
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.badge_outlined, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ค้นหาพนักงานในระบบ (${employees.length} รายชื่อ)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ชื่อ, รหัสพนักงาน, แผนก หรือตำแหน่ง...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setDialogState(() => query = ''),
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (val) => setDialogState(() => query = val),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('ไม่พบรายชื่อพนักงานที่ค้นหา', style: TextStyle(color: Colors.grey)))
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final emp = filtered[i];
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                                    child: Text(
                                      emp.employeeCode.length >= 2 ? emp.employeeCode.substring(emp.employeeCode.length - 2) : emp.employeeCode,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                    ),
                                  ),
                                  title: Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: Text('รหัส ${emp.employeeCode} • ${emp.department} • ${emp.position}', style: const TextStyle(fontSize: 11)),
                                  trailing: const Icon(Icons.check_circle_outline, color: Color(0xFF1E3A8A), size: 20),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    onSelected(emp);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);
    final employees = employeesAsync.asData?.value ?? [];

    final allElections = ref.watch(cpoElectionsProvider).asData?.value ?? [];
    final election = _electionId != null
        ? allElections.firstWhere(
            (e) => e.id == _electionId,
            orElse: () => widget.existingElection ?? const CpoElectionModel(electionCode: '', electionTitle: '', termYear: '', votingDate: ''),
          )
        : widget.existingElection;

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
        width: 780,
        height: 600,
        child: Form(
          key: _formKey,
          child: DefaultTabController(
            length: 3,
            initialIndex: widget.initialTabIndex,
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.how_to_reg, size: 18, color: Colors.amber.shade900),
                                    const SizedBox(width: 6),
                                    Text(
                                      'เลือกรายชื่อจากทะเบียนพนักงาน หรือพิมพ์ระบุเอง',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                    ),
                                    const Spacer(),
                                    if (_selectedOfficerEmpId != null)
                                      TextButton.icon(
                                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                                        icon: const Icon(Icons.clear, size: 14, color: Colors.red),
                                        label: const Text('ล้างการเลือก', style: TextStyle(fontSize: 11, color: Colors.red)),
                                        onPressed: () {
                                          setState(() {
                                            _selectedOfficerEmpId = null;
                                            _officerPosition = null;
                                            _officerNameCtrl.clear();
                                            _officerDeptCtrl.clear();
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int?>(
                                        value: employees.any((e) => e.id == _selectedOfficerEmpId) ? _selectedOfficerEmpId : null,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'ค้นหา/เลือกจากทะเบียนพนักงานในระบบ',
                                          prefixIcon: Icon(Icons.badge_outlined, color: Colors.amber, size: 20),
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        ),
                                        items: [
                                          DropdownMenuItem<int?>(
                                            value: null,
                                            child: Text('— แตะเลือกจากพนักงาน (${employees.length} คน) หรือพิมพ์เอง —', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                          ),
                                          ...employees.map((e) => DropdownMenuItem<int?>(
                                            value: e.id,
                                            child: Text('[${e.employeeCode}] ${e.fullName} (${e.department})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                          )),
                                        ],
                                        onChanged: (v) {
                                          setState(() {
                                            _selectedOfficerEmpId = v;
                                            if (v != null) {
                                              final emp = employees.firstWhere((e) => e.id == v);
                                              _officerNameCtrl.text = emp.fullName;
                                              _officerDeptCtrl.text = emp.department;
                                              _officerPosition = emp.position;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.search, size: 16),
                                      label: const Text('ค้นหา', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.amber.shade900,
                                        side: BorderSide(color: Colors.amber.shade700),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                      onPressed: () => _showEmployeeSearchDialog(
                                        employees: employees,
                                        onSelected: (emp) {
                                          setState(() {
                                            _selectedOfficerEmpId = emp.id;
                                            _officerNameCtrl.text = emp.fullName;
                                            _officerDeptCtrl.text = emp.department;
                                            _officerPosition = emp.position;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: _officerNameCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'ชื่อ-นามสกุล กกต. *',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: _officerDeptCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'แผนก/ฝ่าย',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: DropdownButtonFormField<String>(
                                        value: _officerRole,
                                        decoration: const InputDecoration(
                                          labelText: 'หน้าที่ กกต.',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: 'CHAIR', child: Text('ประธาน กกต.', style: TextStyle(fontSize: 12))),
                                          DropdownMenuItem(value: 'SECRETARY', child: Text('เลขา กกต.', style: TextStyle(fontSize: 12))),
                                          DropdownMenuItem(value: 'MEMBER', child: Text('กรรมการ กกต.', style: TextStyle(fontSize: 12))),
                                        ],
                                        onChanged: (v) => setState(() => _officerRole = v ?? 'MEMBER'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: _addOfficer,
                                      icon: Icon(_editingOfficerId != null ? Icons.save : Icons.add, size: 16, color: Colors.white),
                                      label: Text(
                                        _editingOfficerId != null ? 'บันทึกแก้ไข' : 'เพิ่ม กกต.',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _editingOfficerId != null ? Colors.blue.shade800 : Colors.amber.shade800,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                    if (_editingOfficerId != null) ...[
                                      const SizedBox(width: 4),
                                      IconButton(
                                        tooltip: 'ยกเลิกการแก้ไข',
                                        icon: const Icon(Icons.close, color: Colors.grey),
                                        onPressed: () {
                                          setState(() {
                                            _editingOfficerId = null;
                                            _officerNameCtrl.clear();
                                            _officerDeptCtrl.clear();
                                            _selectedOfficerEmpId = null;
                                            _officerPosition = null;
                                          });
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: election == null || election.officers.isEmpty
                                ? const Center(child: Text('ยังไม่มีรายชื่อคณะกรรมการ กกต. (สามารถเลือกหรือกรอกข้อมูลด้านบนแล้วกดเพิ่ม)', style: TextStyle(color: Colors.grey)))
                                : ListView.builder(
                                    itemCount: election.officers.length,
                                    itemBuilder: (ctx, i) {
                                      final off = election.officers[i];
                                      final isBeingEdited = _editingOfficerId == off.id;
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        color: isBeingEdited ? Colors.amber.shade50 : null,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: isBeingEdited ? BorderSide(color: Colors.amber.shade800, width: 1.5) : BorderSide.none,
                                        ),
                                        child: ListTile(
                                          dense: true,
                                          leading: CircleAvatar(
                                            backgroundColor: off.officerRole == 'CHAIR' ? Colors.amber.shade800 : Colors.blue.shade800,
                                            child: const Icon(Icons.person, color: Colors.white, size: 18),
                                          ),
                                          title: Text(off.officerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text('${off.roleLabel} • แผนก: ${off.department ?? "-"} ${off.positionTitle != null ? "• ตำแหน่ง: ${off.positionTitle}" : ""}'),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'แก้ไข',
                                                icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                                                onPressed: () {
                                                  setState(() {
                                                    _editingOfficerId = off.id;
                                                    _officerNameCtrl.text = off.officerName;
                                                    _officerDeptCtrl.text = off.department ?? '';
                                                    _officerRole = off.officerRole;
                                                    _selectedOfficerEmpId = off.employeeId;
                                                    _officerPosition = off.positionTitle;
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                tooltip: 'ลบ',
                                                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                                onPressed: () => ref.read(cpoElectionsProvider.notifier).deleteOfficer(off.id!),
                                              ),
                                            ],
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person_add_alt_1, size: 18, color: Color(0xFF1E3A8A)),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'เลือกรายชื่อจากทะเบียนพนักงาน หรือพิมพ์ระบุเอง',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                    ),
                                    const Spacer(),
                                    if (_selectedCandEmpId != null)
                                      TextButton.icon(
                                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                                        icon: const Icon(Icons.clear, size: 14, color: Colors.red),
                                        label: const Text('ล้างการเลือก', style: TextStyle(fontSize: 11, color: Colors.red)),
                                        onPressed: () {
                                          setState(() {
                                            _selectedCandEmpId = null;
                                            _candPosition = null;
                                            _candNameCtrl.clear();
                                            _candDeptCtrl.clear();
                                            _candPolicyCtrl.clear();
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int?>(
                                        value: employees.any((e) => e.id == _selectedCandEmpId) ? _selectedCandEmpId : null,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'ค้นหา/เลือกจากทะเบียนพนักงานในระบบ',
                                          prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFF1E3A8A), size: 20),
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        ),
                                        items: [
                                          DropdownMenuItem<int?>(
                                            value: null,
                                            child: Text('— แตะเลือกจากพนักงาน (${employees.length} คน) หรือพิมพ์เอง —', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                          ),
                                          ...employees.map((e) => DropdownMenuItem<int?>(
                                            value: e.id,
                                            child: Text('[${e.employeeCode}] ${e.fullName} (${e.department})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                          )),
                                        ],
                                        onChanged: (v) {
                                          setState(() {
                                            _selectedCandEmpId = v;
                                            if (v != null) {
                                              final emp = employees.firstWhere((e) => e.id == v);
                                              _candNameCtrl.text = emp.fullName;
                                              _candDeptCtrl.text = emp.department;
                                              _candPosition = emp.position;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.search, size: 16),
                                      label: const Text('ค้นหา', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF1E3A8A),
                                        side: const BorderSide(color: Color(0xFF1E3A8A)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                      onPressed: () => _showEmployeeSearchDialog(
                                        employees: employees,
                                        onSelected: (emp) {
                                          setState(() {
                                            _selectedCandEmpId = emp.id;
                                            _candNameCtrl.text = emp.fullName;
                                            _candDeptCtrl.text = emp.department;
                                            _candPosition = emp.position;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: _candNameCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'ชื่อ-นามสกุล ผู้สมัคร *',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: _candDeptCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'แผนก/ฝ่าย',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: _candPolicyCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'นโยบาย/สโลแกน (ถ้ามี)',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: _addCandidate,
                                      icon: Icon(_editingCandId != null ? Icons.save : Icons.add, size: 16, color: Colors.white),
                                      label: Text(
                                        _editingCandId != null ? 'บันทึกแก้ไข' : 'เพิ่มผู้สมัคร',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _editingCandId != null ? Colors.blue.shade800 : const Color(0xFF1E3A8A),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                    if (_editingCandId != null) ...[
                                      const SizedBox(width: 4),
                                      IconButton(
                                        tooltip: 'ยกเลิกการแก้ไข',
                                        icon: const Icon(Icons.close, color: Colors.grey),
                                        onPressed: () {
                                          setState(() {
                                            _editingCandId = null;
                                            _candNameCtrl.clear();
                                            _candDeptCtrl.clear();
                                            _candPolicyCtrl.clear();
                                            _selectedCandEmpId = null;
                                            _candPosition = null;
                                          });
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: election == null || election.candidates.isEmpty
                                ? const Center(child: Text('ยังไม่มีรายชื่อผู้สมัครรับเลือกตั้ง (สามารถเลือกหรือกรอกข้อมูลด้านบนแล้วกดเพิ่ม)', style: TextStyle(color: Colors.grey)))
                                : ListView.builder(
                                    itemCount: election.candidates.length,
                                    itemBuilder: (ctx, i) {
                                      final c = election.candidates[i];
                                      final isBeingEdited = _editingCandId == c.id;
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        color: isBeingEdited ? Colors.blue.shade50 : null,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: isBeingEdited ? BorderSide(color: Colors.blue.shade800, width: 1.5) : BorderSide.none,
                                        ),
                                        child: ListTile(
                                          dense: true,
                                          leading: CircleAvatar(
                                            backgroundColor: c.isElected ? Colors.green : Colors.blueGrey,
                                            child: Text('เบอร์ ${c.candidateNo}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                          title: Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text('แผนก: ${c.department ?? "-"} ${c.positionTitle != null ? "• ตำแหน่ง: ${c.positionTitle}" : ""} • ได้คะแนน: ${c.votesReceived} เสียง ${c.isElected ? "(ได้รับเลือกตั้งเป็น คปอ.)" : ""}'),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'แก้ไข',
                                                icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                                                onPressed: () {
                                                  setState(() {
                                                    _editingCandId = c.id;
                                                    _candNameCtrl.text = c.fullName;
                                                    _candDeptCtrl.text = c.department ?? '';
                                                    _candPolicyCtrl.text = c.campaignPolicy ?? '';
                                                    _selectedCandEmpId = c.employeeId;
                                                    _candPosition = c.positionTitle;
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                tooltip: 'ลบ',
                                                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                                onPressed: () => ref.read(cpoElectionsProvider.notifier).deleteCandidate(c.id!),
                                              ),
                                            ],
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
