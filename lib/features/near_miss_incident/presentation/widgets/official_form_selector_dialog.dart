import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/accident_models.dart';
import '../providers/accident_providers.dart';
import '../../services/accident_official_pdf_service.dart';
import '../../../risk_assessment/presentation/providers/risk_assessment_providers.dart';

class OfficialFormSelectorDialog extends ConsumerWidget {
  final AccidentInvestigation investigation;

  const OfficialFormSelectorDialog({
    Key? key,
    required this.investigation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyProfile = ref.watch(companyProfileNotifierProvider).asData?.value;
    final capaAsync = ref.watch(accidentCapaProvider);
    final actions = capaAsync.asData?.value.where((a) => a.investigationId == investigation.id).toList() ?? [];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.print_rounded, color: Color(0xFF1E3A8A), size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('คลังพิมพ์แบบฟอร์มราชการ & เอกสารทางการ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('เลขที่เหตุการณ์: ${investigation.eventNo}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Form 1: กท. 44 (ใบส่งตัว รพ.)
            _buildFormCard(
              context: context,
              icon: Icons.local_hospital_rounded,
              color: Colors.teal.shade700,
              badge: 'ยื่นทันที',
              title: 'แบบ กท. ๔๔ (ใบส่งตัวลูกจ้างเข้ารับการรักษาพยาบาล)',
              subtitle: 'เอกสารแสดงต่อสถานพยาบาลในความตกลง กองทุนเงินทดแทน สปส. เพื่อให้ลูกจ้างรักษาทันทีโดยไม่ต้องสำรองจ่าย',
              onPrint: () => AccidentOfficialPdfService.printKorTor44Document(
                context: context,
                investigation: investigation,
                company: companyProfile,
              ),
            ),
            const SizedBox(height: 10),

            // Form 2: รายงานผลสอบสวน (๗ หัวข้อตามคู่มือราชการ)
            _buildFormCard(
              context: context,
              icon: Icons.description_rounded,
              color: const Color(0xFF1E3A8A),
              badge: 'มาตรฐานราชการ',
              title: 'แบบรายงานผลการสอบสวน วิเคราะห์อุบัติเหตุและโรคจากการทำงาน',
              subtitle: 'รายงานการสอบสวนฉบับสมบูรณ์ (๗ หัวข้อตามคู่มือศูนย์ความปลอดภัยในการทำงานเขต กรมสวัสดิการและคุ้มครองแรงงาน)',
              onPrint: () => AccidentOfficialPdfService.printOfficialInvestigationReport(
                context: context,
                investigation: investigation,
                capaActions: actions,
                company: companyProfile,
              ),
            ),
            const SizedBox(height: 10),

            // Form 3: สปร. ๕ (แจ้ง ม.๓๔ ภายใน ๗ วัน)
            _buildFormCard(
              context: context,
              icon: Icons.assignment_late_rounded,
              color: Colors.indigo.shade700,
              badge: 'ภายใน ๗ วัน',
              title: 'แบบ สปร. ๕ (แบบแจ้งอุบัติภัยร้ายแรงหรือประสบอันตราย)',
              subtitle: 'หนังสือแจ้งต่อพนักงานตรวจความปลอดภัย ตามมาตรา ๓๔ แห่ง พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ ภายใน ๗ วันนับแต่วันเกิดเหตุ',
              onPrint: () => AccidentOfficialPdfService.printPorSorRor5Document(
                context: context,
                investigation: investigation,
                company: companyProfile,
              ),
            ),
            const SizedBox(height: 10),

            // Form 4: กท. ๑๖ (แจ้งเงินทดแทน ภายใน ๑๕ วัน)
            _buildFormCard(
              context: context,
              icon: Icons.payments_rounded,
              color: Colors.deepOrange.shade700,
              badge: 'ภายใน ๑๕ วัน',
              title: 'แบบ กท. ๑๖ (แบบแจ้งการประสบอันตรายและขอรับเงินทดแทน)',
              subtitle: 'เอกสารแจ้งต่อสำนักงานประกันสังคม (สปส.) ภายใน ๑๕ วันนับแต่วันทราบการประสบอันตรายของลูกจ้าง',
              onPrint: () => AccidentOfficialPdfService.printKorTor16Document(
                context: context,
                investigation: investigation,
                company: companyProfile,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ปิดหน้าต่าง')),
      ],
    );
  }

  Widget _buildFormCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String badge,
    required String title,
    required String subtitle,
    required VoidCallback onPrint,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onPrint();
            },
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('พิมพ์', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
