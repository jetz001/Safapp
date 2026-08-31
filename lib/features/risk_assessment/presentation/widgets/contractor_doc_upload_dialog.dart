import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/contractor_jsa_models.dart';
import '../providers/risk_assessment_providers.dart';

class ContractorDocUploadDialog extends ConsumerStatefulWidget {
  final ContractorJsaDocument? existingDoc;

  const ContractorDocUploadDialog({
    Key? key,
    this.existingDoc,
  }) : super(key: key);

  @override
  ConsumerState<ContractorDocUploadDialog> createState() => _ContractorDocUploadDialogState();
}

class _ContractorDocUploadDialogState extends ConsumerState<ContractorDocUploadDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _contractorNameController;
  late TextEditingController _projectTitleController;
  late TextEditingController _workLocationController;
  late TextEditingController _assessmentDateController;
  late TextEditingController _validUntilDateController;
  late TextEditingController _assessorNameController;
  late TextEditingController _notesController;

  String _documentType = 'JSA ผู้รับเหมา (Job Safety Analysis)';

  final List<String> _existingFilePaths = [];
  final List<String> _newFilePathsToUpload = [];
  bool _isSaving = false;

  final List<String> _docTypes = [
    'JSA ผู้รับเหมา (Job Safety Analysis)',
    'แบบ ปอ.๑ / ปอ.๒ ผู้รับเหมา',
    'Safety Method Statement (SMS)',
    'แผนงานความปลอดภัยและการควบคุมอันตราย',
    'เอกสารขั้นตอนการทำงานปลอดภัย (SOP ผู้รับเหมา)',
    'เอกสารอื่นๆ จากผู้รับเหมา',
  ];

  @override
  void initState() {
    super.initState();
    final doc = widget.existingDoc;

    _contractorNameController = TextEditingController(text: doc?.contractorName ?? '');
    _projectTitleController = TextEditingController(text: doc?.projectTitle ?? '');
    _workLocationController = TextEditingController(text: doc?.workLocation ?? '');
    _assessmentDateController = TextEditingController(
      text: doc?.assessmentDate ?? DateTime.now().toIso8601String().substring(0, 10),
    );
    _validUntilDateController = TextEditingController(text: doc?.validUntilDate ?? '');
    _assessorNameController = TextEditingController(text: doc?.assessorName ?? '');
    _notesController = TextEditingController(text: doc?.notes ?? '');

    if (doc != null) {
      if (_docTypes.contains(doc.documentType)) {
        _documentType = doc.documentType;
      }
      _existingFilePaths.addAll(doc.filePaths);
    }
  }

  @override
  void dispose() {
    _contractorNameController.dispose();
    _projectTitleController.dispose();
    _workLocationController.dispose();
    _assessmentDateController.dispose();
    _validUntilDateController.dispose();
    _assessorNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result != null && result.paths.isNotEmpty) {
      setState(() {
        for (final path in result.paths) {
          if (path != null && !_newFilePathsToUpload.contains(path) && !_existingFilePaths.contains(path)) {
            _newFilePathsToUpload.add(path);
          }
        }
      });
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_existingFilePaths.isEmpty && _newFilePathsToUpload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาแนบไฟล์เอกสาร PDF หรือรูปถ่าย Hard copy อย่างน้อย 1 ไฟล์'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final doc = ContractorJsaDocument(
        id: widget.existingDoc?.id,
        contractorName: _contractorNameController.text.trim(),
        projectTitle: _projectTitleController.text.trim(),
        workLocation: _workLocationController.text.trim().isEmpty ? null : _workLocationController.text.trim(),
        documentType: _documentType,
        assessmentDate: _assessmentDateController.text.trim(),
        validUntilDate: _validUntilDateController.text.trim().isEmpty ? null : _validUntilDateController.text.trim(),
        assessorName: _assessorNameController.text.trim().isEmpty ? null : _assessorNameController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        filePaths: _existingFilePaths,
        status: widget.existingDoc?.status ?? 'ACTIVE',
      );

      await ref.read(contractorJsaProvider.notifier).saveDocument(
            doc,
            newFilesToPersist: _newFilePathsToUpload,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingDoc == null
                ? 'บันทึกเอกสารผู้รับเหมาเรียบร้อยแล้ว'
                : 'แก้ไขข้อมูลเอกสารเรียบร้อยแล้ว'),
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
    final isEdit = widget.existingDoc != null;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.folder_shared_rounded, color: Color(0xFF1E3A8A), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEdit ? 'แก้ไขเอกสารความปลอดภัยผู้รับเหมา' : 'อัปโหลดเอกสาร JSA / ความปลอดภัยผู้รับเหมา',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.blue.shade800, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'รองรับไฟล์ PDF และภาพถ่าย/ภาพสแกนเอกสาร Hard copy (JPG, PNG) ระบบจะจัดเก็บสำเนาไฟล์ไว้ในคลังข้อมูลอย่างปลอดภัย',
                          style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 1. ข้อมูลผู้รับเหมาและงาน
                _buildSectionHeader('๑. ข้อมูลผู้รับเหมาและโครงการ'),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _contractorNameController,
                        decoration: _inputDecoration('ชื่อบริษัทผู้รับเหมา *', icon: Icons.business),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อผู้รับเหมา' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _documentType,
                        decoration: _inputDecoration('ประเภทเอกสาร *', icon: Icons.category),
                        items: _docTypes.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _documentType = v);
                        },
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
                        controller: _projectTitleController,
                        decoration: _inputDecoration('ชื่องาน / โครงการ / กิจกรรม *', icon: Icons.construction),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่องาน/โครงการ' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _workLocationController,
                        decoration: _inputDecoration('สถานที่ / แผนก / พื้นที่', icon: Icons.place_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. วันที่และผู้ประเมิน
                _buildSectionHeader('๒. วันที่และผู้ประเมิน'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _assessmentDateController,
                        readOnly: true,
                        onTap: () => _selectDate(_assessmentDateController),
                        decoration: _inputDecoration('วันที่จัดทำ / ประเมิน *', icon: Icons.calendar_today),
                        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุวันที่' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _validUntilDateController,
                        readOnly: true,
                        onTap: () => _selectDate(_validUntilDateController),
                        decoration: _inputDecoration('วันที่สิ้นสุด / ทบทวน', icon: Icons.event_available),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _assessorNameController,
                        decoration: _inputDecoration('ผู้ประเมิน / จป. ผู้รับเหมา', icon: Icons.person_outline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. แนบไฟล์เอกสาร
                _buildSectionHeader('๓. ไฟล์เอกสารแนบ (PDF / รูปภาพสแกน Hard copy)'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                        label: const Text('เลือกไฟล์ PDF หรือรูปถ่ายสแกน Hard copy', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Attached files preview list
                      if (_existingFilePaths.isEmpty && _newFilePathsToUpload.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text(
                              'ยังไม่มีไฟล์ที่เลือก (สามารถเลือกได้หลายไฟล์พร้อมกัน)',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ),
                        )
                      else ...[
                        // Existing files
                        ..._existingFilePaths.map((filePath) => _buildFileItem(
                              filePath: filePath,
                              isExisting: true,
                              onRemove: () {
                                setState(() {
                                  _existingFilePaths.remove(filePath);
                                });
                              },
                            )),
                        // New picked files
                        ..._newFilePathsToUpload.map((filePath) => _buildFileItem(
                              filePath: filePath,
                              isExisting: false,
                              onRemove: () {
                                setState(() {
                                  _newFilePathsToUpload.remove(filePath);
                                });
                              },
                            )),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. หมายเหตุเพิ่มเติม
                _buildSectionHeader('๔. หมายเหตุ / ข้อความเพิ่มเติม'),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: _inputDecoration('หมายเหตุเพิ่มเติม (เช่น สภาพหน้างาน, มาตรการพิเศษ)', icon: Icons.notes),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกเอกสาร'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
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

  Widget _buildFileItem({
    required String filePath,
    required bool isExisting,
    required VoidCallback onRemove,
  }) {
    final fileName = p.basename(filePath);
    final ext = p.extension(filePath).toLowerCase();
    final isPdf = ext == '.pdf';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isPdf ? Colors.red.shade200 : Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
            color: isPdf ? Colors.red.shade700 : Colors.blue.shade700,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  isExisting ? 'บันทึกในคลังแล้ว' : 'เตรียมอัปโหลด',
                  style: TextStyle(fontSize: 10, color: isExisting ? Colors.green.shade700 : Colors.orange.shade700),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            tooltip: 'ลบไฟล์นี้',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            onPressed: onRemove,
          ),
        ],
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
