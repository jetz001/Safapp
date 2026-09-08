import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ptw_model.dart';
import '../../data/models/ptw_checklist_model.dart';
import '../../data/models/confined_role_model.dart';
import '../../data/models/loto_isolation_model.dart';
import '../../data/datasources/ptw_statutory_master_data.dart';
import '../../domain/enums/high_risk_type.dart';
import '../../domain/enums/confined_role_type.dart';
import '../../domain/enums/energy_type.dart';
import '../notifiers/ptw_list_notifier.dart';
import '../widgets/signature_pad_widget.dart';

/// Tab 2: PTW Wizard — Sequential 6-Step Form for Creating / Editing a Permit to Work
class PtwWizardTab extends ConsumerStatefulWidget {
  /// Optional existing permit to pre-fill the form for editing
  final PtwModel? editingPermit;

  /// Callback invoked after successful save (to switch tab back to dashboard)
  final VoidCallback? onPermitSaved;

  const PtwWizardTab({super.key, this.editingPermit, this.onPermitSaved});

  @override
  ConsumerState<PtwWizardTab> createState() => _PtwWizardTabState();
}

class _PtwWizardTabState extends ConsumerState<PtwWizardTab> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  // ── Step 1: General Info ──────────────────────────────────────────────────
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _applicantNameCtrl = TextEditingController();
  final _applicantDeptCtrl = TextEditingController();
  final _applicantPhoneCtrl = TextEditingController();
  String _applicantType = 'INTERNAL_EMPLOYEE';
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _endDate = DateTime.now().add(const Duration(hours: 8));
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  // ── Step 2: Risk Types ────────────────────────────────────────────────────
  HighRiskType _primaryRisk = HighRiskType.hotWork;
  final Set<HighRiskType> _secondaryRisks = {};

  // ── Step 3: Safety Checklist ──────────────────────────────────────────────
  List<PtwChecklistModel> _checklistItems = [];

  // ── Step 4: Personnel & LOTO ─────────────────────────────────────────────
  final _workerCountCtrl = TextEditingController(text: '1');
  final List<TextEditingController> _workerNameCtrls = [];
  // Confined roles
  final Map<ConfinedRoleType, TextEditingController> _roleNameCtrls = {};
  final Map<ConfinedRoleType, TextEditingController> _roleCertCtrls = {};
  final Map<ConfinedRoleType, TextEditingController> _rolePhoneCtrls = {};
  final Map<ConfinedRoleType, TextEditingController> _roleCompanyCtrls = {};
  final Map<ConfinedRoleType, TextEditingController> _roleExpiryCtrls = {};
  // LOTO
  final List<_LotoEntry> _lotoEntries = [];

  // ── Step 5: Emergency & PPE ───────────────────────────────────────────────
  final _emergencyCtrl = TextEditingController(text: 'ฉุกเฉิน: 1669 | หัวหน้างาน: 081-xxx-xxxx | จป.: 082-xxx-xxxx');
  final _ppeCtrl = TextEditingController(text: 'หมวกนิรภัย, แว่นตา, รองเท้าเซฟตี้, ชุดป้องกัน, ถุงมือ');
  final _precautionsCtrl = TextEditingController();
  final _jsaCtrl = TextEditingController();

  // ── Step 6: Signature ─────────────────────────────────────────────────────
  final SignaturePadController _sigCtrl = SignaturePadController();
  String? _savedSignaturePath;

  static const List<String> _stepTitles = [
    'ข้อมูลทั่วไป',
    'ประเภทความเสี่ยง',
    'รายการตรวจสอบ',
    'บุคลากร & LOTO',
    'ฉุกเฉิน & PPE',
    'ลงลายมือชื่อ',
  ];

  @override
  void initState() {
    super.initState();
    _initConfinedRoleCtrls();
    if (widget.editingPermit != null) {
      _prefillFromPermit(widget.editingPermit!);
    }
    _updateChecklist();
  }

  void _initConfinedRoleCtrls() {
    for (final role in ConfinedRoleType.values) {
      _roleNameCtrls[role] = TextEditingController();
      _roleCertCtrls[role] = TextEditingController();
      _rolePhoneCtrls[role] = TextEditingController();
      _roleCompanyCtrls[role] = TextEditingController(text: 'บริษัท...');
      _roleExpiryCtrls[role] = TextEditingController(
        text: '${DateTime.now().year + 2}-12-31',
      );
    }
  }

  void _prefillFromPermit(PtwModel p) {
    _titleCtrl.text = p.workTitle;
    _descCtrl.text = p.workDescription;
    _areaCtrl.text = p.plantArea;
    _locationCtrl.text = p.specificLocation;
    _applicantNameCtrl.text = p.applicantName;
    _applicantDeptCtrl.text = p.applicantDepartment;
    _applicantPhoneCtrl.text = p.applicantPhone;
    _applicantType = p.applicantType;
    _primaryRisk = p.primaryRiskType;
    _secondaryRisks.addAll(p.secondaryRiskTypes);
    _emergencyCtrl.text = p.emergencyRescuePlan;
    _ppeCtrl.text = p.requiredPpeList;
    _precautionsCtrl.text = p.specialPrecautions;
    _jsaCtrl.text = p.jsaReferenceNo ?? '';
    _workerCountCtrl.text = p.workerCount.toString();
    _checklistItems = List.from(p.checklistItems);

    try {
      _startDate = DateTime.parse(p.workStartDate);
      final parts = p.workStartTime.split(':');
      _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {}
    try {
      _endDate = DateTime.parse(p.workEndDate);
      final parts = p.workEndTime.split(':');
      _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {}

    for (int i = 0; i < p.workerNames.length; i++) {
      _ensureWorkerControllers(i + 1);
      _workerNameCtrls[i].text = p.workerNames[i];
    }

    for (final role in p.confinedRoles) {
      _roleNameCtrls[role.roleType]?.text = role.personName;
      _roleCertCtrls[role.roleType]?.text = role.certNumber;
      _rolePhoneCtrls[role.roleType]?.text = role.contactPhone;
      _roleCompanyCtrls[role.roleType]?.text = role.companyName;
      _roleExpiryCtrls[role.roleType]?.text = role.certExpiryDate;
    }

    for (final loto in p.lotoIsolations) {
      _lotoEntries.add(_LotoEntry.fromModel(loto));
    }
  }

  void _ensureWorkerControllers(int count) {
    while (_workerNameCtrls.length < count) {
      _workerNameCtrls.add(TextEditingController());
    }
  }

  void _updateChecklist() {
    if (_checklistItems.isEmpty) {
      _checklistItems = PtwStatutoryMasterData.getStandardChecklistForRiskType(
        _primaryRisk,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _areaCtrl.dispose();
    _locationCtrl.dispose();
    _applicantNameCtrl.dispose();
    _applicantDeptCtrl.dispose();
    _applicantPhoneCtrl.dispose();
    _workerCountCtrl.dispose();
    _emergencyCtrl.dispose();
    _ppeCtrl.dispose();
    _precautionsCtrl.dispose();
    _jsaCtrl.dispose();
    _sigCtrl.dispose();
    for (final c in _workerNameCtrls) {
      c.dispose();
    }
    for (final m in [_roleNameCtrls, _roleCertCtrls, _rolePhoneCtrls, _roleCompanyCtrls, _roleExpiryCtrls]) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _nextStep() {
    if (_currentStep < 5) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      if (_currentStep == 2) {
        _checklistItems = PtwStatutoryMasterData.getStandardChecklistForRiskType(_primaryRisk);
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── Save permit ───────────────────────────────────────────────────────────

  Future<void> _savePermit() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final dateStr = now.toIso8601String().substring(0, 10);
      final ptwNumber =
          widget.editingPermit?.ptwNumber ?? 'PTW-${dateStr.replaceAll('-', '')}-${now.millisecondsSinceEpoch % 1000 + 1}';

      // Save signature if drawn
      if (_sigCtrl.isNotEmpty && _savedSignaturePath == null) {
        _savedSignaturePath = await _sigCtrl.saveToFile(
          ptwNumber: ptwNumber,
          roleKey: 'applicant',
        );
      }

      final workerNames = <String>[];
      final count = int.tryParse(_workerCountCtrl.text) ?? 1;
      _ensureWorkerControllers(count);
      for (int i = 0; i < count && i < _workerNameCtrls.length; i++) {
        final name = _workerNameCtrls[i].text.trim();
        if (name.isNotEmpty) workerNames.add(name);
      }

      // Build confined roles list
      final confinedRoles = <ConfinedRoleModel>[];
      if (_primaryRisk == HighRiskType.confinedSpace || _secondaryRisks.contains(HighRiskType.confinedSpace)) {
        for (final roleType in ConfinedRoleType.values) {
          final name = _roleNameCtrls[roleType]?.text.trim() ?? '';
          if (name.isNotEmpty) {
            confinedRoles.add(ConfinedRoleModel(
              roleAssignmentId: 'CFR-$ptwNumber-${roleType.toDbCode()}',
              ptwNumber: ptwNumber,
              roleType: roleType,
              personName: name,
              companyName: _roleCompanyCtrls[roleType]?.text.trim() ?? '',
              certNumber: _roleCertCtrls[roleType]?.text.trim() ?? '',
              certInstitute: 'หน่วยงานฝึกอบรม',
              certIssueDate: dateStr,
              certExpiryDate: _roleExpiryCtrls[roleType]?.text.trim() ?? '',
              contactPhone: _rolePhoneCtrls[roleType]?.text.trim() ?? '',
            ));
          }
        }
      }

      // Build LOTO isolations
      final lotoIsolations = <LotoIsolationModel>[];
      for (int i = 0; i < _lotoEntries.length; i++) {
        final e = _lotoEntries[i];
        lotoIsolations.add(LotoIsolationModel(
          isolationId: 'LOTO-$ptwNumber-${(i + 1).toString().padLeft(2, '0')}',
          ptwNumber: ptwNumber,
          equipmentTagNo: e.tagCtrl.text.trim(),
          equipmentName: e.nameCtrl.text.trim(),
          locationArea: e.locationCtrl.text.trim(),
          energyType: e.energyType,
          isolationMethod: e.isolationMethod,
          padlockTagNo: e.padlockCtrl.text.trim(),
          lockAppliedBy: e.lockByCtrl.text.trim(),
          lockAppliedTimestamp: now.toIso8601String(),
          zeroEnergyTestMethod: e.testMethodCtrl.text.trim(),
          isZeroEnergyVerified: e.isZeroVerified,
          verifiedBy: e.verifiedByCtrl.text.trim(),
        ));
      }

      final startDateStr = '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';
      final endDateStr = '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}';
      final startTimeStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
      final endTimeStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';

      final permit = PtwModel(
        id: widget.editingPermit?.id,
        ptwNumber: ptwNumber,
        workTitle: _titleCtrl.text.trim(),
        workDescription: _descCtrl.text.trim(),
        primaryRiskType: _primaryRisk,
        secondaryRiskTypes: _secondaryRisks.toList(),
        plantArea: _areaCtrl.text.trim(),
        specificLocation: _locationCtrl.text.trim(),
        requestDate: dateStr,
        workStartDate: startDateStr,
        workStartTime: startTimeStr,
        workEndDate: endDateStr,
        workEndTime: endTimeStr,
        applicantType: _applicantType,
        applicantName: _applicantNameCtrl.text.trim(),
        applicantDepartment: _applicantDeptCtrl.text.trim(),
        applicantPhone: _applicantPhoneCtrl.text.trim(),
        workerCount: count,
        workerNames: workerNames,
        emergencyRescuePlan: _emergencyCtrl.text.trim(),
        requiredPpeList: _ppeCtrl.text.trim(),
        specialPrecautions: _precautionsCtrl.text.trim(),
        jsaReferenceNo: _jsaCtrl.text.trim().isEmpty ? null : _jsaCtrl.text.trim(),
        applicantSignaturePath: _savedSignaturePath,
        applicantSignedAt: _savedSignaturePath != null ? now.toIso8601String() : null,
        checklistItems: _checklistItems,
        confinedRoles: confinedRoles,
        lotoIsolations: lotoIsolations,
        createdAt: widget.editingPermit?.createdAt ?? now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      );

      if (widget.editingPermit != null) {
        await ref.read(ptwListProvider.notifier).updatePermit(permit);
      } else {
        await ref.read(ptwListProvider.notifier).createPermit(permit);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกใบอนุญาต $ptwNumber สำเร็จแล้ว'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        widget.onPermitSaved?.call();
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStepIndicator(),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStep1GeneralInfo(),
              _buildStep2RiskType(),
              _buildStep3Checklist(),
              _buildStep4Personnel(),
              _buildStep5Emergency(),
              _buildStep6Signature(),
            ],
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  // ── Step Indicator ────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(_stepTitles.length, (i) {
              final isActive = i == _currentStep;
              final isDone = i < _currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? Colors.green
                                  : isActive
                                      ? Colors.orange.shade700
                                      : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: isActive ? Colors.white : Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _stepTitles[i],
                            style: TextStyle(
                              fontSize: 10,
                              color: isActive ? Colors.orange.shade700 : Colors.grey.shade500,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    if (i < _stepTitles.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 24),
                          color: i < _currentStep ? Colors.green : Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Step 1: General Info ──────────────────────────────────────────────────

  Widget _buildStep1GeneralInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('ข้อมูลงาน', Icons.info_outline),
          _buildTextField(_titleCtrl, 'ชื่องาน / Work Title *', Icons.work, required: true),
          _buildTextField(_descCtrl, 'รายละเอียดงาน / Description *', Icons.description, maxLines: 3, required: true),
          _buildTextField(_areaCtrl, 'โรงงาน / อาคาร / แผนก *', Icons.factory, required: true),
          _buildTextField(_locationCtrl, 'ตำแหน่งเฉพาะเจาะจง / Specific Location *', Icons.location_on, required: true),
          const SizedBox(height: 16),
          _sectionHeader('ผู้ขออนุญาต', Icons.person),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('พนักงานบริษัท', style: TextStyle(fontSize: 13)),
                  value: 'INTERNAL_EMPLOYEE',
                  groupValue: _applicantType,
                  onChanged: (v) => setState(() => _applicantType = v!),
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('ผู้รับเหมา', style: TextStyle(fontSize: 13)),
                  value: 'CONTRACTOR',
                  groupValue: _applicantType,
                  onChanged: (v) => setState(() => _applicantType = v!),
                  dense: true,
                ),
              ),
            ],
          ),
          _buildTextField(_applicantNameCtrl, 'ชื่อผู้ขออนุญาต *', Icons.badge, required: true),
          _buildTextField(_applicantDeptCtrl, 'แผนก / บริษัทผู้รับเหมา *', Icons.business, required: true),
          _buildTextField(_applicantPhoneCtrl, 'เบอร์โทรศัพท์', Icons.phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _sectionHeader('ช่วงเวลาปฏิบัติงาน', Icons.schedule),
          Row(
            children: [
              Expanded(child: _buildDatePicker('วันเริ่มต้น', _startDate, (d) => setState(() => _startDate = d))),
              const SizedBox(width: 12),
              Expanded(child: _buildTimePicker('เวลาเริ่ม', _startTime, (t) => setState(() => _startTime = t))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildDatePicker('วันสิ้นสุด', _endDate, (d) => setState(() => _endDate = d))),
              const SizedBox(width: 12),
              Expanded(child: _buildTimePicker('เวลาสิ้นสุด', _endTime, (t) => setState(() => _endTime = t))),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 2: Risk Type ─────────────────────────────────────────────────────

  Widget _buildStep2RiskType() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('ประเภทความเสี่ยงหลัก *', Icons.warning_amber),
          const Text('เลือกประเภทงานความเสี่ยงสูงหลักที่ต้องขอใบอนุญาต',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 12),
          ...HighRiskType.values.map((type) {
            final isSelected = _primaryRisk == type;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? type.color : Colors.transparent,
                  width: 2,
                ),
              ),
              color: isSelected ? type.backgroundColor : Colors.white,
              child: RadioListTile<HighRiskType>(
                value: type,
                groupValue: _primaryRisk,
                onChanged: (v) {
                  setState(() {
                    _primaryRisk = v!;
                    _secondaryRisks.remove(v);
                    _checklistItems = [];
                  });
                },
                title: Row(
                  children: [
                    Icon(type.icon, color: type.color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(type.labelTh, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(type.legalRefTh, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
                activeColor: type.color,
              ),
            );
          }),
          const SizedBox(height: 16),
          _sectionHeader('ความเสี่ยงร่วม (เลือกได้หลายข้อ)', Icons.add_circle_outline),
          const Text('กรณีงานมีความเสี่ยงซ้อนทับจากหลายประเภท', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 12),
          ...HighRiskType.values.where((t) => t != _primaryRisk).map((type) {
            final isSelected = _secondaryRisks.contains(type);
            return CheckboxListTile(
              value: isSelected,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _secondaryRisks.add(type);
                  } else {
                    _secondaryRisks.remove(type);
                  }
                });
              },
              title: Row(
                children: [
                  Icon(type.icon, color: type.color, size: 18),
                  const SizedBox(width: 8),
                  Text(type.labelTh, style: const TextStyle(fontSize: 13)),
                ],
              ),
              activeColor: type.color,
              dense: true,
            );
          }),
        ],
      ),
    );
  }

  // ── Step 3: Checklist ─────────────────────────────────────────────────────

  Widget _buildStep3Checklist() {
    if (_checklistItems.isEmpty) {
      _checklistItems = PtwStatutoryMasterData.getStandardChecklistForRiskType(_primaryRisk);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('รายการตรวจสอบความปลอดภัย', Icons.checklist),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryRisk.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _primaryRisk.color.withAlpha(77)),
            ),
            child: Row(
              children: [
                Icon(_primaryRisk.icon, color: _primaryRisk.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'รายการตรวจสอบสำหรับ: ${_primaryRisk.labelTh}',
                    style: TextStyle(fontWeight: FontWeight.w600, color: _primaryRisk.color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._checklistItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(item.itemId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        if (item.isMandatory) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                            child: const Text('บังคับ', style: TextStyle(fontSize: 10, color: Colors.red)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(item.questionTh, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    Text(item.questionEn, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _checklistResultBtn(i, 'YES', Colors.green),
                        const SizedBox(width: 8),
                        _checklistResultBtn(i, 'NO', Colors.red),
                        const SizedBox(width: 8),
                        _checklistResultBtn(i, 'N/A', Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _checklistResultBtn(int index, String value, Color color) {
    final current = _checklistItems[index].result;
    final isSelected = current == value;
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _checklistItems[index] = _checklistItems[index].copyWith(result: value);
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? color : null,
        foregroundColor: isSelected ? Colors.white : color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
      ),
      child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  // ── Step 4: Personnel & LOTO ──────────────────────────────────────────────

  Widget _buildStep4Personnel() {
    final showConfinedRoles = _primaryRisk == HighRiskType.confinedSpace ||
        _secondaryRisks.contains(HighRiskType.confinedSpace);
    final showLoto = _primaryRisk == HighRiskType.electricalLoto ||
        _secondaryRisks.contains(HighRiskType.electricalLoto);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('รายชื่อผู้ปฏิบัติงาน', Icons.group),
          Row(
            children: [
              const Text('จำนวนผู้ปฏิบัติงาน:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _workerCountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                  onChanged: (v) {
                    final count = int.tryParse(v) ?? 1;
                    _ensureWorkerControllers(count);
                    setState(() {});
                  },
                ),
              ),
              const Text(' คน'),
            ],
          ),
          const SizedBox(height: 12),
          Builder(builder: (_) {
            final count = int.tryParse(_workerCountCtrl.text) ?? 1;
            _ensureWorkerControllers(count);
            return Column(
              children: List.generate(count, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _workerNameCtrls[i],
                    decoration: InputDecoration(
                      labelText: 'ผู้ปฏิบัติงานคนที่ ${i + 1}',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                );
              }),
            );
          }),

          // Confined Space 4 Roles
          if (showConfinedRoles) ...[
            const SizedBox(height: 16),
            _sectionHeader('ผู้มีหน้าที่ 4 ฝ่าย (ที่อับอากาศ)', Icons.sensor_door),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Text(
                'กฎกระทรวงฯ ๒๕๖๒ กำหนดให้มีผู้มีหน้าที่ครบ 4 บทบาท ทุกคนต้องผ่านการอบรมตามหลักสูตรที่กรมสวัสดิการและคุ้มครองแรงงานกำหนด',
                style: TextStyle(fontSize: 12, color: Colors.purple.shade800),
              ),
            ),
            const SizedBox(height: 12),
            ...ConfinedRoleType.values.map((role) => _buildRoleCard(role)),
          ],

          // LOTO Isolation Points
          if (showLoto) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _sectionHeader('จุดตัดแยกพลังงาน LOTO', Icons.lock)),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _lotoEntries.add(_LotoEntry())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('เพิ่มจุด'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            ..._lotoEntries.asMap().entries.map((entry) => _buildLotoCard(entry.key, entry.value)),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleCard(ConfinedRoleType role) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(role.icon, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text(role.labelTh, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('(${role.legalSectionTh})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildTextField(_roleNameCtrls[role]!, 'ชื่อ-สกุล', Icons.person, dense: true)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(_rolePhoneCtrls[role]!, 'โทร.', Icons.phone, dense: true)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildTextField(_roleCertCtrls[role]!, 'เลขที่ใบรับรอง', Icons.verified, dense: true)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(_roleExpiryCtrls[role]!, 'วันหมดอายุ (YYYY-MM-DD)', Icons.event, dense: true)),
              ],
            ),
            _buildTextField(_roleCompanyCtrls[role]!, 'บริษัท/หน่วยงาน', Icons.business, dense: true),
          ],
        ),
      ),
    );
  }

  Widget _buildLotoCard(int index, _LotoEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.amber.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Text('จุด LOTO #${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => setState(() => _lotoEntries.removeAt(index)),
                  iconSize: 20,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildTextField(entry.tagCtrl, 'Tag No. อุปกรณ์', Icons.tag, dense: true)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(entry.nameCtrl, 'ชื่ออุปกรณ์', Icons.precision_manufacturing, dense: true)),
              ],
            ),
            _buildTextField(entry.locationCtrl, 'ตำแหน่ง/อาคาร', Icons.location_on, dense: true),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<EnergyType>(
                    value: entry.energyType,
                    items: EnergyType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.labelTh, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setState(() => entry.energyType = v!),
                    decoration: const InputDecoration(labelText: 'ชนิดพลังงาน', border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(entry.padlockCtrl, 'หมายเลขกุญแจ', Icons.vpn_key, dense: true)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildTextField(entry.lockByCtrl, 'ผู้ใส่กุญแจ', Icons.person, dense: true)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(entry.testMethodCtrl, 'วิธีทดสอบพลังงานศูนย์', Icons.power_off, dense: true)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildTextField(entry.verifiedByCtrl, 'ผู้ยืนยันพลังงานศูนย์', Icons.verified_user, dense: true)),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Text('ยืนยันแล้ว:', style: TextStyle(fontSize: 13)),
                    Switch(
                      value: entry.isZeroVerified,
                      onChanged: (v) => setState(() => entry.isZeroVerified = v),
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 5: Emergency & PPE ───────────────────────────────────────────────

  Widget _buildStep5Emergency() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('แผนฉุกเฉิน', Icons.emergency),
          _buildTextField(_emergencyCtrl, 'แผนฉุกเฉินและเบอร์ติดต่อกู้ภัย *', Icons.phone_in_talk, maxLines: 3),
          const SizedBox(height: 16),
          _sectionHeader('รายการ PPE', Icons.safety_check),
          _buildTextField(_ppeCtrl, 'อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล *', Icons.shield, maxLines: 3),
          const SizedBox(height: 16),
          _sectionHeader('มาตรการควบคุมพิเศษ', Icons.security),
          _buildTextField(_precautionsCtrl, 'มาตรการควบคุมพิเศษเฉพาะหน้างาน', Icons.rule, maxLines: 3),
          const SizedBox(height: 16),
          _sectionHeader('เอกสารอ้างอิง JSA', Icons.article),
          _buildTextField(_jsaCtrl, 'เลขที่เอกสาร JSA / Risk Assessment', Icons.numbers),
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Text('PPE มาตรฐาน: ${_primaryRisk.labelTh}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange.shade800, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(_getPpeRecommendation(_primaryRisk),
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPpeRecommendation(HighRiskType risk) {
    switch (risk) {
      case HighRiskType.hotWork:
        return 'หมวกนิรภัย, หน้ากากกันควัน/ฟูม, ถุงมือหนัง, ผ้ากันเปลวไฟ, ชุดเชื่อม, รองเท้าเซฟตี้';
      case HighRiskType.confinedSpace:
        return 'SCBA/Airline Respirator, Full Body Harness, เครื่องวัดแก๊ส, ชุด HAZMAT (ถ้าจำเป็น), โทรศัพท์กันระเบิด';
      case HighRiskType.workingAtHeight:
        return 'Full Body Harness + Double Lanyard, หมวกนิรภัย, รองเท้าเซฟตี้ กันลื่น, แว่นตา';
      case HighRiskType.electricalLoto:
        return 'ถุงมือยางกันไฟฟ้า Class 00/0, รองเท้าฉนวนไฟฟ้า, แว่นตา Arc Flash Shield, ชุด Arc Flash PPE';
      case HighRiskType.excavationLifting:
        return 'หมวกนิรภัย, เสื้อกั้กสะท้อนแสง, รองเท้าเซฟตี้, ถุงมือ, เครื่องวัดก๊าซ (กรณีขุดลึก)';
    }
  }

  // ── Step 6: Signature ─────────────────────────────────────────────────────

  Widget _buildStep6Signature() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('ลายมือชื่อผู้ขออนุญาต', Icons.draw),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              'ข้าพเจ้าขอรับรองว่าข้อมูลที่กรอกในแบบฟอร์มใบอนุญาตทำงานนี้ถูกต้องครบถ้วน และจะดำเนินการตามมาตรการความปลอดภัยที่ระบุทุกประการ',
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
            ),
          ),
          const SizedBox(height: 16),
          SignaturePadWidget(
            controller: _sigCtrl,
            height: 200,
            placeholderText: 'ลายมือชื่อผู้ขออนุญาต — เซ็นชื่อที่นี่',
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final count = int.tryParse(_workerCountCtrl.text) ?? 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('สรุปข้อมูลใบอนุญาต', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(),
            _summaryRow('ชื่องาน', _titleCtrl.text),
            _summaryRow('พื้นที่', '${_areaCtrl.text} - ${_locationCtrl.text}'),
            _summaryRow('ประเภทความเสี่ยงหลัก', _primaryRisk.labelTh),
            _summaryRow('ผู้ขออนุญาต', _applicantNameCtrl.text),
            _summaryRow('จำนวนผู้ปฏิบัติงาน', '$count คน'),
            _summaryRow('ช่วงเวลา',
                '${_startDate.toString().substring(0, 10)} ${_startTime.format(context)} — ${_endDate.toString().substring(0, 10)} ${_endTime.format(context)}'),
            _summaryRow('รายการตรวจสอบ', '${_checklistItems.where((c) => c.result == 'YES').length}/${_checklistItems.length} รายการผ่าน'),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  // ── Navigation Buttons ────────────────────────────────────────────────────

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: _prevStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('ย้อนกลับ'),
            ),
          const Spacer(),
          if (_currentStep < 5)
            ElevatedButton.icon(
              onPressed: _nextStep,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('ถัดไป'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _savePermit,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกใบอนุญาต'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool required = false,
    bool dense = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 8 : 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: const OutlineInputBorder(),
          isDense: dense,
          contentPadding: dense ? const EdgeInsets.symmetric(vertical: 10, horizontal: 12) : null,
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime date, void Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
          isDense: true,
        ),
        child: Text(
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, void Function(TimeOfDay) onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.access_time, size: 18),
          isDense: true,
        ),
        child: Text(time.format(context), style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}

// ── LOTO Entry Helper Class ───────────────────────────────────────────────────

class _LotoEntry {
  final tagCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final padlockCtrl = TextEditingController(text: 'LOCK-01');
  final lockByCtrl = TextEditingController();
  final testMethodCtrl = TextEditingController(text: 'โวลต์มิเตอร์วัดไฟ 0V');
  final verifiedByCtrl = TextEditingController();
  EnergyType energyType = EnergyType.electrical;
  String isolationMethod = 'BREAKER_LOCK';
  bool isZeroVerified = false;

  _LotoEntry();

  factory _LotoEntry.fromModel(LotoIsolationModel m) {
    final entry = _LotoEntry();
    entry.tagCtrl.text = m.equipmentTagNo;
    entry.nameCtrl.text = m.equipmentName;
    entry.locationCtrl.text = m.locationArea;
    entry.padlockCtrl.text = m.padlockTagNo;
    entry.lockByCtrl.text = m.lockAppliedBy;
    entry.testMethodCtrl.text = m.zeroEnergyTestMethod;
    entry.verifiedByCtrl.text = m.verifiedBy;
    entry.energyType = m.energyType;
    entry.isolationMethod = m.isolationMethod;
    entry.isZeroVerified = m.isZeroEnergyVerified;
    return entry;
  }
}
