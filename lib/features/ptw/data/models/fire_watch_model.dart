import 'dart:convert';

/// Hot Work Fire Watch & 30-Minute Post-Work Monitoring Model
/// under Ministerial Regulation on Fire Prevention and Suppression B.E. 2555 (กฎกระทรวงอัคคีภัย ๒๕๕๕)
class FireWatchModel {
  final int? id;
  final String watchId; // e.g. "FW-PTW-2026-001"
  final String ptwNumber; // Reference to PtwModel.ptwNumber
  final String fireWatcherName; // ชื่อผู้เฝ้าระวังไฟ
  final String fireWatcherPhone;
  final String fireExtinguisherType; // ชนิดถังดับเพลิง e.g. "Dry Chemical 15 lbs", "CO2"
  final String fireExtinguisherSerial; // หมายเลขถังดับเพลิง
  final bool extinguisherInspectedReady; // ตรวจสอบเกจวัดแรงดันพร้อมใช้งาน
  final double clearedRadiusMeters; // รัศมีเคลียร์วัสดุติดไฟ (มาตรฐาน >= 11 เมตร / 35 ฟุต)
  final bool fireBlanketInstalled; // ติดตั้งผ้ากันสะเก็ดไฟ
  final bool combustibleMaterialProtected; // คลุมหรือเคลื่อนย้ายสารไวไฟ
  final bool sewerCovered; // ปิดฝาท่อระบายน้ำ/ช่องเปิดป้องกันสะเก็ดไฟ
  final String hotWorkEndTime; // เวลาสิ้นสุดงานประกายไฟ (ISO 8601 or YYYY-MM-DDTHH:mm:ss)
  final String postWorkWatchStartTime; // เวลาเริ่มเฝ้าระวังหลังเลิกงาน
  final String? postWorkWatchEndTime; // เวลาสิ้นสุดการเฝ้าระวัง
  final int postWorkWatchDurationMinutes; // ระยะเวลาเฝ้าระวังจริง (ต้อง >= 30 นาที)
  final bool isPostWorkAreaSafe; // ยืนยันไม่มีความร้อนคุกรุ่น/สะเก็ดไฟหลงเหลือ
  final String? finalInspectorName; // ผู้ตรวจสอบปิดงานไฟ
  final String? finalInspectorSignature; // ลายเซ็นผู้ตรวจสอบ
  final String? notes;
  final String? createdAt;

  const FireWatchModel({
    this.id,
    required this.watchId,
    required this.ptwNumber,
    required this.fireWatcherName,
    required this.fireWatcherPhone,
    required this.fireExtinguisherType,
    required this.fireExtinguisherSerial,
    this.extinguisherInspectedReady = true,
    this.clearedRadiusMeters = 11.0,
    this.fireBlanketInstalled = true,
    this.combustibleMaterialProtected = true,
    this.sewerCovered = true,
    required this.hotWorkEndTime,
    required this.postWorkWatchStartTime,
    this.postWorkWatchEndTime,
    this.postWorkWatchDurationMinutes = 30,
    required this.isPostWorkAreaSafe,
    this.finalInspectorName,
    this.finalInspectorSignature,
    this.notes,
    this.createdAt,
  });

