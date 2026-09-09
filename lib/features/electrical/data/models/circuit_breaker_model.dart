class CircuitBreakerModel {
  final int? id;
  final String equipmentTag;
  final String equipmentName;
  final String locationBuilding;
  final String? locationFloor;
  final String voltageLevel;
  final double? ratedCurrentAmp;
  final String breakerType;
  final String? upstreamSource;
  final bool isLocked;
  final String? lockoutTagNo;
  final String? lockedBy;
  final String? lockedAt;
  final bool zeroEnergyVerified;
  final String? authorizedOperator;
  final String? singleLineDiagramRef;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  CircuitBreakerModel({
    this.id,
    required this.equipmentTag,
    required this.equipmentName,
    required this.locationBuilding,
    this.locationFloor,
    this.voltageLevel = 'LOW_VOLTAGE',
    this.ratedCurrentAmp,
    required this.breakerType,
    this.upstreamSource,
    this.isLocked = false,
    this.lockoutTagNo,
    this.lockedBy,
    this.lockedAt,
    this.zeroEnergyVerified = false,
    this.authorizedOperator,
    this.singleLineDiagramRef,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'equipment_tag': equipmentTag,
      'equipment_name': equipmentName,
      'location_building': locationBuilding,
      'location_floor': locationFloor,
      'voltage_level': voltageLevel,
      'rated_current_amp': ratedCurrentAmp,
      'breaker_type': breakerType,
      'upstream_source': upstreamSource,
      'is_locked': isLocked ? 1 : 0,
      'lockout_tag_no': lockoutTagNo,
      'locked_by': lockedBy,
      'locked_at': lockedAt,
      'zero_energy_verified': zeroEnergyVerified ? 1 : 0,
      'authorized_operator': authorizedOperator,
      'single_line_diagram_ref': singleLineDiagramRef,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory CircuitBreakerModel.fromMap(Map<String, dynamic> map) {
    return CircuitBreakerModel(
      id: map['id'] as int?,
      equipmentTag: map['equipment_tag']?.toString() ?? '',
      equipmentName: map['equipment_name']?.toString() ?? '',
      locationBuilding: map['location_building']?.toString() ?? '',
      locationFloor: map['location_floor']?.toString(),
      voltageLevel: map['voltage_level']?.toString() ?? 'LOW_VOLTAGE',
      ratedCurrentAmp: (map['rated_current_amp'] as num?)?.toDouble(),
      breakerType: map['breaker_type']?.toString() ?? '',
      upstreamSource: map['upstream_source']?.toString(),
      isLocked: map['is_locked'] == 1 || map['is_locked'] == true,
      lockoutTagNo: map['lockout_tag_no']?.toString(),
      lockedBy: map['locked_by']?.toString(),
      lockedAt: map['locked_at']?.toString(),
      zeroEnergyVerified: map['zero_energy_verified'] == 1 || map['zero_energy_verified'] == true,
      authorizedOperator: map['authorized_operator']?.toString(),
      singleLineDiagramRef: map['single_line_diagram_ref']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  CircuitBreakerModel copyWith({
    int? id,
    String? equipmentTag,
    String? equipmentName,
    String? locationBuilding,
    String? locationFloor,
    String? voltageLevel,
    double? ratedCurrentAmp,
    String? breakerType,
    String? upstreamSource,
    bool? isLocked,
    String? lockoutTagNo,
    String? lockedBy,
    String? lockedAt,
    bool? zeroEnergyVerified,
    String? authorizedOperator,
    String? singleLineDiagramRef,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return CircuitBreakerModel(
      id: id ?? this.id,
      equipmentTag: equipmentTag ?? this.equipmentTag,
      equipmentName: equipmentName ?? this.equipmentName,
      locationBuilding: locationBuilding ?? this.locationBuilding,
      locationFloor: locationFloor ?? this.locationFloor,
      voltageLevel: voltageLevel ?? this.voltageLevel,
      ratedCurrentAmp: ratedCurrentAmp ?? this.ratedCurrentAmp,
      breakerType: breakerType ?? this.breakerType,
      upstreamSource: upstreamSource ?? this.upstreamSource,
      isLocked: isLocked ?? this.isLocked,
      lockoutTagNo: lockoutTagNo ?? this.lockoutTagNo,
      lockedBy: lockedBy ?? this.lockedBy,
      lockedAt: lockedAt ?? this.lockedAt,
      zeroEnergyVerified: zeroEnergyVerified ?? this.zeroEnergyVerified,
      authorizedOperator: authorizedOperator ?? this.authorizedOperator,
      singleLineDiagramRef: singleLineDiagramRef ?? this.singleLineDiagramRef,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
