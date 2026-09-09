class FactoryScopeModel {
  final bool hasBoiler;
  final bool hasCrane;
  final bool hasChemical;
  final bool hasConfinedSpace;
  final bool hasWorkingAtHeight;
  final bool hasElectricalLoto;
  final bool hasEmergencyFire;
  final bool hasPpe;

  const FactoryScopeModel({
    this.hasBoiler = true,
    this.hasCrane = true,
    this.hasChemical = true,
    this.hasConfinedSpace = true,
    this.hasWorkingAtHeight = true,
    this.hasElectricalLoto = true,
    this.hasEmergencyFire = true,
    this.hasPpe = true,
  });

  int get activeCount => [
        hasBoiler,
        hasCrane,
        hasChemical,
        hasConfinedSpace,
        hasWorkingAtHeight,
        hasElectricalLoto,
        hasEmergencyFire,
        hasPpe,
      ].where((b) => b).length;

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'has_boiler': hasBoiler ? 1 : 0,
      'has_crane': hasCrane ? 1 : 0,
      'has_chemical': hasChemical ? 1 : 0,
      'has_confined_space': hasConfinedSpace ? 1 : 0,
      'has_working_at_height': hasWorkingAtHeight ? 1 : 0,
      'has_electrical_loto': hasElectricalLoto ? 1 : 0,
      'has_emergency_fire': hasEmergencyFire ? 1 : 0,
      'has_ppe': hasPpe ? 1 : 0,
    };
  }

  factory FactoryScopeModel.fromMap(Map<String, dynamic> map) {
    return FactoryScopeModel(
      hasBoiler: (map['has_boiler'] as int? ?? 1) == 1,
      hasCrane: (map['has_crane'] as int? ?? 1) == 1,
      hasChemical: (map['has_chemical'] as int? ?? 1) == 1,
      hasConfinedSpace: (map['has_confined_space'] as int? ?? 1) == 1,
      hasWorkingAtHeight: (map['has_working_at_height'] as int? ?? 1) == 1,
      hasElectricalLoto: (map['has_electrical_loto'] as int? ?? 1) == 1,
      hasEmergencyFire: (map['has_emergency_fire'] as int? ?? 1) == 1,
      hasPpe: (map['has_ppe'] as int? ?? 1) == 1,
    );
  }

  FactoryScopeModel copyWith({
    bool? hasBoiler,
    bool? hasCrane,
    bool? hasChemical,
    bool? hasConfinedSpace,
    bool? hasWorkingAtHeight,
    bool? hasElectricalLoto,
    bool? hasEmergencyFire,
    bool? hasPpe,
  }) {
    return FactoryScopeModel(
      hasBoiler: hasBoiler ?? this.hasBoiler,
      hasCrane: hasCrane ?? this.hasCrane,
      hasChemical: hasChemical ?? this.hasChemical,
      hasConfinedSpace: hasConfinedSpace ?? this.hasConfinedSpace,
      hasWorkingAtHeight: hasWorkingAtHeight ?? this.hasWorkingAtHeight,
      hasElectricalLoto: hasElectricalLoto ?? this.hasElectricalLoto,
      hasEmergencyFire: hasEmergencyFire ?? this.hasEmergencyFire,
      hasPpe: hasPpe ?? this.hasPpe,
    );
  }
}
