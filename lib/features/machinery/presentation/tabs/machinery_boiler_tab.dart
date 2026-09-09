import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../data/models/boiler_inspection_model.dart';
import '../notifiers/machinery_providers.dart';

class MachineryBoilerTab extends ConsumerStatefulWidget {
  const MachineryBoilerTab({super.key});

  @override
  ConsumerState<MachineryBoilerTab> createState() => _MachineryBoilerTabState();
}

class _MachineryBoilerTabState extends ConsumerState<MachineryBoilerTab> {
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

  void _showAddEditBoilerDialog([BoilerInspectionModel? existing]) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.boilerName ?? '');
    final tagCtrl = TextEditingController(text: existing?.boilerTag ?? '');
    final capCtrl = TextEditingController(text: existing?.capacityTonHr?.toString() ?? '2.0');
    final bldCtrl = TextEditingController(text: existing?.locationBuilding ?? '');
    final areaCtrl = TextEditingController(text: existing?.locationArea ?? '');
    final maxPressCtrl = TextEditingController(text: existing?.maxAllowableWorkingPressureBar.toString() ?? '10.0');
    final hydroPressCtrl = TextEditingController(text: existing?.hydroTestPressureBar?.toString() ?? '15.0');
    final popPressCtrl = TextEditingController(text: existing?.safetyValvePopPressureBar?.toString() ?? '10.5');
    final engNameCtrl = TextEditingController(text: existing?.engineerName ?? '');
    final engLicCtrl = TextEditingController(text: existing?.engineerLicenseNo ?? '');
    final contractorCtrl = TextEditingController(text: existing?.contractorCompany ?? '');
    final defectsCtrl = TextEditingController(text: existing?.defectsFound ?? '');
    final actionsCtrl = TextEditingController(text: existing?.correctiveActions ?? '');

    String boilerType = existing?.boilerType ?? 'STEAM_BOILER';
    String hydroResult = existing?.hydroTestResult ?? 'PASS';
    String safetyValveResult = existing?.safetyValveTestResult ?? 'PASS';
    String waterTreatment = existing?.waterTreatmentStatus ?? 'PASS';
    String burnerControl = existing?.burnerControlStatus ?? 'PASS';
    String overallResult = existing?.overallResult ?? 'PASS';

    DateTime inspDate = existing?.inspectionDate ?? DateTime.now();
    DateTime expDate = existing?.expiryDate ?? DateTime(inspDate.year + 1, inspDate.month, inspDate.day);

    String? reportPdf = existing?.reportPdfPath;
    String? engLicPdf = existing?.engineerLicensePdfPath;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDlgState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.water_damage_outlined, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Text(existing == null ? 'บันทึกผลการตรวจหม้อน้ำ & ภาชนะรับแรงดัน' : 'แก้ไขผลการตรวจหม้อน้ำ'),
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
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: boilerType,
                            decoration: const InputDecoration(labelText: 'ประเภทอุปกรณ์ / หม้อน้ำ *', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'STEAM_BOILER', child: Text('หม้อน้ำไอน้ำ (Steam Boiler)')),
                              DropdownMenuItem(value: 'THERMAL_OIL', child: Text('หม้อต้มน้ำมันนำความร้อน (Thermal Oil)')),
                              DropdownMenuItem(value: 'HOT_WATER', child: Text('หม้อต้มน้ำร้อน (Hot Water Boiler)')),
                              DropdownMenuItem(value: 'PRESSURE_VESSEL', child: Text('ภาชนะรับแรงดัน (Pressure Vessel / Air Tank)')),
                            ],
                            onChanged: (v) {
                              if (v != null) setDlgState(() => boilerType = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: capCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'กำลังผลิต (Capacity)', hintText: 'e.g. 2.0', suffixText: 'Ton/hr', border: OutlineInputBorder()),
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
                            decoration: const InputDecoration(labelText: 'รหัสอุปกรณ์ (Boiler Tag) *', hintText: 'e.g. BOILER-01-STM', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกรหัส' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(labelText: 'ชื่อและรุ่นอุปกรณ์ *', hintText: 'e.g. หม้อน้ำไอน้ำท่อไฟ อาคาร Utility', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
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
                            decoration: const InputDecoration(labelText: 'อาคาร / สถานที่ติดตั้ง *', hintText: 'e.g. อาคาร Utility', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุสถานที่' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: areaCtrl,
                            decoration: const InputDecoration(labelText: 'ห้อง / โซน (Area)', hintText: 'e.g. ห้องหม้อน้ำ Boiler Room', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: maxPressCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'ความดันใช้งานสูงสุด (MAWP) *', suffixText: 'bar', border: OutlineInputBorder()),
                            validator: (v) => v == null || double.tryParse(v) == null ? 'กรอกตัวเลข bar' : null,
                            onChanged: (v) {
                              final mawp = double.tryParse(v) ?? 0;
                              // Standard hydro test is 1.5x MAWP
                              final hydro = mawp * 1.5;
                              final pop = mawp * 1.05;
                              hydroPressCtrl.text = hydro.toStringAsFixed(1);
                              popPressCtrl.text = pop.toStringAsFixed(1);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: hydroPressCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'ความดันทดสอบ Hydrostatic', suffixText: 'bar (1.5x)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: popPressCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'ความดัน Safety Valve ปลดปล่อย', suffixText: 'bar', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('ผลการตรวจสอบระบบความปลอดภัย (Safety Devices):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 10,
                        children: [
                          _buildMiniCheckDropdown('การทดสอบ Hydrostatic Test', hydroResult, (v) => setDlgState(() => hydroResult = v)),
                          _buildMiniCheckDropdown('การทดสอบลิ้นนิรภัย (Safety Valve)', safetyValveResult, (v) => setDlgState(() => safetyValveResult = v)),
                          _buildMiniCheckDropdown('ระบบบำบัดน้ำเลี้ยง (Water Quality)', waterTreatment, (v) => setDlgState(() => waterTreatment = v)),
                          _buildMiniCheckDropdown('ระบบควบคุมหัวพ่นไฟ (Burner Control)', burnerControl, (v) => setDlgState(() => burnerControl = v)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: engNameCtrl,
                            decoration: const InputDecoration(labelText: 'สามัญวิศวกรเครื่องกลผู้รับรอง *', hintText: 'e.g. ณรงค์ศักดิ์ กว.เครื่องกล', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อวิศวกร' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: engLicCtrl,
                            decoration: const InputDecoration(labelText: 'เลขที่ใบอนุญาต กว. *', hintText: 'e.g. สค. 3312', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกเลขที่ กว.' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contractorCtrl,
                      decoration: const InputDecoration(labelText: 'บริษัทผู้รับเหมาตรวจรับรอง', hintText: 'e.g. บริษัท บอยเลอร์ แอนด์ เอ็นจิเนียริ่ง จำกัด', border: OutlineInputBorder()),
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
                                  expDate = DateTime(picked.year + 1, picked.month, picked.day);
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
                      decoration: const InputDecoration(labelText: 'ข้อบกพร่องที่ตรวจพบ', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: actionsCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'ข้อเสนอแนะและมาตรการปรับปรุง', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    const Text('แนบเอกสารหลักฐาน (PDF):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildFilePickerButton(
                          title: 'รายงานการตรวจรับรองหม้อน้ำ',
                          currentPath: reportPdf,
                          onPick: () async {
                            final res = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                            if (res != null && res.files.single.path != null) {
                              setDlgState(() => reportPdf = res.files.single.path);
                            }
                          },
                          onClear: () => setDlgState(() => reportPdf = null),
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
                final boiler = BoilerInspectionModel(
                  id: existing?.id,
                  boilerName: nameCtrl.text.trim(),
                  boilerTag: tagCtrl.text.trim(),
                  boilerType: boilerType,
                  capacityTonHr: double.tryParse(capCtrl.text),
                  locationBuilding: bldCtrl.text.trim(),
                  locationArea: areaCtrl.text.trim().isEmpty ? null : areaCtrl.text.trim(),
                  maxAllowableWorkingPressureBar: double.tryParse(maxPressCtrl.text) ?? 10.0,
                  hydroTestPressureBar: double.tryParse(hydroPressCtrl.text),
                  hydroTestResult: hydroResult,
                  safetyValveTestResult: safetyValveResult,
                  safetyValvePopPressureBar: double.tryParse(popPressCtrl.text),
                  waterTreatmentStatus: waterTreatment,
                  burnerControlStatus: burnerControl,
                  engineerName: engNameCtrl.text.trim(),
                  engineerLicenseNo: engLicCtrl.text.trim(),
                  contractorCompany: contractorCtrl.text.trim().isEmpty ? null : contractorCtrl.text.trim(),
                  inspectionDate: inspDate,
                  expiryDate: expDate,
                  overallResult: overallResult,
                  defectsFound: defectsCtrl.text.trim().isEmpty ? null : defectsCtrl.text.trim(),
                  correctiveActions: actionsCtrl.text.trim().isEmpty ? null : actionsCtrl.text.trim(),
                  reportPdfPath: reportPdf,
                  engineerLicensePdfPath: engLicPdf,
                  createdAt: existing?.createdAt,
                );

                await ref.read(boilerInspectionListProvider.notifier).saveBoiler(boiler);
                if (!mounted) return;
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('บันทึกผลการตรวจรับรองหม้อน้ำสำเร็จ'), backgroundColor: Color(0xFF16A34A)),
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
      width: 280,
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          DropdownButton<String>(
            value: value,
            isDense: true,
            items: const [
              DropdownMenuItem(value: 'PASS', child: Text('ผ่านเกณฑ์', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))),
              DropdownMenuItem(value: 'FAIL', child: Text('ไม่ผ่าน', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))),
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
    final boilersAsync = ref.watch(boilerInspectionListProvider);

    return boilersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
      data: (boilers) {
        final total = boilers.length;
        final overdue = boilers.where((b) => b.slaStatus == 'OVERDUE').length;
        final warning = boilers.where((b) => b.slaStatus == 'WARNING').length;
        final compliant = boilers.where((b) => b.slaStatus == 'COMPLIANT').length;

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
                    Text('รายการหม้อน้ำและภาชนะรับแรงดัน ($total รายการ)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('การตรวจรับรองประจำปีตามกฎกระทรวงเครื่องจักร ปั้นจั่น หม้อน้ำ พ.ศ. ๒๕๖๔ & กรมโรงงานฯ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _showAddEditBoilerDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('บันทึกผลตรวจหม้อน้ำ'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (boilers.isEmpty)
              _buildEmptyState()
            else
              ...boilers.map((b) => _buildBoilerCard(b)),
          ],
        );
      },
    );
  }

  Widget _buildStatutoryBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.water_damage_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ข้อกำหนดทางกฎหมาย: การตรวจสอบรับรองหม้อน้ำและหม้อต้มน้ำมันนำความร้อนประจำปี',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'นายจ้างต้องจัดให้มีการตรวจสอบรับรองหม้อน้ำ (Boiler) และหม้อต้มที่ใช้ของเหลวเป็นสื่อนำความร้อน (Thermal Oil) อย่างน้อยปีละ ๑ ครั้ง โดยสามัญวิศวกรเครื่องกล พร้อมทดสอบความดันไฮโดรสแตติก (Hydrostatic test ๑.๕ เท่า) และตรวจทดสอบระบบอุปกรณ์ตัดอัตโนมัติ ลิ้นนิรภัย (Safety Valve) และคุณภาพน้ำเลี้ยง',
                  style: TextStyle(fontSize: 12, color: Color(0xFF14532D), height: 1.4),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildChip('รอบตรวจสอบ: อย่างน้อยปีละ ๑ ครั้ง', Icons.history),
                    _buildChip('ทดสอบความดัน: Hydrostatic Test ๑.๕ เท่า', Icons.speed),
                    _buildChip('ระบบระบายความดัน: Safety Valve Pop Test', Icons.security),
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
        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF16A34A)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534))),
        ],
      ),
    );
  }

  Widget _buildKpiRow({required int total, required int compliant, required int warning, required int overdue}) {
    return Row(
      children: [
        _buildKpiCard('หม้อน้ำทั้งหมด', '$total หน่วย', Icons.water_damage, const Color(0xFF0284C7)),
        const SizedBox(width: 12),
        _buildKpiCard('ผลตรวจปกติ (Compliant)', '$compliant หน่วย', Icons.check_circle_outline, const Color(0xFF16A34A)),
        const SizedBox(width: 12),
        _buildKpiCard('ใกล้ครบกำหนด 30 วัน', '$warning หน่วย', Icons.warning_amber_rounded, const Color(0xFFF59E0B)),
        const SizedBox(width: 12),
        _buildKpiCard('เกินกำหนด (Overdue)', '$overdue หน่วย', Icons.error_outline, const Color(0xFFDC2626)),
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

  Widget _buildBoilerCard(BoilerInspectionModel boiler) {
    final isPass = boiler.overallResult == 'PASS';
    final isOverdue = boiler.slaStatus == 'OVERDUE';
    final isWarning = boiler.slaStatus == 'WARNING';

    Color slaColor = const Color(0xFF16A34A);
    String slaText = 'ยังไม่หมดอายุ (${boiler.daysUntilExpiry} วัน)';
    if (isOverdue) {
      slaColor = const Color(0xFFDC2626);
      slaText = 'เกินกำหนดแล้ว (${boiler.daysUntilExpiry.abs()} วัน)';
    } else if (isWarning) {
      slaColor = const Color(0xFFF59E0B);
      slaText = 'ใกล้ครบกำหนด (${boiler.daysUntilExpiry} วัน)';
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
                  child: Text(boiler.boilerTag, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7), fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text(boiler.boilerTypeTh, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700, fontSize: 11)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    boiler.boilerName,
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
                  onPressed: () => _showAddEditBoilerDialog(boiler),
                  tooltip: 'แก้ไข',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  onPressed: () => _confirmDelete(boiler),
                  tooltip: 'ลบ',
                ),
              ],
            ),
            const Divider(height: 18),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _buildInfoItem('สถานที่ติดตั้ง', '${boiler.locationBuilding} ${boiler.locationArea ?? ''}'),
                _buildInfoItem('กำลังผลิต', '${boiler.capacityTonHr ?? '-'} Ton/hr'),
                _buildInfoItem('ความดันใช้งานสูงสุด (MAWP)', '${boiler.maxAllowableWorkingPressureBar} bar'),
                _buildInfoItem('ความดันทดสอบ Hydrostatic', '${boiler.hydroTestPressureBar ?? '-'} bar'),
                _buildInfoItem('ความดันลิ้นนิรภัย (Safety Valve)', '${boiler.safetyValvePopPressureBar ?? '-'} bar'),
                _buildInfoItem('วิศวกรเครื่องกลผู้ตรวจ', '${boiler.engineerName} (${boiler.engineerLicenseNo})'),
                _buildInfoItem('วันที่ตรวจ', boiler.inspectionDate.toIso8601String().substring(0, 10)),
                _buildInfoItem('วันหมดอายุ', boiler.expiryDate.toIso8601String().substring(0, 10)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Text('ระบบความปลอดภัย: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  _buildStatusChip('Hydro Test', boiler.hydroTestResult),
                  const SizedBox(width: 8),
                  _buildStatusChip('Safety Valve', boiler.safetyValveTestResult),
                  const SizedBox(width: 8),
                  _buildStatusChip('น้ำเลี้ยงหม้อน้ำ', boiler.waterTreatmentStatus),
                  const SizedBox(width: 8),
                  _buildStatusChip('ระบบหัวเผา', boiler.burnerControlStatus),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPass ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isPass ? Colors.green : Colors.red),
                    ),
                    child: Text(
                      boiler.overallResultTh,
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
                _buildAttachmentButton('รายงานการตรวจรับรองหม้อน้ำ (PDF)', boiler.reportPdfPath, Icons.picture_as_pdf, const Color(0xFFDC2626)),
                _buildAttachmentButton('ใบ กว. เครื่องกล (PDF)', boiler.engineerLicensePdfPath, Icons.badge_outlined, const Color(0xFF2563EB)),
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
              constraints: const BoxConstraints(maxWidth: 140),
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
          Icon(Icons.water_damage_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('ยังไม่มีข้อมูลการตรวจรับรองหม้อน้ำ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 6),
          const Text('กดปุ่ม "บันทึกผลตรวจหม้อน้ำ" ด้านบน เพื่อเพิ่มรายการแรก', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BoilerInspectionModel boiler) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบประวัติการตรวจหม้อน้ำ ${boiler.boilerName} ใช่หรือไม่?'),
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
    if (ok == true && boiler.id != null) {
      await ref.read(boilerInspectionListProvider.notifier).deleteBoiler(boiler.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบรายการสำเร็จ')));
      }
    }
  }
}
