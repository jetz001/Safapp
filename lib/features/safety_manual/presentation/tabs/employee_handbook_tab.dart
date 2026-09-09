import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/manual_chapter_model.dart';
import '../../services/safety_manual_pdf_exporter.dart';
import '../notifiers/manual_providers.dart';

class EmployeeHandbookTab extends ConsumerWidget {
  const EmployeeHandbookTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(employeeHandbookChaptersProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header Banner (Amber/Orange theme)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD97706).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.badge_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'ฉบับพกพาติดตัว / Pocket Guide',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final bytes = await SafetyManualPdfExporter.generateEmployeeHandbookBytes(chapters: sections);
                        await SafetyManualPdfExporter.printOrPreviewPdf(bytes, 'Employee_Safety_Handbook');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('เกิดข้อผิดพลาดในการพิมพ์ PDF: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFFD97706)),
                    label: const Text(
                      'พิมพ์/ส่งออก PDF ฉบับพนักงาน',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706), fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'คู่มือความปลอดภัยประจำตัวพนักงาน (Employee Pocket Safety Handbook)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(
                'สรุปกฎทองความปลอดภัย สิทธิและหน้าที่ของพนักงานตามกฎหมาย เข้าใจง่าย กระชับ พร้อมเบอร์ติดต่อฉุกเฉินประจำโรงงาน',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section Cards
        ...sections.map((sec) => _buildSectionCard(sec)),
      ],
    );
  }

  Widget _buildSectionCard(ManualChapterModel sec) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Color(0xFFD97706), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sec.titleTh,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      if (sec.titleEn.isNotEmpty)
                        Text(sec.titleEn, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFEF3C7)),
              ),
              child: Text(
                sec.content,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF92400E), height: 1.4),
              ),
            ),
            if (sec.keyRules.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...sec.keyRules.map(
                (rule) => Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 12),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rule,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
