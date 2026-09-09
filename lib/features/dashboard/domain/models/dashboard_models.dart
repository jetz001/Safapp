import 'package:flutter/material.dart';

enum DashboardChartMetric {
  trir,
  caseCounts,
}

class SafetyOverviewKpi {
  final int safeDaysCount;
  final int ltiCountThisYear;
  final int nearMissCountThisYear;
  final int activePtwToday;
  final double trirValue;
  final String? lastIncidentDate;
  final int totalWorkforce;

  const SafetyOverviewKpi({
    required this.safeDaysCount,
    required this.ltiCountThisYear,
    required this.nearMissCountThisYear,
    required this.activePtwToday,
    required this.trirValue,
    this.lastIncidentDate,
    required this.totalWorkforce,
  });

  factory SafetyOverviewKpi.empty() {
    return const SafetyOverviewKpi(
      safeDaysCount: 0,
      ltiCountThisYear: 0,
      nearMissCountThisYear: 0,
      activePtwToday: 0,
      trirValue: 0.0,
      totalWorkforce: 0,
    );
  }
}

class ModuleSummaryItem {
  final String title;
  final String mainValue;
  final String subValue;
  final IconData icon;
  final Color color;
  final int targetRouteIndex;
  final String badgeText;
  final bool isAttentionNeeded;

  const ModuleSummaryItem({
    required this.title,
    required this.mainValue,
    required this.subValue,
    required this.icon,
    required this.color,
    required this.targetRouteIndex,
    required this.badgeText,
    this.isAttentionNeeded = false,
  });
}

class MonthlyTrendSpot {
  final int monthIndex; // 0 to 11
  final String monthName; // ม.ค. ถึง ธ.ค.
  final int nearMissCount;
  final int incidentCount;
  final double manHours;
  final double trirRate;

  const MonthlyTrendSpot({
    required this.monthIndex,
    required this.monthName,
    required this.nearMissCount,
    required this.incidentCount,
    required this.manHours,
    required this.trirRate,
  });

  int get totalCases => nearMissCount + incidentCount;
}

class StatutoryAlertItem {
  final String title;
  final String description;
  final String category;
  final String urgency; // 'CRITICAL', 'WARNING', 'INFO'
  final String? dueDate;
  final int targetRouteIndex;
  final IconData icon;

  const StatutoryAlertItem({
    required this.title,
    required this.description,
    required this.category,
    required this.urgency,
    this.dueDate,
    required this.targetRouteIndex,
    required this.icon,
  });

  Color get urgencyColor {
    switch (urgency) {
      case 'CRITICAL':
        return const Color(0xFFEF4444); // Red
      case 'WARNING':
        return const Color(0xFFF59E0B); // Amber
      case 'INFO':
      default:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  String get urgencyLabel {
    switch (urgency) {
      case 'CRITICAL':
        return 'ด่วนมาก';
      case 'WARNING':
        return 'ต้องแก้ไข';
      case 'INFO':
      default:
        return 'แจ้งเตือน';
    }
  }
}

class DashboardData {
  final SafetyOverviewKpi kpi;
  final List<ModuleSummaryItem> moduleSummaries;
  final List<MonthlyTrendSpot> monthlyTrends;
  final List<StatutoryAlertItem> alerts;
  final String companyName;

  const DashboardData({
    required this.kpi,
    required this.moduleSummaries,
    required this.monthlyTrends,
    required this.alerts,
    required this.companyName,
  });

  factory DashboardData.empty() {
    return DashboardData(
      kpi: SafetyOverviewKpi.empty(),
      moduleSummaries: const [],
      monthlyTrends: const [],
      alerts: const [],
      companyName: '',
    );
  }
}
