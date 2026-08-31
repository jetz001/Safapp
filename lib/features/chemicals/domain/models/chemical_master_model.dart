/// Model representing an item in the Thai Hazardous Chemicals Master List (1,516 items)
/// per Department of Labour Protection and Welfare (DLPW) Notification B.E. 2556.
class ChemicalMasterItem {
  final int sequenceNo;
  final String thaiName;
  final String englishName;
  final String casNumber;
  final String? unNumber;
  final String? hazardCategory;
  final double? molecularWeight;
  final String? chemicalFormula;

  const ChemicalMasterItem({
    required this.sequenceNo,
    required this.thaiName,
    required this.englishName,
    required this.casNumber,
    this.unNumber,
    this.hazardCategory,
    this.molecularWeight,
    this.chemicalFormula,
  });

  ChemicalMasterItem copyWith({
    int? sequenceNo,
    String? thaiName,
    String? englishName,
    String? casNumber,
    String? unNumber,
    String? hazardCategory,
    double? molecularWeight,
    String? chemicalFormula,
  }) {
    return ChemicalMasterItem(
      sequenceNo: sequenceNo ?? this.sequenceNo,
      thaiName: thaiName ?? this.thaiName,
      englishName: englishName ?? this.englishName,
      casNumber: casNumber ?? this.casNumber,
      unNumber: unNumber ?? this.unNumber,
      hazardCategory: hazardCategory ?? this.hazardCategory,
      molecularWeight: molecularWeight ?? this.molecularWeight,
      chemicalFormula: chemicalFormula ?? this.chemicalFormula,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sequence_no': sequenceNo,
      'thai_name': thaiName,
      'english_name': englishName,
      'cas_number': casNumber,
      'un_number': unNumber,
      'hazard_category': hazardCategory,
      'molecular_weight': molecularWeight,
      'chemical_formula': chemicalFormula,
    };
  }

  factory ChemicalMasterItem.fromMap(Map<String, dynamic> map) {
    return ChemicalMasterItem(
      sequenceNo: map['sequence_no'] is int
          ? map['sequence_no'] as int
          : int.tryParse(map['sequence_no']?.toString() ?? '0') ?? 0,
      thaiName: (map['thai_name'] ?? '').toString(),
      englishName: (map['english_name'] ?? '').toString(),
      casNumber: (map['cas_number'] ?? '').toString(),
      unNumber: map['un_number']?.toString(),
      hazardCategory: map['hazard_category']?.toString(),
      molecularWeight: map['molecular_weight'] != null
          ? double.tryParse(map['molecular_weight'].toString())
          : null,
      chemicalFormula: map['chemical_formula']?.toString(),
    );
  }

  /// Calculates a relevance score (0-100) for autocomplete ranking.
  /// Handles dashes in CAS numbers gracefully (e.g. 7664939 matches 7664-93-9).
  int matchScore(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return 0;

    final cleanQuery = query.replaceAll(RegExp(r'[^a-zA-Z0-9\u0E00-\u0E7F]'), '');
    final cleanCas = casNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final enLower = englishName.toLowerCase();
    final thLower = thaiName.toLowerCase();

    // 1. Exact CAS match
    if (casNumber.toLowerCase() == query || (cleanCas.isNotEmpty && cleanCas == cleanQuery)) {
      return 100;
    }

    // 2. CAS prefix match
    if (casNumber.toLowerCase().startsWith(query) || (cleanCas.isNotEmpty && cleanCas.startsWith(cleanQuery))) {
      return 90;
    }

    // 3. Exact Name match (EN or TH)
    if (enLower == query || thLower == query) {
      return 85;
    }

    // 4. Name prefix match
    if (enLower.startsWith(query) || thLower.startsWith(query)) {
      return 75;
    }

    // 5. Name contains word boundary match
    if (enLower.contains(' $query') || enLower.contains('-$query') || enLower.contains('($query')) {
      return 65;
    }

    // 6. Substring match
    if (enLower.contains(query) || thLower.contains(query) || casNumber.toLowerCase().contains(query)) {
      return 50;
    }

    // 7. Sequence number match (e.g. #42)
    if (query.startsWith('#') && sequenceNo.toString() == query.replaceFirst('#', '')) {
      return 95;
    }
    if (sequenceNo.toString() == query) {
      return 40;
    }

    return 0;
  }

  @override
  String toString() => '$sequenceNo: $thaiName ($englishName) [CAS: $casNumber]';
}
