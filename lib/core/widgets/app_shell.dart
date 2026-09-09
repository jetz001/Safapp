import 'package:flutter/material.dart';
import 'package:safety_superapp/core/constants/app_routes.dart';
import 'package:safety_superapp/core/widgets/glass_container.dart';

// Group 1: ภาพรวม & สถิติ
import 'package:safety_superapp/features/landing/presentation/pages/landing_page.dart';
import 'package:safety_superapp/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:safety_superapp/features/sms_setup/presentation/pages/sms_setup_page.dart';

// Group 2: งานควบคุมความเสี่ยงหน้างาน
import 'package:safety_superapp/features/risk_assessment/presentation/pages/jsa_page.dart';
import 'package:safety_superapp/features/ptw/presentation/pages/ptw_page.dart';
import 'package:safety_superapp/features/audit_inspection/presentation/pages/audit_page.dart';
import 'package:safety_superapp/features/near_miss_incident/presentation/pages/near_miss_form_page.dart';

// Group 3: บุคลากร สุขอนามัย & ผู้รับเหมา
import 'package:safety_superapp/features/employee/presentation/pages/employee_page.dart';
import 'package:safety_superapp/features/cpo/presentation/pages/cpo_main_page.dart';
import 'package:safety_superapp/features/contractor/presentation/pages/contractor_page.dart';
import 'package:safety_superapp/features/health_hygiene/presentation/pages/health_page.dart';
import 'package:safety_superapp/features/ppe_asl/presentation/pages/ppe_page.dart';

// Group 4: เทคนิควิศวกรรม & สิ่งแวดล้อม
import 'package:safety_superapp/features/machinery/presentation/pages/machinery_page.dart';
import 'package:safety_superapp/features/electrical/presentation/pages/electrical_page.dart';
import 'package:safety_superapp/features/chemicals/presentation/pages/chemicals_page.dart';
import 'package:safety_superapp/features/environment/presentation/pages/environment_page.dart';
import 'package:safety_superapp/features/emergency/presentation/pages/emergency_page.dart';

