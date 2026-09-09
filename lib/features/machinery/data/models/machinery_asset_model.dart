class MachineryAssetModel {
  final int? id;
  final String assetTag;
  final String assetName;
  final String category; // CRANE, HOIST, SLING_WIRE, SLING_WEBBING, CHAIN, SHACKLE, MACHINE_GUARD
  final String? ratedCapacity;
  final String location;
  final String? manufacturerBrand;
  final String? serialNo;
  final String status; // READY, DEFECTIVE, IN_REPAIR, RETIRED
  final String? lastInspectedDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MachineryAssetModel({
    this.id,
    required this.assetTag,
    required this.assetName,
    required this.category,
    this.ratedCapacity,
    required this.location,
    this.manufacturerBrand,
    this.serialNo,
    this.status = 'READY',
    this.lastInspectedDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  String get categoryTh {
    switch (category) {
      case 'CRANE':
        return 'ปั้นจั่น (Crane)';
      case 'HOIST':
        return 'รอกไฟฟ้า / กว้าน (Hoist / Winch)';
      case 'SLING_WIRE':
        return 'ลวดสลิงยกของ (Wire Rope Sling)';
      case 'SLING_WEBBING':
        return 'สายรัดผ้าใบโพลีเอสเตอร์ (Webbing Sling)';
      case 'CHAIN':
        return 'โซ่ยกของ (Lifting Chain)';
      case 'SHACKLE':
        return 'สะเก็น / ห่วงคล้อง (Shackle / Ring)';
      case 'MACHINE_GUARD':
        return 'การ์ดป้องกันจุดอันตรายเครื่องจักร (Machine Guarding)';
      default:
        return category;
    }
  }

  String get statusTh {
    switch (status) {
      case 'READY':
        return 'พร้อมใช้งาน (READY)';
      case 'DEFECTIVE':
        return 'ชำรุดห้ามใช้ (DEFECTIVE)';
      case 'IN_REPAIR':
        return 'อยู่ระหว่างซ่อม (IN REPAIR)';
      case 'RETIRED':
        return 'ปลดระวาง (RETIRED)';
      default:
        return status;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'asset_tag': assetTag,
      'asset_name': assetName,
      'category': category,
      'rated_capacity': ratedCapacity,
      'location': location,
      'manufacturer_brand': manufacturerBrand,
      'serial_no': serialNo,
      'status': status,
      'last_inspected_date': lastInspectedDate,
      'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  factory MachineryAssetModel.fromMap(Map<String, dynamic> map) {
    return MachineryAssetModel(
      id: map['id'] as int?,
      assetTag: map['asset_tag'] as String? ?? '',
      assetName: map['asset_name'] as String? ?? '',
      category: map['category'] as String? ?? 'CRANE',
      ratedCapacity: map['rated_capacity'] as String?,
      location: map['location'] as String? ?? '',
      manufacturerBrand: map['manufacturer_brand'] as String?,
      serialNo: map['serial_no'] as String?,
      status: map['status'] as String? ?? 'READY',
      lastInspectedDate: map['last_inspected_date'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'] as String) : null,
    );
  }

  MachineryAssetModel copyWith({
    int? id,
    String? assetTag,
    String? assetName,
    String? category,
    String? ratedCapacity,
    String? location,
    String? manufacturerBrand,
    String? serialNo,
    String? status,
    String? lastInspectedDate,
    String? notes,
  }) {
    return MachineryAssetModel(
      id: id ?? this.id,
      assetTag: assetTag ?? this.assetTag,
      assetName: assetName ?? this.assetName,
      category: category ?? this.category,
      ratedCapacity: ratedCapacity ?? this.ratedCapacity,
      location: location ?? this.location,
      manufacturerBrand: manufacturerBrand ?? this.manufacturerBrand,
      serialNo: serialNo ?? this.serialNo,
      status: status ?? this.status,
      lastInspectedDate: lastInspectedDate ?? this.lastInspectedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