  /// Compliant with the statutory 30-minute post-work fire monitoring rule
  bool get isCompliantWith30MinRule =>
      postWorkWatchDurationMinutes >= 30 && isPostWorkAreaSafe;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'watch_id': watchId,
      'ptw_number': ptwNumber,
      'fire_watcher_name': fireWatcherName,
      'fire_watcher_phone': fireWatcherPhone,
      'fire_extinguisher_type': fireExtinguisherType,
      'fire_extinguisher_serial': fireExtinguisherSerial,
      'extinguisher_inspected_ready': extinguisherInspectedReady ? 1 : 0,
      'cleared_radius_meters': clearedRadiusMeters,
      'fire_blanket_installed': fireBlanketInstalled ? 1 : 0,
      'combustible_material_protected': combustibleMaterialProtected ? 1 : 0,
      'sewer_covered': sewerCovered ? 1 : 0,
      'hot_work_end_time': hotWorkEndTime,
      'post_work_watch_start_time': postWorkWatchStartTime,
      'post_work_watch_end_time': postWorkWatchEndTime,
      'post_work_watch_duration_minutes': postWorkWatchDurationMinutes,
      'is_post_work_area_safe': isPostWorkAreaSafe ? 1 : 0,
      'final_inspector_name': finalInspectorName,
      'final_inspector_signature': finalInspectorSignature,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory FireWatchModel.fromMap(Map<String, dynamic> map) {
    return FireWatchModel(
      id: map['id'] as int?,
      watchId: map['watch_id']?.toString() ?? '',
      ptwNumber: map['ptw_number']?.toString() ?? '',
      fireWatcherName: map['fire_watcher_name']?.toString() ?? '',
      fireWatcherPhone: map['fire_watcher_phone']?.toString() ?? '',
      fireExtinguisherType: map['fire_extinguisher_type']?.toString() ?? '',
      fireExtinguisherSerial: map['fire_extinguisher_serial']?.toString() ?? '',
      extinguisherInspectedReady: (map['extinguisher_inspected_ready'] == 1 || map['extinguisher_inspected_ready'] == true),
      clearedRadiusMeters: (map['cleared_radius_meters'] as num?)?.toDouble() ?? 11.0,
      fireBlanketInstalled: (map['fire_blanket_installed'] == 1 || map['fire_blanket_installed'] == true),
      combustibleMaterialProtected: (map['combustible_material_protected'] == 1 || map['combustible_material_protected'] == true),
      sewerCovered: (map['sewer_covered'] == 1 || map['sewer_covered'] == true),
      hotWorkEndTime: map['hot_work_end_time']?.toString() ?? '',
      postWorkWatchStartTime: map['post_work_watch_start_time']?.toString() ?? '',
      postWorkWatchEndTime: map['post_work_watch_end_time']?.toString(),
      postWorkWatchDurationMinutes: (map['post_work_watch_duration_minutes'] as num?)?.toInt() ?? 30,
      isPostWorkAreaSafe: (map['is_post_work_area_safe'] == 1 || map['is_post_work_area_safe'] == true),
      finalInspectorName: map['final_inspector_name']?.toString(),
      finalInspectorSignature: map['final_inspector_signature']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: map['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory FireWatchModel.fromJson(Map<String, dynamic> json) => FireWatchModel.fromMap(json);

  FireWatchModel copyWith({
    int? id,
    String? watchId,
    String? ptwNumber,
    String? fireWatcherName,
    String? fireWatcherPhone,
    String? fireExtinguisherType,
    String? fireExtinguisherSerial,
    bool? extinguisherInspectedReady,
    double? clearedRadiusMeters,
    bool? fireBlanketInstalled,
    bool? combustibleMaterialProtected,
    bool? sewerCovered,
    String? hotWorkEndTime,
    String? postWorkWatchStartTime,
    String? postWorkWatchEndTime,
    int? postWorkWatchDurationMinutes,
    bool? isPostWorkAreaSafe,
    String? finalInspectorName,
    String? finalInspectorSignature,
    String? notes,
    String? createdAt,
  }) {
    return FireWatchModel(
      id: id ?? this.id,
      watchId: watchId ?? this.watchId,
      ptwNumber: ptwNumber ?? this.ptwNumber,
      fireWatcherName: fireWatcherName ?? this.fireWatcherName,
      fireWatcherPhone: fireWatcherPhone ?? this.fireWatcherPhone,
      fireExtinguisherType: fireExtinguisherType ?? this.fireExtinguisherType,
      fireExtinguisherSerial: fireExtinguisherSerial ?? this.fireExtinguisherSerial,
      extinguisherInspectedReady: extinguisherInspectedReady ?? this.extinguisherInspectedReady,
      clearedRadiusMeters: clearedRadiusMeters ?? this.clearedRadiusMeters,
      fireBlanketInstalled: fireBlanketInstalled ?? this.fireBlanketInstalled,
      combustibleMaterialProtected: combustibleMaterialProtected ?? this.combustibleMaterialProtected,
      sewerCovered: sewerCovered ?? this.sewerCovered,
      hotWorkEndTime: hotWorkEndTime ?? this.hotWorkEndTime,
      postWorkWatchStartTime: postWorkWatchStartTime ?? this.postWorkWatchStartTime,
      postWorkWatchEndTime: postWorkWatchEndTime ?? this.postWorkWatchEndTime,
      postWorkWatchDurationMinutes: postWorkWatchDurationMinutes ?? this.postWorkWatchDurationMinutes,
      isPostWorkAreaSafe: isPostWorkAreaSafe ?? this.isPostWorkAreaSafe,
      finalInspectorName: finalInspectorName ?? this.finalInspectorName,
      finalInspectorSignature: finalInspectorSignature ?? this.finalInspectorSignature,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'FireWatchModel(watchId: $watchId, fireWatcher: $fireWatcherName, duration: ${postWorkWatchDurationMinutes}m, isSafe: $isPostWorkAreaSafe)';
}
