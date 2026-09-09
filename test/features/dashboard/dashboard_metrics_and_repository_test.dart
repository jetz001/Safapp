import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/dashboard/domain/models/dashboard_models.dart';

void main() {
  group('Dashboard Models & Metric Tests', () {
    test('SafetyOverviewKpi calculates TRIR and sets properties correctly', () {
      const kpi = SafetyOverviewKpi(
        safeDaysCount: 252,
        ltiCountThisYear: 0,
        nearMissCountThisYear: 1,
        activePtwToday: 1,
        trirValue: 0.0,
        totalWorkforce: 89,
      );

      expect(kpi.safeDaysCount, 252);
      expect(kpi.ltiCountThisYear, 0);
      expect(kpi.nearMissCountThisYear, 1);
      expect(kpi.activePtwToday, 1);
      expect(kpi.trirValue, 0.0);
      expect(kpi.totalWorkforce, 89);
    });

    test('MonthlyTrendSpot aggregates total cases and validates TRIR rate', () {
      const spot = MonthlyTrendSpot(
        monthIndex: 0,
        monthName: 'ม.ค.',
        nearMissCount: 2,
        incidentCount: 1,
        manHours: 15664.0,
        trirRate: 12.77,
      );

      expect(spot.totalCases, 3);
      expect(spot.monthName, 'ม.ค.');
      expect(spot.trirRate, 12.77);
    });

    test('StatutoryAlertItem maps urgency levels to correct colors and labels', () {
      const criticalAlert = StatutoryAlertItem(
        title: 'CAR เกินกำหนด',
        description: 'แก้ไขระดับเสียงเกินมาตรฐาน',
        category: 'SMS ๒๕๖๕',
        urgency: 'CRITICAL',
        targetRouteIndex: 6,
        icon: Icons.warning_amber_rounded,
      );

      expect(criticalAlert.urgencyColor, const Color(0xFFEF4444));
      expect(criticalAlert.urgencyLabel, 'ด่วนมาก');
      expect(criticalAlert.targetRouteIndex, 6);

      const warningAlert = StatutoryAlertItem(
        title: 'CAR รอแก้ไข',
        description: 'ปั้นจั่น ปจ.๑',
        category: 'SMS ๒๕๖๕',
        urgency: 'WARNING',
        targetRouteIndex: 6,
        icon: Icons.warning_amber_rounded,
      );

      expect(warningAlert.urgencyColor, const Color(0xFFF59E0B));
      expect(warningAlert.urgencyLabel, 'ต้องแก้ไข');

      const infoAlert = StatutoryAlertItem(
        title: 'อบรมใกล้หมดอายุ',
        description: 'ใบรับรอง จป.หัวหน้างาน',
        category: 'ทะเบียนอบรม',
        urgency: 'INFO',
        targetRouteIndex: 7,
        icon: Icons.badge_rounded,
      );

      expect(infoAlert.urgencyColor, const Color(0xFF3B82F6));
      expect(infoAlert.urgencyLabel, 'แจ้งเตือน');
      expect(infoAlert.targetRouteIndex, 7);
    });

    test('ModuleSummaryItem encapsulates cross-module navigation indices', () {
      const item = ModuleSummaryItem(
        title: 'PTW ใบอนุญาตทำงาน',
        mainValue: '1 ใบ',
        subValue: 'Hot Work กำลังปฏิบัติงาน',
        icon: Icons.assignment_turned_in_rounded,
        color: Color(0xFF10B981),
        targetRouteIndex: 5,
        badgeText: 'Active',
      );

      expect(item.targetRouteIndex, 5);
      expect(item.title, 'PTW ใบอนุญาตทำงาน');
      expect(item.isAttentionNeeded, isFalse);
    });

    test('DashboardData initializes with empty defaults', () {
      final empty = DashboardData.empty();
      expect(empty.kpi.safeDaysCount, 0);
      expect(empty.moduleSummaries, isEmpty);
      expect(empty.monthlyTrends, isEmpty);
      expect(empty.alerts, isEmpty);
      expect(empty.companyName, isEmpty);
    });
  });
}
