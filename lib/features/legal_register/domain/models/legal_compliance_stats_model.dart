import 'legal_master_item_model.dart';
import 'legal_compliance_assessment_model.dart';
import 'legal_capa_model.dart';

/// Compliance statistics per regulatory category.
class CategoryComplianceStats {
  final String category; // 'OSH_ACT', 'SAFETY_OFFICER', etc.
  final String categoryTitleTh;
  final int totalItems;
  final int applicableItems;
  final int compliantCount;
  final int nonCompliantCount;
  final int inProgressCount;
  final int notApplicableCount;
  final double basicCompliancePercent;
  final double riskWeightedCompliancePercent;
  final int highRiskNonCompliantCount;

  const CategoryComplianceStats({
    required this.category,
    required this.categoryTitleTh,
    required this.totalItems,
    required this.applicableItems,
    required this.compliantCount,
    required this.nonCompliantCount,
    required this.inProgressCount,
    required this.notApplicableCount,
    required this.basicCompliancePercent,
    required this.riskWeightedCompliancePercent,
    this.highRiskNonCompliantCount = 0,
  });

  LegalCategoryEnum get categoryEnum => LegalCategoryEnum.fromCode(category);

  CategoryComplianceStats copyWith({
    String? category,
    String? categoryTitleTh,
    int? totalItems,
    int? applicableItems,
    int? compliantCount,
    int? nonCompliantCount,
    int? inProgressCount,
    int? notApplicableCount,
    double? basicCompliancePercent,
    double? riskWeightedCompliancePercent,
    int? highRiskNonCompliantCount,
  }) {
    return CategoryComplianceStats(
      category: category ?? this.category,
      categoryTitleTh: categoryTitleTh ?? this.categoryTitleTh,
      totalItems: totalItems ?? this.totalItems,
      applicableItems: applicableItems ?? this.applicableItems,
      compliantCount: compliantCount ?? this.compliantCount,
      nonCompliantCount: nonCompliantCount ?? this.nonCompliantCount,
      inProgressCount: inProgressCount ?? this.inProgressCount,
      notApplicableCount: notApplicableCount ?? this.notApplicableCount,
      basicCompliancePercent: basicCompliancePercent ?? this.basicCompliancePercent,
      riskWeightedCompliancePercent: riskWeightedCompliancePercent ?? this.riskWeightedCompliancePercent,
      highRiskNonCompliantCount: highRiskNonCompliantCount ?? this.highRiskNonCompliantCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'category_title_th': categoryTitleTh,
      'total_items': totalItems,
      'applicable_items': applicableItems,
      'compliant_count': compliantCount,
      'non_compliant_count': nonCompliantCount,
      'in_progress_count': inProgressCount,
      'not_applicable_count': notApplicableCount,
      'basic_compliance_percent': basicCompliancePercent,
      'risk_weighted_compliance_percent': riskWeightedCompliancePercent,
      'high_risk_non_compliant_count': highRiskNonCompliantCount,
    };
  }

