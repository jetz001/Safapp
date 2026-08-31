import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/models/contractor_models.dart';
import '../../services/safety_pass_pdf_service.dart';

class SafetyPassDialog extends StatelessWidget {
  final ContractorWorker worker;

  const SafetyPassDialog({
    Key? key,
    required this.worker,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = worker.inductionStatus;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'VALID':
        statusColor = const Color(0xFF10B981);
        statusText = 'ผ่านการอบรม (VALID SAFETY PASS)';
        statusIcon = Icons.verified_rounded;
        break;
      case 'EXPIRING_SOON':
        statusColor = const Color(0xFFF59E0B);
        statusText = 'ใกล้หมดอายุ (EXPIRING SOON)';
        statusIcon = Icons.warning_amber_rounded;
        break;
      case 'EXPIRED':
        statusColor = const Color(0xFFEF4444);
        statusText = 'บัตรหมดอายุ (PASS EXPIRED)';
        statusIcon = Icons.cancel_rounded;
        break;
      case 'PENDING':
      default:
        statusColor = Colors.grey;
        statusText = 'ยังไม่อบรม (INDUCTION PENDING)';
        statusIcon = Icons.hourglass_top_rounded;
        break;
    }

    final hasPhoto = worker.photoPath != null && File(worker.photoPath!).existsSync();

    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 380,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Badge Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SAFAPP CONTRACTOR PASS',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 0.5),
                        ),
                        Text(
                          'บัตรอนุญาตเข้าปฏิบัติงาน',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Photo & Main info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 90,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))
                          ],
                        ),
                        child: hasPhoto
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(File(worker.photoPath!), fit: BoxFit.cover),
                              )
                            : Icon(Icons.person, size: 48, color: Colors.grey.shade400),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker.workerName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                worker.jobRole,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'บริษัท: ${worker.contractorName ?? "ผู้รับเหมา"}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                            ),
                            if (worker.nationalIdOrPassport != null)
                              Text(
                                'ID: ${worker.nationalIdOrPassport}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Induction Validity Info Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ],
                        ),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('วันที่อบรม: ${worker.inductionDate ?? "-"}', style: const TextStyle(fontSize: 11)),
                            Text(
                              'ใช้ได้ถึง: ${worker.inductionValidUntil ?? "-"}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('ปิด'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await SafetyPassPdfService.printSafetyPass(context, worker);
                          },
                          icon: const Icon(Icons.print_rounded, size: 16),
                          label: const Text('พิมพ์บัตร'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
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
    );
  }
}
