import '../../domain/enums/cpo_election_status.dart';

class CpoElectionModel {
  final int? id;
  final String electionCode;
  final String electionTitle;
  final String termYear;
  final String? announcementDate;
  final String? nominationStartDate;
  final String? nominationEndDate;
  final String votingDate;
  final String votingStartTime;
  final String votingEndTime;
  final int eligibleVotersCount;
  final int totalBallotsCast;
  final int validBallotsCount;
  final int invalidBallotsCount;
  final int noVoteBallotsCount;
  final int requiredRepsCount;
  final CpoElectionStatus status;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  final List<CpoElectionOfficerModel> officers;
  final List<CpoCandidateModel> candidates;

  const CpoElectionModel({
    this.id,
    required this.electionCode,
    required this.electionTitle,
    required this.termYear,
    this.announcementDate,
    this.nominationStartDate,
    this.nominationEndDate,
    required this.votingDate,
    this.votingStartTime = '08:00',
    this.votingEndTime = '17:00',
    this.eligibleVotersCount = 0,
    this.totalBallotsCast = 0,
    this.validBallotsCount = 0,
    this.invalidBallotsCount = 0,
    this.noVoteBallotsCount = 0,
    this.requiredRepsCount = 2,
    this.status = CpoElectionStatus.draft,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.officers = const [],
    this.candidates = const [],
  });

  double get turnoutPercentage {
    if (eligibleVotersCount <= 0) return 0.0;
    return (totalBallotsCast / eligibleVotersCount) * 100.0;
  }

  CpoElectionModel copyWith({
    int? id,
    String? electionCode,
    String? electionTitle,
    String? termYear,
    String? announcementDate,
    String? nominationStartDate,
    String? nominationEndDate,
    String? votingDate,
    String? votingStartTime,
    String? votingEndTime,
    int? eligibleVotersCount,
    int? totalBallotsCast,
    int? validBallotsCount,
    int? invalidBallotsCount,
    int? noVoteBallotsCount,
    int? requiredRepsCount,
    CpoElectionStatus? status,
    String? notes,
    String? createdAt,
    String? updatedAt,
    List<CpoElectionOfficerModel>? officers,
    List<CpoCandidateModel>? candidates,
  }) {
    return CpoElectionModel(
      id: id ?? this.id,
      electionCode: electionCode ?? this.electionCode,
      electionTitle: electionTitle ?? this.electionTitle,
      termYear: termYear ?? this.termYear,
      announcementDate: announcementDate ?? this.announcementDate,
      nominationStartDate: nominationStartDate ?? this.nominationStartDate,
      nominationEndDate: nominationEndDate ?? this.nominationEndDate,
      votingDate: votingDate ?? this.votingDate,
      votingStartTime: votingStartTime ?? this.votingStartTime,
      votingEndTime: votingEndTime ?? this.votingEndTime,
      eligibleVotersCount: eligibleVotersCount ?? this.eligibleVotersCount,
      totalBallotsCast: totalBallotsCast ?? this.totalBallotsCast,
      validBallotsCount: validBallotsCount ?? this.validBallotsCount,
      invalidBallotsCount: invalidBallotsCount ?? this.invalidBallotsCount,
      noVoteBallotsCount: noVoteBallotsCount ?? this.noVoteBallotsCount,
      requiredRepsCount: requiredRepsCount ?? this.requiredRepsCount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      officers: officers ?? this.officers,
      candidates: candidates ?? this.candidates,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'election_code': electionCode,
      'election_title': electionTitle,
      'term_year': termYear,
      'announcement_date': announcementDate,
      'nomination_start_date': nominationStartDate,
      'nomination_end_date': nominationEndDate,
      'voting_date': votingDate,
      'voting_start_time': votingStartTime,
      'voting_end_time': votingEndTime,
      'eligible_voters_count': eligibleVotersCount,
      'total_ballots_cast': totalBallotsCast,
      'valid_ballots_count': validBallotsCount,
      'invalid_ballots_count': invalidBallotsCount,
      'no_vote_ballots_count': noVoteBallotsCount,
      'required_reps_count': requiredRepsCount,
      'status': status.toDbCode(),
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory CpoElectionModel.fromMap(
    Map<String, dynamic> map, {
    List<CpoElectionOfficerModel> officers = const [],
    List<CpoCandidateModel> candidates = const [],
  }) {
    return CpoElectionModel(
      id: map['id'] as int?,
      electionCode: map['election_code']?.toString() ?? '',
      electionTitle: map['election_title']?.toString() ?? '',
      termYear: map['term_year']?.toString() ?? '',
      announcementDate: map['announcement_date']?.toString(),
      nominationStartDate: map['nomination_start_date']?.toString(),
      nominationEndDate: map['nomination_end_date']?.toString(),
      votingDate: map['voting_date']?.toString() ?? '',
      votingStartTime: map['voting_start_time']?.toString() ?? '08:00',
      votingEndTime: map['voting_end_time']?.toString() ?? '17:00',
      eligibleVotersCount: (map['eligible_voters_count'] as num?)?.toInt() ?? 0,
      totalBallotsCast: (map['total_ballots_cast'] as num?)?.toInt() ?? 0,
      validBallotsCount: (map['valid_ballots_count'] as num?)?.toInt() ?? 0,
      invalidBallotsCount: (map['invalid_ballots_count'] as num?)?.toInt() ?? 0,
      noVoteBallotsCount: (map['no_vote_ballots_count'] as num?)?.toInt() ?? 0,
      requiredRepsCount: (map['required_reps_count'] as num?)?.toInt() ?? 2,
      status: CpoElectionStatus.fromDbCode(map['status']?.toString()),
      notes: map['notes']?.toString(),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
      officers: officers,
      candidates: candidates,
    );
  }
}

class CpoElectionOfficerModel {
  final int? id;
  final int electionId;
  final int? employeeId;
  final String officerName;
  final String? department;
  final String? positionTitle;
  final String officerRole; // CHAIR, SECRETARY, MEMBER
  final String? appointmentOrderNo;
  final String? createdAt;

  const CpoElectionOfficerModel({
    this.id,
    required this.electionId,
    this.employeeId,
    required this.officerName,
    this.department,
    this.positionTitle,
    this.officerRole = 'MEMBER',
    this.appointmentOrderNo,
    this.createdAt,
  });

  String get roleLabel {
    switch (officerRole) {
      case 'CHAIR':
        return 'ประธาน กกต.';
      case 'SECRETARY':
        return 'เลขานุการ กกต.';
      case 'MEMBER':
      default:
        return 'กรรมการ กกต.';
    }
  }

  String get officerRoleLabel => roleLabel;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'election_id': electionId,
      'employee_id': employeeId,
      'officer_name': officerName,
      'department': department,
      'position_title': positionTitle,
      'officer_role': officerRole,
      'appointment_order_no': appointmentOrderNo,
      'created_at': createdAt,
    };
  }

