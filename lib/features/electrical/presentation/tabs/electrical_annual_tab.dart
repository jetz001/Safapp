import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:safety_superapp/features/electrical/data/models/electrical_inspection_model.dart';
import 'package:safety_superapp/features/electrical/presentation/notifiers/electrical_providers.dart';

class ElectricalInspectionTab extends ConsumerStatefulWidget {
  const ElectricalInspectionTab({super.key});

  @override
  ConsumerState<ElectricalInspectionTab> createState() => _ElectricalInspectionTabState();
}

class _ElectricalInspectionTabState extends ConsumerState<ElectricalInspectionTab> {
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

  void _showRecordForm([ElectricalInspectionModel? existing]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ElectricalInspectionFormDialog(
        existingRecord: existing,
        onSave: (record) async {
          await ref.read(electricalInspectionListProvider.notifier).saveInspection(record);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(existing == null ? 'บันทึกผลการตรวจสอบเรียบร้อยแล้ว' : 'แก้ไขข้อมูลเรียบร้อยแล้ว'),
                backgroundColor: const Color(0xFF16A34A),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(ElectricalInspectionModel record) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันลบรายการตรวจสอบ'),
          ],
        ),
        content: Text('ต้องการลบประวัติการตรวจสอบวันที่ ${record.inspectionDate.toIso8601String().substring(0, 10)} ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบรายการ'),
          ),
        ],
      ),
    );

    if (ok == true && record.id != null) {
      await ref.read(electricalInspectionListProvider.notifier).deleteInspection(record.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบรายการสำเร็จ')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inspectionsAsync = ref.watch(electricalInspectionListProvider);

    return inspectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
      data: (records) {
        final latest = records.isNotEmpty ? records.first : null;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Legal Mandate Banner
            _buildStatutoryBanner(),
            const SizedBox(height: 16),

            // SLA & KPI Summary Cards
            if (latest != null) ...[
              _buildKpiSummary(latest, records.length),
              const SizedBox(height: 16),
            ],

            // Section Header & Add Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ประวัติการตรวจสอบระบบไฟฟ้า (${records.length} รายการ)',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'จัดเก็บรายงาน แบบ ๕๖๒๘๙, ภาพ Thermo-scan และใบ กว. สำหรับรับการตรวจจากพนักงานตรวจความปลอดภัย',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _showRecordForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('บันทึกผลตรวจรับรอง'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (records.isEmpty)
              _buildEmptyState()
            else
              ...records.map((r) => _buildRecordCard(r)),
          ],
        );
      },
    );
  }

  Widget _buildStatutoryBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ข้อกำหนดทางกฎหมาย: การตรวจสอบระบบไฟฟ้าและบริภัณฑ์ไฟฟ้าประจำปี (ม.๑๒)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ตามกฎกระทรวงกำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานเกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘ ข้อ ๑๒ กำหนดให้นายจ้างต้องจัดให้มีการตรวจสอบและรับรองระบบไฟฟ้าอย่างน้อยปีละ ๑ ครั้ง โดยบุคคลที่ขึ้นทะเบียนตามมาตรา ๙ หรือนิติบุคคลตามมาตรา ๑๑ และจัดทำบันทึกตาม แบบ ๕๖๒๘๙',
                  style: TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.4),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildChip('รอบตรวจสอบ: อย่างน้อยปีละ ๑ ครั้ง', Icons.event_repeat),
                    _buildChip('แบบราชการ: แบบ ๕๖๒๘๙', Icons.description_outlined),
                    _buildChip('เกณฑ์ความต้านทานดิน: ไม่เกิน ๕ โอห์ม', Icons.electric_meter),
                    _buildChip('วิศวกรผู้รับรอง: กว. / ผู้ขึ้นทะเบียน ม.๑๑', Icons.verified_user_outlined),
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
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF92400E)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
        ],
      ),
    );
  }

  Widget _buildKpiSummary(ElectricalInspectionModel latest, int totalCount) {
    final status = latest.slaStatus;
    final isPass = latest.overallResult == 'PASS';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(status.icon, color: status.color, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'สถานะการรับรองระบบไฟฟ้าล่าสุด: ${status.titleTh}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: status.color),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPass ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isPass ? Colors.green : Colors.red),
                ),
                child: Text(
                  latest.overallResultTh,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPass ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'วันตรวจล่าสุด',
                  latest.inspectionDate.toIso8601String().substring(0, 10),
                  Icons.calendar_today_outlined,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'วันครบกำหนดรอบปี',
                  latest.expiryDate.toIso8601String().substring(0, 10),
                  Icons.alarm,
                  status.color,
                  subtitle: latest.isOverdue
                      ? 'เลยกำหนดมาแล้ว ${latest.daysRemaining.abs()} วัน'
                      : 'เหลืออีก ${latest.daysRemaining} วัน',
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'ค่าความต้านทานดิน',
                  latest.groundingResistanceOhm != null ? '${latest.groundingResistanceOhm} Ω' : 'ไม่ได้ระบุ',
                  Icons.speed,
                  latest.isGroundingStandardPass ? Colors.green : Colors.red,
                  subtitle: latest.isGroundingStandardPass ? 'ผ่านเกณฑ์ (<= 5 Ω)' : 'เกินเกณฑ์มาตรฐาน',
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'วิศวกร / ผู้รับเหมา',
                  latest.contractorCompany ?? latest.inspectorName,
                  Icons.business,
                  Colors.purple,
                  subtitle: 'เลขที่ กว.: ${latest.inspectorLicenseNo}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.bolt_rounded, size: 64, color: Colors.amber.shade300),
          const SizedBox(height: 12),
          const Text(
            'ยังไม่มีการบันทึกผลตรวจรับรองระบบไฟฟ้าประจำปี',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'กฎหมายกำหนดให้สถานประกอบการตรวจสอบอย่างน้อยปีละ ๑ ครั้ง และแนบเล่มรายงาน ผรม. หรือ แบบ ๕๖๒๘๙',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showRecordForm(),
            icon: const Icon(Icons.add),
            label: const Text('บันทึกผลการตรวจรับรองครั้งแรก'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(ElectricalInspectionModel record) {
    final status = record.slaStatus;
    final isPass = record.overallResult == 'PASS';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: record.isOverdue ? Colors.red.shade300 : Colors.grey.shade200,
          width: record.isOverdue ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.bolt, color: Color(0xFFD97706), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'รายงานผลตรวจรับรองระบบไฟฟ้า วันที่ ${record.inspectionDate.toIso8601String().substring(0, 10)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'รอบหมดอายุ: ${record.expiryDate.toIso8601String().substring(0, 10)} (${record.isOverdue ? "หมดอายุมาแล้ว ${record.daysRemaining.abs()} วัน" : "เหลือ ${record.daysRemaining} วัน"})',
                          style: TextStyle(
                            fontSize: 12,
                            color: status.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPass ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isPass ? Colors.green : Colors.red),
                      ),
                      child: Text(
                        record.overallResultTh,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPass ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                      tooltip: 'แก้ไข',
                      onPressed: () => _showRecordForm(record),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      tooltip: 'ลบ',
                      onPressed: () => _confirmDelete(record),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),

            // Key Inspection Info Grid
            Wrap(
              spacing: 24,
              runSpacing: 10,
              children: [
                _buildInfoItem('ผู้รับเหมา/บริษัทตรวจ', record.contractorCompany ?? '-'),
                _buildInfoItem('วิศวกรผู้ตรวจรับรอง', '${record.inspectorName} (กว. ${record.inspectorLicenseNo})'),
                _buildInfoItem('ระบบแรงดัน', record.voltageSystemTh),
                _buildInfoItem('หม้อแปลงไฟฟ้า', '${record.transformerCount} ลูก'),
                _buildInfoItem('ตู้สวิตช์บอร์ด MDB', '${record.mdbPanelCount} ตู้'),
                _buildInfoItem(
                  'ค่าความต้านทานดิน',
                  record.groundingResistanceOhm != null
                      ? '${record.groundingResistanceOhm} Ω ${record.isGroundingStandardPass ? "(ผ่านเกณฑ์ <= 5 Ω)" : "(เกินเกณฑ์)"}'
                      : '-',
                ),
              ],
            ),

            if (record.defectsFound != null && record.defectsFound!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ข้อบกพร่องที่ตรวจพบ: ${record.defectsFound}',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (record.correctiveActions != null && record.correctiveActions!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.build_circle_outlined, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'มาตรการแก้ไข: ${record.correctiveActions}',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Attachment Badges & 1-Click Launchers
            Text(
              'เอกสารแนบประกอบรายงาน (คลิกเพื่อเปิดดูไฟล์):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _buildAttachmentButton(
                  title: 'เล่มรายงาน ผรม. (PDF)',
                  filePath: record.vendorReportPdfPath,
                  icon: Icons.picture_as_pdf,
                  color: const Color(0xFFDC2626),
                ),
                _buildAttachmentButton(
                  title: 'รายงาน Thermo-scan (PDF)',
                  filePath: record.thermoscanReportPath,
                  icon: Icons.thermostat_auto,
                  color: const Color(0xFFEA580C),
                ),
                _buildAttachmentButton(
                  title: 'สำเนาใบ กว. / ม.๑๑',
                  filePath: record.engineerLicenseDocPath,
                  icon: Icons.badge_outlined,
                  color: const Color(0xFF2563EB),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton({
    required String title,
    required String? filePath,
    required IconData icon,
    required Color color,
  }) {
    final hasFile = filePath != null && filePath.trim().isNotEmpty;
    final fileName = hasFile ? p.basename(filePath) : 'ยังไม่ได้แนบไฟล์';

    return OutlinedButton.icon(
      onPressed: hasFile ? () => _openFile(filePath) : null,
      icon: Icon(icon, size: 16, color: hasFile ? color : Colors.grey),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: hasFile ? Colors.black87 : Colors.grey)),
          if (hasFile) ...[
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                fileName,
                style: TextStyle(fontSize: 11, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 13, color: color),
          ],
        ],
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: hasFile ? color.withValues(alpha: 0.5) : Colors.grey.shade300),
        backgroundColor: hasFile ? color.withValues(alpha: 0.04) : Colors.grey.shade50,
      ),
    );
  }
}

