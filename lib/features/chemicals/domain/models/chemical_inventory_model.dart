import 'dart:convert';
import 'package:flutter/material.dart';

/// Expiry status of Safety Data Sheet (SDS) based on statutory review cycles.
enum SdsExpiryStatus {
  /// More than 90 days remaining until required review (Valid)
  normal,

  /// 61 to 90 days remaining (Attention needed)
  near90,

  /// 31 to 60 days remaining (Review planning)
  near60,

  /// 0 to 30 days remaining (Urgent review required)
  near30,

  /// Review cycle overdue (Expired / Non-compliant)
  expired,

  /// No SDS issue date recorded
  noSds,
}

/// Static helper calculations for SDS validity and review cycles.
class SdsExpiryCalculation {
  /// Calculates the expiry date by adding [validityYears] (default 3 or 5) to [issueDate].
  static DateTime? getExpiryDate(DateTime? issueDate, {int validityYears = 3}) {
    if (issueDate == null) return null;
    return DateTime(
      issueDate.year + validityYears,
      issueDate.month,
      issueDate.day,
    );
  }

  /// Calculates the number of days remaining until SDS expires.
  static int getDaysRemaining(DateTime? issueDate, {int validityYears = 3}) {
    if (issueDate == null) return -99999;
    final expiry = getExpiryDate(issueDate, validityYears: validityYears);
    if (expiry == null) return -99999;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryNormalized = DateTime(expiry.year, expiry.month, expiry.day);
    return expiryNormalized.difference(today).inDays;
  }

  /// Determines the status enum based on issue date and validity cycle.
  static SdsExpiryStatus calculateStatus(DateTime? issueDate, {int validityYears = 3}) {
    if (issueDate == null) return SdsExpiryStatus.noSds;
    final days = getDaysRemaining(issueDate, validityYears: validityYears);
    if (days < 0) return SdsExpiryStatus.expired;
    if (days <= 30) return SdsExpiryStatus.near30;
    if (days <= 60) return SdsExpiryStatus.near60;
    if (days <= 90) return SdsExpiryStatus.near90;
    return SdsExpiryStatus.normal;
  }

  static Color getStatusColor(SdsExpiryStatus status) {
    switch (status) {
      case SdsExpiryStatus.normal:
        return const Color(0xFF10B981); // Emerald Green
      case SdsExpiryStatus.near90:
        return const Color(0xFFF59E0B); // Amber / Yellow
      case SdsExpiryStatus.near60:
        return const Color(0xFFFB923C); // Orange
      case SdsExpiryStatus.near30:
        return const Color(0xFFF97316); // Red-Orange (Urgent)
      case SdsExpiryStatus.expired:
        return const Color(0xFFEF4444); // Red
      case SdsExpiryStatus.noSds:
        return const Color(0xFF9CA3AF); // Gray
    }
  }

  static Color getStatusBackgroundColor(SdsExpiryStatus status) {
    switch (status) {
      case SdsExpiryStatus.normal:
        return const Color(0xFFECFDF5);
      case SdsExpiryStatus.near90:
        return const Color(0xFFFFFBEB);
      case SdsExpiryStatus.near60:
        return const Color(0xFFFFF7ED);
      case SdsExpiryStatus.near30:
        return const Color(0xFFFFEDD5);
      case SdsExpiryStatus.expired:
        return const Color(0xFFFEF2F2);
      case SdsExpiryStatus.noSds:
        return const Color(0xFFF3F4F6);
    }
  }

  static String getStatusLabelTh(SdsExpiryStatus status, {int? daysRemaining}) {
    switch (status) {
      case SdsExpiryStatus.normal:
        return daysRemaining != null ? 'ปกติ (เหลือ $daysRemaining วัน)' : 'ปกติ (Valid)';
      case SdsExpiryStatus.near90:
        return daysRemaining != null ? 'ใกล้หมดอายุ (เหลือ $daysRemaining วัน)' : 'ใกล้หมดอายุ (90 วัน)';
      case SdsExpiryStatus.near60:
        return daysRemaining != null ? 'ใกล้หมดอายุ (เหลือ $daysRemaining วัน)' : 'ใกล้หมดอายุ (60 วัน)';
      case SdsExpiryStatus.near30:
        return daysRemaining != null ? 'ใกล้หมดอายุเร่งด่วน (เหลือ $daysRemaining วัน)' : 'ใกล้หมดอายุเร่งด่วน (30 วัน)';
      case SdsExpiryStatus.expired:
        return daysRemaining != null ? 'หมดอายุแล้ว (${daysRemaining.abs()} วันก่อน)' : 'หมดอายุแล้ว (Expired)';
      case SdsExpiryStatus.noSds:
        return 'ยังไม่มีเอกสาร SDS';
    }
  }

