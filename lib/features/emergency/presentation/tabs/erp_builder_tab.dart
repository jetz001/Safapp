import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/hazard_type.dart';
import '../../domain/enums/emergency_enums.dart';
import '../../data/models/emergency_plan_model.dart';
import '../../data/datasources/emergency_presets_data.dart';
import '../../services/erp_pdf_exporter.dart';
import '../../services/emergency_excel_exporter.dart';
import '../notifiers/emergency_providers.dart';

class ErpBuilderTab extends ConsumerStatefulWidget {
  final EmergencyPlanModel? initialPlan;

  const ErpBuilderTab({super.key, this.initialPlan});

  @override
  ConsumerState<ErpBuilderTab> createState() => _ErpBuilderTabState();
}

class _ErpBuilderTabState extends ConsumerState<ErpBuilderTab> {
  int _currentStep = 0;
  late EmergencyPlanModel _editingPlan;
  bool _isSaving = false;
  bool _isRegularShift = true; // For Suppression team toggle

  // Controllers for general info
  late final TextEditingController _titleCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _totalEmpCtrl;
  late final TextEditingController _maleEmpCtrl;
  late final TextEditingController _femaleEmpCtrl;
  late final TextEditingController _commanderCtrl;
  late final TextEditingController _deputyCommanderCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _versionCtrl;

  @override
  void initState() {
    super.initState();
    final plan = widget.initialPlan ??
        EmergencyPresetsData.getPreset(
          hazardType: HazardType.fire,
          businessType: BusinessType.factory,
        );
    _editingPlan = plan;

    _titleCtrl = TextEditingController(text: plan.planTitle);
    _companyCtrl = TextEditingController(text: plan.companyName);
    _addressCtrl = TextEditingController(text: plan.companyAddress);
    _totalEmpCtrl = TextEditingController(text: plan.totalEmployees.toString());
    _maleEmpCtrl = TextEditingController(text: plan.maleCount.toString());
    _femaleEmpCtrl = TextEditingController(text: plan.femaleCount.toString());
    _commanderCtrl = TextEditingController(text: plan.fireCommanderName);
    _deputyCommanderCtrl = TextEditingController(text: plan.deputyCommanderName);
    _phoneCtrl = TextEditingController(text: plan.commanderPhone);
    _versionCtrl = TextEditingController(text: plan.version);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _addressCtrl.dispose();
    _totalEmpCtrl.dispose();
    _maleEmpCtrl.dispose();
    _femaleEmpCtrl.dispose();
    _commanderCtrl.dispose();
    _deputyCommanderCtrl.dispose();
    _phoneCtrl.dispose();
    _versionCtrl.dispose();
    super.dispose();
  }

