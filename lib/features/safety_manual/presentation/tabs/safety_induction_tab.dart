import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/safety_manual_pdf_exporter.dart';
import '../notifiers/manual_providers.dart';

class SafetyInductionTab extends ConsumerWidget {
  const SafetyInductionTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaflet = ref.watch(safetyInductionLeafletProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header Banner (Teal / Cyan theme)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F766E).withValues(alpha: 0.2),
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
                        Icon(Icons.assignment_ind_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'เอกสาร 1-Page ปฐมนิเทศ / Contractors',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final bytes = await SafetyManualPdfExporter.generateInductionLeafletBytes(leaflet: leaflet);
                        await SafetyManualPdfExporter.printOrPreviewPdf(bytes, 'Safety_Induction_Leaflet');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('เกิดข้อผิดพลาดในการพิมพ์ PDF: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFF0F766E)),
                    label: const Text(
                      'พิมพ์/ส่งออก PDF แผ่นพับ 1 หน้า',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E), fontSize: 12),
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
                'ใบสรุปความปลอดภัย 1 หน้า สำหรับพนักงานใหม่และผู้รับเหมา (Safety Induction Leaflet)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(
                'ออกแบบให้พิมพ์ลงกระดาษ A4 หน้าเดียวจบ พร้อม "ใบฉีก (Tear-off Slip)" ด้านล่างสำหรับเซ็นชื่อรับทราบและยินยอมปฏิบัติตามกฎ',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Simulated A4 1-Page Document Container
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top document header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.contact_emergency_rounded, color: Color(0xFF0F766E), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leaflet.titleTh,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          leaflet.titleEn,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'MUST-KNOW RULES',
                      style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Overview Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCCFBF1)),
                ),
                child: Text(
                  leaflet.content,
                  style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF134E4A)),
                ),
              ),
              const SizedBox(height: 16),

              // Key Rules
              const Text(
                'ข้อควรปฏิบัติและกฎเหล็กที่ต้องทราบทันทีก่อนเข้าพื้นที่:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F766E)),
              ),
              const SizedBox(height: 10),
              ...leaflet.keyRules.map(
                (rule) => Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D9488),
                          shape: BoxShape.circle,
                        ),
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
              const SizedBox(height: 24),

              // Perforated Tear-off Slip Simulation
              Row(
                children: [
                  const Icon(Icons.content_cut, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final boxWidth = constraints.constrainWidth();
                        const dashWidth = 5.0;
                        const dashSpace = 4.0;
                        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
                        return Flex(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          direction: Axis.horizontal,
                          children: List.generate(dashCount, (_) {
                            return const SizedBox(
                              width: dashWidth,
                              height: 1,
                              child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey)),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Slip Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ใบฉีกเซ็นรับทราบและยินยอมปฏิบัติตามกฎความปลอดภัย (Tear-off Sign-off Slip)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('ส่งคืน จป./ฝ่ายบุคคล', style: TextStyle(fontSize: 11, color: Colors.black87)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ข้าพเจ้าได้รับฟังการปฐมนิเทศและได้รับเอกสารสรุปกฎความปลอดภัยแล้ว ข้าพเจ้ายินยอมปฏิบัติตามกฎระเบียบความปลอดภัยอย่างเคร่งครัด หากฝ่าฝืนยินยอมรับมาตรการทางวินัยหรือถูกระงับการเข้าปฏิบัติงานในพื้นที่',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, height: 1.3),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ชื่อ-นามสกุล: _________________________________', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                              const SizedBox(height: 10),
                              Text('ตำแหน่ง/บริษัท: _________________________________', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ลายมือชื่อ: ___________________________________', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                              const SizedBox(height: 10),
                              Text('วันที่: ________ / ________ / ___________________', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