  static IconData getStatusIcon(SdsExpiryStatus status) {
    switch (status) {
      case SdsExpiryStatus.normal:
        return Icons.verified_rounded;
      case SdsExpiryStatus.near90:
      case SdsExpiryStatus.near60:
        return Icons.access_time_rounded;
      case SdsExpiryStatus.near30:
        return Icons.warning_amber_rounded;
      case SdsExpiryStatus.expired:
        return Icons.error_rounded;
      case SdsExpiryStatus.noSds:
        return Icons.help_outline_rounded;
    }
  }
}

/// Chemical inventory record held at the workplace, with SDS metadata & storage parameters.
class ChemicalInventoryItem {
  final int? id;
  final int? seqNo;
  final String tradeName;
  final String chemicalNameTh;
  final String chemicalNameEn;
  final String casNumber;
  final String? unNumber;
  final String storageLocation;
  final String physicalState; // 'SOLID', 'LIQUID', 'GAS'
  final double quantity;
  final String unit; // 'kg', 'L', 'ถัง (Drums)', 'ท่อ (Cylinders)', 'ตัน (Tons)'
  final double? maxCapacity;
  final String? containerType;
  final String? manufacturerSupplier;
  final String? hazardClass;
  final List<String> ghsPictograms;
  final String registerDate;
  final String sdsIssueDate;
  final int sdsExpiryYears; // default 3 or 5
  final String? sdsFilePath;
  final String? labelImagePath;
  final int? nfpaHealth;
  final int? nfpaFlammability;
  final int? nfpaInstability;
  final String? nfpaSpecial;
  final String? notes;
  final String status; // 'ACTIVE', 'INACTIVE', 'DISPOSED'
  final String? createdAt;
  final String? updatedAt;

  const ChemicalInventoryItem({
    this.id,
    this.seqNo,
    required this.tradeName,
    required this.chemicalNameTh,
    required this.chemicalNameEn,
    required this.casNumber,
    this.unNumber,
    required this.storageLocation,
    required this.physicalState,
    required this.quantity,
    required this.unit,
    this.maxCapacity,
    this.containerType,
    this.manufacturerSupplier,
    this.hazardClass,
    this.ghsPictograms = const [],
    required this.registerDate,
    required this.sdsIssueDate,
    this.sdsExpiryYears = 3,
    this.sdsFilePath,
    this.labelImagePath,
    this.nfpaHealth = 0,
    this.nfpaFlammability = 0,
    this.nfpaInstability = 0,
    this.nfpaSpecial,
    this.notes,
    this.status = 'ACTIVE',
    this.createdAt,
    this.updatedAt,
  });

