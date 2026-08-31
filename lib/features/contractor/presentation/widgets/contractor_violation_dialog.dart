import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/contractor_models.dart';
import '../providers/contractor_providers.dart';

class ContractorViolationDialog extends ConsumerStatefulWidget {
  final int? preselectedContractorId;

  const ContractorViolationDialog({
    Key? key,
    this.preselectedContractorId,
  }) : super(key: key);

  @override
  ConsumerState<ContractorViolationDialog> createState() => _ContractorViolationDialogState();
}

class _ContractorViolationDialogState extends ConsumerState<ContractorViolationDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _dateController;
  late TextEditingController _descriptionController;
  late TextEditingController _actionTakenController;
  late TextEditingController _scoreDeductedController;
  late TextEditingController _inspectorNameController;

  int? _selectedContractorId;
  int? _selectedWorkerId;
  String _violationType = 'ไม่สวมใส่อุปกรณ์คุ้มครองความปลอดภัย (PPE)';
  String _severityLevel = 'MODERATE';
  bool _isSaving = false;

  final List<String> _violationTypes = [
    'ไม่สวมใส่อุปกรณ์คุ้มครองความปลอดภัย (PPE)',
    'ฝ่าฝืนข้อกำหนดใบอนุญาตทำงาน (PTW)',
    'การกระทำที่ไม่ปลอดภัยร้ายแรง (Unsafe Act)',
    'การใช้อุปกรณ์ / เครื่องจักร / นั่งร้านชำรุด',
    'ไม่ปฏิบัติตามขั้นตอน JSA / SOPs ที่กำหนด',
    'การสูบบุหรี่หรือก่อประกายไฟในพื้นที่หวงห้าม',
    'นำสารเคมีอันตรายเข้าพื้นที่โดยไม่มี SDS / การขออนุญาต',
    'อื่นๆ',
  ];

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    _descriptionController = TextEditingController();
    _actionTakenController = TextEditingController(text: 'ออกใบสั่งตักเตือน พร้อมให้หยุดงานแก้ไขทันที');
    _scoreDeductedController = TextEditingController(text: '5');
    _inspectorNameController = TextEditingController(text: 'จป.วิชาชีพ ประจำโรงงาน');
    _selectedContractorId = widget.preselectedContractorId;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _descriptionController.dispose();
    _actionTakenController.dispose();
    _scoreDeductedController.dispose();
    _inspectorNameController.dispose();
    super.dispose();
  }

  void _onSeverityChanged(String? level) {
    if (level == null) return;
    setState(() {
      _severityLevel = level;
      switch (level) {
        case 'MINOR':
          _scoreDeductedController.text = '2';
          _actionTakenController.text = 'ตักเตือนด้วยวาจา และแก้ไขหน้างานทันที';
          break;
        case 'MODERATE':
          _scoreDeductedController.text = '5';
          _actionTakenController.text = 'ออกใบสั่งตักเตือนลายลักษณ์อักษร (Safety Warning)';
          break;
        case 'SEVERE':
          _scoreDeductedController.text = '15';
          _actionTakenController.text = 'สั่งหยุดงานชั่วคราว พร้อมเรียกผู้ควบคุมงานชี้แจง';
          break;
        case 'CRITICAL':
          _scoreDeductedController.text = '25';
          _actionTakenController.text = 'ระงับการปฏิบัติงานทันที และนำเข้าพิจารณาสถานะผู้รับเหมา';
          break;
      }
    });
  }

  Future<void> _selectDate() async {
    DateTime initial = DateTime.tryParse(_dateController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedContractorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกบริษัทผู้รับเหมา'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final violation = ContractorViolation(
        contractorId: _selectedContractorId!,
        workerId: _selectedWorkerId,
        incidentDate: _dateController.text.trim(),
        violationType: _violationType,
        severityLevel: _severityLevel,
        description: _descriptionController.text.trim(),
        actionTaken: _actionTakenController.text.trim(),
        scoreDeducted: int.tryParse(_scoreDeductedController.text.trim()) ?? 0,
        inspectorName: _inspectorNameController.text.trim().isEmpty ? null : _inspectorNameController.text.trim(),
      );

      await ref.read(contractorViolationsProvider.notifier).saveViolation(violation);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('บันทึกการตักเตือนและตัดคะแนนความปลอดภัยเรียบร้อยแล้ว'),
            backgroundColor: Colors.orange.shade800,
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
    final companiesAsync = ref.watch(contractorCompaniesProvider);
    final workersAsync = ref.watch(contractorWorkersProvider);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade800, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'ออกใบตักเตือนความปลอดภัย (Safety Violation Notice)',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader('๑. ข้อมูลผู้รับเหมาและผู้กระทำผิด'),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: companiesAsync.when(
                        data: (companies) {
                          if (_selectedContractorId == null && companies.isNotEmpty) {
                            _selectedContractorId = companies.first.id;
                          }
                          return DropdownButtonFormField<int>(
                            isExpanded: true,
                            value: _selectedContractorId,
                            decoration: _inputDecoration('บริษัทผู้รับเหมา *', icon: Icons.business),
                            items: companies.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text(c.companyName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _selectedContractorId = v;
                                  _selectedWorkerId = null;
                                });
                              }
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: workersAsync.when(
                        data: (workers) {
                          final filtered = _selectedContractorId != null
                              ? workers.where((w) => w.contractorId == _selectedContractorId).toList()
                              : workers;
                          return DropdownButtonFormField<int?>(
                            isExpanded: true,
                            value: _selectedWorkerId,
                            decoration: _inputDecoration('คนงานผู้กระทำผิด (ถ้ามี)', icon: Icons.person_outline),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('- ทั้งบริษัท / ไม่ระบุคน -', style: TextStyle(fontSize: 12))),
                              ...filtered.map((w) {
                                return DropdownMenuItem(
                                  value: w.id,
                                  child: Text(w.workerName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                );
                              }),
                            ],
                            onChanged: (v) => setState(() => _selectedWorkerId = v),
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildSectionHeader('๒. รายละเอียดการกระทำผิด & ความรุนแรง'),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _violationType,
                        decoration: _inputDecoration('ประเภทการฝ่าฝืน *', icon: Icons.report_problem),
                        items: _violationTypes.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _violationType = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _severityLevel,
                        decoration: _inputDecoration('ระดับความรุนแรง *', icon: Icons.speed),
                        items: const [
                          DropdownMenuItem(value: 'MINOR', child: Text('🟢 เล็กน้อย (Minor)')),
                          DropdownMenuItem(value: 'MODERATE', child: Text('🟡 ปานกลาง (Moderate)')),
                          DropdownMenuItem(value: 'SEVERE', child: Text('🟠 ร้ายแรง (Severe)')),
                          DropdownMenuItem(value: 'CRITICAL', child: Text('🔴 วิกฤต (Critical)')),
                        ],
                        onChanged: _onSeverityChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: _selectDate,
                        decoration: _inputDecoration('วันที่พบการกระทำผิด *', icon: Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _scoreDeductedController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('คะแนนที่ตัด (คะแนน)', icon: Icons.remove_circle_outline),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _inspectorNameController,
                        decoration: _inputDecoration('ผู้ตรวจพบ / จป.', icon: Icons.security),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: _inputDecoration('รายละเอียดเหตุการณ์ / สภาพที่พบ *', icon: Icons.description),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุรายละเอียด' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _actionTakenController,
                  maxLines: 2,
                  decoration: _inputDecoration('มาตรการดำเนินการ / การแก้ไขทันที *', icon: Icons.fact_check_outlined),
                  validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุมาตรการดำเนินการ' : null,
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
              : const Icon(Icons.warning_rounded, size: 18),
          label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกใบตักเตือน'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
