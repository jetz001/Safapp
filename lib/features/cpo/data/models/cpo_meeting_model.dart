import '../../domain/enums/cpo_meeting_status.dart';

class CpoMeetingModel {
  final int? id;
  final int meetingNo;
  final String meetingYear;
  final String meetingTitle;
  final String meetingDate;
  final String startTime;
  final String endTime;
  final String location;
  final int? termId;
  final String chairName;
  final String secretaryName;
  final int totalInvited;
  final int totalAttended;
  final bool isQuorumReached;
  final CpoMeetingStatus status;
  final String? overallSummary;
  final String? nextMeetingDate;
  final String? pdfPath;
  final String? createdAt;
  final String? updatedAt;
  final List<CpoAttendeeModel> attendees;
  final List<CpoAgendaModel> agendas;

  const CpoMeetingModel({
    this.id,
    required this.meetingNo,
    required this.meetingYear,
    required this.meetingTitle,
    required this.meetingDate,
    this.startTime = '09:00',
    this.endTime = '12:00',
    this.location = 'ห้องประชุมใหญ่',
    this.termId,
    required this.chairName,
    required this.secretaryName,
    this.totalInvited = 0,
    this.totalAttended = 0,
    this.isQuorumReached = true,
    this.status = CpoMeetingStatus.draft,
    this.overallSummary,
    this.nextMeetingDate,
    this.pdfPath,
    this.createdAt,
    this.updatedAt,
    this.attendees = const [],
    this.agendas = const [],
  });

  String get meetingCode => 'ครั้งที่ $meetingNo/$meetingYear';
  int get meetingNumber => meetingNo;
  String get chairmanName => chairName;

