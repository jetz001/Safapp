import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../risk_assessment/presentation/providers/risk_assessment_providers.dart';
import '../../../ptw/presentation/notifiers/ptw_list_notifier.dart';
import '../../../audit_inspection/presentation/notifiers/audit_providers.dart';
import '../../../near_miss_incident/presentation/providers/accident_providers.dart';
import '../../../employee/presentation/providers/employee_providers.dart';

class LandingPage extends ConsumerWidget {
  final void Function(int targetIndex) onNavigate;

  const LandingPage({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(companyProfileNotifierProvider);
    final sessionsAsync = ref.watch(riskSessionsProvider);
    final ptwKpiAsync = ref.watch(ptwKpiProvider);
    final auditKpiAsync = ref.watch(auditKpiStatsProvider);
    final accidentAsync = ref.watch(accidentInvestigationsProvider);
    final employeesAsync = ref.watch(employeesProvider);

    final registeredEmployeeCount = employeesAsync.asData?.value.length ?? 0;

    final companyProfile = profileAsync.asData?.value;
    final rawName = companyProfile?.companyName.trim();
    final companyName = (rawName != null && rawName.isNotEmpty && rawName.toLowerCase() != 'safapp')
        ? rawName
        : 'บริษัท ไทยพัฒนาอุตสาหกรรมชิ้นส่วนยานยนต์ จำกัด (มหาชน)';
    final logoPath = companyProfile?.logoPath;
    final safetyOfficer = (companyProfile?.safetyOfficerName?.isNotEmpty == true && companyProfile!.safetyOfficerName!.toLowerCase() != 'safapp')
        ? companyProfile.safetyOfficerName!
        : 'นางสาวพัชราภรณ์ สุขสวัสดิ์ (จป.วิชาชีพ)';
    final safetyOfficerPhone = (companyProfile?.safetyOfficerPhone?.isNotEmpty == true && companyProfile!.safetyOfficerPhone!.toLowerCase() != 'safapp')
        ? companyProfile.safetyOfficerPhone!
        : '02-709-1234 ต่อ 105';
    final rawPolicy = companyProfile?.safetyPolicy?.trim();
    final safetyPolicy = (rawPolicy != null && rawPolicy.isNotEmpty && rawPolicy.toLowerCase() != 'safapp' && rawPolicy != '"" safapp"')
        ? rawPolicy
        : 'มุ่งมั่นสร้างความปลอดภัยในการทำงาน อุบัติเหตุต้องเป็นศูนย์ (Zero Accident Goal) พนักงานทุกคนมีส่วนร่วมและปฏิบัติตามมาตรฐานสากล';
    final totalSessions = sessionsAsync.asData?.value.length ?? 0;

    final activePtwCount = ptwKpiAsync.asData?.value.activeCount ?? 0;
    final totalPtwCount = ptwKpiAsync.asData?.value.totalPermits ?? 0;
    final auditCompliance = auditKpiAsync.asData?.value.averageComplianceRate ?? 100.0;

    final investigations = accidentAsync.asData?.value ?? [];
    final nearMissCount = investigations.where((i) => i.eventType == 'NEAR_MISS').length;
    final ltiCount = investigations.where((i) => i.eventType == 'LOST_TIME' || i.eventType == 'DISABILITY' || i.eventType == 'FATALITY' || i.daysLost > 0).length;

    final now = DateTime.now();
    final thaiMonths = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    final thaiDateStr = '${now.day} ${thaiMonths[now.month - 1]} ${now.year + 543}';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==============================================================
            // 1. HERO BANNER: Welcome & Organization Status
            // ==============================================================
            _buildHeroBanner(
              context: context,
              companyName: companyName,
              logoPath: logoPath,
              safetyPolicy: safetyPolicy,
              thaiDateStr: thaiDateStr,
            ),
            const SizedBox(height: 20),

            // ==============================================================
            // 2. LIVE KPI / STAT OVERVIEW
            // ==============================================================
            _buildKpiSection(
              context: context,
              registeredEmployeeCount: registeredEmployeeCount,
              totalSessions: totalSessions,
              activePtwCount: activePtwCount,
              totalPtwCount: totalPtwCount,
              auditCompliance: auditCompliance,
              nearMissCount: nearMissCount,
              ltiCount: ltiCount,
            ),
            const SizedBox(height: 24),

            // ==============================================================
            // 3. QUICK ACTION SHORTCUTS
            // ==============================================================
            _buildQuickActions(context),
            const SizedBox(height: 28),

            // ==============================================================
            // 4. CATEGORIZED MODULE SHOWCASE (15 Modules)
            // ==============================================================
            _buildModuleCategories(context),
            const SizedBox(height: 28),

            // ==============================================================
            // 5. EMERGENCY CONTACT & SAFETY OFFICER BAR
            // ==============================================================
            _buildEmergencyBar(
              safetyOfficer: safetyOfficer,
              safetyOfficerPhone: safetyOfficerPhone,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // 1. HERO BANNER WIDGET
  // ==============================================================
  Widget _buildHeroBanner({
    required BuildContext context,
    required String companyName,
    required String? logoPath,
    required String safetyPolicy,
    required String thaiDateStr,
  }) {
    return GlassContainer(
      blur: 25,
      opacity: 0.65,
      padding: const EdgeInsets.all(24.0),
      borderRadius: BorderRadius.circular(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 750;

          final logoWidget = Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: logoPath != null && File(logoPath).existsSync()
                ? ClipOval(child: Image.file(File(logoPath), fit: BoxFit.cover))
                : const Center(
                    child: Icon(Icons.shield_rounded, size: 44, color: Color(0xFF1E3A8A)),
                  ),
          );

          final titleContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 14, color: Color(0xFF1E3A8A)),
                        SizedBox(width: 5),
                        Text(
                          'ศูนย์ปฏิบัติการความปลอดภัย',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Zero Accident Goal 🛡️',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                companyName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      safetyPolicy,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );

          final dateBadge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF1E3A8A)),
                    const SizedBox(width: 6),
                    Text(
                      thaiDateStr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'สถานะระบบ: เชื่อมโยงพร้อมใช้งาน',
                  style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    logoWidget,
                    const SizedBox(width: 16),
                    Expanded(child: dateBadge),
                  ],
                ),
                const SizedBox(height: 16),
                titleContent,
              ],
            );
          }

          return Row(
            children: [
              logoWidget,
              const SizedBox(width: 20),
              Expanded(child: titleContent),
              const SizedBox(width: 20),
              dateBadge,
            ],
          );
        },
      ),
    );
  }

  // ==============================================================
  // 2. LIVE KPI / STAT OVERVIEW
  // ==============================================================
  Widget _buildKpiSection({
    required BuildContext context,
    required int registeredEmployeeCount,
    required int totalSessions,
    required int activePtwCount,
    required int totalPtwCount,
    required double auditCompliance,
    required int nearMissCount,
    required int ltiCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 800;

        final items = [
          _KpiItem(
            title: 'พนักงานในระบบ',
            value: '$registeredEmployeeCount คน',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF3B82F6),
            targetIndex: 7, // Employee Page
          ),
          _KpiItem(
            title: 'การประเมินความเสี่ยง JSA',
            value: totalSessions > 0 ? '$totalSessions ชุดงาน' : 'พร้อมใช้งาน',
            icon: Icons.assignment_rounded,
            color: const Color(0xFF10B981),
            targetIndex: 4, // JSA Page
          ),
          _KpiItem(
            title: 'ใบอนุญาต PTW / Audit',
            value: activePtwCount > 0
                ? 'PTW $activePtwCount ใบ (ทำงานอยู่)'
                : (totalPtwCount > 0
                    ? 'PTW $totalPtwCount ใบ • Audit ${auditCompliance.toStringAsFixed(0)}%'
                    : 'Audit สอดคล้อง ${auditCompliance.toStringAsFixed(0)}%'),
            icon: Icons.assignment_turned_in_rounded,
            color: const Color(0xFFF59E0B),
            targetIndex: 5, // PTW Page
          ),
          _KpiItem(
            title: 'สถิติ Near Miss & ปลอดภัย',
            value: ltiCount == 0
                ? (nearMissCount > 0
                    ? 'Near Miss $nearMissCount • Zero LTI 🛡️'
                    : '0 อุบัติเหตุสะสม (Zero LTI) 🛡️')
                : 'หยุดงาน $ltiCount ราย (Near Miss $nearMissCount)',
            icon: Icons.health_and_safety_rounded,
            color: const Color(0xFFEC4899),
            targetIndex: 3, // Near Miss Page
          ),
        ];

        if (isSmallScreen) {
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: items.map((item) => _buildKpiCard(item)).toList(),
          );
        }

        return Row(
          children: items
              .map(
                (item) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: item == items.last ? 0 : 16.0),
                    child: _buildKpiCard(item),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiItem item) {
    return InkWell(
      onTap: () => onNavigate(item.targetIndex),
      borderRadius: BorderRadius.circular(16),
      child: GlassContainer(
        blur: 15,
        opacity: 0.55,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // 3. QUICK ACTIONS SHORTCUTS
  // ==============================================================
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        title: 'แจ้ง Near Miss / เหตุการณ์',
        subtitle: 'รายงานเหตุการณ์ผิดปกติทันที',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFE11D48),
        targetIndex: 3,
      ),
      _QuickAction(
        title: 'ขอเปิดใบงาน PTW',
        subtitle: 'ใบอนุญาตทำงานที่มีความเสี่ยง',
        icon: Icons.assignment_turned_in_rounded,
        color: const Color(0xFFD97706),
        targetIndex: 5,
      ),
      _QuickAction(
        title: 'ประเมินความเสี่ยง JSA',
        subtitle: 'แบบ ปอ.๑ และ ปอ.๒ ตามกฎหมาย',
        icon: Icons.assignment_rounded,
        color: const Color(0xFF2563EB),
        targetIndex: 4,
      ),
      _QuickAction(
        title: 'ตรวจความปลอดภัย Audit',
        subtitle: 'Safety Inspection Checklist',
        icon: Icons.fact_check_rounded,
        color: const Color(0xFF059669),
        targetIndex: 6,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.flash_on_rounded, size: 18, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(width: 8),
            const Text(
              'ทางลัดปฏิบัติงานด่วน (Quick Actions)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 850;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isNarrow ? 2 : 4,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: isNarrow ? 2.3 : 2.5,
              ),
              itemBuilder: (context, index) {
                final action = actions[index];
                return InkWell(
                  onTap: () => onNavigate(action.targetIndex),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          action.color.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: action.color.withValues(alpha: 0.25), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: action.color.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: action.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: action.color.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(action.icon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                action.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                action.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ==============================================================
  // 4. CATEGORIZED MODULE SHOWCASE (15 Modules)
  // ==============================================================
  Widget _buildModuleCategories(BuildContext context) {
    final categories = [
      _CategoryGroup(
        title: 'หมวดที่ ๑: การควบคุมความเสี่ยง & ปฏิบัติงาน (Risk & Operations)',
        icon: Icons.shield_outlined,
        color: const Color(0xFF2563EB),
        modules: [
          _ModuleItem(
            name: 'JSA & ประเมินความเสี่ยง',
            desc: 'แบบประเมิน ปอ.๑ และ ปอ.๒ ตามกฎหมาย',
            icon: Icons.assignment_rounded,
            color: const Color(0xFF2563EB),
            targetIndex: 4,
          ),
          _ModuleItem(
            name: 'PTW ใบอนุญาตทำงาน',
            desc: 'ระบบขออนุมัติงานที่เสี่ยงอันตรายสูง',
            icon: Icons.assignment_turned_in_rounded,
            color: const Color(0xFFD97706),
            targetIndex: 5,
          ),
          _ModuleItem(
            name: 'Audit & Safety Inspection',
            desc: 'ตรวจความปลอดภัยประจำพื้นที่และอุปกรณ์',
            icon: Icons.fact_check_rounded,
            color: const Color(0xFF059669),
            targetIndex: 6,
          ),
          _ModuleItem(
            name: 'รายงานอุบัติเหตุ & Near Miss',
            desc: 'บันทึกเหตุการณ์ วิเคราะห์รากเหง้า RCA',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFE11D48),
            targetIndex: 3,
          ),
        ],
      ),
      _CategoryGroup(
        title: 'หมวดที่ ๒: บุคลากร สุขอนามัย & ผู้รับเหมา (People & Health)',
        icon: Icons.people_outline_rounded,
        color: const Color(0xFF7C3AED),
        modules: [
          _ModuleItem(
            name: 'ทะเบียนพนักงาน & ฝึกอบรม',
            desc: 'ข้อมูลบุคลากร ประวัติการอบรมความปลอดภัย',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF4F46E5),
            targetIndex: 7,
          ),
          _ModuleItem(
            name: 'จัดการผู้รับเหมา Contractor',
            desc: 'ขึ้นทะเบียน ควบคุมการเข้าปฏิบัติงาน',
            icon: Icons.engineering_rounded,
            color: const Color(0xFFEA580C),
            targetIndex: 8,
          ),
          _ModuleItem(
            name: 'อาชีวอนามัย & ตรวจสุขภาพ',
            desc: 'สมุดตรวจสุขภาพตามปัจจัยเสี่ยงและสุขอนามัย',
            icon: Icons.health_and_safety_rounded,
            color: const Color(0xFF0D9488),
            targetIndex: 9,
          ),
          _ModuleItem(
            name: 'อุปกรณ์ PPE & มาตรฐาน ASL',
            desc: 'ควบคุม เบิกจ่าย และตรวจสภาพอุปกรณ์',
            icon: Icons.construction_rounded,
            color: const Color(0xFF0284C7),
            targetIndex: 12,
          ),
        ],
      ),
      _CategoryGroup(
        title: 'หมวดที่ ๓: สารเคมี สิ่งแวดล้อม & ภาวะฉุกเฉิน (Chemicals & Environment)',
        icon: Icons.science_outlined,
        color: const Color(0xFF059669),
        modules: [
          _ModuleItem(
            name: 'บัญชีสารเคมีอันตราย & SDS',
            desc: 'เอกสารความปลอดภัยสารเคมี การจัดเก็บ',
            icon: Icons.science_rounded,
            color: const Color(0xFF9333EA),
            targetIndex: 10,
          ),
          _ModuleItem(
            name: 'การจัดการสิ่งแวดล้อม & ของเสีย',
            desc: 'มลพิษ อากาศ น้ำ กากของเสียอุตสาหกรรม',
            icon: Icons.thermostat_rounded,
            color: const Color(0xFF16A34A),
            targetIndex: 11,
          ),
          _ModuleItem(
            name: 'แผนตอบโต้ภาวะฉุกเฉิน',
            desc: 'ซ้อมหนีไฟ ทีมฉุกเฉิน แผนระงับเหตุอัคคีภัย',
            icon: Icons.local_hospital_rounded,
            color: const Color(0xFFDC2626),
            targetIndex: 13,
          ),
          _ModuleItem(
            name: 'ระบบความปลอดภัยทางไฟฟ้า',
            desc: 'ตรวจรับรองประจำปี ม.๑๒ แบบ ๕๖๒๘๙ LOTO & PM',
            icon: Icons.bolt_rounded,
            color: const Color(0xFFD97706),
            targetIndex: 14,
          ),
          _ModuleItem(
            name: 'เครื่องจักร ปั้นจั่น & หม้อน้ำ',
            desc: 'ตรวจรับรอง ปจ.๑ / ปจ.๒ Load Test หม้อน้ำ & อุปกรณ์ช่วยยก',
            icon: Icons.precision_manufacturing_rounded,
            color: const Color(0xFF0284C7),
            targetIndex: 15,
          ),
        ],
      ),
      _CategoryGroup(
        title: 'หมวดที่ ๔: การบริหารจัดการ & กฎหมาย (Governance & Compliance)',
        icon: Icons.gavel_rounded,
        color: const Color(0xFF475569),
        modules: [
          _ModuleItem(
            name: 'ข้อมูลองค์กร & ตั้งค่า SMS',
            desc: 'บัญชีกิจการกระทรวงแรงงาน ผู้ชำนาญการ ม.๓๓',
            icon: Icons.domain_rounded,
            color: const Color(0xFF1E3A8A),
            targetIndex: 1,
          ),
          _ModuleItem(
            name: 'แดชบอร์ดสรุปสถิติ (Dashboard)',
            desc: 'สถิติภาพรวม กราฟความปลอดภัยรายเดือน',
            icon: Icons.dashboard_rounded,
            color: const Color(0xFF6366F1),
            targetIndex: 2,
          ),
          _ModuleItem(
            name: 'คู่มือความปลอดภัย & SOPs',
            desc: 'ขั้นตอนการทำงานปลอดภัย มาตรฐานปฏิบัติการ',
            icon: Icons.menu_book_rounded,
            color: const Color(0xFFC2410C),
            targetIndex: 16,
          ),
          _ModuleItem(
            name: 'ทะเบียนกฎหมายความปลอดภัย',
            desc: 'Legal Register กฎหมายความปลอดภัยและสิ่งแวดล้อม',
            icon: Icons.gavel_rounded,
            color: const Color(0xFF334155),
            targetIndex: 17,
          ),
          _ModuleItem(
            name: 'คณะกรรมการ คปอ.',
            desc: 'เลือกตั้ง กกต. โครงสร้าง ประชม ๖ วาระ ติดตามมติ',
            icon: Icons.diversity_3_rounded,
            color: const Color(0xFF0D9488),
            targetIndex: 18,
          ),
          _ModuleItem(
            name: 'ตั้งค่าระบบ (Settings)',
            desc: 'กำหนดสิทธิ์ สำรองฐานข้อมูล ปรับแต่งแอป',
            icon: Icons.settings_rounded,
            color: const Color(0xFF64748B),
            targetIndex: 19,
          ),
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(width: 8),
            const Text(
              'ระบบโมดูลความปลอดภัยทั้งหมด (17 Modules Directory)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...categories.map((cat) => _buildCategorySection(cat)),
      ],
    );
  }

  Widget _buildCategorySection(_CategoryGroup group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: GlassContainer(
        blur: 20,
        opacity: 0.5,
        padding: const EdgeInsets.all(18.0),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: group.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(group.icon, color: group.color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: group.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final int crossCount = constraints.maxWidth < 650
                    ? 1
                    : constraints.maxWidth < 1000
                        ? 2
                        : group.modules.length > 4
                            ? 3
                            : group.modules.length;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: group.modules.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: crossCount == 1 ? 3.5 : 2.4,
                  ),
                  itemBuilder: (context, index) {
                    final mod = group.modules[index];
                    return InkWell(
                      onTap: () => onNavigate(mod.targetIndex),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: mod.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(mod.icon, color: mod.color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    mod.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    mod.desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // 5. EMERGENCY CONTACT & SAFETY OFFICER BAR
  // ==============================================================
  Widget _buildEmergencyBar({
    required String safetyOfficer,
    required String safetyOfficerPhone,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A).withValues(alpha: 0.9),
            const Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 750;

          final officerInfo = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade400.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.contact_phone_rounded, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'จป. ประจำสถานประกอบการ: $safetyOfficer',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'เบอร์ติดต่อ: $safetyOfficerPhone',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
                  ),
                ],
              ),
            ],
          );

          final hotlines = Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildHotlineChip('🚒 แจ้งเพลิงไหม้ ๑๙๙', '199'),
              _buildHotlineChip('🚑 แพทย์ฉุกเฉิน ๑๖๖๙', '1669'),
              _buildHotlineChip('📞 สายด่วน กสร. ๑๕๐๖', '1506'),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                officerInfo,
                const SizedBox(height: 12),
                const Divider(height: 1, color: Colors.white24),
                const SizedBox(height: 12),
                hotlines,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: officerInfo),
              const SizedBox(width: 16),
              hotlines,
            ],
          );
        },
      ),
    );
  }

  Widget _buildHotlineChip(String label, String number) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Helper Data Classes
// ----------------------------------------------------------------------
class _KpiItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int targetIndex;

  _KpiItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.targetIndex,
  });
}

class _QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int targetIndex;

  _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.targetIndex,
  });
}

class _CategoryGroup {
  final String title;
  final IconData icon;
  final Color color;
  final List<_ModuleItem> modules;

  _CategoryGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.modules,
  });
}

class _ModuleItem {
  final String name;
  final String desc;
  final IconData icon;
  final Color color;
  final int targetIndex;

  _ModuleItem({
    required this.name,
    required this.desc,
    required this.icon,
    required this.color,
    required this.targetIndex,
  });
}
