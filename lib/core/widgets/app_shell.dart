import 'package:flutter/material.dart';
// Phase 1 & 2
import 'package:safety_superapp/features/near_miss_incident/presentation/pages/near_miss_form_page.dart';
import 'package:safety_superapp/features/employee/presentation/pages/employee_page.dart';
import 'package:safety_superapp/features/settings/presentation/pages/settings_page.dart';
import 'package:safety_superapp/features/sms_setup/presentation/pages/sms_setup_page.dart';
import 'package:safety_superapp/features/safety_manual/presentation/pages/manuals_page.dart';

// Phase 3
import 'package:safety_superapp/features/chemicals/presentation/pages/chemicals_page.dart';
import 'package:safety_superapp/features/emergency/presentation/pages/emergency_page.dart';
import 'package:safety_superapp/features/environment/presentation/pages/environment_page.dart';
import 'package:safety_superapp/features/risk_assessment/presentation/pages/jsa_page.dart';
import 'package:safety_superapp/features/ptw/presentation/pages/ptw_page.dart';
import 'package:safety_superapp/features/ppe_asl/presentation/pages/ppe_page.dart';

// Phase 4
import 'package:safety_superapp/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:safety_superapp/features/legal_register/presentation/pages/legal_page.dart';
import 'package:safety_superapp/features/audit_inspection/presentation/pages/audit_page.dart';
import 'package:safety_superapp/features/contractor/presentation/pages/contractor_page.dart';
import 'package:safety_superapp/features/health_hygiene/presentation/pages/health_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({Key? key}) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const SmsSetupPage(), // 0
    const DashboardPage(), // 1
    const NearMissFormPage(), // 2
    const JsaPage(), // 3
    const PtwPage(), // 4
    const AuditPage(), // 5
    const EmployeePage(), // 6
    const ContractorPage(), // 7
    const HealthPage(), // 8
    const ChemicalsPage(), // 9
    const EnvironmentPage(), // 10
    const PpePage(), // 11
    const EmergencyPage(), // 12
    const ManualsPage(), // 13
    const LegalPage(), // 14
    const SettingsPage(), // 15
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 100, // Fixed width for sidebar
            color: Colors.white,
            child: Column(
              children: [
                // App Logo Placeholder
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF1E3A8A).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Icon(Icons.shield, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 8),
                      const Text('SAFAPP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: NavigationRail(
                              selectedIndex: _selectedIndex,
                              onDestinationSelected: (int index) {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                              labelType: NavigationRailLabelType.all,
                              backgroundColor: Colors.white,
                              useIndicator: true,
                              indicatorColor: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                              selectedIconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
                              unselectedIconTheme: const IconThemeData(color: Color(0xFF64748B)),
                              selectedLabelTextStyle: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 11),
                              unselectedLabelTextStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                              destinations: const [
                                NavigationRailDestination(icon: Icon(Icons.domain_outlined), selectedIcon: Icon(Icons.domain), label: Text('องค์กร')),
                                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('หน้าหลัก')),
                                NavigationRailDestination(icon: Icon(Icons.warning_amber_outlined), selectedIcon: Icon(Icons.warning), label: Text('อุบัติเหตุ')),
                                NavigationRailDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: Text('JSA')),
                                NavigationRailDestination(icon: Icon(Icons.assignment_turned_in_outlined), selectedIcon: Icon(Icons.assignment_turned_in), label: Text('PTW')),
                                NavigationRailDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check), label: Text('Audit')),
                                NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('พนักงาน')),
                                NavigationRailDestination(icon: Icon(Icons.engineering_outlined), selectedIcon: Icon(Icons.engineering), label: Text('ผู้รับเหมา')),
                                NavigationRailDestination(icon: Icon(Icons.health_and_safety_outlined), selectedIcon: Icon(Icons.health_and_safety), label: Text('สุขภาพ')),
                                NavigationRailDestination(icon: Icon(Icons.science_outlined), selectedIcon: Icon(Icons.science), label: Text('สารเคมี')),
                                NavigationRailDestination(icon: Icon(Icons.thermostat_outlined), selectedIcon: Icon(Icons.thermostat), label: Text('สิ่งแวดล้อม')),
                                NavigationRailDestination(icon: Icon(Icons.construction_outlined), selectedIcon: Icon(Icons.construction), label: Text('PPE')),
                                NavigationRailDestination(icon: Icon(Icons.local_hospital_outlined), selectedIcon: Icon(Icons.local_hospital), label: Text('ฉุกเฉิน')),
                                NavigationRailDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: Text('SOPs')),
                                NavigationRailDestination(icon: Icon(Icons.gavel_outlined), selectedIcon: Icon(Icons.gavel), label: Text('กฎหมาย')),
                                NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('ตั้งค่า')),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFE2E8F0)),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
