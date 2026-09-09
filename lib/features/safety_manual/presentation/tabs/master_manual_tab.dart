import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/manual_chapter_model.dart';
import '../../services/safety_manual_pdf_exporter.dart';
import '../notifiers/manual_providers.dart';

class MasterManualTab extends ConsumerWidget {
  const MasterManualTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters = ref.watch(masterManualChaptersProvider);
    final scopeAsync = ref.watch(factoryScopeProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0369A1), Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.2),
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
                        Icon(Icons.gavel, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ มาตรา ๑๓',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final bytes = await SafetyManualPdfExporter.generateMasterManualBytes(chapters: chapters);
                        await SafetyManualPdfExporter.printOrPreviewPdf(bytes, 'Master_Safety_Manual');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('เกิดข้อผิดพลาดในการพิมพ์ PDF: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFF0369A1)),
                    label: const Text(
                      'พิมพ์/ส่งออก PDF เล่มเต็ม',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1), fontSize: 12),
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
                'คู่มือและข้อบังคับว่าด้วยความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน (เล่มเต็ม)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(
                'สังเคราะห์และรวบรวมเนื้อหาอัตโนมัติตามขอบเขตความเสี่ยงโรงงาน (${chapters.length} บท) กฎระเบียบฉบับนี้มีผลบังคับใช้ตามกฎหมายแก่พนักงานและผู้รับเหมาทุกคน',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Scope info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'สารบัญและหมวดหมู่ข้อบังคับ (${chapters.length} บท)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
            ),
            scopeAsync.when(
              data: (scope) => Text(
                'ขอบเขต: ${scope.hasBoiler ? "✓ มีหม้อน้ำ" : "✗ ไม่มีหม้อน้ำ"} | ${scope.hasCrane ? "✓ มีปั้นจั่น" : "✗ ไม่มีปั้นจั่น"}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Chapters List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chapters.length,
          itemBuilder: (context, index) {
            final ch = chapters[index];
            return _buildChapterCard(ch);
          },
        ),
      ],
    );
  }

  Widget _buildChapterCard(ManualChapterModel ch) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: ch.chapterNumber <= 3,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${ch.chapterNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7), fontSize: 15),
            ),
          ),
          title: Text(
            ch.titleTh,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          subtitle: ch.titleEn.isNotEmpty
              ? Text(ch.titleEn, style: TextStyle(fontSize: 11, color: Colors.grey.shade600))
              : null,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Content
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ch.content,
                style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
              ),
            ),
            if (ch.keyRules.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'ข้อกำหนดและกฎเกณฑ์สำคัญ (Key Safety Rules):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0284C7)),
              ),
              const SizedBox(height: 6),
              ...ch.keyRules.map(
                (rule) => Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rule,
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), height: 1.3),
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
