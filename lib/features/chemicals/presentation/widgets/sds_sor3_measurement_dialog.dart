import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/datasources/chemical_324_tlv_data.dart';
import '../../domain/models/chemical_measurement_sor3_model.dart';
import '../../domain/models/chemical_tlv_model.dart';

/// Form Dialog for recording workplace air monitoring per Revised Notification B.E. 2565 (แบบ สอ.๓).
/// Features real-time TLV matching against 324 exposure standards, Section 9/11 certs, and sampling points.
class SdsSor3MeasurementDialog extends StatefulWidget {
  final ChemicalMeasurementSor3Model? initialItem;
  final Future<void> Function(ChemicalMeasurementSor3Model, String?) onSave;

  const SdsSor3MeasurementDialog({
    Key? key,
    this.initialItem,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SdsSor3MeasurementDialog> createState() => _SdsSor3MeasurementDialogState();
}

class _SdsSor3MeasurementDialogState extends State<SdsSor3MeasurementDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _documentNoController;
  late TextEditingController _assessmentDateController;
  late TextEditingController _workplaceAreaController;
  late TextEditingController _samplingPointDescController;
  late TextEditingController _chemicalNameController;
  late TextEditingController _casNumberController;
  late TextEditingController _samplingDurationController;
  late TextEditingController _samplingMethodController;
  late TextEditingController _measuredValueController;
  late TextEditingController _tlvStandardController;

  // Surveyor & Laboratory
  String _surveyorType = 'SECTION_9'; // 'SECTION_9' or 'SECTION_11'
  late TextEditingController _serviceProviderNameController;
  late TextEditingController _serviceProviderM9RegNoController;
  late TextEditingController _serviceProviderM11CertNoController;
  late TextEditingController _surveyorQualificationController;
  late TextEditingController _samplingOfficerController;
  late TextEditingController _analystNameController;
  late TextEditingController _analysisLaboratoryController;

  // Weather & Environment
  late TextEditingController _weatherConditionController;
  late TextEditingController _temperatureController;
  late TextEditingController _humidityController;

  // Recommendations
  late TextEditingController _correctiveActionController;

  String _samplingType = 'TWA_8HR';
  String _unit = 'ppm';
  ChemicalTlvItem? _selectedTlvChemical;
  TlvEvaluationResult? _evaluationResult;

  List<Sor3SamplingPointItem> _samplingPoints = [];
  String? _selectedCertFilePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final it = widget.initialItem;

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    _documentNoController = TextEditingController(text: it?.documentNo ?? 'SOR3-${now.year + 543}-${now.millisecondsSinceEpoch.toString().substring(8)}');
    _assessmentDateController = TextEditingController(text: it?.assessmentDate ?? todayStr);
    _workplaceAreaController = TextEditingController(text: it?.workplaceArea ?? '');
    _samplingPointDescController = TextEditingController(text: it?.samplingPointDescription ?? '');
    _chemicalNameController = TextEditingController(text: it?.chemicalName ?? 'โทลูอีน (Toluene)');
    _casNumberController = TextEditingController(text: it?.casNumber ?? '108-88-3');
    _samplingDurationController = TextEditingController(text: (it?.samplingDurationMinutes ?? 480).toString());
    _samplingMethodController = TextEditingController(text: it?.samplingMethod ?? 'NIOSH Method 1501 / GC-FID');
    _measuredValueController = TextEditingController(text: (it?.measuredValue ?? 20.0).toString());
    _tlvStandardController = TextEditingController(text: (it?.tlvStandardValue ?? 50.0).toString());

    _surveyorType = it?.surveyorType ?? 'SECTION_9';
    _serviceProviderNameController = TextEditingController(text: it?.serviceProviderName ?? 'บริษัท ศูนย์ตรวจวิเคราะห์สิ่งแวดล้อมความปลอดภัย จำกัด');
    _serviceProviderM9RegNoController = TextEditingController(text: it?.serviceProviderM9RegNo ?? 'นบ. 024-2563');
    _serviceProviderM11CertNoController = TextEditingController(text: it?.serviceProviderM11CertNo ?? '');
    _surveyorQualificationController = TextEditingController(text: it?.surveyorQualification ?? 'สุขศาสตร์อุตสาหกรรมและความปลอดภัย (วท.บ.)');
    _samplingOfficerController = TextEditingController(text: it?.samplingOfficerName ?? 'นายสมศักดิ์ มั่นคง (จป.วิชาชีพ)');
    _analystNameController = TextEditingController(text: it?.analystName ?? 'ดร.สมชาย นักวิจัย (นักเคมีปฏิบัติการ)');
    _analysisLaboratoryController = TextEditingController(text: it?.analysisLaboratory ?? 'ห้องปฏิบัติการมาตรฐาน ISO/IEC 17025 กรมวิทยาศาสตร์บริการ');

    _weatherConditionController = TextEditingController(text: it?.weatherCondition ?? 'แดดจัด ท้องฟ้าโปร่ง');
    _temperatureController = TextEditingController(text: (it?.temperatureCelsius ?? 28.5).toString());
    _humidityController = TextEditingController(text: (it?.relativeHumidity ?? 62.0).toString());

    _correctiveActionController = TextEditingController(
      text: it?.correctiveAction ?? 'ผลการตรวจวัดอยู่ในเกณฑ์มาตรฐานความปลอดภัย แนะนำให้ตรวจบำรุงรักษาระบบระบายอากาศเฉพาะที่ (Local Exhaust) ทุก 3 เดือน และตรวจวัดบรรยากาศซ้ำเป็นประจำทุกปี',
    );

    _samplingType = it?.samplingType ?? 'TWA_8HR';
    _unit = it?.unit ?? 'ppm';
    _samplingPoints = List.from(it?.samplingPoints ?? []);

    // Try matching initial TLV item
    if (it != null && it.casNumber.isNotEmpty) {
      _selectedTlvChemical = Chemical324TlvData.findByCas(it.casNumber);
    } else {
      _selectedTlvChemical = Chemical324TlvData.findByCas('108-88-3');
    }

    _calculateTlvEvaluation();
  }

