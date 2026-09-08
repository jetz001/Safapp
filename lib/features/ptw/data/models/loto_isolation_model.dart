import 'dart:convert';
import '../../domain/enums/energy_type.dart';

/// Lockout/Tagout (LOTO) Energy Isolation Point Model
/// under Ministerial Regulation on Electrical Safety B.E. 2558 (กฎกระทรวงไฟฟ้า ๒๕๕๘)
class LotoIsolationModel {
  final int? id;
  final String isolationId; // e.g. "LOTO-PTW-2026-001-01"
  final String ptwNumber; // Reference to PtwModel.ptwNumber
  final String equipmentTagNo; // e.g. "MCC-PNL-04", "PUMP-101-M", "V-304"
  final String equipmentName; // e.g. "ปั๊มสูบจ่ายสารเคมีหลัก ชุดที่ 1"
  final String locationArea; // e.g. "อาคารควบคุมระบบไฟฟ้า ชั้น 1"
  final EnergyType energyType;
  final String isolationMethod; // 'BREAKER_LOCK', 'VALVE_LOCKOUT', 'BLIND_FLANGE', 'FUSE_REMOVAL'
  final String padlockTagNo; // หมายเลขแม่กุญแจ LOTO / Padlock Tag No.
  final String lockAppliedBy; // ผู้ใส่กุญแจและป้ายเตือน
  final String lockAppliedTimestamp; // วันเวลาที่ทำการล็อก
  final String zeroEnergyTestMethod; // วิธีทดสอบพลังงานศูนย์ e.g. "โวลต์มิเตอร์วัดไฟ 0V", "เปิดวาล์วเดรนแรงดัน 0 bar"
  final bool isZeroEnergyVerified; // ยืนยันสถานะพลังงานตกค้างเป็นศูนย์
  final String verifiedBy; // ผู้ทดสอบและยืนยัน
  final String? verifiedTimestamp;
  final bool isDeIsolated; // ปลดล็อกคืนสภาพเมื่อปิดงาน
  final String? deIsolatedBy;
  final String? deIsolatedTimestamp;
  final String? notes;
  final String? createdAt;

  const LotoIsolationModel({
    this.id,
    required this.isolationId,
    required this.ptwNumber,
    required this.equipmentTagNo,
    required this.equipmentName,
    required this.locationArea,
    required this.energyType,
    required this.isolationMethod,
    required this.padlockTagNo,
    required this.lockAppliedBy,
    required this.lockAppliedTimestamp,
    required this.zeroEnergyTestMethod,
    required this.isZeroEnergyVerified,
    required this.verifiedBy,
    this.verifiedTimestamp,
    this.isDeIsolated = false,
    this.deIsolatedBy,
    this.deIsolatedTimestamp,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'isolation_id': isolationId,
      'ptw_number': ptwNumber,
      'equipment_tag_no': equipmentTagNo,
      'equipment_name': equipmentName,
      'location_area': locationArea,
      'energy_type': energyType.toDbCode(),
      'isolation_method': isolationMethod,
      'padlock_tag_no': padlockTagNo,
      'lock_applied_by': lockAppliedBy,
      'lock_applied_timestamp': lockAppliedTimestamp,
      'zero_energy_test_method': zeroEnergyTestMethod,
      'is_zero_energy_verified': isZeroEnergyVerified ? 1 : 0,
      'verified_by': verifiedBy,
      'verified_timestamp': verifiedTimestamp,
      'is_de_isolated': isDeIsolated ? 1 : 0,
      'de_isolated_by': deIsolatedBy,
      'de_isolated_timestamp': deIsolatedTimestamp,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory LotoIsolationModel.fromMap(Map<String, dynamic> map) {
    return LotoIsolationModel(
      id: map['id'] as int?,
      isolationId: map['isolation_id']?.toString() ?? '',
      ptwNumber: map['ptw_number']?.toString() ?? '',
      equipmentTagNo: map['equipment_tag_no']?.toString() ?? '',
      equipmentName: map['equipment_name']?.toString() ?? '',
      locationArea: map['location_area']?.toString() ?? '',
      energyType: EnergyType.fromDbCode(map['energy_type']?.toString()),
      isolationMethod: map['isolation_method']?.toString() ?? '',
      padlockTagNo: map['padlock_tag_no']?.toString() ?? '',
      lockAppliedBy: map['lock_applied_by']?.toString() ?? '',
      lockAppliedTimestamp: map['lock_applied_timestamp']?.toString() ?? '',
      zeroEnergyTestMethod: map['zero_energy_test_method']?.toString() ?? '',
      isZeroEnergyVerified: (map['is_zero_energy_verified'] == 1 || map['is_zero_energy_verified'] == true),
      verifiedBy: map['verified_by']?.toString() ?? '',
      verifiedTimestamp: map['verified_timestamp']?.toString(),
      isDeIsolated: (map['is_de_isolated'] == 1 || map['is_de_isolated'] == true),
      deIsolatedBy: map['de_isolated_by']?.toString(),
      deIsolatedTimestamp: map['de_isolated_timestamp']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: map['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory LotoIsolationModel.fromJson(Map<String, dynamic> json) => LotoIsolationModel.fromMap(json);

  LotoIsolationModel copyWith({
    int? id,
    String? isolationId,
    String? ptwNumber,
    String? equipmentTagNo,
    String? equipmentName,
    String? locationArea,
    EnergyType? energyType,
    String? isolationMethod,
    String? padlockTagNo,
    String? lockAppliedBy,
    String? lockAppliedTimestamp,
    String? zeroEnergyTestMethod,
    bool? isZeroEnergyVerified,
    String? verifiedBy,
    String? verifiedTimestamp,
    bool? isDeIsolated,
    String? deIsolatedBy,
    String? deIsolatedTimestamp,
    String? notes,
    String? createdAt,
  }) {
    return LotoIsolationModel(
      id: id ?? this.id,
      isolationId: isolationId ?? this.isolationId,
      ptwNumber: ptwNumber ?? this.ptwNumber,
      equipmentTagNo: equipmentTagNo ?? this.equipmentTagNo,
      equipmentName: equipmentName ?? this.equipmentName,
      locationArea: locationArea ?? this.locationArea,
      energyType: energyType ?? this.energyType,
      isolationMethod: isolationMethod ?? this.isolationMethod,
      padlockTagNo: padlockTagNo ?? this.padlockTagNo,
      lockAppliedBy: lockAppliedBy ?? this.lockAppliedBy,
      lockAppliedTimestamp: lockAppliedTimestamp ?? this.lockAppliedTimestamp,
      zeroEnergyTestMethod: zeroEnergyTestMethod ?? this.zeroEnergyTestMethod,
      isZeroEnergyVerified: isZeroEnergyVerified ?? this.isZeroEnergyVerified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedTimestamp: verifiedTimestamp ?? this.verifiedTimestamp,
      isDeIsolated: isDeIsolated ?? this.isDeIsolated,
      deIsolatedBy: deIsolatedBy ?? this.deIsolatedBy,
      deIsolatedTimestamp: deIsolatedTimestamp ?? this.deIsolatedTimestamp,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'LotoIsolationModel(isolationId: $isolationId, tag: $equipmentTagNo, energy: ${energyType.toDbCode()}, verified: $isZeroEnergyVerified, deIsolated: $isDeIsolated)';
}
