import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/legal_compliance_assessment_model.dart';
import '../../domain/models/legal_master_item_model.dart';
import '../providers/legal_register_providers.dart';
import 'legal_capa_dialog.dart';

/// Modal dialog for assessing facility compliance against statutory safety legislation.
/// Supports status selection, actual practice notes, evaluator metadata, review dates,
/// multi-evidence file attachment picking, and seamless CAPA creation for non-compliant items.
class LegalAssessmentDialog extends ConsumerStatefulWidget {
  final LegalComplianceAssessmentModel assessment;
  final Function(LegalComplianceAssessmentModel savedItem)? onSaved;
  final Function(LegalComplianceAssessmentModel item)? onCreateCapa;

  const LegalAssessmentDialog({
    Key? key,
    required this.assessment,
    this.onSaved,
    this.onCreateCapa,
  }) : super(key: key);

  @override
  ConsumerState<LegalAssessmentDialog> createState() => _LegalAssessmentDialogState();
}

class _LegalAssessmentDialogState extends ConsumerState<LegalAssessmentDialog> {
  final _formKey = GlobalKey<FormState>();

  late bool _isApplicable;
  late String _complianceStatus;
  late TextEditingController _actualPracticeController;
  late TextEditingController _evaluatorNameController;
  late TextEditingController _evaluatorRoleController;
  late TextEditingController _departmentController;
  late TextEditingController _notesController;

  late DateTime _evaluatedDate;
  DateTime? _nextReviewDate;

  List<String> _existingEvidencePaths = [];
  List<String> _newPickedFilePaths = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.assessment;
    _isApplicable = a.isApplicable;
    _complianceStatus = a.complianceStatus;
    _actualPracticeController = TextEditingController(text: a.actualPractice ?? '');
    _evaluatorNameController = TextEditingController(text: a.evaluatorName);
    _evaluatorRoleController = TextEditingController(text: a.evaluatorRole ?? 'จป.วิชาชีพ');
    _departmentController = TextEditingController(text: a.department ?? 'ฝ่ายความปลอดภัยและสิ่งแวดล้อม (EHS)');
    _notesController = TextEditingController(text: a.notes ?? '');

    _evaluatedDate = DateTime.tryParse(a.evaluatedDate) ?? DateTime.now();
    _nextReviewDate = a.nextReviewDate != null ? DateTime.tryParse(a.nextReviewDate!) : null;

