import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/environment_session_model.dart';
import '../../domain/models/environment_kpi_summary.dart';
import '../../domain/models/subcontractor_model.dart';
import '../../services/environment_pdf_exporter.dart';
import '../../services/environment_excel_exporter.dart';
import '../providers/environment_providers.dart';
import '../widgets/add_edit_session_dialog.dart';
import '../widgets/attachment_preview_dialog.dart';

/// Tab 0: Executive KPI Dashboard, Annual Sessions, Subcontractor Credentials, and Multi-category Attachments.
class EnvironmentDashboardTab extends ConsumerWidget {
  final VoidCallback? onNavigateToPoints;
  final VoidCallback? onNavigateToCapa;

  const EnvironmentDashboardTab({
    Key? key,
    this.onNavigateToPoints,
    this.onNavigateToCapa,
  }) : super(key: key);

  void _openCreateSessionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEditSessionDialog(
        onSaved: (s) {
          ref.read(envSelectedSessionIdProvider.notifier).state = s.sessionId;
        },
      ),
    );
  }

  void _openEditSessionDialog(BuildContext context, WidgetRef ref, EnvironmentSessionModel session) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEditSessionDialog(session: session),
    );
  }

  void _confirmDeleteSession(BuildContext context, WidgetRef ref, EnvironmentSessionModel session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('ยืนยันการลบรอบตรวจวัด', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('คุณต้องการลบรอบการตรวจวัด "${session.sessionTitle}" (${session.sessionId}) หรือไม่? ข้อมูลจุดตรวจวัดและแผน CAPA ที่เกี่ยวข้องทั้งหมดจะถูกลบด้วย'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(envSessionListProvider.notifier).deleteSession(session.sessionId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ลบรอบการตรวจวัดเรียบร้อยแล้ว'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('ลบข้อมูล'),
          ),
        ],
      ),
    );
  }

  void _previewAttachment(BuildContext context, String title, String path, String category) {
    showDialog(
      context: context,
      builder: (ctx) => AttachmentPreviewDialog(
        title: title,
        filePath: path,
        category: category,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpiAsync = ref.watch(envKpiSummaryProvider);
    final sessionsAsync = ref.watch(envSessionListProvider);
    final selectedSessionId = ref.watch(envSelectedSessionIdProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // --------------------------------------------------------------------
        // 1. Executive KPI Summary Cards
        // --------------------------------------------------------------------
        kpiAsync.when(
          data: (kpi) => _buildKpiSection(context, kpi),
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
          error: (err, _) => Center(child: Text('ข้อผิดพลาดโหลด KPI: $err', style: const TextStyle(color: Colors.red))),
        ),
        const SizedBox(height: 20),

        // --------------------------------------------------------------------
        // 2. Active Session & Subcontractor Credentials Card
        // --------------------------------------------------------------------
        sessionsAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return _buildNoSessionsBanner(context, ref);
            }

            final activeSession = sessions.firstWhere(
              (s) => s.sessionId == selectedSessionId,
              orElse: () => sessions.first,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActiveSessionCard(context, ref, activeSession),
                const SizedBox(height: 20),
                _buildSubcontractorAndDeadlinesCard(context, ref, activeSession),
                const SizedBox(height: 20),
                _buildMultiCategoryAttachmentsCard(context, ref, activeSession),
                const SizedBox(height: 20),
                _buildAnnualSessionsTable(context, ref, sessions),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('เกิดข้อผิดพลาด: $err', style: const TextStyle(color: Colors.red))),
        ),
      ],
    );
  }

  Widget _buildKpiSection(BuildContext context, EnvironmentKpiSummary kpi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics_rounded, color: Color(0xFF1E3A8A), size: 22),
            const SizedBox(width: 8),
            const Text(
              'ดัชนีสรุปผลการตรวจวัดสภาพแวดล้อม (Environmental KPI Summary)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const Spacer(),
            Text(
              'คำนวณล่าสุด: ${kpi.calculatedAt.substring(0, 10)}',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4 Main Metric Cards
        Row(
          children: [
            // Overall Compliance Gauge
            Expanded(
              flex: 3,
              child: _buildMetricCard(
                title: 'ดัชนีความสอดคล้องรวม',
                value: '${kpi.compliancePercentage.toStringAsFixed(1)}%',
                subtitle: 'ผ่าน ${kpi.passedPoints} จากทั้งหมด ${kpi.totalPoints} จุด',
                color: kpi.compliancePercentage >= 90
                    ? const Color(0xFF10B981)
                    : (kpi.compliancePercentage >= 75 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                icon: Icons.verified_rounded,
              ),
            ),
            const SizedBox(width: 12),

            // Pass Count
            Expanded(
              flex: 2,
              child: _buildMetricCard(
                title: 'ผ่านเกณฑ์มาตรฐาน',
                value: '${kpi.passedPoints}',
                subtitle: 'ผลการตรวจวัดปกติ',
                color: const Color(0xFF10B981),
                icon: Icons.check_circle_rounded,
              ),
            ),
            const SizedBox(width: 12),

            // Action Level (HCP)
            Expanded(
              flex: 2,
              child: _buildMetricCard(
                title: 'เฝ้าระวัง Action Level',
                value: '${kpi.actionLevelPoints}',
                subtitle: 'เข้าโครงการ HCP: ${kpi.hcpRequiredCount} จุด',
                color: const Color(0xFFF59E0B),
                icon: Icons.warning_amber_rounded,
              ),
            ),
            const SizedBox(width: 12),

            // Exceed Standard (Fail)
            Expanded(
              flex: 2,
              child: _buildMetricCard(
                title: 'เกินเกณฑ์มาตรฐาน',
                value: '${kpi.failedPoints}',
                subtitle: 'แผน CAPA ค้าง: ${kpi.capaPendingCount + kpi.capaOverdueCount}',
                color: const Color(0xFFEF4444),
                icon: Icons.cancel_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Parameter Breakdown Progress Bars
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildParamProgress(
                  label: 'แสงสว่าง (Lighting)',
                  icon: Icons.lightbulb_outline_rounded,
                  color: const Color(0xFFD97706),
                  percentage: kpi.lightCompliancePercentage,
                  detail: 'ผ่าน ${kpi.lightPassed} / ${kpi.lightPoints} จุด',
                ),
              ),
              Container(height: 40, width: 1, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 16)),
              Expanded(
                child: _buildParamProgress(
                  label: 'เสียง (Noise)',
                  icon: Icons.volume_up_rounded,
                  color: const Color(0xFF2563EB),
                  percentage: kpi.noiseCompliancePercentage,
                  detail: 'ปกติ ${kpi.noiseNormal} | เฝ้าระวัง ${kpi.noiseActionLevel} | เกิน ${kpi.noiseExceeded}',
                ),
              ),
              Container(height: 40, width: 1, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 16)),
              Expanded(
                child: _buildParamProgress(
                  label: 'ความร้อน (Heat WBGT)',
                  icon: Icons.thermostat_rounded,
                  color: const Color(0xFFDC2626),
                  percentage: kpi.heatCompliancePercentage,
                  detail: 'ผ่าน ${kpi.heatPassed} / ${kpi.heatPoints} จุด',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamProgress({
    required String label,
    required IconData icon,
    required Color color,
    required double percentage,
    required String detail,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100.0,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(detail, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildNoSessionsBanner(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 48, color: Color(0xFF1E3A8A)),
            const SizedBox(height: 14),
            const Text(
              'ยังไม่มีรอบการตรวจวัดสภาพแวดล้อม',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'เริ่มต้นโดยการสร้างรอบการตรวจวัดประจำปี พร้อมระบุข้อมูลผู้รับจ้างตรวจวัด (ม.๙ / ม.๑๑)',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _openCreateSessionDialog(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('สร้างรอบการตรวจวัดใหม่'),
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
    );
  }

  Widget _buildActiveSessionCard(BuildContext context, WidgetRef ref, EnvironmentSessionModel session) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E3A8A).withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  session.sessionId,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  session.sessionTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session.status.labelTh,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildSessionInfoItem(Icons.corporate_fare_rounded, 'สถานประกอบการ', session.workplaceName),
              _buildSessionInfoItem(Icons.location_on_outlined, 'โรงงาน/พื้นที่', session.locationPlant),
              _buildSessionInfoItem(Icons.event_available_rounded, 'วันที่ตรวจวัด', session.measurementDate),
              _buildSessionInfoItem(Icons.handshake_outlined, 'ผู้ให้บริการ', session.subcontractorCompanyName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
                Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcontractorAndDeadlinesCard(BuildContext context, WidgetRef ref, EnvironmentSessionModel session) {
    final postingDl = session.postingDeadline ?? EnvironmentSessionModel.calculatePostingDeadline(session.measurementDate);
    final submissionDl = session.submissionDeadline ?? EnvironmentSessionModel.calculateSubmissionDeadline(session.measurementDate);

    final isPostOverdue = session.isPostingOverdue;
    final isSubOverdue = session.isSubmissionOverdue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subcontractor Credentials Card
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF1E3A8A), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'การรับรองผู้ให้บริการตรวจวัด (Subcontractor ม.๙ / ม.๑๑)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        session.subcontractorType.labelTh,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSubDetailRow('บริษัทผู้ให้บริการ:', session.subcontractorCompanyName),
                _buildSubDetailRow('เลขทะเบียน/ใบอนุญาต:', session.subcontractorRegNumber),
                _buildSubDetailRow('ผู้ทำการตรวจวัด:', '${session.surveyorName} (${session.surveyorLicenseNo ?? "-"})'),
                _buildSubDetailRow('ผู้รับรองรายงาน:', '${session.certifierName} (เลขทะเบียน ${session.certifierRegNo ?? session.subcontractorRegNumber})'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Statutory Deadlines Card (Section 15 OSH Act)
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'กำหนดเวลาตามกฎหมาย (Section 15)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 15-day Posting
                Row(
                  children: [
                    Icon(
                      isPostOverdue ? Icons.error_rounded : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: isPostOverdue ? Colors.red : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ปิดประกาศผล ณ สถานประกอบการ (๑๕ วัน)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          Text('กำหนดภายใน: $postingDl', style: TextStyle(fontSize: 11, color: isPostOverdue ? Colors.red : Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    if (isPostOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                        child: const Text('เกินกำหนด', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // 30-day DLPW Submission
                Row(
                  children: [
                    Icon(
                      isSubOverdue ? Icons.error_rounded : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: isSubOverdue ? Colors.red : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('จัดส่งรายงานให้อธิบดีกรมฯ (๓๐ วัน)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          Text('กำหนดภายใน: $submissionDl', style: TextStyle(fontSize: 11, color: isSubOverdue ? Colors.red : Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    if (isSubOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                        child: const Text('เกินกำหนด', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiCategoryAttachmentsCard(BuildContext context, WidgetRef ref, EnvironmentSessionModel session) {
    final pdfReport = session.pdfReportPath ?? 'รายงานผลตรวจวัดฉบับเต็ม.pdf';
    final calCerts = session.calibrationCertPaths.isNotEmpty ? session.calibrationCertPaths : ['ใบสอบเทียบ Sound Level Meter.pdf', 'ใบสอบเทียบ Lux Meter.pdf'];
    final subLicense = session.subcontractorLicensePath ?? 'ใบสำคัญรับรองขึ้นทะเบียน ม.๑๑.pdf';
    final photos = session.sitePhotoPaths.isNotEmpty ? session.sitePhotoPaths : ['ภาพถ่ายจุดตรวจวัด แผนกผลิต 1.jpg', 'ภาพถ่ายจุดตรวจวัด แผนก QC.jpg'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.folder_shared_rounded, color: Color(0xFF1E3A8A), size: 20),
              SizedBox(width: 8),
              Text(
                'เอกสารอ้างอิงและหลักฐานประกอบการตรวจวัด (Multi-Category Attachments)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              // 1. PDF Report
              Expanded(
                child: _buildAttachmentCategoryCard(
                  title: 'เล่มรายงานผลฉบับเต็ม',
                  count: '1 ไฟล์',
                  icon: Icons.picture_as_pdf_rounded,
                  color: const Color(0xFFDC2626),
                  onPreview: () => _previewAttachment(context, 'เล่มรายงานผลฉบับเต็ม (PDF Report)', pdfReport, 'เล่มรายงานผล'),
                ),
              ),
              const SizedBox(width: 12),

              // 2. Calibration Certs
              Expanded(
                child: _buildAttachmentCategoryCard(
                  title: 'ใบรับรองการสอบเทียบ',
                  count: '${calCerts.length} ฉบับ',
                  icon: Icons.speed_rounded,
                  color: const Color(0xFF2563EB),
                  onPreview: () => _previewAttachment(context, 'ใบรับรองการสอบเทียบเครื่องมือวัด (ISO/IEC 17025)', calCerts.first, 'ใบสอบเทียบ'),
                ),
              ),
              const SizedBox(width: 12),

              // 3. Subcontractor License
              Expanded(
                child: _buildAttachmentCategoryCard(
                  title: 'ใบอนุญาต ม.๙/๑๑',
                  count: '1 ฉบับ',
                  icon: Icons.badge_rounded,
                  color: const Color(0xFF16A34A),
                  onPreview: () => _previewAttachment(context, 'ใบสำคัญ/ใบอนุญาตขึ้นทะเบียนผู้ให้บริการ', subLicense, 'ใบอนุญาต ม.๙/๑๑'),
                ),
              ),
              const SizedBox(width: 12),

              // 4. Site Photos
              Expanded(
                child: _buildAttachmentCategoryCard(
                  title: 'รูปถ่ายจุดตรวจวัด',
                  count: '${photos.length} รูป',
                  icon: Icons.photo_library_rounded,
                  color: const Color(0xFF9333EA),
                  onPreview: () => _previewAttachment(context, 'รูปถ่ายจุดตรวจวัดและสภาพแวดล้อมจริง', photos.first, 'รูปถ่ายจุดตรวจวัด'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCategoryCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required VoidCallback onPreview,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(count, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPreview,
              icon: const Icon(Icons.visibility_rounded, size: 14),
              label: const Text('พรีวิวเอกสาร', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnualSessionsTable(BuildContext context, WidgetRef ref, List<EnvironmentSessionModel> sessions) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: Color(0xFF1E3A8A), size: 20),
              const SizedBox(width: 8),
              const Text(
                'รายการรอบการตรวจวัดประจำปี (Annual Measurement Sessions)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _openCreateSessionDialog(context, ref),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('สร้างรอบตรวจวัดใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final s = sessions[i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'พ.ศ.\n${s.sessionYearBe}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(s.sessionId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(s.status.labelTh, style: const TextStyle(fontSize: 10, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(s.sessionTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('ตรวจวัด: ${s.measurementDate}  |  ผู้รับจ้าง: ${s.subcontractorCompanyName}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'แก้ไข',
                      onPressed: () => _openEditSessionDialog(context, ref, s),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      tooltip: 'ลบ',
                      onPressed: () => _confirmDeleteSession(context, ref, s),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
