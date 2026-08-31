import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/accident_models.dart';
import '../providers/accident_providers.dart';
import '../../services/accident_official_pdf_service.dart';
import '../../../employee/domain/models/employee_models.dart';
import '../../../employee/presentation/providers/employee_providers.dart';
import '../../../risk_assessment/presentation/providers/risk_assessment_providers.dart';

class IncidentQuickReportDialog extends ConsumerStatefulWidget {
  const IncidentQuickReportDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<IncidentQuickReportDialog> createState() => _IncidentQuickReportDialogState();
}

class _IncidentQuickReportDialogState extends ConsumerState<IncidentQuickReportDialog> {
  final _formKey = GlobalKey<FormState>();

  String _eventType = 'NEAR_MISS';
  late TextEditingController _titleController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _locationController;

  // Injured Person
  int? _selectedEmployeeId;
  String _employeeType = 'EMPLOYEE';
  late TextEditingController _nameController;
  late TextEditingController _nationalIdController;
  late TextEditingController _positionController;
  late TextEditingController _deptController;
  late TextEditingController _hospitalController;
  late TextEditingController _injuryNatureController;
  late TextEditingController _bodyPartController;
  late TextEditingController _descriptionController;

  final List<String> _photoPaths = [];
  bool _isSaving = false;

  final List<String> _injuryNatures = [
    'แผลฉีกขาด / ถูกของมีคมบาด (Cut / Laceration)',
    'กระดูกหัก / ข้อเคลื่อน (Fracture / Dislocation)',
    'ถูกกระแทก / ฟกช้ำ (Contusion / Bruise)',
    'แผลไฟไหม้ / น้ำร้อนลวก (Burn / Scald)',
    'สารเคมีกระเด็นใส่ / สัมผัสสารพิษ (Chemical Exposure)',
    'สัมผัสกระแสไฟฟ้า (Electric Shock)',
    'สิ่งแปลกปลอมเข้าตา (Eye Injury)',
    'สูญเสียอวัยวะ (Amputation)',
    'กล้ามเนื้ออักเสบ / เคล็ดขัดยอก (Strain / Sprain)',
    'อื่นๆ',
  ];

