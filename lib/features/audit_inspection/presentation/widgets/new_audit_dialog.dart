import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../safety_manual/presentation/notifiers/manual_providers.dart';
import '../notifiers/audit_providers.dart';

class NewAuditDialog extends ConsumerStatefulWidget {
  const NewAuditDialog({super.key});

  @override
  ConsumerState<NewAuditDialog> createState() => _NewAuditDialogState();
}

class _NewAuditDialogState extends ConsumerState<NewAuditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _leadAuditorController;
  late TextEditingController _auditorTeamController;
  late TextEditingController _dateController;
  String _scope = 'INTEGRATED'; // 'INTEGRATED' or 'SMS_2565'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final thaiYear = now.year + 543;
    _titleController = TextEditingController(text: 'ตรวจประเมินระบบการจัดการความปลอดภัยประจำปี $thaiYear');
    _leadAuditorController = TextEditingController(text: 'จป.วิชาชีพ / ผู้ตรวจประเมินหลัก');
    _auditorTeamController = TextEditingController(text: 'คณะกรรมการ คปอ. และหัวหน้าแผนก');
    _dateController = TextEditingController(
      text: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _leadAuditorController.dispose();
    _auditorTeamController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final session = await ref.read(auditSessionsProvider.notifier).createSession(
        title: _titleController.text.trim(),
        leadAuditor: _leadAuditorController.text.trim(),
        auditorTeam: _auditorTeamController.text.trim().isNotEmpty ? _auditorTeamController.text.trim() : null,
        scope: _scope,
        auditDate: _dateController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(session);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('สร้างรอบการตรวจประเมิน ${session.auditNo} สำเร็จ (${session.totalItems} ข้อตรวจ)'),
            backgroundColor: const Color(0xFF1E3A8A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final factoryScope = ref.watch(factoryScopeProvider).asData?.value;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.playlist_add_check_circle_rounded, color: Color(0xFF1E3A8A), size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('เปิดรอบการตรวจประเมินความปลอดภัยใหม่',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('อิงกฎกระทรวงระบบการจัดการด้านความปลอดภัย พ.ศ. ๒๕๖๕ และบริบทโรงงาน',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'ชื่อหัวข้อการตรวจประเมิน *',
                  prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อหัวข้อการตรวจ' : null,
              ),
              const SizedBox(height: 14),

              // Date & Lead Auditor
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'วันที่ตรวจประเมิน (YYYY-MM-DD) *',
                        prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุวันที่' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _leadAuditorController,
                      decoration: InputDecoration(
                        labelText: 'หัวหน้าทีมผู้ตรวจ (Lead Auditor) *',
                        prefixIcon: const Icon(Icons.person_pin_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุผู้ตรวจหลัก' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Team
              TextFormField(
                controller: _auditorTeamController,
                decoration: InputDecoration(
                  labelText: 'ทีมผู้ตรวจร่วม / พยาน (Auditor Team)',
                  prefixIcon: const Icon(Icons.group_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),

              // Scope Selection
              const Text('ขอบเขตเกณฑ์การตรวจประเมิน (Audit Scope):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _scope = 'INTEGRATED'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _scope == 'INTEGRATED' ? const Color(0xFF1E3A8A).withValues(alpha: 0.08) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _scope == 'INTEGRATED' ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
                            width: _scope == 'INTEGRATED' ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _scope == 'INTEGRATED' ? Icons.radio_button_checked : Icons.radio_button_off,
                                  size: 18,
                                  color: _scope == 'INTEGRATED' ? const Color(0xFF1E3A8A) : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                const Text('ตรวจแบบบูรณาการ (Integrated)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text('๕ เสาหลัก SMS ๒๕๖๕ + ข้อตรวจหน้างานตามบริบทโรงงาน (เครื่องจักร, สารเคมี, ไฟฟ้า, PTW)',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _scope = 'SMS_2565'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _scope == 'SMS_2565' ? const Color(0xFF1E3A8A).withValues(alpha: 0.08) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _scope == 'SMS_2565' ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
                            width: _scope == 'SMS_2565' ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _scope == 'SMS_2565' ? Icons.radio_button_checked : Icons.radio_button_off,
                                  size: 18,
                                  color: _scope == 'SMS_2565' ? const Color(0xFF1E3A8A) : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                const Text('เฉพาะระบบการจัดการ (SMS Only)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text('ตรวจเฉพาะ ๕ องค์ประกอบหลักตามกฎกระทรวงฯ ๒๕๖๕ (๑๖ ข้อย่อยหลักตามกฎหมาย)',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Active Factory Context Preview
              if (_scope == 'INTEGRATED' && factoryScope != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.factory_outlined, size: 16, color: Color(0xFF475569)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'บริบทโรงงานที่เปิดใช้งาน: '
                          '${factoryScope.hasElectricalLoto ? "ไฟฟ้า/LOTO • " : ""}'
                          '${factoryScope.hasCrane ? "ปั้นจั่น • " : ""}'
                          '${factoryScope.hasBoiler ? "หม้อน้ำ • " : ""}'
                          '${factoryScope.hasChemical ? "สารเคมี • " : ""}'
                          '${factoryScope.hasConfinedSpace ? "ที่อับอากาศ/PTW • " : ""}'
                          '${factoryScope.hasEmergencyFire ? "ซ้อมหนีไฟ • " : ""}'
                          '${factoryScope.hasPpe ? "PPE" : ""}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('ยกเลิก'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('เริ่มการตรวจประเมิน (Start Audit)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
