import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../data/models/sop_model.dart';

class SopEditorDialog extends StatefulWidget {
  final SopModel? existing;
  final void Function(SopModel sop) onSave;

  const SopEditorDialog({
    super.key,
    this.existing,
    required this.onSave,
  });

  @override
  State<SopEditorDialog> createState() => _SopEditorDialogState();
}

class _SopEditorDialogState extends State<SopEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _revisionCtrl;
  late TextEditingController _purposeCtrl;
  late TextEditingController _scopeCtrl;
  late TextEditingController _precautionsCtrl;
  late TextEditingController _emergencyCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _reviewerCtrl;
  late TextEditingController _approverCtrl;

  late String _category;
  late String _status;
  late DateTime _effectiveDate;
  late DateTime _reviewDueDate;
  late List<String> _selectedPpe;
  late List<SopStepModel> _steps;
  String? _pdfFilePath;

  static const List<Map<String, dynamic>> _availablePpe = [
    {'id': 'HELMET', 'label': 'หมวกนิรภัย', 'icon': Icons.engineering},
    {'id': 'SAFETY_GLASSES', 'label': 'แว่นตานิรภัย', 'icon': Icons.visibility},
    {'id': 'EAR_PLUGS', 'label': 'ที่อุดหู', 'icon': Icons.hearing},
    {'id': 'GLOVES', 'label': 'ถุงมือนิรภัย', 'icon': Icons.pan_tool},
    {'id': 'BOOTS', 'label': 'รองเท้าหัวเหล็ก', 'icon': Icons.hiking},
    {'id': 'HARNESS', 'label': 'ชุดกันตก (Harness)', 'icon': Icons.accessibility_new},
    {'id': 'RESPIRATOR', 'label': 'หน้ากากกรองอากาศ', 'icon': Icons.masks},
    {'id': 'FACE_SHIELD', 'label': 'กระบังหน้า', 'icon': Icons.face},
    {'id': 'HI_VIS_VEST', 'label': 'เสื้อสะท้อนแสง', 'icon': Icons.health_and_safety},
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _codeCtrl = TextEditingController(text: item?.docCode ?? '');
    _titleCtrl = TextEditingController(text: item?.title ?? '');
    _revisionCtrl = TextEditingController(text: item?.revision ?? 'Rev. 01');
    _purposeCtrl = TextEditingController(text: item?.purpose ?? '');
    _scopeCtrl = TextEditingController(text: item?.scope ?? '');
    _precautionsCtrl = TextEditingController(text: item?.precautions ?? '');
    _emergencyCtrl = TextEditingController(text: item?.emergencyProcedure ?? '');
    _authorCtrl = TextEditingController(text: item?.author ?? '');
    _reviewerCtrl = TextEditingController(text: item?.reviewer ?? '');
    _approverCtrl = TextEditingController(text: item?.approver ?? '');

    _category = item?.category ?? 'MACHINERY';
    _status = item?.status ?? 'ACTIVE';
    _effectiveDate = item?.effectiveDate ?? DateTime.now();
    _reviewDueDate = item?.reviewDueDate ?? DateTime.now().add(const Duration(days: 365));
    _selectedPpe = List.from(item?.requiredPpeList ?? []);
    _steps = List.from(item?.steps ?? []);
    _pdfFilePath = item?.pdfFilePath;

    if (_steps.isEmpty) {
      _steps.add(const SopStepModel(
        stepNumber: 1,
        title: 'การเตรียมการก่อนเริ่มปฏิบัติงาน',
        action: 'ตรวจสอบพื้นที่และอุปกรณ์ความปลอดภัยก่อนเริ่มงาน',
        safetyCheckpoint: 'สวมใส่อุปกรณ์ PPE ครบถ้วนตามมาตรฐาน',
      ));
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _titleCtrl.dispose();
    _revisionCtrl.dispose();
    _purposeCtrl.dispose();
    _scopeCtrl.dispose();
    _precautionsCtrl.dispose();
    _emergencyCtrl.dispose();
    _authorCtrl.dispose();
    _reviewerCtrl.dispose();
    _approverCtrl.dispose();
    super.dispose();
  }

  void _addStep() {
    setState(() {
      _steps.add(SopStepModel(
        stepNumber: _steps.length + 1,
        title: 'ขั้นตอนที่ ${_steps.length + 1}',
        action: '',
        safetyCheckpoint: '',
      ));
    });
  }

  void _removeStep(int index) {
    if (_steps.length <= 1) return;
    setState(() {
      _steps.removeAt(index);
      for (int i = 0; i < _steps.length; i++) {
        _steps[i] = SopStepModel(
          stepNumber: i + 1,
          title: _steps[i].title,
          action: _steps[i].action,
          safetyCheckpoint: _steps[i].safetyCheckpoint,
        );
      }
    });
  }

  Future<void> _pickPdf() async {
    final res = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (res != null && res.files.single.path != null) {
      setState(() {
        _pdfFilePath = res.files.single.path;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final sop = SopModel(
      id: widget.existing?.id,
      docCode: _codeCtrl.text.trim(),
      title: _titleCtrl.text.trim(),
      category: _category,
      revision: _revisionCtrl.text.trim().isEmpty ? 'Rev. 01' : _revisionCtrl.text.trim(),
      effectiveDate: _effectiveDate,
      reviewDueDate: _reviewDueDate,
      purpose: _purposeCtrl.text.trim().isEmpty ? null : _purposeCtrl.text.trim(),
      scope: _scopeCtrl.text.trim().isEmpty ? null : _scopeCtrl.text.trim(),
      requiredPpeList: _selectedPpe,
      precautions: _precautionsCtrl.text.trim().isEmpty ? null : _precautionsCtrl.text.trim(),
      steps: _steps,
      emergencyProcedure: _emergencyCtrl.text.trim().isEmpty ? null : _emergencyCtrl.text.trim(),
      pdfFilePath: _pdfFilePath,
      author: _authorCtrl.text.trim().isEmpty ? null : _authorCtrl.text.trim(),
      reviewer: _reviewerCtrl.text.trim().isEmpty ? null : _reviewerCtrl.text.trim(),
      approver: _approverCtrl.text.trim().isEmpty ? null : _approverCtrl.text.trim(),
      status: _status,
    );

    widget.onSave(sop);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 820,
        height: 750,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_document, color: Color(0xFF0284C7), size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  isNew ? 'สร้างคู่มือขั้นตอนปฏิบัติงานใหม่ (New SOP)' : 'แก้ไขขั้นตอนปฏิบัติงาน (${widget.existing!.docCode})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'ปิด',
                )
              ],
            ),
            const Divider(height: 24),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info Card
                      _buildSectionTitle('๑. ข้อมูลทั่วไปของเอกสาร (Document Header)'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _codeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'รหัสเอกสาร (Doc Code) *',
                                hintText: 'เช่น SOP-MCH-002',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุรหัสเอกสาร' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              controller: _titleCtrl,
                              decoration: const InputDecoration(
                                labelText: 'ชื่อขั้นตอนการปฏิบัติงาน (SOP Title) *',
                                hintText: 'เช่น ขั้นตอนการใช้งานและตรวจสอบรอกไฟฟ้า',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อเรื่อง' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _revisionCtrl,
                              decoration: const InputDecoration(
                                labelText: 'เวอร์ชัน (Revision)',
                                hintText: 'Rev. 01',
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
                            child: DropdownButtonFormField<String>(
                              initialValue: _category,
                              decoration: const InputDecoration(labelText: 'หมวดหมู่งานความปลอดภัย *', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'MACHINERY', child: Text('เครื่องจักร & ปั้นจั่น')),
                                DropdownMenuItem(value: 'ELECTRICAL', child: Text('ระบบไฟฟ้า & LOTO')),
                                DropdownMenuItem(value: 'CHEMICAL', child: Text('สารเคมีอันตราย')),
                                DropdownMenuItem(value: 'CONFINED_SPACE', child: Text('ที่อับอากาศ')),
                                DropdownMenuItem(value: 'HEIGHTS', child: Text('ทำงานบนที่สูง')),
                                DropdownMenuItem(value: 'EMERGENCY', child: Text('ระงับอัคคีภัย & ฉุกเฉิน')),
                                DropdownMenuItem(value: 'PPE', child: Text('อุปกรณ์คุ้มครอง PPE')),
                                DropdownMenuItem(value: 'GENERAL', child: Text('ความปลอดภัยทั่วไป')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _category = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _status,
                              decoration: const InputDecoration(labelText: 'สถานะการใช้งาน *', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'ACTIVE', child: Text('ใช้งานอยู่ (Active)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                                DropdownMenuItem(value: 'DRAFT', child: Text('ฉบับร่าง (Draft)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                                DropdownMenuItem(value: 'ARCHIVED', child: Text('ยกเลิก/จัดเก็บ (Archived)', style: TextStyle(color: Colors.grey))),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _status = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('วันที่มีผลบังคับใช้ (Effective Date)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              subtitle: Text(
                                _effectiveDate.toIso8601String().substring(0, 10),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              trailing: const Icon(Icons.calendar_today, size: 20),
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _effectiveDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (d != null) setState(() => _effectiveDate = d);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('กำหนดทบทวนประจำปี (Review Due Date)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              subtitle: Text(
                                _reviewDueDate.toIso8601String().substring(0, 10),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              trailing: const Icon(Icons.event_repeat, size: 20),
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _reviewDueDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (d != null) setState(() => _reviewDueDate = d);
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      // PPE Checklist
                      _buildSectionTitle('๒. อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคลที่จำเป็น (Required PPE)'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availablePpe.map((ppe) {
                          final isSelected = _selectedPpe.contains(ppe['id']);
                          return FilterChip(
                            avatar: Icon(
                              ppe['icon'] as IconData,
                              size: 18,
                              color: isSelected ? Colors.white : Colors.blueGrey,
                            ),
                            label: Text(ppe['label'] as String),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0284C7),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedPpe.add(ppe['id'] as String);
                                } else {
                                  _selectedPpe.remove(ppe['id']);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),
                      // Objective & Precautions
                      _buildSectionTitle('๓. วัตถุประสงค์และข้อควรระวังสำคัญ (Purpose & Hazards)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _purposeCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'วัตถุประสงค์และขอบเขต (Purpose & Scope)',
                          hintText: 'เพื่อกำหนดขั้นตอนการทำงานที่ปลอดภัยและลดความเสี่ยง...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _precautionsCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'อันตรายสำคัญและข้อควรระวัง (Critical Hazards & Golden Rules)',
                          hintText: '• ห้ามเดินใต้แนวรัศมีชิ้นงาน\n• ต้องสวมใส่อุปกรณ์ PPE ตลอดเวลา',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),
                      // Step by step builder
                      Row(
                        children: [
                          _buildSectionTitle('๔. ขั้นตอนการปฏิบัติงาน (Step-by-Step Operating Procedures)'),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _addStep,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('เพิ่มขั้นตอน (+)', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _steps.length,
                        itemBuilder: (ctx, i) {
                          final step = _steps[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: const Color(0xFF0284C7),
                                        child: Text('${step.stepNumber}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: step.title,
                                          decoration: const InputDecoration(
                                            labelText: 'ชื่อขั้นตอน',
                                            isDense: true,
                                            border: UnderlineInputBorder(),
                                          ),
                                          onChanged: (v) {
                                            _steps[i] = SopStepModel(
                                              stepNumber: step.stepNumber,
                                              title: v,
                                              action: step.action,
                                              safetyCheckpoint: step.safetyCheckpoint,
                                            );
                                          },
                                        ),
                                      ),
                                      if (_steps.length > 1)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                          onPressed: () => _removeStep(i),
                                          tooltip: 'ลบขั้นตอนนี้',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: step.action,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      labelText: 'วิธีและคำอธิบายการปฏิบัติงาน',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (v) {
                                      _steps[i] = SopStepModel(
                                        stepNumber: step.stepNumber,
                                        title: step.title,
                                        action: v,
                                        safetyCheckpoint: step.safetyCheckpoint,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: step.safetyCheckpoint,
                                    decoration: const InputDecoration(
                                      labelText: 'จุดตรวจความปลอดภัย (Safety Checkpoint)',
                                      hintText: 'เช่น ตรวจสอบสลักนิรภัย, วัดแรงดัน = 0V',
                                      prefixIcon: Icon(Icons.check_circle_outline, color: Color(0xFF0284C7), size: 18),
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (v) {
                                      _steps[i] = SopStepModel(
                                        stepNumber: step.stepNumber,
                                        title: step.title,
                                        action: step.action,
                                        safetyCheckpoint: v,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),
                      // Emergency & First Aid
                      _buildSectionTitle('๕. การระงับเหตุฉุกเฉินและการปฐมพยาบาล (Emergency Procedures)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emergencyCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'ข้อปฏิบัติเมื่อเกิดเหตุฉุกเฉิน / เบอร์ติดต่อ',
                          hintText: 'กรณีเกิดเหตุฉุกเฉิน ให้กดปุ่ม Emergency Stop และแจ้ง จป. โทร...',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),
                      // PDF Attachment
                      _buildSectionTitle('๖. เอกสารคู่มือ PDF แนบ (Attached PDF File)'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickPdf,
                            icon: const Icon(Icons.picture_as_pdf, size: 18),
                            label: Text(_pdfFilePath == null ? 'เลือกไฟล์ PDF แนบ' : 'เปลี่ยนไฟล์ PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_pdfFilePath != null) ...[
                            Expanded(
                              child: Text(
                                p.basename(_pdfFilePath!),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _pdfFilePath = null),
                              icon: const Icon(Icons.clear, color: Colors.red, size: 18),
                              tooltip: 'ลบไฟล์แนบ',
                            ),
                          ] else
                            const Text('ยังไม่ได้แนบไฟล์ PDF', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),

                      const SizedBox(height: 16),
                      // Approvals
                      _buildSectionTitle('๗. ผู้จัดทำและผู้อนุมัติ (Document Governance)'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _authorCtrl,
                              decoration: const InputDecoration(labelText: 'ผู้จัดทำ (Author)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _reviewerCtrl,
                              decoration: const InputDecoration(labelText: 'ผู้ตรวจสอบ (Reviewer / จป.)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _approverCtrl,
                              decoration: const InputDecoration(labelText: 'ผู้อนุมัติ (Approver)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('บันทึกเอกสาร SOP', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
    );
  }
}