  final List<String> _bodyParts = [
    'ศีรษะ / ใบหน้า (Head / Face)',
    'ตา (Eye)',
    'มือ / ข้อมือ / นิ้วมือ (Hand / Wrist / Fingers)',
    'แขน / ข้อศอก (Arm / Elbow)',
    'ขา / เข่า (Leg / Knee)',
    'เท้า / ข้อเท้า / นิ้วเท้า (Foot / Ankle / Toes)',
    'ลำตัว / หน้าอก / หลัง (Torso / Chest / Back)',
    'หลายส่วนของร่างกาย (Multiple Parts)',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _titleController = TextEditingController();
    _dateController = TextEditingController(text: now.toIso8601String().substring(0, 10));
    _timeController = TextEditingController(text: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}');
    _locationController = TextEditingController(text: 'อาคารผลิตหลัก ชั้น ๑');
    _nameController = TextEditingController();
    _nationalIdController = TextEditingController();
    _positionController = TextEditingController();
    _deptController = TextEditingController();
    _hospitalController = TextEditingController(text: 'โรงพยาบาลในความตกลง กองทุนเงินทดแทน');
    _injuryNatureController = TextEditingController(text: 'แผลฉีกขาด / ถูกของมีคมบาด (Cut / Laceration)');
    _bodyPartController = TextEditingController(text: 'มือ / ข้อมือ / นิ้วมือ (Hand / Wrist / Fingers)');
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _nameController.dispose();
    _nationalIdController.dispose();
    _positionController.dispose();
    _deptController.dispose();
    _hospitalController.dispose();
    _injuryNatureController.dispose();
    _bodyPartController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onEmployeeSelected(int? empId, List<Employee> employees) {
    if (empId == null) return;
    setState(() {
      _selectedEmployeeId = empId;
      final emp = employees.firstWhere((e) => e.id == empId, orElse: () => employees.first);
      _nameController.text = emp.fullName;
      _nationalIdController.text = emp.nationalId ?? '';
      _positionController.text = emp.position;
      _deptController.text = emp.department;
    });
  }

  Future<void> _pickPhotos() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (final f in result.files) {
          if (f.path != null && !_photoPaths.contains(f.path!)) {
            _photoPaths.add(f.path!);
          }
        }
      });
    }
  }

  Future<AccidentInvestigation?> _save() async {
    if (!_formKey.currentState!.validate()) return null;

    setState(() => _isSaving = true);
    try {
      final eventNo = 'INC-${DateTime.now().toIso8601String().substring(0, 10).replaceAll("-", "")}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      final investigation = AccidentInvestigation(
        eventNo: eventNo,
        eventType: _eventType,
        incidentTitle: _titleController.text.trim(),
        incidentDate: _dateController.text.trim(),
        incidentTime: _timeController.text.trim(),
        incidentLocation: _locationController.text.trim(),
        employeeId: _selectedEmployeeId,
        employeeType: _employeeType,
        injuredPersonName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        injuredPersonNationalId: _nationalIdController.text.trim().isEmpty ? null : _nationalIdController.text.trim(),
        injuredPersonPosition: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
        injuredPersonDepartment: _deptController.text.trim().isEmpty ? null : _deptController.text.trim(),
        injuryNature: _eventType != 'NEAR_MISS' ? _injuryNatureController.text.trim() : null,
        injuredBodyPart: _eventType != 'NEAR_MISS' ? _bodyPartController.text.trim() : null,
        hospitalName: _eventType != 'NEAR_MISS' ? _hospitalController.text.trim() : null,
        hospitalSentDate: _eventType != 'NEAR_MISS' ? _dateController.text.trim() : null,
        description5w1h: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        photoPaths: _photoPaths,
        status: 'INVESTIGATING',
      );

      final id = await ref.read(accidentInvestigationsProvider.notifier).saveInvestigation(investigation, newPhotos: _photoPaths);
      final savedInv = investigation.copyWith(id: id);

      if (mounted) {
        Navigator.of(context).pop(savedInv);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกรายงานอุบัติเหตุ/Near Miss เลขที่ $eventNo เรียบร้อย'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
      return savedInv;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAndPrintKorTor44() async {
    final saved = await _save();
    if (saved != null && mounted) {
      final profile = ref.read(companyProfileNotifierProvider).asData?.value;
      await AccidentOfficialPdfService.printKorTor44Document(
        context: context,
        investigation: saved,
        company: profile,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);
    final isNearMiss = _eventType == 'NEAR_MISS';

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'บันทึกรายงานอุบัติเหตุ / Near Miss ด่วน (Incident Flash Report)',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. ระดับความรุนแรง
                _buildSectionHeader('๑. ประเภทเหตุการณ์และระดับความรุนแรง'),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _eventType,
                  decoration: _inputDecoration('ประเภทเหตุการณ์ *', icon: Icons.report_problem),
                  items: const [
                    DropdownMenuItem(value: 'NEAR_MISS', child: Text('⚠️ เหตุการณ์เกือบเกิดอุบัติเหตุ (Near Miss - ไม่มีความเสียหาย/บาดเจ็บ)')),
                    DropdownMenuItem(value: 'FIRST_AID', child: Text('🩹 ปฐมพยาบาลเบื้องต้น (First Aid - ไม่หยุดงาน)')),
                    DropdownMenuItem(value: 'LOST_TIME', child: Text('🏥 อุบัติเหตุถึงขั้นหยุดงาน (Lost Time Injury - LTI)')),
                    DropdownMenuItem(value: 'DISABILITY', child: Text('🦽 สูญเสียอวัยวะ / ทุพพลภาพ (Disability)')),
                    DropdownMenuItem(value: 'FATALITY', child: Text('⚰️ อุบัติเหตุถึงแก่ชีวิต (Fatality)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _eventType = v);
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration('หัวข้อเหตุการณ์ / ลักษณะอุบัติเหตุ *', icon: Icons.title),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุหัวข้อเหตุการณ์' : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dateController,
                        decoration: _inputDecoration('วันที่เกิดเหตุ *', icon: Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _timeController,
                        decoration: _inputDecoration('เวลาที่เกิดเหตุ (น.) *', icon: Icons.access_time),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _locationController,
                        decoration: _inputDecoration('สถานที่ / จุดเกิดเหตุ *', icon: Icons.location_on),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. ผู้ประสบเหตุ (ถ้าไม่ใช่ Near Miss)
                if (!isNearMiss) ...[
                  _buildSectionHeader('๒. ข้อมูลผู้ประสบอันตราย & การส่งตัวรักษาพยาบาล'),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: employeesAsync.when(
                          data: (employees) {
                            return DropdownButtonFormField<int?>(
                              isExpanded: true,
                              value: _selectedEmployeeId,
                              decoration: _inputDecoration('เลือกจากพนักงานในระบบ (Auto-fill)', icon: Icons.person_search),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('- กรอกชื่อเอง / ผู้รับเหมา -', style: TextStyle(fontSize: 12))),
                                ...employees.map((e) => DropdownMenuItem(
                                      value: e.id,
                                      child: Text('${e.employeeCode} - ${e.fullName} (${e.department})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                    )),
                              ],
                              onChanged: (v) => _onEmployeeSelected(v, employees),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _employeeType,
                          decoration: _inputDecoration('ประเภทบุคคล', icon: Icons.badge),
                          items: const [
                            DropdownMenuItem(value: 'EMPLOYEE', child: Text('พนักงานประจำ')),
                            DropdownMenuItem(value: 'CONTRACTOR', child: Text('คนงานผู้รับเหมา')),
                            DropdownMenuItem(value: 'THIRD_PARTY', child: Text('บุคคลภายนอก')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _employeeType = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration('ชื่อ - นามสกุล ผู้ประสบเหตุ *', icon: Icons.person),
                          validator: (v) => !isNearMiss && (v == null || v.trim().isEmpty) ? 'กรุณาระบุชื่อผู้ประสบเหตุ' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _nationalIdController,
                          decoration: _inputDecoration('เลขบัตรประชาชน', icon: Icons.credit_card),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _deptController,
                          decoration: _inputDecoration('แผนก / ฝ่าย', icon: Icons.domain),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _positionController,
                          decoration: _inputDecoration('ตำแหน่งงาน', icon: Icons.work_outline),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _injuryNatureController.text,
                          decoration: _inputDecoration('ลักษณะบาดแผล *', icon: Icons.healing),
                          items: _injuryNatures.map((n) => DropdownMenuItem(value: n, child: Text(n, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)))).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _injuryNatureController.text = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _bodyPartController.text,
                          decoration: _inputDecoration('อวัยวะที่บาดเจ็บ *', icon: Icons.accessibility_new),
                          items: _bodyParts.map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)))).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _bodyPartController.text = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _hospitalController,
                    decoration: _inputDecoration('ชื่อโรงพยาบาล / สถานพยาบาลที่ส่งตัวรักษา (สำหรับ กท.๔๔)', icon: Icons.local_hospital),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. รายละเอียดเหตุการณ์เบื้องต้น
                _buildSectionHeader('๓. รายละเอียดเหตุการณ์ที่เกิดขึ้น'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _inputDecoration('อธิบายสิ่งที่เกิดขึ้น ผู้เห็นเหตุการณ์ และการช่วยเหลือเบื้องต้น *', icon: Icons.description),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุรายละเอียดเหตุการณ์' : null,
                ),
                const SizedBox(height: 12),

                // Attach Photos
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickPhotos,
                      icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                      label: const Text('แนบภาพถ่ายที่เกิดเหตุ'),
                    ),
                    const SizedBox(width: 12),
                    Text('${_photoPaths.length} ภาพที่แนบ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                if (_photoPaths.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photoPaths.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, idx) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(File(_photoPaths[idx]), width: 60, height: 60, fit: BoxFit.cover),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        if (!isNearMiss) ...[
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveAndPrintKorTor44,
            icon: const Icon(Icons.local_hospital_rounded, size: 16),
            label: const Text('บันทึก & พิมพ์ใบส่งตัว กท.๔๔ ทันที'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกรายงานเหตุ'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade400, size: 18) : null,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
      ),
    );
  }
}
