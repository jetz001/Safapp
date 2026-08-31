import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/risk_assessment_models.dart';
import '../../domain/models/risk_matrix_criteria.dart';
import '../providers/risk_assessment_providers.dart';

class SessionEditDialog extends ConsumerStatefulWidget {
  final RiskAssessmentSession? existingSession;

  const SessionEditDialog({Key? key, this.existingSession}) : super(key: key);

  @override
  ConsumerState<SessionEditDialog> createState() => _SessionEditDialogState();
}

class _SessionEditDialogState extends ConsumerState<SessionEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _dateController;
  late TextEditingController _nextReviewDateController;
  late TextEditingController _hazardMethodOtherController;
  late TextEditingController _hazardStandardApprovedController;
  late TextEditingController _assessor1NameController;
  late TextEditingController _assessor1PositionController;
  late TextEditingController _assessor2NameController;
  late TextEditingController _assessor2PositionController;
  late TextEditingController _expertOpinionController;

  String _assessmentType = 'PERIODIC';
  String _hazardIdMethod = RiskMatrixCriteria.hazardIdentificationMethods.first;
  String _status = 'DRAFT';

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final in3Years = DateTime.now().add(const Duration(days: 365 * 3)).toIso8601String().substring(0, 10);

    final s = widget.existingSession;
    _titleController = TextEditingController(text: s?.sessionTitle ?? 'การประเมินอันตรายและการศึกษาผลกระทบประจำปี');
    _dateController = TextEditingController(text: s?.assessmentDate ?? today);
    _nextReviewDateController = TextEditingController(text: s?.nextReviewDate ?? in3Years);
    _hazardMethodOtherController = TextEditingController(text: s?.hazardIdMethodOther ?? '');
    _hazardStandardApprovedController = TextEditingController(text: s?.hazardIdStandardApproved ?? '');
    final profileAsync = ref.read(companyProfileNotifierProvider);
    final profile = profileAsync.value;
    final defaultAssessorName = (s != null && s.assessor1Name != null && s.assessor1Name!.isNotEmpty)
        ? s.assessor1Name!
        : (profile?.safetyOfficerName ?? '');
    final defaultAssessorRole = (s != null && s.assessor1Position != null && s.assessor1Position!.isNotEmpty)
        ? s.assessor1Position!
        : (profile?.safetyOfficerLevel ?? 'เจ้าหน้าที่ความปลอดภัยในการทำงาน (จป.)');

    _assessor1NameController = TextEditingController(text: defaultAssessorName);
    _assessor1PositionController = TextEditingController(text: defaultAssessorRole);
    _assessor2NameController = TextEditingController(text: s?.assessor2Name ?? '');
    _assessor2PositionController = TextEditingController(text: s?.assessor2Position ?? 'ตัวแทนลูกจ้างผู้ปฏิบัติงาน');
    _expertOpinionController = TextEditingController(text: s?.expertOpinion ?? '');

    if (s != null) {
      _assessmentType = s.assessmentType;
      _hazardIdMethod = s.hazardIdMethod;
      _status = s.status;
    }
  }

  void _onTypeChanged(String? val) {
    if (val == null) return;
    setState(() {
      _assessmentType = val;
      if (val == 'PERIODIC') {
        _nextReviewDateController.text =
            DateTime.now().add(const Duration(days: 365 * 3)).toIso8601String().substring(0, 10);
      } else {
        _nextReviewDateController.text =
            DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _nextReviewDateController.dispose();
    _hazardMethodOtherController.dispose();
    _hazardStandardApprovedController.dispose();
    _assessor1NameController.dispose();
    _assessor1PositionController.dispose();
    _assessor2NameController.dispose();
    _assessor2PositionController.dispose();
    _expertOpinionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final session = RiskAssessmentSession(
      id: widget.existingSession?.id,
      sessionTitle: _titleController.text.trim(),
      assessmentType: _assessmentType,
      assessmentDate: _dateController.text.trim(),
      nextReviewDate: _nextReviewDateController.text.trim(),
      hazardIdMethod: _hazardIdMethod,
      hazardIdMethodOther: _hazardMethodOtherController.text.trim(),
      hazardIdStandardApproved: _hazardStandardApprovedController.text.trim(),
      assessor1Name: _assessor1NameController.text.trim(),
      assessor1Position: _assessor1PositionController.text.trim(),
      assessor2Name: _assessor2NameController.text.trim(),
      assessor2Position: _assessor2PositionController.text.trim(),
      expertOpinion: _expertOpinionController.text.trim(),
      status: _status,
    );

    final savedId = await ref.read(riskSessionsProvider.notifier).saveSession(session);
    if (mounted) {
      Navigator.of(context).pop(savedId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกชุดการประเมิน "${session.sessionTitle}" เรียบร้อยแล้ว')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 750,
        constraints: const BoxConstraints(maxHeight: 680),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.assessment_rounded, color: Colors.amber.shade800),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.existingSession == null ? 'สร้างชุดการประเมินอันตรายใหม่' : 'แก้ไขข้อมูลชุดการประเมินอันตราย',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'หัวข้อชุดการประเมิน *',
                          hintText: 'เช่น การประเมินอันตรายประจำปี ๒๕๖๘ (รอบ 3 ปี)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุหัวข้อการประเมิน' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _assessmentType,
                              decoration: const InputDecoration(
                                labelText: 'ประเภทรอบการประเมินตามกฎหมาย *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'PERIODIC',
                                  child: Text('รอบปกติ (ทบทวนทุก ๓ ปี - ข้อ ๕ วรรค ๑)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)),
                                ),
                                DropdownMenuItem(
                                  value: 'MOC',
                                  child: Text('รอบปรับปรุง/เปลี่ยนแปลง MOC (เสร็จใน ๓๐ วัน)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)),
                                ),
                              ],
                              onChanged: _onTypeChanged,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _status,
                              decoration: const InputDecoration(
                                labelText: 'สถานะรายงาน',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'DRAFT', child: Text('ร่าง (Draft)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'ENDORSED', child: Text('รับรองแล้ว (Endorsed)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'SUBMITTED', child: Text('จัดส่งกรมแรงงานแล้ว (Submitted)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12))),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _status = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dateController,
                              decoration: const InputDecoration(
                                labelText: 'วันที่ดำเนินการประเมิน (YYYY-MM-DD) *',
                                border: OutlineInputBorder(),
                                isDense: true,
                                suffixIcon: Icon(Icons.calendar_today, size: 18),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุวันที่ประเมิน' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _nextReviewDateController,
                              decoration: const InputDecoration(
                                labelText: 'วันครบกำหนดทบทวนครั้งต่อไป (YYYY-MM-DD)',
                                border: OutlineInputBorder(),
                                isDense: true,
                                suffixIcon: Icon(Icons.event_repeat, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Hazard Identification Method (ข้อ ๖)
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _hazardIdMethod,
                        decoration: const InputDecoration(
                          labelText: 'วิธีการชี้บ่งอันตราย (ตามข้อ ๖ แห่งประกาศกระทรวงแรงงาน) *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: RiskMatrixCriteria.hazardIdentificationMethods.map((m) {
                          return DropdownMenuItem<String>(
                            value: m,
                            child: Text(m, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _hazardIdMethod = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_hazardIdMethod.contains('วิธีการอื่น')) ...[
                        TextFormField(
                          controller: _hazardMethodOtherController,
                          decoration: const InputDecoration(
                            labelText: 'ระบุวิธีการอื่น / มาตรฐานสากล',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _hazardStandardApprovedController,
                          decoration: const InputDecoration(
                            labelText: 'รายละเอียดหนังสือเห็นชอบจากกรมสวัสดิการและคุ้มครองแรงงาน (ถ้ามี)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Assessors (ข้อ ๕ วรรคสาม)
                      const Text(
                        'คณะผู้ทำหน้าที่ในการประเมินอันตราย (อย่างน้อย ๒ คน ตามกฎหมาย):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _assessor1NameController,
                              decoration: const InputDecoration(
                                labelText: '๑. ชื่อ-นามสกุล ผู้ประเมิน (จป./ผู้มีความรู้)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _assessor1PositionController,
                              decoration: const InputDecoration(
                                labelText: 'ตำแหน่ง',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _assessor2NameController,
                              decoration: const InputDecoration(
                                labelText: '๒. ชื่อ-นามสกุล ลูกจ้างผู้ปฏิบัติงาน/ตัวแทน',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _assessor2PositionController,
                              decoration: const InputDecoration(
                                labelText: 'ตำแหน่ง',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _expertOpinionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'สรุปความเห็นของผู้ชำนาญการด้านความปลอดภัย อาชีวอนามัย (ม.๓๓)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
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
                      backgroundColor: Colors.amber.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('บันทึกชุดการประเมิน'),
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
