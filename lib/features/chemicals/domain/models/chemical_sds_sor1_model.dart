import 'dart:convert';
import 'package:flutter/material.dart';

/// Sub-model representing an individual chemical ingredient/component in Section 3 of SDS Form สอ.๑.
class SdsIngredientItem {
  final String chemicalName;
  final String casNumber;
  final double percentage; // % by weight or volume
  final String? hazardClassification;
  final String? tlvPel;

  const SdsIngredientItem({
    required this.chemicalName,
    required this.casNumber,
    required this.percentage,
    this.hazardClassification,
    this.tlvPel,
  });

  Map<String, dynamic> toMap() {
    return {
      'chemical_name': chemicalName,
      'cas_number': casNumber,
      'percentage': percentage,
      'hazard_classification': hazardClassification,
      'tlv_pel': tlvPel,
    };
  }

  factory SdsIngredientItem.fromMap(Map<String, dynamic> map) {
    return SdsIngredientItem(
      chemicalName: (map['chemical_name'] ?? '').toString(),
      casNumber: (map['cas_number'] ?? '').toString(),
      percentage: (map['percentage'] is num) ? (map['percentage'] as num).toDouble() : double.tryParse(map['percentage']?.toString() ?? '0') ?? 0.0,
      hazardClassification: map['hazard_classification']?.toString(),
      tlvPel: map['tlv_pel']?.toString(),
    );
  }

  SdsIngredientItem copyWith({
    String? chemicalName,
    String? casNumber,
    double? percentage,
    String? hazardClassification,
    String? tlvPel,
  }) {
    return SdsIngredientItem(
      chemicalName: chemicalName ?? this.chemicalName,
      casNumber: casNumber ?? this.casNumber,
      percentage: percentage ?? this.percentage,
      hazardClassification: hazardClassification ?? this.hazardClassification,
      tlvPel: tlvPel ?? this.tlvPel,
    );
  }
}

/// Comprehensive Model representing Form สอ.๑ (SDS 16 Sections) conforming strictly to
/// DLPW Notification on Form สอ.๑ B.E. 2556 (ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง แบบ สอ.๑).
class ChemicalSdsSor1Model {
  final int? id;
  final int? inventoryId; // Foreign key to chemical_inventory
  final String tradeName;
  final String? chemicalFormula;
  final String casNumber;
  final String? unNumber;

  // Section 1: Identification
  final String manufacturerImporterInfo;
  final String? emergencyPhone;
  final String? recommendedUse;

  // Section 2: Hazard Identification
  final String? ghsClassification;
  final List<String> ghsPictograms;
  final String signalWord; // 'DANGER', 'WARNING', 'NONE'
  final List<String> hazardStatements;
  final List<String> precautionaryStatements;
  final int nfpaHealth;
  final int nfpaFlammability;
  final int nfpaInstability;
  final String? nfpaSpecial;

  // Section 3: Composition / Information on Ingredients
  final List<SdsIngredientItem> ingredients;
  final String? compositionSummary;

  // Section 4: First-Aid Measures
  final String? inhalationFirstAid;
  final String? skinContactFirstAid;
  final String? eyeContactFirstAid;
  final String? ingestionFirstAid;
  final String? symptomsEffects;
  final String? specialMedicalAttention;

  // Section 5: Fire-Fighting Measures
  final String? suitableExtinguishingMedia;
  final String? unsuitableExtinguishingMedia;
  final String? specificFireHazards;
  final String? protectiveEquipmentFirefighters;

  // Section 6: Accidental Release Measures
  final String? personalPrecautions;
  final String? environmentalPrecautions;
  final String? containmentCleanUp;

  // Section 7: Handling and Storage
  final String? handlingPrecautions;
  final String? storageConditions;
  final String? storageTemperature;

  // Section 8: Exposure Controls / Personal Protection
  final String? exposureLimits;
  final String? engineeringControls;
  final String? respiratoryProtection;
  final String? eyeProtection;
  final String? skinHandProtection;

