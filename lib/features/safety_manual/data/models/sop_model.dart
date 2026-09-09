import 'dart:convert';
import 'package:flutter/material.dart';

class SopStepModel {
  final int stepNumber;
  final String title;
  final String action;
  final String? safetyCheckpoint;

  const SopStepModel({
    required this.stepNumber,
    required this.title,
    required this.action,
    this.safetyCheckpoint,
  });

  Map<String, dynamic> toMap() {
    return {
      'stepNumber': stepNumber,
      'title': title,
      'action': action,
      'safetyCheckpoint': safetyCheckpoint,
    };
  }

  factory SopStepModel.fromMap(Map<String, dynamic> map) {
    return SopStepModel(
      stepNumber: map['stepNumber'] as int? ?? 1,
      title: map['title'] as String? ?? '',
      action: map['action'] as String? ?? '',
      safetyCheckpoint: map['safetyCheckpoint'] as String?,
    );
  }
}

class SopModel {
  final int? id;
  final String docCode;
  final String title;
  final String category;
  final String revision;
  final DateTime effectiveDate;
  final DateTime reviewDueDate;
  final String? purpose;
  final String? scope;
  final List<String> requiredPpeList;
  final String? precautions;
  final List<SopStepModel> steps;
  final String? emergencyProcedure;
  final String? pdfFilePath;
  final String? author;
  final String? reviewer;
  final String? approver;
  final String status;

  const SopModel({
    this.id,
    required this.docCode,
    required this.title,
    required this.category,
    this.revision = 'Rev. 01',
    required this.effectiveDate,
    required this.reviewDueDate,
    this.purpose,
    this.scope,
    this.requiredPpeList = const [],
    this.precautions,
    this.steps = const [],
    this.emergencyProcedure,
    this.pdfFilePath,
    this.author,
    this.reviewer,
    this.approver,
    this.status = 'ACTIVE',
  });

  int get daysUntilReview => reviewDueDate.difference(DateTime.now()).inDays;
  bool get isReviewDue => daysUntilReview < 0;
  bool get isReviewWarning => daysUntilReview >= 0 && daysUntilReview <= 30;

  String get categoryTh {
    switch (category) {
      case 'MACHINERY':
        return 'เครื่องจักร & ปั้นจั่น';
      case 'ELECTRICAL':
        return 'ระบบไฟฟ้า & LOTO';
      case 'CHEMICAL':
        return 'สารเคมีอันตราย';
      case 'CONFINED_SPACE':
        return 'ที่อับอากาศ';
      case 'HEIGHTS':
        return 'ทำงานบนที่สูง';
      case 'EMERGENCY':
        return 'ระงับอัคคีภัย & ฉุกเฉิน';
      case 'PPE':
        return 'อุปกรณ์ PPE';
      default:
        return 'ความปลอดภัยทั่วไป';
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case 'MACHINERY':
        return Icons.precision_manufacturing;
      case 'ELECTRICAL':
        return Icons.bolt;
      case 'CHEMICAL':
        return Icons.science;
      case 'CONFINED_SPACE':
        return Icons.door_front_door;
      case 'HEIGHTS':
        return Icons.stairs;
      case 'EMERGENCY':
        return Icons.local_fire_department;
      case 'PPE':
        return Icons.health_and_safety;
      default:
        return Icons.menu_book;
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'MACHINERY':
        return const Color(0xFF0284C7); // Sky Blue
      case 'ELECTRICAL':
        return const Color(0xFFD97706); // Amber
      case 'CHEMICAL':
        return const Color(0xFF9333EA); // Purple
      case 'CONFINED_SPACE':
        return const Color(0xFFDC2626); // Red
      case 'HEIGHTS':
        return const Color(0xFFEA580C); // Orange
      case 'EMERGENCY':
        return const Color(0xFFE11D48); // Rose
      case 'PPE':
        return const Color(0xFF0D9488); // Teal
      default:
        return const Color(0xFF475569); // Slate
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'doc_code': docCode,
      'title': title,
      'category': category,
      'revision': revision,
      'effective_date': effectiveDate.toIso8601String().substring(0, 10),
      'review_due_date': reviewDueDate.toIso8601String().substring(0, 10),
      'purpose': purpose,
      'scope': scope,
      'required_ppe': jsonEncode(requiredPpeList),
      'precautions': precautions,
      'steps_json': jsonEncode(steps.map((s) => s.toMap()).toList()),
      'emergency_procedure': emergencyProcedure,
      'pdf_file_path': pdfFilePath,
      'author': author,
      'reviewer': reviewer,
      'approver': approver,
      'status': status,
    };
  }