class _ElectricalInspectionFormDialog extends StatefulWidget {
  final ElectricalInspectionModel? existingRecord;
  final Future<void> Function(ElectricalInspectionModel record) onSave;

  const _ElectricalInspectionFormDialog({
    this.existingRecord,
    required this.onSave,
  });

  @override
  State<_ElectricalInspectionFormDialog> createState() => _ElectricalInspectionFormDialogState();
}

class _ElectricalInspectionFormDialogState extends State<_ElectricalInspectionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyNameController;
  late TextEditingController _inspectionDateController;
  late TextEditingController _expiryDateController;
  late TextEditingController _inspectorNameController;
  late TextEditingController _inspectorLicenseNoController;
  late TextEditingController _contractorCompanyController;
  late TextEditingController _transformerCountController;
  late TextEditingController _mdbPanelCountController;
  late TextEditingController _groundingResistanceController;
  late TextEditingController _defectsFoundController;
  late TextEditingController _correctiveActionsController;

  String _inspectorType = 'EXTERNAL_CONTRACTOR';
  String _overallResult = 'PASS';
  String _voltageSystem = 'HIGH_AND_LOW_VOLTAGE';

  String? _vendorReportPdfPath;
  String? _thermoscanReportPath;
  String? _engineerLicenseDocPath;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.existingRecord;
    final now = DateTime.now();

    _companyNameController = TextEditingController(text: r?.companyName ?? '');
    _inspectionDateController = TextEditingController(
      text: r != null
          ? r.inspectionDate.toIso8601String().substring(0, 10)
          : now.toIso8601String().substring(0, 10),
    );
    _expiryDateController = TextEditingController(
      text: r != null
          ? r.expiryDate.toIso8601String().substring(0, 10)
          : DateTime(now.year + 1, now.month, now.day).toIso8601String().substring(0, 10),
    );
    _inspectorNameController = TextEditingController(text: r?.inspectorName ?? '');
    _inspectorLicenseNoController = TextEditingController(text: r?.inspectorLicenseNo ?? '');
    _contractorCompanyController = TextEditingController(text: r?.contractorCompany ?? '');
    _transformerCountController = TextEditingController(text: (r?.transformerCount ?? 1).toString());
    _mdbPanelCountController = TextEditingController(text: (r?.mdbPanelCount ?? 2).toString());
    _groundingResistanceController = TextEditingController(
      text: r?.groundingResistanceOhm != null ? r!.groundingResistanceOhm.toString() : '2.8',
    );
    _defectsFoundController = TextEditingController(text: r?.defectsFound ?? '');
    _correctiveActionsController = TextEditingController(text: r?.correctiveActions ?? '');

    if (r != null) {
      _inspectorType = r.inspectorType;
      _overallResult = r.overallResult;
      _voltageSystem = r.voltageSystem;
      _vendorReportPdfPath = r.vendorReportPdfPath;
      _thermoscanReportPath = r.thermoscanReportPath;
      _engineerLicenseDocPath = r.engineerLicenseDocPath;
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _inspectionDateController.dispose();
    _expiryDateController.dispose();
    _inspectorNameController.dispose();
    _inspectorLicenseNoController.dispose();
    _contractorCompanyController.dispose();
    _transformerCountController.dispose();
    _mdbPanelCountController.dispose();
    _groundingResistanceController.dispose();
    _defectsFoundController.dispose();
    _correctiveActionsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller, {bool updateExpiry = false}) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().substring(0, 10);
        if (updateExpiry) {
          final exp = DateTime(picked.year + 1, picked.month, picked.day);
          _expiryDateController.text = exp.toIso8601String().substring(0, 10);
        }
      });
    }
  }

  Future<void> _pickFile(void Function(String path) onPicked) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xlsx', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        onPicked(result.files.single.path!);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final inspectionDate = DateTime.parse(_inspectionDateController.text);
      final expiryDate = DateTime.parse(_expiryDateController.text);

      final model = ElectricalInspectionModel(
        id: widget.existingRecord?.id,
        companyName: _companyNameController.text.trim().isEmpty ? null : _companyNameController.text.trim(),
        inspectionDate: inspectionDate,
        expiryDate: expiryDate,
        inspectorName: _inspectorNameController.text.trim(),
        inspectorLicenseNo: _inspectorLicenseNoController.text.trim(),
        contractorCompany: _contractorCompanyController.text.trim().isEmpty ? null : _contractorCompanyController.text.trim(),
        inspectorType: _inspectorType,
        overallResult: _overallResult,
        voltageSystem: _voltageSystem,
        transformerCount: int.tryParse(_transformerCountController.text) ?? 0,
        mdbPanelCount: int.tryParse(_mdbPanelCountController.text) ?? 0,
        groundingResistanceOhm: double.tryParse(_groundingResistanceController.text),
        defectsFound: _defectsFoundController.text.trim().isEmpty ? null : _defectsFoundController.text.trim(),
        correctiveActions: _correctiveActionsController.text.trim().isEmpty ? null : _correctiveActionsController.text.trim(),
        vendorReportPdfPath: _vendorReportPdfPath,
        thermoscanReportPath: _thermoscanReportPath,
        engineerLicenseDocPath: _engineerLicenseDocPath,
      );

      await widget.onSave(model);
      if (mounted) Navigator.pop(context);
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
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 750),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.bolt, color: Color(0xFFD97706)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.existingRecord == null
                                ? 'บันทึกผลการตรวจสอบและรับรองระบบไฟฟ้า (แบบ ๕๖๒๘๙)'
                                : 'แก้ไขผลการตรวจสอบและรับรองระบบไฟฟ้า',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'กฎกระทรวงกำหนดมาตรฐานฯ พ.ศ. ๒๕๕๘ ข้อ ๑๒ (ตรวจสอบโดยวิศวกร กว. / ผู้รับเหมาขึ้นทะเบียน ม.๑๑)',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Scrollable Form Fields
                Expanded(
                  child: ListView(
                    children: [
                      // Dates & Expiry
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _inspectionDateController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'วันที่ตรวจสอบ *',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_month),
                              ),
                              onTap: () => _pickDate(_inspectionDateController, updateExpiry: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _expiryDateController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'วันครบกำหนดรอบปี (SLA 365 วัน) *',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.event_available),
                              ),
                              onTap: () => _pickDate(_expiryDateController),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Contractor & Inspector
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _contractorCompanyController,
                              decoration: const InputDecoration(
                                labelText: 'ชื่อบริษัทผู้รับเหมา / หน่วยงานที่ขึ้นทะเบียน ม.๑๑',
                                hintText: 'เช่น บริษัท วิศวกรรมไฟฟ้าบริการ จำกัด',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: _inspectorType,
                              decoration: const InputDecoration(
                                labelText: 'ประเภทผู้ตรวจสอบ',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'EXTERNAL_CONTRACTOR', child: Text('ผู้รับเหมาขึ้นทะเบียน ม.๑๑')),
                                DropdownMenuItem(value: 'INTERNAL_ENGINEER', child: Text('วิศวกรไฟฟ้าประจำโรงงาน')),
                                DropdownMenuItem(value: 'GOVERNMENT', child: Text('เจ้าหน้าที่ กฟน./กฟภ.')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _inspectorType = v);
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
                              controller: _inspectorNameController,
                              decoration: const InputDecoration(
                                labelText: 'ชื่อ-นามสกุล ผู้ตรวจสอบ / รับรอง *',
                                hintText: 'เช่น นายวิศวะ ช่างไฟ',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อผู้ตรวจสอบ' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _inspectorLicenseNoController,
                              decoration: const InputDecoration(
                                labelText: 'เลขที่ใบอนุญาต กว. หรือ เลขทะเบียน ม.๑๑ *',
                                hintText: 'เช่น ภฟก. 12345 หรือ ทบ. 0123-58',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุเลขที่ใบอนุญาต' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Technical Electrical Specs
                      const Text(
                        'ข้อมูลทางเทคนิคและการวัดค่า',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _voltageSystem,
                              decoration: const InputDecoration(
                                labelText: 'ระบบแรงดันไฟฟ้า',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'HIGH_AND_LOW_VOLTAGE', child: Text('แรงดันสูงและต่ำ')),
                                DropdownMenuItem(value: 'HIGH_VOLTAGE', child: Text('แรงดันสูง (High Voltage)')),
                                DropdownMenuItem(value: 'LOW_VOLTAGE', child: Text('แรงดันต่ำ (Low Voltage)')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _voltageSystem = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _transformerCountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'จำนวนหม้อแปลง (ลูก)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _mdbPanelCountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'จำนวนตู้ MDB/DB (ตู้)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _groundingResistanceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'ความต้านทานดิน (โอห์ม)',
                                hintText: '<= 5 Ω ตามมาตรฐาน',
                                border: OutlineInputBorder(),
                                suffixText: 'Ω',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _overallResult,
                              decoration: const InputDecoration(
                                labelText: 'สรุปผลการตรวจสอบรวม',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'PASS', child: Text('ปลอดภัยใช้งานได้ (ผ่าน)')),
                                DropdownMenuItem(value: 'CONDITIONAL_PASS', child: Text('ปลอดภัยแบบมีเงื่อนไข (ต้องแก้ไข)')),
                                DropdownMenuItem(value: 'FAIL', child: Text('ไม่ปลอดภัย (ต้องแก้ไขด่วน)')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _overallResult = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _defectsFoundController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'ข้อบกพร่องที่ตรวจพบ (ถ้ามี)',
                          hintText: 'เช่น จุดต่อสาย MDB-1 มีอุณหภูมิสูงผิดปกติ, ค่าความต้านทานดินหลักที่ 2 สูงเกินเกณฑ์',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _correctiveActionsController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'มาตรการแก้ไขและคำแนะนำ',
                          hintText: 'เช่น ขันแน่นจุดต่อและเปลี่ยนหางปลาใหม่, ปรับปรุงระบบกราวด์เพิ่มหลักดิน',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Attachments Section
                      const Text(
                        'แนบไฟล์เอกสารจากผู้รับเหมา (Vendor Report / Thermo-scan / License)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                      ),
                      const SizedBox(height: 8),

                      _buildFilePickerField(
                        label: 'เล่มรายงานผลการตรวจสอบและรับรองระบบไฟฟ้า (PDF ของ ผรม.)',
                        currentPath: _vendorReportPdfPath,
                        icon: Icons.picture_as_pdf,
                        color: Colors.red,
                        onPicked: (p) => _vendorReportPdfPath = p,
                        onClear: () => setState(() => _vendorReportPdfPath = null),
                      ),
                      const SizedBox(height: 10),

                      _buildFilePickerField(
                        label: 'รายงานภาพถ่ายความร้อนอินฟราเรด (Thermo-scan Report)',
                        currentPath: _thermoscanReportPath,
                        icon: Icons.thermostat_auto,
                        color: Colors.orange,
                        onPicked: (p) => _thermoscanReportPath = p,
                        onClear: () => setState(() => _thermoscanReportPath = null),
                      ),
                      const SizedBox(height: 10),

                      _buildFilePickerField(
                        label: 'สำเนาใบ กว. วิศวกร / ใบรับรองการขึ้นทะเบียน ม.๑๑',
                        currentPath: _engineerLicenseDocPath,
                        icon: Icons.badge_outlined,
                        color: Colors.blue,
                        onPicked: (p) => _engineerLicenseDocPath = p,
                        onClear: () => setState(() => _engineerLicenseDocPath = null),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),

                // Dialog Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('ยกเลิก'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: const Text('บันทึกข้อมูล'),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilePickerField({
    required String label,
    required String? currentPath,
    required IconData icon,
    required Color color,
    required void Function(String path) onPicked,
    required VoidCallback onClear,
  }) {
    final hasFile = currentPath != null && currentPath.trim().isNotEmpty;
    final fileName = hasFile ? p.basename(currentPath) : 'ยังไม่ได้เลือกไฟล์';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasFile ? color.withValues(alpha: 0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasFile ? color.withValues(alpha: 0.4) : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: hasFile ? color : Colors.grey, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 11,
                    color: hasFile ? color : Colors.grey.shade600,
                    fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (hasFile) ...[
            IconButton(
              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
              tooltip: 'ลบไฟล์แนบ',
              onPressed: onClear,
            ),
          ],
          FilledButton.tonalIcon(
            onPressed: () => _pickFile(onPicked),
            icon: const Icon(Icons.attach_file, size: 16),
            label: Text(hasFile ? 'เปลี่ยนไฟล์' : 'เลือกไฟล์'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
          ),
        ],
      ),
    );
  }
}