  // Section 9: Physical and Chemical Properties
  final String? appearance; // e.g. "ของเหลวใส ไม่มีสี"
  final String? odor;
  final String? phValue;
  final String? boilingPoint;
  final String? flashPoint;
  final String? flammabilityLimits;
  final String? vaporPressure;
  final String? relativeDensity;
  final String? solubility;

  // Section 10: Stability and Reactivity
  final String? reactivity;
  final String? chemicalStability;
  final String? conditionsToAvoid;
  final String? incompatibleMaterials;
  final String? hazardousDecompositionProducts;

  // Section 11: Toxicological Information
  final String? acuteToxicity; // e.g. "LD50 ทางปาก (หนู) = 5,000 mg/kg"
  final String? skinCorrosionIrritation;
  final String? seriousEyeDamage;
  final String? carcinogenicity;
  final String? reproductiveToxicity;
  final String? targetOrganToxicity;

  // Section 12: Ecological Information
  final String? ecotoxicity;
  final String? persistenceDegradability;
  final String? bioaccumulativePotential;
  final String? mobilityInSoil;

  // Section 13: Disposal Considerations
  final String? wasteTreatmentMethods;
  final String? contaminatedPackaging;

  // Section 14: Transport Information
  final String? unProperShippingName;
  final String? transportHazardClass;
  final String? packingGroup;
  final String? marinePollutant;
  final String? specialPrecautionsTransport;

  // Section 15: Regulatory Information
  final String? safetyHealthRegulations;
  final String? hazardousSubstanceType;

  // Section 16: Other Information
  final String? revisionDate;
  final String? versionNo;
  final String? preparedBy;
  final String? referencesList;

  final String status; // 'DRAFT', 'COMPLETED', 'UNDER_REVIEW'
  final String? createdAt;
  final String? updatedAt;

  const ChemicalSdsSor1Model({
    this.id,
    this.inventoryId,
    required this.tradeName,
    this.chemicalFormula,
    required this.casNumber,
    this.unNumber,
    this.manufacturerImporterInfo = '',
    this.emergencyPhone,
    this.recommendedUse,
    this.ghsClassification,
    this.ghsPictograms = const [],
    this.signalWord = 'DANGER',
    this.hazardStatements = const [],
    this.precautionaryStatements = const [],
    this.nfpaHealth = 0,
    this.nfpaFlammability = 0,
    this.nfpaInstability = 0,
    this.nfpaSpecial,
    this.ingredients = const [],
    this.compositionSummary,
    this.inhalationFirstAid,
    this.skinContactFirstAid,
    this.eyeContactFirstAid,
    this.ingestionFirstAid,
    this.symptomsEffects,
    this.specialMedicalAttention,
    this.suitableExtinguishingMedia,
    this.unsuitableExtinguishingMedia,
    this.specificFireHazards,
    this.protectiveEquipmentFirefighters,
    this.personalPrecautions,
    this.environmentalPrecautions,
    this.containmentCleanUp,
    this.handlingPrecautions,
    this.storageConditions,
    this.storageTemperature,
    this.exposureLimits,
    this.engineeringControls,
    this.respiratoryProtection,
    this.eyeProtection,
    this.skinHandProtection,
    this.appearance,
    this.odor,
    this.phValue,
    this.boilingPoint,
    this.flashPoint,
    this.flammabilityLimits,
    this.vaporPressure,
    this.relativeDensity,
    this.solubility,
    this.reactivity,
    this.chemicalStability,
    this.conditionsToAvoid,
    this.incompatibleMaterials,
    this.hazardousDecompositionProducts,
    this.acuteToxicity,
    this.skinCorrosionIrritation,
    this.seriousEyeDamage,
    this.carcinogenicity,
    this.reproductiveToxicity,
    this.targetOrganToxicity,
    this.ecotoxicity,
    this.persistenceDegradability,
    this.bioaccumulativePotential,
    this.mobilityInSoil,
    this.wasteTreatmentMethods,
    this.contaminatedPackaging,
    this.unProperShippingName,
    this.transportHazardClass,
    this.packingGroup,
    this.marinePollutant,
    this.specialPrecautionsTransport,
    this.safetyHealthRegulations,
    this.hazardousSubstanceType,
    this.revisionDate,
    this.versionNo = '1.0',
    this.preparedBy,
    this.referencesList,
    this.status = 'COMPLETED',
    this.createdAt,
    this.updatedAt,
  });

