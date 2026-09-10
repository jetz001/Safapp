import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/thai_address_cascade_widget.dart';
import '../../../risk_assessment/domain/models/risk_assessment_models.dart';
import '../../../risk_assessment/domain/models/risk_matrix_criteria.dart';
import '../../../risk_assessment/presentation/providers/risk_assessment_providers.dart';

class SmsSetupPage extends ConsumerStatefulWidget {
  const SmsSetupPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SmsSetupPage> createState() => _SmsSetupPageState();
}

class _SmsSetupPageState extends ConsumerState<SmsSetupPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // 1. General & Employer
  late TextEditingController _companyNameController;
  late TextEditingController _employerNameController;
  late TextEditingController _taxIdController;
  late TextEditingController _employeeCountController;
  late TextEditingController _areaSqmController;

  // 2. Schedule Category (กระทรวงแรงงาน)
  int _selectedSchedule = 2; // 1 = บัญชี ๑, 2 = บัญชี ๒
  String? _selectedCategoryTitle;

  // 3. Address & Contacts
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

  // 4. Safety Expert (ผู้ชำนาญการ ม.๓๓)
  late TextEditingController _safetyExpertNameController;
  late TextEditingController _safetyExpertLicenseNoController;
  late TextEditingController _safetyExpertValidFromController;
  late TextEditingController _safetyExpertValidToController;

  // 5. Safety Officer (จป. เจ้าหน้าที่ความปลอดภัยในการทำงาน)
  late TextEditingController _safetyOfficerNameController;
  String _safetyOfficerLevel = 'จป.วิชาชีพ';
  late TextEditingController _safetyOfficerCertNoController;
  late TextEditingController _safetyOfficerPhoneController;

  // 6. Policy & Goals
  late TextEditingController _safetyPolicyController;

  int? _profileId;
  String? _logoPath;
  CompanyProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _employerNameController = TextEditingController();
    _taxIdController = TextEditingController();
    _employeeCountController = TextEditingController(text: '0');
    _areaSqmController = TextEditingController();

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

    _safetyOfficerNameController = TextEditingController();
    _safetyOfficerCertNoController = TextEditingController();
    _safetyOfficerPhoneController = TextEditingController();

    _safetyPolicyController = TextEditingController();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    try {
      final profile = forceRefresh
          ? await ref.refresh(companyProfileNotifierProvider.future)
          : await ref.read(companyProfileNotifierProvider.future);
      if (profile != null && mounted) {
        setState(() {
          _populateFields(profile);
        });
      }
    } catch (_) {
      // Fallback to read
      final profileAsync = ref.read(companyProfileNotifierProvider);
      profileAsync.whenData((profile) {
        if (profile != null && mounted) {
          setState(() {
            _populateFields(profile);
          });
        }
      });
    }
  }

  void _populateFields(CompanyProfile profile) {
    _currentProfile = profile;
    _profileId = profile.id;
    _logoPath = profile.logoPath;

    _companyNameController.text = profile.companyName;
    _employerNameController.text = profile.employerName ?? '';
    _taxIdController.text = profile.taxId ?? '';
    _employeeCountController.text = profile.employeeCount > 0 ? '${profile.employeeCount}' : '';
    _areaSqmController.text = profile.areaSqm != null ? '${profile.areaSqm}' : '';

    _selectedSchedule = profile.businessCategorySchedule > 0 ? profile.businessCategorySchedule : 2;
    final categoriesList = _selectedSchedule == 1
        ? RiskMatrixCriteria.schedule1Categories
        : RiskMatrixCriteria.schedule2Categories;
    final validCategory = categoriesList.contains(profile.businessCategoryTitle)
        ? profile.businessCategoryTitle
        : (categoriesList.isNotEmpty ? categoriesList.first : null);
    _selectedCategoryTitle = validCategory;

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

    _safetyOfficerNameController.text = profile.safetyOfficerName ?? '';
    if (profile.safetyOfficerLevel != null && profile.safetyOfficerLevel!.isNotEmpty) {
      _safetyOfficerLevel = profile.safetyOfficerLevel!;
    } else {
      _safetyOfficerLevel = 'จป.วิชาชีพ';
    }
    _safetyOfficerCertNoController.text = profile.safetyOfficerCertNo ?? '';
    _safetyOfficerPhoneController.text = profile.safetyOfficerPhone ?? '';
    _safetyPolicyController.text = profile.safetyPolicy ?? '';
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _employerNameController.dispose();
    _taxIdController.dispose();
    _employeeCountController.dispose();
    _areaSqmController.dispose();

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

    _safetyOfficerNameController.dispose();
    _safetyOfficerCertNoController.dispose();
    _safetyOfficerPhoneController.dispose();

    _safetyPolicyController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final originalPath = result.files.single.path!;
        final appDocDir = await getApplicationDocumentsDirectory();
        final logoFolder = Directory('${appDocDir.path}\\SafetySuperapp\\Logos');
        if (!await logoFolder.exists()) {
          await logoFolder.create(recursive: true);
        }

        final ext = p.extension(originalPath);
        final newFileName = 'company_logo_${DateTime.now().millisecondsSinceEpoch}$ext';
        final targetPath = '${logoFolder.path}\\$newFileName';
        
        final savedFile = await File(originalPath).copy(targetPath);

        if (!mounted) return;
        setState(() {
          _logoPath = savedFile.path;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อัปโหลดโลโก้สำเร็จ (อย่าลืมกด "บันทึกข้อมูลองค์กร")'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกไฟล์: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _removeLogo() {
    setState(() {
      _logoPath = null;
    });
  }

  Future<void> _save() async {
    final currentTabIndex = _tabController.index;

    // Smart Cross-Tab Validation
    if (_companyNameController.text.trim().isEmpty) {
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกชื่อบริษัท / สถานประกอบการ ในแท็บ "๑. ข้อมูลทั่วไป & ประเภทกิจการ"'),
          backgroundColor: Colors.amber,
        ),
      );
      _formKey.currentState?.validate();
      return;
    }

    if (_provinceController.text.trim().isEmpty ||
        _districtController.text.trim().isEmpty ||
        _subdistrictController.text.trim().isEmpty) {
      _tabController.animateTo(1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาระบุที่ตั้งสถานประกอบการ (จังหวัด, อำเภอ, ตำบล) ในแท็บ "๒. ที่ตั้ง & ข้อมูลติดต่อ"'),
          backgroundColor: Colors.amber,
        ),
      );
      _formKey.currentState?.validate();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final updatedProfile = CompanyProfile(
      id: _profileId,
      companyName: _companyNameController.text.trim(),
      employerName: _employerNameController.text.trim(),
      taxId: _taxIdController.text.trim(),
      businessCategorySchedule: _selectedSchedule,
      businessCategoryTitle: _selectedCategoryTitle,
      employeeCount: int.tryParse(_employeeCountController.text.trim()) ?? 0,
      areaSqm: double.tryParse(_areaSqmController.text.trim()),
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
      safetyOfficerName: _safetyOfficerNameController.text.trim(),
      safetyOfficerLevel: _safetyOfficerLevel,
      safetyOfficerCertNo: _safetyOfficerCertNoController.text.trim(),
      safetyOfficerPhone: _safetyOfficerPhoneController.text.trim(),
      safetyPolicy: _safetyPolicyController.text.trim(),
      logoPath: _logoPath,
    );

    await ref.read(companyProfileNotifierProvider.notifier).saveProfile(updatedProfile);
    _currentProfile = updatedProfile;
    _profileId = updatedProfile.id;

    if (mounted && _tabController.index != currentTabIndex) {
      _tabController.index = currentTabIndex;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกข้อมูลองค์กรและข้อมูล จป./สถานประกอบการเรียบร้อยแล้ว (เชื่อมต่อข้อมูลกลางสำเร็จ)'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<CompanyProfile?>>(companyProfileNotifierProvider, (_, next) {
      next.whenData((profile) {
        if (profile != null) {
          if (_currentProfile == null && _companyNameController.text.isEmpty) {
            _populateFields(profile);
            setState(() {});
          }
        }
      });
    });

    final profileAsync = ref.watch(companyProfileNotifierProvider);
    final categories = _selectedSchedule == 1
        ? RiskMatrixCriteria.schedule1Categories
        : RiskMatrixCriteria.schedule2Categories;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('ข้อมูลองค์กร & สถานประกอบกิจการ (SMS Context)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => _loadData(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('รีเซ็ตข้อมูลเดิม'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('บันทึกข้อมูลองค์กร', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
      body: profileAsync.when(
        skipLoadingOnReload: true,
        data: (profile) {
          if (profile != null && _companyNameController.text.isEmpty && _currentProfile == null) {
            _populateFields(profile);
          }

          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 4.0),
                  child: const Text(
                    'ตั้งค่าระบบการจัดการความปลอดภัย (Safety Management System) - ฐานข้อมูลกลางเชื่อมต่อการประเมินความเสี่ยง ปอ.๑ และ ปอ.๒ ทุกโมดูล',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Tab Bar ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: GlassContainer(
                    borderRadius: BorderRadius.circular(14),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.business_rounded, size: 18),
                          text: '๑. ข้อมูลทั่วไป & ประเภทกิจการ',
                        ),
                        Tab(
                          icon: Icon(Icons.location_on_rounded, size: 18),
                          text: '๒. ที่ตั้ง & ข้อมูลติดต่อ',
                        ),
                        Tab(
                          icon: Icon(Icons.shield_rounded, size: 18),
                          text: '๓. จป., ผู้ชำนาญการ & นโยบาย',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Tab Views ────────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: ข้อมูลทั่วไป & ประเภทกิจการ
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                        child: _buildGeneralAndCategoryTab(categories),
                      ),
                      // Tab 2: ที่ตั้ง & ข้อมูลติดต่อ
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                        child: _buildAddressAndContactTab(),
                      ),
                      // Tab 3: จป., ผู้ชำนาญการ & นโยบาย
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                        child: _buildPersonnelAndPolicyTab(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
      ),
    );
  }

  // ── Tab 1: ข้อมูลทั่วไป & ประเภทกิจการ ────────────────────────────────────
  Widget _buildGeneralAndCategoryTab(List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. ข้อมูลทั่วไปและโลโก้
        _buildSectionCard(
          title: '๑. ข้อมูลทั่วไปของสถานประกอบการ & นายจ้าง',
          icon: Icons.business,
          children: [
            Center(
              child: Stack(
                children: [
                  InkWell(
                    onTap: _pickLogo,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _logoPath != null && File(_logoPath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.file(
                                  File(_logoPath!),
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                          : const Icon(Icons.domain, size: 44, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(color: Color(0xFF1E3A8A), shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        tooltip: 'เลือกรูปโลโก้',
                        onPressed: _pickLogo,
                      ),
                    ),
                  ),
                  if (_logoPath != null && File(_logoPath!).existsSync())
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 14),
                          tooltip: 'ลบโลโก้',
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                          padding: EdgeInsets.zero,
                          onPressed: _removeLogo,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: _pickLogo,
                icon: const Icon(Icons.image, size: 14),
                label: Text(
                  _logoPath == null ? 'คลิกเพื่อเลือกไฟล์โลโก้' : 'เปลี่ยนรูปโลโก้',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'ชื่อบริษัท / สถานประกอบการ *',
              Icons.business_center,
              controller: _companyNameController,
              validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อสถานประกอบการ' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'ชื่อ-นามสกุล นายจ้าง / ผู้มีอำนาจลงนาม',
              Icons.person_pin,
              controller: _employerNameController,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'เลขประจำตัวผู้เสียภาษี / เลขทะเบียนนิติบุคคล',
              Icons.tag,
              controller: _taxIdController,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        'จำนวนลูกจ้างรวมของสถานประกอบการ (คน) *',
                        Icons.people,
                        controller: _employeeCountController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                      _buildStatutoryCriteriaChips(
                        int.tryParse(_employeeCountController.text.trim()) ?? 0,
                        _selectedSchedule,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    'พื้นที่สถานประกอบการ (ตารางเมตร)',
                    Icons.square_foot,
                    controller: _areaSqmController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. บัญชีประเภทกิจการตามประกาศกระทรวงแรงงาน
        _buildSectionCard(
          title: '๒. ประเภทกิจการตามประกาศกระทรวงแรงงาน (๒๕๖๗)',
          icon: Icons.category_rounded,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('บัญชี ๑ (๕ ประเภท - ๒ คนขึ้นไป)'),
                  selected: _selectedSchedule == 1,
                  onSelected: (sel) {
                    if (sel) {
                      setState(() {
                        _selectedSchedule = 1;
                        _selectedCategoryTitle = null;
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('บัญชี ๒ (๔๙ ประเภท - ๒๐ คนขึ้นไป)'),
                  selected: _selectedSchedule == 2,
                  onSelected: (sel) {
                    if (sel) {
                      setState(() {
                        _selectedSchedule = 2;
                        _selectedCategoryTitle = RiskMatrixCriteria.schedule2Categories[18];
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: categories.contains(_selectedCategoryTitle)
                  ? _selectedCategoryTitle
                  : (_selectedSchedule == 2 && categories.contains(RiskMatrixCriteria.schedule2Categories[18])
                      ? RiskMatrixCriteria.schedule2Categories[18]
                      : null),
              decoration: InputDecoration(
                labelText: 'เลือกประเภทอุตสาหกรรม/กิจการ ตามบัญชีท้ายประกาศ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.5),
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
          ],
        ),
        const SizedBox(height: 24),

        // Navigation to Next Tab
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('ถัดไป: ที่ตั้ง & ข้อมูลติดต่อ', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Tab 2: ที่ตั้ง & ข้อมูลติดต่อ ────────────────────────────────────────
  Widget _buildAddressAndContactTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 3. ที่ตั้งสถานประกอบกิจการ
        _buildSectionCard(
          title: '๓. ที่ตั้งสถานประกอบกิจการ & ข้อมูลติดต่อ',
          icon: Icons.location_on,
          children: [
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
          ],
        ),
        const SizedBox(height: 24),

        // Navigation Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('ก่อนหน้า: ข้อมูลทั่วไป'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(2),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('ถัดไป: จป., ผู้ชำนาญการ & นโยบาย', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Tab 3: จป., ผู้ชำนาญการ & นโยบาย ──────────────────────────────────
  Widget _buildPersonnelAndPolicyTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 4. ผู้ชำนาญการด้านความปลอดภัยฯ (มาตรา ๓๓)
        _buildSectionCard(
          title: '๔. ผู้ชำนาญการด้านความปลอดภัยฯ ที่ได้รับใบอนุญาต (ม.๓๓)',
          icon: Icons.verified_user_rounded,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    'ชื่อ-นามสกุล ผู้ชำนาญการฯ',
                    Icons.badge,
                    controller: _safetyExpertNameController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    'เลขที่ใบอนุญาต (กสร.)',
                    Icons.card_membership,
                    controller: _safetyExpertLicenseNoController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'วันที่ได้รับอนุญาต (วัน/เดือน/ปี เช่น 01/01/2567)',
                    Icons.calendar_today,
                    controller: _safetyExpertValidFromController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    'วันที่สิ้นสุดใบอนุญาต (วัน/เดือน/ปี เช่น 31/12/2569)',
                    Icons.event_busy,
                    controller: _safetyExpertValidToController,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 5. เจ้าหน้าที่ความปลอดภัยในการทำงาน (จป.)
        _buildSectionCard(
          title: '๕. เจ้าหน้าที่ความปลอดภัยในการทำงาน (จป.) ประจำสถานประกอบการ',
          icon: Icons.health_and_safety_rounded,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    'ชื่อ-นามสกุล จป. (ผู้ประเมินหลัก)',
                    Icons.person,
                    controller: _safetyOfficerNameController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _safetyOfficerLevel,
                    decoration: InputDecoration(
                      labelText: 'ระดับ จป.',
                      prefixIcon: const Icon(Icons.stars, color: Colors.amber, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.6),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'จป.วิชาชีพ', child: Text('จป.วิชาชีพ', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'จป.เทคนิคขั้นสูง', child: Text('จป.เทคนิคขั้นสูง', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'จป.เทคนิค', child: Text('จป.เทคนิค', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'จป.บริหาร', child: Text('จป.บริหาร', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'จป.หัวหน้างาน', child: Text('จป.หัวหน้างาน', style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _safetyOfficerLevel = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'เลขที่ขึ้นทะเบียน / เลขที่ใบประกาศนียบัตร จป.',
                    Icons.badge_outlined,
                    controller: _safetyOfficerCertNoController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    'เบอร์โทรศัพท์ติดต่อ จป.',
                    Icons.phone_in_talk,
                    controller: _safetyOfficerPhoneController,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 6. นโยบายและเป้าหมายความปลอดภัย
        _buildSectionCard(
          title: '๖. นโยบายและเป้าหมายความปลอดภัย',
          icon: Icons.policy,
          children: [
            _buildTextField(
              'คำประกาศนโยบายความปลอดภัย (Safety Policy)',
              Icons.article,
              controller: _safetyPolicyController,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            const Text(
              'เป้าหมายด้านความปลอดภัย (Safety Objectives)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            _buildGoalItem('เป้าหมายอุบัติเหตุถึงขั้นหยุดงาน (LTI)', '0 ครั้ง/ปี'),
            const SizedBox(height: 8),
            _buildGoalItem('เป้าหมายการฝึกอบรม', '100% ของพนักงาน'),
            const SizedBox(height: 8),
            _buildGoalItem('ความถี่ในการตรวจพื้นที่ (Audit)', 'สัปดาห์ละ 1 ครั้ง'),
          ],
        ),
        const SizedBox(height: 24),

        // Navigation & Save Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('ก่อนหน้า: ที่ตั้ง & ข้อมูลติดต่อ'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('บันทึกข้อมูลองค์กรทั้งหมด', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return GlassContainer(
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon, {
    TextEditingController? controller,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.grey.shade400, size: 18) : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.6),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }

  Widget _buildStatutoryCriteriaChips(int count, int schedule) {
    final isSmsMandatory = (schedule == 1 && count >= 2) || (schedule == 2 && count >= 20);
    String cpoText;
    if (count >= 500) {
      cpoText = 'โควตา คปอ. ๑๑ คน (≥ ๕๐๐ คน)';
    } else if (count >= 100) {
      cpoText = 'โควตา คปอ. ๗ คน (๑๐๐-๔๙๙ คน)';
    } else if (count >= 50) {
      cpoText = 'โควตา คปอ. ๕ คน (๕๐-๙๙ คน)';
    } else {
      cpoText = 'ไม่บังคับ คปอ. (< ๕๐ คน)';
    }

    String safetyOfficerTier;
    if (count >= 100) {
      safetyOfficerTier = 'จป.วิชาชีพ เต็มเวลา (≥ ๑๐๐ คน)';
    } else if (count >= 50) {
      safetyOfficerTier = 'จป.เทคนิคขั้นสูง/วิชาชีพ (๕๐-๙๙ คน)';
    } else if (count >= 20) {
      safetyOfficerTier = 'จป.เทคนิค (๒๐-๔๙ คน)';
    } else {
      safetyOfficerTier = 'จป.หัวหน้างาน & บริหาร (≥ ๒ คน)';
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_rounded, size: 14, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 6),
              Text(
                'เกณฑ์ประเมินข้อกำหนดกฎหมาย (คำนวณจากลูกจ้างรวม $count คน):',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildCriteriaBadge(
                isSmsMandatory ? 'เข้าข่ายจัดทำระบบ SMS (กฎกระทรวงฯ ๒๕๖๕)' : 'ไม่เข้าข่าย SMS ภาคบังคับ',
                isSmsMandatory ? const Color(0xFF10B981) : const Color(0xFF64748B),
                Icons.check_circle_outline_rounded,
              ),
              _buildCriteriaBadge(
                cpoText,
                count >= 50 ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
                Icons.groups_rounded,
              ),
              _buildCriteriaBadge(
                safetyOfficerTier,
                const Color(0xFF8B5CF6),
                Icons.badge_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(value, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
