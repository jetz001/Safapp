import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/health_models.dart';
import '../providers/health_providers.dart';
import '../../../employee/domain/models/employee_models.dart';
import '../../../employee/presentation/providers/employee_providers.dart';

class HealthRecordFormDialog extends ConsumerStatefulWidget {
  final EmployeeHealthRecord? existingRecord;
  final int? preselectedEmployeeId;

  const HealthRecordFormDialog({
    Key? key,
    this.existingRecord,
    this.preselectedEmployeeId,
  }) : super(key: key);

  @override
  ConsumerState<HealthRecordFormDialog> createState() => _HealthRecordFormDialogState();
}

class _HealthRecordFormDialogState extends ConsumerState<HealthRecordFormDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  int? _selectedEmployeeId;
  late String _checkupType;
  late TextEditingController _checkupDateController;
  late TextEditingController _hospitalController;
  late TextEditingController _doctorNameController;
  late TextEditingController _doctorLicenseController;
  late String _overallResult;

  // Vitals
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _systolicController;
  late TextEditingController _diastolicController;
  late TextEditingController _pulseController;
  double? _calculatedBmi;

  // General & Lab
  late String _physicalExamResult;
  late TextEditingController _physicalNotesController;
  late String _chestXrayResult;
  late String _audiogramResult;
  late String _spirometryResult;
  late String _visionTestResult;
  late String _bloodCbcResult;
  late String _bloodSugarResult;
  late String _liverResult;
  late String _kidneyResult;
  late String _urineResult;
  late String _drugResult;

  // Risk Factors (ตามประกาศกระทรวง)
  final List<String> _selectedRiskFactors = [];
  final Map<String, String> _riskFactorResults = {};
  late TextEditingController _doctorOpinionController;
  late String _fitnessToWork;

  String? _pdfFilePath;
  bool _isSaving = false;

  final List<String> _standardRiskFactors = [
    'สารเคมี: ตัวทำละลายอินทรีย์ (โทลูอีน, ไซลีน, เบนซีน, อะซีโตน)',
    'สารเคมี: ฝุ่น/ฟูมโลหะ (ตะกั่ว, แคดเมียม, โครเมียม, นิกเกิล)',
    'สารเคมี: ก๊าซพิษ และไอระเหยกรด/ด่าง (คลอรีน, แอมโมเนีย, ไฮโดรเจนซัลไฟด์)',
    'ปัจจัยกายภาพ: เสียงดัง (Noise / Audiogram การได้ยิน)',
    'ปัจจัยกายภาพ: ความร้อนสูง / แสงจ้า / รังสี',
    'ฝุ่นและระบบทางเดินหายใจ: ฝุ่นหิน/ซิลิก้า/ฝุ่นฝ้าย (Spirometry / CXR)',
    'การยศาสตร์: ยกของหนัก / การตรวจกล้ามเนื้อและกระดูก',
    'จุลชีพและชีวภาพ: ไวรัส / แบคทีเรีย / สารชีวภาพ',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final r = widget.existingRecord;

    _selectedEmployeeId = r?.employeeId ?? widget.preselectedEmployeeId;
    _checkupType = r?.checkupType ?? 'ANNUAL';
    _checkupDateController = TextEditingController(text: r?.checkupDate ?? DateTime.now().toIso8601String().substring(0, 10));
    _hospitalController = TextEditingController(text: r?.hospitalName ?? 'โรงพยาบาลในความตกลง กองทุนเงินทดแทน');
    _doctorNameController = TextEditingController(text: r?.doctorName ?? 'นพ. สมเกียรติ สุขสมบูรณ์');
    _doctorLicenseController = TextEditingController(text: r?.doctorLicenseNo ?? 'ว.45892');
    _overallResult = r?.overallResult ?? 'NORMAL';

    _weightController = TextEditingController(text: r?.weight != null ? '${r!.weight}' : '65.0');
    _heightController = TextEditingController(text: r?.height != null ? '${r!.height}' : '170.0');
    _systolicController = TextEditingController(text: r?.bpSystolic != null ? '${r!.bpSystolic}' : '120');
    _diastolicController = TextEditingController(text: r?.bpDiastolic != null ? '${r!.bpDiastolic}' : '80');
    _pulseController = TextEditingController(text: r?.pulse != null ? '${r!.pulse}' : '75');
    _calculateBmi();

    _physicalExamResult = r?.physicalExamResult ?? 'NORMAL';
    _physicalNotesController = TextEditingController(text: r?.physicalExamNotes ?? '');
    _chestXrayResult = r?.chestXrayResult ?? 'NORMAL';
    _audiogramResult = r?.audiogramResult ?? 'NORMAL';
    _spirometryResult = r?.spirometryResult ?? 'NORMAL';
    _visionTestResult = r?.visionTestResult ?? 'NORMAL';
    _bloodCbcResult = r?.bloodCbcResult ?? 'NORMAL';
    _bloodSugarResult = r?.bloodSugarResult ?? 'NORMAL';
    _liverResult = r?.liverFunctionResult ?? 'NORMAL';
    _kidneyResult = r?.kidneyFunctionResult ?? 'NORMAL';
    _urineResult = r?.urineExamResult ?? 'NORMAL';
    _drugResult = r?.drugScreeningResult ?? 'NEGATIVE';

    if (r?.riskFactorsTested != null) {
      _selectedRiskFactors.addAll(r!.riskFactorsTested);
    }
    if (r?.riskFactorResults != null) {
      _riskFactorResults.addAll(r!.riskFactorResults);
    }

    _doctorOpinionController = TextEditingController(text: r?.doctorOpinion ?? 'สุขภาพทั่วไปอยู่ในเกณฑ์ปกติ สามารถปฏิบัติงานได้ตามปกติ');
    _fitnessToWork = r?.fitnessToWork ?? 'FIT';
    _pdfFilePath = r?.pdfFilePath;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _checkupDateController.dispose();
    _hospitalController.dispose();
    _doctorNameController.dispose();
    _doctorLicenseController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    _physicalNotesController.dispose();
    _doctorOpinionController.dispose();
    super.dispose();
  }

  void _calculateBmi() {
    final w = double.tryParse(_weightController.text);
    final h = double.tryParse(_heightController.text);
    if (w != null && h != null && h > 0) {
      final hMeter = h / 100;
      setState(() {
        _calculatedBmi = w / (hMeter * hMeter);
      });
    }
  }

  Future<void> _pickPdfFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _pdfFilePath = result.files.single.path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกพนักงานผู้รับการตรวจ')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final record = EmployeeHealthRecord(
        id: widget.existingRecord?.id,
        employeeId: _selectedEmployeeId!,
        checkupType: _checkupType,
        checkupDate: _checkupDateController.text.trim(),
        hospitalName: _hospitalController.text.trim(),
        doctorName: _doctorNameController.text.trim().isEmpty ? null : _doctorNameController.text.trim(),
        doctorLicenseNo: _doctorLicenseController.text.trim().isEmpty ? null : _doctorLicenseController.text.trim(),
        overallResult: _overallResult,
        weight: double.tryParse(_weightController.text.trim()),
        height: double.tryParse(_heightController.text.trim()),
        bmi: _calculatedBmi,
        bpSystolic: int.tryParse(_systolicController.text.trim()),
        bpDiastolic: int.tryParse(_diastolicController.text.trim()),
        pulse: int.tryParse(_pulseController.text.trim()),
        physicalExamResult: _physicalExamResult,
        physicalExamNotes: _physicalNotesController.text.trim().isEmpty ? null : _physicalNotesController.text.trim(),
        chestXrayResult: _chestXrayResult,
        audiogramResult: _audiogramResult,
        spirometryResult: _spirometryResult,
        visionTestResult: _visionTestResult,
        bloodCbcResult: _bloodCbcResult,
        bloodSugarResult: _bloodSugarResult,
        liverFunctionResult: _liverResult,
        kidneyFunctionResult: _kidneyResult,
        urineExamResult: _urineResult,
        drugScreeningResult: _drugResult,
        riskFactorsTested: _selectedRiskFactors,
        riskFactorResults: _riskFactorResults,
        doctorOpinion: _doctorOpinionController.text.trim().isEmpty ? null : _doctorOpinionController.text.trim(),
        fitnessToWork: _fitnessToWork,
        pdfFilePath: _pdfFilePath,
      );

      await ref.read(healthRecordsProvider.notifier).saveRecord(record, newPdfPath: _pdfFilePath);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingRecord != null ? 'อัปเดตผลตรวจสุขภาพเรียบร้อย' : 'บันทึกผลตรวจสุขภาพเรียบร้อย'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);
    final isEdit = widget.existingRecord != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      child: Container(
        width: 880,
        height: 760,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.health_and_safety_rounded, color: Colors.tealAccent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'แก้ไขผลการตรวจสุขภาพพนักงาน' : 'บันทึกผลการตรวจสุขภาพพนักงาน (Health Examination Record)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'ตรวจก่อนเข้างาน, ประจำปี, ตรวจตามปัจจัยเสี่ยง (สารเคมี/เสียงดัง/ปอด), และผล Lab',
                          style: TextStyle(fontSize: 11.5, color: Colors.blue.shade100),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1E3A8A),
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: const Color(0xFF1E3A8A),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.person, size: 18), text: '๑. ข้อมูลทั่วไป & สัญญาณชีพ'),
                Tab(icon: Icon(Icons.science_rounded, size: 18), text: '๒. ผลตรวจ Lab & ปัจจัยเสี่ยง'),
                Tab(icon: Icon(Icons.assignment_turned_in, size: 18), text: '๓. สรุปผลแพทย์ & แนบ PDF'),
              ],
            ),
            const Divider(height: 1),

            // Tab Body
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTab1GeneralAndVitals(employeesAsync),
                    _buildTab2LabAndRiskFactors(),
                    _buildTab3ConclusionAndPdf(),
                  ],
                ),
              ),
            ),

            // Bottom Actions
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('ผลตรวจภาพรวม: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _overallResult,
                        items: const [
                          DropdownMenuItem(value: 'NORMAL', child: Text('🟢 ปกติ (Normal)')),
                          DropdownMenuItem(value: 'WATCH', child: Text('🟡 เฝ้าระวัง (Watch)')),
                          DropdownMenuItem(value: 'ABNORMAL', child: Text('🔴 ผิดปกติ (Abnormal)')),
                          DropdownMenuItem(value: 'PENDING', child: Text('⚪ รอผลตรวจ (Pending)')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _overallResult = v);
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(), child: const Text('ยกเลิก')),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกผลตรวจสุขภาพ'),
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
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 1: GENERAL & VITALS
  // --------------------------------------------------------------------------
  Widget _buildTab1GeneralAndVitals(AsyncValue<List<Employee>> employeesAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('๑. ข้อมูลพนักงานและประเภทการตรวจ'),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: employeesAsync.when(
                  data: (employees) {
                    return DropdownButtonFormField<int?>(
                      isExpanded: true,
                      value: _selectedEmployeeId,
                      decoration: _inputDecoration('เลือกพนักงาน *', icon: Icons.person_search),
                      items: employees.map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Text('${e.employeeCode} - ${e.fullName} (${e.department})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          )).toList(),
                      onChanged: (v) => setState(() => _selectedEmployeeId = v),
                      validator: (v) => v == null ? 'กรุณาเลือกพนักงาน' : null,
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
                  value: _checkupType,
                  decoration: _inputDecoration('ประเภทการตรวจ *', icon: Icons.assignment_outlined),
                  items: const [
                    DropdownMenuItem(value: 'PRE_EMPLOYMENT', child: Text('ตรวจก่อนเข้างาน (Pre-employment)')),
                    DropdownMenuItem(value: 'ANNUAL', child: Text('ตรวจสุขภาพประจำปี (Annual)')),
                    DropdownMenuItem(value: 'RISK_BASED', child: Text('ตรวจตามปัจจัยเสี่ยง (Risk-based)')),
                    DropdownMenuItem(value: 'JOB_CHANGE', child: Text('ตรวจเมื่อเปลี่ยนงาน (Job Change)')),
                    DropdownMenuItem(value: 'RETURN_TO_WORK', child: Text('ตรวจก่อนกลับเข้าทำงาน (RTW)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _checkupType = v);
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
                  controller: _checkupDateController,
                  decoration: _inputDecoration('วันที่ตรวจสุขภาพ *', icon: Icons.calendar_today),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _hospitalController,
                  decoration: _inputDecoration('หน่วยบริการตรวจสุขภาพ / โรงพยาบาล *', icon: Icons.local_hospital),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _doctorNameController,
                  decoration: _inputDecoration('แพทย์ผู้ทำการตรวจ', icon: Icons.person_pin),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _doctorLicenseController,
                  decoration: _inputDecoration('เลขที่ใบประกอบวิชาชีพเวชกรรม (ว.)', icon: Icons.badge_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('๒. สัญญาณชีพและผลตรวจร่างกายเบื้องต้น (Vitals & Physical Exam)'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('น้ำหนัก (กก.)', icon: Icons.monitor_weight_outlined),
                  onChanged: (_) => _calculateBmi(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('ส่วนสูง (ซม.)', icon: Icons.height),
                  onChanged: (_) => _calculateBmi(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ดัชนีมวลกาย (BMI)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      Text(
                        _calculatedBmi != null ? _calculatedBmi!.toStringAsFixed(1) : '-',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      ),
                    ],
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
                  controller: _systolicController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('ความดันตัวบน (Systolic mmHg)', icon: Icons.favorite_border),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _diastolicController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('ความดันตัวล่าง (Diastolic mmHg)', icon: Icons.favorite),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _pulseController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('ชีพจร (bpm)', icon: Icons.speed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _physicalExamResult,
                  decoration: _inputDecoration('ผลตรวจร่างกายตามระบบ (Physical Exam)', icon: Icons.accessibility_new),
                  items: const [
                    DropdownMenuItem(value: 'NORMAL', child: Text('🟢 ปกติทุกระบบ')),
                    DropdownMenuItem(value: 'ABNORMAL', child: Text('🔴 พบความผิดปกติ')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _physicalExamResult = v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _physicalNotesController,
                  decoration: _inputDecoration('รายละเอียดความผิดปกติที่ตรวจพบ (ถ้ามี)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 2: LAB & RISK FACTORS
  // --------------------------------------------------------------------------
  Widget _buildTab2LabAndRiskFactors() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('๑. ผลตรวจทางห้องปฏิบัติการและเครื่องมือพิเศษ (Lab & Diagnostic Tests)'),
          Row(
            children: [
              Expanded(child: _buildTestDropdown('เอกซเรย์ปอด (CXR)', _chestXrayResult, (v) => setState(() => _chestXrayResult = v))),
              const SizedBox(width: 10),
              Expanded(child: _buildTestDropdown('การได้ยิน (Audiogram)', _audiogramResult, (v) => setState(() => _audiogramResult = v))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildTestDropdown('สมรรถภาพปอด (Spirometry)', _spirometryResult, (v) => setState(() => _spirometryResult = v))),
              const SizedBox(width: 10),
              Expanded(child: _buildTestDropdown('สายตา/ตาบอดสี (Vision)', _visionTestResult, (v) => setState(() => _visionTestResult = v))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildTestDropdown('ความสมบูรณ์เลือด (CBC)', _bloodCbcResult, (v) => setState(() => _bloodCbcResult = v))),
              const SizedBox(width: 10),
              Expanded(child: _buildTestDropdown('ระดับน้ำตาลในเลือด (FBS)', _bloodSugarResult, (v) => setState(() => _bloodSugarResult = v))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildTestDropdown('การทำงานของตับ (SGOT/SGPT)', _liverResult, (v) => setState(() => _liverResult = v))),
              const SizedBox(width: 10),
              Expanded(child: _buildTestDropdown('การทำงานของไต (BUN/Cr)', _kidneyResult, (v) => setState(() => _kidneyResult = v))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildTestDropdown('ตรวจปัสสาวะ (UA)', _urineResult, (v) => setState(() => _urineResult = v))),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _drugResult,
                  decoration: _inputDecoration('ตรวจสารเสพติด (Drug Test)'),
                  items: const [
                    DropdownMenuItem(value: 'NEGATIVE', child: Text('🟢 ผลลบ (Negative - ไม่พบสาร)')),
                    DropdownMenuItem(value: 'POSITIVE', child: Text('🔴 ผลบวก (Positive - พบสารเสพติด)')),
                    DropdownMenuItem(value: 'NOT_TESTED', child: Text('⚪ ไม่ได้ตรวจ')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _drugResult = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('๒. การตรวจตามปัจจัยเสี่ยงเฉพาะทาง (ตามประกาศกรมสวัสดิการฯ ๒๕๖๔)'),
          ..._standardRiskFactors.map((factor) {
            final isSelected = _selectedRiskFactors.contains(factor);
            final factorStatus = _riskFactorResults[factor] ?? 'NORMAL';

            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    activeColor: const Color(0xFF1E3A8A),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedRiskFactors.add(factor);
                          _riskFactorResults[factor] = 'NORMAL';
                        } else {
                          _selectedRiskFactors.remove(factor);
                          _riskFactorResults.remove(factor);
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: Text(factor, style: const TextStyle(fontSize: 12)),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: factorStatus,
                        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'NORMAL', child: Text('🟢 ปกติ', style: TextStyle(fontSize: 11))),
                          DropdownMenuItem(value: 'ABNORMAL', child: Text('🔴 ผิดปกติ', style: TextStyle(fontSize: 11))),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _riskFactorResults[factor] = v);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 3: CONCLUSION & PDF
  // --------------------------------------------------------------------------
  Widget _buildTab3ConclusionAndPdf() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('๑. ความเห็นแพทย์และการประเมินความพร้อมทำงาน (Fitness for Duty)'),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _fitnessToWork,
            decoration: _inputDecoration('การประเมินความพร้อมในการปฏิบัติงาน *', icon: Icons.verified_user_rounded),
            items: const [
              DropdownMenuItem(value: 'FIT', child: Text('🟢 พร้อมทำงานได้ตามปกติ (Fit for Duty)')),
              DropdownMenuItem(value: 'FIT_WITH_RESTRICTION', child: Text('🟡 พร้อมทำงานแบบมีเงื่อนไข (Fit with Restriction - ห้ามยกของหนัก/ห้ามอยู่เสียงดัง)')),
              DropdownMenuItem(value: 'UNFIT', child: Text('🔴 ไม่พร้อมทำงานชั่วคราว (Unfit for Duty - ต้องรับการรักษาก่อน)')),
              DropdownMenuItem(value: 'PENDING', child: Text('⚪ รอผลตรวจเพิ่มเติม (Pending)')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _fitnessToWork = v);
            },
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _doctorOpinionController,
            maxLines: 4,
            decoration: _inputDecoration('ความเห็นแพทย์ / คำแนะนำทางการแพทย์เพิ่มเติม *', icon: Icons.comment),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('๒. แนบไฟล์เล่มรายงานผลตรวจรายบุคคล (Individual Health Report PDF)'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _pdfFilePath != null ? Colors.teal.shade50 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _pdfFilePath != null ? Icons.picture_as_pdf_rounded : Icons.upload_file_rounded,
                    color: _pdfFilePath != null ? Colors.teal.shade700 : Colors.grey.shade600,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pdfFilePath != null ? p.basename(_pdfFilePath!) : 'ยังไม่ได้แนบไฟล์ผลตรวจทางการแพทย์',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: _pdfFilePath != null ? const Color(0xFF0F172A) : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('รองรับไฟล์ PDF, JPG, PNG ขนาดไม่เกิน 50MB', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickPdfFile,
                  icon: const Icon(Icons.attach_file_rounded, size: 16),
                  label: Text(_pdfFilePath != null ? 'เปลี่ยนไฟล์' : 'เลือกไฟล์'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestDropdown(String label, String value, Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      decoration: _inputDecoration(label),
      items: const [
        DropdownMenuItem(value: 'NORMAL', child: Text('🟢 ปกติ (Normal)')),
        DropdownMenuItem(value: 'ABNORMAL', child: Text('🔴 ผิดปกติ (Abnormal)')),
        DropdownMenuItem(value: 'NOT_TESTED', child: Text('⚪ ไม่ได้ตรวจ')),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
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