  /// Serializes model to SQLite `chemical_sds_sor1` table map.
  Map<String, dynamic> toMap() {
    final firstAidMap = {
      'inhalation': inhalationFirstAid,
      'skin': skinContactFirstAid,
      'eye': eyeContactFirstAid,
      'ingestion': ingestionFirstAid,
      'symptoms': symptomsEffects,
      'special_medical': specialMedicalAttention,
    };

    final fireFightingMap = {
      'suitable_media': suitableExtinguishingMedia,
      'unsuitable_media': unsuitableExtinguishingMedia,
      'specific_hazards': specificFireHazards,
      'protective_equipment': protectiveEquipmentFirefighters,
    };

    final accidentalReleaseMap = {
      'personal_precautions': personalPrecautions,
      'environmental_precautions': environmentalPrecautions,
      'containment_cleanup': containmentCleanUp,
    };

    final handlingStorageMap = {
      'handling': handlingPrecautions,
      'storage': storageConditions,
      'temperature': storageTemperature,
    };

    final exposureControlsMap = {
      'exposure_limits': exposureLimits,
      'engineering_controls': engineeringControls,
      'respiratory': respiratoryProtection,
      'eye': eyeProtection,
      'skin_hand': skinHandProtection,
    };

    final physicalChemicalMap = {
      'appearance': appearance,
      'odor': odor,
      'ph': phValue,
      'boiling_point': boilingPoint,
      'flash_point': flashPoint,
      'flammability_limits': flammabilityLimits,
      'vapor_pressure': vaporPressure,
      'relative_density': relativeDensity,
      'solubility': solubility,
    };

    final stabilityReactivityMap = {
      'reactivity': reactivity,
      'chemical_stability': chemicalStability,
      'conditions_to_avoid': conditionsToAvoid,
      'incompatible_materials': incompatibleMaterials,
      'hazardous_decomposition': hazardousDecompositionProducts,
    };

    final toxicologicalMap = {
      'acute_toxicity': acuteToxicity,
      'skin_corrosion': skinCorrosionIrritation,
      'serious_eye': seriousEyeDamage,
      'carcinogenicity': carcinogenicity,
      'reproductive_toxicity': reproductiveToxicity,
      'target_organ': targetOrganToxicity,
    };

    final ecologicalMap = {
      'ecotoxicity': ecotoxicity,
      'persistence': persistenceDegradability,
      'bioaccumulation': bioaccumulativePotential,
      'mobility': mobilityInSoil,
    };

    final disposalMap = {
      'waste_treatment': wasteTreatmentMethods,
      'contaminated_packaging': contaminatedPackaging,
    };

    final transportMap = {
      'shipping_name': unProperShippingName,
      'hazard_class': transportHazardClass,
      'packing_group': packingGroup,
      'marine_pollutant': marinePollutant,
      'special_precautions': specialPrecautionsTransport,
    };

    final regulatoryMap = {
      'regulations': safetyHealthRegulations,
      'substance_type': hazardousSubstanceType,
    };

    final otherInfoMap = {
      'emergency_phone': emergencyPhone,
      'recommended_use': recommendedUse,
      'composition_summary': compositionSummary,
      'revision_date': revisionDate,
      'version_no': versionNo,
      'prepared_by': preparedBy,
      'references_list': referencesList,
    };

    return {
      'id': id,
      'inventory_id': inventoryId,
      'trade_name': tradeName,
      'chemical_formula': chemicalFormula,
      'cas_number': casNumber,
      'un_number': unNumber,
      'manufacturer_importer_info': manufacturerImporterInfo,
      'ghs_classification': ghsClassification,
      'ghs_pictograms': jsonEncode(ghsPictograms),
      'signal_word': signalWord,
      'hazard_statements': jsonEncode(hazardStatements),
      'precautionary_statements': jsonEncode(precautionaryStatements),
      'ingredients_json': jsonEncode(ingredients.map((i) => i.toMap()).toList()),
      'first_aid_json': jsonEncode(firstAidMap),
      'fire_fighting_json': jsonEncode(fireFightingMap),
      'accidental_release_json': jsonEncode(accidentalReleaseMap),
      'handling_storage_json': jsonEncode(handlingStorageMap),
      'exposure_controls_json': jsonEncode(exposureControlsMap),
      'physical_chemical_json': jsonEncode(physicalChemicalMap),
      'stability_reactivity_json': jsonEncode(stabilityReactivityMap),
      'toxicological_json': jsonEncode(toxicologicalMap),
      'ecological_json': jsonEncode(ecologicalMap),
      'disposal_json': jsonEncode(disposalMap),
      'transport_json': jsonEncode(transportMap),
      'regulatory_json': jsonEncode(regulatoryMap),
      'other_info_json': jsonEncode(otherInfoMap),
      'nfpa_health': nfpaHealth,
      'nfpa_flammability': nfpaFlammability,
      'nfpa_instability': nfpaInstability,
      'nfpa_special': nfpaSpecial,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Deserializes model from SQLite row map.
  factory ChemicalSdsSor1Model.fromMap(Map<String, dynamic> map) {
    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      try {
        final decoded = jsonDecode(val.toString());
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
      return [];
    }

    Map<String, dynamic> parseJsonMap(dynamic val) {
      if (val == null) return {};
      if (val is Map<String, dynamic>) return val;
      try {
        final decoded = jsonDecode(val.toString());
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
      return {};
    }

    List<SdsIngredientItem> parseIngredients(dynamic val) {
      if (val == null) return [];
      try {
        final decoded = jsonDecode(val.toString());
        if (decoded is List) {
          return decoded.map((i) => SdsIngredientItem.fromMap(Map<String, dynamic>.from(i))).toList();
        }
      } catch (_) {}
      return [];
    }

    final firstAid = parseJsonMap(map['first_aid_json']);
    final fireFighting = parseJsonMap(map['fire_fighting_json']);
    final accidentalRelease = parseJsonMap(map['accidental_release_json']);
    final handlingStorage = parseJsonMap(map['handling_storage_json']);
    final exposureControls = parseJsonMap(map['exposure_controls_json']);
    final physicalChemical = parseJsonMap(map['physical_chemical_json']);
    final stabilityReactivity = parseJsonMap(map['stability_reactivity_json']);
    final toxicological = parseJsonMap(map['toxicological_json']);
    final ecological = parseJsonMap(map['ecological_json']);
    final disposal = parseJsonMap(map['disposal_json']);
    final transport = parseJsonMap(map['transport_json']);
    final regulatory = parseJsonMap(map['regulatory_json']);
    final otherInfo = parseJsonMap(map['other_info_json']);

    return ChemicalSdsSor1Model(
      id: map['id'] as int?,
      inventoryId: map['inventory_id'] as int?,
      tradeName: (map['trade_name'] ?? '').toString(),
      chemicalFormula: map['chemical_formula']?.toString(),
      casNumber: (map['cas_number'] ?? '').toString(),
      unNumber: map['un_number']?.toString(),
      manufacturerImporterInfo: (map['manufacturer_importer_info'] ?? '').toString(),
      emergencyPhone: otherInfo['emergency_phone']?.toString(),
      recommendedUse: otherInfo['recommended_use']?.toString(),
      ghsClassification: map['ghs_classification']?.toString(),
      ghsPictograms: parseList(map['ghs_pictograms']),
      signalWord: (map['signal_word'] ?? 'DANGER').toString(),
      hazardStatements: parseList(map['hazard_statements']),
      precautionaryStatements: parseList(map['precautionary_statements']),
      nfpaHealth: (map['nfpa_health'] as num?)?.toInt() ?? 0,
      nfpaFlammability: (map['nfpa_flammability'] as num?)?.toInt() ?? 0,
      nfpaInstability: (map['nfpa_instability'] as num?)?.toInt() ?? 0,
      nfpaSpecial: map['nfpa_special']?.toString(),
      ingredients: parseIngredients(map['ingredients_json']),
      compositionSummary: otherInfo['composition_summary']?.toString(),
      inhalationFirstAid: firstAid['inhalation']?.toString(),
      skinContactFirstAid: firstAid['skin']?.toString(),
      eyeContactFirstAid: firstAid['eye']?.toString(),
      ingestionFirstAid: firstAid['ingestion']?.toString(),
      symptomsEffects: firstAid['symptoms']?.toString(),
      specialMedicalAttention: firstAid['special_medical']?.toString(),
      suitableExtinguishingMedia: fireFighting['suitable_media']?.toString(),
      unsuitableExtinguishingMedia: fireFighting['unsuitable_media']?.toString(),
      specificFireHazards: fireFighting['specific_hazards']?.toString(),
      protectiveEquipmentFirefighters: fireFighting['protective_equipment']?.toString(),
      personalPrecautions: accidentalRelease['personal_precautions']?.toString(),
      environmentalPrecautions: accidentalRelease['environmental_precautions']?.toString(),
      containmentCleanUp: accidentalRelease['containment_cleanup']?.toString(),
      handlingPrecautions: handlingStorage['handling']?.toString(),
      storageConditions: handlingStorage['storage']?.toString(),
      storageTemperature: handlingStorage['temperature']?.toString(),
      exposureLimits: exposureControls['exposure_limits']?.toString(),
      engineeringControls: exposureControls['engineering_controls']?.toString(),
      respiratoryProtection: exposureControls['respiratory']?.toString(),
      eyeProtection: exposureControls['eye']?.toString(),
      skinHandProtection: exposureControls['skin_hand']?.toString(),
      appearance: physicalChemical['appearance']?.toString(),
      odor: physicalChemical['odor']?.toString(),
      phValue: physicalChemical['ph']?.toString(),
      boilingPoint: physicalChemical['boiling_point']?.toString(),
      flashPoint: physicalChemical['flash_point']?.toString(),
      flammabilityLimits: physicalChemical['flammability_limits']?.toString(),
      vaporPressure: physicalChemical['vapor_pressure']?.toString(),
      relativeDensity: physicalChemical['relative_density']?.toString(),
      solubility: physicalChemical['solubility']?.toString(),
      reactivity: stabilityReactivity['reactivity']?.toString(),
      chemicalStability: stabilityReactivity['chemical_stability']?.toString(),
      conditionsToAvoid: stabilityReactivity['conditions_to_avoid']?.toString(),
      incompatibleMaterials: stabilityReactivity['incompatible_materials']?.toString(),
      hazardousDecompositionProducts: stabilityReactivity['hazardous_decomposition']?.toString(),
      acuteToxicity: toxicological['acute_toxicity']?.toString(),
      skinCorrosionIrritation: toxicological['skin_corrosion']?.toString(),
      seriousEyeDamage: toxicological['serious_eye']?.toString(),
      carcinogenicity: toxicological['carcinogenicity']?.toString(),
      reproductiveToxicity: toxicological['reproductive_toxicity']?.toString(),
      targetOrganToxicity: toxicological['target_organ']?.toString(),
      ecotoxicity: ecological['ecotoxicity']?.toString(),
      persistenceDegradability: ecological['persistence']?.toString(),
      bioaccumulativePotential: ecological['bioaccumulation']?.toString(),
      mobilityInSoil: ecological['mobility']?.toString(),
      wasteTreatmentMethods: disposal['waste_treatment']?.toString(),
      contaminatedPackaging: disposal['contaminated_packaging']?.toString(),
      unProperShippingName: transport['shipping_name']?.toString(),
      transportHazardClass: transport['hazard_class']?.toString(),
      packingGroup: transport['packing_group']?.toString(),
      marinePollutant: transport['marine_pollutant']?.toString(),
      specialPrecautionsTransport: transport['special_precautions']?.toString(),
      safetyHealthRegulations: regulatory['regulations']?.toString(),
      hazardousSubstanceType: regulatory['substance_type']?.toString(),
      revisionDate: otherInfo['revision_date']?.toString(),
      versionNo: (otherInfo['version_no'] ?? '1.0').toString(),
      preparedBy: otherInfo['prepared_by']?.toString(),
      referencesList: otherInfo['references_list']?.toString(),
      status: (map['status'] ?? 'COMPLETED').toString(),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  ChemicalSdsSor1Model copyWith({
    int? id,
    int? inventoryId,
    String? tradeName,
    String? chemicalFormula,
    String? casNumber,
    String? unNumber,
    String? manufacturerImporterInfo,
    String? emergencyPhone,
    String? recommendedUse,
    String? ghsClassification,
    List<String>? ghsPictograms,
    String? signalWord,
    List<String>? hazardStatements,
    List<String>? precautionaryStatements,
    int? nfpaHealth,
    int? nfpaFlammability,
    int? nfpaInstability,
    String? nfpaSpecial,
    List<SdsIngredientItem>? ingredients,
    String? compositionSummary,
    String? inhalationFirstAid,
    String? skinContactFirstAid,
    String? eyeContactFirstAid,
    String? ingestionFirstAid,
    String? symptomsEffects,
    String? specialMedicalAttention,
    String? suitableExtinguishingMedia,
    String? unsuitableExtinguishingMedia,
    String? specificFireHazards,
    String? protectiveEquipmentFirefighters,
    String? personalPrecautions,
    String? environmentalPrecautions,
    String? containmentCleanUp,
    String? handlingPrecautions,
    String? storageConditions,
    String? storageTemperature,
    String? exposureLimits,
    String? engineeringControls,
    String? respiratoryProtection,
    String? eyeProtection,
    String? skinHandProtection,
    String? appearance,
    String? odor,
    String? phValue,
    String? boilingPoint,
    String? flashPoint,
    String? flammabilityLimits,
    String? vaporPressure,
    String? relativeDensity,
    String? solubility,
    String? reactivity,
    String? chemicalStability,
    String? conditionsToAvoid,
    String? incompatibleMaterials,
    String? hazardousDecompositionProducts,
    String? acuteToxicity,
    String? skinCorrosionIrritation,
    String? seriousEyeDamage,
    String? carcinogenicity,
    String? reproductiveToxicity,
    String? targetOrganToxicity,
    String? ecotoxicity,
    String? persistenceDegradability,
    String? bioaccumulativePotential,
    String? mobilityInSoil,
    String? wasteTreatmentMethods,
    String? contaminatedPackaging,
    String? unProperShippingName,
    String? transportHazardClass,
    String? packingGroup,
    String? marinePollutant,
    String? specialPrecautionsTransport,
    String? safetyHealthRegulations,
    String? hazardousSubstanceType,
    String? revisionDate,
    String? versionNo,
    String? preparedBy,
    String? referencesList,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return ChemicalSdsSor1Model(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      tradeName: tradeName ?? this.tradeName,
      chemicalFormula: chemicalFormula ?? this.chemicalFormula,
      casNumber: casNumber ?? this.casNumber,
      unNumber: unNumber ?? this.unNumber,
      manufacturerImporterInfo: manufacturerImporterInfo ?? this.manufacturerImporterInfo,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      recommendedUse: recommendedUse ?? this.recommendedUse,
      ghsClassification: ghsClassification ?? this.ghsClassification,
      ghsPictograms: ghsPictograms ?? this.ghsPictograms,
      signalWord: signalWord ?? this.signalWord,
      hazardStatements: hazardStatements ?? this.hazardStatements,
      precautionaryStatements: precautionaryStatements ?? this.precautionaryStatements,
      nfpaHealth: nfpaHealth ?? this.nfpaHealth,
      nfpaFlammability: nfpaFlammability ?? this.nfpaFlammability,
      nfpaInstability: nfpaInstability ?? this.nfpaInstability,
      nfpaSpecial: nfpaSpecial ?? this.nfpaSpecial,
      ingredients: ingredients ?? this.ingredients,
      compositionSummary: compositionSummary ?? this.compositionSummary,
      inhalationFirstAid: inhalationFirstAid ?? this.inhalationFirstAid,
      skinContactFirstAid: skinContactFirstAid ?? this.skinContactFirstAid,
      eyeContactFirstAid: eyeContactFirstAid ?? this.eyeContactFirstAid,
      ingestionFirstAid: ingestionFirstAid ?? this.ingestionFirstAid,
      symptomsEffects: symptomsEffects ?? this.symptomsEffects,
      specialMedicalAttention: specialMedicalAttention ?? this.specialMedicalAttention,
      suitableExtinguishingMedia: suitableExtinguishingMedia ?? this.suitableExtinguishingMedia,
      unsuitableExtinguishingMedia: unsuitableExtinguishingMedia ?? this.unsuitableExtinguishingMedia,
      specificFireHazards: specificFireHazards ?? this.specificFireHazards,
      protectiveEquipmentFirefighters: protectiveEquipmentFirefighters ?? this.protectiveEquipmentFirefighters,
      personalPrecautions: personalPrecautions ?? this.personalPrecautions,
      environmentalPrecautions: environmentalPrecautions ?? this.environmentalPrecautions,
      containmentCleanUp: containmentCleanUp ?? this.containmentCleanUp,
      handlingPrecautions: handlingPrecautions ?? this.handlingPrecautions,
      storageConditions: storageConditions ?? this.storageConditions,
      storageTemperature: storageTemperature ?? this.storageTemperature,
      exposureLimits: exposureLimits ?? this.exposureLimits,
      engineeringControls: engineeringControls ?? this.engineeringControls,
      respiratoryProtection: respiratoryProtection ?? this.respiratoryProtection,
      eyeProtection: eyeProtection ?? this.eyeProtection,
      skinHandProtection: skinHandProtection ?? this.skinHandProtection,
      appearance: appearance ?? this.appearance,
      odor: odor ?? this.odor,
      phValue: phValue ?? this.phValue,
      boilingPoint: boilingPoint ?? this.boilingPoint,
      flashPoint: flashPoint ?? this.flashPoint,
      flammabilityLimits: flammabilityLimits ?? this.flammabilityLimits,
      vaporPressure: vaporPressure ?? this.vaporPressure,
      relativeDensity: relativeDensity ?? this.relativeDensity,
      solubility: solubility ?? this.solubility,
      reactivity: reactivity ?? this.reactivity,
      chemicalStability: chemicalStability ?? this.chemicalStability,
      conditionsToAvoid: conditionsToAvoid ?? this.conditionsToAvoid,
      incompatibleMaterials: incompatibleMaterials ?? this.incompatibleMaterials,
      hazardousDecompositionProducts: hazardousDecompositionProducts ?? this.hazardousDecompositionProducts,
      acuteToxicity: acuteToxicity ?? this.acuteToxicity,
      skinCorrosionIrritation: skinCorrosionIrritation ?? this.skinCorrosionIrritation,
      seriousEyeDamage: seriousEyeDamage ?? this.seriousEyeDamage,
      carcinogenicity: carcinogenicity ?? this.carcinogenicity,
      reproductiveToxicity: reproductiveToxicity ?? this.reproductiveToxicity,
      targetOrganToxicity: targetOrganToxicity ?? this.targetOrganToxicity,
      ecotoxicity: ecotoxicity ?? this.ecotoxicity,
      persistenceDegradability: persistenceDegradability ?? this.persistenceDegradability,
      bioaccumulativePotential: bioaccumulativePotential ?? this.bioaccumulativePotential,
      mobilityInSoil: mobilityInSoil ?? this.mobilityInSoil,
      wasteTreatmentMethods: wasteTreatmentMethods ?? this.wasteTreatmentMethods,
      contaminatedPackaging: contaminatedPackaging ?? this.contaminatedPackaging,
      unProperShippingName: unProperShippingName ?? this.unProperShippingName,
      transportHazardClass: transportHazardClass ?? this.transportHazardClass,
      packingGroup: packingGroup ?? this.packingGroup,
      marinePollutant: marinePollutant ?? this.marinePollutant,
      specialPrecautionsTransport: specialPrecautionsTransport ?? this.specialPrecautionsTransport,
      safetyHealthRegulations: safetyHealthRegulations ?? this.safetyHealthRegulations,
      hazardousSubstanceType: hazardousSubstanceType ?? this.hazardousSubstanceType,
      revisionDate: revisionDate ?? this.revisionDate,
      versionNo: versionNo ?? this.versionNo,
      preparedBy: preparedBy ?? this.preparedBy,
      referencesList: referencesList ?? this.referencesList,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
