import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/chemical_inventory_model.dart';
import '../../domain/models/chemical_master_model.dart';
import 'chemical_autocomplete_field.dart';
import 'ghs_pictogram_selector.dart';
import 'nfpa_diamond_widget.dart';

/// Form dialog for adding or editing a workplace hazardous chemical inventory item.
class ChemicalInventoryFormDialog extends StatefulWidget {
  final ChemicalInventoryItem? initialItem;
  final Future<void> Function(ChemicalInventoryItem item, String? newSdsPath, String? newLabelPath) onSave;

  const ChemicalInventoryFormDialog({
    Key? key,
    this.initialItem,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ChemicalInventoryFormDialog> createState() => _ChemicalInventoryFormDialogState();
}

class _ChemicalInventoryFormDialogState extends State<ChemicalInventoryFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _tradeNameController;
  late TextEditingController _nameThController;
  late TextEditingController _nameEnController;
  late TextEditingController _casController;
  late TextEditingController _unController;
  late TextEditingController _locationController;
  late TextEditingController _quantityController;
  late TextEditingController _maxCapacityController;
  late TextEditingController _containerTypeController;
  late TextEditingController _supplierController;
  late TextEditingController _hazardClassController;
  late TextEditingController _registerDateController;
  late TextEditingController _sdsDateController;
  late TextEditingController _notesController;

  String _physicalState = 'LIQUID';
  String _unit = 'L';
  int _sdsExpiryYears = 3;
  String _status = 'ACTIVE';

  List<String> _selectedGhs = [];
  int _nfpaHealth = 0;
  int _nfpaFlammability = 0;
  int _nfpaInstability = 0;
  String _nfpaSpecial = '';

  String? _currentSdsPath;
  String? _newSdsPath;
  String? _currentLabelPath;
  String? _newLabelPath;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;

    _tradeNameController = TextEditingController(text: item?.tradeName ?? '');
    _nameThController = TextEditingController(text: item?.chemicalNameTh ?? '');
    _nameEnController = TextEditingController(text: item?.chemicalNameEn ?? '');
    _casController = TextEditingController(text: item?.casNumber ?? '');
    _unController = TextEditingController(text: item?.unNumber ?? '');
    _locationController = TextEditingController(text: item?.storageLocation ?? 'คลังสารเคมีหลัก');
    _quantityController = TextEditingController(text: item?.quantity.toString() ?? '0');
    _maxCapacityController = TextEditingController(text: item?.maxCapacity?.toString() ?? '');
    _containerTypeController = TextEditingController(text: item?.containerType ?? 'ถังเหล็ก 200 ลิตร (Drums)');
    _supplierController = TextEditingController(text: item?.manufacturerSupplier ?? '');
    _hazardClassController = TextEditingController(text: item?.hazardClass ?? 'สารไวไฟ (Flammable)');
    _registerDateController = TextEditingController(
      text: item?.registerDate ?? DateTime.now().toIso8601String().substring(0, 10),
    );
    _sdsDateController = TextEditingController(
      text: item?.sdsIssueDate ?? DateTime.now().toIso8601String().substring(0, 10),
    );
    _notesController = TextEditingController(text: item?.notes ?? '');

    if (item != null) {
      _physicalState = item.physicalState;
      _unit = item.unit;
      _sdsExpiryYears = item.sdsExpiryYears;
      _status = item.status;
      _selectedGhs = List.from(item.ghsPictograms);
      _nfpaHealth = item.nfpaHealth ?? 0;
      _nfpaFlammability = item.nfpaFlammability ?? 0;
      _nfpaInstability = item.nfpaInstability ?? 0;
      _nfpaSpecial = item.nfpaSpecial ?? '';
      _currentSdsPath = item.sdsFilePath;
      _currentLabelPath = item.labelImagePath;
    }
  }

