import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ptw_model.dart';
import '../../data/models/loto_isolation_model.dart';
import '../../domain/enums/ptw_status.dart';
import '../notifiers/ptw_list_notifier.dart';
import '../notifiers/ptw_live_controls_notifier.dart';
import '../widgets/gas_test_logger_card.dart';
import '../widgets/fire_watch_timer_card.dart';
import '../widgets/signature_pad_widget.dart';

/// Tab 3: Live Controls — Real-Time Field Operations Panel
class PtwLiveControlsTab extends ConsumerStatefulWidget {
  const PtwLiveControlsTab({super.key});

  @override
  ConsumerState<PtwLiveControlsTab> createState() => _PtwLiveControlsTabState();
}

class _PtwLiveControlsTabState extends ConsumerState<PtwLiveControlsTab> {
  String? _selectedPtwNumber;

  @override
  Widget build(BuildContext context) {
    final permitsAsync = ref.watch(ptwListProvider);

    return permitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
      data: (permits) {
        final activePermits = permits
            .where((p) => p.status == PtwStatus.active || p.status == PtwStatus.extendedHandover)
            .toList();

        // Auto-select if only one active permit and none currently selected
        if (_selectedPtwNumber == null && activePermits.length == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && activePermits.isNotEmpty) {
              setState(() => _selectedPtwNumber = activePermits.first.ptwNumber);
            }
          });
        }

        final PtwModel? selectedPermit = activePermits.isEmpty
            ? null
            : activePermits.cast<PtwModel?>().firstWhere(
                (p) => p?.ptwNumber == _selectedPtwNumber,
                orElse: () => activePermits.firstOrNull,
              );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active PTW Selector
              _buildPermitSelector(activePermits, selectedPermit?.ptwNumber),
              const SizedBox(height: 16),

              if (activePermits.isEmpty || selectedPermit == null)
                _buildNoActivePermitsCard()
              else ...[
                // Show the selected permit
                _buildSelectedPermitBanner(selectedPermit),
                const SizedBox(height: 16),

                // Gas Test Logger (Confined Space only)
                if (selectedPermit.isConfinedSpaceWork) ...[
                  _buildSectionHeader('ระบบตรวจวัดแก๊ส (Gas Test Logger)', Icons.air, Colors.purple),
                  const SizedBox(height: 8),
                  GasTestLoggerCard(
                    ptwNumber: selectedPermit.ptwNumber,
                    existingLogs: selectedPermit.gasTestLogs,
                    onLogSaved: (_) => ref.read(ptwListProvider.notifier).refresh(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Fire Watch Timer (Hot Work only)
                if (selectedPermit.isHotWork) ...[
                  _buildSectionHeader('ระบบจับเวลาเฝ้าระวังไฟ (30 นาที)', Icons.local_fire_department, Colors.red),
                  const SizedBox(height: 8),
                  FireWatchTimerCard(
                    ptwNumber: selectedPermit.ptwNumber,
                    existingModel: selectedPermit.fireWatch,
                    onCompleted: (_) => ref.read(ptwListProvider.notifier).refresh(),
                  ),
                  const SizedBox(height: 16),
                ],

                // LOTO Status Panel (Electrical/LOTO)
                if (selectedPermit.isElectricalLotoWork) ...[
                  _buildSectionHeader('สถานะการล็อคพลังงาน LOTO', Icons.lock, Colors.amber.shade800),
                  const SizedBox(height: 8),
                  _buildLotoPanel(selectedPermit),
                  const SizedBox(height: 16),
                ],

                // Shift Handover Sign-off
                _buildSectionHeader('ส่งมอบงานระหว่างกะ (Shift Handover)', Icons.swap_horiz, Colors.blue.shade700),
                const SizedBox(height: 8),
                _buildShiftHandoverPanel(selectedPermit),
                const SizedBox(height: 80),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Permit Selector ───────────────────────────────────────────────────────

  Widget _buildPermitSelector(List<PtwModel> activePermits, String? selectedPtwNumber) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text('ใบอนุญาตที่กำลังดำเนินการ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: activePermits.isNotEmpty ? Colors.green.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${activePermits.length} ใบ',
                    style: TextStyle(
                      color: activePermits.isNotEmpty ? Colors.green.shade800 : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (activePermits.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: (selectedPtwNumber != null && activePermits.any((p) => p.ptwNumber == selectedPtwNumber))
                    ? selectedPtwNumber
                    : activePermits.firstOrNull?.ptwNumber,
                items: activePermits
                    .map((p) => DropdownMenuItem(
                          value: p.ptwNumber,
                          child: Row(
                            children: [
                              Icon(p.primaryRiskType.icon, color: p.primaryRiskType.color, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(p.ptwNumber, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text(p.workTitle, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPtwNumber = v),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  labelText: 'เลือกใบอนุญาตที่ต้องการควบคุม',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoActivePermitsCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.pause_circle_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('ไม่มีใบอนุญาตที่กำลังดำเนินการ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'ใบอนุญาตจะปรากฏที่นี่เมื่อได้รับการอนุมัติและอยู่ในสถานะ "กำลังปฏิบัติงาน"',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPermitBanner(PtwModel permit) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [permit.primaryRiskType.color.withAlpha(230), permit.primaryRiskType.color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(permit.primaryRiskType.icon, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(permit.ptwNumber, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(permit.workTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${permit.plantArea} — ${permit.specificLocation}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(permit.status.labelTh, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              Text(permit.applicantName, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ── LOTO Panel ────────────────────────────────────────────────────────────

  Widget _buildLotoPanel(PtwModel permit) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (permit.lotoIsolations.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.lock_open, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('ยังไม่ได้บันทึกจุดตัดแยกพลังงาน', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              )
            else
              ...permit.lotoIsolations.asMap().entries.map((entry) {
                final i = entry.key;
                final loto = entry.value;
                return _buildLotoRow(i, loto, permit.ptwNumber);
              }),

            // Summary
            if (permit.lotoIsolations.isNotEmpty) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('จำนวนจุดทั้งหมด: ${permit.lotoIsolations.length}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    'ยืนยันแล้ว: ${permit.lotoIsolations.where((l) => l.isZeroEnergyVerified).length}/${permit.lotoIsolations.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: permit.isLotoVerified ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLotoRow(int index, LotoIsolationModel loto, String ptwNumber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: loto.isZeroEnergyVerified ? Colors.green.shade50 : Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: loto.isZeroEnergyVerified ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(loto.energyType.icon, color: loto.isZeroEnergyVerified ? Colors.green : Colors.red, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loto.equipmentTagNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(loto.equipmentName, style: const TextStyle(fontSize: 12)),
                  Text('${loto.energyType.labelTh} | กุญแจ: ${loto.padlockTagNo}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  if (loto.isZeroEnergyVerified)
                    Text('✓ ยืนยันโดย: ${loto.verifiedBy}',
                        style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: loto.isZeroEnergyVerified,
                  onChanged: (v) async {
                    final nameCtrl = TextEditingController(text: loto.verifiedBy);
                    final confirmedName = await _showVerifierDialog(context, nameCtrl, v);
                    if (confirmedName != null) {
                      final repo = ref.read(ptwRepositoryProvider);
                      await repo.toggleLotoZeroEnergy(loto.isolationId, v, confirmedName);
                      ref.invalidate(ptwListProvider);
                    }
                  },
                  activeColor: Colors.green,
                ),
                Text(loto.isZeroEnergyVerified ? 'พลังงานศูนย์' : 'ยังไม่ยืนยัน',
                    style: TextStyle(
                      fontSize: 10,
                      color: loto.isZeroEnergyVerified ? Colors.green : Colors.red,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showVerifierDialog(
    BuildContext context,
    TextEditingController nameCtrl,
    bool newValue,
  ) async {
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(newValue ? 'ยืนยันพลังงานศูนย์' : 'ยกเลิกการยืนยัน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              newValue
                  ? 'โปรดระบุชื่อผู้ยืนยันว่าพลังงานตกค้างเป็นศูนย์ (0V / 0 bar)'
                  : 'โปรดระบุชื่อผู้ยกเลิกการยืนยัน',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'ชื่อผู้ยืนยัน',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameCtrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Shift Handover Panel ──────────────────────────────────────────────────

  Widget _buildShiftHandoverPanel(PtwModel permit) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'การส่งมอบงานระหว่างกะเป็นขั้นตอนบังคับตาม พ.ร.บ. ๒๕๕๔ มาตรา ๘ เพื่อให้ผู้รับช่วงงานรับรู้ถึงสภาพความเสี่ยงและมาตรการควบคุม',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _initiateShiftHandover(context, permit, 'OUTGOING'),
                    icon: const Icon(Icons.logout),
                    label: const Text('ลงนามส่งมอบ (กะออก)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _initiateShiftHandover(context, permit, 'INCOMING'),
                    icon: const Icon(Icons.login),
                    label: const Text('รับมอบงาน (กะเข้า)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (permit.handoverSignedAt != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'ส่งมอบงานล่าสุด: ${permit.handoverSignedAt?.substring(0, 19).replaceAll('T', ' ')}',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _initiateShiftHandover(BuildContext context, PtwModel permit, String role) async {
    final sigCtrl = SignaturePadController();
    final nameCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(role == 'OUTGOING' ? 'ลงนามส่งมอบงาน (กะออก)' : 'รับมอบงาน (กะเข้า)'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: role == 'OUTGOING' ? 'ชื่อหัวหน้ากะผู้ส่งมอบ' : 'ชื่อหัวหน้ากะผู้รับมอบ',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SignaturePadWidget(
                controller: sigCtrl,
                height: 160,
                placeholderText: role == 'OUTGOING' ? 'ลายมือชื่อหัวหน้ากะผู้ส่งมอบ' : 'ลายมือชื่อหัวหน้ากะผู้รับมอบ',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              sigCtrl.dispose();
              Navigator.pop(context);
            },
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              String? sigPath;
              if (sigCtrl.isNotEmpty) sigPath = await sigCtrl.saveToFile(ptwNumber: permit.ptwNumber, roleKey: 'handover_${role.toLowerCase()}');
              if (mounted) {
                final repo = ref.read(ptwRepositoryProvider);
                final updated = permit.copyWith(
                  handoverSignaturePath: sigPath,
                  handoverSignedAt: DateTime.now().toIso8601String(),
                );
                await repo.savePermit(updated);
                ref.invalidate(ptwListProvider);
                sigCtrl.dispose();
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('ยืนยันลงนาม', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