  ChemicalInventoryItem copyWith({
    int? id,
    int? seqNo,
    String? tradeName,
    String? chemicalNameTh,
    String? chemicalNameEn,
    String? casNumber,
    String? unNumber,
    String? storageLocation,
    String? physicalState,
    double? quantity,
    String? unit,
    double? maxCapacity,
    String? containerType,
    String? manufacturerSupplier,
    String? hazardClass,
    List<String>? ghsPictograms,
    String? registerDate,
    String? sdsIssueDate,
    int? sdsExpiryYears,
    String? sdsFilePath,
    String? labelImagePath,
    int? nfpaHealth,
    int? nfpaFlammability,
    int? nfpaInstability,
    String? nfpaSpecial,
    String? notes,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return ChemicalInventoryItem(
      id: id ?? this.id,
      seqNo: seqNo ?? this.seqNo,
      tradeName: tradeName ?? this.tradeName,
      chemicalNameTh: chemicalNameTh ?? this.chemicalNameTh,
      chemicalNameEn: chemicalNameEn ?? this.chemicalNameEn,
      casNumber: casNumber ?? this.casNumber,
      unNumber: unNumber ?? this.unNumber,
      storageLocation: storageLocation ?? this.storageLocation,
      physicalState: physicalState ?? this.physicalState,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      containerType: containerType ?? this.containerType,
      manufacturerSupplier: manufacturerSupplier ?? this.manufacturerSupplier,
      hazardClass: hazardClass ?? this.hazardClass,
      ghsPictograms: ghsPictograms ?? this.ghsPictograms,
      registerDate: registerDate ?? this.registerDate,
      sdsIssueDate: sdsIssueDate ?? this.sdsIssueDate,
      sdsExpiryYears: sdsExpiryYears ?? this.sdsExpiryYears,
      sdsFilePath: sdsFilePath ?? this.sdsFilePath,
      labelImagePath: labelImagePath ?? this.labelImagePath,
      nfpaHealth: nfpaHealth ?? this.nfpaHealth,
      nfpaFlammability: nfpaFlammability ?? this.nfpaFlammability,
      nfpaInstability: nfpaInstability ?? this.nfpaInstability,
      nfpaSpecial: nfpaSpecial ?? this.nfpaSpecial,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seq_no': seqNo,
      'trade_name': tradeName,
      'chemical_name_th': chemicalNameTh,
      'chemical_name_en': chemicalNameEn,
      'cas_number': casNumber,
      'un_number': unNumber,
      'storage_location': storageLocation,
      'physical_state': physicalState,
      'quantity': quantity,
      'unit': unit,
      'max_capacity': maxCapacity,
      'container_type': containerType,
      'manufacturer_supplier': manufacturerSupplier,
      'hazard_class': hazardClass,
      'ghs_pictograms': jsonEncode(ghsPictograms),
      'register_date': registerDate,
      'sds_issue_date': sdsIssueDate,
      'sds_expiry_years': sdsExpiryYears,
      'sds_file_path': sdsFilePath,
      'label_image_path': labelImagePath,
      'nfpa_health': nfpaHealth,
      'nfpa_flammability': nfpaFlammability,
      'nfpa_instability': nfpaInstability,
      'nfpa_special': nfpaSpecial,
      'notes': notes,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ChemicalInventoryItem.fromMap(Map<String, dynamic> map) {
    List<String> parsedPictograms = [];
    if (map['ghs_pictograms'] != null) {
      try {
        final decoded = jsonDecode(map['ghs_pictograms'].toString());
        if (decoded is List) {
          parsedPictograms = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        if (map['ghs_pictograms'] is List) {
          parsedPictograms = (map['ghs_pictograms'] as List).map((e) => e.toString()).toList();
        }
      }
    }

    return ChemicalInventoryItem(
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      seqNo: map['seq_no'] != null ? int.tryParse(map['seq_no'].toString()) : null,
      tradeName: (map['trade_name'] ?? '').toString(),
      chemicalNameTh: (map['chemical_name_th'] ?? '').toString(),
      chemicalNameEn: (map['chemical_name_en'] ?? '').toString(),
      casNumber: (map['cas_number'] ?? '').toString(),
      unNumber: map['un_number']?.toString(),
      storageLocation: (map['storage_location'] ?? '').toString(),
      physicalState: (map['physical_state'] ?? 'LIQUID').toString(),
      quantity: double.tryParse(map['quantity']?.toString() ?? '0') ?? 0.0,
      unit: (map['unit'] ?? 'kg').toString(),
      maxCapacity: map['max_capacity'] != null ? double.tryParse(map['max_capacity'].toString()) : null,
      containerType: map['container_type']?.toString(),
      manufacturerSupplier: map['manufacturer_supplier']?.toString(),
      hazardClass: map['hazard_class']?.toString(),
      ghsPictograms: parsedPictograms,
      registerDate: (map['register_date'] ?? DateTime.now().toIso8601String().substring(0, 10)).toString(),
      sdsIssueDate: (map['sds_issue_date'] ?? DateTime.now().toIso8601String().substring(0, 10)).toString(),
      sdsExpiryYears: int.tryParse(map['sds_expiry_years']?.toString() ?? '3') ?? 3,
      sdsFilePath: map['sds_file_path']?.toString(),
      labelImagePath: map['label_image_path']?.toString(),
      nfpaHealth: int.tryParse(map['nfpa_health']?.toString() ?? '0') ?? 0,
      nfpaFlammability: int.tryParse(map['nfpa_flammability']?.toString() ?? '0') ?? 0,
      nfpaInstability: int.tryParse(map['nfpa_instability']?.toString() ?? '0') ?? 0,
      nfpaSpecial: map['nfpa_special']?.toString(),
      notes: map['notes']?.toString(),
      status: (map['status'] ?? 'ACTIVE').toString(),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  // --- Dynamic Lifecycle Getters ---

  DateTime? get parsedSdsIssueDate => DateTime.tryParse(sdsIssueDate);

  DateTime? get sdsExpiryDate => SdsExpiryCalculation.getExpiryDate(
        parsedSdsIssueDate,
        validityYears: sdsExpiryYears,
      );

  int get daysUntilExpiry => SdsExpiryCalculation.getDaysRemaining(
        parsedSdsIssueDate,
        validityYears: sdsExpiryYears,
      );

  SdsExpiryStatus get sdsStatus => SdsExpiryCalculation.calculateStatus(
        parsedSdsIssueDate,
        validityYears: sdsExpiryYears,
      );

  Color get sdsBadgeColor => SdsExpiryCalculation.getStatusColor(sdsStatus);
  Color get sdsBadgeBackgroundColor => SdsExpiryCalculation.getStatusBackgroundColor(sdsStatus);
  String get sdsBadgeText => SdsExpiryCalculation.getStatusLabelTh(sdsStatus, daysRemaining: daysUntilExpiry);
  IconData get sdsBadgeIcon => SdsExpiryCalculation.getStatusIcon(sdsStatus);

  bool get isExpired => sdsStatus == SdsExpiryStatus.expired;
  bool get isExpiringSoon =>
      sdsStatus == SdsExpiryStatus.near30 ||
      sdsStatus == SdsExpiryStatus.near60 ||
      sdsStatus == SdsExpiryStatus.near90;
  bool get isActive => status.toUpperCase() == 'ACTIVE';

  double get capacityUtilization {
    if (maxCapacity == null || maxCapacity! <= 0) return 0.0;
    return (quantity / maxCapacity!).clamp(0.0, 1.0);
  }
}