  @override
  void dispose() {
    _tradeNameController.dispose();
    _nameThController.dispose();
    _nameEnController.dispose();
    _casController.dispose();
    _unController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    _maxCapacityController.dispose();
    _containerTypeController.dispose();
    _supplierController.dispose();
    _hazardClassController.dispose();
    _registerDateController.dispose();
    _sdsDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onMasterChemicalSelected(ChemicalMasterItem master) {
    setState(() {
      if (_tradeNameController.text.isEmpty) {
        _tradeNameController.text = master.thaiName;
      }
      _nameThController.text = master.thaiName;
      _nameEnController.text = master.englishName;
      _casController.text = master.casNumber;
      if (master.unNumber != null && master.unNumber!.isNotEmpty) {
        _unController.text = master.unNumber!;
      }
      if (master.hazardCategory != null && master.hazardCategory!.isNotEmpty) {
        _hazardClassController.text = master.hazardCategory!;
      }
    });
  }

  Future<void> _pickSdsFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        setState(() {
          _newSdsPath = result.files.single.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking SDS file: $e');
    }
  }

  Future<void> _pickLabelImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        setState(() {
          _newLabelPath = result.files.single.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking label image: $e');
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initialDate = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final qty = double.tryParse(_quantityController.text) ?? 0.0;
      final maxCap = double.tryParse(_maxCapacityController.text);

      final item = ChemicalInventoryItem(
        id: widget.initialItem?.id,
        seqNo: widget.initialItem?.seqNo,
        tradeName: _tradeNameController.text.trim(),
        chemicalNameTh: _nameThController.text.trim(),
        chemicalNameEn: _nameEnController.text.trim(),
        casNumber: _casController.text.trim(),
        unNumber: _unController.text.trim().isEmpty ? null : _unController.text.trim(),
        storageLocation: _locationController.text.trim(),
        physicalState: _physicalState,
        quantity: qty,
        unit: _unit,
        maxCapacity: maxCap,
        containerType: _containerTypeController.text.trim().isEmpty ? null : _containerTypeController.text.trim(),
        manufacturerSupplier: _supplierController.text.trim().isEmpty ? null : _supplierController.text.trim(),
        hazardClass: _hazardClassController.text.trim().isEmpty ? null : _hazardClassController.text.trim(),
        ghsPictograms: _selectedGhs,
        registerDate: _registerDateController.text.trim(),
        sdsIssueDate: _sdsDateController.text.trim(),
        sdsExpiryYears: _sdsExpiryYears,
        sdsFilePath: _newSdsPath ?? _currentSdsPath,
        labelImagePath: _newLabelPath ?? _currentLabelPath,
        nfpaHealth: _nfpaHealth,
        nfpaFlammability: _nfpaFlammability,
        nfpaInstability: _nfpaInstability,
        nfpaSpecial: _nfpaSpecial.isEmpty ? null : _nfpaSpecial,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        status: _status,
      );

      await widget.onSave(item, _newSdsPath, _newLabelPath);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialItem != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        width: 880,
        constraints: const BoxConstraints(maxHeight: 880),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'แก้ไขข้อมูลสารเคมีในครอบครอง' : 'ขึ้นทะเบียนสารเคมีอันตรายใหม่ (Chemical Register)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'ตามกฎกระทรวงสารเคมีอันตราย พ.ศ. ๒๕๕๖ และแบบ สอ.๑ กรมสวัสดิการและคุ้มครองแรงงาน',
                          style: TextStyle(fontSize: 11, color: Color(0xFFBFDBFE)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Master Lookup
                      _buildSectionHeader('๑. ค้นหาและระบุสารเคมี (Hazardous Chemical Identification)', Icons.science_rounded),
                      const SizedBox(height: 10),
                      ChemicalAutocompleteField(
                        initialValue: _nameThController.text.isNotEmpty ? '${_nameThController.text} (${_nameEnController.text})' : null,
                        onSelected: _onMasterChemicalSelected,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _tradeNameController,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาระบุชื่อทางการค้า' : null,
                              decoration: _inputDecoration('ชื่อทางการค้า / ชื่อผลิตภัณฑ์ (Trade Name)*', Icons.label_important_outline_rounded),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _casController,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาระบุ CAS No.' : null,
                              decoration: _inputDecoration('CAS Number*', Icons.fingerprint_rounded),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _unController,
                              decoration: _inputDecoration('UN Number', Icons.local_shipping_outlined),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameThController,
                              decoration: _inputDecoration('ชื่อทางเคมีภาษาไทย (Chemical Name TH)', Icons.translate_rounded),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _nameEnController,
                              decoration: _inputDecoration('ชื่อทางเคมีภาษาอังกฤษ (Chemical Name EN)', Icons.language_rounded),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 2: Storage & Quantity
                      _buildSectionHeader('๒. การจัดเก็บ ปริมาณ และบรรจุภัณฑ์ (Storage & Inventory)', Icons.inventory_2_rounded),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _locationController,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาระบุสถานที่จัดเก็บ' : null,
                              decoration: _inputDecoration('สถานที่จัดเก็บ (Storage Location)*', Icons.location_on_outlined),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _physicalState,
                              isExpanded: true,
                              decoration: _inputDecoration('สถานะทางกายภาพ', Icons.bubble_chart_outlined),
                              items: const [
                                DropdownMenuItem(value: 'LIQUID', child: Text('ของเหลว (Liquid)', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'SOLID', child: Text('ของแข็ง (Solid)', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'GAS', child: Text('ก๊าซ (Gas)', overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (val) => setState(() => _physicalState = val ?? 'LIQUID'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _supplierController,
                              decoration: _inputDecoration('ผู้ผลิต / ผู้จัดจำหน่าย', Icons.business_rounded),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'กรุณาระบุปริมาณ';
                                if (double.tryParse(v) == null) return 'ตัวเลขไม่ถูกต้อง';
                                return null;
                              },
                              decoration: _inputDecoration('ปริมาณที่มีในครอบครอง*', Icons.scale_rounded),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: ['L', 'kg', 'ตัน (Tons)', 'ถัง (Drums)', 'ท่อ (Cylinders)', 'แกลลอน (Gallons)'].contains(_unit) ? _unit : 'L',
                              isExpanded: true,
                              decoration: _inputDecoration('หน่วยนับ (Unit)', Icons.straighten_rounded),
                              items: const [
                                DropdownMenuItem(value: 'L', child: Text('ลิตร (L)', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'kg', child: Text('กิโลกรัม (kg)', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'ตัน (Tons)', child: Text('ตัน (Tons)', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'ถัง (Drums)', child: Text('ถัง (Drums)', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'ท่อ (Cylinders)', child: Text('ท่อ (Cylinders)', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'แกลลอน (Gallons)', child: Text('แกลลอน (Gallons)', overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (val) => setState(() => _unit = val ?? 'L'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _maxCapacityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: _inputDecoration('ความจุสูงสุดของสถานที่', Icons.pie_chart_outline_rounded),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _containerTypeController,
                              decoration: _inputDecoration('ประเภทภาชนะบรรจุ', Icons.inventory_outlined),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 3: SDS Lifecycle Tracking & Attachments
                      _buildSectionHeader('๓. การติดตามเอกสาร SDS และไฟล์แนบ (SDS Lifecycle Tracking)', Icons.assignment_turned_in_rounded),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _registerDateController,
                              readOnly: true,
                              onTap: () => _pickDate(_registerDateController),
                              decoration: _inputDecoration('วันที่ขึ้นทะเบียนสารเคมี', Icons.calendar_today_rounded),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _sdsDateController,
                              readOnly: true,
                              onTap: () => _pickDate(_sdsDateController),
                              decoration: _inputDecoration('วันที่จัดทำ/ทบทวน SDS ล่าสุด*', Icons.event_available_rounded),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int>(
                              value: _sdsExpiryYears,
                              isExpanded: true,
                              decoration: _inputDecoration('รอบการทบทวน SDS', Icons.update_rounded),
                              items: const [
                                DropdownMenuItem(value: 3, child: Text('ทุก ๓ ปี (มาตรฐาน)', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 5, child: Text('ทุก ๕ ปี (สูงสุด)', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 1, child: Text('ทุก ๑ ปี (เข้มงวด)', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 2, child: Text('ทุก ๒ ปี', overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (val) => setState(() => _sdsExpiryYears = val ?? 3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _status,
                              isExpanded: true,
                              decoration: _inputDecoration('สถานะสารเคมี', Icons.toggle_on_outlined),
                              items: const [
                                DropdownMenuItem(value: 'ACTIVE', child: Text('🟢 ใช้งานปกติ (Active)', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'INACTIVE', child: Text('🟡 พักการใช้ (Inactive)', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'DISPOSED', child: Text('🔴 จำหน่ายทิ้งแล้ว', overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (val) => setState(() => _status = val ?? 'ACTIVE'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Document Attachment Pickers
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF1E3A8A), size: 28),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('เอกสาร Safety Data Sheet (SDS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        Text(
                                          _newSdsPath != null
                                              ? 'เลือกใหม่: ${p.basename(_newSdsPath!)}'
                                              : (_currentSdsPath != null ? p.basename(_currentSdsPath!) : 'ยังไม่ได้แนบเอกสาร SDS'),
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _pickSdsFile,
                                    icon: const Icon(Icons.attach_file_rounded, size: 16),
                                    label: const Text('เลือกไฟล์ SDS', style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      backgroundColor: const Color(0xFF1E3A8A),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.teal.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.image_rounded, color: Color(0xFF0D9488), size: 28),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('รูปถ่ายฉลากสารเคมี / บรรจุภัณฑ์', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        Text(
                                          _newLabelPath != null
                                              ? 'เลือกใหม่: ${p.basename(_newLabelPath!)}'
                                              : (_currentLabelPath != null ? p.basename(_currentLabelPath!) : 'ยังไม่ได้แนบรูปถ่ายฉลาก'),
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _pickLabelImage,
                                    icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                                    label: const Text('เลือกรูปถ่าย', style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      backgroundColor: const Color(0xFF0D9488),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 4: GHS Pictograms & NFPA 704
                      _buildSectionHeader('๔. การบ่งชี้ความเป็นอันตราย (GHS & NFPA 704 Hazard Rating)', Icons.security_rounded),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: GhsPictogramSelector(
                              selectedCodes: _selectedGhs,
                              onChanged: (codes) => setState(() => _selectedGhs = codes),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'ระดับอันตราย NFPA 704 Diamond',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 8),
                                NfpaDiamondWidget(
                                  health: _nfpaHealth,
                                  flammability: _nfpaFlammability,
                                  instability: _nfpaInstability,
                                  special: _nfpaSpecial,
                                  size: 130,
                                  isInteractive: true,
                                  onChanged: (h, f, i, s) {
                                    setState(() {
                                      _nfpaHealth = h;
                                      _nfpaFlammability = f;
                                      _nfpaInstability = i;
                                      _nfpaSpecial = s;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 5: Notes
                      _buildSectionHeader('๕. บันทึกเพิ่มเติม / ข้อกำหนดพิเศษ (Notes & Remarks)', Icons.note_alt_outlined),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: _inputDecoration('บันทึกข้อควรระวังพิเศษ, อุปกรณ์ PPE บังคับ, หรือหมายเหตุการใช้งาน', Icons.edit_note_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('ยกเลิก'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded),
                    label: Text(isEdit ? 'บันทึกการแก้ไข' : 'ขึ้นทะเบียนสารเคมี'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1E3A8A)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.8),
      ),
    );
  }
}
