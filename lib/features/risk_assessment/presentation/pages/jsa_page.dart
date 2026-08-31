import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/risk_assessment_models.dart';
import '../../domain/models/contractor_jsa_models.dart';
import '../../domain/models/risk_matrix_criteria.dart';
import '../providers/risk_assessment_providers.dart';
import '../widgets/company_profile_dialog.dart';
import '../widgets/session_edit_dialog.dart';
import '../widgets/contractor_doc_upload_dialog.dart';
import 'workstation_hazard_editor_page.dart';
import 'official_report_preview_page.dart';
import 'contractor_doc_viewer_page.dart';

class JsaPage extends ConsumerStatefulWidget {
  const JsaPage({Key? key}) : super(key: key);

  @override
  ConsumerState<JsaPage> createState() => _JsaPageState();
}

class _JsaPageState extends ConsumerState<JsaPage> {
  int _selectedTab = 0; // 0 = In-house JSA, 1 = Contractor Documents

  void _openProfileDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const CompanyProfileDialog(),
    );
  }

  void _openCreateSessionDialog() async {
    final newId = await showDialog<int?>(
      context: context,
      builder: (ctx) => const SessionEditDialog(),
    );

    if (newId != null && mounted) {
      // เปิดไปยังหน้าจัดทำสถานีงานและประเมินอันตรายทันที
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkstationHazardEditorPage(sessionId: newId),
        ),
      );
    }
  }

  void _openUploadContractorDocDialog({ContractorJsaDocument? existingDoc}) async {
    await showDialog(
      context: context,
      builder: (ctx) => ContractorDocUploadDialog(existingDoc: existingDoc),
    );
  }

  Future<void> _deleteContractorDoc(ContractorJsaDocument doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบเอกสารผู้รับเหมา'),
        content: Text('ต้องการลบเอกสาร "${doc.projectTitle}" ของ ${doc.contractorName} และไฟล์แนบทั้งหมดใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true && doc.id != null) {
      await ref.read(contractorJsaProvider.notifier).deleteDocument(doc.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบเอกสารผู้รับเหมาเรียบร้อยแล้ว')),
        );
      }
    }
  }

  void _showCriteriaInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.gavel_rounded, color: Colors.blue.shade800),
            const SizedBox(width: 8),
            const Text('เกณฑ์การประเมินอันตรายตามประกาศกระทรวงแรงงาน (๒๕๖๗)'),
          ],
        ),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCriteriaTableTitle('ตารางที่ ๑: เกณฑ์การวิเคราะห์โอกาสที่จะเกิดอันตราย (Likelihood)'),
                ...RiskMatrixCriteria.likelihoodCriteria.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• ${e.value["title"]}: ${e.value["description"]}', style: const TextStyle(fontSize: 12)),
                    )),
                const Divider(height: 20),
                _buildCriteriaTableTitle('ตารางที่ ๒: เกณฑ์การวิเคราะห์ความรุนแรงของอันตราย (Severity)'),
                ...RiskMatrixCriteria.severityCriteria.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• ${e.value["title"]}: ${e.value["description"]}', style: const TextStyle(fontSize: 12)),
                    )),
                const Divider(height: 20),
                _buildCriteriaTableTitle('ตารางที่ ๓ & ๔: เมทริกซ์ ๓x๓ และระดับความเป็นอันตราย'),
                Table(
                  border: TableBorder.all(color: Colors.grey.shade400),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade200),
                      children: const [
                        Padding(padding: EdgeInsets.all(6), child: Text('ระดับอันตราย', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(6), child: Text('คะแนน (LxS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(6), child: Text('ความหมาย & การดำเนินการตามกฎหมาย', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: EdgeInsets.all(6), child: Text('แบบ ปอ.๒', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                    _buildMatrixInfoRow('(๑) ระดับต่ำมาก', '๑', 'ความเป็นอันตรายเล็กน้อย ไม่ต้องจัดทำแผนควบคุม', 'ไม่ต้อง', Colors.green),
                    _buildMatrixInfoRow('(๒) ระดับต่ำ', '๒', 'อันตรายยอมรับได้ ต้องเฝ้าระวังและติดตามตรวจสอบ', 'ไม่ต้อง', Colors.blue),
                    _buildMatrixInfoRow('(๓) ระดับปานกลาง', '๓ หรือ ๔', 'ต้องทบทวนมาตรการควบคุม พร้อมจัดทำแผนดำเนินงาน', 'ต้องทำ', Colors.amber.shade800),
                    _buildMatrixInfoRow('(๔) ระดับสูง', '๖', 'ต้องดำเนินงานเพื่อลดระดับอันตราย พร้อมจัดทำแผนดำเนินงาน', 'ต้องทำ', Colors.orange.shade900),
                    _buildMatrixInfoRow('(๕) ระดับสูงมาก', '๙', 'ยอมรับไม่ได้ ต้องหยุดดำเนินการและปรับปรุงแก้ไขทันที', 'ต้องทำ', Colors.red.shade700),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('ปิด')),
        ],
      ),
    );
  }

  Widget _buildCriteriaTableTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade900),
      ),
    );
  }

  TableRow _buildMatrixInfoRow(String level, String score, String meaning, String por2, Color color) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(level, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 11)),
        ),
        Padding(padding: const EdgeInsets.all(6), child: Text(score, style: const TextStyle(fontSize: 11))),
        Padding(padding: const EdgeInsets.all(6), child: Text(meaning, style: const TextStyle(fontSize: 11))),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            por2,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: por2 == 'ต้องทำ' ? Colors.red : Colors.green,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteSession(RiskAssessmentSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบชุดการประเมิน'),
        content: Text('ต้องการลบชุดการประเมิน "${session.sessionTitle}" และข้อมูลสถานีงาน/รายการอันตรายทั้งหมดใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true && session.id != null) {
      await ref.read(riskSessionsProvider.notifier).deleteSession(session.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบชุดการประเมินเรียบร้อยแล้ว')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(riskSessionsProvider);
    final contractorDocsAsync = ref.watch(contractorJsaProvider);
    final companyAsync = ref.watch(companyProfileNotifierProvider);

    final inHouseCount = sessionsAsync.asData?.value.length ?? 0;
    final contractorCount = contractorDocsAsync.asData?.value.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------------------
            // Header Card
            // ----------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade900, Colors.indigo.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.indigo.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield_outlined, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ระบบประเมินอันตรายและการศึกษาผลกระทบ (แบบ ปอ. ๑ และ แบบ ปอ. ๒)',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ตามประกาศกระทรวงแรงงาน เรื่อง การประเมินอันตราย การศึกษาผลกระทบ และการจัดทำแผนควบคุม (๒๕๖๗)',
                          style: TextStyle(color: Colors.blue.shade100, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        companyAsync.when(
                          data: (comp) => Text(
                            'สถานประกอบการ: ${comp?.companyName ?? "ยังไม่ได้ระบุชื่อบริษัท"} | ผู้ชำนาญการ ม.๓๓: ${comp?.safetyExpertName ?? "-"}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white60),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('เกณฑ์เมทริกซ์ 3x3'),
                        onPressed: _showCriteriaInfoDialog,
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white60),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        icon: const Icon(Icons.business_rounded, size: 16),
                        label: const Text('ข้อมูลสถานประกอบการ (Profile)'),
                        onPressed: _openProfileDialog,
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                        label: const Text('อัปโหลดเอกสารผู้รับเหมา', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _openUploadContractorDocDialog(),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade500,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('สร้างรอบประเมินใหม่', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _openCreateSessionDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ----------------------------------------------------------------
            // Segmented Navigation Tabs
            // ----------------------------------------------------------------
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      index: 0,
                      label: 'ประเมินในระบบ (In-house JSA / ปอ.๑ & ปอ.๒)',
                      count: inHouseCount,
                      icon: Icons.table_chart_rounded,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildTabButton(
                      index: 1,
                      label: 'เอกสารผู้รับเหมา (Contractor Files / Hard copy & PDF)',
                      count: contractorCount,
                      icon: Icons.folder_shared_rounded,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ----------------------------------------------------------------
            // TAB CONTENT
            // ----------------------------------------------------------------
            if (_selectedTab == 0)
              _buildInHouseJsaSection(sessionsAsync)
            else
              _buildContractorDocsSection(contractorDocsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedTab == index;

    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // 1. IN-HOUSE JSA LIST
  // ----------------------------------------------------------------
  Widget _buildInHouseJsaSection(AsyncValue<List<RiskAssessmentSession>> sessionsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'รายการชุดการประเมินอันตรายในระบบ (Risk Assessment Sessions)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Spacer(),
            sessionsAsync.when(
              data: (list) => Text('ทั้งหมด ${list.length} รายการ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
        const SizedBox(height: 12),

        sessionsAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'ยังไม่มีประวัติการประเมินอันตรายในระบบ',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'เริ่มต้นโดยการกำหนดโครงสร้างสถานีงาน กระบวนการ หรือเครื่องจักร แล้วประเมินความเสี่ยงเพื่อจัดทำแบบ ปอ.๑ และ ปอ.๒',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('สร้างชุดการประเมินแรกของคุณ'),
                      onPressed: _openCreateSessionDialog,
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final s = sessions[idx];
                final isPeriodic = s.assessmentType == 'PERIODIC';

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon / Type indicator
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isPeriodic ? Colors.blue.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isPeriodic ? Icons.event_repeat_rounded : Icons.sync_problem_rounded,
                            color: isPeriodic ? Colors.blue.shade800 : Colors.orange.shade900,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Session Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    s.sessionTitle,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPeriodic ? Colors.blue.shade100 : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isPeriodic ? 'รอบปกติ (ทบทวน ๓ ปี)' : 'รอบปรับปรุง MOC (๓๐ วัน)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isPeriodic ? Colors.blue.shade900 : Colors.orange.shade900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusBadge(s.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'วันที่ประเมิน: ${s.assessmentDate}  |  วันครบกำหนดทบทวน: ${s.nextReviewDate ?? "-"}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'วิธีชี้บ่งอันตราย: ${s.hazardIdMethod}  |  ผู้ประเมิน: ${s.assessor1Name ?? "-"} (${s.assessor1Position ?? "-"})',
                                style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600),
                              ),
                            ],
                          ),
                        ),

                        // Actions
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.indigo.shade700,
                                side: BorderSide(color: Colors.indigo.shade200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.print_rounded, size: 16),
                              label: const Text('พรีวิว ปอ.๑ / ปอ.๒'),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => OfficialReportPreviewPage(sessionId: s.id!),
                                  ),
                                );
                              },
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade800,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: const Text('จัดการสถานีงาน & ชี้บ่งอันตราย'),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => WorkstationHazardEditorPage(sessionId: s.id!),
                                  ),
                                );
                              },
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (val) async {
                                if (val == 'edit') {
                                  await showDialog(
                                    context: context,
                                    builder: (ctx) => SessionEditDialog(existingSession: s),
                                  );
                                } else if (val == 'delete') {
                                  await _deleteSession(s);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'edit', child: Text('แก้ไขข้อมูลชุดประเมิน')),
                                const PopupMenuItem(value: 'delete', child: Text('ลบชุดการประเมิน', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------
  // 2. CONTRACTOR DOCUMENTS LIST
  // ----------------------------------------------------------------
  Widget _buildContractorDocsSection(AsyncValue<List<ContractorJsaDocument>> contractorDocsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'รายการเอกสารความปลอดภัยและ JSA ของผู้รับเหมาภายนอก',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Spacer(),
            contractorDocsAsync.when(
              data: (list) => Text('ทั้งหมด ${list.length} รายการ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
        const SizedBox(height: 12),

        contractorDocsAsync.when(
          data: (docs) {
            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_shared_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'ยังไม่มีเอกสารประเมินความเสี่ยงของผู้รับเหมา',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'เมื่อผู้รับเหมานำส่งเอกสาร JSA, Safety Method Statement หรือแบบ ปอ.๑/๒ รูปแบบไฟล์ PDF หรือรูปถ่ายสแกน สามารถอัปโหลดจัดเก็บได้ที่นี่',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('อัปโหลดเอกสารผู้รับเหมาแรก'),
                      onPressed: () => _openUploadContractorDocDialog(),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final doc = docs[idx];
                final pdfCount = doc.filePaths.where((f) => p.extension(f).toLowerCase() == '.pdf').length;
                final imgCount = doc.filePaths.where((f) => p.extension(f).toLowerCase() != '.pdf').length;

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.business_center_rounded,
                            color: Color(0xFF0D9488),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Document Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    doc.contractorName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.teal.shade200),
                                    ),
                                    child: Text(
                                      doc.documentType,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ชื่องาน/โครงการ: ${doc.projectTitle}${doc.workLocation != null ? " (สถานที่: ${doc.workLocation})" : ""}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'วันที่จัดทำ: ${doc.assessmentDate}${doc.validUntilDate != null ? "  |  ใช้ได้ถึง: ${doc.validUntilDate}" : ""}${doc.assessorName != null ? "  |  ผู้ประเมิน: ${doc.assessorName}" : ""}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 8),

                              // File pills
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (pdfCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.picture_as_pdf_rounded, size: 14, color: Colors.red.shade700),
                                          const SizedBox(width: 4),
                                          Text(
                                            'PDF $pdfCount ไฟล์',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (imgCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.image_rounded, size: 14, color: Colors.blue.shade700),
                                          const SizedBox(width: 4),
                                          Text(
                                            'ภาพสแกน/Hard copy $imgCount ไฟล์',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (doc.filePaths.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'ไม่มีไฟล์แนบ',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Actions
                        Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D9488),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.visibility_rounded, size: 16),
                              label: const Text('เปิดดูเอกสาร', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ContractorDocViewerPage(document: doc),
                                  ),
                                );
                              },
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (val) async {
                                if (val == 'edit') {
                                  _openUploadContractorDocDialog(existingDoc: doc);
                                } else if (val == 'delete') {
                                  await _deleteContractorDoc(doc);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'edit', child: Text('แก้ไขข้อมูล / แนบไฟล์เพิ่ม')),
                                const PopupMenuItem(value: 'delete', child: Text('ลบเอกสารผู้รับเหมา', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('เกิดข้อผิดพลาดในการโหลดเอกสาร: $e')),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'SUBMITTED':
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        label = 'ส่งรายงานกรมแล้ว';
        break;
      case 'ENDORSED':
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade900;
        label = 'รับรองโดยผู้ชำนาญการแล้ว';
        break;
      case 'DRAFT':
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        label = 'ร่าง (Draft)';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
