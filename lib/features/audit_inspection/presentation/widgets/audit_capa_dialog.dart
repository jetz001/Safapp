import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/audit_models.dart';
import '../notifiers/audit_providers.dart';

class AuditCapaDialog extends ConsumerStatefulWidget {
  final int auditSessionId;
  final AuditChecklistItem? checklistItem;
  final AuditFindingCapa? existingFinding;

  const AuditCapaDialog({
    super.key,
    required this.auditSessionId,
    this.checklistItem,
    this.existingFinding,
  });

  @override
  ConsumerState<AuditCapaDialog> createState() => _AuditCapaDialogState();
}

class _AuditCapaDialogState extends ConsumerState<AuditCapaDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clauseController;
  late TextEditingController _problemController;
  late TextEditingController _rootCauseController;
  late TextEditingController _correctiveController;
  late TextEditingController _preventiveController;
  late TextEditingController _responsibleController;
  late TextEditingController _dueDateController;
  late TextEditingController _verifierController;

  String _findingType = 'MINOR_NC';
  String _status = 'OPEN';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final f = widget.existingFinding;
    final item = widget.checklistItem;

    _findingType = f?.findingType ?? (item?.isMajorNc == true ? 'MAJOR_NC' : 'MINOR_NC');
    _clauseController = TextEditingController(text: f?.clauseRef ?? (item != null ? '${item.clauseNo}: ${item.itemTitle}' : ''));
    _problemController = TextEditingController(text: f?.problemDescription ?? (item?.auditorNotes ?? ''));
    _rootCauseController = TextEditingController(text: f?.rootCause ?? '');
    _correctiveController = TextEditingController(text: f?.correctiveAction ?? (item?.suggestedAction ?? ''));
    _preventiveController = TextEditingController(text: f?.preventiveAction ?? '');
    _responsibleController = TextEditingController(text: f?.responsiblePerson ?? 'ผู้จัดการแผนก / จป.วิชาชีพ');

    final defaultDue = DateTime.now().add(Duration(days: _findingType == 'MAJOR_NC' ? 7 : 30));
    _dueDateController = TextEditingController(
      text: f?.dueDate ?? '${defaultDue.year}-${defaultDue.month.toString().padLeft(2, '0')}-${defaultDue.day.toString().padLeft(2, '0')}',
    );
    _verifierController = TextEditingController(text: f?.verifierName ?? '');
    _status = f?.status ?? 'OPEN';
  }

  @override
  void dispose() {
    _clauseController.dispose();
    _problemController.dispose();
    _rootCauseController.dispose();
    _correctiveController.dispose();
    _preventiveController.dispose();
    _responsibleController.dispose();
    _dueDateController.dispose();
    _verifierController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final finding = AuditFindingCapa(
        id: widget.existingFinding?.id,
        auditSessionId: widget.auditSessionId,
        checklistItemId: widget.checklistItem?.id ?? widget.existingFinding?.checklistItemId,
        findingNo: widget.existingFinding?.findingNo ?? '',
        findingType: _findingType,
        clauseRef: _clauseController.text.trim(),
        problemDescription: _problemController.text.trim(),
        rootCause: _rootCauseController.text.trim().isNotEmpty ? _rootCauseController.text.trim() : null,
        correctiveAction: _correctiveController.text.trim(),
        preventiveAction: _preventiveController.text.trim().isNotEmpty ? _preventiveController.text.trim() : null,
        responsiblePerson: _responsibleController.text.trim(),
        dueDate: _dueDateController.text.trim(),
        status: _status,
        completedDate: _status == 'CLOSED' ? (widget.existingFinding?.completedDate ?? '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}') : null,
        verifierName: _verifierController.text.trim().isNotEmpty ? _verifierController.text.trim() : null,
      );

      await ref.read(allAuditFindingsProvider.notifier).saveFinding(finding);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingFinding == null ? 'บันทึกเปิดใบสั่งการแก้ไข (CAR) เรียบร้อยแล้ว' : 'อัปเดตข้อมูล CAR เรียบร้อยแล้ว'),
            backgroundColor: Colors.green.shade800,
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.assignment_late_outlined, color: Colors.red.shade800, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.existingFinding == null ? 'เปิดใบสั่งการแก้ไขข้อบกพร่อง (CAR / CAPA)' : 'จัดการใบสั่งการแก้ไข ${widget.existingFinding!.findingNo}',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const Text('กำหนดมาตรการแก้ไข ป้องกันการเกิดซ้ำ และระบุผู้รับผิดชอบตามกฎกระทรวงฯ ข้อ ๑๑',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Severity & Status Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _findingType,
                        decoration: InputDecoration(
                          labelText: 'ระดับข้อบกพร่อง *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'MAJOR_NC', child: Text('🚨 Major NC (ข้อบกพร่องร้ายแรง)')),
                          DropdownMenuItem(value: 'MINOR_NC', child: Text('⚠️ Minor NC (ข้อบกพร่องเล็กน้อย)')),
                          DropdownMenuItem(value: 'OBSERVATION', child: Text('💡 Observation (ข้อสังเกต/โอกาสปรับปรุง)')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _findingType = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: InputDecoration(
                          labelText: 'สถานะมาตรการ (Status) *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'OPEN', child: Text('🔴 OPEN (รอเริ่มดำเนินการ)')),
                          DropdownMenuItem(value: 'IN_PROGRESS', child: Text('🟡 IN_PROGRESS (กำลังแก้ไข)')),
                          DropdownMenuItem(value: 'CLOSED', child: Text('🟢 CLOSED (ปิดประเด็นแล้ว)')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _status = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Clause Reference
                TextFormField(
                  controller: _clauseController,
                  decoration: InputDecoration(
                    labelText: 'ข้อกำหนดกฎหมาย / หมวดการตรวจอ้างอิง *',
                    prefixIcon: const Icon(Icons.gavel_outlined, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุข้อกำหนดอ้างอิง' : null,
                ),
                const SizedBox(height: 12),

                // Problem Description
                TextFormField(
                  controller: _problemController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'รายละเอียดข้อบกพร่องที่พบ (Non-Conformance) *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุข้อบกพร่องที่พบ' : null,
                ),
                const SizedBox(height: 12),

                // Root Cause
                TextFormField(
                  controller: _rootCauseController,
                  decoration: InputDecoration(
                    labelText: 'การวิเคราะห์สาเหตุรากเหง้า (Root Cause - ทำไมจึงเกิดข้อบกพร่อง)',
                    prefixIcon: const Icon(Icons.psychology_outlined, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Corrective Action
                TextFormField(
                  controller: _correctiveController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'มาตรการแก้ไขทันที (Corrective Action) *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุมาตรการแก้ไข' : null,
                ),
                const SizedBox(height: 12),

                // Preventive Action
                TextFormField(
                  controller: _preventiveController,
                  decoration: InputDecoration(
                    labelText: 'มาตรการป้องกันการเกิดซ้ำ (Preventive Action)',
                    prefixIcon: const Icon(Icons.shield_outlined, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Responsible & Due Date
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _responsibleController,
                        decoration: InputDecoration(
                          labelText: 'ผู้รับผิดชอบดำเนินการ *',
                          prefixIcon: const Icon(Icons.person_outline, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุผู้รับผิดชอบ' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _dueDateController,
                        decoration: InputDecoration(
                          labelText: 'กำหนดเสร็จ (YYYY-MM-DD) *',
                          prefixIcon: const Icon(Icons.event_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุกำหนดเสร็จ' : null,
                      ),
                    ),
                  ],
                ),
                if (_status == 'CLOSED') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _verifierController,
                    decoration: InputDecoration(
                      labelText: 'ผู้ตรวจสอบและยืนยันการปิดประเด็น (Verifier Name)',
                      prefixIcon: const Icon(Icons.verified_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
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
                          : const Icon(Icons.save_rounded, size: 18),
                      label: const Text('บันทึกมาตรการ CAR/CAPA'),
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
      ),
    );
  }
}
