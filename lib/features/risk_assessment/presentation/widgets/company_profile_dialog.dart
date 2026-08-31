import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/thai_address_cascade_widget.dart';
import '../../domain/models/risk_assessment_models.dart';
import '../../domain/models/risk_matrix_criteria.dart';
import '../providers/risk_assessment_providers.dart';

class CompanyProfileDialog extends ConsumerStatefulWidget {
  const CompanyProfileDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<CompanyProfileDialog> createState() => _CompanyProfileDialogState();
}

class _CompanyProfileDialogState extends ConsumerState<CompanyProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyNameController;
  late TextEditingController _employerNameController;
  late TextEditingController _taxIdController;
  late TextEditingController _employeeCountController;
  late TextEditingController _addressNumberController;
  late TextEditingController _mooController;
  late TextEditingController _soiController;
  late TextEditingController _roadController;
  late TextEditingController _subdistrictController;
  late TextEditingController _districtController;
  late TextEditingController _provinceController;
  late TextEditingController _postalCodeController;
  late TextEditingController _phoneController;
  late TextEditingController _faxController;
  late TextEditingController _mobileController;

  // ผู้ชำนาญการ ม.๓๓
  late TextEditingController _safetyExpertNameController;
  late TextEditingController _safetyExpertLicenseNoController;
  late TextEditingController _safetyExpertValidFromController;
  late TextEditingController _safetyExpertValidToController;

  int _selectedSchedule = 2; // 1 = บัญชี ๑, 2 = บัญชี ๒
  String? _selectedCategoryTitle;
  int? _profileId;

  String? _logoPath;
  String? _safetyPolicy;
  double? _areaSqm;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadInitialData();
  }

  void _initControllers() {
    _companyNameController = TextEditingController();
    _employerNameController = TextEditingController();
    _taxIdController = TextEditingController();
    _employeeCountController = TextEditingController(text: '0');
    _addressNumberController = TextEditingController();
    _mooController = TextEditingController();
    _soiController = TextEditingController();
    _roadController = TextEditingController();
    _subdistrictController = TextEditingController();
    _districtController = TextEditingController();
    _provinceController = TextEditingController();
    _postalCodeController = TextEditingController();
    _phoneController = TextEditingController();
    _faxController = TextEditingController();
    _mobileController = TextEditingController();

    _safetyExpertNameController = TextEditingController();
    _safetyExpertLicenseNoController = TextEditingController();
    _safetyExpertValidFromController = TextEditingController();
    _safetyExpertValidToController = TextEditingController();
  }

  void _loadInitialData() {
    final profileAsync = ref.read(companyProfileNotifierProvider);
    profileAsync.whenData((profile) {
      if (profile != null) {
        _profileId = profile.id;
        _logoPath = profile.logoPath;
        _safetyPolicy = profile.safetyPolicy;
        _areaSqm = profile.areaSqm;

        _companyNameController.text = profile.companyName;
        _employerNameController.text = profile.employerName ?? '';
        _taxIdController.text = profile.taxId ?? '';
        _employeeCountController.text = '${profile.employeeCount}';
        _addressNumberController.text = profile.addressNumber ?? '';
        _mooController.text = profile.moo ?? '';
        _soiController.text = profile.soi ?? '';
        _roadController.text = profile.road ?? '';
        _subdistrictController.text = profile.subdistrict ?? '';
        _districtController.text = profile.district ?? '';
        _provinceController.text = profile.province ?? '';
        _postalCodeController.text = profile.postalCode ?? '';
        _phoneController.text = profile.phone ?? '';
        _faxController.text = profile.fax ?? '';
        _mobileController.text = profile.mobile ?? '';

        _safetyExpertNameController.text = profile.safetyExpertName ?? '';
        _safetyExpertLicenseNoController.text = profile.safetyExpertLicenseNo ?? '';
        _safetyExpertValidFromController.text = profile.safetyExpertValidFrom ?? '';
        _safetyExpertValidToController.text = profile.safetyExpertValidTo ?? '';

        _selectedSchedule = profile.businessCategorySchedule;
        _selectedCategoryTitle = profile.businessCategoryTitle;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _employerNameController.dispose();
    _taxIdController.dispose();
    _employeeCountController.dispose();
    _addressNumberController.dispose();
    _mooController.dispose();
    _soiController.dispose();
    _roadController.dispose();
    _subdistrictController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _faxController.dispose();
    _mobileController.dispose();
    _safetyExpertNameController.dispose();
    _safetyExpertLicenseNoController.dispose();
    _safetyExpertValidFromController.dispose();
    _safetyExpertValidToController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = CompanyProfile(
      id: _profileId,
      companyName: _companyNameController.text.trim(),
      employerName: _employerNameController.text.trim(),
      taxId: _taxIdController.text.trim(),
      businessCategorySchedule: _selectedSchedule,
      businessCategoryTitle: _selectedCategoryTitle,
      employeeCount: int.tryParse(_employeeCountController.text.trim()) ?? 0,
      addressNumber: _addressNumberController.text.trim(),
      moo: _mooController.text.trim(),
      soi: _soiController.text.trim(),
      road: _roadController.text.trim(),
      subdistrict: _subdistrictController.text.trim(),
      district: _districtController.text.trim(),
      province: _provinceController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      phone: _phoneController.text.trim(),
      fax: _faxController.text.trim(),
      mobile: _mobileController.text.trim(),
      safetyExpertName: _safetyExpertNameController.text.trim(),
      safetyExpertLicenseNo: _safetyExpertLicenseNoController.text.trim(),
      safetyExpertValidFrom: _safetyExpertValidFromController.text.trim(),
      safetyExpertValidTo: _safetyExpertValidToController.text.trim(),
      safetyPolicy: _safetyPolicy,
      areaSqm: _areaSqm,
      logoPath: _logoPath,
    );

    await ref.read(companyProfileNotifierProvider.notifier).saveProfile(profile);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลสถานประกอบการและผู้ชำนาญการเรียบร้อยแล้ว')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _selectedSchedule == 1
        ? RiskMatrixCriteria.schedule1Categories
        : RiskMatrixCriteria.schedule2Categories;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.business_rounded, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ข้อมูลสถานประกอบกิจการ & ผู้ชำนาญการ (ตามประกาศกระทรวงแรงงาน)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: ข้อมูลสถานประกอบกิจการ
                      _buildSectionHeader('๑. ข้อมูลสถานประกอบกิจการ & นายจ้าง'),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _companyNameController,
                              decoration: const InputDecoration(
                                labelText: 'ชื่อสถานประกอบกิจการ *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อสถานประกอบการ' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _employerNameController,
                              decoration: const InputDecoration(
                                labelText: 'ชื่อ-นามสกุล นายจ้าง / ผู้มีอำนาจลงนาม',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _taxIdController,
                              decoration: const InputDecoration(
                                labelText: 'เลขทะเบียนนิติบุคคล / เลขประจำตัวผู้เสียภาษี',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _employeeCountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'จำนวนลูกจ้างรวม (คน)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Schedule Selection
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          const Text('บัญชีประเภทกิจการ: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ChoiceChip(
                            label: const Text('บัญชี ๑ (๕ ประเภท - บังคับตั้งแต่ ๒ คน)'),
                            selected: _selectedSchedule == 1,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedSchedule = 1;
                                  _selectedCategoryTitle = null;
                                });
                              }
                            },
                          ),
                          ChoiceChip(
                            label: const Text('บัญชี ๒ (๔๙ ประเภท - บังคับตั้งแต่ ๒๐ คน)'),
                            selected: _selectedSchedule == 2,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedSchedule = 2;
                                  _selectedCategoryTitle = null;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: categories.contains(_selectedCategoryTitle) ? _selectedCategoryTitle : null,
                        decoration: const InputDecoration(
                          labelText: 'เลือกประเภทอุตสาหกรรม/กิจการ ตามบัญชีท้ายประกาศ',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: categories.map((c) {
                          return DropdownMenuItem<String>(
                            value: c,
                            child: Text(c, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategoryTitle = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address
                      _buildSectionHeader('๒. ที่ตั้งสถานประกอบกิจการ'),
                      ThaiAddressCascadeWidget(
                        addressNumberController: _addressNumberController,
                        mooController: _mooController,
                        soiController: _soiController,
                        roadController: _roadController,
                        subdistrictController: _subdistrictController,
                        districtController: _districtController,
                        provinceController: _provinceController,
                        postalCodeController: _postalCodeController,
                        phoneController: _phoneController,
                        faxController: _faxController,
                        mobileController: _mobileController,
                      ),
                      const SizedBox(height: 16),

                      // Section 3: ผู้ชำนาญการ ม.๓๓
                      _buildSectionHeader('๓. ข้อมูลผู้ชำนาญการด้านความปลอดภัยฯ ที่ได้รับใบอนุญาต (มาตรา ๓๓)'),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(_safetyExpertNameController, 'ชื่อ-นามสกุล ผู้ชำนาญการฯ'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _buildTextField(_safetyExpertLicenseNoController, 'เลขที่ใบอนุญาตผู้ชำนาญการ'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _safetyExpertValidFromController,
                              'วันที่ได้รับอนุญาต (วัน/เดือน/ปี เช่น 01/01/2567)',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              _safetyExpertValidToController,
                              'วันที่สิ้นสุดใบอนุญาต (วัน/เดือน/ปี เช่น 31/12/2569)',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ยกเลิก'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('บันทึกข้อมูล'),
                    onPressed: _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade900),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
