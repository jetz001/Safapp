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

  bool _copyPointsFromPrevious = true;
  String? _selectedSourceSessionId;

  @override
  void initState() {
    super.initState();
    final s = widget.session;

    final now = DateTime.now();
    final currentYearBe = now.year + 543;
    final defaultId = 'ENV-SESS-${now.year}-${(now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}';

    // Pick first available session as clone source & default template
    final existingSessions = ref.read(envSessionListProvider).asData?.value ?? [];
    EnvironmentSessionModel? latest;
    if (existingSessions.isNotEmpty) {
      latest = existingSessions.first;
      _selectedSourceSessionId = latest.sessionId;
    }

    _sessionIdCtrl = TextEditingController(text: s?.sessionId ?? defaultId);
    _titleCtrl = TextEditingController(text: s?.sessionTitle ?? 'ตรวจวัดสภาพแวดล้อมประจำปี $currentYearBe');
    _yearBeCtrl = TextEditingController(text: (s?.sessionYearBe ?? currentYearBe).toString());
    _measDateCtrl = TextEditingController(text: s?.measurementDate ?? now.toIso8601String().substring(0, 10));
    _locationPlantCtrl = TextEditingController(text: s?.locationPlant ?? latest?.locationPlant ?? 'โรงงาน 2 (ลาดหลุมแก้ว)');
    _workplaceNameCtrl = TextEditingController(text: s?.workplaceName ?? latest?.workplaceName ?? 'บริษัท บอส คาร์ตัน จำกัด');
    _workplaceAddressCtrl = TextEditingController(
      text: s?.workplaceAddress ??
          latest?.workplaceAddress ??
          '178 หมู่ 4 ถนน ปทุมธานี-ลาดหลุมแก้ว แขวง/ตำบล ระแหง เขต/อำเภอ ลาดหลุมแก้ว จังหวัด ปทุมธานี 12140',
    );
    _objectiveCtrl = TextEditingController(
      text: s?.objective ??
          latest?.objective ??
          'ตรวจวัดและวิเคราะห์สภาวะการทำงานเกี่ยวกับความร้อน แสงสว่าง และเสียง ตามกฎกระทรวงฯ พ.ศ. ๒๕๕๙',
    );
    _subcontractorCompanyCtrl = TextEditingController(
      text: s?.subcontractorCompanyName ?? latest?.subcontractorCompanyName ?? 'บริษัท เอ็นพีเอสเอส แมเนจเม้นท์ จำกัด',
    );
    _subcontractorRegCtrl = TextEditingController(
      text: s?.subcontractorRegNumber ?? latest?.subcontractorRegNumber ?? '0105563117641',
    );
    _surveyorNameCtrl = TextEditingController(
      text: s?.surveyorName ?? latest?.surveyorName ?? 'นางสาวสวลักษณ์ หงำกระโทก / นางสาวอรนุช ล้อมวงษ์',
    );
    _surveyorLicenseCtrl = TextEditingController(
      text: s?.surveyorLicenseNo ??
          latest?.surveyorLicenseNo ??
          'ความร้อน: 0401-03-2565-0039 / แสง: 0402-03-2565-0040 / เสียง: 0403-03-2565-0039',
    );
    _certifierNameCtrl = TextEditingController(
      text: s?.certifierName ?? latest?.certifierName ?? 'นายวงศธร พิชัยสวัสดิ์ (นายจ้าง/ผู้มีอำนาจกระทำการแทน)',
    );
    _certifierRegCtrl = TextEditingController(
      text: s?.certifierRegNo ?? latest?.certifierRegNo ?? '0125542004155',
    );
    _notesCtrl = TextEditingController(text: s?.notes ?? '');

    _selectedSubcontractorType = s?.subcontractorType ?? latest?.subcontractorType ?? SubcontractorType.section11Juristic;
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

  void _save() async {
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

    await ref.read(envSessionListProvider.notifier).saveSession(session);

    // If new session and user opted to clone points from previous year
    if (widget.session == null && _copyPointsFromPrevious && _selectedSourceSessionId != null) {
      await ref.read(envSessionListProvider.notifier).copyPointsToSession(
        sourceSessionId: _selectedSourceSessionId!,
        targetSessionId: session.sessionId,
        targetYearBe: yearBe,
      );
      ref.read(envSelectedSessionIdProvider.notifier).state = session.sessionId;
    }

    if (widget.onSaved != null) {
      widget.onSaved!(session);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _clearSubcontractorFields() {
    setState(() {
      _subcontractorCompanyCtrl.clear();
      _subcontractorRegCtrl.clear();
      _surveyorNameCtrl.clear();
      _surveyorLicenseCtrl.clear();
      _licenseDocPath = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ล้างข้อมูลเรียบร้อยแล้ว ท่านสามารถกรอกบริษัทผู้รับจ้างเจ้าใหม่ได้ทันที')),
    );
  }

  void _fillLatestSubcontractor() {
    final existingSessions = ref.read(envSessionListProvider).asData?.value ?? [];
    if (existingSessions.isNotEmpty) {
      final latest = existingSessions.first;
      setState(() {
        _selectedSubcontractorType = latest.subcontractorType;
        _subcontractorCompanyCtrl.text = latest.subcontractorCompanyName;
        _subcontractorRegCtrl.text = latest.subcontractorRegNumber;
        _surveyorNameCtrl.text = latest.surveyorName;
        _surveyorLicenseCtrl.text = latest.surveyorLicenseNo ?? '';
        _certifierNameCtrl.text = latest.certifierName;
        _certifierRegCtrl.text = latest.certifierRegNo ?? '';
        _licenseDocPath = latest.subcontractorLicensePath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ดึงข้อมูลล่าสุดจาก "${latest.subcontractorCompanyName}" เรียบร้อยแล้ว')),
      );
    }
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
                              const Expanded(
                                child: Text(
                                  'ข้อมูลผู้รับจ้างตรวจวัด (Subcontractor ม.๙ / ม.๑๑)',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _fillLatestSubcontractor,
                                icon: const Icon(Icons.autorenew_rounded, size: 15),
                                label: const Text('ดึงเจ้าเดิมล่าสุด', style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF1E3A8A),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                              const SizedBox(width: 6),
                              OutlinedButton.icon(
                                onPressed: _clearSubcontractorFields,
                                icon: const Icon(Icons.edit_note_rounded, size: 15),
                                label: const Text('เปลี่ยนเจ้าใหม่', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFD97706),
                                  side: const BorderSide(color: Color(0xFFD97706)),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          DropdownButtonFormField<SubcontractorType>(
                            value: _selectedSubcontractorType,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'ประเภทผู้ให้บริการตาม พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: SubcontractorType.values.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(t.labelTh, overflow: TextOverflow.ellipsis),
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
                    if (!isEdit) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _copyPointsFromPrevious,
                                  activeColor: const Color(0xFF1E3A8A),
                                  onChanged: (val) {
                                    setState(() => _copyPointsFromPrevious = val ?? false);
                                  },
                                ),
                                const Expanded(
                                  child: Text(
                                    'คัดลอกจุดตรวจวัดจากรอบก่อนหน้าอัตโนมัติ (แนะนำสำหรับการขึ้นปีใหม่)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                                  ),
                                ),
                              ],
                            ),
                            if (_copyPointsFromPrevious) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 40, right: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'ระบบจะจำลองจุดตรวจวัดทั้งหมด (แผนก, พื้นที่, เครื่องจักร/งาน, ค่าเกณฑ์มาตรฐาน) เข้าสู่รอบปีใหม่นี้โดยอัตโนมัติ และรีเซ็ตค่าที่วัดได้เพื่อให้พร้อมลงบันทึกผลประจำปีใหม่ โดยไม่ต้องกรอก ๑๙ จุดซ้ำ',
                                      style: TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.4),
                                    ),
                                    const SizedBox(height: 10),
                                    Consumer(
                                      builder: (ctx, ref, _) {
                                        final sessions = ref.watch(envSessionListProvider).asData?.value ?? [];
                                        if (sessions.isEmpty) return const SizedBox.shrink();
                                        final sourceVal = (_selectedSourceSessionId != null && sessions.any((s) => s.sessionId == _selectedSourceSessionId))
                                            ? _selectedSourceSessionId
                                            : sessions.first.sessionId;
                                        return Row(
                                          children: [
                                            const Text('คัดลอกจากรอบ: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: DropdownButtonFormField<String>(
                                                value: sourceVal,
                                                isDense: true,
                                                decoration: InputDecoration(
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                ),
                                                items: sessions.map((s) {
                                                  return DropdownMenuItem<String>(
                                                    value: s.sessionId,
                                                    child: Text(
                                                      'พ.ศ. ${s.sessionYearBe} - ${s.sessionTitle} (${s.sessionId})',
                                                      style: const TextStyle(fontSize: 12),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (val) {
                                                  setState(() => _selectedSourceSessionId = val);
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
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