  @override
  void dispose() {
    _documentNoController.dispose();
    _assessmentDateController.dispose();
    _workplaceAreaController.dispose();
    _samplingPointDescController.dispose();
    _chemicalNameController.dispose();
    _casNumberController.dispose();
    _samplingDurationController.dispose();
    _samplingMethodController.dispose();
    _measuredValueController.dispose();
    _tlvStandardController.dispose();
    _serviceProviderNameController.dispose();
    _serviceProviderM9RegNoController.dispose();
    _serviceProviderM11CertNoController.dispose();
    _surveyorQualificationController.dispose();
    _samplingOfficerController.dispose();
    _analystNameController.dispose();
    _analysisLaboratoryController.dispose();
    _weatherConditionController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    _correctiveActionController.dispose();
    super.dispose();
  }

  void _onTlvChemicalChanged(int? seq) {
    if (seq == null) return;
    final item = Chemical324TlvData.findBySequence(seq);
    if (item != null) {
      setState(() {
        _selectedTlvChemical = item;
        _chemicalNameController.text = '${item.thaiName} (${item.englishName})';
        if (item.casNumber != null && item.casNumber!.isNotEmpty) {
          _casNumberController.text = item.casNumber!;
        }
      });
      _updateTlvLimitFromChemical();
    }
  }

  void _updateTlvLimitFromChemical() {
    if (_selectedTlvChemical == null) return;
    double? limit;
    final item = _selectedTlvChemical!;

    if (_unit == 'ppm') {
      if (_samplingType == 'TWA_8HR') limit = item.twaPpm;
      if (_samplingType == 'STEL_15MIN') limit = item.stelPpm ?? (item.twaPpm != null ? item.twaPpm! * 1.5 : null);
      if (_samplingType == 'CEILING') limit = item.ceilingPpm;
    } else {
      if (_samplingType == 'TWA_8HR') limit = item.twaMgM3;
      if (_samplingType == 'STEL_15MIN') limit = item.stelMgM3 ?? (item.twaMgM3 != null ? item.twaMgM3! * 1.5 : null);
      if (_samplingType == 'CEILING') limit = item.ceilingMgM3;
    }

    if (limit != null) {
      _tlvStandardController.text = limit.toString();
    }
    _calculateTlvEvaluation();
  }

