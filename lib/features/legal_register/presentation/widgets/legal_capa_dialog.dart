import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/legal_capa_model.dart';
import '../../domain/models/legal_compliance_assessment_model.dart';
import '../providers/legal_register_providers.dart';

/// Dialog for creating and editing Corrective and Preventive Action (CAPA) items
/// tied to statutory safety legal compliance assessments.
class LegalCapaDialog extends ConsumerStatefulWidget {
  final LegalCapaModel? capaItem;
  final LegalComplianceAssessmentModel? linkedAssessment;
  final Function(LegalCapaModel savedCapa)? onSaved;

  const LegalCapaDialog({
    Key? key,
    this.capaItem,
    this.linkedAssessment,
    this.onSaved,
  }) : super(key: key);

  @override
  ConsumerState<LegalCapaDialog> createState() => _LegalCapaDialogState();
}

class _LegalCapaDialogState extends ConsumerState<LegalCapaDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _actionTitleController;
  late TextEditingController _rootCauseController;
  late TextEditingController _correctiveActionController;
  late TextEditingController _preventiveActionController;
  late TextEditingController _picNameController;
  late TextEditingController _picDepartmentController;
  late TextEditingController _notesController;

  late DateTime _targetDate;
  DateTime? _completedDate;
  late String _status;

  String? _existingEvidencePath;
  String? _newPickedEvidencePath;
  bool _isSaving = false;

  int? _selectedAssessmentId;
  LegalComplianceAssessmentModel? _selectedAssessment;

  @override
  void initState() {
    super.initState();
    final c = widget.capaItem;
    final a = widget.linkedAssessment;

    _selectedAssessment = a;
    _selectedAssessmentId = c?.assessmentId ?? a?.id ?? 0;

    _actionTitleController = TextEditingController(
      text: c?.actionTitle ?? (a != null ? 'แผนปรับปรุงความสอดคล้อง: ${a.requirementCode}' : ''),
    );
    _rootCauseController = TextEditingController(text: c?.rootCause ?? '');
    _correctiveActionController = TextEditingController(text: c?.correctiveAction ?? (a?.actualPractice ?? ''));
    _preventiveActionController = TextEditingController(text: c?.preventiveAction ?? '');
    _picNameController = TextEditingController(text: c?.picName ?? (a?.evaluatorName ?? 'จป.วิชาชีพ'));
    _picDepartmentController = TextEditingController(text: c?.picDepartment ?? (a?.department ?? 'ฝ่ายความปลอดภัย (EHS)'));
    _notesController = TextEditingController(text: c?.notes ?? '');

    _status = c?.status ?? 'PENDING';
    _targetDate = c?.parsedTargetDate ?? DateTime.now().add(const Duration(days: 30));
    _completedDate = c?.parsedCompletedDate;

    _existingEvidencePath = c?.evidenceFilePath;
  }

  @override
  void dispose() {
    _actionTitleController.dispose();
    _rootCauseController.dispose();
    _correctiveActionController.dispose();
    _preventiveActionController.dispose();
    _picNameController.dispose();
    _picDepartmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidenceFile() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx', 'xlsx'],
      );

      if (result != null && result.paths.isNotEmpty && result.paths.first != null) {
        setState(() {
          _newPickedEvidencePath = result.paths.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเลือกไฟล์หลักฐานได้: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0D9488)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _selectCompletedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _completedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF10B981)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _completedDate = picked);
    }
  }

  Future<void> _saveCapa() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final targetDateStr = _targetDate.toIso8601String().substring(0, 10);
      final completedDateStr = _status == 'COMPLETED'
          ? (_completedDate?.toIso8601String().substring(0, 10) ?? DateTime.now().toIso8601String().substring(0, 10))
          : null;

      final capa = (widget.capaItem ??
              LegalCapaModel(
                assessmentId: _selectedAssessmentId ?? _selectedAssessment?.id ?? 0,
                actionTitle: '',
                rootCause: '',
                correctiveAction: '',
                picName: '',
                targetDate: targetDateStr,
              ))
          .copyWith(
        assessmentId: _selectedAssessmentId ?? _selectedAssessment?.id ?? 0,
        actionTitle: _actionTitleController.text.trim(),
        rootCause: _rootCauseController.text.trim(),
        correctiveAction: _correctiveActionController.text.trim(),
        preventiveAction: _preventiveActionController.text.trim(),
        picName: _picNameController.text.trim(),
        picDepartment: _picDepartmentController.text.trim(),
        targetDate: targetDateStr,
        completedDate: completedDateStr,
        status: _status,
        evidenceFilePath: _existingEvidencePath,
        notes: _notesController.text.trim(),
        requirementCode: _selectedAssessment?.requirementCode ?? widget.capaItem?.requirementCode,
        requirementTitle: _selectedAssessment?.requirementTitle ?? widget.capaItem?.requirementTitle,
        category: _selectedAssessment?.category ?? widget.capaItem?.category,
        lawTitle: _selectedAssessment?.lawTitleTh ?? widget.capaItem?.lawTitle,
      );

      final savedId = await ref.read(legalCapaListProvider.notifier).saveCapa(
            capa,
            newEvidencePath: _newPickedEvidencePath,
          );

      final finalItem = capa.copyWith(id: capa.id ?? savedId);

      if (widget.onSaved != null) {
        widget.onSaved!(finalItem);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.capaItem != null ? 'แก้ไขแผนงาน CAPA เรียบร้อยแล้ว' : 'สร้างแผนงาน CAPA ใหม่สำเร็จ'),
            backgroundColor: const Color(0xFF0D9488),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก CAPA: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.capaItem != null;
    final assessmentAsync = ref.watch(legalAssessmentListProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        width: 840,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'แก้ไขแผนการปรับปรุงแก้ไข (CAPA Action Plan)' : 'เปิดแผนการปรับปรุงแก้ไขใหม่ (New CAPA)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'มาตรการแก้ไขและป้องกันข้อบกพร่องตามกฎหมายความปลอดภัยราชกิจจานุเบกษา',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade100),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Dialog Body Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Linked Assessment Selector / Card
                      const Text(
                        'ข้อกำหนดกฎหมายที่ต้องปรับปรุงแก้ไข (Linked Requirement) *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),

                      if (widget.linkedAssessment != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.linkedAssessment!.requirementCode,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.linkedAssessment!.requirementTitle,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                    ),
                                    Text(
                                      widget.linkedAssessment!.lawTitleTh,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        assessmentAsync.when(
                          data: (items) {
                            final validItems = items.where((i) => i.id != null && i.id! > 0).toList();
                            return DropdownButtonFormField<int>(
                              value: _selectedAssessmentId != 0 ? _selectedAssessmentId : (validItems.isNotEmpty ? validItems.first.id : null),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                              ),
                              items: validItems.map((item) {
                                return DropdownMenuItem<int>(
                                  value: item.id,
                                  child: Text(
                                    '[${item.requirementCode}] ${item.requirementTitle}',
                                    style: const TextStyle(fontSize: 12.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedAssessmentId = val;
                                    _selectedAssessment = validItems.firstWhere((element) => element.id == val);
                                  });
                                }
                              },
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text('ไม่สามารถโหลดรายการข้อกำหนดได้'),
                        ),

                      const SizedBox(height: 18),

                      // Action Title
                      const Text('ชื่อแผนงานปรับปรุง (Action Title) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _actionTitleController,
                        decoration: InputDecoration(
                          hintText: 'เช่น จัดซื้อและติดตั้งฝาครอบป้องกันเครื่องจักร (Safety Guard) เพิ่มเติม',
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อแผนงานปรับปรุง' : null,
                      ),

                      const SizedBox(height: 18),

                      // Root Cause Analysis
                      const Text(
                        'การวิเคราะห์สาเหตุที่แท้จริง (Root Cause Analysis - 5 Whys) *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _rootCauseController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'ระบุสาเหตุรากเหง้า เช่น ฝ่ายซ่อมบำรุงถอดการ์ดออกขณะเปลี่ยนอะไหล่แล้วลืมใส่กลับคืน และไม่มีเช็กลิสต์ตรวจประจำวัน...',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุการวิเคราะห์สาเหตุที่แท้จริง' : null,
                      ),

                      const SizedBox(height: 18),

                      // Corrective Action & Preventive Action
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('มาตรการแก้ไขเฉพาะหน้า (Corrective Action) *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _correctiveActionController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'สั่งหยุดเครื่องจักรชั่วคราว และติดตั้งฝาครอบป้องกันทันที',
                                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกมาตรการแก้ไข' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('มาตรการป้องกันการเกิดซ้ำ (Preventive Action)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _preventiveActionController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'เพิ่มข้อกำหนดใน Work Instruction และจัดทำระบบ Safety Interlock ตัดไฟอัตโนมัติ',
                                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // PIC & Department & Target Date
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ผู้รับผิดชอบ (PIC) *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _picNameController,
                                  decoration: InputDecoration(
                                    hintText: 'ชื่อผู้รับผิดชอบดำเนินการ',
                                    isDense: true,
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุผู้รับผิดชอบ' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('แผนก / ส่วนงาน', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _picDepartmentController,
                                  decoration: InputDecoration(
                                    hintText: 'เช่น ซ่อมบำรุง / ผลิต / EHS',
                                    isDense: true,
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('กำหนดแล้วเสร็จ (Target Date) *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _selectTargetDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _targetDate.toIso8601String().substring(0, 10),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0D9488)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Status Selector Chips
                      const Text('สถานะการดำเนินงาน (Action Status) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildCapaStatusChoice('PENDING', '⏳ รอดำเนินการ', const Color(0xFF6B7280), const Color(0xFFF3F4F6))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildCapaStatusChoice('IN_PROGRESS', '🏃 กำลังดำเนินการ', const Color(0xFF3B82F6), const Color(0xFFEFF6FF))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildCapaStatusChoice('COMPLETED', '✅ เสร็จสิ้นแล้ว', const Color(0xFF10B981), const Color(0xFFECFDF5))),
                        ],
                      ),

                      // If Status is COMPLETED, show completion date & closure notes
                      if (_status == 'COMPLETED') ...[
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF6EE7B7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                  const SizedBox(width: 8),
                                  const Text('บันทึกการปิดงาน CAPA (Closure Verification)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('วันที่ดำเนินการแล้วเสร็จจริง', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        InkWell(
                                          onTap: _selectCompletedDate,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFF10B981)),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  _completedDate != null
                                                      ? _completedDate!.toIso8601String().substring(0, 10)
                                                      : DateTime.now().toIso8601String().substring(0, 10),
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                ),
                                                const Icon(Icons.check_rounded, size: 16, color: Color(0xFF10B981)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Evidence File Picker
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('หลักฐานการแก้ไข (Action Evidence)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            onPressed: _pickEvidenceFile,
                            icon: const Icon(Icons.attach_file_rounded, size: 16),
                            label: Text(_existingEvidencePath != null || _newPickedEvidencePath != null ? 'เปลี่ยนไฟล์หลักฐาน' : 'แนบไฟล์หลักฐาน'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      if (_newPickedEvidencePath != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF93C5FD)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF3B82F6), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ไฟล์ใหม่: ${p.basename(_newPickedEvidencePath!)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                onPressed: () => setState(() => _newPickedEvidencePath = null),
                              ),
                            ],
                          ),
                        )
                      else if (_existingEvidencePath != null && _existingEvidencePath!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.attach_file_rounded, color: Color(0xFF0D9488), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.basename(_existingEvidencePath!),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                onPressed: () => setState(() => _existingEvidencePath = null),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          'ยังไม่ได้แนบหลักฐาน (ภาพถ่ายหลังแก้ไข / ใบเสร็จ / รายงานตรวจสภาพ)',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                        ),

                      const SizedBox(height: 18),

                      // Notes
                      const Text('บันทึกเพิ่มเติม (Notes)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'บันทึกการติดตามงานหรือผลกระทบ...',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveCapa,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกแผนงาน CAPA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildCapaStatusChoice(String code, String label, Color color, Color bgColor) {
    final isSelected = _status == code;
    return InkWell(
      onTap: () {
        setState(() {
          _status = code;
          if (code == 'COMPLETED' && _completedDate == null) {
            _completedDate = DateTime.now();
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}
