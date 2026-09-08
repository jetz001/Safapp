import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/risk_assessment_models.dart';
import '../../domain/models/risk_matrix_criteria.dart';
import '../providers/risk_assessment_providers.dart';
import 'interactive_risk_matrix_widget.dart';
import '../../../ppe_asl/domain/models/ppe_item_model.dart';
import '../../../ppe_asl/presentation/widgets/ppe_quick_picker_dialog.dart';

class HazardItemEditorDialog extends ConsumerStatefulWidget {
  final int stepId;
  final String stepName;
  final HazardEvaluationPor1? existingHazard;
  final RiskControlPlanPor2? existingPlan;

  const HazardItemEditorDialog({
    Key? key,
    required this.stepId,
    required this.stepName,
    this.existingHazard,
    this.existingPlan,
  }) : super(key: key);

  @override
  ConsumerState<HazardItemEditorDialog> createState() => _HazardItemEditorDialogState();
}

class _HazardItemEditorDialogState extends ConsumerState<HazardItemEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  // Por 1 Fields
  late TextEditingController _hazardTitleController;
  late TextEditingController _consequencesController;
  late TextEditingController _existingMeasuresController;
  late TextEditingController _recommendationController;

  int _likelihood = 1;
  int _severity = 1;

  // Por 2 Fields
  late TextEditingController _controlPlanController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _responsiblePersonController;
  late TextEditingController _supervisorMonitorController;
  String _planStatus = 'PLANNED';

  @override
  void initState() {
    super.initState();
    final h = widget.existingHazard;
    final p = widget.existingPlan;

    _hazardTitleController = TextEditingController(text: h?.hazardItemTitle ?? '');
    _consequencesController = TextEditingController(text: h?.potentialConsequences ?? '');
    _existingMeasuresController = TextEditingController(text: h?.existingControlMeasures ?? '');
    _recommendationController = TextEditingController(text: h?.recommendation ?? '');

    _likelihood = h?.likelihoodScore ?? 1;
    _severity = h?.severityScore ?? 1;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final in1Month = DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10);

    _controlPlanController = TextEditingController(text: p?.controlPlanDescription ?? h?.recommendation ?? '');
    _startDateController = TextEditingController(text: p?.startDate ?? today);
    _endDateController = TextEditingController(text: p?.endDate ?? in1Month);
    _responsiblePersonController = TextEditingController(text: p?.responsiblePerson ?? '');
    _supervisorMonitorController = TextEditingController(text: p?.supervisorMonitor ?? '');
    if (p != null) _planStatus = p.status;
  }

  @override
  void dispose() {
    _hazardTitleController.dispose();
    _consequencesController.dispose();
    _existingMeasuresController.dispose();
    _recommendationController.dispose();
    _controlPlanController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _responsiblePersonController.dispose();
    _supervisorMonitorController.dispose();
    super.dispose();
  }

  Future<void> _pickPpeFor(TextEditingController controller) async {
    final selected = await showDialog<List<PpeItem>>(
      context: context,
      builder: (ctx) => const PpeQuickPickerDialog(),
    );
    if (selected != null && selected.isNotEmpty) {
      final ppeNames = selected.map((e) => '${e.name} (${e.standardCert})').join(', ');
      final current = controller.text.trim();
      if (current.isEmpty) {
        controller.text = 'สวมใส่อุปกรณ์ PPE: $ppeNames';
      } else {
        controller.text = '$current, สวมใส่ PPE: $ppeNames';
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(riskAssessmentRepoProvider);
    final eval = RiskMatrixCriteria.evaluate(_likelihood, _severity);

    // 1. Save Hazard Por 1
    final hazard = HazardEvaluationPor1(
      id: widget.existingHazard?.id,
      stepId: widget.stepId,
      hazardItemTitle: _hazardTitleController.text.trim(),
      potentialConsequences: _consequencesController.text.trim(),
      existingControlMeasures: _existingMeasuresController.text.trim(),
      recommendation: _recommendationController.text.trim(),
      likelihoodScore: _likelihood,
      severityScore: _severity,
      riskScore: eval.score,
      riskLevel: eval.codeName,
      riskLevelThai: eval.thaiName,
      requiresPor2: eval.requiresPor2,
    );

    final savedHazardId = await repo.saveHazardPor1(hazard);

    // 2. Save Plan Por 2 if required
    if (eval.requiresPor2) {
      final plan = RiskControlPlanPor2(
        id: widget.existingPlan?.id,
        hazardId: savedHazardId,
        controlPlanDescription: _controlPlanController.text.trim().isNotEmpty
            ? _controlPlanController.text.trim()
            : _recommendationController.text.trim(),
        startDate: _startDateController.text.trim(),
        endDate: _endDateController.text.trim(),
        responsiblePerson: _responsiblePersonController.text.trim().isNotEmpty
            ? _responsiblePersonController.text.trim()
            : 'ผู้จัดการแผนก / หัวหน้างาน',
        supervisorMonitor: _supervisorMonitorController.text.trim().isNotEmpty
            ? _supervisorMonitorController.text.trim()
            : 'จป.วิชาชีพ',
        actionTrackerId: widget.existingPlan?.actionTrackerId,
        status: _planStatus,
      );

      await repo.savePlanPor2(plan, hazardTitle: hazard.hazardItemTitle);
    } else if (widget.existingPlan?.id != null) {
      // If downgraded to low/very low and plan existed, delete old plan
      await repo.deletePlanPor2(widget.existingPlan!.id!);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกผลการประเมินอันตรายเรียบร้อยแล้ว')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eval = RiskMatrixCriteria.evaluate(_likelihood, _severity);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 850,
        constraints: const BoxConstraints(maxHeight: 760),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existingHazard == null
                              ? 'ชี้บ่งและประเมินอันตราย (แบบ ปอ.๑)'
                              : 'แก้ไขการประเมินอันตราย (แบบ ปอ.๑)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'ขั้นตอนงาน: ${widget.stepName}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Form Scroll Area
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section A: ข้อมูลอันตราย
                      TextFormField(
                        controller: _hazardTitleController,
                        decoration: const InputDecoration(
                          labelText: 'สิ่งและลักษณะอันตราย *',
                          hintText: 'เช่น สารเคมีกระเด็นเข้าตา, ชิ้นงานหนีบนิ้วมือ, เสียงดังเกินเกณฑ์',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกสิ่งและลักษณะอันตราย' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _consequencesController,
                        decoration: const InputDecoration(
                          labelText: 'ผลกระทบที่อาจเกิดขึ้น (ต่อร่างกาย จิตใจ หรือทรัพย์สิน) *',
                          hintText: 'เช่น เยื่อบุตาอักเสบ, นิ้วมือแตกหัก, สูญเสียการได้ยิน, ทรัพย์สินเสียหาย',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุผลกระทบที่อาจเกิดขึ้น' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _existingMeasuresController,
                              decoration: InputDecoration(
                                labelText: 'มาตรการป้องกันและควบคุมอันตรายที่มีอยู่เดิม',
                                hintText: 'เช่น มี Guard ครอบ, สวมแว่นนิรภัย, มี WI การทำงาน',
                                border: const OutlineInputBorder(),
                                isDense: true,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 18),
                                  tooltip: 'เลือกอุปกรณ์ PPE จากคลัง (ม.๒๒)',
                                  onPressed: () => _pickPpeFor(_existingMeasuresController),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _recommendationController,
                              decoration: InputDecoration(
                                labelText: 'ข้อเสนอแนะ / มาตรการที่เสนอแนะเพิ่ม',
                                hintText: 'เช่น ติดตั้ง Interlock Switch, เปลี่ยนชนิดถุงมือ',
                                border: const OutlineInputBorder(),
                                isDense: true,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 18),
                                  tooltip: 'เลือกอุปกรณ์ PPE จากคลัง (ม.๒๒)',
                                  onPressed: () => _pickPpeFor(_recommendationController),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _pickPpeFor(_existingMeasuresController),
                          icon: const Icon(Icons.add_moderator, size: 16, color: Color(0xFF2563EB)),
                          label: const Text(
                            '+ เลือกอุปกรณ์ PPE ตามมาตรฐาน ม.๒๒ ใส่ในมาตรการควบคุม',
                            style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section B: Interactive 3x3 Risk Matrix Scoring
                      const Text(
                        'การประเมินคะแนนความเป็นอันตราย (โอกาส x ความรุนแรง ตามเกณฑ์กระทรวงแรงงาน):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 8),
                      InteractiveRiskMatrixWidget(
                        selectedLikelihood: _likelihood,
                        selectedSeverity: _severity,
                        onSelectionChanged: (l, s) {
                          setState(() {
                            _likelihood = l;
                            _severity = s;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Section C: แผน ปอ.๒ (เปิดเมื่อระดับปานกลาง, สูง, หรือสูงมาก)
                      if (eval.requiresPor2) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade600, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.assignment_turned_in_rounded, color: Colors.amber.shade900, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'แผนดำเนินงานด้านความปลอดภัยฯ (แบบ ปอ. ๒)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'ระดับ: ${eval.thaiName}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: eval.color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'เนื่องจากรายการนี้ได้คะแนน ${eval.score} (${eval.thaiName}) ซึ่งเป็นระดับอันตรายที่ต้องจัดทำแผนดำเนินงานเพื่อลดและควบคุมความเสี่ยงตามกฎหมาย',
                                style: const TextStyle(fontSize: 11, color: Colors.black87),
                              ),
                              const Divider(height: 16),
                              TextFormField(
                                controller: _controlPlanController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'แผนการดำเนินงานเพื่อลดและควบคุมอันตราย (มาตรการ/กิจกรรม/หลักเกณฑ์มาตรฐาน) *',
                                  hintText: 'ระบุกิจกรรมแก้ไข มาตรการวิศวกรรม หรือระเบียบปฏิบัติที่ต้องเพิ่ม',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                validator: (v) => eval.requiresPor2 && (v == null || v.trim().isEmpty)
                                    ? 'กรุณากรอกแผนดำเนินงาน ปอ.๒'
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _startDateController,
                                      decoration: const InputDecoration(
                                        labelText: 'วันที่เริ่มดำเนินการ (YYYY-MM-DD)',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        fillColor: Colors.white,
                                        filled: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _endDateController,
                                      decoration: const InputDecoration(
                                        labelText: 'วันที่สิ้นสุด / กำหนดเสร็จ (YYYY-MM-DD)',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        fillColor: Colors.white,
                                        filled: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _responsiblePersonController,
                                      decoration: const InputDecoration(
                                        labelText: 'ผู้รับผิดชอบ *',
                                        hintText: 'เช่น นายสมชาย หัวหน้าแผนก',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        fillColor: Colors.white,
                                        filled: true,
                                      ),
                                      validator: (v) => eval.requiresPor2 && (v == null || v.trim().isEmpty)
                                          ? 'กรุณาระบุผู้รับผิดชอบ'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _supervisorMonitorController,
                                      decoration: const InputDecoration(
                                        labelText: 'ผู้ตรวจติดตาม *',
                                        hintText: 'เช่น จป.วิชาชีพ / ผจก.โรงงาน',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        fillColor: Colors.white,
                                        filled: true,
                                      ),
                                      validator: (v) => eval.requiresPor2 && (v == null || v.trim().isEmpty)
                                          ? 'กรุณาระบุผู้ตรวจติดตาม'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      value: _planStatus,
                                      decoration: const InputDecoration(
                                        labelText: 'สถานะมาตรการ',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        fillColor: Colors.white,
                                        filled: true,
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'PLANNED', child: Text('วางแผน (Planned)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11))),
                                        DropdownMenuItem(value: 'IN_PROGRESS', child: Text('กำลังทำ (In Progress)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11))),
                                        DropdownMenuItem(value: 'COMPLETED', child: Text('เสร็จ (Completed)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11))),
                                      ],
                                      onChanged: (v) {
                                        if (v != null) setState(() => _planStatus = v);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 20),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ยกเลิก'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('บันทึกผลการประเมิน'),
                    onPressed: _save,
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