  void _calculateTlvEvaluation() {
    final val = double.tryParse(_measuredValueController.text) ?? 0.0;
    final limit = double.tryParse(_tlvStandardController.text);

    setState(() {
      _evaluationResult = TlvEvaluationEngine.evaluate(
        measuredValue: val,
        standardLimit: limit,
        unit: _unit,
      );
    });
  }

  void _addSamplingPoint() {
    final idx = _samplingPoints.length + 1;
    final val = double.tryParse(_measuredValueController.text) ?? 0.0;
    final limit = double.tryParse(_tlvStandardController.text) ?? 50.0;
    final eval = TlvEvaluationEngine.evaluate(measuredValue: val, standardLimit: limit, unit: _unit);

    setState(() {
      _samplingPoints.add(
        Sor3SamplingPointItem(
          pointCode: 'SP-${idx.toString().padLeft(2, '0')}',
          workAreaName: _workplaceAreaController.text.isNotEmpty ? _workplaceAreaController.text : 'จุดตรวจวัด $idx',
          processDescription: 'งานประจำจุดสัมผัสสารเคมี',
          exposedWorkersCount: 1,
          ppeUsed: 'หน้ากากป้องกันสารเคมี, ถุงมือทนสาร',
          chemicalName: _chemicalNameController.text,
          casNumber: _casNumberController.text,
          samplingType: _samplingType,
          samplingDurationMinutes: int.tryParse(_samplingDurationController.text) ?? 480,
          measuredValue: val,
          unit: _unit,
          tlvStandardValue: limit,
          evaluationResult: eval.status.name.toUpperCase(),
        ),
      );
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final measured = double.tryParse(_measuredValueController.text) ?? 0.0;
      final standard = double.tryParse(_tlvStandardController.text) ?? 0.0;
      final evalStatus = _evaluationResult?.status.name.toUpperCase() ?? 'PASS';

      final model = ChemicalMeasurementSor3Model(
        id: widget.initialItem?.id,
        documentNo: _documentNoController.text.trim(),
        assessmentDate: _assessmentDateController.text.trim(),
        workplaceArea: _workplaceAreaController.text.trim(),
        samplingPointDescription: _samplingPointDescController.text.trim().isEmpty ? null : _samplingPointDescController.text.trim(),
        chemicalName: _chemicalNameController.text.trim(),
        casNumber: _casNumberController.text.trim(),
        samplingType: _samplingType,
        samplingDurationMinutes: int.tryParse(_samplingDurationController.text) ?? 480,
        samplingMethod: _samplingMethodController.text.trim(),
        measuredValue: measured,
        unit: _unit,
        tlvStandardValue: standard,
        evaluationResult: evalStatus,
        serviceProviderName: _serviceProviderNameController.text.trim(),
        surveyorType: _surveyorType,
        serviceProviderM9RegNo: _surveyorType == 'SECTION_9' ? _serviceProviderM9RegNoController.text.trim() : null,
        serviceProviderM11CertNo: _surveyorType == 'SECTION_11' ? _serviceProviderM11CertNoController.text.trim() : null,
        surveyorQualification: _surveyorQualificationController.text.trim(),
        samplingOfficerName: _samplingOfficerController.text.trim(),
        analystName: _analystNameController.text.trim(),
        analysisLaboratory: _analysisLaboratoryController.text.trim(),
        weatherCondition: _weatherConditionController.text.trim(),
        temperatureCelsius: double.tryParse(_temperatureController.text),
        relativeHumidity: double.tryParse(_humidityController.text),
        correctiveAction: _correctiveActionController.text.trim(),
        certificatePdfPath: _selectedCertFilePath ?? widget.initialItem?.certificatePdfPath,
        samplingPoints: _samplingPoints,
        status: 'APPROVED',
      );

      await widget.onSave(model, _selectedCertFilePath);
      if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        width: 960,
        height: 760,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1 & 2: General & Workplace
                      _buildSectionTitle('๑. ข้อมูลทั่วไปและสถานที่ตรวจวัด', Icons.location_on_outlined),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _documentNoController,
                              decoration: const InputDecoration(labelText: 'เลขที่รายงาน (Document No.) *', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุเลขที่รายงาน' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _assessmentDateController,
                              decoration: const InputDecoration(
                                labelText: 'วันที่ตรวจวัด (YYYY-MM-DD) *',
                                prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุวันที่ตรวจวัด' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _workplaceAreaController,
                              decoration: const InputDecoration(labelText: 'แผนก / พื้นที่ปฏิบัติงาน *', hintText: 'แผนกผสมสารเคมี อาคาร 2', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุแผนก/พื้นที่' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 3 & 4: Chemical & TLV Auto Evaluation
                      _buildSectionTitle('๒. สารเคมีที่ตรวจวัด & ขีดจำกัดความเข้มข้นตามกฎหมาย (๓๒๔ รายการ)', Icons.science_outlined),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedTlvChemical?.sequenceNo,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'เลือกสารเคมีมาตรฐานตามประกาศกรมสวัสดิการฯ (๓๒๔ รายการ)',
                          filled: true,
                          fillColor: Color(0xFFF8FAFC),
                          border: OutlineInputBorder(),
                        ),
                        items: Chemical324TlvData.tlvList.map((c) {
                          return DropdownMenuItem(
                            value: c.sequenceNo,
                            child: Text(
                              '#${c.sequenceNo} ${c.thaiName} (${c.englishName}) [CAS: ${c.casNumber ?? "N/A"}]',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: _onTlvChemicalChanged,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _chemicalNameController,
                              decoration: const InputDecoration(labelText: 'ชื่อสารเคมีที่ตรวจวัด *', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อสารเคมี' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _casNumberController,
                              decoration: const InputDecoration(labelText: 'CAS Number *', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุ CAS No.' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _samplingType,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'ประเภทการวัด', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'TWA_8HR', child: Text('TWA (8 ชม.)', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'STEL_15MIN', child: Text('STEL (15 นาที)', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'CEILING', child: Text('Ceiling (เพดาน)', overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (t) {
                                setState(() => _samplingType = t ?? 'TWA_8HR');
                                _updateTlvLimitFromChemical();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _unit,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'หน่วยวัด', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'ppm', child: Text('ppm', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'mg/m3', child: Text('mg/m³', overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (u) {
                                setState(() => _unit = u ?? 'ppm');
                                _updateTlvLimitFromChemical();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _measuredValueController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'ค่าที่ตรวจวัดได้ *', border: OutlineInputBorder()),
                              onChanged: (_) => _calculateTlvEvaluation(),
                              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุค่าที่ตรวจวัด' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _tlvStandardController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'ค่ามาตรฐานตามกฎหมาย (TLV) *', border: OutlineInputBorder()),
                              onChanged: (_) => _calculateTlvEvaluation(),
                              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุค่ามาตรฐาน' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _samplingDurationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'ระยะเวลาเก็บตัวอย่าง (นาที)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _samplingMethodController,
                              decoration: const InputDecoration(labelText: 'วิธีการตรวจวัดและวิเคราะห์', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Evaluation Result Feedback Banner
                      if (_evaluationResult != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _evaluationResult!.statusBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _evaluationResult!.statusColor.withValues(alpha: 0.6), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Icon(_evaluationResult!.statusIcon, size: 28, color: _evaluationResult!.statusColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ผลการประเมิน: ${_evaluationResult!.statusBadgeLabelTh}',
                                      style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.bold, color: _evaluationResult!.statusColor),
                                    ),
                                    Text(
                                      _evaluationResult!.messageTh,
                                      style: GoogleFonts.prompt(fontSize: 11, color: const Color(0xFF334155)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _addSamplingPoint,
                            icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                            label: Text('บันทึกเป็นจุดเก็บตัวอย่าง (${_samplingPoints.length} จุด)', style: GoogleFonts.prompt(fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 5: Surveyor Certification (Section 9 / 11)
                      _buildSectionTitle('๓. ข้อมูลผู้ตรวจวัดขึ้นทะเบียนตาม พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔', Icons.badge_outlined),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'SECTION_9',
                            groupValue: _surveyorType,
                            onChanged: (v) => setState(() => _surveyorType = v!),
                          ),
                          const Text('นิติบุคคลตามมาตรา ๙ (ขึ้นทะเบียนกับกรมสวัสดิการฯ)'),
                          const SizedBox(width: 20),
                          Radio<String>(
                            value: 'SECTION_11',
                            groupValue: _surveyorType,
                            onChanged: (v) => setState(() => _surveyorType = v!),
                          ),
                          const Text('บุคคลธรรมดาตามมาตรา ๑๑ (ขึ้นทะเบียนกับกรมสวัสดิการฯ)'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _serviceProviderNameController,
                              decoration: InputDecoration(
                                labelText: _surveyorType == 'SECTION_9' ? 'ชื่อนิติบุคคลผู้ตรวจวัด *' : 'ชื่อบุคคลผู้ตรวจวัด *',
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อผู้ตรวจวัด' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_surveyorType == 'SECTION_9') ...[
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _serviceProviderM9RegNoController,
                                decoration: const InputDecoration(labelText: 'เลขทะเบียนใบสำคัญ (นบ. xxx-xxxx) *', border: OutlineInputBorder()),
                                validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุเลขทะเบียน นบ.' : null,
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _serviceProviderM11CertNoController,
                                decoration: const InputDecoration(labelText: 'เลขทะเบียนใบสำคัญ (บ. xxx-xxxx) *', border: OutlineInputBorder()),
                                validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุเลขทะเบียน บ.' : null,
                              ),
                            ),
                          ],
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _surveyorQualificationController,
                              decoration: const InputDecoration(labelText: 'คุณวุฒิ / สาขาวิชาชีพ', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _samplingOfficerController,
                              decoration: const InputDecoration(labelText: 'เจ้าหน้าที่ผู้เก็บตัวอย่าง', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _analystNameController,
                              decoration: const InputDecoration(labelText: 'นักวิเคราะห์ผลทางห้องปฏิบัติการ', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _analysisLaboratoryController,
                              decoration: const InputDecoration(labelText: 'ห้องปฏิบัติการตรวจวิเคราะห์', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 6: Recommendations
                      _buildSectionTitle('๔. สรุปผลการตรวจวัดและข้อเสนอแนะเพื่อการปรับปรุงแก้ไข', Icons.rate_review_outlined),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _correctiveActionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'ข้อเสนอแนะและมาตรการป้องกันแก้ไขตามหลักสุขศาสตร์อุตสาหกรรม',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF065F46),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.speed_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.initialItem == null
                      ? 'บันทึกผลการตรวจวัดความเข้มข้นสารเคมีในบรรยากาศ (แบบ สอ.๓ ๒๕๖๕)'
                      : 'แก้ไขรายงานผลการตรวจวัด แบบ สอ.๓: ${_documentNoController.text}',
                  style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'ตามประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง หลักเกณฑ์ วิธีการตรวจวัดฯ (ฉบับที่ ๒) พ.ศ. ๒๕๖๕',
                  style: GoogleFonts.prompt(fontSize: 11, color: const Color(0xFFA7F3D0)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF065F46), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
      ],
    );
  }

  Widget _buildBottomActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey.shade700)),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _handleSave,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(
              _isSaving ? 'กำลังบันทึก...' : 'บันทึกรายงาน แบบ สอ.๓ ๒๕๖๕',
              style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF065F46),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