  CpoMeetingModel copyWith({
    int? id,
    int? meetingNo,
    String? meetingYear,
    String? meetingTitle,
    String? meetingDate,
    String? startTime,
    String? endTime,
    String? location,
    int? termId,
    String? chairName,
    String? secretaryName,
    int? totalInvited,
    int? totalAttended,
    bool? isQuorumReached,
    CpoMeetingStatus? status,
    String? overallSummary,
    String? nextMeetingDate,
    String? pdfPath,
    String? createdAt,
    String? updatedAt,
    List<CpoAttendeeModel>? attendees,
    List<CpoAgendaModel>? agendas,
  }) {
    return CpoMeetingModel(
      id: id ?? this.id,
      meetingNo: meetingNo ?? this.meetingNo,
      meetingYear: meetingYear ?? this.meetingYear,
      meetingTitle: meetingTitle ?? this.meetingTitle,
      meetingDate: meetingDate ?? this.meetingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      termId: termId ?? this.termId,
      chairName: chairName ?? this.chairName,
      secretaryName: secretaryName ?? this.secretaryName,
      totalInvited: totalInvited ?? this.totalInvited,
      totalAttended: totalAttended ?? this.totalAttended,
      isQuorumReached: isQuorumReached ?? this.isQuorumReached,
      status: status ?? this.status,
      overallSummary: overallSummary ?? this.overallSummary,
      nextMeetingDate: nextMeetingDate ?? this.nextMeetingDate,
      pdfPath: pdfPath ?? this.pdfPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attendees: attendees ?? this.attendees,
      agendas: agendas ?? this.agendas,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'meeting_no': meetingNo,
      'meeting_year': meetingYear,
      'meeting_title': meetingTitle,
      'meeting_date': meetingDate,
      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'term_id': termId,
      'chair_name': chairName,
      'secretary_name': secretaryName,
      'total_invited': totalInvited,
      'total_attended': totalAttended,
      'is_quorum_reached': isQuorumReached ? 1 : 0,
      'status': status.toDbCode(),
      'overall_summary': overallSummary,
      'next_meeting_date': nextMeetingDate,
      'pdf_path': pdfPath,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory CpoMeetingModel.fromMap(
    Map<String, dynamic> map, {
    List<CpoAttendeeModel> attendees = const [],
    List<CpoAgendaModel> agendas = const [],
  }) {
    return CpoMeetingModel(
      id: map['id'] as int?,
      meetingNo: (map['meeting_no'] as num?)?.toInt() ?? 1,
      meetingYear: map['meeting_year']?.toString() ?? '',
      meetingTitle: map['meeting_title']?.toString() ?? '',
      meetingDate: map['meeting_date']?.toString() ?? '',
      startTime: map['start_time']?.toString() ?? '09:00',
      endTime: map['end_time']?.toString() ?? '12:00',
      location: map['location']?.toString() ?? 'ห้องประชุมใหญ่',
      termId: (map['term_id'] as num?)?.toInt(),
      chairName: map['chair_name']?.toString() ?? '',
      secretaryName: map['secretary_name']?.toString() ?? '',
      totalInvited: (map['total_invited'] as num?)?.toInt() ?? 0,
      totalAttended: (map['total_attended'] as num?)?.toInt() ?? 0,
      isQuorumReached: (map['is_quorum_reached'] as num?)?.toInt() == 1,
      status: CpoMeetingStatus.fromDbCode(map['status']?.toString()),
      overallSummary: map['overall_summary']?.toString(),
      nextMeetingDate: map['next_meeting_date']?.toString(),
      pdfPath: map['pdf_path']?.toString(),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
      attendees: attendees,
      agendas: agendas,
    );
  }
}

class CpoAttendeeModel {
  final int? id;
  final int meetingId;
  final int? employeeId;
  final String attendeeName;
  final String roleLabel;
  final String? department;
  final bool isPresent;
  final String? absenceReason;
  final String? signaturePath;
  final String? createdAt;

  const CpoAttendeeModel({
    this.id,
    required this.meetingId,
    this.employeeId,
    required this.attendeeName,
    required this.roleLabel,
    this.department,
    this.isPresent = true,
    this.absenceReason,
    this.signaturePath,
    this.createdAt,
  });

  CpoAttendeeModel copyWith({
    int? id,
    int? meetingId,
    int? employeeId,
    String? attendeeName,
    String? roleLabel,
    String? department,
    bool? isPresent,
    String? absenceReason,
    String? signaturePath,
    String? createdAt,
  }) {
    return CpoAttendeeModel(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      employeeId: employeeId ?? this.employeeId,
      attendeeName: attendeeName ?? this.attendeeName,
      roleLabel: roleLabel ?? this.roleLabel,
      department: department ?? this.department,
      isPresent: isPresent ?? this.isPresent,
      absenceReason: absenceReason ?? this.absenceReason,
      signaturePath: signaturePath ?? this.signaturePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'meeting_id': meetingId,
      'employee_id': employeeId,
      'attendee_name': attendeeName,
      'role_label': roleLabel,
      'department': department,
      'is_present': isPresent ? 1 : 0,
      'absence_reason': absenceReason,
      'signature_path': signaturePath,
      'created_at': createdAt,
    };
  }

  factory CpoAttendeeModel.fromMap(Map<String, dynamic> map) {
    return CpoAttendeeModel(
      id: map['id'] as int?,
      meetingId: (map['meeting_id'] as num?)?.toInt() ?? 0,
      employeeId: (map['employee_id'] as num?)?.toInt(),
      attendeeName: map['attendee_name']?.toString() ?? '',
      roleLabel: map['role_label']?.toString() ?? '',
      department: map['department']?.toString(),
      isPresent: (map['is_present'] as num?)?.toInt() == 1,
      absenceReason: map['absence_reason']?.toString(),
      signaturePath: map['signature_path']?.toString(),
      createdAt: map['created_at']?.toString(),
    );
  }
}

class CpoAgendaModel {
  final int? id;
  final int meetingId;
  final int agendaNo; // 1 to 6
  final String agendaTitle;
  final String? discussionContent;
  final String? resolutionContent;
  final String? presenterName;
  final bool isApproved;
  final int sortOrder;
  final String? createdAt;

  const CpoAgendaModel({
    this.id,
    required this.meetingId,
    required this.agendaNo,
    required this.agendaTitle,
    this.discussionContent,
    this.resolutionContent,
    this.presenterName,
    this.isApproved = true,
    this.sortOrder = 0,
    this.createdAt,
  });

  int get agendaOrder => agendaNo;
  String get title => agendaTitle;

  CpoAgendaModel copyWith({
    int? id,
    int? meetingId,
    int? agendaNo,
    String? agendaTitle,
    String? discussionContent,
    String? resolutionContent,
    String? presenterName,
    bool? isApproved,
    int? sortOrder,
    String? createdAt,
  }) {
    return CpoAgendaModel(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      agendaNo: agendaNo ?? this.agendaNo,
      agendaTitle: agendaTitle ?? this.agendaTitle,
      discussionContent: discussionContent ?? this.discussionContent,
      resolutionContent: resolutionContent ?? this.resolutionContent,
      presenterName: presenterName ?? this.presenterName,
      isApproved: isApproved ?? this.isApproved,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'meeting_id': meetingId,
      'agenda_no': agendaNo,
      'agenda_title': agendaTitle,
      'discussion_content': discussionContent,
      'resolution_content': resolutionContent,
      'presenter_name': presenterName,
      'is_approved': isApproved ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt,
    };
  }

  factory CpoAgendaModel.fromMap(Map<String, dynamic> map) {
    return CpoAgendaModel(
      id: map['id'] as int?,
      meetingId: (map['meeting_id'] as num?)?.toInt() ?? 0,
      agendaNo: (map['agenda_no'] as num?)?.toInt() ?? 1,
      agendaTitle: map['agenda_title']?.toString() ?? '',
      discussionContent: map['discussion_content']?.toString(),
      resolutionContent: map['resolution_content']?.toString(),
      presenterName: map['presenter_name']?.toString(),
      isApproved: (map['is_approved'] as num?)?.toInt() != 0,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at']?.toString(),
    );
  }
}
