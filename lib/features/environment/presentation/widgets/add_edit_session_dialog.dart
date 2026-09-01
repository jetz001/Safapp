import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/environment_session_model.dart';
import '../../domain/models/subcontractor_model.dart';
import '../providers/environment_providers.dart';

/// Dialog for creating or editing an Environmental Monitoring Session.
class AddEditSessionDialog extends ConsumerStatefulWidget {
  final EnvironmentSessionModel? session;
  final ValueChanged<EnvironmentSessionModel>? onSaved;

  const AddEditSessionDialog({
    Key? key,
    this.session,
    this.onSaved,
  }) : super(key: key);

  @override
  ConsumerState<AddEditSessionDialog> createState() => _AddEditSessionDialogState();
}

class _AddEditSessionDialogState extends ConsumerState<AddEditSessionDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _sessionIdCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _yearBeCtrl;
  late TextEditingController _measDateCtrl;
  late TextEditingController _locationPlantCtrl;
  late TextEditingController _workplaceNameCtrl;
  late TextEditingController _workplaceAddressCtrl;
  late TextEditingController _objectiveCtrl;
  late TextEditingController _subcontractorCompanyCtrl;
  late TextEditingController _subcontractorRegCtrl;
  late TextEditingController _surveyorNameCtrl;
  late TextEditingController _surveyorLicenseCtrl;
  late TextEditingController _certifierNameCtrl;
  late TextEditingController _certifierRegCtrl;
  late TextEditingController _notesCtrl;

  late SubcontractorType _selectedSubcontractorType;
  late EnvironmentSessionStatus _selectedStatus;
  List<String> _calibrationCerts = [];
  List<String> _sitePhotos = [];
  String? _pdfReportPath;
  String? _licenseDocPath;

  @override
  void initState() {
    super.initState();
    final s = widget.session;

    final now = DateTime.now();
    final currentYearBe = now.year + 543;
    final defaultId = 'ENV-SESS-${now.year}-${(now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}';

    _sessionIdCtrl = TextEditingController(text: s?.sessionId ?? defaultId);
    _titleCtrl = TextEditingController(text: s?.sessionTitle ?? 'ตรวจวัดสภาพแวดล้อมประจำปี $currentYearBe');
    _yearBeCtrl = TextEditingController(text: (s?.sessionYearBe ?? currentYearBe).toString());
    _measDateCtrl = TextEditingController(text: s?.measurementDate ?? now.toIso8601String().substring(0, 10));
    _locationPlantCtrl = TextEditingController(text: s?.locationPlant ?? 'โรงงานหลัก (Main Plant)');
    _workplaceNameCtrl = TextEditingController(text: s?.workplaceName ?? 'บริษัท โรงงานอุตสาหกรรมตัวอย่าง จำกัด (มหาชน)');
    _workplaceAddressCtrl = TextEditingController(text: s?.workplaceAddress ?? '123/45 นิคมอุตสาหกรรม ตำบลคลองหนึ่ง อำเภอคลองหลวง จังหวัดปทุมธานี 12120');
    _objectiveCtrl = TextEditingController(text: s?.objective ?? 'ตรวจวัดและวิเคราะห์สภาวะการทำงานประจำปีตามกฎหมายความปลอดภัยฯ');
    _subcontractorCompanyCtrl = TextEditingController(text: s?.subcontractorCompanyName ?? 'บริษัท สิ่งแวดล้อมปลอดภัยตรวจวัด จำกัด');
    _subcontractorRegCtrl = TextEditingController(text: s?.subcontractorRegNumber ?? 'บ. 0045-12/2565');
    _surveyorNameCtrl = TextEditingController(text: s?.surveyorName ?? 'นายตรวจวัด ชำนาญการ');
    _surveyorLicenseCtrl = TextEditingController(text: s?.surveyorLicenseNo ?? 'ENV-TECH-2565-019');
    _certifierNameCtrl = TextEditingController(text: s?.certifierName ?? 'นายวิศวกร สิ่งแวดล้อม (วศ.บ.)');
    _certifierRegCtrl = TextEditingController(text: s?.certifierRegNo ?? 'บ. 0045-12/2565');
    _notesCtrl = TextEditingController(text: s?.notes ?? '');

    _selectedSubcontractorType = s?.subcontractorType ?? SubcontractorType.section11Juristic;
    _selectedStatus = s?.status ?? EnvironmentSessionStatus.planned;
    _calibrationCerts = List.from(s?.calibrationCertPaths ?? []);
    _sitePhotos = List.from(s?.sitePhotoPaths ?? []);
    _pdfReportPath = s?.pdfReportPath;
    _licenseDocPath = s?.subcontractorLicensePath;
  }

  @override
  void dispose() {
    _sessionIdCtrl.dispose();
    _titleCtrl.dispose();
    _yearBeCtrl.dispose();
    _measDateCtrl.dispose();
    _locationPlantCtrl.dispose();
    _workplaceNameCtrl.dispose();
    _workplaceAddressCtrl.dispose();
    _objectiveCtrl.dispose();
    _subcontractorCompanyCtrl.dispose();
    _subcontractorRegCtrl.dispose();
    _surveyorNameCtrl.dispose();
    _surveyorLicenseCtrl.dispose();
    _certifierNameCtrl.dispose();
    _certifierRegCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final yearBe = int.tryParse(_yearBeCtrl.text.trim()) ?? (DateTime.now().year + 543);
    final yearAd = yearBe - 543;
    final measDate = _measDateCtrl.text.trim();

    final session = EnvironmentSessionModel(
      id: widget.session?.id,
      sessionId: _sessionIdCtrl.text.trim(),
      sessionTitle: _titleCtrl.text.trim(),
      sessionYearBe: yearBe,
      sessionYearAd: yearAd,
      measurementDate: measDate,
      postingDeadline: EnvironmentSessionModel.calculatePostingDeadline(measDate),
      submissionDeadline: EnvironmentSessionModel.calculateSubmissionDeadline(measDate),
      locationPlant: _locationPlantCtrl.text.trim(),
      workplaceName: _workplaceNameCtrl.text.trim(),
      workplaceAddress: _workplaceAddressCtrl.text.trim(),
      objective: _objectiveCtrl.text.trim(),
      subcontractorType: _selectedSubcontractorType,
      subcontractorCompanyName: _subcontractorCompanyCtrl.text.trim(),
      subcontractorRegNumber: _subcontractorRegCtrl.text.trim(),
      surveyorName: _surveyorNameCtrl.text.trim(),
      surveyorLicenseNo: _surveyorLicenseCtrl.text.trim(),
      certifierName: _certifierNameCtrl.text.trim(),
      certifierRegNo: _certifierRegCtrl.text.trim(),
      status: _selectedStatus,
      notes: _notesCtrl.text.trim(),
      pdfReportPath: _pdfReportPath,
      calibrationCertPaths: _calibrationCerts,
      subcontractorLicensePath: _licenseDocPath,
      sitePhotoPaths: _sitePhotos,
    );

    ref.read(envSessionListProvider.notifier).saveSession(session);
    if (widget.onSaved != null) {
      widget.onSaved!(session);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.session != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 750,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Title Header
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
                  const Icon(Icons.event_note_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEdit ? 'แก้ไขรอบการตรวจวัด (${widget.session!.sessionId})' : 'สร้างรอบการตรวจวัดสภาพแวดล้อมใหม่',
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
                    // 1. Session ID & Title
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _sessionIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'รหัสรอบตรวจวัด (Session ID) *',
                              hintText: 'ENV-SESS-2026-001',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุรหัสรอบ' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _yearBeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'ปี พ.ศ. *',
                              hintText: '2569',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุปี' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _measDateCtrl,
                            decoration: const InputDecoration(
                              labelText: 'วันที่ตรวจวัด (YYYY-MM-DD) *',
                              hintText: '2026-09-01',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุวันที่' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อรอบการตรวจวัด *',
                        hintText: 'ตรวจวัดสภาพแวดล้อมประจำปี 2569 (แสง เสียง ความร้อน)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อรอบ' : null,
                    ),
                    const SizedBox(height: 16),

                    // 2. Workplace & Plant
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _workplaceNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'ชื่อสถานประกอบกิจการ *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อสถานประกอบการ' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _locationPlantCtrl,
                            decoration: const InputDecoration(
                              labelText: 'โรงงาน / สาขา / อาคาร *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุพื้นที่/โรงงาน' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _workplaceAddressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ที่อยู่สถานประกอบการ',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _objectiveCtrl,
                      decoration: const InputDecoration(
                        labelText: 'วัตถุประสงค์การตรวจวัด',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Subcontractor Info (Section 9 / 11)
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
                          Row(
                            children: [
                              const Icon(Icons.verified_user_rounded, color: Color(0xFF1E3A8A), size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'ข้อมูลผู้รับจ้างตรวจวัด (Subcontractor ม.๙ / ม.๑๑)',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          DropdownButtonFormField<SubcontractorType>(
                            value: _selectedSubcontractorType,
                            decoration: const InputDecoration(
                              labelText: 'ประเภทผู้ให้บริการตาม พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: SubcontractorType.values.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(t.labelTh),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedSubcontractorType = v);
                            },
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _subcontractorCompanyCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'ชื่อบริษัท / ผู้ให้บริการ *',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อบริษัท' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _subcontractorRegCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'เลขทะเบียน/ใบอนุญาต *',
                                    hintText: _selectedSubcontractorType.expectedPrefix,
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุเลขทะเบียน' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _surveyorNameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'ชื่อผู้ทำการตรวจวัด (Surveyor) *',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุผู้ตรวจวัด' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _surveyorLicenseCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'เลขที่ใบอนุญาต/คุณวุฒิผู้ตรวจวัด',
                                    border: OutlineInputBorder(),
                                    isDense: true,
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
                                  controller: _certifierNameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'ชื่อผู้รับรองรายงาน (Certifier) *',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุผู้รับรอง' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _certifierRegCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'เลขทะเบียนผู้รับรองรายงาน',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. Status & Notes
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<EnvironmentSessionStatus>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'สถานะรอบการตรวจวัด',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: EnvironmentSessionStatus.values.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(s.labelTh),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedStatus = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

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
                    label: Text(isEdit ? 'บันทึกการแก้ไข' : 'สร้างรอบการตรวจวัด'),
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
