import '../../domain/enums/cpo_action_status.dart';

class CpoActionItemModel {
  final int? id;
  final String itemCode;
  final int meetingId;
  final int? agendaId;
  final int agendaNo;
  final String title;
  final String actionDetail;
  final String responsiblePerson;
  final String? department;
  final String dueDate;
  final String priority; // LOW, MEDIUM, HIGH, URGENT
  final CpoActionStatus status;
  final int progressPercent;
  final String? resolutionNotes;
  final String? completedDate;
  final String? evidencePhotoPath;
  final String? createdAt;
  final String? updatedAt;

  const CpoActionItemModel({
    this.id,
    required this.itemCode,
    required this.meetingId,
    this.agendaId,
    this.agendaNo = 5,
    required this.title,
    required this.actionDetail,
    required this.responsiblePerson,
    this.department,
    required this.dueDate,
    this.priority = 'MEDIUM',
    this.status = CpoActionStatus.pending,
    this.progressPercent = 0,
    this.resolutionNotes,
    this.completedDate,
    this.evidencePhotoPath,
    this.createdAt,
    this.updatedAt,
  });

  bool get isOverdue {
    if (status == CpoActionStatus.completed || status == CpoActionStatus.cancelled) {
      return false;
    }
    try {
      final due = DateTime.parse(dueDate);
      return DateTime.now().isAfter(due);
    } catch (_) {
      return false;
    }
  }

  String get taskTitle => title;
  String? get assigneeName => responsiblePerson;
  int get progressPercentage => progressPercent;
  String? get notes => resolutionNotes;

  CpoActionItemModel copyWith({
    int? id,
    String? itemCode,
    int? meetingId,
    int? agendaId,
    int? agendaNo,
    String? title,
    String? actionDetail,
    String? responsiblePerson,
    String? department,
    String? dueDate,
    String? priority,
    CpoActionStatus? status,
    int? progressPercent,
    String? resolutionNotes,
    String? completedDate,
    String? evidencePhotoPath,
    String? createdAt,
    String? updatedAt,
  }) {
    return CpoActionItemModel(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      meetingId: meetingId ?? this.meetingId,
      agendaId: agendaId ?? this.agendaId,
      agendaNo: agendaNo ?? this.agendaNo,
      title: title ?? this.title,
      actionDetail: actionDetail ?? this.actionDetail,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      department: department ?? this.department,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      completedDate: completedDate ?? this.completedDate,
      evidencePhotoPath: evidencePhotoPath ?? this.evidencePhotoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'item_code': itemCode,
      'meeting_id': meetingId,
      'agenda_id': agendaId,
      'agenda_no': agendaNo,
      'title': title,
      'action_detail': actionDetail,
      'responsible_person': responsiblePerson,
      'department': department,
      'due_date': dueDate,
      'priority': priority,
      'status': status.toDbCode(),
      'progress_percent': progressPercent,
      'resolution_notes': resolutionNotes,
      'completed_date': completedDate,
      'evidence_photo_path': evidencePhotoPath,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory CpoActionItemModel.fromMap(Map<String, dynamic> map) {
    return CpoActionItemModel(
      id: map['id'] as int?,
      itemCode: map['item_code']?.toString() ?? '',
      meetingId: (map['meeting_id'] as num?)?.toInt() ?? 0,
      agendaId: (map['agenda_id'] as num?)?.toInt(),
      agendaNo: (map['agenda_no'] as num?)?.toInt() ?? 5,
      title: map['title']?.toString() ?? '',
      actionDetail: map['action_detail']?.toString() ?? '',
      responsiblePerson: map['responsible_person']?.toString() ?? '',
      department: map['department']?.toString(),
      dueDate: map['due_date']?.toString() ?? '',
      priority: map['priority']?.toString() ?? 'MEDIUM',
      status: CpoActionStatus.fromDbCode(map['status']?.toString()),
      progressPercent: (map['progress_percent'] as num?)?.toInt() ?? 0,
      resolutionNotes: map['resolution_notes']?.toString(),
      completedDate: map['completed_date']?.toString(),
      evidencePhotoPath: map['evidence_photo_path']?.toString(),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }
}
