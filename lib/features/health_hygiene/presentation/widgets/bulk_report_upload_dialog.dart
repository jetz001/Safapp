import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/health_models.dart';
import '../providers/health_providers.dart';

class BulkReportUploadDialog extends ConsumerStatefulWidget {
  final CompanyHealthBulkReport? existingReport;

  const BulkReportUploadDialog({
    Key? key,
    this.existingReport,
  }) : super(key: key);

  @override
  ConsumerState<BulkReportUploadDialog> createState() => _BulkReportUploadDialogState();
}

class _BulkReportUploadDialogState extends ConsumerState<BulkReportUploadDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _yearController;
  late TextEditingController _titleController;
  late TextEditingController _hospitalController;
  late TextEditingController _dateController;
  late TextEditingController _totalController;
  late TextEditingController _normalController;
  late TextEditingController _abnormalController;
  late TextEditingController _watchController;
  late TextEditingController _notesController;

  String? _pdfFilePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.existingReport;
    final now = DateTime.now();

    _yearController = TextEditingController(text: r?.reportYear ?? '${now.year + 543}');
    _titleController = TextEditingController(
      text: r?.reportTitle ?? 'เล่มรายงานผลการตรวจสุขภาพประจำปีและตามปัจจัยเสี่ยง ${now.year + 543}',
    );
    _hospitalController = TextEditingController(text: r?.hospitalName ?? 'ศูนย์อาชีวเวชศาสตร์ โรงพยาบาล');
    _dateController = TextEditingController(text: r?.checkupDate ?? now.toIso8601String().substring(0, 10));
    _totalController = TextEditingController(text: r != null ? '${r.totalEmployeesTested}' : '120');
    _normalController = TextEditingController(text: r != null ? '${r.normalCount}' : '108');
    _abnormalController = TextEditingController(text: r != null ? '${r.abnormalCount}' : '4');
    _watchController = TextEditingController(text: r != null ? '${r.watchCount}' : '8');
    _notesController = TextEditingController(text: r?.summaryNotes ?? 'พบผู้มีภาวะความดันโลหิตสูงและสมรรถภาพการได้ยินลดลงเล็กน้อยในแผนกผลิต');
    _pdfFilePath = r?.pdfFilePath;
  }

  @override
  void dispose() {
    _yearController.dispose();
    _titleController.dispose();
    _hospitalController.dispose();
    _dateController.dispose();
    _totalController.dispose();
    _normalController.dispose();
    _abnormalController.dispose();
    _watchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _pdfFilePath = result.files.single.path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pdfFilePath == null || _pdfFilePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกไฟล์ PDF เล่มรายงานจากโรงพยาบาล')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final report = CompanyHealthBulkReport(
        id: widget.existingReport?.id,
        reportYear: _yearController.text.trim(),
        reportTitle: _titleController.text.trim(),
        hospitalName: _hospitalController.text.trim(),
        checkupDate: _dateController.text.trim(),
        totalEmployeesTested: int.tryParse(_totalController.text.trim()) ?? 0,
        normalCount: int.tryParse(_normalController.text.trim()) ?? 0,
        abnormalCount: int.tryParse(_abnormalController.text.trim()) ?? 0,
        watchCount: int.tryParse(_watchController.text.trim()) ?? 0,
        summaryNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        pdfFilePath: _pdfFilePath!,
      );

      await ref.read(companyBulkReportsProvider.notifier).saveBulkReport(report, newPdfPath: _pdfFilePath);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingReport != null ? 'อัปเดตเล่มรายงานเรียบร้อย' : 'บันทึกเล่มรายงาน รพ. ภาพรวมเรียบร้อย'),
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
    final isEdit = widget.existingReport != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.menu_book_rounded, color: Color(0xFF1E3A8A), size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            isEdit ? 'แก้ไขเล่มรายงานสรุปภาพรวมจากโรงพยาบาล' : 'อัปโหลดเล่มรายงานสรุปภาพรวมจากโรงพยาบาล (Bulk Report)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _yearController,
                        decoration: _inputDecoration('ปีที่ตรวจ (พ.ศ.) *', icon: Icons.calendar_today),
                        validator: (v) => v == null || v.trim().isEmpty ? 'ระบุปี' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _titleController,
                        decoration: _inputDecoration('ชื่อเล่มรายงาน / โครงการตรวจสุขภาพ *', icon: Icons.title),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อรายงาน' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _hospitalController,
                        decoration: _inputDecoration('โรงพยาบาล / สถาบันผู้ตรวจ *', icon: Icons.local_hospital),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุโรงพยาบาล' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _dateController,
                        decoration: _inputDecoration('วันที่ตรวจ *', icon: Icons.event),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildSectionHeader('สรุปสถิติจำนวนพนักงานที่เข้ารับการตรวจ'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _totalController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('จำนวนผู้ตรวจทั้งหมด (คน) *', icon: Icons.group),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _normalController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('ผลปกติ (คน)', icon: Icons.check_circle_outline),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _watchController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('เฝ้าระวัง (คน)', icon: Icons.warning_amber_rounded),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _abnormalController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('ผิดปกติ (คน)', icon: Icons.error_outline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: _inputDecoration('สรุปภาพรวมทางการแพทย์ / คำแนะนำสำหรับองค์กร', icon: Icons.notes),
                ),
                const SizedBox(height: 16),

                _buildSectionHeader('แนบไฟล์ PDF เล่มรายงานฉบับสมบูรณ์ (Full Bulk PDF Report) *'),
                Container(
                  padding: const EdgeInsets.all(14),
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
                          color: _pdfFilePath != null ? Colors.red.shade50 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          color: _pdfFilePath != null ? Colors.red.shade700 : Colors.grey.shade600,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pdfFilePath != null ? p.basename(_pdfFilePath!) : 'ยังไม่ได้เลือกไฟล์ PDF เล่มรายงาน',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _pdfFilePath != null ? const Color(0xFF0F172A) : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('รองรับไฟล์ PDF ทุกขนาด (เล่มรายงานทางการแพทย์ประจำปี)', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _pickPdf,
                        icon: const Icon(Icons.upload_file_rounded, size: 16),
                        label: Text(_pdfFilePath != null ? 'เปลี่ยนไฟล์' : 'เลือกไฟล์ PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(), child: const Text('ยกเลิก')),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.cloud_upload_rounded, size: 18),
          label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกเล่มรายงาน'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF334155)),
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
