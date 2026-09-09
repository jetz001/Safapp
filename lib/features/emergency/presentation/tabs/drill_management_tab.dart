import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/enums/hazard_type.dart';
import '../../domain/enums/emergency_enums.dart';
import '../../data/models/drill_session_model.dart';
import '../../domain/services/emergency_evaluator.dart';
import '../../services/spr4_pdf_exporter.dart';
import '../../services/emergency_excel_exporter.dart';
import '../notifiers/emergency_providers.dart';

class DrillManagementTab extends ConsumerStatefulWidget {
  const DrillManagementTab({super.key});

  @override
  ConsumerState<DrillManagementTab> createState() => _DrillManagementTabState();
}

class _DrillManagementTabState extends ConsumerState<DrillManagementTab> {
  void _openDrillDialog({DrillSessionModel? existingDrill}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DrillFormDialog(existingDrill: existingDrill),
    );
  }

  Future<void> _openVendorReport(String filePath) async {
    if (!File(filePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบไฟล์เอกสารในระบบ (ไฟล์อาจถูกย้ายหรือลบ)'), backgroundColor: Colors.orange),
      );
      return;
    }
    try {
      if (Platform.isWindows) {
        await Process.run('cmd.exe', ['/c', 'start', '', filePath]);
      } else {
        await Process.run('open', [filePath]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเปิดไฟล์ได้: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportSpr4(DrillSessionModel drill) async {
    try {
      final activePlan = await ref.read(emergencyRepositoryProvider).getActivePlan(drill.hazardType);
      final exporter = Spr4PdfExporter();
      final path = await exporter.savePdf(drill: drill, plan: activePlan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('สร้างแบบรายงาน สปร. ๔ PDF สำเร็จ:\n$path'),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้าง สปร. ๔: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportExcel(List<DrillSessionModel> drills) async {
    try {
      await EmergencyExcelExporter.exportDrillHistory(drills, context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งออก Excel: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final drillsAsync = ref.watch(drillSessionListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'การฝึกซ้อมและรายงานผล (บันทึก สปร. ๔ & แนบรายงานเอกชน)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'บันทึกสถิติการฝึกซ้อม แนบเล่มรายงานที่หน่วยงานภายนอกออกให้ และติดตามกำหนดส่ง สปร. ๔ ภายใน ๓๐ วัน',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        final drills = drillsAsync.value ?? [];
                        if (drills.isNotEmpty) _exportExcel(drills);
                      },
                      icon: const Icon(Icons.table_view_outlined, size: 16),
                      label: const Text('ส่งออกประวัติ Excel'),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF059669)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openDrillDialog(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('บันทึก/แนบรายงานการฝึกซ้อม'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Drill Records List ──
          drillsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (drills) {
              if (drills.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('ยังไม่มีบันทึกการฝึกซ้อมในระบบ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('กดปุ่ม "บันทึก/แนบรายงานการฝึกซ้อม" เพื่อบันทึกประวัติ หรือแนบเล่มรายงาน PDF จากบริษัทเอกชน', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _openDrillDialog(),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                        child: const Text('บันทึกการฝึกซ้อมครั้งแรก'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: drills.map((d) => _buildDrillCard(d)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrillCard(DrillSessionModel drill) {
    final compliance = EmergencyEvaluator.evaluateDrillCompliance(drill);
    final rate = drill.participationRatePercent > 0
        ? drill.participationRatePercent
        : (drill.totalWorkersOnSite > 0 ? (drill.participatedCount / drill.totalWorkersOnSite) * 100.0 : 100.0);
    final hasVendorReport = drill.vendorReportPath != null && drill.vendorReportPath!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: compliance.isOverdue ? Colors.red.shade300 : Colors.grey.shade200,
          width: compliance.isOverdue ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Responsive)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: drill.hazardType.color.withValues(alpha: 0.12),
                    child: Icon(drill.hazardType.icon, size: 18, color: drill.hazardType.color),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(drill.drillTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('วันที่ ${drill.drillDate} (${drill.startTime} - ${drill.endTime} น.) | ปี พ.ศ./ค.ศ. ${drill.drillYear}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: drill.spr4SubmissionStatus.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      drill.spr4SubmissionStatus.label,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: drill.spr4SubmissionStatus.color),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'SUBMIT') {
                        final updated = drill.copyWith(
                          spr4SubmissionStatus: Spr4SubmissionStatus.submitted,
                          submittedDate: DateTime.now().toIso8601String().substring(0, 10),
                        );
                        await ref.read(drillSessionListProvider.notifier).saveDrill(updated);
                      } else if (action == 'EDIT') {
                        _openDrillDialog(existingDrill: drill);
                      } else if (action == 'DELETE') {
                        if (drill.id != null) {
                          await ref.read(drillSessionListProvider.notifier).deleteDrill(drill.id!);
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (drill.spr4SubmissionStatus != Spr4SubmissionStatus.submitted)
                        const PopupMenuItem(value: 'SUBMIT', child: Text('บันทึกว่ายื่น สปร. ๔ แล้ว')),
                      const PopupMenuItem(value: 'EDIT', child: Text('แก้ไขข้อมูลการซ้อม')),
                      const PopupMenuItem(value: 'DELETE', child: Text('ลบรายการนี้', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Attached Vendor Report Banner (If available)
          if (hasVendorReport) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Color(0xFF059669), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'เล่มรายงานจากเอกชน: ${drill.vendorReportPath!.split(RegExp(r'[\\/]')).last}',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openVendorReport(drill.vendorReportPath!),
                    icon: const Icon(Icons.open_in_new, size: 14, color: Color(0xFF059669)),
                    label: const Text('เปิดดูเล่มรายงาน', style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Key Stats Row (Responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth > 650
                  ? (constraints.maxWidth - (10 * 3) - 24) / 4
                  : (constraints.maxWidth - 10 - 24) / 2;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(width: itemWidth, child: _drillStat('ผู้เข้าร่วม', '${drill.participatedCount} / ${drill.totalWorkersOnSite} คน', 'อัตราเข้าร่วม ${rate.toStringAsFixed(1)}%')),
                    SizedBox(width: itemWidth, child: _drillStat('เวลาดับเพลิงขั้นต้น', '${drill.initialAttackTimeSec} วินาที', 'สกัดเพลิงระยะแรก')),
                    SizedBox(width: itemWidth, child: _drillStat('เวลาอพยพทั้งหมด', '${drill.evacuationTimeSec} วินาที', 'ถึงจุดรวมพล')),
                    SizedBox(width: itemWidth, child: _drillStat('การนับยอดพนักงาน', drill.headcountStatus.label, 'เจ็บจำลอง: ${drill.simulatedInjuriesCount} คน')),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // Scenario & Organizer Info
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'ผู้จัด: ${drill.organizerType.label} (${drill.organizerName.isNotEmpty ? drill.organizerName : "หน่วยงานภายนอก"})',
                style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
              ),
              Text(
                'กำหนดส่ง สปร. ๔: ${drill.submissionDeadline} (${compliance.daysRemainingToSubmitSpr4 >= 0 ? "เหลือ ${compliance.daysRemainingToSubmitSpr4} วัน" : "เกิน ${compliance.daysRemainingToSubmitSpr4.abs()} วัน"})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: compliance.isOverdue ? Colors.red : Colors.grey.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openDrillDialog(existingDrill: drill),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('แก้ไข/แนบไฟล์เพิ่ม'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
              ElevatedButton.icon(
                onPressed: () => _exportSpr4(drill),
                icon: const Icon(Icons.print_outlined, size: 14),
                label: const Text('แบบ สปร. ๔ (PDF)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _drillStat(String label, String value, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
        Text(sub, style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

/// Dialog สำหรับบันทึก/แก้ไขข้อมูลการฝึกซ้อม พร้อมตัวแนบไฟล์รายงานจากเอกชน
class _DrillFormDialog extends ConsumerStatefulWidget {
  final DrillSessionModel? existingDrill;

  const _DrillFormDialog({this.existingDrill});

  @override
  ConsumerState<_DrillFormDialog> createState() => _DrillFormDialogState();
}

class _DrillFormDialogState extends ConsumerState<_DrillFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _startTimeCtrl;
  late TextEditingController _endTimeCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _organizerNameCtrl;
  late TextEditingController _approvalNoCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _sourceCtrl;
  late TextEditingController _scenarioCtrl;
  late TextEditingController _totalWorkersCtrl;
  late TextEditingController _participatedCtrl;
  late TextEditingController _maleCtrl;
  late TextEditingController _femaleCtrl;
  late TextEditingController _attackTimeCtrl;
  late TextEditingController _evacTimeCtrl;
  late TextEditingController _problemsCtrl;
  late TextEditingController _actionsCtrl;
  late TextEditingController _evaluatorNameCtrl;
  late TextEditingController _evaluatorPosCtrl;

  String? _pickedVendorReportPath;
  HazardType _hazardType = HazardType.fire;
  DrillOrganizerType _organizerType = DrillOrganizerType.certifiedTrainingBody;
  HeadcountStatus _headcountStatus = HeadcountStatus.allAccounted;
  Spr4SubmissionStatus _submissionStatus = Spr4SubmissionStatus.pending;

  @override
  void initState() {
    super.initState();
    final d = widget.existingDrill;
    final now = DateTime.now();
    final todayStr = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    _titleCtrl = TextEditingController(text: d?.drillTitle ?? 'การฝึกซ้อมดับเพลิงและฝึกซ้อมอพยพหนีไฟประจำปี');
    _dateCtrl = TextEditingController(text: d?.drillDate ?? todayStr);
    _startTimeCtrl = TextEditingController(text: d?.startTime ?? '09:00');
    _endTimeCtrl = TextEditingController(text: d?.endTime ?? '11:30');
    _yearCtrl = TextEditingController(text: (d?.drillYear ?? now.year).toString());
    _organizerNameCtrl = TextEditingController(text: d?.organizerName ?? 'บริษัท ฝึกอบรมดับเพลิงและกู้ภัย จำกัด');
    _approvalNoCtrl = TextEditingController(text: d?.approvalCertNo ?? 'รง.0504/ว.1234');
    _locationCtrl = TextEditingController(text: d?.incidentLocation ?? 'อาคารฝ่ายผลิตและลานกิจกรรม');
    _sourceCtrl = TextEditingController(text: d?.fireOrHazardSource ?? 'ไฟฟ้าลัดวงจรตู้สวิตช์บอร์ด');
    _scenarioCtrl = TextEditingController(text: d?.scenarioDescription ?? 'จำลองเกิดเพลิงไหม้ขั้นต้น ณ อาคารผลิต ทีมดับเพลิงขั้นต้นเข้าฉีดสกัดแต่ไม่สำเร็จ ผู้อำนวยการสั่งใช้แผนอพยพและประสานรถดับเพลิงเทศบาล');
    _totalWorkersCtrl = TextEditingController(text: (d?.totalWorkersOnSite ?? 100).toString());
    _participatedCtrl = TextEditingController(text: (d?.participatedCount ?? 98).toString());
    _maleCtrl = TextEditingController(text: (d?.maleParticipants ?? 58).toString());
    _femaleCtrl = TextEditingController(text: (d?.femaleParticipants ?? 40).toString());
    _attackTimeCtrl = TextEditingController(text: (d?.initialAttackTimeSec ?? 45).toString());
    _evacTimeCtrl = TextEditingController(text: (d?.evacuationTimeSec ?? 180).toString());
    _problemsCtrl = TextEditingController(text: d?.problemsAndObstacles ?? 'ไม่มีปัญหาอุปสรรคสำคัญ พนักงานปฏิบัติตามแผนเป็นอย่างดี');
    _actionsCtrl = TextEditingController(text: d?.improvementActions ?? 'ทบทวนผู้นำทางหนีไฟและซักซ้อมจุดรวมพลอย่างสม่ำเสมอ');
    _evaluatorNameCtrl = TextEditingController(text: d?.evaluatorName ?? 'นายวิชาญ รักปลอดภัย');
    _evaluatorPosCtrl = TextEditingController(text: d?.evaluatorPosition ?? 'เจ้าหน้าที่ความปลอดภัยในการทำงานระดับวิชาชีพ');

    if (d != null) {
      _hazardType = d.hazardType;
      _organizerType = d.organizerType;
      _headcountStatus = d.headcountStatus;
      _submissionStatus = d.spr4SubmissionStatus;
      _pickedVendorReportPath = d.vendorReportPath;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _dateCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    _yearCtrl.dispose();
    _organizerNameCtrl.dispose();
    _approvalNoCtrl.dispose();
    _locationCtrl.dispose();
    _sourceCtrl.dispose();
    _scenarioCtrl.dispose();
    _totalWorkersCtrl.dispose();
    _participatedCtrl.dispose();
    _maleCtrl.dispose();
    _femaleCtrl.dispose();
    _attackTimeCtrl.dispose();
    _evacTimeCtrl.dispose();
    _problemsCtrl.dispose();
    _actionsCtrl.dispose();
    _evaluatorNameCtrl.dispose();
    _evaluatorPosCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVendorFile() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xlsx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        setState(() {
          _pickedVendorReportPath = result.files.first.path;
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final total = int.tryParse(_totalWorkersCtrl.text) ?? 0;
    final part = int.tryParse(_participatedCtrl.text) ?? 0;
    final rate = total > 0 ? (part / total) * 100.0 : 100.0;
    final deadline = DrillSessionModel.calculateDeadline(_dateCtrl.text);

    final drill = DrillSessionModel(
      id: widget.existingDrill?.id,
      hazardType: _hazardType,
      drillTitle: _titleCtrl.text,
      drillDate: _dateCtrl.text,
      startTime: _startTimeCtrl.text,
      endTime: _endTimeCtrl.text,
      drillYear: int.tryParse(_yearCtrl.text) ?? DateTime.now().year,
      organizerType: _organizerType,
      organizerName: _organizerNameCtrl.text,
      approvalCertNo: _approvalNoCtrl.text,
      incidentLocation: _locationCtrl.text,
      fireOrHazardSource: _sourceCtrl.text,
      scenarioDescription: _scenarioCtrl.text,
      totalWorkersOnSite: total,
      participatedCount: part,
      maleParticipants: int.tryParse(_maleCtrl.text) ?? 0,
      femaleParticipants: int.tryParse(_femaleCtrl.text) ?? 0,
      participationRatePercent: rate,
      initialAttackTimeSec: int.tryParse(_attackTimeCtrl.text) ?? 0,
      evacuationTimeSec: int.tryParse(_evacTimeCtrl.text) ?? 0,
      headcountStatus: _headcountStatus,
      problemsAndObstacles: _problemsCtrl.text,
      improvementActions: _actionsCtrl.text,
      evaluatorName: _evaluatorNameCtrl.text,
      evaluatorPosition: _evaluatorPosCtrl.text,
      spr4SubmissionStatus: _submissionStatus,
      submissionDeadline: deadline,
      vendorReportPath: _pickedVendorReportPath,
    );

    await ref.read(drillSessionListProvider.notifier).saveDrill(drill);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 760,
        height: 680,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('บันทึกผลการฝึกซ้อมและแนบเล่มรายงานเอกชน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Vendor Report Attachment Section (Highlighted) ──
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.attach_file, color: Color(0xFF2563EB), size: 20),
                                    SizedBox(width: 8),
                                    Text('แนบเล่มรายงานฝึกซ้อมจากเอกชน (Vendor Report File)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: _pickVendorFile,
                                  icon: const Icon(Icons.upload_file, size: 16),
                                  label: const Text('เลือกไฟล์ PDF/เอกสาร'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'กรณีจ้างหน่วยงานฝึกอบรมภายนอกจัดซ้อม สามารถแนบไฟล์เล่มรายงานและใบรับรองที่ได้รับไว้ในระบบเพื่อเป็นหลักฐานได้โดยตรง',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            if (_pickedVendorReportPath != null && _pickedVendorReportPath!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF6EE7B7)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, size: 16, color: Color(0xFF059669)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _pickedVendorReportPath!,
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF065F46), fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                      onPressed: () => setState(() => _pickedVendorReportPath = null),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'หัวข้อการฝึกซ้อม', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _dateCtrl, decoration: const InputDecoration(labelText: 'วันที่ทำการซ้อม (YYYY-MM-DD)', border: OutlineInputBorder()))),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _startTimeCtrl, decoration: const InputDecoration(labelText: 'เวลาเริ่ม (น.)', border: OutlineInputBorder()))),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _endTimeCtrl, decoration: const InputDecoration(labelText: 'เวลาสิ้นสุด (น.)', border: OutlineInputBorder()))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<HazardType>(
                              initialValue: _hazardType,
                              decoration: const InputDecoration(labelText: 'ประเภทภัย', border: OutlineInputBorder()),
                              items: HazardType.values.map((h) => DropdownMenuItem(value: h, child: Text(h.shortTitle))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _hazardType = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<DrillOrganizerType>(
                              initialValue: _organizerType,
                              decoration: const InputDecoration(labelText: 'ผู้ดำเนินการฝึกซ้อม', border: OutlineInputBorder()),
                              items: DrillOrganizerType.values.map((o) => DropdownMenuItem(value: o, child: Text(o.code == 'SELF_APPROVED' ? 'นายจ้างจัดซ้อมเอง' : 'หน่วยงานขึ้นทะเบียน'))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _organizerType = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _organizerNameCtrl, decoration: const InputDecoration(labelText: 'ชื่อหน่วยงานผู้จัดฝึกซ้อม (เอกชน/วิทยากร)', border: OutlineInputBorder()))),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _approvalNoCtrl, decoration: const InputDecoration(labelText: 'เลขทะเบียนหน่วยงาน / หนังสือเห็นชอบ', border: OutlineInputBorder()))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _totalWorkersCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ลูกจ้างทั้งหมด (คน)', border: OutlineInputBorder()))),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _participatedCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ผู้ร่วมซ้อม (คน)', border: OutlineInputBorder()))),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _maleCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ชาย (คน)', border: OutlineInputBorder()))),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _femaleCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'หญิง (คน)', border: OutlineInputBorder()))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _attackTimeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'เวลาดับเพลิงขั้นต้น (วินาที)', border: OutlineInputBorder()))),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _evacTimeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'เวลาอพยพถึงจุดรวมพล (วินาที)', border: OutlineInputBorder()))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<HeadcountStatus>(
                              initialValue: _headcountStatus,
                              decoration: const InputDecoration(labelText: 'การตรวจนับยอด', border: OutlineInputBorder()),
                              items: HeadcountStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label, style: const TextStyle(fontSize: 11)))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _headcountStatus = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(controller: _scenarioCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'การจำลองสถานการณ์และจุดเกิดเหตุ', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextFormField(controller: _problemsCtrl, decoration: const InputDecoration(labelText: 'ปัญหาและอุปสรรคที่พบ', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextFormField(controller: _actionsCtrl, decoration: const InputDecoration(labelText: 'แนวทางแก้ไขและข้อเสนอแนะ', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _evaluatorNameCtrl, decoration: const InputDecoration(labelText: 'ชื่อผู้ประเมินผล (จป.วิชาชีพ)', border: OutlineInputBorder()))),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _evaluatorPosCtrl, decoration: const InputDecoration(labelText: 'ตำแหน่ง', border: OutlineInputBorder()))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ยกเลิก')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                    child: const Text('บันทึกข้อมูลการฝึกซ้อม'),
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
