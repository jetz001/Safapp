import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/environment_capa_model.dart';
import '../../domain/models/environment_point_model.dart';
import '../../domain/models/environment_standard_model.dart';
import '../providers/environment_providers.dart';

/// Modal dialog for creating or editing an Environmental CAPA action plan.
class AddEditCapaDialog extends ConsumerStatefulWidget {
  final EnvironmentCapaModel? capaItem;
  final EnvironmentPointModel? linkedPoint;
  final ValueChanged<EnvironmentCapaModel>? onSaved;

  const AddEditCapaDialog({
    Key? key,
    this.capaItem,
    this.linkedPoint,
    this.onSaved,
  }) : super(key: key);

  @override
  ConsumerState<AddEditCapaDialog> createState() => _AddEditCapaDialogState();
}

class _AddEditCapaDialogState extends ConsumerState<AddEditCapaDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _capaIdCtrl;
  late TextEditingController _actionTitleCtrl;
  late TextEditingController _hazardDescCtrl;
  late TextEditingController _rootCauseCtrl;
  late TextEditingController _engCtrl;
  late TextEditingController _adminCtrl;
  late TextEditingController _ppeCtrl;
  late TextEditingController _picNameCtrl;
  late TextEditingController _picDeptCtrl;
  late TextEditingController _targetDateCtrl;
  late TextEditingController _completedDateCtrl;
  late TextEditingController _notesCtrl;

  late EnvironmentFactorType _selectedFactor;
  late String _selectedStatus;
  late bool _hearingEnrolled;
  String? _selectedPointId;
  String? _selectedSessionId;

  @override
  void initState() {
    super.initState();
    final c = widget.capaItem;
    final p = widget.linkedPoint;

    final now = DateTime.now();
    final defaultId = c?.capaId ?? 'CAPA-ENV-${now.millisecondsSinceEpoch % 10000}';
    final targetDt = c?.targetDate ?? now.add(const Duration(days: 30)).toIso8601String().substring(0, 10);

    _capaIdCtrl = TextEditingController(text: defaultId);
    _actionTitleCtrl = TextEditingController(
      text: c?.actionTitle ?? (p != null ? 'ปรับปรุงผลตรวจวัด ${p.factorType.labelTh} (${p.locationName})' : ''),
    );
    _hazardDescCtrl = TextEditingController(
      text: c?.hazardDescription ?? (p != null ? 'จุดตรวจวัด ${p.pointId} ${p.summaryValueDisplay} ${p.evaluationStatus.labelTh}' : ''),
    );
    _rootCauseCtrl = TextEditingController(text: c?.rootCause ?? 'ผลการตรวจวัดไม่สอดคล้องตามเกณฑ์มาตรฐานหรืออยู่ในระดับเฝ้าระวัง');
    _engCtrl = TextEditingController(text: c?.engineeringControl ?? '');
    _adminCtrl = TextEditingController(text: c?.administrativeControl ?? '');
    _ppeCtrl = TextEditingController(text: c?.ppeControl ?? '');
    _picNameCtrl = TextEditingController(text: c?.picName ?? 'จป.วิชาชีพ / หัวหน้าแผนก');
    _picDeptCtrl = TextEditingController(text: c?.picDepartment ?? (p?.department ?? 'ฝ่ายความปลอดภัย & ฝ่ายผลิต'));
    _targetDateCtrl = TextEditingController(text: targetDt);
    _completedDateCtrl = TextEditingController(text: c?.completedDate ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');

    _selectedFactor = c?.factorType ?? (p?.factorType ?? EnvironmentFactorType.light);
    _selectedStatus = c?.status ?? 'PENDING';
    _hearingEnrolled = c?.hearingProgramEnrolled ?? (p?.requiresHearingConservation ?? false);
    _selectedPointId = c?.pointId ?? p?.pointId;
    _selectedSessionId = c?.sessionId ?? (p?.sessionId ?? 'ENV-SESS-2026-001');
  }

  @override
  void dispose() {
    _capaIdCtrl.dispose();
    _actionTitleCtrl.dispose();
    _hazardDescCtrl.dispose();
    _rootCauseCtrl.dispose();
    _engCtrl.dispose();
    _adminCtrl.dispose();
    _ppeCtrl.dispose();
    _picNameCtrl.dispose();
    _picDeptCtrl.dispose();
    _targetDateCtrl.dispose();
    _completedDateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final capa = EnvironmentCapaModel(
      id: widget.capaItem?.id,
      capaId: _capaIdCtrl.text.trim(),
      pointId: _selectedPointId,
      sessionId: _selectedSessionId ?? 'ENV-SESS-2026-001',
      factorType: _selectedFactor,
      actionTitle: _actionTitleCtrl.text.trim(),
      hazardDescription: _hazardDescCtrl.text.trim(),
      rootCause: _rootCauseCtrl.text.trim(),
      engineeringControl: _engCtrl.text.trim().isNotEmpty ? _engCtrl.text.trim() : null,
      administrativeControl: _adminCtrl.text.trim().isNotEmpty ? _adminCtrl.text.trim() : null,
      ppeControl: _ppeCtrl.text.trim().isNotEmpty ? _ppeCtrl.text.trim() : null,
      picName: _picNameCtrl.text.trim(),
      picDepartment: _picDeptCtrl.text.trim().isNotEmpty ? _picDeptCtrl.text.trim() : null,
      targetDate: _targetDateCtrl.text.trim(),
      completedDate: _completedDateCtrl.text.trim().isNotEmpty ? _completedDateCtrl.text.trim() : null,
      status: _selectedStatus,
      hearingProgramEnrolled: _hearingEnrolled,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    );

    ref.read(envCapaListProvider.notifier).saveCapa(capa);
    if (widget.onSaved != null) {
      widget.onSaved!(capa);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.capaItem != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 760,
        constraints: const BoxConstraints(maxHeight: 720),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A8A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEdit ? 'แก้ไขแผนงาน CAPA (${widget.capaItem!.capaId})' : 'เปิดแผนปฏิบัติการแก้ไข (CAPA Plan)',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Factor & Point ID Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _capaIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'รหัส CAPA *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'ระบุรหัส CAPA' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<EnvironmentFactorType>(
                            value: _selectedFactor,
                            decoration: const InputDecoration(
                              labelText: 'ปัจจัยสภาพแวดล้อม *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: EnvironmentFactorType.values.map((f) {
                              return DropdownMenuItem(
                                value: f,
                                child: Text(f.labelTh),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedFactor = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: _selectedPointId ?? '-',
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'จุดตรวจวัดที่เชื่อมโยง',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action Title
                    TextFormField(
                      controller: _actionTitleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'หัวข้อแผนงานแก้ไขและป้องกัน (Action Title) *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุหัวข้อแผนงาน' : null,
                    ),
                    const SizedBox(height: 16),

                    // Hazard & Non-compliance description
                    TextFormField(
                      controller: _hazardDescCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'รายละเอียดสภาพปัญหา / ความไม่สอดคล้อง *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุสภาพปัญหา' : null,
                    ),
                    const SizedBox(height: 16),

                    // Root Cause (5 Whys)
                    TextFormField(
                      controller: _rootCauseCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'สาเหตุรากเหง้า (Root Cause Analysis) *',
                        hintText: 'วิเคราะห์สาเหตุ เช่น หลอดไฟเสื่อมสภาพ, เครื่องจักรสึกหรอ, แหล่งความร้อนไม่มีฉนวน...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุสาเหตุรากเหง้า' : null,
                    ),
                    const SizedBox(height: 20),

                    // Hierarchy of Controls Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shield_rounded, color: Color(0xFF1E3A8A), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'ลำดับขั้นการควบคุมความปลอดภัย (Hierarchy of Controls)',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _engCtrl,
                            decoration: const InputDecoration(
                              labelText: '๑. มาตรการทางวิศวกรรม (Engineering Control)',
                              hintText: 'เช่น ติดตั้งโคมไฟเพิ่ม, ทำฉนวนกันเสียง, กั้นห้องเครื่องจักร, พัดลมระบายอากาศ...',
                              border: OutlineInputBorder(),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _adminCtrl,
                            decoration: const InputDecoration(
                              labelText: '๒. มาตรการบริหารจัดการ (Administrative Control)',
                              hintText: 'เช่น ปรับรอบการทำงาน, สลับกะ, ติดป้ายเตือน, อบรมความปลอดภัย...',
                              border: OutlineInputBorder(),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _ppeCtrl,
                            decoration: const InputDecoration(
                              labelText: '๓. อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล (PPE Control)',
                              hintText: 'เช่น ปลั๊กอุดหู (Earplugs NRR 25), ครอบหู (Earmuffs), แว่นตากรองแสง...',
                              border: OutlineInputBorder(),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PIC & Target Date
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _picNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'ผู้รับผิดชอบหลัก (PIC Name) *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'ระบุผู้รับผิดชอบ' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _picDeptCtrl,
                            decoration: const InputDecoration(
                              labelText: 'แผนก/ฝ่าย',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _targetDateCtrl,
                            decoration: const InputDecoration(
                              labelText: 'กำหนดแล้วเสร็จ (YYYY-MM-DD) *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'ระบุกำหนดเสร็จ' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status & Completed Date
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'สถานะการดำเนินงาน *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'PENDING', child: Text('รอดำเนินการ (Pending)')),
                              DropdownMenuItem(value: 'IN_PROGRESS', child: Text('กำลังดำเนินการ (In Progress)')),
                              DropdownMenuItem(value: 'COMPLETED', child: Text('เสร็จสิ้นแล้ว (Completed)')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _selectedStatus = v;
                                  if (v == 'COMPLETED' && _completedDateCtrl.text.isEmpty) {
                                    _completedDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _completedDateCtrl,
                            decoration: const InputDecoration(
                              labelText: 'วันที่แล้วเสร็จจริง (YYYY-MM-DD)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Hearing Conservation Checkbox
                    CheckboxListTile(
                      value: _hearingEnrolled,
                      onChanged: (v) => setState(() => _hearingEnrolled = v ?? false),
                      title: const Text('ขึ้นทะเบียนโครงการอนุรักษ์การได้ยิน (Hearing Conservation Program - HCP)'),
                      subtitle: const Text('สำหรับจุดที่มีระดับเสียงเฉลี่ยตั้งแต่ 85 dBA ขึ้นไป (ข้อ ๑๑ กฎกระทรวงฯ ๒๕๕๙)'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'หมายเหตุเพิ่มเติม',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ยกเลิก'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(isEdit ? 'บันทึกการแก้ไข' : 'บันทึกแผนงาน CAPA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
