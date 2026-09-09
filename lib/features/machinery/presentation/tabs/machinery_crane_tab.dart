import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../data/models/crane_inspection_model.dart';
import '../notifiers/machinery_providers.dart';

class MachineryCraneTab extends ConsumerStatefulWidget {
  const MachineryCraneTab({super.key});

  @override
  ConsumerState<MachineryCraneTab> createState() => _MachineryCraneTabState();
}

class _MachineryCraneTabState extends ConsumerState<MachineryCraneTab> {
  Future<void> _openFile(String? filePath) async {
    if (filePath == null || filePath.trim().isEmpty) return;
    final file = File(filePath);
    if (!file.existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบไฟล์เอกสารในเครื่อง (ไฟล์อาจถูกย้ายหรือลบ)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
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

  void _showAddEditCraneDialog([CraneInspectionModel? existing]) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.craneName ?? '');
    final tagCtrl = TextEditingController(text: existing?.craneTag ?? '');
    final bldCtrl = TextEditingController(text: existing?.locationBuilding ?? '');
    final areaCtrl = TextEditingController(text: existing?.locationArea ?? '');
    final swlCtrl = TextEditingController(text: existing?.safeWorkingLoadTon.toString() ?? '5.0');
    final testWeightCtrl = TextEditingController(text: existing?.testWeightTon?.toString() ?? '6.25');
    final loadPercentCtrl = TextEditingController(text: existing?.loadTestPercent?.toString() ?? '125.0');
    final engNameCtrl = TextEditingController(text: existing?.engineerName ?? '');
    final engLicCtrl = TextEditingController(text: existing?.engineerLicenseNo ?? '');
    final contractorCtrl = TextEditingController(text: existing?.contractorCompany ?? '');
    final defectsCtrl = TextEditingController(text: existing?.defectsFound ?? '');
    final actionsCtrl = TextEditingController(text: existing?.correctiveActions ?? '');

    String craneType = existing?.craneType ?? 'OVERHEAD';
    String inspectionForm = existing?.inspectionForm ?? 'PJ1';
    int cycleMonths = existing?.inspectionCycleMonths ?? 6;
    String wireRope = existing?.wireRopeStatus ?? 'PASS';
    String hookLatch = existing?.hookLatchStatus ?? 'PASS';
    String limitSwitch = existing?.limitSwitchStatus ?? 'PASS';
    String brakeSystem = existing?.brakeSystemStatus ?? 'PASS';
    String structure = existing?.structureStatus ?? 'PASS';
    String overallResult = existing?.overallResult ?? 'PASS';

    DateTime inspDate = existing?.inspectionDate ?? DateTime.now();
    DateTime expDate = existing?.expiryDate ?? DateTime(inspDate.year, inspDate.month + cycleMonths, inspDate.day);

    String? vendorPdf = existing?.vendorReportPdfPath;
    String? loadCertPdf = existing?.loadTestCertPdfPath;
    String? engLicPdf = existing?.engineerLicensePdfPath;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDlgState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.precision_manufacturing, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Text(existing == null ? 'บันทึกผลการตรวจปั้นจั่น (ปจ.๑ / ปจ.๒)' : 'แก้ไขผลการตรวจปั้นจั่น'),
            ],
          ),
          content: SizedBox(
            width: 760,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: inspectionForm,
                            decoration: const InputDecoration(labelText: 'แบบรายงานราชการ *', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'PJ1', child: Text('แบบ ปจ.๑ (ปั้นจั่นอยู่กับที่ / เหนือศีรษะ)')),
                              DropdownMenuItem(value: 'PJ2', child: Text('แบบ ปจ.๒ (ปั้นจั่นเคลื่อนที่ / รถเครน)')),
                            ],
                            onChanged: (v) {
                              if (v != null) setDlgState(() => inspectionForm = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: craneType,
                            decoration: const InputDecoration(labelText: 'ชนิดปั้นจั่น *', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'OVERHEAD', child: Text('ปั้นจั่นเหนือศีรษะ (Overhead Crane)')),
                              DropdownMenuItem(value: 'GANTRY', child: Text('ปั้นจั่นขาสูง (Gantry Crane)')),
                              DropdownMenuItem(value: 'JIB', child: Text('ปั้นจั่นแบบหมุน / รอก (Jib / Hoist)')),
                              DropdownMenuItem(value: 'TOWER', child: Text('ปั้นจั่นหอสูง (Tower Crane)')),
                              DropdownMenuItem(value: 'MOBILE', child: Text('ปั้นจั่นเคลื่อนที่ / รถเครน (Mobile Crane)')),
                            ],
                            onChanged: (v) {
                              if (v != null) setDlgState(() => craneType = v);
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
                            controller: tagCtrl,
                            decoration: const InputDecoration(labelText: 'รหัสปั้นจั่น (Crane Tag) *', hintText: 'e.g. CRANE-01-OH', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกรหัสปั้นจั่น' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(labelText: 'ชื่ออุปกรณ์ / รายละเอียด *', hintText: 'e.g. ปั้นจั่นเหนือศีรษะ 5 ตัน อาคารผลิต 1', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อปั้นจั่น' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: bldCtrl,
                            decoration: const InputDecoration(labelText: 'อาคาร / โรงงาน *', hintText: 'e.g. อาคารผลิต 1', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุอาคาร' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: areaCtrl,
                            decoration: const InputDecoration(labelText: 'พื้นที่ / โซน (Location Area)', hintText: 'e.g. Bay 1 โซนประกอบ', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: swlCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'พิกัดยกปลอดภัย (SWL) *', suffixText: 'ตัน (Ton)', border: OutlineInputBorder()),
                            validator: (v) => v == null || double.tryParse(v) == null ? 'กรอกตัวเลขตัน' : null,
                            onChanged: (v) {
                              final swl = double.tryParse(v) ?? 0;
                              final testW = swl * 1.25;
                              testWeightCtrl.text = testW.toStringAsFixed(2);
                              loadPercentCtrl.text = '125.0';
                              int autoCycle = 12;
                              if (swl > 50) {
                                autoCycle = 3;
                              } else if (swl >= 3) {
                                autoCycle = 6;
                              }
                              setDlgState(() {
                                cycleMonths = autoCycle;
                                expDate = DateTime(inspDate.year, inspDate.month + cycleMonths, inspDate.day);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: testWeightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'น้ำหนักที่ทดสอบ (Load Test)', suffixText: 'ตัน', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: cycleMonths,
                            decoration: const InputDecoration(labelText: 'รอบตรวจตามกฎหมาย *', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 3, child: Text('ทุก 3 เดือน (> 50 ตัน)')),
                              DropdownMenuItem(value: 6, child: Text('ทุก 6 เดือน (3 - 50 ตัน)')),
                              DropdownMenuItem(value: 12, child: Text('ทุก 1 ปี (1 - 3 ตัน)')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setDlgState(() {
                                  cycleMonths = v;
                                  expDate = DateTime(inspDate.year, inspDate.month + cycleMonths, inspDate.day);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('ผลการตรวจสอบส่วนประกอบสำคัญ (ตามเกณฑ์วิศวกรรม):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 10,
                        children: [
                          _buildMiniCheckDropdown('ลวดสลิง / โซ่ยก', wireRope, (v) => setDlgState(() => wireRope = v)),
                          _buildMiniCheckDropdown('ตะขอ & ปากลิ้นเซฟตี้', hookLatch, (v) => setDlgState(() => hookLatch = v)),
                          _buildMiniCheckDropdown('สวิตช์ตัดพิกัด (Limit)', limitSwitch, (v) => setDlgState(() => limitSwitch = v)),
                          _buildMiniCheckDropdown('ระบบเบรก & คลัตช์', brakeSystem, (v) => setDlgState(() => brakeSystem = v)),
                          _buildMiniCheckDropdown('โครงสร้างสะพาน & ราง', structure, (v) => setDlgState(() => structure = v)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: engNameCtrl,
                            decoration: const InputDecoration(labelText: 'วิศวกรเครื่องกลผู้รับรอง *', hintText: 'e.g. ธีรพงษ์ วิศวกรเครื่องกล', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อวิศวกร' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: engLicCtrl,
                            decoration: const InputDecoration(labelText: 'เลขที่ใบอนุญาต กว. *', hintText: 'e.g. สค. 8891 (เครื่องกล)', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกเลขที่ กว.' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contractorCtrl,
                      decoration: const InputDecoration(labelText: 'บริษัทผู้รับเหมาตรวจทดสอบ', hintText: 'e.g. บริษัท สยามเครน อินสเปคชั่น จำกัด', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text('วันที่ตรวจ: ${inspDate.toIso8601String().substring(0, 10)}'),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: inspDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setDlgState(() {
                                  inspDate = picked;
                                  expDate = DateTime(picked.year, picked.month + cycleMonths, picked.day);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event_available, size: 16),
                            label: Text('วันหมดอายุ: ${expDate.toIso8601String().substring(0, 10)}'),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: expDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) setDlgState(() => expDate = picked);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: overallResult,
                            decoration: const InputDecoration(labelText: 'สรุปผลตรวจรับรอง *', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'PASS', child: Text('ผ่านเกณฑ์ (PASS)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                              DropdownMenuItem(value: 'FAIL', child: Text('มีข้อบกพร่อง (FAIL)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                            ],
                            onChanged: (v) {
                              if (v != null) setDlgState(() => overallResult = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: defectsCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'ข้อบกพร่อง / จุดที่ต้องซ่อมบำรุง', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: actionsCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'ข้อเสนอแนะและมาตรการแก้ไข', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    const Text('แนบเอกสารหลักฐาน (PDF):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildFilePickerButton(
                          title: 'เล่มรายงาน ปจ.๑/ปจ.๒',
                          currentPath: vendorPdf,
                          onPick: () async {
                            final res = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                            if (res != null && res.files.single.path != null) {
                              setDlgState(() => vendorPdf = res.files.single.path);
                            }
                          },
                          onClear: () => setDlgState(() => vendorPdf = null),
                        ),
                        _buildFilePickerButton(
                          title: 'เอกสารรับรอง Load Test',
                          currentPath: loadCertPdf,
                          onPick: () async {
                            final res = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                            if (res != null && res.files.single.path != null) {
                              setDlgState(() => loadCertPdf = res.files.single.path);
                            }
                          },
                          onClear: () => setDlgState(() => loadCertPdf = null),
                        ),
                        _buildFilePickerButton(
                          title: 'สำเนาใบ กว. เครื่องกล',
                          currentPath: engLicPdf,
                          onPick: () async {
                            final res = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                            if (res != null && res.files.single.path != null) {
                              setDlgState(() => engLicPdf = res.files.single.path);
                            }
                          },
                          onClear: () => setDlgState(() => engLicPdf = null),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final crane = CraneInspectionModel(
                  id: existing?.id,
                  craneName: nameCtrl.text.trim(),
                  craneTag: tagCtrl.text.trim(),
                  craneType: craneType,
                  inspectionForm: inspectionForm,
                  locationBuilding: bldCtrl.text.trim(),
                  locationArea: areaCtrl.text.trim().isEmpty ? null : areaCtrl.text.trim(),
                  safeWorkingLoadTon: double.tryParse(swlCtrl.text) ?? 5.0,
                  testWeightTon: double.tryParse(testWeightCtrl.text),
                  loadTestPercent: double.tryParse(loadPercentCtrl.text),
                  inspectionCycleMonths: cycleMonths,
                  wireRopeStatus: wireRope,
                  hookLatchStatus: hookLatch,
                  limitSwitchStatus: limitSwitch,
                  brakeSystemStatus: brakeSystem,
                  structureStatus: structure,
                  engineerName: engNameCtrl.text.trim(),
                  engineerLicenseNo: engLicCtrl.text.trim(),
                  contractorCompany: contractorCtrl.text.trim().isEmpty ? null : contractorCtrl.text.trim(),
                  inspectionDate: inspDate,
                  expiryDate: expDate,
                  overallResult: overallResult,
                  defectsFound: defectsCtrl.text.trim().isEmpty ? null : defectsCtrl.text.trim(),
                  correctiveActions: actionsCtrl.text.trim().isEmpty ? null : actionsCtrl.text.trim(),
                  vendorReportPdfPath: vendorPdf,
                  loadTestCertPdfPath: loadCertPdf,
                  engineerLicensePdfPath: engLicPdf,
                  createdAt: existing?.createdAt,
                );

                await ref.read(craneInspectionListProvider.notifier).saveCrane(crane);
                if (!mounted) return;
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('บันทึกผลการตรวจปั้นจั่นสำเร็จ'), backgroundColor: Color(0xFF16A34A)),
                );
              },
              child: const Text('บันทึกข้อมูล'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCheckDropdown(String label, String value, ValueChanged<String> onChanged) {
    return SizedBox(
      width: 200,
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          DropdownButton<String>(
            value: value,
            isDense: true,
            items: const [
              DropdownMenuItem(value: 'PASS', child: Text('ปกติ', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))),
              DropdownMenuItem(value: 'FAIL', child: Text('ชำรุด', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilePickerButton({
    required String title,
    required String? currentPath,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    final hasFile = currentPath != null && currentPath.isNotEmpty;
    final filename = hasFile ? p.basename(currentPath) : 'ยังไม่แนบไฟล์';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasFile ? const Color(0xFFF0FDF4) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasFile ? Colors.green.shade300 : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasFile ? Icons.check_circle : Icons.attach_file, size: 16, color: hasFile ? Colors.green : Colors.grey),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(filename, style: TextStyle(fontSize: 10, color: hasFile ? Colors.green.shade800 : Colors.grey), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(hasFile ? Icons.close : Icons.upload_file, size: 16),
            onPressed: hasFile ? onClear : onPick,
            tooltip: hasFile ? 'ลบไฟล์' : 'เลือกไฟล์ PDF',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cranesAsync = ref.watch(craneInspectionListProvider);

    return cranesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
      data: (cranes) {
        final total = cranes.length;
        final overdue = cranes.where((c) => c.slaStatus == 'OVERDUE').length;
        final warning = cranes.where((c) => c.slaStatus == 'WARNING').length;
        final compliant = cranes.where((c) => c.slaStatus == 'COMPLIANT').length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatutoryBanner(),
            const SizedBox(height: 16),
            _buildKpiRow(total: total, compliant: compliant, warning: warning, overdue: overdue),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('รายการปั้นจั่นและประวัติการตรวจทดสอบ ($total รายการ)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('ควบคุมตามกฎกระทรวงเครื่องจักร ปั้นจั่น และหม้อน้ำ พ.ศ. ๒๕๖๔ (แบบ ปจ.๑ / ปจ.๒)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _showAddEditCraneDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('บันทึกผลตรวจ ปจ.'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (cranes.isEmpty)
              _buildEmptyState()
            else
              ...cranes.map((c) => _buildCraneCard(c)),
          ],
        );
      },
    );
  }

  Widget _buildStatutoryBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF0284C7), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.precision_manufacturing, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ข้อกำหนดทางกฎหมาย: การตรวจและทดสอบปั้นจั่นตามรอบเวลา (ปจ.๑ และ ปจ.๒)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ตามกฎกระทรวงเครื่องจักร ปั้นจั่น และหม้อน้ำ พ.ศ. ๒๕๖๔ นายจ้างต้องจัดให้มีการตรวจทดสอบปั้นจั่นโดยวิศวกรเครื่องกลที่ได้รับใบอนุญาต: มากกว่า ๕๐ ตัน ตรวจทุก ๓ เดือน | ๓ - ๕๐ ตัน ตรวจทุก ๖ เดือน | ๑ - ๓ ตัน ตรวจทุก ๑ ปี พร้อมทดสอบพิกัดยก (Load Test ๑.๒๕ เท่า) และจัดทำรายงาน แบบ ปจ.๑ (อยู่กับที่) หรือ แบบ ปจ.๒ (เคลื่อนที่)',
                  style: TextStyle(fontSize: 12, color: Color(0xFF0C4A6E), height: 1.4),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildChip('รอบตรวจ: ๓ / ๖ / ๑๒ เดือนตามพิกัด', Icons.history),
                    _buildChip('ทดสอบพิกัดยก: Load Test ๑๒๕%', Icons.scale),
                    _buildChip('แบบราชการ: แบบ ปจ.๑ & ปจ.๒', Icons.description_outlined),
                    _buildChip('ผู้รับรอง: สามัญวิศวกรเครื่องกล กว.', Icons.verified_outlined),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF0284C7)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0369A1))),
        ],
      ),
    );
  }

  Widget _buildKpiRow({required int total, required int compliant, required int warning, required int overdue}) {
    return Row(
      children: [
        _buildKpiCard('ปั้นจั่นทั้งหมด', '$total เครื่อง', Icons.precision_manufacturing, const Color(0xFF0284C7)),
        const SizedBox(width: 12),
        _buildKpiCard('ผลตรวจปกติ (Compliant)', '$compliant เครื่อง', Icons.check_circle_outline, const Color(0xFF16A34A)),
        const SizedBox(width: 12),
        _buildKpiCard('ใกล้ครบกำหนด 30 วัน', '$warning เครื่อง', Icons.warning_amber_rounded, const Color(0xFFF59E0B)),
        const SizedBox(width: 12),
        _buildKpiCard('เกินกำหนด (Overdue)', '$overdue เครื่อง', Icons.error_outline, const Color(0xFFDC2626)),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCraneCard(CraneInspectionModel crane) {
    final isPass = crane.overallResult == 'PASS';
    final isOverdue = crane.slaStatus == 'OVERDUE';
    final isWarning = crane.slaStatus == 'WARNING';

    Color slaColor = const Color(0xFF16A34A);
    String slaText = 'ยังไม่หมดอายุ (${crane.daysUntilExpiry} วัน)';
    if (isOverdue) {
      slaColor = const Color(0xFFDC2626);
      slaText = 'เกินกำหนดแล้ว (${crane.daysUntilExpiry.abs()} วัน)';
    } else if (isWarning) {
      slaColor = const Color(0xFFF59E0B);
      slaText = 'ใกล้ครบกำหนด (${crane.daysUntilExpiry} วัน)';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF0284C7).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(crane.craneTag, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7), fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text(crane.inspectionFormTh, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade700, fontSize: 11)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    crane.craneName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: slaColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: slaColor)),
                  child: Text(slaText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: slaColor)),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                  onPressed: () => _showAddEditCraneDialog(crane),
                  tooltip: 'แก้ไข',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  onPressed: () => _confirmDelete(crane),
                  tooltip: 'ลบ',
                ),
              ],
            ),
            const Divider(height: 18),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _buildInfoItem('ชนิดปั้นจั่น', crane.craneTypeTh),
                _buildInfoItem('สถานที่ติดตั้ง', '${crane.locationBuilding} ${crane.locationArea ?? ''}'),
                _buildInfoItem('พิกัดยกปลอดภัย (SWL)', '${crane.safeWorkingLoadTon} ตัน (รอบตรวจ ${crane.inspectionCycleMonths} เดือน)'),
                _buildInfoItem('ผลการทดสอบ Load Test', '${crane.testWeightTon ?? '-'} ตัน (${crane.loadTestPercent ?? '-'}%)'),
                _buildInfoItem('วิศวกรผู้รับรอง', '${crane.engineerName} (${crane.engineerLicenseNo})'),
                _buildInfoItem('บริษัทผู้ตรวจ', crane.contractorCompany ?? '-'),
                _buildInfoItem('วันที่ตรวจ', crane.inspectionDate.toIso8601String().substring(0, 10)),
                _buildInfoItem('วันหมดอายุ', crane.expiryDate.toIso8601String().substring(0, 10)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Text('ผลตรวจจุดสำคัญ: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  _buildStatusChip('สลิง/โซ่', crane.wireRopeStatus),
                  const SizedBox(width: 8),
                  _buildStatusChip('ตะขอ/ลิ้น', crane.hookLatchStatus),
                  const SizedBox(width: 8),
                  _buildStatusChip('ลิมิตสวิตช์', crane.limitSwitchStatus),
                  const SizedBox(width: 8),
                  _buildStatusChip('ระบบเบรก', crane.brakeSystemStatus),
                  const SizedBox(width: 8),
                  _buildStatusChip('โครงสร้าง', crane.structureStatus),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPass ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isPass ? Colors.green : Colors.red),
                    ),
                    child: Text(
                      crane.overallResultTh,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPass ? Colors.green.shade700 : Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildAttachmentButton('เล่มรายงาน ปจ. (PDF)', crane.vendorReportPdfPath, Icons.picture_as_pdf, const Color(0xFFDC2626)),
                _buildAttachmentButton('เอกสาร Load Test (PDF)', crane.loadTestCertPdfPath, Icons.scale, const Color(0xFF0284C7)),
                _buildAttachmentButton('ใบ กว. เครื่องกล (PDF)', crane.engineerLicensePdfPath, Icons.badge_outlined, const Color(0xFF2563EB)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String status) {
    final isOk = status == 'PASS';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isOk ? Icons.check_circle : Icons.cancel, size: 12, color: isOk ? Colors.green : Colors.red),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: isOk ? Colors.black87 : Colors.red, fontWeight: isOk ? FontWeight.normal : FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return SizedBox(
      width: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton(String title, String? filePath, IconData icon, Color color) {
    final hasFile = filePath != null && filePath.trim().isNotEmpty;
    final filename = hasFile ? p.basename(filePath) : 'ยังไม่แนบ';

    return OutlinedButton.icon(
      onPressed: hasFile ? () => _openFile(filePath) : null,
      icon: Icon(icon, size: 14, color: hasFile ? color : Colors.grey),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: hasFile ? Colors.black87 : Colors.grey)),
          if (hasFile) ...[
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text('($filename)', style: TextStyle(fontSize: 10, color: color), overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 12, color: color),
          ],
        ],
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        side: BorderSide(color: hasFile ? color.withValues(alpha: 0.4) : Colors.grey.shade300),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.precision_manufacturing_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('ยังไม่มีข้อมูลการตรวจรับรองปั้นจั่น', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 6),
          const Text('กดปุ่ม "บันทึกผลตรวจ ปจ." ด้านบน เพื่อเพิ่มรายการแรก', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(CraneInspectionModel crane) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบประวัติการตรวจปั้นจั่น ${crane.craneName} ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok == true && crane.id != null) {
      await ref.read(craneInspectionListProvider.notifier).deleteCrane(crane.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบรายการสำเร็จ')));
      }
    }
  }
}
