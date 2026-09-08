enum PpeCategory {
  head('HEAD', 'อุปกรณ์ป้องกันศีรษะ', 'หมวกนิรภัย, กระบังป้องกันกระแทก', 0xFF2563EB),
  eyeFace('EYE_FACE', 'อุปกรณ์ป้องกันดวงตาและใบหน้า', 'แว่นตานิรภัย, กระบังหน้า, แว่นครอบตากันสารเคมี', 0xFF0D9488),
  hearing('HEARING', 'อุปกรณ์ป้องกันระบบการได้ยิน', 'ปลั๊กอุดหู (Earplugs), ที่ครอบหู (Earmuffs)', 0xFFD97706),
  respiratory('RESPIRATORY', 'อุปกรณ์ป้องกันระบบทางเดินหายใจ', 'หน้ากาก N95, หน้ากากไส้กรองสารเคมี, SCBA', 0xFFDC2626),
  handArm('HAND_ARM', 'อุปกรณ์ป้องกันมือและแขน', 'ถุงมือกันบาด, ถุงมือกันสารเคมี, ถุงมือฉนวนไฟฟ้า', 0xFF7C3AED),
  footLeg('FOOT_LEG', 'อุปกรณ์ป้องกันเท้าและขา', 'รองเท้านิรภัยหัวเหล็ก, รองเท้าบูทยางกันสารเคมี', 0xFF475569),
  fallProtection('FALL_PROTECTION', 'อุปกรณ์ป้องกันการตกจากที่สูง', 'Full Body Harness, เชือกช่วยชีวิต (Lanyard), เชือกดูดซับแรง', 0xFFEA580C),
  body('BODY', 'อุปกรณ์ป้องกันลำตัว', 'ชุดกันสารเคมี, เสื้อสะท้อนแสง, ชุดทนไฟ/ประกายไฟ', 0xFF0284C7);

  final String code;
  final String labelTh;
  final String description;
  final int colorValue;

  const PpeCategory(this.code, this.labelTh, this.description, this.colorValue);

  static PpeCategory fromCode(String? code) {
    return PpeCategory.values.firstWhere(
      (e) => e.code.toUpperCase() == code?.trim().toUpperCase(),
      orElse: () => PpeCategory.head,
    );
  }
}

class PpeItem {
  final int? id;
  final String code;
  final String name;
  final PpeCategory category;
  final String standardCert; // e.g. มอก. 368-2554, ANSI Z89.1, EN 397
  final String? description;
  final String unit; // ชิ้น, คู่, ชุด, กล่อง
  final int currentStock;
  final int minStock;
  final double unitCost;
  final String? storageLocation;
  final int? replacementCycleDays; // e.g. 180, 365 days
  final int? preferredSupplierId;
  final String? preferredSupplierName;
  final String? imagePath;
  final String status; // ACTIVE, INACTIVE
  final String? createdAt;
  final String? updatedAt;

  const PpeItem({
    this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.standardCert,
    this.description,
    this.unit = 'ชิ้น',
    this.currentStock = 0,
    this.minStock = 5,
    this.unitCost = 0.0,
    this.storageLocation,
    this.replacementCycleDays,
    this.preferredSupplierId,
    this.preferredSupplierName,
    this.imagePath,
    this.status = 'ACTIVE',
    this.createdAt,
    this.updatedAt,
  });

  bool get isLowStock => currentStock <= minStock;
  bool get isOutOfStock => currentStock <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category.code,
      'standard_cert': standardCert,
      'description': description,
      'unit': unit,
      'current_stock': currentStock,
      'min_stock': minStock,
      'unit_cost': unitCost,
      'storage_location': storageLocation,
      'replacement_cycle_days': replacementCycleDays,
      'preferred_supplier_id': preferredSupplierId,
      'preferred_supplier_name': preferredSupplierName,
      'image_path': imagePath,
      'status': status,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory PpeItem.fromMap(Map<String, dynamic> map) {
    return PpeItem(
      id: map['id'] as int?,
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: PpeCategory.fromCode(map['category']?.toString()),
      standardCert: map['standard_cert']?.toString() ?? '',
      description: map['description']?.toString(),
      unit: map['unit']?.toString() ?? 'ชิ้น',
      currentStock: (map['current_stock'] as num?)?.toInt() ?? 0,
      minStock: (map['min_stock'] as num?)?.toInt() ?? 5,
      unitCost: (map['unit_cost'] as num?)?.toDouble() ?? 0.0,
      storageLocation: map['storage_location']?.toString(),
      replacementCycleDays: (map['replacement_cycle_days'] as num?)?.toInt(),
      preferredSupplierId: (map['preferred_supplier_id'] as num?)?.toInt(),
      preferredSupplierName: map['preferred_supplier_name']?.toString(),
      imagePath: map['image_path']?.toString(),
      status: map['status']?.toString() ?? 'ACTIVE',
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  PpeItem copyWith({
    int? id,
    String? code,
    String? name,
    PpeCategory? category,
    String? standardCert,
    String? description,
    String? unit,
    int? currentStock,
    int? minStock,
    double? unitCost,
    String? storageLocation,
    int? replacementCycleDays,
    int? preferredSupplierId,
    String? preferredSupplierName,
    String? imagePath,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return PpeItem(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      standardCert: standardCert ?? this.standardCert,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      unitCost: unitCost ?? this.unitCost,
      storageLocation: storageLocation ?? this.storageLocation,
      replacementCycleDays: replacementCycleDays ?? this.replacementCycleDays,
      preferredSupplierId: preferredSupplierId ?? this.preferredSupplierId,
      preferredSupplierName: preferredSupplierName ?? this.preferredSupplierName,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
