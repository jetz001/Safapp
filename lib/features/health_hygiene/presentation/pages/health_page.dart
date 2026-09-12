import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/health_models.dart';
import '../providers/health_providers.dart';
import '../widgets/health_record_form_dialog.dart';
import '../widgets/bulk_report_upload_dialog.dart';
import '../widgets/followup_action_dialog.dart';
import '../widgets/health_report_viewer_dialog.dart';
import '../../services/health_official_pdf_service.dart';
import '../../services/health_excel_service.dart';
import '../../../employee/domain/models/employee_models.dart';
import '../../../employee/presentation/providers/employee_providers.dart';
import '../../../risk_assessment/presentation/providers/risk_assessment_providers.dart';

class HealthPage extends ConsumerStatefulWidget {
  const HealthPage({super.key});

  @override
  ConsumerState<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends ConsumerState<HealthPage> {
  int _selectedTab = 0; // 0 = Individual Register, 1 = Bulk Reports, 2 = Surveillance, 3 = Official JorPhorSor1
  String _selectedTypeFilter = 'ALL';
  String _selectedResultFilter = 'ALL';
  String _selectedYearFilter = 'ALL';
  String _searchQuery = '';
  String _selectedFollowupFilter = 'ALL';

  List<String> _extractAvailableYears(List<EmployeeHealthRecord> records) {
    final currentYearCe = DateTime.now().year;
    final currentYearBe = currentYearCe + 543;
    final years = <String>{'$currentYearBe', '${currentYearBe - 1}'};

    for (final r in records) {
      if (r.checkupDate.isNotEmpty) {
        final parsedYear = int.tryParse(r.checkupDate.split('-').first);
        if (parsedYear != null) {
          final be = parsedYear > 2400 ? parsedYear : parsedYear + 543;
          years.add('$be');
        }
      }
    }
    final sorted = years.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  bool _recordMatchesYear(EmployeeHealthRecord r, String yearFilter) {
    if (yearFilter == 'ALL') return true;
    final targetBe = int.tryParse(yearFilter);
    if (targetBe == null) return true;
    final targetCe = targetBe > 2400 ? targetBe - 543 : targetBe;

    final recYear = int.tryParse(r.checkupDate.split('-').first);
    if (recYear == null) return false;
    final recCe = recYear > 2400 ? recYear - 543 : recYear;
    return recCe == targetCe;
  }

  String _recordYearBe(EmployeeHealthRecord r) {
    final recYear = int.tryParse(r.checkupDate.split('-').first);
    if (recYear == null) return '';
    final be = recYear > 2400 ? recYear : recYear + 543;
    return 'ปี $be';
  }

  Future<void> _handleDownloadTemplate() async {
    final currentYearCe = DateTime.now().year;
    final path = await HealthExcelService.downloadTemplate(year: currentYearCe);
    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึก Template ตรวจสุขภาพเรียบร้อยที่: $path'),
          backgroundColor: Colors.green.shade700,
          action: Platform.isWindows
              ? SnackBarAction(
                  label: 'เปิดโฟลเดอร์',
                  textColor: Colors.white,
                  onPressed: () {
                    Process.run('explorer.exe', ['/select,', path]);
                  },
                )
              : null,
        ),
      );
    }
  }

  Future<void> _handleImportExcel() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final healthRepo = ref.read(healthRepoProvider);
      final employeeRepo = ref.read(employeeRepoProvider);

      int? defaultYear;
      if (_selectedYearFilter != 'ALL') {
        final be = int.tryParse(_selectedYearFilter);
        if (be != null) defaultYear = be > 2400 ? be - 543 : be;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังนำเข้าข้อมูลผลตรวจสุขภาพ...'),
                ],
              ),
            ),
          ),
        ),
      );

      final importRes = await HealthExcelService.importHealthRecordsFromExcel(
        filePath,
        healthRepo,
        employeeRepo,
        defaultYear: defaultYear,
      );

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      ref.invalidate(healthRecordsProvider);
      ref.invalidate(employeesProvider);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  importRes.failedCount == 0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  color: importRes.failedCount == 0 ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text('ผลการนำเข้าข้อมูลตรวจสุขภาพ'),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ข้อมูลในไฟล์ทั้งหมด: ${importRes.totalRows} แถว'),
                  const SizedBox(height: 4),
                  Text('• นำเข้าสำเร็จ: ${importRes.successCount} รายการ',
                      style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                  if (importRes.failedCount > 0) ...[
                    const SizedBox(height: 4),
                    Text('• พบข้อผิดพลาด: ${importRes.failedCount} รายการ',
                        style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text('รายละเอียดข้อผิดพลาด:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: importRes.errorMessages.length,
                        itemBuilder: (_, i) => Text('• ${importRes.errorMessages[i]}',
                            style: TextStyle(fontSize: 11.5, color: Colors.red.shade900)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleExportExcel(List<EmployeeHealthRecord> records) async {
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีข้อมูลผลตรวจสุขภาพสำหรับส่งออก')),
      );
      return;
    }

    final path = await HealthExcelService.exportHealthRecordsToExcel(
      records,
      yearLabel: _selectedYearFilter == 'ALL' ? 'All' : _selectedYearFilter,
    );

    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ส่งออกข้อมูล Excel เรียบร้อยที่: $path'),
          backgroundColor: Colors.green.shade700,
          action: Platform.isWindows
              ? SnackBarAction(
                  label: 'เปิดโฟลเดอร์',
                  textColor: Colors.white,
                  onPressed: () {
                    Process.run('explorer.exe', ['/select,', path]);
                  },
                )
              : null,
        ),
      );
    }
  }

  void _openHealthRecordDialog({EmployeeHealthRecord? existingRecord, int? preselectedEmployeeId}) {
    showDialog(
      context: context,
      builder: (ctx) => HealthRecordFormDialog(
        existingRecord: existingRecord,
        preselectedEmployeeId: preselectedEmployeeId,
      ),
    );
  }

  void _openBulkUploadDialog({CompanyHealthBulkReport? existingReport}) {
    showDialog(
      context: context,
      builder: (ctx) => BulkReportUploadDialog(existingReport: existingReport),
    );
  }

  void _openFollowupDialog({
    required int healthRecordId,
    required int employeeId,
    String? initialSymptom,
    MedicalSurveillanceFollowup? existingFollowup,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => FollowupActionDialog(
        healthRecordId: healthRecordId,
        employeeId: employeeId,
        initialSymptom: initialSymptom,
        existingFollowup: existingFollowup,
      ),
    );
  }

  void _openPdfViewer({required String filePath, required String title, String? subtitle}) {
    showDialog(
      context: context,
      builder: (ctx) => HealthReportViewerDialog(
        filePath: filePath,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  void _deleteHealthRecord(EmployeeHealthRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบผลตรวจสุขภาพ'),
        content: Text('คุณต้องการลบผลตรวจสุขภาพของ "${record.employeeName ?? "พนักงาน"}" (${record.checkupDate}) หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (record.id != null) {
                await ref.read(healthRecordsProvider.notifier).deleteRecord(record.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบรายการเรียบร้อยแล้ว')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ลบข้อมูล'),
          ),
        ],
      ),
    );
  }

  void _deleteBulkReport(CompanyHealthBulkReport report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบเล่มรายงานภาพรวม'),
        content: Text('คุณต้องการลบเล่มรายงาน "${report.reportTitle}" หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (report.id != null) {
                await ref.read(companyBulkReportsProvider.notifier).deleteBulkReport(report.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบเล่มรายงานเรียบร้อยแล้ว')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ลบข้อมูล'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final healthRecordsAsync = ref.watch(healthRecordsProvider);
    final bulkReportsAsync = ref.watch(companyBulkReportsProvider);
    final followupsAsync = ref.watch(medicalFollowupsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------------------
            // 1. Hero Header Banner
            // ----------------------------------------------------------------
            _buildHeroBanner(),
            const SizedBox(height: 16),

            // ----------------------------------------------------------------
            // 2. Summary KPI Metrics
            // ----------------------------------------------------------------
            healthRecordsAsync.when(
              data: (records) => _buildKpiRow(records, bulkReportsAsync.asData?.value.length ?? 0),
              loading: () => const LinearProgressIndicator(),
              error: (err, stack) => const SizedBox(),
            ),
            const SizedBox(height: 16),

            // ----------------------------------------------------------------
            // 3. Segmented 4-Tab Navigation
            // ----------------------------------------------------------------
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      index: 0,
                      label: '📊 ผลตรวจรายคน & สมุดสุขภาพ',
                      count: healthRecordsAsync.asData?.value.length ?? 0,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabButton(
                      index: 1,
                      label: '📚 เล่มรายงานภาพรวม รพ. (Bulk)',
                      count: bulkReportsAsync.asData?.value.length ?? 0,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabButton(
                      index: 2,
                      label: '🩺 ติดตามอาการผิดปกติ (Surveillance)',
                      count: followupsAsync.asData?.value.length ?? 0,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabButton(
                      index: 3,
                      label: '📑 แบบรายงานราชการ (จผส. ๑)',
                      count: healthRecordsAsync.asData?.value.where((r) => r.overallResult == 'ABNORMAL' || r.overallResult == 'WATCH').length ?? 0,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ----------------------------------------------------------------
            // 4. Tab Body Content
            // ----------------------------------------------------------------
            if (_selectedTab == 0)
              _buildIndividualRegisterTab(healthRecordsAsync)
            else if (_selectedTab == 1)
              _buildBulkReportsTab(bulkReportsAsync)
            else if (_selectedTab == 2)
              _buildSurveillanceTab(followupsAsync)
            else
              _buildOfficialJorPhorSor1Tab(healthRecordsAsync, followupsAsync),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // HERO BANNER
  // ==========================================================================
  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.tealAccent, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ระบบตรวจสุขภาพพนักงานและอาชีวอนามัย (Occupational Health & Medical Surveillance)',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'ตรวจก่อนเข้างาน 30 วัน, ประจำปี, ตรวจตามปัจจัยเสี่ยง (สารเคมี/เสียงดัง/ปอด), เล่มรายงาน รพ. ภาพรวมและรายคน, สมุดสุขภาพประจำตัว และแบบ จผส. ๑',
                  style: TextStyle(color: Colors.blue.shade100, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _handleDownloadTemplate,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('ดาวน์โหลด Template'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _handleImportExcel,
                icon: const Icon(Icons.file_upload_rounded, size: 16),
                label: const Text('นำเข้า Excel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _openBulkUploadDialog(),
                icon: const Icon(Icons.menu_book_rounded, size: 16),
                label: const Text('อัปโหลดเล่มรวม รพ.'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openHealthRecordDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('บันทึกผลตรวจรายคน', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent.shade700,
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // KPI ROW
  // ==========================================================================
  Widget _buildKpiRow(List<EmployeeHealthRecord> records, int bulkReportsCount) {
    final yearFiltered = records.where((r) => _recordMatchesYear(r, _selectedYearFilter)).toList();
    final total = yearFiltered.length;
    final normal = yearFiltered.where((r) => r.overallResult == 'NORMAL').length;
    final watch = yearFiltered.where((r) => r.overallResult == 'WATCH').length;
    final abnormal = yearFiltered.where((r) => r.overallResult == 'ABNORMAL').length;

    return Row(
      children: [
        _buildKpiCard('ตรวจสุขภาพสะสม', '$total รายการ', Icons.medical_information_rounded, const Color(0xFF1E3A8A)),
        const SizedBox(width: 10),
        _buildKpiCard('ผลตรวจปกติ (Normal)', '$normal รายการ', Icons.check_circle_rounded, Colors.green.shade700),
        const SizedBox(width: 10),
        _buildKpiCard('เฝ้าระวัง (Watch)', '$watch รายการ', Icons.warning_amber_rounded, Colors.amber.shade800),
        const SizedBox(width: 10),
        _buildKpiCard('ผิดปกติ (Abnormal)', '$abnormal รายการ', Icons.error_outline_rounded, abnormal > 0 ? Colors.red.shade700 : Colors.grey.shade700),
        const SizedBox(width: 10),
        _buildKpiCard('เล่มรายงาน รพ. ภาพรวม', '$bulkReportsCount เล่ม', Icons.menu_book_rounded, const Color(0xFF0D9488)),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({required int index, required String label, required int count, required Color color}) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 1: INDIVIDUAL HEALTH REGISTER
  // ==========================================================================
  Widget _buildIndividualRegisterTab(AsyncValue<List<EmployeeHealthRecord>> healthRecordsAsync) {
    final employeesAsync = ref.watch(employeesProvider);
    final companyProfile = ref.watch(companyProfileNotifierProvider).asData?.value;

    return healthRecordsAsync.when(
      data: (records) {
        final availableYears = _extractAvailableYears(records);

        var filtered = records;
        if (_selectedYearFilter != 'ALL') {
          filtered = filtered.where((r) => _recordMatchesYear(r, _selectedYearFilter)).toList();
        }
        if (_selectedTypeFilter != 'ALL') {
          filtered = filtered.where((r) => r.checkupType == _selectedTypeFilter).toList();
        }
        if (_selectedResultFilter != 'ALL') {
          filtered = filtered.where((r) => r.overallResult == _selectedResultFilter).toList();
        }
        if (_searchQuery.isNotEmpty) {
          filtered = filtered.where((r) =>
              (r.employeeName ?? "").toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (r.employeeCode ?? "").toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (r.department ?? "").toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.hospitalName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'ค้นหาชื่อพนักงาน, รหัส, แผนก, โรงพยาบาล...',
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Year Filter Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedYearFilter,
                        icon: const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF1E3A8A)),
                        items: [
                          const DropdownMenuItem(value: 'ALL', child: Text('ทุกปี (All Years)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          ...availableYears.map((y) => DropdownMenuItem(value: y, child: Text('ปี พ.ศ. $y', style: const TextStyle(fontSize: 12)))),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedYearFilter = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedTypeFilter,
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('ประเภทการตรวจทั้งหมด')),
                      DropdownMenuItem(value: 'PRE_EMPLOYMENT', child: Text('ตรวจก่อนเข้างาน')),
                      DropdownMenuItem(value: 'ANNUAL', child: Text('ตรวจสุขภาพประจำปี')),
                      DropdownMenuItem(value: 'RISK_BASED', child: Text('ตรวจตามปัจจัยเสี่ยง')),
                      DropdownMenuItem(value: 'JOB_CHANGE', child: Text('ตรวจเมื่อเปลี่ยนงาน')),
                      DropdownMenuItem(value: 'RETURN_TO_WORK', child: Text('ตรวจก่อนกลับเข้าทำงาน')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedTypeFilter = v);
                    },
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedResultFilter,
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('ผลตรวจทั้งหมด')),
                      DropdownMenuItem(value: 'NORMAL', child: Text('🟢 ปกติ (Normal)')),
                      DropdownMenuItem(value: 'WATCH', child: Text('🟡 เฝ้าระวัง (Watch)')),
                      DropdownMenuItem(value: 'ABNORMAL', child: Text('🔴 ผิดปกติ (Abnormal)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedResultFilter = v);
                    },
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'ส่งออกข้อมูล Excel (${_selectedYearFilter == "ALL" ? "ทั้งหมด" : "ปี $_selectedYearFilter"})',
                    child: OutlinedButton.icon(
                      onPressed: () => _handleExportExcel(filtered),
                      icon: const Icon(Icons.file_download_outlined, size: 15),
                      label: const Text('Excel', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D9488),
                        side: const BorderSide(color: Color(0xFF0D9488)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (filtered.isEmpty)
              _buildEmptyState(
                icon: Icons.health_and_safety_outlined,
                title: 'ไม่พบประวัติการตรวจสุขภาพพนักงาน',
                subtitle: 'กดปุ่ม "ดาวน์โหลด Template" หรือ "นำเข้า Excel" ด้านบน เพื่อเริ่มบันทึกผลตรวจสุขภาพ',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final r = filtered[idx];
                  final hasPdf = r.pdfFilePath != null && r.pdfFilePath!.isNotEmpty;
                  final isAbnormal = r.overallResult == 'ABNORMAL' || r.overallResult == 'WATCH';

                  Color resultBg;
                  Color resultFg;
                  if (r.overallResult == 'NORMAL') {
                    resultBg = Colors.green.shade50;
                    resultFg = Colors.green.shade800;
                  } else if (r.overallResult == 'WATCH') {
                    resultBg = Colors.amber.shade50;
                    resultFg = Colors.amber.shade900;
                  } else {
                    resultBg = Colors.red.shade50;
                    resultFg = Colors.red.shade800;
                  }

                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: resultBg, borderRadius: BorderRadius.circular(10)),
                            child: Icon(
                              r.overallResult == 'NORMAL' ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                              color: resultFg,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${r.employeeCode ?? "-"} - ${r.employeeName ?? "พนักงาน"}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                      child: Text(r.checkupTypeLabel, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: resultBg, borderRadius: BorderRadius.circular(6)),
                                      child: Text(r.overallResultLabel, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: resultFg)),
                                    ),
                                    if (_recordYearBe(r).isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.25), width: 0.8),
                                        ),
                                        child: Text(_recordYearBe(r), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'แผนก: ${r.department ?? "-"}  |  ตำแหน่ง: ${r.position ?? "-"}  |  วันที่ตรวจ: ${r.checkupDate}  |  รพ.: ${r.hospitalName}',
                                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                      child: Text('BP: ${r.bpReading}', style: const TextStyle(fontSize: 10, color: Color(0xFF334155))),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                      child: Text('BMI: ${r.bmi?.toStringAsFixed(1) ?? "-"}', style: const TextStyle(fontSize: 10, color: Color(0xFF334155))),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                                      child: Text('ความพร้อม: ${r.fitnessLabel}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                                    ),
                                    if (hasPdf) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                                        child: const Text('📄 แนบเล่มเดี่ยวแล้ว', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Actions
                          Wrap(
                            spacing: 6,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  final empList = employeesAsync.asData?.value ?? [];
                                  final emp = empList.firstWhere((e) => e.id == r.employeeId, orElse: () => Employee(employeeCode: r.employeeCode ?? '-', fullName: r.employeeName ?? '-', department: r.department ?? '-', position: r.position ?? '-'));
                                  final empRecords = records.where((rec) => rec.employeeId == r.employeeId).toList();
                                  HealthOfficialPdfService.printElectronicHealthBook(
                                    context: context,
                                    employee: emp,
                                    healthRecords: empRecords,
                                    company: companyProfile,
                                  );
                                },
                                icon: const Icon(Icons.menu_book_rounded, size: 15),
                                label: const Text('สมุดสุขภาพ', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1E3A8A),
                                  side: const BorderSide(color: Color(0xFF1E3A8A)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  HealthOfficialPdfService.printHealthSummaryCertificate(
                                    context: context,
                                    record: r,
                                    company: companyProfile,
                                  );
                                },
                                icon: const Icon(Icons.print_rounded, size: 15),
                                label: const Text('ใบสรุปผล', style: TextStyle(fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D9488),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                              ),
                              if (hasPdf) ...[
                                ElevatedButton.icon(
                                  onPressed: () => _openPdfViewer(
                                    filePath: r.pdfFilePath!,
                                    title: 'รายงานผลตรวจสุขภาพ: ${r.employeeName}',
                                    subtitle: '${r.checkupTypeLabel} (${r.checkupDate})',
                                  ),
                                  icon: const Icon(Icons.visibility_rounded, size: 15),
                                  label: const Text('ดู PDF', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ],
                              if (isAbnormal && r.id != null) ...[
                                ElevatedButton.icon(
                                  onPressed: () => _openFollowupDialog(
                                    healthRecordId: r.id!,
                                    employeeId: r.employeeId,
                                    initialSymptom: r.physicalExamNotes ?? r.doctorOpinion ?? 'ผลตรวจสุขภาพผิดปกติ',
                                  ),
                                  icon: const Icon(Icons.medical_services_rounded, size: 15),
                                  label: const Text('ติดตามอาการ', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade800,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ],
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _openHealthRecordDialog(existingRecord: r);
                                  } else if (val == 'delete') {
                                    _deleteHealthRecord(r);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'edit', child: Text('แก้ไขผลการตรวจสุขภาพ')),
                                  const PopupMenuItem(value: 'delete', child: Text('ลบรายการนี้', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
    );
  }

  // ==========================================================================
  // TAB 2: HOSPITAL BULK REPORTS
  // ==========================================================================
  Widget _buildBulkReportsTab(AsyncValue<List<CompanyHealthBulkReport>> bulkReportsAsync) {
    return bulkReportsAsync.when(
      data: (reports) {
        if (reports.isEmpty) {
          return _buildEmptyState(
            icon: Icons.menu_book_outlined,
            title: 'ยังไม่มีเล่มรายงานภาพรวมจากโรงพยาบาล',
            subtitle: 'กดปุ่ม "อัปโหลดเล่มรวม รพ." ด้านบน เพื่อนำเข้าไฟล์ PDF เล่มรายงานประจำปี',
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reports.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (ctx, idx) {
            final b = reports[idx];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.picture_as_pdf_rounded, color: Colors.red.shade700, size: 28),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text('ประจำปี ${b.reportYear}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                b.reportTitle,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'หน่วยบริการ: ${b.hospitalName}  |  วันที่ตรวจ: ${b.checkupDate}',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('ตรวจทั้งหมด: ${b.totalEmployeesTested} คน', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            Text('ปกติ: ${b.normalCount} (${b.normalPercentage.toStringAsFixed(1)}%)', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            Text('เฝ้าระวัง: ${b.watchCount}', style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            Text('ผิดปกติ: ${b.abnormalCount}', style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (b.summaryNotes != null && b.summaryNotes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('สรุป: ${b.summaryNotes}', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
                  ),

                  // Actions
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _openPdfViewer(
                          filePath: b.pdfFilePath,
                          title: b.reportTitle,
                          subtitle: '${b.hospitalName} (${b.checkupDate})',
                        ),
                        icon: const Icon(Icons.menu_book_rounded, size: 16),
                        label: const Text('เปิดอ่านเล่ม PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (val) {
                          if (val == 'edit') {
                            _openBulkUploadDialog(existingReport: b);
                          } else if (val == 'delete') {
                            _deleteBulkReport(b);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'edit', child: Text('แก้ไขสถิติเล่มรายงาน')),
                          const PopupMenuItem(value: 'delete', child: Text('ลบเล่มรายงานนี้', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
    );
  }

  // ==========================================================================
  // TAB 3: MEDICAL SURVEILLANCE
  // ==========================================================================
  Widget _buildSurveillanceTab(AsyncValue<List<MedicalSurveillanceFollowup>> followupsAsync) {
    return followupsAsync.when(
      data: (followups) {
        var filtered = followups;
        if (_selectedFollowupFilter != 'ALL') {
          filtered = filtered.where((f) => f.status == _selectedFollowupFilter).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Text('สถานะการเฝ้าระวัง: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedFollowupFilter,
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('ทั้งหมด')),
                      DropdownMenuItem(value: 'OPEN', child: Text('🔴 อยู่ระหว่างเฝ้าระวัง (Open)')),
                      DropdownMenuItem(value: 'IN_PROGRESS', child: Text('🟡 กำลังรักษา/รอตรวจซ้ำ (In Progress)')),
                      DropdownMenuItem(value: 'RESOLVED', child: Text('🟢 หายดี/ปิดการเฝ้าระวัง (Resolved)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedFollowupFilter = v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (filtered.isEmpty)
              _buildEmptyState(
                icon: Icons.verified_user_outlined,
                title: 'ไม่มีรายการที่ต้องเฝ้าระวังทางการแพทย์',
                subtitle: 'หากตรวจพบผลตรวจผิดปกติ สามารถกด "ติดตามอาการ" บนการ์ดพนักงานในแท็บแรกได้ทันที',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final f = filtered[idx];

                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: f.status == 'RESOLVED' ? Colors.green.shade50 : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              f.status == 'RESOLVED' ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                              color: f.status == 'RESOLVED' ? Colors.green.shade700 : Colors.amber.shade900,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${f.employeeCode ?? "-"} - ${f.employeeName ?? "พนักงาน"} (${f.department ?? "-"})',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                      child: Text(f.actionTypeLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text('อาการ/ความผิดปกติ: ${f.abnormalSymptom}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                                const SizedBox(height: 2),
                                Text(
                                  'แผนปฏิบัติ: ${f.actionDetails}  |  นัดติดตาม: ${f.targetDate}  ${f.treatmentHospital != null ? "| รพ.: ${f.treatmentHospital}" : ""}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: Color(0xFF1E3A8A)),
                            onPressed: () => _openFollowupDialog(
                              healthRecordId: f.healthRecordId,
                              employeeId: f.employeeId,
                              existingFollowup: f,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            onPressed: () async {
                              if (f.id != null) {
                                await ref.read(medicalFollowupsProvider.notifier).deleteFollowup(f.id!);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
    );
  }

  // ==========================================================================
  // TAB 4: OFFICIAL JORPHORSOR.1 GENERATOR
  // ==========================================================================
  Widget _buildOfficialJorPhorSor1Tab(
    AsyncValue<List<EmployeeHealthRecord>> healthRecordsAsync,
    AsyncValue<List<MedicalSurveillanceFollowup>> followupsAsync,
  ) {
    final companyProfile = ref.watch(companyProfileNotifierProvider).asData?.value;

    return healthRecordsAsync.when(
      data: (records) {
        final abnormalRecords = records.where((r) => r.overallResult == 'ABNORMAL' || r.overallResult == 'WATCH').toList();
        final followups = followupsAsync.asData?.value ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.assignment_late_rounded, color: Color(0xFF6366F1), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'แบบแจ้งผลการตรวจสุขภาพของลูกจ้างที่ผิดปกติฯ (แบบ จผส. ๑)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ตามกฎกระทรวงกำหนดมาตรฐานการตรวจสุขภาพลูกจ้างซึ่งทำงานเกี่ยวกับปัจจัยเสี่ยง พ.ศ. ๒๕๖๓ สำหรับส่งพนักงานตรวจความปลอดภัย e-Service กรมสวัสดิการและคุ้มครองแรงงาน',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      HealthOfficialPdfService.printJorPhorSor1Report(
                        context: context,
                        abnormalRecords: abnormalRecords,
                        followups: followups,
                        company: companyProfile,
                      );
                    },
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('พิมพ์ แบบ จผส. ๑', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'รายการพนักงานที่ผลตรวจสุขภาพผิดปกติ / ต้องติดตามอาการ (รวม ${0} คน)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 8),

            if (abnormalRecords.isEmpty)
              _buildEmptyState(
                icon: Icons.check_circle_outline,
                title: 'ไม่พบพนักงานที่มีผลตรวจสุขภาพผิดปกติ',
                subtitle: 'ยอดเยี่ยม! พนักงานทุกคนในสถานประกอบการมีผลตรวจสุขภาพอยู่ในเกณฑ์ปกติ',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: abnormalRecords.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final r = abnormalRecords[idx];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                          child: Text('ลำดับที่ ${idx + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${r.employeeCode ?? "-"} - ${r.employeeName ?? "พนักงาน"} (${r.department ?? "-"})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('ปัจจัยเสี่ยงที่ตรวจ: ${r.riskFactorsTested.join(", ")}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
                              if (r.doctorOpinion != null)
                                Text('ความเห็นแพทย์: ${r.doctorOpinion}', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blueGrey.shade700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 54, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