// Group 5: กฎหมาย มาตรฐาน & ตั้งค่า
import 'package:safety_superapp/features/legal_register/presentation/pages/legal_page.dart';
import 'package:safety_superapp/features/safety_manual/presentation/pages/manuals_page.dart';
import 'package:safety_superapp/features/settings/presentation/pages/settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = AppRoutes.home;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      // ── กลุ่มที่ ๑: ภาพรวม & สถิติ ──────────────────────────────────────────
      LandingPage(
        onNavigate: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ), // 0: AppRoutes.home
      DashboardPage(
        onNavigate: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ), // 1: AppRoutes.dashboard
      const SmsSetupPage(), // 2: AppRoutes.smsSetup

      // ── กลุ่มที่ ๒: การควบคุมความเสี่ยงหน้างาน ──────────────────────────────
      const JsaPage(), // 3: AppRoutes.jsa
      const PtwPage(), // 4: AppRoutes.ptw
      const AuditPage(), // 5: AppRoutes.audit
      const NearMissFormPage(), // 6: AppRoutes.nearMiss

      // ── กลุ่มที่ ๓: บุคลากร สุขอนามัย & ผู้รับเหมา ──────────────────────────
      const EmployeePage(), // 7: AppRoutes.employee
      const CpoMainPage(), // 8: AppRoutes.cpo
      const ContractorPage(), // 9: AppRoutes.contractor
      const HealthPage(), // 10: AppRoutes.health
      const PpePage(), // 11: AppRoutes.ppe

      // ── กลุ่มที่ ๔: เทคนิควิศวกรรม & สิ่งแวดล้อม ────────────────────────────
      const MachineryPage(), // 12: AppRoutes.machinery
      const ElectricalPage(), // 13: AppRoutes.electrical
      const ChemicalsPage(), // 14: AppRoutes.chemicals
      const EnvironmentPage(), // 15: AppRoutes.environment
      const EmergencyPage(), // 16: AppRoutes.emergency

      // ── กลุ่มที่ ๕: การกำกับดูแล นโยบาย & ตั้งค่า ───────────────────────────
      const LegalPage(), // 17: AppRoutes.legal
      const ManualsPage(), // 18: AppRoutes.manuals
      const SettingsPage(), // 19: AppRoutes.settings
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F2FE), // Light sky blue
              Color(0xFFF3E8FF), // Light purple
              Color(0xFFFCE7F3), // Light pink
            ],
          ),
        ),
        child: Row(
          children: [
            GlassContainer(
              blur: 30,
              opacity: 0.45,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: SizedBox(
                width: 104, // Compact, ergonomic width
                child: Column(
                  children: [
                    // ── App Brand Logo ────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.shield, color: Colors.white, size: 26),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'SAFAPP',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.5,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: Colors.white60),

                    // ── Categorized OSH Nav List ──────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          children: [
                            // หมวด ๑: ภาพรวม & สถิติ
                            _buildSectionDivider('ภาพรวม'),
                            _buildNavItem(
                              index: AppRoutes.home,
                              icon: Icons.home_outlined,
                              selectedIcon: Icons.home_rounded,
                              label: 'หน้าแรก',
                              tooltip: 'หน้าแรก / Portal Hub',
                            ),
                            _buildNavItem(
                              index: AppRoutes.dashboard,
                              icon: Icons.dashboard_outlined,
                              selectedIcon: Icons.dashboard_rounded,
                              label: 'แดชบอร์ด',
                              tooltip: 'แดชบอร์ดสถิติผู้บริหาร (TRIR & KPI)',
                            ),
                            _buildNavItem(
                              index: AppRoutes.smsSetup,
                              icon: Icons.domain_outlined,
                              selectedIcon: Icons.domain_rounded,
                              label: 'องค์กร',
                              tooltip: 'ข้อมูลองค์กร & ตั้งค่า SMS ๒๕๖๕',
                            ),

                            // หมวด ๒: งานควบคุมความเสี่ยงหน้างาน
                            _buildSectionDivider('หน้างาน'),
                            _buildNavItem(
                              index: AppRoutes.jsa,
                              icon: Icons.assignment_outlined,
                              selectedIcon: Icons.assignment_rounded,
                              label: 'JSA',
                              tooltip: 'JSA & ประเมินความเสี่ยง ปอ.๑ / ปอ.๒',
                            ),
                            _buildNavItem(
                              index: AppRoutes.ptw,
                              icon: Icons.assignment_turned_in_outlined,
                              selectedIcon: Icons.assignment_turned_in_rounded,
                              label: 'PTW',
                              tooltip: 'PTW ใบอนุญาตทำงานเสี่ยงอันตรายสูง',
                            ),
                            _buildNavItem(
                              index: AppRoutes.audit,
                              icon: Icons.fact_check_outlined,
                              selectedIcon: Icons.fact_check_rounded,
                              label: 'Audit',
                              tooltip: 'ศูนย์ตรวจประเมินอัจฉริยะ SMS ๒๕๖๕',
                            ),
                            _buildNavItem(
                              index: AppRoutes.nearMiss,
                              icon: Icons.warning_amber_outlined,
                              selectedIcon: Icons.warning_rounded,
                              label: 'อุบัติเหตุ',
                              tooltip: 'รายงานอุบัติเหตุ & สอบสวน Near Miss',
                            ),

                            // หมวด ๓: บุคลากร สุขอนามัย & ผู้รับเหมา
                            _buildSectionDivider('บุคลากร'),
                            _buildNavItem(
                              index: AppRoutes.employee,
                              icon: Icons.people_outline_rounded,
                              selectedIcon: Icons.people_alt_rounded,
                              label: 'พนักงาน',
                              tooltip: 'ทะเบียนพนักงาน & ประวัติฝึกอบรม',
                            ),
                            _buildNavItem(
                              index: AppRoutes.cpo,
                              icon: Icons.diversity_3_outlined,
                              selectedIcon: Icons.diversity_3_rounded,
                              label: 'คปอ.',
                              tooltip: 'คณะกรรมการความปลอดภัยฯ (คปอ.)',
                            ),
                            _buildNavItem(
                              index: AppRoutes.contractor,
                              icon: Icons.engineering_outlined,
                              selectedIcon: Icons.engineering_rounded,
                              label: 'ผู้รับเหมา',
                              tooltip: 'จัดการความปลอดภัยผู้รับเหมา Contractor',
                            ),
                            _buildNavItem(
                              index: AppRoutes.health,
                              icon: Icons.health_and_safety_outlined,
                              selectedIcon: Icons.health_and_safety_rounded,
                              label: 'สุขภาพ',
                              tooltip: 'อาชีวอนามัย & ตรวจสุขภาพตามปัจจัยเสี่ยง',
                            ),
                            _buildNavItem(
                              index: AppRoutes.ppe,
                              icon: Icons.construction_outlined,
                              selectedIcon: Icons.construction_rounded,
                              label: 'PPE',
                              tooltip: 'อุปกรณ์ป้องกัน PPE & มาตรฐาน ASL',
                            ),

                            // หมวด ๔: เทคนิควิศวกรรม & สิ่งแวดล้อม
                            _buildSectionDivider('วิศวกรรม'),
                            _buildNavItem(
                              index: AppRoutes.machinery,
                              icon: Icons.precision_manufacturing_outlined,
                              selectedIcon: Icons.precision_manufacturing_rounded,
                              label: 'เครื่องจักร',
                              tooltip: 'เครื่องจักร ปั้นจั่น ปจ.๑/๒ & หม้อน้ำ',
                            ),
                            _buildNavItem(
                              index: AppRoutes.electrical,
                              icon: Icons.bolt_outlined,
                              selectedIcon: Icons.bolt_rounded,
                              label: 'ระบบไฟฟ้า',
                              tooltip: 'ระบบไฟฟ้า ตรวจ ม.๑๒ แบบ ๕๖๒๘๙ & LOTO',
                            ),
                            _buildNavItem(
                              index: AppRoutes.chemicals,
                              icon: Icons.science_outlined,
                              selectedIcon: Icons.science_rounded,
                              label: 'สารเคมี',
                              tooltip: 'บัญชีสารเคมีอันตราย & SDS สอ.๑/สอ.๓',
                            ),
                            _buildNavItem(
                              index: AppRoutes.environment,
                              icon: Icons.thermostat_outlined,
                              selectedIcon: Icons.thermostat_rounded,
                              label: 'สิ่งแวดล้อม',
                              tooltip: 'ตรวจสิ่งแวดล้อม แสง เสียง ความร้อน WBGT',
                            ),
                            _buildNavItem(
                              index: AppRoutes.emergency,
                              icon: Icons.local_hospital_outlined,
                              selectedIcon: Icons.local_hospital_rounded,
                              label: 'ฉุกเฉิน',
                              tooltip: 'แผนตอบโต้ภาวะฉุกเฉิน & ซ้อมหนีไฟ สปร.๔',
                            ),

                            // หมวด ๕: การกำกับดูแล นโยบาย & ตั้งค่า
                            _buildSectionDivider('กำกับดูแล'),
                            _buildNavItem(
                              index: AppRoutes.legal,
                              icon: Icons.gavel_outlined,
                              selectedIcon: Icons.gavel_rounded,
                              label: 'กฎหมาย',
                              tooltip: 'ทะเบียนกฎหมายความปลอดภัย Legal Register',
                            ),
                            _buildNavItem(
                              index: AppRoutes.manuals,
                              icon: Icons.menu_book_outlined,
                              selectedIcon: Icons.menu_book_rounded,
                              label: 'SOPs',
                              tooltip: 'คู่มือความปลอดภัย & มาตรฐาน SOPs',
                            ),
                            _buildNavItem(
                              index: AppRoutes.settings,
                              icon: Icons.settings_outlined,
                              selectedIcon: Icons.settings_rounded,
                              label: 'ตั้งค่า',
                              tooltip: 'ตั้งค่าระบบ & สำรองฐานข้อมูล',
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionDivider(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 6.0, left: 10.0, right: 10.0),
      child: Column(
        children: [
          Container(
            height: 1,
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required String tooltip,
  }) {
    final isSelected = _selectedIndex == index;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.5),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 4.0),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
