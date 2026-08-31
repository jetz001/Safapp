import 'package:flutter/material.dart';

/// Model representing a Thai Royal Gazette chemical safety regulation / statutory document.
class ChemicalLawItem {
  final String id;
  final String titleTh;
  final String titleEn;
  final String issuingAuthority;
  final String gazetteDate;
  final String gazetteVolume;
  final String gazettePart;
  final String category; // 'MINISTERIAL_REG', 'DLPW_NOTIF', 'ACT', 'MIN_INDUSTRY'
  final String summary;
  final List<String> keyProvisions;
  final String? pdfAssetPath;
  final String? externalUrl;
  final int sortOrder;

  const ChemicalLawItem({
    required this.id,
    required this.titleTh,
    required this.titleEn,
    required this.issuingAuthority,
    required this.gazetteDate,
    required this.gazetteVolume,
    required this.gazettePart,
    required this.category,
    required this.summary,
    required this.keyProvisions,
    this.pdfAssetPath,
    this.externalUrl,
    this.sortOrder = 0,
  });

  ChemicalLawItem copyWith({
    String? id,
    String? titleTh,
    String? titleEn,
    String? issuingAuthority,
    String? gazetteDate,
    String? gazetteVolume,
    String? gazettePart,
    String? category,
    String? summary,
    List<String>? keyProvisions,
    String? pdfAssetPath,
    String? externalUrl,
    int? sortOrder,
  }) {
    return ChemicalLawItem(
      id: id ?? this.id,
      titleTh: titleTh ?? this.titleTh,
      titleEn: titleEn ?? this.titleEn,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      gazetteDate: gazetteDate ?? this.gazetteDate,
      gazetteVolume: gazetteVolume ?? this.gazetteVolume,
      gazettePart: gazettePart ?? this.gazettePart,
      category: category ?? this.category,
      summary: summary ?? this.summary,
      keyProvisions: keyProvisions ?? this.keyProvisions,
      pdfAssetPath: pdfAssetPath ?? this.pdfAssetPath,
      externalUrl: externalUrl ?? this.externalUrl,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title_th': titleTh,
      'title_en': titleEn,
      'issuing_authority': issuingAuthority,
      'gazette_date': gazetteDate,
      'gazette_volume': gazetteVolume,
      'gazette_part': gazettePart,
      'category': category,
      'summary': summary,
      'key_provisions': keyProvisions,
      'pdf_asset_path': pdfAssetPath,
      'external_url': externalUrl,
      'sort_order': sortOrder,
    };
  }

  factory ChemicalLawItem.fromMap(Map<String, dynamic> map) {
    return ChemicalLawItem(
      id: (map['id'] ?? '').toString(),
      titleTh: (map['title_th'] ?? '').toString(),
      titleEn: (map['title_en'] ?? '').toString(),
      issuingAuthority: (map['issuing_authority'] ?? '').toString(),
      gazetteDate: (map['gazette_date'] ?? '').toString(),
      gazetteVolume: (map['gazette_volume'] ?? '').toString(),
      gazettePart: (map['gazette_part'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      summary: (map['summary'] ?? '').toString(),
      keyProvisions: (map['key_provisions'] is List)
          ? (map['key_provisions'] as List).map((e) => e.toString()).toList()
          : [],
      pdfAssetPath: map['pdf_asset_path']?.toString(),
      externalUrl: map['external_url']?.toString(),
      sortOrder: map['sort_order'] is int ? map['sort_order'] as int : 0,
    );
  }

  String get gazetteCitation => 'ราชกิจจานุเบกษา เล่ม $gazetteVolume ตอน $gazettePart วันที่ $gazetteDate';

  IconData get categoryIcon {
    switch (category) {
      case 'ACT':
        return Icons.gavel_rounded;
      case 'MINISTERIAL_REG':
        return Icons.account_balance_rounded;
      case 'DLPW_NOTIF':
        return Icons.verified_user_rounded;
      case 'MIN_INDUSTRY':
        return Icons.factory_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'ACT':
        return const Color(0xFF4338CA); // Indigo
      case 'MINISTERIAL_REG':
        return const Color(0xFF0284C7); // Sky Blue
      case 'DLPW_NOTIF':
        return const Color(0xFF0D9488); // Teal
      case 'MIN_INDUSTRY':
        return const Color(0xFFD97706); // Amber
      default:
        return const Color(0xFF4B5563);
    }
  }

  String get categoryLabelTh {
    switch (category) {
      case 'ACT':
        return 'พระราชบัญญัติ (Act)';
      case 'MINISTERIAL_REG':
        return 'กฎกระทรวง (Ministerial Reg.)';
      case 'DLPW_NOTIF':
        return 'ประกาศกรมสวัสดิการฯ (DLPW)';
      case 'MIN_INDUSTRY':
        return 'ประกาศกระทรวงอุตสาหกรรม (DIW)';
      default:
        return 'ระเบียบ/ข้อบังคับ';
    }
  }
}