  void _loadPreset(HazardType hazard, BusinessType bType) {
    setState(() {
      final preset = EmergencyPresetsData.getPreset(
        hazardType: hazard,
        businessType: bType,
        companyName: _companyCtrl.text.isNotEmpty ? _companyCtrl.text : 'บริษัท ตัวอย่าง จำกัด',
        companyAddress: _addressCtrl.text.isNotEmpty ? _addressCtrl.text : 'นิคมอุตสาหกรรมบางปู จ.สมุทรปราการ',
        totalEmployees: int.tryParse(_totalEmpCtrl.text) ?? 100,
        maleCount: int.tryParse(_maleEmpCtrl.text) ?? 60,
        femaleCount: int.tryParse(_femaleEmpCtrl.text) ?? 40,
      );
      _editingPlan = preset;
      _titleCtrl.text = preset.planTitle;
      _companyCtrl.text = preset.companyName;
      _addressCtrl.text = preset.companyAddress;
      _totalEmpCtrl.text = preset.totalEmployees.toString();
      _maleEmpCtrl.text = preset.maleCount.toString();
      _femaleEmpCtrl.text = preset.femaleCount.toString();
      _commanderCtrl.text = preset.fireCommanderName;
      _deputyCommanderCtrl.text = preset.deputyCommanderName;
      _phoneCtrl.text = preset.commanderPhone;
      _versionCtrl.text = preset.version;
      _currentStep = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('โหลดพรีเซ็ตมาตรฐาน "${hazard.shortTitle} - ${bType.label}" เรียบร้อยแล้ว'),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  void _syncCurrentFormValues() {
    _editingPlan = _editingPlan.copyWith(
      planTitle: _titleCtrl.text,
      companyName: _companyCtrl.text,
      companyAddress: _addressCtrl.text,
      totalEmployees: int.tryParse(_totalEmpCtrl.text) ?? 0,
      maleCount: int.tryParse(_maleEmpCtrl.text) ?? 0,
      femaleCount: int.tryParse(_femaleEmpCtrl.text) ?? 0,
      fireCommanderName: _commanderCtrl.text,
      deputyCommanderName: _deputyCommanderCtrl.text,
      commanderPhone: _phoneCtrl.text,
      version: _versionCtrl.text,
    );
  }

  Future<void> _savePlan() async {
    _syncCurrentFormValues();
    setState(() => _isSaving = true);
    try {
      final id = await ref.read(emergencyPlanListProvider.notifier).savePlan(_editingPlan);
      _editingPlan = _editingPlan.copyWith(id: id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกแผนฉุกเฉิน "${_editingPlan.planTitle}" เรียบร้อยแล้ว (ID: $id)'),
            backgroundColor: const Color(0xFF059669),
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

  Future<void> _exportPdf() async {
    _syncCurrentFormValues();
    try {
      final exporter = ErpPdfExporter();
      final path = await exporter.savePdf(_editingPlan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ส่งออกเล่มแผนฉุกเฉิน A4 สำเร็จ:\n$path'),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถส่งออก PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportExcel() async {
    _syncCurrentFormValues();
    try {
      await EmergencyExcelExporter.exportPlanDetails(_editingPlan, context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถส่งออก Excel: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DIALOG HELPERS (Full CRUD for each sub-plan)
  // ──────────────────────────────────────────────────────────────────────────

  // 1. Inspection Item Dialog
  Future<void> _showInspectionItemDialog({InspectionItem? existingItem, int? index}) async {
    final catCtrl = TextEditingController(text: existingItem?.category ?? '');
    final areaCtrl = TextEditingController(text: existingItem?.area ?? '');
    String freq = existingItem?.frequency ?? 'MONTHLY';
    final roleCtrl = TextEditingController(text: existingItem?.inspectorRole ?? 'จป.วิชาชีพ');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.search_outlined, color: Color(0xFFD97706), size: 22),
              ),
              const SizedBox(width: 10),
              Text(existingItem == null ? 'เพิ่มจุดตรวจตราความปลอดภัย' : 'แก้ไขจุดตรวจตรา', style: const TextStyle(fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: catCtrl,
                    decoration: const InputDecoration(
                      labelText: 'หมวดหมู่อุปกรณ์ / จุดตรวจ *',
                      hintText: 'เช่น เครื่องดับเพลิงมือถือ, ระบบสัญญาณเตือน, เส้นทางหนีไฟ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(label: const Text('เครื่องดับเพลิง', style: TextStyle(fontSize: 10)), onPressed: () => catCtrl.text = 'เครื่องดับเพลิงมือถือ (Portable Extinguishers)'),
                      ActionChip(label: const Text('สัญญาณเตือนภัย', style: TextStyle(fontSize: 10)), onPressed: () => catCtrl.text = 'ระบบสัญญาณเตือนเพลิงไหม้ (Fire Alarm & Smoke Detector)'),
                      ActionChip(label: const Text('ปั๊มน้ำดับเพลิง', style: TextStyle(fontSize: 10)), onPressed: () => catCtrl.text = 'ปั๊มน้ำดับเพลิง (Fire Pump) และระบบสปริงเกลอร์'),
                      ActionChip(label: const Text('ทางหนีไฟ/ไฟฉุกเฉิน', style: TextStyle(fontSize: 10)), onPressed: () => catCtrl.text = 'เส้นทางหนีไฟ ประตูหนีไฟ และไฟฉุกเฉิน (Emergency Light)'),
                      ActionChip(label: const Text('ตู้ MDB ไฟฟ้า', style: TextStyle(fontSize: 10)), onPressed: () => catCtrl.text = 'ตู้ควบคุมไฟฟ้าหลัก (MDB) และอุปกรณ์ไฟฟ้า'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: areaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'พื้นที่ / โซนที่ตรวจสอบ',
                      hintText: 'เช่น ทุกอาคาร, อาคารผลิต 1, คลังสินค้า',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: freq,
                    decoration: const InputDecoration(labelText: 'ความถี่ในการตรวจตรา', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'DAILY', child: Text('รายวัน (DAILY)')),
                      DropdownMenuItem(value: 'WEEKLY', child: Text('รายสัปดาห์ (WEEKLY)')),
                      DropdownMenuItem(value: 'MONTHLY', child: Text('รายเดือน (MONTHLY)')),
                      DropdownMenuItem(value: 'QUARTERLY', child: Text('รายไตรมาส (QUARTERLY)')),
                      DropdownMenuItem(value: 'ANNUALLY', child: Text('รายปี (ANNUALLY)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => freq = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ผู้ตรวจตรา / ตำแหน่ง',
                      hintText: 'เช่น จป.วิชาชีพ, ช่างซ่อมบำรุง, ตัวแทน คปอ.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
              onPressed: () {
                if (catCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('กรุณาระบุหมวดหมู่อุปกรณ์'), backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('บันทึกจุดตรวจ'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final updated = InspectionItem(
        category: catCtrl.text.trim(),
        area: areaCtrl.text.trim(),
        frequency: freq,
        inspectorRole: roleCtrl.text.trim(),
      );

      setState(() {
        final currentItems = List<InspectionItem>.from(_editingPlan.inspectionPlan.items);
        if (index != null && index >= 0 && index < currentItems.length) {
          currentItems[index] = updated;
        } else {
          currentItems.add(updated);
        }
        _editingPlan = _editingPlan.copyWith(
          inspectionPlan: InspectionSubPlan(
            items: currentItems,
            frequencyDescription: _editingPlan.inspectionPlan.frequencyDescription,
            reportingProcedure: _editingPlan.inspectionPlan.reportingProcedure,
          ),
        );
      });
    }

    catCtrl.dispose();
    areaCtrl.dispose();
    roleCtrl.dispose();
  }

  // 2. Training Course Dialog
  Future<void> _showTrainingCourseDialog({TrainingCourseItem? existingCourse, int? index}) async {
    final nameCtrl = TextEditingController(text: existingCourse?.courseName ?? '');
    final audienceCtrl = TextEditingController(text: existingCourse?.targetAudience ?? '');
    final providerCtrl = TextEditingController(text: existingCourse?.provider ?? '');
    final freqCtrl = TextEditingController(text: existingCourse?.frequency ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school_outlined, color: Color(0xFF2563EB), size: 22),
            ),
            const SizedBox(width: 10),
            Text(existingCourse == null ? 'เพิ่มหลักสูตรฝึกอบรม' : 'แก้ไขหลักสูตรฝึกอบรม', style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อหลักสูตรอบรม *',
                    hintText: 'เช่น การฝึกอบรมการดับเพลิงขั้นต้น (ข้อ ๒๗)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('ดับเพลิงขั้นต้น (>=40%)', style: TextStyle(fontSize: 10)),
                      onPressed: () {
                        nameCtrl.text = 'การฝึกอบรมการดับเพลิงขั้นต้น (กฎหมายกำหนด >= 40% ของลูกจ้างทุกแผนก)';
                        audienceCtrl.text = 'พนักงานใหม่และพนักงานประจำแผนกทุกส่วน';
                        providerCtrl.text = 'หน่วยงานฝึกอบรมที่ขึ้นทะเบียนตามมาตรา ๑๑';
                        freqCtrl.text = 'ปีละ ๑ ครั้ง หรือทุกครั้งที่มีพนักงานใหม่เข้าทำงาน';
                      },
                    ),
                    ActionChip(
                      label: const Text('ซ้อมหนีไฟประจำปี (ข้อ ๓๐)', style: TextStyle(fontSize: 10)),
                      onPressed: () {
                        nameCtrl.text = 'การฝึกซ้อมดับเพลิงและฝึกซ้อมอพยพหนีไฟประจำปี (กฎกระทรวงฯ ข้อ ๓๐)';
                        audienceCtrl.text = 'พนักงานทุกคนทุกระดับ ผู้รับเหมา และผู้มาติดต่อ';
                        providerCtrl.text = 'นายจ้างจัดฝึกซ้อมร่วมกับหน่วยงานภายนอก/เทศบาล';
                        freqCtrl.text = 'อย่างน้อยปีละ ๑ ครั้ง';
                      },
                    ),
                    ActionChip(
                      label: const Text('ปฐมพยาบาล CPR/AED', style: TextStyle(fontSize: 10)),
                      onPressed: () {
                        nameCtrl.text = 'การปฐมพยาบาลเบื้องต้นและการช่วยชีวิตขั้นพื้นฐาน (First Aid & CPR/AED)';
                        audienceCtrl.text = 'ทีมปฐมพยาบาล และตัวแทน คปอ.';
                        providerCtrl.text = 'สภากาชาดไทย หรือ รพ. เครือข่าย';
                        freqCtrl.text = 'ปีละ ๑ ครั้ง';
                      },
                    ),
                    ActionChip(
                      label: const Text('สารเคมีรั่วไหล (HAZMAT)', style: TextStyle(fontSize: 10)),
                      onPressed: () {
                        nameCtrl.text = 'การระงับเหตุสารเคมีรั่วไหลขั้นต้นด้วย Spill Kit';
                        audienceCtrl.text = 'พนักงานฝ่ายผลิต คลังสินค้า และทีม ERT';
                        providerCtrl.text = 'จป.วิชาชีพ หรือวิทยากรสารเคมี';
                        freqCtrl.text = 'ปีละ ๑ ครั้ง';
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: audienceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'กลุ่มเป้าหมายผู้เข้าอบรม',
                    hintText: 'เช่น พนักงานใหม่และทุกแผนก, พนักงานทุกคน',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: providerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ผู้ดำเนินการจัดอบรม / วิทยากร',
                    hintText: 'เช่น หน่วยงานฝึกอบรมขึ้นทะเบียน ม.๑๑, จป.วิชาชีพ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: freqCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ความถี่ในการฝึกอบรม',
                    hintText: 'เช่น ปีละ ๑ ครั้ง, ทุกครั้งที่มีพนักงานใหม่',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('กรุณาระบุชื่อหลักสูตรอบรม'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('บันทึกหลักสูตร'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updated = TrainingCourseItem(
        courseName: nameCtrl.text.trim(),
        targetAudience: audienceCtrl.text.trim(),
        provider: providerCtrl.text.trim(),
        frequency: freqCtrl.text.trim(),
      );

      setState(() {
        final currentCourses = List<TrainingCourseItem>.from(_editingPlan.trainingPlan.courses);
        if (index != null && index >= 0 && index < currentCourses.length) {
          currentCourses[index] = updated;
        } else {
          currentCourses.add(updated);
        }
        _editingPlan = _editingPlan.copyWith(
          trainingPlan: TrainingSubPlan(
            basicFireQuotaPercent: _editingPlan.trainingPlan.basicFireQuotaPercent,
            annualDrillTargetMonth: _editingPlan.trainingPlan.annualDrillTargetMonth,
            courses: currentCourses,
          ),
        );
      });
    }

    nameCtrl.dispose();
    audienceCtrl.dispose();
    providerCtrl.dispose();
    freqCtrl.dispose();
  }

  // 3. Campaign Activity Dialog
  Future<void> _showCampaignActivityDialog() async {
    final actCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เพิ่มกิจกรรมรณรงค์ความปลอดภัย', style: TextStyle(fontSize: 16)),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: actCtrl,
                decoration: const InputDecoration(
                  labelText: 'ชื่อกิจกรรมรณรงค์ *',
                  hintText: 'เช่น จัดสัปดาห์ความปลอดภัย Safety Week',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(label: const Text('5ส บิ๊กคลีนนิ่ง', style: TextStyle(fontSize: 10)), onPressed: () => actCtrl.text = 'จัดกิจกรรมสัปดาห์ความปลอดภัยและบิ๊กคลีนนิ่งเดย์ (5ส เพื่อลดแหล่งสะสมเชื้อเพลิง)'),
                  ActionChip(label: const Text('เขตห้ามสูบบุหรี่', style: TextStyle(fontSize: 10)), onPressed: () => actCtrl.text = 'รณรงค์พื้นที่เขตห้ามสูบบุหรี่เด็ดขาดในโรงงาน และกวดขันจุดสูบบุหรี่ภายนอก'),
                  ActionChip(label: const Text('คลิปสาธิตถังดับเพลิง', style: TextStyle(fontSize: 10)), onPressed: () => actCtrl.text = 'เผยแพร่วิดีโอสาธิตการใช้ถังดับเพลิงชนิดผงเคมีแห้ง/CO2 ทางไลน์กลุ่มพนักงานและจอประชาสัมพันธ์'),
                  ActionChip(label: const Text('ป้ายเตือนเบอร์ 199', style: TextStyle(fontSize: 10)), onPressed: () => actCtrl.text = 'ติดป้ายเตือนอันตรายและเบอร์โทรฉุกเฉิน 199 ณ ทุกจุดเข้าออก'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
            onPressed: () {
              if (actCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('เพิ่มกิจกรรม'),
          ),
        ],
      ),
    );

    if (confirmed == true && actCtrl.text.trim().isNotEmpty) {
      setState(() {
        final currentActs = List<String>.from(_editingPlan.campaignPlan.activities)..add(actCtrl.text.trim());
        _editingPlan = _editingPlan.copyWith(
          campaignPlan: CampaignSubPlan(
            activities: currentActs,
            smokingControlPolicy: _editingPlan.campaignPlan.smokingControlPolicy,
            hotWorkSafetyReminder: _editingPlan.campaignPlan.hotWorkSafetyReminder,
          ),
        );
      });
    }

    actCtrl.dispose();
  }

  // 4. Suppression Role Dialog
  Future<void> _showSuppressionRoleDialog({required bool isRegular, EmergencyTeamRole? existingRole, int? index}) async {
    final titleCtrl = TextEditingController(text: existingRole?.roleTitle ?? '');
    final personCtrl = TextEditingController(text: existingRole?.assignedPerson ?? '');
    final contactCtrl = TextEditingController(text: existingRole?.contactNumber ?? '');
    final dutiesCtrl = TextEditingController(text: existingRole?.keyDuties ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fire_hydrant_alt, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 10),
            Text(existingRole == null ? 'เพิ่มตำแหน่งทีมระงับเหตุ' : 'แก้ไขตำแหน่งทีมระงับเหตุ', style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อตำแหน่งในทีมฉุกเฉิน *',
                    hintText: 'เช่น หัวหน้าชุดผจญเพลิงขั้นต้น, ผู้ควบคุมระบบไฟฟ้า',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(label: const Text('ผู้อำนวยการดับเพลิง', style: TextStyle(fontSize: 10)), onPressed: () => titleCtrl.text = 'ผู้อำนวยการดับเพลิง (Incident Commander)'),
                    ActionChip(label: const Text('หัวหน้าชุดผจญเพลิง', style: TextStyle(fontSize: 10)), onPressed: () => titleCtrl.text = 'หัวหน้าชุดผจญเพลิงขั้นต้น'),
                    ActionChip(label: const Text('ผู้ควบคุมไฟฟ้า', style: TextStyle(fontSize: 10)), onPressed: () => titleCtrl.text = 'ผู้ควบคุมระบบไฟฟ้าและพลังงาน'),
                    ActionChip(label: const Text('ผู้ควบคุม Fire Pump', style: TextStyle(fontSize: 10)), onPressed: () => titleCtrl.text = 'ผู้ควบคุมเครื่องสูบน้ำดับเพลิง (Fire Pump)'),
                    ActionChip(label: const Text('ประสานงาน 199', style: TextStyle(fontSize: 10)), onPressed: () => titleCtrl.text = 'ผู้ประสานงานและสื่อสารฉุกเฉิน'),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: personCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ผู้รับผิดชอบ / รายชื่อพนักงาน (ใส่ได้หลายคน)*',
                    hintText: 'เช่น นายสมศักดิ์ มั่นคง, นายสมชาย สู้เพลิง',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactCtrl,
                  decoration: const InputDecoration(
                    labelText: 'เบอร์ติดต่อโทรศัพท์ / วอร์สื่อสาร',
                    hintText: 'เช่น 081-234-5678 หรือ ว.ช่อง 1',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dutiesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'หน้าที่สำคัญ',
                    hintText: 'เช่น ตัดกระแสไฟฟ้าเฉพาะโซนเกิดเหตุ และควบคุมระบบไฟฉุกเฉิน',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('กรุณาระบุชื่อตำแหน่งในทีมฉุกเฉิน'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('บันทึกตำแหน่ง'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updatedRole = EmergencyTeamRole(
        roleTitle: titleCtrl.text.trim(),
        assignedPerson: personCtrl.text.trim(),
        contactNumber: contactCtrl.text.trim(),
        keyDuties: dutiesCtrl.text.trim(),
      );

      setState(() {
        final currentTeam = isRegular
            ? List<EmergencyTeamRole>.from(_editingPlan.suppressionPlan.regularShiftTeam)
            : List<EmergencyTeamRole>.from(_editingPlan.suppressionPlan.offHoursTeam);

        if (index != null && index >= 0 && index < currentTeam.length) {
          currentTeam[index] = updatedRole;
        } else {
          currentTeam.add(updatedRole);
        }

        _editingPlan = _editingPlan.copyWith(
          suppressionPlan: SuppressionSubPlan(
            initialResponseProtocol: _editingPlan.suppressionPlan.initialResponseProtocol,
            majorEmergencyProtocol: _editingPlan.suppressionPlan.majorEmergencyProtocol,
            regularShiftTeam: isRegular ? currentTeam : _editingPlan.suppressionPlan.regularShiftTeam,
            offHoursTeam: isRegular ? _editingPlan.suppressionPlan.offHoursTeam : currentTeam,
          ),
        );
      });
    }

    titleCtrl.dispose();
    personCtrl.dispose();
    contactCtrl.dispose();
    dutiesCtrl.dispose();
  }

  // 5. Evacuation Team Dialog (Supports multiple teams & multi-member names!)
  Future<void> _showEvacuationTeamDialog({EvacuationTeam? existingTeam, int? index}) async {
    final teamNameCtrl = TextEditingController(text: existingTeam?.teamName ?? '');
    final areaFloorCtrl = TextEditingController(text: existingTeam?.areaFloor ?? '');
    final leaderNameCtrl = TextEditingController(text: existingTeam?.leaderName ?? '');
    final deputyLeaderNameCtrl = TextEditingController(text: existingTeam?.deputyLeaderName ?? '');
    final membersCtrl = TextEditingController(text: existingTeam?.members.join('\n') ?? '');
    final assemblyPointCtrl = TextEditingController(text: existingTeam?.assignedAssemblyPoint ?? '');
    final dutiesCtrl = TextEditingController(text: existingTeam?.duties ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.groups_outlined, color: Color(0xFF059669), size: 22),
            ),
            const SizedBox(width: 10),
            Text(existingTeam == null ? 'เพิ่มทีมอพยพ / ผู้นำทางหนีไฟ' : 'แก้ไขทีมอพยพ', style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: teamNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อทีม / หน่วยอพยพ *',
                    hintText: 'เช่น ทีมผู้นำทางหนีไฟ อาคารผลิต ชั้น 1, ทีมตรวจค้นผู้ติดค้าง',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: areaFloorCtrl,
                        decoration: const InputDecoration(
                          labelText: 'พื้นที่ / ชั้นที่รับผิดชอบ',
                          hintText: 'เช่น อาคาร 1 ชั้น 2, คลังสินค้า โซน A',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: assemblyPointCtrl,
                        decoration: const InputDecoration(
                          labelText: 'จุดรวมพลเป้าหมาย',
                          hintText: 'เช่น จุดรวมพลที่ ๑ (ลานจอดรถ)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: leaderNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'หัวหน้าทีม (Leader)',
                          hintText: 'ชื่อ-นามสกุล / ตำแหน่งงาน',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: deputyLeaderNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'รองหัวหน้าทีม (Deputy Leader)',
                          hintText: 'ชื่อ-นามสกุล',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: membersCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'รายชื่อสมาชิกในทีม (ใส่ได้หลายคน)*',
                    hintText: 'พิมพ์รายชื่อสมาชิก โดยแยกบรรทัดละคน หรือคั่นด้วยเครื่องหมายจุลภาค (,)\nเช่น:\nนายสมชาย ดีเลิศ\nน.ส.วรรณา สดใส\nนายกิตติ เก่งกล้า',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dutiesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ภารกิจหน้าที่ของทีม',
                    hintText: 'เช่น นำทางพนักงานอพยพตามเส้นทางที่กำหนด เคลียร์ห้องน้ำมุมอับ และตรวจนับยอด',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (teamNameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('กรุณาระบุชื่อทีม'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('บันทึกข้อมูลทีม'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final rawMembersText = membersCtrl.text.trim();
      final memberList = rawMembersText.isEmpty
          ? <String>[]
          : rawMembersText
              .split(RegExp(r'[\n,]+'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      final updatedTeam = EvacuationTeam(
        teamName: teamNameCtrl.text.trim(),
        areaFloor: areaFloorCtrl.text.trim(),
        leaderName: leaderNameCtrl.text.trim(),
        deputyLeaderName: deputyLeaderNameCtrl.text.trim(),
        members: memberList,
        assignedAssemblyPoint: assemblyPointCtrl.text.trim(),
        duties: dutiesCtrl.text.trim(),
      );

      setState(() {
        final currentTeams = List<EvacuationTeam>.from(_editingPlan.evacuationPlan.evacuationTeams);
        if (index != null && index >= 0 && index < currentTeams.length) {
          currentTeams[index] = updatedTeam;
        } else {
          currentTeams.add(updatedTeam);
        }
        _editingPlan = _editingPlan.copyWith(
          evacuationPlan: _editingPlan.evacuationPlan.copyWith(
            evacuationTeams: currentTeams,
          ),
        );
      });
    }

    teamNameCtrl.dispose();
    areaFloorCtrl.dispose();
    leaderNameCtrl.dispose();
    deputyLeaderNameCtrl.dispose();
    membersCtrl.dispose();
    assemblyPointCtrl.dispose();
    dutiesCtrl.dispose();
  }

  // 6. Assembly Point Dialog
  Future<void> _showAssemblyPointDialog({AssemblyPointItem? existingPoint, int? index}) async {
    final nameCtrl = TextEditingController(text: existingPoint?.pointName ?? '');
    final locCtrl = TextEditingController(text: existingPoint?.location ?? '');
    final deptsCtrl = TextEditingController(text: existingPoint?.assignedDepartments ?? '');
    final capCtrl = TextEditingController(text: existingPoint != null ? existingPoint.capacity.toString() : '100');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.flag_outlined, color: Color(0xFF059669), size: 22),
            ),
            const SizedBox(width: 10),
            Text(existingPoint == null ? 'เพิ่มจุดรวมพล' : 'แก้ไขจุดรวมพล', style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อจุดรวมพล *',
                    hintText: 'เช่น จุดรวมพลที่ ๑ (ลานจอดรถหน้าอาคาร)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ที่ตั้ง / ทิศทาง / สภาพพื้นที่',
                    hintText: 'เช่น ทิศเหนือ ห่างจากตัวอาคาร ๒๐ เมตร อากาศถ่ายเท',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deptsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'แผนกที่กำหนดให้มารวมพล',
                    hintText: 'เช่น ฝ่ายผลิต, คลังสินค้า, ฝ่ายสำนักงาน',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ความจุรองรับ (คน)',
                    hintText: '100',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('กรุณาระบุชื่อจุดรวมพล'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('บันทึกจุดรวมพล'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updated = AssemblyPointItem(
        pointName: nameCtrl.text.trim(),
        location: locCtrl.text.trim(),
        assignedDepartments: deptsCtrl.text.trim(),
        capacity: int.tryParse(capCtrl.text.trim()) ?? 100,
      );

      setState(() {
        final current = List<AssemblyPointItem>.from(_editingPlan.evacuationPlan.assemblyPoints);
        if (index != null && index >= 0 && index < current.length) {
          current[index] = updated;
        } else {
          current.add(updated);
        }
        _editingPlan = _editingPlan.copyWith(
          evacuationPlan: _editingPlan.evacuationPlan.copyWith(assemblyPoints: current),
        );
      });
    }

    nameCtrl.dispose();
    locCtrl.dispose();
    deptsCtrl.dispose();
    capCtrl.dispose();
  }

  // 7. Emergency Government Contact Dialog
  Future<void> _showGovernmentContactDialog({EmergencyContactAgency? existingContact, int? index}) async {
    final agencyCtrl = TextEditingController(text: existingContact?.agencyName ?? '');
    final phoneCtrl = TextEditingController(text: existingContact?.phoneNumber ?? '');
    final personCtrl = TextEditingController(text: existingContact?.contactPerson ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.phone_in_talk, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 10),
            Text(existingContact == null ? 'เพิ่มหน่วยงานติดต่อฉุกเฉิน' : 'แก้ไขหน่วยงานติดต่อ', style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: agencyCtrl,
                decoration: const InputDecoration(
                  labelText: 'ชื่อหน่วยงาน / สถานี *',
                  hintText: 'เช่น สถานีดับเพลิงเทศบาล, รพ.ประจำจังหวัด',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(label: const Text('ดับเพลิง 199', style: TextStyle(fontSize: 10)), onPressed: () { agencyCtrl.text = 'สถานีดับเพลิงและกู้ภัยในพื้นที่ (ศูนย์รวมข่าว 199)'; phoneCtrl.text = '199'; }),
                  ActionChip(label: const Text('กู้ชีพ 1669', style: TextStyle(fontSize: 10)), onPressed: () { agencyCtrl.text = 'ศูนย์กู้ชีพนเรนทร (ห้องฉุกเฉิน ER)'; phoneCtrl.text = '1669'; }),
                  ActionChip(label: const Text('ตำรวจ 191', style: TextStyle(fontSize: 10)), onPressed: () { agencyCtrl.text = 'สถานีตำรวจภูธรพื้นที่'; phoneCtrl.text = '191'; }),
                  ActionChip(label: const Text('การไฟฟ้า 1129', style: TextStyle(fontSize: 10)), onPressed: () { agencyCtrl.text = 'การไฟฟ้านครหลวง/ภูมิภาค (ตัดไฟฉุกเฉิน)'; phoneCtrl.text = '1129'; }),
                  ActionChip(label: const Text('กรมสวัสดิการฯ สปร.๔', style: TextStyle(fontSize: 10)), onPressed: () { agencyCtrl.text = 'สำนักงานสวัสดิการและคุ้มครองแรงงานจังหวัด (ยื่น สปร. ๔)'; }),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'หมายเลขโทรศัพท์ติดต่อ *',
                  hintText: 'เช่น 199 หรือ 02-395-0111',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: personCtrl,
                decoration: const InputDecoration(
                  labelText: 'ผู้ประสานงาน / ตำแหน่ง',
                  hintText: 'เช่น หัวหน้าสถานีดับเพลิง, ห้องฉุกเฉิน ER',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () {
              if (agencyCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('กรุณาระบุชื่อหน่วยงานและหมายเลขโทรศัพท์'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('บันทึกหน่วยงาน'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updated = EmergencyContactAgency(
        agencyName: agencyCtrl.text.trim(),
        phoneNumber: phoneCtrl.text.trim(),
        contactPerson: personCtrl.text.trim(),
      );

      setState(() {
        final current = List<EmergencyContactAgency>.from(_editingPlan.reliefPlan.governmentContacts);
        if (index != null && index >= 0 && index < current.length) {
          current[index] = updated;
        } else {
          current.add(updated);
        }
        _editingPlan = _editingPlan.copyWith(
          reliefPlan: ReliefSubPlan(
            governmentContacts: current,
            searchAndRescueProtocol: _editingPlan.reliefPlan.searchAndRescueProtocol,
            damageAssessmentProtocol: _editingPlan.reliefPlan.damageAssessmentProtocol,
            businessContinuityProtocol: _editingPlan.reliefPlan.businessContinuityProtocol,
          ),
        );
      });
    }

    agencyCtrl.dispose();
    phoneCtrl.dispose();
    personCtrl.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD METHOD
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Control Bar ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;
                return isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderTitle(),
                          const SizedBox(height: 12),
                          _buildHeaderActions(),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _buildHeaderTitle()),
                          _buildHeaderActions(),
                        ],
                      );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Hazard & Preset Switcher ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, size: 18, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    const Text('เลือกประเภทภัยและโหลดพรีเซ็ตมาตรฐาน: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: HazardType.values.map((h) {
                      final isSelected = _editingPlan.hazardType == h;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          avatar: Icon(h.icon, size: 16, color: isSelected ? Colors.white : h.color),
                          label: Text(h.titleTh, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          selected: isSelected,
                          selectedColor: h.color,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                          onSelected: (val) {
                            if (val) {
                              _loadPreset(h, _editingPlan.businessType);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text('ประเภทสถานประกอบการ: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      const SizedBox(width: 8),
                      ...BusinessType.values.map((b) {
                        final isSelected = _editingPlan.businessType == b;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: FilterChip(
                            label: Text(b.label, style: const TextStyle(fontSize: 11)),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                _loadPreset(_editingPlan.hazardType, b);
                              }
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Stepper Form ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Stepper(
              physics: const NeverScrollableScrollPhysics(),
              currentStep: _currentStep,
              onStepTapped: (step) {
                _syncCurrentFormValues();
                setState(() => _currentStep = step);
              },
              onStepContinue: () {
                _syncCurrentFormValues();
                if (_currentStep < 6) {
                  setState(() => _currentStep += 1);
                } else {
                  _savePlan();
                }
              },
              onStepCancel: () {
                _syncCurrentFormValues();
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _editingPlan.hazardType.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text(_currentStep == 6 ? 'บันทึกแผนทั้งหมด' : 'ถัดไป >'),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                          child: const Text('< ย้อนกลับ'),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('ข้อมูลสถานประกอบการและผู้อำนวยการสั่งการ', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('ชื่อบริษัท ที่ตั้ง และผู้บัญชาการเหตุการณ์', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  isActive: _currentStep >= 0,
                  content: _buildStep1General(),
                ),
                Step(
                  title: const Text('๑. แผนการตรวจตรา (Inspection Plan)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('การสำรวจจุดเสี่ยง อุปกรณ์ดับเพลิง และความถี่ในการตรวจสอบ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  isActive: _currentStep >= 1,
                  content: _buildStep2Inspection(),
                ),
                Step(
                  title: const Text('๒. แผนการอบรม (Training Plan)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('โควตาดับเพลิงขั้นต้น >= 40% (ข้อ ๒๗) และกำหนดการซ้อม', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  isActive: _currentStep >= 2,
                  content: _buildStep3Training(),
                ),
                Step(
                  title: const Text('๓. แผนการรณรงค์ป้องกัน (Campaign Plan)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('กิจกรรม 5ส สื่อประชาสัมพันธ์ และมาตรการลดแหล่งกำเนิดประกายไฟ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  isActive: _currentStep >= 3,
                  content: _buildStep4Campaign(),
                ),
                Step(
                  title: const Text('๔. แผนการดับเพลิงและระงับเหตุ (Suppression Plan)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('ขั้นตอนเผชิญเหตุขั้นต้น-ขั้นรุนแรง และโครงสร้างทีมดับเพลิง', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  isActive: _currentStep >= 4,
                  content: _buildStep5Suppression(),
                ),
                Step(
                  title: const Text('๕. แผนอพยพหนีไฟ (Evacuation Plan)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('สัญญาณเตือนภัย จุดรวมพล และทีมผู้นำทางหนีไฟ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  isActive: _currentStep >= 5,
                  content: _buildStep6Evacuation(),
                ),
                Step(
                  title: const Text('๖. แผนบรรเทาทุกข์และฟื้นฟู (Relief & Recovery Plan)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('การประสานงาน 199/รพ./ตำรวจ การประเมินความเสียหาย และ BCP', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  isActive: _currentStep >= 6,
                  content: _buildStep7Relief(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_editingPlan.hazardType.icon, color: _editingPlan.hazardType.color, size: 24),
            const SizedBox(width: 8),
            const Text(
              'เครื่องมือจัดทำแผนฉุกเฉิน (ERP Builder)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'จัดทำโครงสร้าง ๖ แผนย่อยตามกฎหมายอัคคีภัย ๒๕๕๕ ข้อ ๔ ปรับแต่งรายชื่อทีมและพิมพ์เล่มแผน',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: _exportExcel,
          icon: const Icon(Icons.table_view_outlined, size: 16),
          label: const Text('Excel'),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF059669)),
        ),
        OutlinedButton.icon(
          onPressed: _exportPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
          label: const Text('ส่งออก PDF เล่มแผน'),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _savePlan,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined, size: 16),
          label: const Text('บันทึกแผนฉุกเฉิน'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 1: GENERAL INFO
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildStep1General() {
    return Column(
      children: [
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(labelText: 'ชื่อแผนฉุกเฉิน', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _companyCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อสถานประกอบกิจการ', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _versionCtrl,
                decoration: const InputDecoration(labelText: 'ฉบับที่ (Version)', border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressCtrl,
          decoration: const InputDecoration(labelText: 'ที่ตั้งสถานประกอบกิจการ', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _totalEmpCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'พนักงานทั้งหมด (คน)', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maleEmpCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'พนักงานชาย (คน)', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _femaleEmpCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'พนักงานหญิง (คน)', border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commanderCtrl,
                decoration: const InputDecoration(labelText: 'ผู้อำนวยการสั่งการ/ผู้จัดการโรงงาน', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _deputyCommanderCtrl,
                decoration: const InputDecoration(labelText: 'รองผู้อำนวยการเหตุฉุกเฉิน', border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneCtrl,
          decoration: const InputDecoration(labelText: 'เบอร์โทรศัพท์ติดต่อฉุกเฉินตลอด 24 ชม.', border: OutlineInputBorder()),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 2: INSPECTION PLAN
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildStep2Inspection() {
    final items = _editingPlan.inspectionPlan.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('รายการจุดตรวจตราและอุปกรณ์ (${items.length} รายการ):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ElevatedButton.icon(
              onPressed: () => _showInspectionItemDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('เพิ่มจุดตรวจ'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Text('ยังไม่มีรายการตรวจตรา กดปุ่ม "+ เพิ่มจุดตรวจ" หรือโหลดพรีเซ็ต', style: TextStyle(color: Colors.grey)),
          )
        else
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final it = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('พื้นที่: ${it.area}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Text(it.frequency, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: Text('ผู้ตรวจ: ${it.inspectorRole}', style: const TextStyle(fontSize: 11))),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                    onPressed: () => _showInspectionItemDialog(existingItem: it, index: idx),
                    tooltip: 'แก้ไข',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        final newItems = List<InspectionItem>.from(items)..removeAt(idx);
                        _editingPlan = _editingPlan.copyWith(
                          inspectionPlan: InspectionSubPlan(
                            items: newItems,
                            frequencyDescription: _editingPlan.inspectionPlan.frequencyDescription,
                            reportingProcedure: _editingPlan.inspectionPlan.reportingProcedure,
                          ),
                        );
                      });
                    },
                    tooltip: 'ลบ',
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: _editingPlan.inspectionPlan.frequencyDescription,
          decoration: const InputDecoration(labelText: 'ความถี่และภาพรวมขั้นตอนการตรวจตรา', border: OutlineInputBorder()),
          onChanged: (val) {
            _editingPlan = _editingPlan.copyWith(
              inspectionPlan: InspectionSubPlan(
                items: _editingPlan.inspectionPlan.items,
                frequencyDescription: val,
                reportingProcedure: _editingPlan.inspectionPlan.reportingProcedure,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: _editingPlan.inspectionPlan.reportingProcedure,
          decoration: const InputDecoration(labelText: 'ขั้นตอนการรายงานผลและซ่อมบำรุงเมื่อพบจุดชำรุด', border: OutlineInputBorder()),
          onChanged: (val) {
            _editingPlan = _editingPlan.copyWith(
              inspectionPlan: InspectionSubPlan(
                items: _editingPlan.inspectionPlan.items,
                frequencyDescription: _editingPlan.inspectionPlan.frequencyDescription,
                reportingProcedure: val,
              ),
            );
          },
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 3: TRAINING PLAN (Making it fully interactive!)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildStep3Training() {
    final courses = _editingPlan.trainingPlan.courses;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'กฎกระทรวงอัคคีภัย ๒๕๕๕ ข้อ ๒๗: นายจ้างต้องจัดให้ลูกจ้างไม่น้อยกว่าร้อยละ ๔๐ ของจำนวนลูกจ้างในแต่ละแผนกรับการฝึกอบรมการดับเพลิงขั้นต้น และข้อ ๓๐ ให้ฝึกซ้อมดับเพลิงและฝึกซ้อมหนีไฟอย่างน้อยปีละ ๑ ครั้ง',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade900, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _editingPlan.trainingPlan.basicFireQuotaPercent.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'เป้าหมายโควตาอบรมดับเพลิงขั้นต้น (%)',
                  hintText: '40',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent, size: 16),
                ),
                onChanged: (val) {
                  final pct = double.tryParse(val) ?? 40.0;
                  _editingPlan = _editingPlan.copyWith(
                    trainingPlan: TrainingSubPlan(
                      basicFireQuotaPercent: pct,
                      annualDrillTargetMonth: _editingPlan.trainingPlan.annualDrillTargetMonth,
                      courses: _editingPlan.trainingPlan.courses,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: _editingPlan.trainingPlan.annualDrillTargetMonth,
                decoration: const InputDecoration(
                  labelText: 'กำหนดเดือนซ้อมใหญ่ประจำปี (ข้อ ๓๐)',
                  hintText: 'พฤศจิกายน',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today_outlined, size: 16),
                ),
                onChanged: (val) {
                  _editingPlan = _editingPlan.copyWith(
                    trainingPlan: TrainingSubPlan(
                      basicFireQuotaPercent: _editingPlan.trainingPlan.basicFireQuotaPercent,
                      annualDrillTargetMonth: val,
                      courses: _editingPlan.trainingPlan.courses,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('หลักสูตรอบรมตามแผน (${courses.length} หลักสูตร):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ElevatedButton.icon(
              onPressed: () => _showTrainingCourseDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('เพิ่มหลักสูตรอบรม'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (courses.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Text('ยังไม่มีหลักสูตรอบรม กดปุ่ม "+ เพิ่มหลักสูตรอบรม" ด้านบน', style: TextStyle(color: Colors.grey)),
          )
        else
          ...courses.asMap().entries.map((entry) {
            final idx = entry.key;
            final c = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school, size: 18, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(c.courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                        onPressed: () => _showTrainingCourseDialog(existingCourse: c, index: idx),
                        tooltip: 'แก้ไข',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            final current = List<TrainingCourseItem>.from(courses)..removeAt(idx);
                            _editingPlan = _editingPlan.copyWith(
                              trainingPlan: TrainingSubPlan(
                                basicFireQuotaPercent: _editingPlan.trainingPlan.basicFireQuotaPercent,
                                annualDrillTargetMonth: _editingPlan.trainingPlan.annualDrillTargetMonth,
                                courses: current,
                              ),
                            );
                          });
                        },
                        tooltip: 'ลบ',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      Text('กลุ่มเป้าหมาย: ${c.targetAudience}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                      Text('ผู้จัด: ${c.provider}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                      Text('ความถี่: ${c.frequency}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 4: CAMPAIGN PLAN
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildStep4Campaign() {
    final acts = _editingPlan.campaignPlan.activities;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('กิจกรรมรณรงค์และส่งเสริมความปลอดภัย (${acts.length} กิจกรรม):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ElevatedButton.icon(
              onPressed: _showCampaignActivityDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('เพิ่มกิจกรรม'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...acts.asMap().entries.map((entry) {
          final idx = entry.key;
          final a = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 16, color: Color(0xFF059669)),
                const SizedBox(width: 8),
                Expanded(child: Text(a, style: const TextStyle(fontSize: 12))),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      final updated = List<String>.from(acts)..removeAt(idx);
                      _editingPlan = _editingPlan.copyWith(
                        campaignPlan: CampaignSubPlan(
                          activities: updated,
                          smokingControlPolicy: _editingPlan.campaignPlan.smokingControlPolicy,
                          hotWorkSafetyReminder: _editingPlan.campaignPlan.hotWorkSafetyReminder,
                        ),
                      );
                    });
                  },
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: _editingPlan.campaignPlan.smokingControlPolicy,
          decoration: const InputDecoration(labelText: 'นโยบายการควบคุมการสูบบุหรี่', border: OutlineInputBorder()),
          onChanged: (val) {
            _editingPlan = _editingPlan.copyWith(
              campaignPlan: CampaignSubPlan(
                activities: _editingPlan.campaignPlan.activities,
                smokingControlPolicy: val,
                hotWorkSafetyReminder: _editingPlan.campaignPlan.hotWorkSafetyReminder,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: _editingPlan.campaignPlan.hotWorkSafetyReminder,
          decoration: const InputDecoration(labelText: 'มาตรการความปลอดภัยงานประกายไฟและความร้อน (Hot Work / PTW)', border: OutlineInputBorder()),
          onChanged: (val) {
            _editingPlan = _editingPlan.copyWith(
              campaignPlan: CampaignSubPlan(
                activities: _editingPlan.campaignPlan.activities,
                smokingControlPolicy: _editingPlan.campaignPlan.smokingControlPolicy,
                hotWorkSafetyReminder: val,
              ),
            );
          },
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 5: SUPPRESSION PLAN
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildStep5Suppression() {
    final currentTeam = _isRegularShift
        ? _editingPlan.suppressionPlan.regularShiftTeam
        : _editingPlan.suppressionPlan.offHoursTeam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: _editingPlan.suppressionPlan.initialResponseProtocol,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'ขั้นตอนการปฏิบัติเมื่อพบเหตุขั้นต้น (ระยะ ๑ นาทีแรก)', border: OutlineInputBorder()),
          onChanged: (val) {
            _editingPlan = _editingPlan.copyWith(
              suppressionPlan: SuppressionSubPlan(
                initialResponseProtocol: val,
                majorEmergencyProtocol: _editingPlan.suppressionPlan.majorEmergencyProtocol,
                regularShiftTeam: _editingPlan.suppressionPlan.regularShiftTeam,
                offHoursTeam: _editingPlan.suppressionPlan.offHoursTeam,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: _editingPlan.suppressionPlan.majorEmergencyProtocol,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'ขั้นตอนการปฏิบัติเมื่อเกิดเหตุขั้นรุนแรง (Major Emergency)', border: OutlineInputBorder()),
          onChanged: (val) {
            _editingPlan = _editingPlan.copyWith(
              suppressionPlan: SuppressionSubPlan(
                initialResponseProtocol: _editingPlan.suppressionPlan.initialResponseProtocol,
                majorEmergencyProtocol: val,
                regularShiftTeam: _editingPlan.suppressionPlan.regularShiftTeam,
                offHoursTeam: _editingPlan.suppressionPlan.offHoursTeam,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Shift Toggle
        Row(
          children: [
            ChoiceChip(
              label: Text('กะปฏิบัติงานปกติ (${_editingPlan.suppressionPlan.regularShiftTeam.length})'),
              selected: _isRegularShift,
              onSelected: (val) => setState(() => _isRegularShift = true),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text('นอกเวลาทำงาน/วันหยุด (${_editingPlan.suppressionPlan.offHoursTeam.length})'),
              selected: !_isRegularShift,
              onSelected: (val) => setState(() => _isRegularShift = false),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ตำแหน่งในทีมระงับเหตุ (${currentTeam.length} ตำแหน่ง):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ElevatedButton.icon(
              onPressed: () => _showSuppressionRoleDialog(isRegular: _isRegularShift),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('เพิ่มตำแหน่งทีม'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (currentTeam.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Text('ยังไม่มีการกำหนดตำแหน่งทีม กดปุ่ม "+ เพิ่มตำแหน่งทีม"', style: TextStyle(color: Colors.grey)),
          )
        else
          ...currentTeam.asMap().entries.map((entry) {
            final idx = entry.key;
            final t = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.roleTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('ผู้รับผิดชอบ: ${t.assignedPerson}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(t.contactNumber, style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(t.keyDuties, style: const TextStyle(fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                    onPressed: () => _showSuppressionRoleDialog(isRegular: _isRegularShift, existingRole: t, index: idx),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        final current = _isRegularShift
                            ? (List<EmergencyTeamRole>.from(_editingPlan.suppressionPlan.regularShiftTeam)..removeAt(idx))
                            : (List<EmergencyTeamRole>.from(_editingPlan.suppressionPlan.offHoursTeam)..removeAt(idx));

                        _editingPlan = _editingPlan.copyWith(
                          suppressionPlan: SuppressionSubPlan(
                            initialResponseProtocol: _editingPlan.suppressionPlan.initialResponseProtocol,
                            majorEmergencyProtocol: _editingPlan.suppressionPlan.majorEmergencyProtocol,
                            regularShiftTeam: _isRegularShift ? current : _editingPlan.suppressionPlan.regularShiftTeam,
                            offHoursTeam: _isRegularShift ? _editingPlan.suppressionPlan.offHoursTeam : current,
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 6: EVACUATION PLAN (Multi-Team with full member list!)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildStep6Evacuation() {
    final teams = _editingPlan.evacuationPlan.evacuationTeams;
    final points = _editingPlan.evacuationPlan.assemblyPoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: _editingPlan.evacuationPlan.alarmSoundSignal,
          decoration: const InputDecoration(labelText: 'ลักษณะสัญญาณเตือนภัยอพยพ', border: OutlineInputBorder()),
          onChanged: (val) {
            _editingPlan = _editingPlan.copyWith(
              evacuationPlan: _editingPlan.evacuationPlan.copyWith(alarmSoundSignal: val),
            );
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: _editingPlan.evacuationPlan.headcountMethod,
          decoration: const InputDecoration(labelText: 'วิธีการตรวจเช็คยอดพนักงาน ณ จุดรวมพล', border: OutlineInputBorder()),
          onChanged: (val) {
            _editingPlan = _editingPlan.copyWith(
              evacuationPlan: _editingPlan.evacuationPlan.copyWith(headcountMethod: val),
            );
          },
        ),
        const SizedBox(height: 20),

        // ── SECTION: EVACUATION TEAMS (หลายทีม + รายชื่อสมาชิก) ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('โครงสร้างทีมอพยพและผู้นำทางหนีไฟ (${teams.length} ทีม):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                Text('กำหนดทีมผู้นำทางหนีไฟแยกตามอาคาร/ชั้น/โซน พร้อมระบุรายชื่อสมาชิกทุกคนในทีม', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showEvacuationTeamDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('เพิ่มทีมอพยพ'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (teams.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                const Icon(Icons.groups_outlined, size: 36, color: Colors.grey),
                const SizedBox(height: 8),
                const Text('ยังไม่ได้กำหนดทีมอพยพ (สามารถกด "+ เพิ่มทีมอพยพ" เพื่อสร้างทีมและใส่รายชื่อพนักงานได้)', style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        else
          ...teams.asMap().entries.map((entry) {
            final idx = entry.key;
            final t = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.directions_run, color: Color(0xFF059669), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(t.teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                      ),
                      if (t.areaFloor.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Text(t.areaFloor, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade800)),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                        onPressed: () => _showEvacuationTeamDialog(existingTeam: t, index: idx),
                        tooltip: 'แก้ไขข้อมูลทีม',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            final current = List<EvacuationTeam>.from(teams)..removeAt(idx);
                            _editingPlan = _editingPlan.copyWith(
                              evacuationPlan: _editingPlan.evacuationPlan.copyWith(evacuationTeams: current),
                            );
                          });
                        },
                        tooltip: 'ลบทีม',
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  // Leaders
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Text('หัวหน้าทีม: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      Text(t.leaderName.isNotEmpty ? t.leaderName : '-', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 16),
                      const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text('รองหัวหน้า: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      Text(t.deputyLeaderName.isNotEmpty ? t.deputyLeaderName : '-', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Members List (ใส่รายชื่อได้หลายคน)
                  Text('รายชื่อสมาชิกในทีม (${t.members.length} คน):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                  const SizedBox(height: 4),
                  if (t.members.isEmpty)
                    Text('- ยังไม่ได้ระบุรายชื่อสมาชิก -', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic))
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: t.members.map((m) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.badge_outlined, size: 12, color: Color(0xFF475569)),
                              const SizedBox(width: 4),
                              Text(m, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 8),
                  // Destination & Duties
                  if (t.assignedAssemblyPoint.isNotEmpty || t.duties.isNotEmpty)
                    Row(
                      children: [
                        if (t.assignedAssemblyPoint.isNotEmpty) ...[
                          const Icon(Icons.flag, size: 14, color: Color(0xFF059669)),
                          const SizedBox(width: 4),
                          Text('เป้าหมาย: ${t.assignedAssemblyPoint}', style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                        ],
                        if (t.duties.isNotEmpty)
                          Expanded(
                            child: Text('หน้าที่: ${t.duties}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                    ),
                ],
              ),
            );
          }),

        const SizedBox(height: 16),

        // ── SECTION: ASSEMBLY POINTS ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('จุดรวมพล (Assembly Points) (${points.length} จุด):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            OutlinedButton.icon(
              onPressed: () => _showAssemblyPointDialog(),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('เพิ่มจุดรวมพล'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (points.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Text('ยังไม่ได้กำหนดจุดรวมพล กดปุ่ม "+ เพิ่มจุดรวมพล"', style: TextStyle(color: Colors.grey)),
          )
        else
          ...points.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag, size: 20, color: Color(0xFF059669)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.pointName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('${p.location} | แผนก: ${p.assignedDepartments} (ความจุ ${p.capacity} คน)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                    onPressed: () => _showAssemblyPointDialog(existingPoint: p, index: idx),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        final current = List<AssemblyPointItem>.from(points)..removeAt(idx);
                        _editingPlan = _editingPlan.copyWith(
                          evacuationPlan: _editingPlan.evacuationPlan.copyWith(assemblyPoints: current),
                        );
                      });
                    },
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STEP 7: RELIEF & RECOVERY PLAN
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildStep7Relief() {
    final contacts = _editingPlan.reliefPlan.governmentContacts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('รายชื่อและหมายเลขโทรศัพท์ติดต่อหน่วยงานฉุกเฉินภายนอก:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ElevatedButton.icon(
              onPressed: () => _showGovernmentContactDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('เพิ่มหน่วยงาน'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (contacts.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Text('ยังไม่มีข้อมูลหน่วยงานฉุกเฉินภายนอก', style: TextStyle(color: Colors.grey)),
          )
        else
          ...contacts.asMap().entries.map((entry) {
            final idx = entry.key;
            final c = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_in_talk, size: 18, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.agencyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        if (c.contactPerson.isNotEmpty)
                          Text('ผู้ประสานงาน: ${c.contactPerson}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Text(c.phoneNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB))),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                    onPressed: () => _showGovernmentContactDialog(existingContact: c, index: idx),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        final current = List<EmergencyContactAgency>.from(contacts)..removeAt(idx);
                        _editingPlan = _editingPlan.copyWith(
                          reliefPlan: ReliefSubPlan(
                            governmentContacts: current,
                            searchAndRescueProtocol: _editingPlan.reliefPlan.searchAndRescueProtocol,
                            damageAssessmentProtocol: _editingPlan.reliefPlan.damageAssessmentProtocol,
                            businessContinuityProtocol: _editingPlan.reliefPlan.businessContinuityProtocol,
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: _editingPlan.reliefPlan.searchAndRescueProtocol,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'ขั้นตอนการค้นหาและกู้ภัยหลังเหตุสงบ (Search & Rescue)', border: OutlineInputBorder()),
          onChanged: (val) {
            _editingPlan = _editingPlan.copyWith(
              reliefPlan: ReliefSubPlan(
                governmentContacts: _editingPlan.reliefPlan.governmentContacts,
                searchAndRescueProtocol: val,
                damageAssessmentProtocol: _editingPlan.reliefPlan.damageAssessmentProtocol,
                businessContinuityProtocol: _editingPlan.reliefPlan.businessContinuityProtocol,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: _editingPlan.reliefPlan.damageAssessmentProtocol,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'ขั้นตอนการประเมินความเสียหายก่อนเปิดใช้อาคาร', border: OutlineInputBorder()),
          onChanged: (val) {
            _editingPlan = _editingPlan.copyWith(
              reliefPlan: ReliefSubPlan(
                governmentContacts: _editingPlan.reliefPlan.governmentContacts,
                searchAndRescueProtocol: _editingPlan.reliefPlan.searchAndRescueProtocol,
                damageAssessmentProtocol: val,
                businessContinuityProtocol: _editingPlan.reliefPlan.businessContinuityProtocol,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: _editingPlan.reliefPlan.businessContinuityProtocol,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'แผนการดำเนินธุรกิจอย่างต่อเนื่อง (Business Continuity Plan - BCP)', border: OutlineInputBorder()),
          onChanged: (val) {
            _editingPlan = _editingPlan.copyWith(
              reliefPlan: ReliefSubPlan(
                governmentContacts: _editingPlan.reliefPlan.governmentContacts,
                searchAndRescueProtocol: _editingPlan.reliefPlan.searchAndRescueProtocol,
                damageAssessmentProtocol: _editingPlan.reliefPlan.damageAssessmentProtocol,
                businessContinuityProtocol: val,
              ),
            );
          },
        ),
      ],
    );
  }
}
