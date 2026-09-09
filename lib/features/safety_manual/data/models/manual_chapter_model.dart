class ManualChapterModel {
  final int chapterNumber;
  final String titleTh;
  final String titleEn;
  final String? categoryKey;
  final String content;
  final List<String> keyRules;
  final bool isCustom;

  const ManualChapterModel({
    required this.chapterNumber,
    required this.titleTh,
    required this.titleEn,
    this.categoryKey,
    required this.content,
    this.keyRules = const [],
    this.isCustom = false,
  });

  ManualChapterModel copyWith({
    int? chapterNumber,
    String? titleTh,
    String? titleEn,
    String? categoryKey,
    String? content,
    List<String>? keyRules,
    bool? isCustom,
  }) {
    return ManualChapterModel(
      chapterNumber: chapterNumber ?? this.chapterNumber,
      titleTh: titleTh ?? this.titleTh,
      titleEn: titleEn ?? this.titleEn,
      categoryKey: categoryKey ?? this.categoryKey,
      content: content ?? this.content,
      keyRules: keyRules ?? this.keyRules,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