    _existingEvidencePaths = List.from(a.evidenceFilePaths);
  }

  @override
  void dispose() {
    _actualPracticeController.dispose();
    _evaluatorNameController.dispose();
    _evaluatorRoleController.dispose();
    _departmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidenceFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx', 'xlsx'],
      );

      if (result != null && result.paths.isNotEmpty) {
        setState(() {
          for (final path in result.paths) {
            if (path != null && path.isNotEmpty && !_newPickedFilePaths.contains(path) && !_existingEvidencePaths.contains(path)) {
              _newPickedFilePaths.add(path);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเลือกไฟล์ได้: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeExistingEvidence(int index) {
    setState(() {
      _existingEvidencePaths.removeAt(index);
    });
  }

  void _removeNewEvidence(int index) {
    setState(() {
      _newPickedFilePaths.removeAt(index);
    });
  }

  Future<void> _selectEvaluatedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _evaluatedDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0D9488)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _evaluatedDate = picked);
    }
  }

  Future<void> _selectNextReviewDate() async {
    final initial = _nextReviewDate ?? _evaluatedDate.add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2010),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0D9488)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _nextReviewDate = picked);
    }
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updated = widget.assessment.copyWith(
        isApplicable: _isApplicable,
        complianceStatus: _isApplicable ? _complianceStatus : 'NOT_APPLICABLE',
        actualPractice: _actualPracticeController.text.trim(),
        evaluatorName: _evaluatorNameController.text.trim(),
        evaluatorRole: _evaluatorRoleController.text.trim(),
        department: _departmentController.text.trim(),
        notes: _notesController.text.trim(),
        evaluatedDate: _evaluatedDate.toIso8601String().substring(0, 10),
        nextReviewDate: _nextReviewDate?.toIso8601String().substring(0, 10),
        evidenceFilePaths: _existingEvidencePaths,
      );

      final savedId = await ref.read(legalAssessmentListProvider.notifier).saveAssessment(
            updated,
            newEvidencePaths: _newPickedFilePaths,
          );

      final finalItem = updated.copyWith(id: updated.id ?? savedId);

      if (widget.onSaved != null) {
        widget.onSaved!(finalItem);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกผลการประเมินความสอดคล้องเรียบร้อยแล้ว'),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _triggerCreateCapa() {
    final currentItem = widget.assessment.copyWith(
      actualPractice: _actualPracticeController.text.trim(),
      complianceStatus: _complianceStatus,
    );

    if (widget.onCreateCapa != null) {
      Navigator.pop(context);
      widget.onCreateCapa!(currentItem);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => LegalCapaDialog(
          linkedAssessment: currentItem,
          onSaved: (capa) {
            ref.invalidate(legalCapaListProvider);
            ref.invalidate(legalAssessmentListProvider);
            ref.invalidate(legalComplianceKpiProvider);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assessment;
    final catEnum = a.categoryEnum;
    final riskEnum = a.riskLevelEnum;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        width: 820,
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
                  colors: [Color(0xFF0F172A), Color(0xFF0D9488)],
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
                    child: Icon(catEnum.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                a.requirementCode,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: riskEnum.bgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                riskEnum.labelTh,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: riskEnum.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ประเมินความสอดคล้อง: ${a.requirementTitle}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Law details box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFF0D9488)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${a.lawTitleTh} (${a.articleNo})',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              a.requirementDetails,
                              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.4),
                            ),
                            if (a.penaltySummary != null && a.penaltySummary!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.gavel_rounded, size: 14, color: Color(0xFFDC2626)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'บทกำหนดโทษ: ${a.penaltySummary}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFFDC2626),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Applicability Switch & Status
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: _isApplicable ? const Color(0xFFF0FDF4) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isApplicable ? const Color(0xFF86EFAC) : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isApplicable ? Icons.check_circle_outline_rounded : Icons.do_not_disturb_on_outlined,
                                    color: _isApplicable ? const Color(0xFF10B981) : Colors.grey.shade600,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ความเกี่ยวข้องกับสถานประกอบการ',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _isApplicable ? const Color(0xFF065F46) : Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          _isApplicable ? 'เกี่ยวข้องกับกิจกรรม/เครื่องจักรของโรงงาน' : 'ไม่มีกิจกรรมหรือกระบวนการที่ตรงกับข้อนี้',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _isApplicable,
                                    activeColor: const Color(0xFF10B981),
                                    onChanged: (val) {
                                      setState(() {
                                        _isApplicable = val;
                                        if (!val) _complianceStatus = 'NOT_APPLICABLE';
                                        if (val && _complianceStatus == 'NOT_APPLICABLE') {
                                          _complianceStatus = 'COMPLIANT';
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_isApplicable) ...[
                        const SizedBox(height: 20),

                        // Compliance Status Selector Buttons
                        const Text(
                          'ผลการประเมินความสอดคล้อง (Compliance Status) *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 600;
                            return isNarrow
                                ? Column(
                                    children: [
                                      _buildStatusChoice('COMPLIANT', '🟢 สอดคล้อง (Compliant)', const Color(0xFF10B981), const Color(0xFFECFDF5)),
                                      const SizedBox(height: 8),
                                      _buildStatusChoice('NON_COMPLIANT', '🔴 ไม่สอดคล้อง (Non-Compliant)', const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
                                      const SizedBox(height: 8),
                                      _buildStatusChoice('IN_PROGRESS', '🟡 อยู่ระหว่างดำเนินการ (In-Progress)', const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(child: _buildStatusChoice('COMPLIANT', '🟢 สอดคล้อง\n(Compliant)', const Color(0xFF10B981), const Color(0xFFECFDF5))),
                                      const SizedBox(width: 8),
                                      Expanded(child: _buildStatusChoice('NON_COMPLIANT', '🔴 ไม่สอดคล้อง\n(Non-Compliant)', const Color(0xFFEF4444), const Color(0xFFFEF2F2))),
                                      const SizedBox(width: 8),
                                      Expanded(child: _buildStatusChoice('IN_PROGRESS', '🟡 อยู่ระหว่างดำเนินการ\n(In-Progress)', const Color(0xFFF59E0B), const Color(0xFFFFFBEB))),
                                    ],
                                  );
                          },
                        ),

                        // Non-Compliant CAPA Alert & Quick Trigger
                        if (_complianceStatus == 'NON_COMPLIANT' || _complianceStatus == 'IN_PROGRESS') ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFCD34D)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_rounded, color: Color(0xFFD97706), size: 22),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ต้องจัดทำแผนงานแก้ไขและป้องกัน (CAPA)',
                                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                      ),
                                      Text(
                                        'เมื่อผลการประเมินไม่สอดคล้องหรืออยู่ระหว่างดำเนินการ ควรเปิดใบงาน CAPA เพื่อติดตามผล',
                                        style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _triggerCreateCapa,
                                  icon: const Icon(Icons.add_task_rounded, size: 16),
                                  label: const Text('เปิด CAPA ทันที'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD97706),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 20),

                      // Actual Practice Notes
                      const Text(
                        'การปฏิบัติตามจริงในสถานประกอบการ (Actual Practice & Controls) *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _actualPracticeController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'ระบุสภาพหน้างานจริง เช่น มีการแต่งตั้ง จป.เทคนิคขั้นสูง ผ่านระบบ e-Service กสร. แล้วเมื่อวันที่ 15 ม.ค. ...',
                          hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5)),
                        ),
                        validator: (val) {
                          if (_isApplicable && (val == null || val.trim().isEmpty)) {
                            return 'กรุณาระบุรายละเอียดการปฏิบัติตามจริง';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Evaluator Info & Dates
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ชื่อผู้ประเมิน *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _evaluatorNameController,
                                  decoration: InputDecoration(
                                    hintText: 'ชื่อ-นามสกุล จป. / ผู้ประเมิน',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อผู้ประเมิน' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ตำแหน่ง / บทบาท', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _evaluatorRoleController,
                                  decoration: InputDecoration(
                                    hintText: 'เช่น จป.วิชาชีพ / ผจก.ความปลอดภัย',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Department & Dates
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('แผนก / หน่วยงาน', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _departmentController,
                                  decoration: InputDecoration(
                                    hintText: 'ฝ่ายความปลอดภัยและสิ่งแวดล้อม',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                                const Text('วันที่ประเมิน', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _selectEvaluatedDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _evaluatedDate.toIso8601String().substring(0, 10),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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

                      // Evidence Attachments Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'เอกสารและหลักฐานอ้างอิง (Evidence & Attachments)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              Text(
                                'ประเภทที่แนะนำ: ${a.riskLevelEnum.labelTh} | ${a.categoryLabelTh}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickEvidenceFiles,
                            icon: const Icon(Icons.attach_file_rounded, size: 16),
                            label: const Text('แนบไฟล์หลักฐาน'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      if (_existingEvidencePaths.isEmpty && _newPickedFilePaths.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                          ),
                          child: Center(
                            child: Text(
                              'ยังไม่มีการแนบไฟล์หลักฐาน (สามารถแนบ PDF, ภาพถ่ายหน้างาน, แบบฟอร์มราชการ)',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Existing files
                            ..._existingEvidencePaths.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final filePath = entry.value;
                              final fileName = p.basename(filePath);
                              return _buildEvidenceChip(
                                fileName: fileName,
                                isNew: false,
                                onRemove: () => _removeExistingEvidence(idx),
                              );
                            }),
                            // Newly picked files
                            ..._newPickedFilePaths.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final filePath = entry.value;
                              final fileName = p.basename(filePath);
                              return _buildEvidenceChip(
                                fileName: fileName,
                                isNew: true,
                                onRemove: () => _removeNewEvidence(idx),
                              );
                            }),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // Next review date & General Notes
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('วันที่ทบทวนครั้งต่อไป (Next Review)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _selectNextReviewDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _nextReviewDate != null
                                              ? _nextReviewDate!.toIso8601String().substring(0, 10)
                                              : 'ยังไม่ได้ระบุ (คลิกเพื่อเลือก)',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _nextReviewDate != null ? Colors.black87 : Colors.grey.shade500,
                                          ),
                                        ),
                                        const Icon(Icons.event_repeat_rounded, size: 16, color: Color(0xFF0D9488)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      const Text('หมายเหตุเพิ่มเติม (Notes)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'บันทึกเพิ่มเติมหรือเงื่อนไขข้อยกเว้นทางกฎหมาย...',
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

            // Dialog Actions Footer
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
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveAssessment,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกผลการประเมิน'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
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

  Widget _buildStatusChoice(String code, String label, Color color, Color bgColor) {
    final isSelected = _complianceStatus == code;
    return InkWell(
      onTap: () {
        setState(() => _complianceStatus = code);
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
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

  Widget _buildEvidenceChip({
    required String fileName,
    required bool isNew,
    required VoidCallback onRemove,
  }) {
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNew ? const Color(0xFF93C5FD) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
            size: 16,
            color: isPdf ? const Color(0xFFDC2626) : const Color(0xFF0D9488),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              fileName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isNew) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(4)),
              child: const Text('ใหม่', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
