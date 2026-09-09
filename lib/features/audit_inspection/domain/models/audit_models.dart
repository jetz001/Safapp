class AuditSession {
  final int? id;
  final String auditNo;
  final String auditTitle;
  final String auditDate;
  final String leadAuditor;
  final String? auditorTeam;
  final String auditScope;
  final String status; // 'DRAFT', 'IN_PROGRESS', 'COMPLETED', 'ARCHIVED'
  final int totalItems;
  final int conformCount;
  final int minorNcCount;
  final int majorNcCount;
  final int naCount;
  final double compliancePercentage;
  final String? summaryNotes;
  final String? createdAt;
  final String? updatedAt;

  const AuditSession({
    this.id,
    required this.auditNo,
    required this.auditTitle,
    required this.auditDate,
    required this.leadAuditor,
    this.auditorTeam,
    required this.auditScope,
    this.status = 'IN_PROGRESS',
    this.totalItems = 0,
    this.conformCount = 0,
    this.minorNcCount = 0,
    this.majorNcCount = 0,
    this.naCount = 0,
    this.compliancePercentage = 0.0,
    this.summaryNotes,
    this.createdAt,
    this.updatedAt,
  });

  bool get isCompleted => status == 'COMPLETED';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'audit_no': auditNo,
      'audit_title': auditTitle,
      'audit_date': auditDate,
      'lead_auditor': leadAuditor,
      'auditor_team': auditorTeam,
      'audit_scope': auditScope,
      'status': status,
      'total_items': totalItems,
      'conform_count': conformCount,
      'minor_nc_count': minorNcCount,
      'major_nc_count': majorNcCount,
      'na_count': naCount,
      'compliance_percentage': compliancePercentage,
      'summary_notes': summaryNotes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  factory AuditSession.fromMap(Map<String, dynamic> map) {
    return AuditSession(
      id: map['id'] as int?,
      auditNo: map['audit_no'] as String? ?? '',
      auditTitle: map['audit_title'] as String? ?? '',
      auditDate: map['audit_date'] as String? ?? '',
      leadAuditor: map['lead_auditor'] as String? ?? '',
      auditorTeam: map['auditor_team'] as String?,
      auditScope: map['audit_scope'] as String? ?? 'SMS_2565',
      status: map['status'] as String? ?? 'IN_PROGRESS',
      totalItems: map['total_items'] as int? ?? 0,
      conformCount: map['conform_count'] as int? ?? 0,
      minorNcCount: map['minor_nc_count'] as int? ?? 0,
      majorNcCount: map['major_nc_count'] as int? ?? 0,
      naCount: map['na_count'] as int? ?? 0,
      compliancePercentage: (map['compliance_percentage'] as num?)?.toDouble() ?? 0.0,
      summaryNotes: map['summary_notes'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  AuditSession copyWith({
    int? id,
    String? auditNo,
    String? auditTitle,
    String? auditDate,
    String? leadAuditor,
    String? auditorTeam,
    String? auditScope,
    String? status,
    int? totalItems,
    int? conformCount,
    int? minorNcCount,
    int? majorNcCount,
    int? naCount,
    double? compliancePercentage,
    String? summaryNotes,
    String? createdAt,
    String? updatedAt,
  }) {
    return AuditSession(
      id: id ?? this.id,
      auditNo: auditNo ?? this.auditNo,
      auditTitle: auditTitle ?? this.auditTitle,
      auditDate: auditDate ?? this.auditDate,
      leadAuditor: leadAuditor ?? this.leadAuditor,
      auditorTeam: auditorTeam ?? this.auditorTeam,
      auditScope: auditScope ?? this.auditScope,
      status: status ?? this.status,
      totalItems: totalItems ?? this.totalItems,
      conformCount: conformCount ?? this.conformCount,
      minorNcCount: minorNcCount ?? this.minorNcCount,
      majorNcCount: majorNcCount ?? this.majorNcCount,
      naCount: naCount ?? this.naCount,
      compliancePercentage: compliancePercentage ?? this.compliancePercentage,
      summaryNotes: summaryNotes ?? this.summaryNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AuditChecklistItem {
  final int? id;
  final int auditSessionId;
  final String categoryCode; // 'POLICY', 'ORGANIZATION', 'PLANNING', 'EVALUATION', 'IMPROVEMENT', 'SPECIFIC_HAZARD'
  final String categoryTitle;
  final String clauseNo;
  final String itemTitle;
  final String requirementDescription;
  final String legalReference;
  final String? sourceModule;
  final String? evidenceSummary;
  final String? evidenceLinkId;
  final String resultStatus; // 'CONFORM', 'MINOR_NC', 'MAJOR_NC', 'NA', 'UNAUDITED'
  final String? auditorNotes;
  final String? suggestedAction;
  final int sortOrder;

  const AuditChecklistItem({
    this.id,
    required this.auditSessionId,
    required this.categoryCode,
    required this.categoryTitle,
    required this.clauseNo,
    required this.itemTitle,
    required this.requirementDescription,
    required this.legalReference,
    this.sourceModule,
    this.evidenceSummary,
    this.evidenceLinkId,
    this.resultStatus = 'UNAUDITED',
    this.auditorNotes,
    this.suggestedAction,
    this.sortOrder = 0,
  });

  bool get isConform => resultStatus == 'CONFORM';
  bool get isMinorNc => resultStatus == 'MINOR_NC';
  bool get isMajorNc => resultStatus == 'MAJOR_NC';
  bool get isNa => resultStatus == 'NA';
  bool get isUnaudited => resultStatus == 'UNAUDITED';
  bool get isNc => isMinorNc || isMajorNc;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'audit_session_id': auditSessionId,
      'category_code': categoryCode,
      'category_title': categoryTitle,
      'clause_no': clauseNo,
      'item_title': itemTitle,
      'requirement_description': requirementDescription,
      'legal_reference': legalReference,
      'source_module': sourceModule,
      'evidence_summary': evidenceSummary,
      'evidence_link_id': evidenceLinkId,
      'result_status': resultStatus,
      'auditor_notes': auditorNotes,
      'suggested_action': suggestedAction,
      'sort_order': sortOrder,
    };
  }

  factory AuditChecklistItem.fromMap(Map<String, dynamic> map) {
    return AuditChecklistItem(
      id: map['id'] as int?,
      auditSessionId: map['audit_session_id'] as int? ?? 0,
      categoryCode: map['category_code'] as String? ?? '',
      categoryTitle: map['category_title'] as String? ?? '',
      clauseNo: map['clause_no'] as String? ?? '',
      itemTitle: map['item_title'] as String? ?? '',
      requirementDescription: map['requirement_description'] as String? ?? '',
      legalReference: map['legal_reference'] as String? ?? '',
      sourceModule: map['source_module'] as String?,
      evidenceSummary: map['evidence_summary'] as String?,
      evidenceLinkId: map['evidence_link_id'] as String?,
      resultStatus: map['result_status'] as String? ?? 'UNAUDITED',
      auditorNotes: map['auditor_notes'] as String?,
      suggestedAction: map['suggested_action'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  AuditChecklistItem copyWith({
    int? id,
    int? auditSessionId,
    String? categoryCode,
    String? categoryTitle,
    String? clauseNo,
    String? itemTitle,
    String? requirementDescription,
    String? legalReference,
    String? sourceModule,
    String? evidenceSummary,
    String? evidenceLinkId,
    String? resultStatus,
    String? auditorNotes,
    String? suggestedAction,
    int? sortOrder,
  }) {
    return AuditChecklistItem(
      id: id ?? this.id,
      auditSessionId: auditSessionId ?? this.auditSessionId,
      categoryCode: categoryCode ?? this.categoryCode,
      categoryTitle: categoryTitle ?? this.categoryTitle,
      clauseNo: clauseNo ?? this.clauseNo,
      itemTitle: itemTitle ?? this.itemTitle,
      requirementDescription: requirementDescription ?? this.requirementDescription,
      legalReference: legalReference ?? this.legalReference,
      sourceModule: sourceModule ?? this.sourceModule,
      evidenceSummary: evidenceSummary ?? this.evidenceSummary,
      evidenceLinkId: evidenceLinkId ?? this.evidenceLinkId,
      resultStatus: resultStatus ?? this.resultStatus,
      auditorNotes: auditorNotes ?? this.auditorNotes,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class AuditFindingCapa {
  final int? id;
  final int auditSessionId;
  final int? checklistItemId;
  final String findingNo;
  final String findingType; // 'MAJOR_NC', 'MINOR_NC', 'OBSERVATION'
  final String clauseRef;
  final String problemDescription;
  final String? rootCause;
  final String correctiveAction;
  final String? preventiveAction;
  final String responsiblePerson;
  final String dueDate;
  final String status; // 'OPEN', 'IN_PROGRESS', 'CLOSED'
  final String? completedDate;
  final String? verifierName;
  final String? createdAt;

  const AuditFindingCapa({
    this.id,
    required this.auditSessionId,
    this.checklistItemId,
    required this.findingNo,
    required this.findingType,
    required this.clauseRef,
    required this.problemDescription,
    this.rootCause,
    required this.correctiveAction,
    this.preventiveAction,
    required this.responsiblePerson,
    required this.dueDate,
    this.status = 'OPEN',
    this.completedDate,
    this.verifierName,
    this.createdAt,
  });

  bool get isClosed => status == 'CLOSED';
  bool get isOverdue {
    if (isClosed) return false;
    final due = DateTime.tryParse(dueDate);
    if (due == null) return false;
    return DateTime.now().isAfter(due);
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'audit_session_id': auditSessionId,
      'checklist_item_id': checklistItemId,
      'finding_no': findingNo,
      'finding_type': findingType,
      'clause_ref': clauseRef,
      'problem_description': problemDescription,
      'root_cause': rootCause,
      'corrective_action': correctiveAction,
      'preventive_action': preventiveAction,
      'responsible_person': responsiblePerson,
      'due_date': dueDate,
      'status': status,
      'completed_date': completedDate,
      'verifier_name': verifierName,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  factory AuditFindingCapa.fromMap(Map<String, dynamic> map) {
    return AuditFindingCapa(
      id: map['id'] as int?,
      auditSessionId: map['audit_session_id'] as int? ?? 0,
      checklistItemId: map['checklist_item_id'] as int?,
      findingNo: map['finding_no'] as String? ?? '',
      findingType: map['finding_type'] as String? ?? 'MINOR_NC',
      clauseRef: map['clause_ref'] as String? ?? '',
      problemDescription: map['problem_description'] as String? ?? '',
      rootCause: map['root_cause'] as String?,
      correctiveAction: map['corrective_action'] as String? ?? '',
      preventiveAction: map['preventive_action'] as String?,
      responsiblePerson: map['responsible_person'] as String? ?? '',
      dueDate: map['due_date'] as String? ?? '',
      status: map['status'] as String? ?? 'OPEN',
      completedDate: map['completed_date'] as String?,
      verifierName: map['verifier_name'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  AuditFindingCapa copyWith({
    int? id,
    int? auditSessionId,
    int? checklistItemId,
    String? findingNo,
    String? findingType,
    String? clauseRef,
    String? problemDescription,
    String? rootCause,
    String? correctiveAction,
    String? preventiveAction,
    String? responsiblePerson,
    String? dueDate,
    String? status,
    String? completedDate,
    String? verifierName,
    String? createdAt,
  }) {
    return AuditFindingCapa(
      id: id ?? this.id,
      auditSessionId: auditSessionId ?? this.auditSessionId,
      checklistItemId: checklistItemId ?? this.checklistItemId,
      findingNo: findingNo ?? this.findingNo,
      findingType: findingType ?? this.findingType,
      clauseRef: clauseRef ?? this.clauseRef,
      problemDescription: problemDescription ?? this.problemDescription,
      rootCause: rootCause ?? this.rootCause,
      correctiveAction: correctiveAction ?? this.correctiveAction,
      preventiveAction: preventiveAction ?? this.preventiveAction,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      completedDate: completedDate ?? this.completedDate,
      verifierName: verifierName ?? this.verifierName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AuditKpiStats {
  final int totalSessions;
  final int completedSessions;
  final int activeSessions;
  final double averageComplianceRate;
  final int totalConform;
  final int totalMinorNc;
  final int totalMajorNc;
  final int totalOpenCapa;
  final int totalClosedCapa;

  const AuditKpiStats({
    this.totalSessions = 0,
    this.completedSessions = 0,
    this.activeSessions = 0,
    this.averageComplianceRate = 0.0,
    this.totalConform = 0,
    this.totalMinorNc = 0,
    this.totalMajorNc = 0,
    this.totalOpenCapa = 0,
    this.totalClosedCapa = 0,
  });
}

class CrossModuleEvidenceSummary {
  final int electricalInspectionCount;
  final bool hasRecentElectricalCert;
  final int craneInspectionCount;
  final int boilerInspectionCount;
  final int chemicalCount;
  final int ptwActiveCount;
  final int environmentSurveyCount;
  final int emergencyPlanCount;
  final int incidentCount;
  final int cpoMeetingCount;
  final int ppeItemCount;

  const CrossModuleEvidenceSummary({
    this.electricalInspectionCount = 0,
    this.hasRecentElectricalCert = false,
    this.craneInspectionCount = 0,
    this.boilerInspectionCount = 0,
    this.chemicalCount = 0,
    this.ptwActiveCount = 0,
    this.environmentSurveyCount = 0,
    this.emergencyPlanCount = 0,
    this.incidentCount = 0,
    this.cpoMeetingCount = 0,
    this.ppeItemCount = 0,
  });
}
