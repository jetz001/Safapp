import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cpo_committee_model.dart';
import '../../domain/enums/cpo_member_role.dart';
import '../../domain/services/cpo_statutory_evaluator.dart';
import '../providers/cpo_providers.dart';
import '../../../employee/presentation/providers/employee_providers.dart';
import '../../../risk_assessment/presentation/providers/risk_assessment_providers.dart';

class CpoStructureTab extends ConsumerStatefulWidget {
  const CpoStructureTab({super.key});

  @override
  ConsumerState<CpoStructureTab> createState() => _CpoStructureTabState();
}

class _CpoStructureTabState extends ConsumerState<CpoStructureTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeTermAsync = ref.watch(cpoActiveTermProvider);
    final companyProfile = ref.watch(companyProfileNotifierProvider).asData?.value;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: activeTermAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('เกิดข้อผิดพลาด: $err')),
        data: (term) {
          if (term == null) {
            return _buildNoActiveTermState(context, companyProfile?.employeeCount ?? 100);
          }

          final employeeCount = term.employeeCount > 0 ? term.employeeCount : (companyProfile?.employeeCount ?? 100);
          final quotaResult = CpoStatutoryEvaluator.evaluateQuota(
            employeeCount: employeeCount,
            members: term.members,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTermHeaderCard(context, term, employeeCount),
                const SizedBox(height: 16),
                _buildComplianceBanner(context, quotaResult),
                const SizedBox(height: 20),
                _buildMembersSection(context, term),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoActiveTermState(BuildContext context, int defaultEmployees) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.diversity_3_outlined, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีวาระคณะกรรมการ คปอ. ที่ใช้งานอยู่',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          Text(
            'ตามกฎหมาย กฎกระทรวง จป./คปอ. พ.ศ. ๒๕๖๕ คณะกรรมการ คปอ. มีวาระคราวละ ๒ ปี',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('จัดตั้งวาระ คปอ. ใหม่ (วาระ ๒ ปี)'),
            onPressed: () => _openTermDialog(context, null, defaultEmployees),
          ),
        ],
      ),
    );
  }

  Widget _buildTermHeaderCard(BuildContext context, CpoTermModel term, int employeeCount) {
    final now = DateTime.now();
    DateTime? endDt;
    try {
      endDt = DateTime.parse(term.endDate);
    } catch (_) {}

    final daysRemaining = endDt != null ? endDt.difference(now).inDays : 0;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFF0D9488), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            term.termTitle,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: term.isActive ? Colors.green.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              term.isActive ? 'วาระปัจจุบัน' : 'หมดวาระ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: term.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ช่วงเวลาวาระ ๒ ปี: ${term.startDate} ถึง ${term.endDate} (เหลือเวลา $daysRemaining วัน)',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('แก้ไขวาระ'),
                  onPressed: () => _openTermDialog(context, term, employeeCount),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                  label: const Text('แต่งตั้งกรรมการเพิ่ม'),
                  onPressed: () => _openMemberDialog(context, term.id!, null),
                ),
              ],
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(16),
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
              Icon(icon, color: textCol, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  quota.summaryText,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCol),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quota breakdown chips
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildQuotaChip('ลูกจ้างทั้งหมด', '${quota.employeeCount} คน', Colors.blueGrey),
              _buildQuotaChip('ประธาน คปอ.', '${quota.actualChair}/${quota.requiredChair}', quota.actualChair >= quota.requiredChair ? Colors.teal : Colors.red),
              _buildQuotaChip('ผู้แทนนายจ้าง', '${quota.actualEmployerRep}/${quota.requiredEmployerRep}', quota.actualEmployerRep >= quota.requiredEmployerRep ? Colors.teal : Colors.red),
              _buildQuotaChip('ผู้แทนลูกจ้าง', '${quota.actualEmployeeRep}/${quota.requiredEmployeeRep}', quota.actualEmployeeRep >= quota.requiredEmployeeRep ? Colors.teal : Colors.red),
              _buildQuotaChip('เลขานุการ (จป.ว)', '${quota.actualSecretary}/${quota.requiredSecretary}', quota.actualSecretary >= quota.requiredSecretary ? Colors.teal : Colors.red),
              _buildQuotaChip('กรรมการรวม', '${quota.actualTotal}/${quota.requiredTotal}', quota.actualTotal >= quota.requiredTotal ? Colors.teal : Colors.red),
            ],
          ),
          if (quota.errorMessages.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final err in quota.errorMessages)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 2),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.red),
                    const SizedBox(width: 6),
                    Text(err, style: const TextStyle(fontSize: 12, color: Colors.red)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuotaChip(String label, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color.shade800)),
        ],
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context, CpoTermModel term) {
    // Group members by role
    final chairs = term.members.where((m) => m.cpoRole == CpoMemberRole.chair).toList();
    final employerReps = term.members.where((m) => m.cpoRole == CpoMemberRole.employerRep).toList();
    final employeeReps = term.members.where((m) => m.cpoRole == CpoMemberRole.employeeRep).toList();
    final secretaries = term.members.where((m) => m.cpoRole == CpoMemberRole.secretary).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRoleGroup(context, term.id!, '๑. ประธานคณะกรรมการ คปอ. (นายจ้างหรือผู้แทนนายจ้างระดับบริหาร)', chairs, CpoMemberRole.chair, Icons.stars),
        const SizedBox(height: 16),
        _buildRoleGroup(context, term.id!, '๒. กรรมการผู้แทนนายจ้างระดับบังคับบัญชา', employerReps, CpoMemberRole.employerRep, Icons.business_center_outlined),
        const SizedBox(height: 16),
        _buildRoleGroup(context, term.id!, '๓. กรรมการผู้แทนลูกจ้าง (จากการเลือกตั้ง)', employeeReps, CpoMemberRole.employeeRep, Icons.how_to_vote_outlined),
        const SizedBox(height: 16),
        _buildRoleGroup(context, term.id!, '๔. เลขานุการคณะกรรมการ คปอ. (จป.วิชาชีพ หรือผู้ได้รับมอบหมาย)', secretaries, CpoMemberRole.secretary, Icons.edit_note_outlined),
      ],
    );
  }

  Widget _buildRoleGroup(
    BuildContext context,
    int termId,
    String title,
    List<CpoMemberModel> members,
    CpoMemberRole defaultRole,
    IconData icon,
  ) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF0D9488)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('เพิ่มในส่วนนี้'),
                  onPressed: () => _openMemberDialog(context, termId, null, initialRole: defaultRole),
                ),
              ],
            ),
            const Divider(height: 20),
            if (members.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'ยังไม่มีกรรมการในตำแหน่งนี้ (โปรดแต่งตั้งให้ครบตามเกณฑ์กฎหมาย)',
                    style: TextStyle(fontSize: 13, color: Colors.orange.shade800, fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (ctx, i) {
                  final m = members[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0D9488).withOpacity(0.1),
                      foregroundColor: const Color(0xFF0D9488),
                      child: Text(m.fullName.isNotEmpty ? m.fullName.substring(0, 1) : '?'),
                    ),
                    title: Row(
                      children: [
                        Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        if (m.companyPosition != null && m.companyPosition!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text('(${m.companyPosition})', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      'แผนก: ${m.department ?? "-"} | โทร: ${m.phone ?? "-"}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'แก้ไขข้อมูล',
                          onPressed: () => _openMemberDialog(context, termId, m),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
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
              await ref.read(cpoActiveTermProvider.notifier).saveTerm(newTerm);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _openMemberDialog(BuildContext context, int termId, CpoMemberModel? member, {CpoMemberRole? initialRole}) {
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
                    if (allEmployees.isNotEmpty && member == null) ...[
                      DropdownButtonFormField<int?>(
                        decoration: const InputDecoration(
                          labelText: 'เลือกจากรายชื่อพนักงานในระบบ (หรือพิมพ์เองด้านล่าง)',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedEmpId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('-- พิมพ์ชื่อเอง / ไม่เลือก --')),
                          ...allEmployees.map((e) => DropdownMenuItem(
                                value: e.id,
                                child: Text('${e.fullName} (${e.department ?? "-"})'),
                              )),
                        ],
                        onChanged: (val) {
                          setDlgState(() {
                            selectedEmpId = val;
                            if (val != null) {
                              final emp = allEmployees.firstWhere((e) => e.id == val);
                              nameCtrl.text = emp.fullName;
                              deptCtrl.text = emp.department ?? '';
                              posCtrl.text = emp.position ?? '';
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
                      value: selectedRole,
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
                    await ref.read(cpoActiveTermProvider.notifier).addMember(m);
                  } else {
                    await ref.read(cpoActiveTermProvider.notifier).updateMember(m);
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
      await ref.read(cpoActiveTermProvider.notifier).deleteMember(member.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบรายชื่อกรรมการเรียบร้อยแล้ว')),
        );
      }
    }
  }
}