  factory CpoElectionOfficerModel.fromMap(Map<String, dynamic> map) {
    return CpoElectionOfficerModel(
      id: map['id'] as int?,
      electionId: (map['election_id'] as num?)?.toInt() ?? 0,
      employeeId: (map['employee_id'] as num?)?.toInt(),
      officerName: map['officer_name']?.toString() ?? '',
      department: map['department']?.toString(),
      positionTitle: map['position_title']?.toString(),
      officerRole: map['officer_role']?.toString() ?? 'MEMBER',
      appointmentOrderNo: map['appointment_order_no']?.toString(),
      createdAt: map['created_at']?.toString(),
    );
  }
}

class CpoCandidateModel {
  final int? id;
  final int electionId;
  final int candidateNo;
  final int? employeeId;
  final String fullName;
  final String? department;
  final String? positionTitle;
  final String? campaignPolicy;
  final int votesReceived;
  final int rankOrder;
  final bool isElected;
  final String status;
  final String? createdAt;

  const CpoCandidateModel({
    this.id,
    required this.electionId,
    required this.candidateNo,
    this.employeeId,
    required this.fullName,
    this.department,
    this.positionTitle,
    this.campaignPolicy,
    this.votesReceived = 0,
    this.rankOrder = 0,
    this.isElected = false,
    this.status = 'QUALIFIED',
    this.createdAt,
  });

  int get candidateNumber => candidateNo;
  String get candidateName => fullName;
  int get voteCount => votesReceived;

  CpoCandidateModel copyWith({
    int? id,
    int? electionId,
    int? candidateNo,
    int? employeeId,
    String? fullName,
    String? department,
    String? positionTitle,
    String? campaignPolicy,
    int? votesReceived,
    int? rankOrder,
    bool? isElected,
    String? status,
    String? createdAt,
  }) {
    return CpoCandidateModel(
      id: id ?? this.id,
      electionId: electionId ?? this.electionId,
      candidateNo: candidateNo ?? this.candidateNo,
      employeeId: employeeId ?? this.employeeId,
      fullName: fullName ?? this.fullName,
      department: department ?? this.department,
      positionTitle: positionTitle ?? this.positionTitle,
      campaignPolicy: campaignPolicy ?? this.campaignPolicy,
      votesReceived: votesReceived ?? this.votesReceived,
      rankOrder: rankOrder ?? this.rankOrder,
      isElected: isElected ?? this.isElected,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'election_id': electionId,
      'candidate_no': candidateNo,
      'employee_id': employeeId,
      'full_name': fullName,
      'department': department,
      'position_title': positionTitle,
      'campaign_policy': campaignPolicy,
      'votes_received': votesReceived,
      'rank_order': rankOrder,
      'is_elected': isElected ? 1 : 0,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory CpoCandidateModel.fromMap(Map<String, dynamic> map) {
    return CpoCandidateModel(
      id: map['id'] as int?,
      electionId: (map['election_id'] as num?)?.toInt() ?? 0,
      candidateNo: (map['candidate_no'] as num?)?.toInt() ?? 1,
      employeeId: (map['employee_id'] as num?)?.toInt(),
      fullName: map['full_name']?.toString() ?? '',
      department: map['department']?.toString(),
      positionTitle: map['position_title']?.toString(),
      campaignPolicy: map['campaign_policy']?.toString(),
      votesReceived: (map['votes_received'] as num?)?.toInt() ?? 0,
      rankOrder: (map['rank_order'] as num?)?.toInt() ?? 0,
      isElected: (map['is_elected'] as num?)?.toInt() == 1,
      status: map['status']?.toString() ?? 'QUALIFIED',
      createdAt: map['created_at']?.toString(),
    );
  }
}
