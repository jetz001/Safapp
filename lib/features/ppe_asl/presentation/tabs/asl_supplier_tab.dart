import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/asl_supplier_model.dart';
import '../providers/ppe_providers.dart';
import '../widgets/asl_supplier_dialog.dart';
import '../../services/ppe_excel_exporter.dart';

class AslSupplierTab extends ConsumerStatefulWidget {
  const AslSupplierTab({super.key});

  @override
  ConsumerState<AslSupplierTab> createState() => _AslSupplierTabState();
}

class _AslSupplierTabState extends ConsumerState<AslSupplierTab> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(aslSuppliersProvider);
    final selectedStatus = ref.watch(aslStatusFilterProvider);

    return Column(
      children: [
        // ── Top Search & Action Bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: Colors.white,
          child: Row(
            children: [
              // Search Input
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'ค้นหาชื่อบริษัท, รหัส ASL, หมวดหมู่อุปกรณ์...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(aslSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) {
                    ref.read(aslSearchQueryProvider.notifier).state = val;
                  },
                ),
              ),
              const SizedBox(width: 14),

              // Filter Status Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('สถานะการรับรองทั้งหมด')),
                      DropdownMenuItem(value: 'APPROVED', child: Text('ผ่านการรับรอง (Approved)')),
                      DropdownMenuItem(value: 'CONDITIONAL', child: Text('รับรองแบบมีเงื่อนไข')),
                      DropdownMenuItem(value: 'UNDER_REVIEW', child: Text('อยู่ระหว่างประเมิน')),
                      DropdownMenuItem(value: 'REJECTED', child: Text('ไม่ผ่านการรับรอง')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(aslStatusFilterProvider.notifier).state = val;
                      }
                    },
                  ),
                ),
              ),
              const Spacer(),

              // Export Excel Button
              OutlinedButton.icon(
                onPressed: () async {
                  final list = suppliersAsync.asData?.value ?? [];
                  if (list.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ไม่มีข้อมูลคู่ค้าสำหรับส่งออก')),
                    );
                    return;
                  }
                  await PpeExcelExporter.exportAslDirectory(list, context);
                },
                icon: const Icon(Icons.table_view_outlined, size: 18, color: Color(0xFF16A34A)),
                label: const Text('Export ASL Excel', style: TextStyle(color: Color(0xFF16A34A))),
              ),
              const SizedBox(width: 10),

              // Add Supplier Button
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const AslSupplierDialog(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.domain_add, size: 18),
                label: const Text('ลงทะเบียนคู่ค้า ASL', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Suppliers Cards List ──
        Expanded(
          child: suppliersAsync.when(
            data: (suppliers) {
              if (suppliers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'ไม่พบข้อมูลคู่ค้าในเงื่อนไขที่เลือก',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'คลิกปุ่ม "+ ลงทะเบียนคู่ค้า ASL" เพื่อเพิ่มผู้จัดจำหน่ายอุปกรณ์ PPE',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: suppliers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (ctx, idx) => _buildSupplierCard(suppliers[idx]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e', style: const TextStyle(color: Colors.red))),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierCard(AslSupplier sup) {
    final statusColor = Color(sup.evaluationStatus.colorValue);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Name, Code, Rating, Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business, color: Color(0xFF0D9488), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          sup.companyName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(sup.code, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        Text(
                          '${sup.rating.toStringAsFixed(1)} / 5.0 คะแนน',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        ),
                        if (sup.taxId != null) ...[
                          const SizedBox(width: 12),
                          Text('เลขผู้เสียภาษี: ${sup.taxId}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      sup.evaluationStatus.labelTh,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Details Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Contact & Address
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sup.contactPerson != null)
                      _buildInfoRow(Icons.person_outline, 'ผู้ติดต่อ: ${sup.contactPerson}'),
                    if (sup.phone != null)
                      _buildInfoRow(Icons.phone_outlined, 'โทร: ${sup.phone}'),
                    if (sup.email != null)
                      _buildInfoRow(Icons.email_outlined, 'อีเมล: ${sup.email}'),
                    if (sup.formattedAddress.isNotEmpty && sup.formattedAddress != '-')
                      _buildInfoRow(Icons.pin_drop_outlined, 'ที่อยู่: ${sup.formattedAddress}'),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Column 2: Supplied Categories & Certificates
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, size: 15, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'อุปกรณ์ที่จัดส่ง: ${sup.suppliedCategories}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (sup.standardCertificates != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.verified, size: 15, color: Color(0xFF16A34A)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'ใบรับรองมาตรฐาน: ${sup.standardCertificates}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    if (sup.validUntil != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.event_available, size: 15, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text('รับรองถึงวันที่: ${sup.validUntil}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        ],
                      ),
                    ],
                    if (sup.notes != null && sup.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('หมายเหตุ: ${sup.notes}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),

              // Action Buttons
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'แก้ไข',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AslSupplierDialog(supplier: sup),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    tooltip: 'ลบ',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('ยืนยันการลบคู่ค้า'),
                          content: Text('คุณต้องการลบ "${sup.companyName}" ออกจากทะเบียน ASL ใช่หรือไม่?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('ลบ'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(ppeRepositoryProvider).deleteSupplier(sup.id!);
                        ref.invalidate(aslSuppliersProvider);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))),
        ],
      ),
    );
  }
}