  factory SopModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedPpe = [];
    if (map['required_ppe'] != null && map['required_ppe'] is String) {
      try {
        final decoded = jsonDecode(map['required_ppe'] as String);
        if (decoded is List) {
          parsedPpe = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    List<SopStepModel> parsedSteps = [];
    if (map['steps_json'] != null && map['steps_json'] is String) {
      try {
        final decoded = jsonDecode(map['steps_json'] as String);
        if (decoded is List) {
          parsedSteps = decoded
              .map((e) => SopStepModel.fromMap(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    DateTime effDate = DateTime.now();
    if (map['effective_date'] != null) {
      effDate = DateTime.tryParse(map['effective_date'] as String) ?? DateTime.now();
    }

    DateTime revDueDate = effDate.add(const Duration(days: 365));
    if (map['review_due_date'] != null) {
      revDueDate = DateTime.tryParse(map['review_due_date'] as String) ?? revDueDate;
    }

    return SopModel(
      id: map['id'] as int?,
      docCode: map['doc_code'] as String? ?? 'SOP-000',
      title: map['title'] as String? ?? 'ไม่มีชื่อเอกสาร',
      category: map['category'] as String? ?? 'GENERAL',
      revision: map['revision'] as String? ?? 'Rev. 01',
      effectiveDate: effDate,
      reviewDueDate: revDueDate,
      purpose: map['purpose'] as String?,
      scope: map['scope'] as String?,
      requiredPpeList: parsedPpe,
      precautions: map['precautions'] as String?,
      steps: parsedSteps,
      emergencyProcedure: map['emergency_procedure'] as String?,
      pdfFilePath: map['pdf_file_path'] as String?,
      author: map['author'] as String?,
      reviewer: map['reviewer'] as String?,
      approver: map['approver'] as String?,
      status: map['status'] as String? ?? 'ACTIVE',
    );
  }

  SopModel copyWith({
    int? id,
    String? docCode,
    String? title,
    String? category,
    String? revision,
    DateTime? effectiveDate,
    DateTime? reviewDueDate,
    String? purpose,
    String? scope,
    List<String>? requiredPpeList,
    String? precautions,
    List<SopStepModel>? steps,
    String? emergencyProcedure,
    String? pdfFilePath,
    String? author,
    String? reviewer,
    String? approver,
    String? status,
  }) {
    return SopModel(
      id: id ?? this.id,
      docCode: docCode ?? this.docCode,
      title: title ?? this.title,
      category: category ?? this.category,
      revision: revision ?? this.revision,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      reviewDueDate: reviewDueDate ?? this.reviewDueDate,
      purpose: purpose ?? this.purpose,
      scope: scope ?? this.scope,
      requiredPpeList: requiredPpeList ?? this.requiredPpeList,
      precautions: precautions ?? this.precautions,
      steps: steps ?? this.steps,
      emergencyProcedure: emergencyProcedure ?? this.emergencyProcedure,
      pdfFilePath: pdfFilePath ?? this.pdfFilePath,
      author: author ?? this.author,
      reviewer: reviewer ?? this.reviewer,
      approver: approver ?? this.approver,
      status: status ?? this.status,
    );
  }
}