  factory CategoryComplianceStats.fromMap(Map<String, dynamic> map) {
    return CategoryComplianceStats(
      category: (map['category'] ?? '').toString(),
      categoryTitleTh: (map['category_title_th'] ?? map['categoryTitleTh'] ?? '').toString(),
      totalItems: int.tryParse((map['total_items'] ?? map['totalItems'] ?? '0').toString()) ?? 0,
      applicableItems: int.tryParse((map['applicable_items'] ?? map['applicableItems'] ?? '0').toString()) ?? 0,
      compliantCount: int.tryParse((map['compliant_count'] ?? map['compliantCount'] ?? '0').toString()) ?? 0,
      nonCompliantCount: int.tryParse((map['non_compliant_count'] ?? map['nonCompliantCount'] ?? '0').toString()) ?? 0,
      inProgressCount: int.tryParse((map['in_progress_count'] ?? map['inProgressCount'] ?? '0').toString()) ?? 0,
      notApplicableCount: int.tryParse((map['not_applicable_count'] ?? map['notApplicableCount'] ?? '0').toString()) ?? 0,
      basicCompliancePercent: double.tryParse((map['basic_compliance_percent'] ?? map['basicCompliancePercent'] ?? '0').toString()) ?? 0.0,
      riskWeightedCompliancePercent: double.tryParse((map['risk_weighted_compliance_percent'] ?? map['riskWeightedCompliancePercent'] ?? '0').toString()) ?? 0.0,
      highRiskNonCompliantCount: int.tryParse((map['high_risk_non_compliant_count'] ?? map['highRiskNonCompliantCount'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory CategoryComplianceStats.fromJson(Map<String, dynamic> json) => CategoryComplianceStats.fromMap(json);
}

/// Comprehensive Aggregated Compliance KPIs & Statistics Model for SAFAPP Legal Register.
class LegalComplianceStatsModel {
  final int totalItems;
  final int applicableItems;
  final int compliantCount;
  final int nonCompliantCount;
  final int inProgressCount;
  final int notApplicableCount;
  final double basicCompliancePercent; // CI (%)
  final double riskWeightedCompliancePercent; // WCI (%)
  final int highRiskNonCompliantCount;
  final int totalCapaCount;
  final int pendingCapaCount;
  final int inProgressCapaCount;
  final int completedCapaCount;
  final int overdueCapaCount;
  final List<CategoryComplianceStats> categoryBreakdown;
  final String? evaluatedDate;

  const LegalComplianceStatsModel({
    required this.totalItems,
    required this.applicableItems,
    required this.compliantCount,
    required this.nonCompliantCount,
    required this.inProgressCount,
    required this.notApplicableCount,
    required this.basicCompliancePercent,
    required this.riskWeightedCompliancePercent,
    this.highRiskNonCompliantCount = 0,
    this.totalCapaCount = 0,
    this.pendingCapaCount = 0,
    this.inProgressCapaCount = 0,
    this.completedCapaCount = 0,
    this.overdueCapaCount = 0,
    this.categoryBreakdown = const [],
    this.evaluatedDate,
  });

  /// Factory calculation from live lists of assessments and CAPAs
  factory LegalComplianceStatsModel.calculate({
    required List<LegalComplianceAssessmentModel> assessments,
    List<LegalCapaModel> capas = const [],
    String? evaluatedDate,
  }) {
    int total = assessments.length;
    int applicable = 0;
    int compliant = 0;
    int nonCompliant = 0;
    int inProgress = 0;
    int notApplicable = 0;
    int highRiskNonCompliant = 0;

    double totalApplicableWeight = 0.0;
    double compliantWeight = 0.0;

    // Group assessments by category
    final Map<String, List<LegalComplianceAssessmentModel>> byCategory = {};

    for (final a in assessments) {
      byCategory.putIfAbsent(a.category, () => []).add(a);

      if (a.isNotApplicable) {
        notApplicable++;
      } else {
        applicable++;
        final weight = a.riskWeight.toDouble();
        totalApplicableWeight += weight;

        if (a.isCompliant) {
          compliant++;
          compliantWeight += weight;
        } else if (a.isNonCompliant) {
          nonCompliant++;
          if (a.riskLevel.toUpperCase() == 'HIGH') {
            highRiskNonCompliant++;
          }
        } else if (a.isInProgress) {
          inProgress++;
        }
      }
    }

    // Basic Compliance Percent = (Compliant / Applicable) * 100
    final double basicPercent = applicable > 0
        ? ((compliant / applicable) * 100.0)
        : 100.0;

    // Risk-Weighted Compliance Percent = (Compliant Weight / Total Applicable Weight) * 100
    final double riskWeightedPercent = totalApplicableWeight > 0.0
        ? ((compliantWeight / totalApplicableWeight) * 100.0)
        : 100.0;

    // CAPA statistics
    int totalCapa = capas.length;
    int pendingCapa = 0;
    int inProgressCapa = 0;
    int completedCapa = 0;
    int overdueCapa = 0;

    for (final c in capas) {
      if (c.isCompleted) {
        completedCapa++;
      } else if (c.isOverdue) {
        overdueCapa++;
      } else if (c.status.toUpperCase() == 'IN_PROGRESS') {
        inProgressCapa++;
      } else {
        pendingCapa++;
      }
    }

    // Category breakdowns across standard 8 categories
    final List<CategoryComplianceStats> breakdown = [];
    for (final catEnum in LegalCategoryEnum.values) {
      final catItems = byCategory[catEnum.code] ?? [];
      int catTotal = catItems.length;
      int catApplicable = 0;
      int catCompliant = 0;
      int catNonCompliant = 0;
      int catInProgress = 0;
      int catNotApplicable = 0;
      int catHighRiskNonCompliant = 0;
      double catTotalWeight = 0.0;
      double catCompliantWeight = 0.0;

      for (final a in catItems) {
        if (a.isNotApplicable) {
          catNotApplicable++;
        } else {
          catApplicable++;
          final w = a.riskWeight.toDouble();
          catTotalWeight += w;

          if (a.isCompliant) {
            catCompliant++;
            catCompliantWeight += w;
          } else if (a.isNonCompliant) {
            catNonCompliant++;
            if (a.riskLevel.toUpperCase() == 'HIGH') {
              catHighRiskNonCompliant++;
            }
          } else if (a.isInProgress) {
            catInProgress++;
          }
        }
      }

      final double catBasicPct = catApplicable > 0
          ? ((catCompliant / catApplicable) * 100.0)
          : 100.0;

      final double catWeightedPct = catTotalWeight > 0.0
          ? ((catCompliantWeight / catTotalWeight) * 100.0)
          : 100.0;

      breakdown.add(CategoryComplianceStats(
        category: catEnum.code,
        categoryTitleTh: catEnum.titleTh,
        totalItems: catTotal,
        applicableItems: catApplicable,
        compliantCount: catCompliant,
        nonCompliantCount: catNonCompliant,
        inProgressCount: catInProgress,
        notApplicableCount: catNotApplicable,
        basicCompliancePercent: catBasicPct,
        riskWeightedCompliancePercent: catWeightedPct,
        highRiskNonCompliantCount: catHighRiskNonCompliant,
      ));
    }

    return LegalComplianceStatsModel(
      totalItems: total,
      applicableItems: applicable,
      compliantCount: compliant,
      nonCompliantCount: nonCompliant,
      inProgressCount: inProgress,
      notApplicableCount: notApplicable,
      basicCompliancePercent: double.parse(basicPercent.toStringAsFixed(1)),
      riskWeightedCompliancePercent: double.parse(riskWeightedPercent.toStringAsFixed(1)),
      highRiskNonCompliantCount: highRiskNonCompliant,
      totalCapaCount: totalCapa,
      pendingCapaCount: pendingCapa,
      inProgressCapaCount: inProgressCapa,
      completedCapaCount: completedCapa,
      overdueCapaCount: overdueCapa,
      categoryBreakdown: breakdown,
      evaluatedDate: evaluatedDate ?? DateTime.now().toIso8601String().substring(0, 10),
    );
  }

  LegalComplianceStatsModel copyWith({
    int? totalItems,
    int? applicableItems,
    int? compliantCount,
    int? nonCompliantCount,
    int? inProgressCount,
    int? notApplicableCount,
    double? basicCompliancePercent,
    double? riskWeightedCompliancePercent,
    int? highRiskNonCompliantCount,
    int? totalCapaCount,
    int? pendingCapaCount,
    int? inProgressCapaCount,
    int? completedCapaCount,
    int? overdueCapaCount,
    List<CategoryComplianceStats>? categoryBreakdown,
    String? evaluatedDate,
  }) {
    return LegalComplianceStatsModel(
      totalItems: totalItems ?? this.totalItems,
      applicableItems: applicableItems ?? this.applicableItems,
      compliantCount: compliantCount ?? this.compliantCount,
      nonCompliantCount: nonCompliantCount ?? this.nonCompliantCount,
      inProgressCount: inProgressCount ?? this.inProgressCount,
      notApplicableCount: notApplicableCount ?? this.notApplicableCount,
      basicCompliancePercent: basicCompliancePercent ?? this.basicCompliancePercent,
      riskWeightedCompliancePercent: riskWeightedCompliancePercent ?? this.riskWeightedCompliancePercent,
      highRiskNonCompliantCount: highRiskNonCompliantCount ?? this.highRiskNonCompliantCount,
      totalCapaCount: totalCapaCount ?? this.totalCapaCount,
      pendingCapaCount: pendingCapaCount ?? this.pendingCapaCount,
      inProgressCapaCount: inProgressCapaCount ?? this.inProgressCapaCount,
      completedCapaCount: completedCapaCount ?? this.completedCapaCount,
      overdueCapaCount: overdueCapaCount ?? this.overdueCapaCount,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      evaluatedDate: evaluatedDate ?? this.evaluatedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_items': totalItems,
      'applicable_items': applicableItems,
      'compliant_count': compliantCount,
      'non_compliant_count': nonCompliantCount,
      'in_progress_count': inProgressCount,
      'not_applicable_count': notApplicableCount,
      'basic_compliance_percent': basicCompliancePercent,
      'risk_weighted_compliance_percent': riskWeightedCompliancePercent,
      'high_risk_non_compliant_count': highRiskNonCompliantCount,
      'total_capa_count': totalCapaCount,
      'pending_capa_count': pendingCapaCount,
      'in_progress_capa_count': inProgressCapaCount,
      'completed_capa_count': completedCapaCount,
      'overdue_capa_count': overdueCapaCount,
      'category_breakdown': categoryBreakdown.map((e) => e.toMap()).toList(),
      'evaluated_date': evaluatedDate,
    };
  }

  factory LegalComplianceStatsModel.fromMap(Map<String, dynamic> map) {
    List<CategoryComplianceStats> breakdown = [];
    if (map['category_breakdown'] != null && map['category_breakdown'] is List) {
      breakdown = (map['category_breakdown'] as List)
          .map((e) => CategoryComplianceStats.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return LegalComplianceStatsModel(
      totalItems: int.tryParse((map['total_items'] ?? map['totalItems'] ?? '0').toString()) ?? 0,
      applicableItems: int.tryParse((map['applicable_items'] ?? map['applicableItems'] ?? '0').toString()) ?? 0,
      compliantCount: int.tryParse((map['compliant_count'] ?? map['compliantCount'] ?? '0').toString()) ?? 0,
      nonCompliantCount: int.tryParse((map['non_compliant_count'] ?? map['nonCompliantCount'] ?? '0').toString()) ?? 0,
      inProgressCount: int.tryParse((map['in_progress_count'] ?? map['inProgressCount'] ?? '0').toString()) ?? 0,
      notApplicableCount: int.tryParse((map['not_applicable_count'] ?? map['notApplicableCount'] ?? '0').toString()) ?? 0,
      basicCompliancePercent: double.tryParse((map['basic_compliance_percent'] ?? map['basicCompliancePercent'] ?? '0').toString()) ?? 0.0,
      riskWeightedCompliancePercent: double.tryParse((map['risk_weighted_compliance_percent'] ?? map['riskWeightedCompliancePercent'] ?? '0').toString()) ?? 0.0,
      highRiskNonCompliantCount: int.tryParse((map['high_risk_non_compliant_count'] ?? map['highRiskNonCompliantCount'] ?? '0').toString()) ?? 0,
      totalCapaCount: int.tryParse((map['total_capa_count'] ?? map['totalCapaCount'] ?? '0').toString()) ?? 0,
      pendingCapaCount: int.tryParse((map['pending_capa_count'] ?? map['pendingCapaCount'] ?? '0').toString()) ?? 0,
      inProgressCapaCount: int.tryParse((map['in_progress_capa_count'] ?? map['inProgressCapaCount'] ?? '0').toString()) ?? 0,
      completedCapaCount: int.tryParse((map['completed_capa_count'] ?? map['completedCapaCount'] ?? '0').toString()) ?? 0,
      overdueCapaCount: int.tryParse((map['overdue_capa_count'] ?? map['overdueCapaCount'] ?? '0').toString()) ?? 0,
      categoryBreakdown: breakdown,
      evaluatedDate: map['evaluated_date']?.toString() ?? map['evaluatedDate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory LegalComplianceStatsModel.fromJson(Map<String, dynamic> json) => LegalComplianceStatsModel.fromMap(json);
}
