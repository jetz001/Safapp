import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../data/models/sop_model.dart';
import 'sop_editor_dialog.dart';

class SopReaderDialog extends StatelessWidget {
  final SopModel sop;
  final void Function(SopModel updated) onUpdate;
  final void Function(int id) onDelete;

  const SopReaderDialog({
    super.key,
    required this.sop,
    required this.onUpdate,
    required this.onDelete,
  });

  Future<void> _openPdf(BuildContext context, String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบไฟล์เอกสาร PDF ในเครื่อง (ไฟล์อาจถูกย้ายหรือลบ)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเปิดไฟล์ได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันการลบ SOP'),
          ],
        ),
        content: Text('คุณต้องการลบเอกสาร "${sop.docCode}: ${sop.title}" ออกจากระบบหรือไม่?\n\n(หากโรงงานของคุณไม่มีงานส่วนนี้ สามารถลบออกได้ตลอดเวลา)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (sop.id != null) {
                onDelete(sop.id!);
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ลบเอกสาร'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPdf = sop.pdfFilePath != null && sop.pdfFilePath!.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 860,
        height: 800,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Top Bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sop.categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(sop.categoryIcon, color: sop.categoryColor, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        sop.categoryTh,
                        style: TextStyle(color: sop.categoryColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    sop.revision,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
                const Spacer(),
                if (hasPdf) ...[
                  ElevatedButton.icon(
                    onPressed: () => _openPdf(context, sop.pdfFilePath!),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('เปิดไฟล์ PDF ตัวเต็ม', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF0284C7)),
                  tooltip: 'แก้ไข SOP นี้',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => SopEditorDialog(
                        existing: sop,
                        onSave: (updated) {
                          onUpdate(updated);
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'ลบเอกสารนี้ (เช่น โรงงานไม่มีงานประเภทนี้)',
                  onPressed: () => _confirmDelete(context),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'ปิด',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 20),

            // Document Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Document Code & Title
                    Text(sop.docCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      sop.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('วันที่มีผล: ${sop.effectiveDate.toIso8601String().substring(0, 10)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 16),
                        const Icon(Icons.event_repeat, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('รอบทบทวน: ${sop.reviewDueDate.toIso8601String().substring(0, 10)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const Spacer(),
                        _buildStatusBadge(sop.status),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Required PPE Section
                    if (sop.requiredPpeList.isNotEmpty) ...[
                      _buildSectionHeader('อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคลที่จำเป็น (Required PPE)'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sop.requiredPpeList.map((ppeId) => _buildPpeBadge(ppeId)).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Purpose & Scope
                    if (sop.purpose != null && sop.purpose!.isNotEmpty) ...[
                      _buildSectionHeader('วัตถุประสงค์และขอบเขต (Purpose & Scope)'),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          sop.purpose!,
                          style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Critical Hazards & Golden Rules
                    if (sop.precautions != null && sop.precautions!.isNotEmpty) ...[
                      _buildSectionHeader('อันตรายและข้อควรระวังสำคัญ (Critical Hazards & Golden Rules)'),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          sop.precautions!,
                          style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF92400E)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Step by step procedures
                    _buildSectionHeader('ขั้นตอนการปฏิบัติงานทีละลำดับ (Step-by-Step Operating Procedures)'),
                    const SizedBox(height: 10),
                    if (sop.steps.isEmpty)
                      const Text('ไม่มีขั้นตอนระบุไว้', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sop.steps.length,
                        itemBuilder: (ctx, idx) {
                          final st = sop.steps[idx];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: const Color(0xFF0284C7),
                                        child: Text(
                                          '${st.stepNumber}',
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          st.title,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 38),
                                    child: Text(
                                      st.action,
                                      style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
                                    ),
                                  ),
                                  if (st.safetyCheckpoint != null && st.safetyCheckpoint!.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      margin: const EdgeInsets.only(left: 38),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle, size: 16, color: Color(0xFF0284C7)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'จุดตรวจความปลอดภัย: ${st.safetyCheckpoint}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 16),
                    // Emergency Actions
                    if (sop.emergencyProcedure != null && sop.emergencyProcedure!.isNotEmpty) ...[
                      _buildSectionHeader('ข้อปฏิบัติกรณีเกิดเหตุฉุกเฉิน / ปฐมพยาบาล (Emergency Actions)'),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.emergency, color: Color(0xFFDC2626), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sop.emergencyProcedure!,
                                style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF991B1B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // PDF Attachment Box
                    if (hasPdf) ...[
                      _buildSectionHeader('เอกสารคู่มือ PDF แนบ (Digital PDF Attachment)'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueGrey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                p.basename(sop.pdfFilePath!),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _openPdf(context, sop.pdfFilePath!),
                              icon: const Icon(Icons.open_in_new, size: 14),
                              label: const Text('เปิดอ่าน PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Sign-offs
                    _buildSectionHeader('การจัดทำและการอนุมัติ (Document Governance)'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          _buildGovBox('ผู้จัดทำ (Author)', sop.author ?? '-'),
                          _buildGovBox('ผู้ตรวจสอบ (Reviewer)', sop.reviewer ?? '-'),
                          _buildGovBox('ผู้อนุมัติ (Approver)', sop.approver ?? '-'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
    );
  }

  Widget _buildGovBox(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.green.shade50;
    Color fg = Colors.green.shade700;
    String label = 'พร้อมใช้งาน (Active)';

    if (status == 'DRAFT') {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade800;
      label = 'ฉบับร่าง (Draft)';
    } else if (status == 'ARCHIVED') {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade700;
      label = 'ยกเลิก/ไม่ใช้ (Archived)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildPpeBadge(String ppeId) {
    IconData icon = Icons.shield;
    String name = ppeId;

    switch (ppeId) {
      case 'HELMET':
        icon = Icons.engineering;
        name = 'หมวกนิรภัย';
        break;
      case 'SAFETY_GLASSES':
        icon = Icons.visibility;
        name = 'แว่นตานิรภัย';
        break;
      case 'EAR_PLUGS':
        icon = Icons.hearing;
        name = 'ที่อุดหู';
        break;
      case 'GLOVES':
        icon = Icons.pan_tool;
        name = 'ถุงมือนิรภัย';
        break;
      case 'BOOTS':
        icon = Icons.hiking;
        name = 'รองเท้าหัวเหล็ก';
        break;
      case 'HARNESS':
        icon = Icons.accessibility_new;
        name = 'ชุดกันตก (Harness)';
        break;
      case 'RESPIRATOR':
        icon = Icons.masks;
        name = 'หน้ากากกรองอากาศ';
        break;
      case 'FACE_SHIELD':
        icon = Icons.face;
        name = 'กระบังหน้า';
        break;
      case 'HI_VIS_VEST':
        icon = Icons.health_and_safety;
        name = 'เสื้อสะท้อนแสง';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF0284C7)),
          const SizedBox(width: 4),
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
        ],
      ),
    );
  }
}
