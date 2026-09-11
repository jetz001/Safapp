import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/cpo_repository.dart';
import '../../data/models/cpo_committee_model.dart';
import '../../data/models/cpo_election_model.dart';
import '../../data/models/cpo_meeting_model.dart';
import '../../data/models/cpo_action_item_model.dart';
import '../../domain/services/cpo_statutory_evaluator.dart';
import '../../data/datasources/cpo_statutory_standards.dart';
import '../../../risk_assessment/presentation/providers/risk_assessment_providers.dart';
import '../../../risk_assessment/domain/models/risk_assessment_models.dart';
import '../../domain/enums/cpo_member_role.dart';

final cpoRepositoryProvider = Provider<CpoRepository>((ref) {
  return CpoRepository();
});

/// โหลดรายการวาระ คปอ. ทั้งหมด
final cpoAllTermsProvider = AsyncNotifierProvider<CpoAllTermsNotifier, List<CpoTermModel>>(
  CpoAllTermsNotifier.new,
);

class CpoAllTermsNotifier extends AsyncNotifier<List<CpoTermModel>> {
  @override
  Future<List<CpoTermModel>> build() async {
    final repo = ref.watch(cpoRepositoryProvider);
    return await repo.getAllTerms();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(cpoRepositoryProvider).getAllTerms());
  }

  Future<int> saveTerm(CpoTermModel term) async {
    final repo = ref.read(cpoRepositoryProvider);
    final id = await repo.saveTerm(term);
    await refresh();
    ref.read(cpoActiveTermProvider.notifier).refresh();
    return id;
  }

  Future<void> addMember(CpoMemberModel member) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.addMember(member);
    await refresh();
    ref.read(cpoActiveTermProvider.notifier).refresh();
  }

  Future<void> updateMember(CpoMemberModel member) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.updateMember(member);
    await refresh();
    ref.read(cpoActiveTermProvider.notifier).refresh();
  }

  Future<void> deleteMember(int memberId) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.deleteMember(memberId);
    await refresh();
    ref.read(cpoActiveTermProvider.notifier).refresh();
  }

  /// ค้นหาหรือสร้างวาระ คปอ. สำหรับรอบการเลือกตั้งนั้นๆ
  Future<CpoTermModel> findOrCreateTermForElection(CpoElectionModel election, {int employeeCount = 100}) async {
    final allTerms = state.asData?.value ?? await build();

    final match = allTerms.cast<CpoTermModel?>().firstWhere(
      (t) => t != null && (t.termCode == 'TERM-${election.termYear}' || t.termTitle.contains(election.termYear)),
      orElse: () => null,
    );

    if (match != null) {
      return match;
    }

    final yearInt = int.tryParse(election.termYear) ?? (DateTime.now().year + 543);
    final nextTwoYears = yearInt + 2;
    final quota = CpoStatutoryStandards.calculateQuota(employeeCount);

    final newTerm = CpoTermModel(
      termCode: 'TERM-${election.termYear}',
      termTitle: 'คณะกรรมการ คปอ. วาระปี $yearInt - $nextTwoYears',
      startDate: election.votingDate.isNotEmpty ? election.votingDate : DateTime.now().toIso8601String().substring(0, 10),
      endDate: '$nextTwoYears-12-31',
      employeeCount: employeeCount,
      requiredQuota: quota['total'] ?? 5,
      employerRepCount: quota['employer_rep'] ?? 2,
      employeeRepCount: quota['employee_rep'] ?? 2,
      secretaryCount: quota['secretary'] ?? 1,
      status: 'ACTIVE',
      notes: 'จัดตั้งสืบเนื่องจากรอบการเลือกตั้ง ${election.electionCode}',
    );

    final newId = await saveTerm(newTerm);
    await refresh();
    final updatedList = state.asData?.value ?? [];
    return updatedList.firstWhere((t) => t.id == newId, orElse: () => newTerm.copyWith(id: newId));
  }

  /// ดึง จป. จากข้อมูลองค์กร (CompanyProfile) มาตั้งเป็นเลขานุการ คปอ. อัตโนมัติ
  Future<void> autoAssignSecretaryFromProfile(int termId, CompanyProfile profile) async {
    if (profile.safetyOfficerName == null || profile.safetyOfficerName!.trim().isEmpty) return;

    final allTerms = state.asData?.value ?? await build();
    final term = allTerms.firstWhere(
      (t) => t.id == termId,
      orElse: () => const CpoTermModel(termCode: '', termTitle: '', startDate: '', endDate: ''),
    );

    final existingSec = term.members.where((m) => m.cpoRole == CpoMemberRole.secretary).toList();

    if (existingSec.isNotEmpty) {
      final first = existingSec.first;
      final updated = first.copyWith(
        fullName: profile.safetyOfficerName!.trim(),
        companyPosition: profile.safetyOfficerLevel ?? first.companyPosition,
        phone: profile.safetyOfficerPhone ?? first.phone,
      );
      await updateMember(updated);
    } else {
      final sec = CpoMemberModel(
        termId: termId,
        fullName: profile.safetyOfficerName!.trim(),
        companyPosition: profile.safetyOfficerLevel ?? 'จป.วิชาชีพ',
        phone: profile.safetyOfficerPhone,
        department: 'ความปลอดภัยและอาชีวอนามัย (EHS)',
        cpoRole: CpoMemberRole.secretary,
        appointmentType: 'EX_OFFICIO',
        status: 'ACTIVE',
      );
      await addMember(sec);
    }
  }
}

/// โหลดข้อมูลวาระ คปอ. ปัจจุบัน
final cpoActiveTermProvider = AsyncNotifierProvider<CpoActiveTermNotifier, CpoTermModel?>(
  CpoActiveTermNotifier.new,
);

class CpoActiveTermNotifier extends AsyncNotifier<CpoTermModel?> {
  @override
  Future<CpoTermModel?> build() async {
    final repo = ref.watch(cpoRepositoryProvider);
    return await repo.getActiveTerm();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(cpoRepositoryProvider).getActiveTerm());
  }

  Future<int> saveTerm(CpoTermModel term) async {
    final repo = ref.read(cpoRepositoryProvider);
    final id = await repo.saveTerm(term);
    await refresh();
    return id;
  }

  Future<void> addMember(CpoMemberModel member) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.addMember(member);
    await refresh();
  }

  Future<void> updateMember(CpoMemberModel member) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.updateMember(member);
    await refresh();
  }

  Future<void> deleteMember(int memberId) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.deleteMember(memberId);
    await refresh();
  }
}

/// รายการรอบการเลือกตั้ง กกต. ทั้งหมด
final cpoElectionsProvider = AsyncNotifierProvider<CpoElectionsNotifier, List<CpoElectionModel>>(
  CpoElectionsNotifier.new,
);

class CpoElectionsNotifier extends AsyncNotifier<List<CpoElectionModel>> {
  @override
  Future<List<CpoElectionModel>> build() async {
    final repo = ref.watch(cpoRepositoryProvider);
    return await repo.getAllElections();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(cpoRepositoryProvider).getAllElections());
  }

  Future<int> saveElection(CpoElectionModel election) async {
    final repo = ref.read(cpoRepositoryProvider);
    final id = await repo.saveElection(election);
    await refresh();
    return id;
  }

  Future<void> deleteElection(int electionId) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.deleteElection(electionId);
    await refresh();
  }

  Future<void> addOfficer(CpoElectionOfficerModel officer) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.addElectionOfficer(officer);
    await refresh();
  }

  Future<void> updateOfficer(CpoElectionOfficerModel officer) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.updateElectionOfficer(officer);
    await refresh();
  }

  Future<void> deleteOfficer(int officerId) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.deleteElectionOfficer(officerId);
    await refresh();
  }

  Future<void> addCandidate(CpoCandidateModel candidate) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.addCandidate(candidate);
    await refresh();
  }

  Future<void> updateCandidate(CpoCandidateModel candidate) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.updateCandidate(candidate);
    await refresh();
  }

  Future<void> deleteCandidate(int candidateId) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.deleteCandidate(candidateId);
    await refresh();
  }

  Future<void> tallyResults(int electionId, {int? requiredReps}) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.tallyElectionResults(electionId, requiredReps: requiredReps);
    await refresh();
  }
}

/// รายการการประชุม คปอ. ทั้งหมด
final cpoMeetingsProvider = AsyncNotifierProvider<CpoMeetingsNotifier, List<CpoMeetingModel>>(
  CpoMeetingsNotifier.new,
);

class CpoMeetingsNotifier extends AsyncNotifier<List<CpoMeetingModel>> {
  @override
  Future<List<CpoMeetingModel>> build() async {
    final repo = ref.watch(cpoRepositoryProvider);
    return await repo.getAllMeetings();
  }

  Future<void> refresh({bool showLoading = false}) async {
    if (showLoading) {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(() => ref.read(cpoRepositoryProvider).getAllMeetings());
  }

  Future<int> createMeetingWithStandardAgendas(CpoMeetingModel meeting, {List<CpoMemberModel>? termMembers}) async {
    final repo = ref.read(cpoRepositoryProvider);
    final id = await repo.createMeetingWithStandardAgendas(meeting, termMembers: termMembers);
    await refresh();
    return id;
  }

  Future<void> updateMeeting(CpoMeetingModel meeting) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.updateMeeting(meeting);
    await refresh();
  }

  Future<void> deleteMeeting(int meetingId) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.deleteMeeting(meetingId);
    await refresh();
  }

  Future<void> updateAgenda(CpoAgendaModel agenda) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.updateAgenda(agenda);
    
    final current = state.value;
    if (current != null) {
      final updatedList = current.map((m) {
        if (m.id == agenda.meetingId) {
          final updatedAgendas = m.agendas.map((ag) {
            return ag.id == agenda.id ? agenda : ag;
          }).toList();
          return m.copyWith(agendas: updatedAgendas);
        }
        return m;
      }).toList();
      state = AsyncData(updatedList);
    } else {
      await refresh();
    }
  }

  Future<void> addAgenda(CpoAgendaModel agenda) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.addAgenda(agenda);
    await refresh();
  }

  Future<void> deleteAgenda(int agendaId) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.deleteAgenda(agendaId);
    await refresh();
  }

  Future<void> saveAttendee(CpoAttendeeModel attendee) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.saveAttendee(attendee);
    
    final current = state.value;
    if (current != null) {
      final updatedList = current.map((m) {
        if (m.id == attendee.meetingId) {
          final updatedAttendees = m.attendees.map((a) {
            return a.id == attendee.id ? attendee : a;
          }).toList();
          return m.copyWith(attendees: updatedAttendees);
        }
        return m;
      }).toList();
      state = AsyncData(updatedList);
    } else {
      await refresh();
    }
  }
}

/// รายการติดตามมติที่ประชุม (Action Items)
final cpoActionItemsProvider = AsyncNotifierProvider<CpoActionItemsNotifier, List<CpoActionItemModel>>(
  CpoActionItemsNotifier.new,
);

class CpoActionItemsNotifier extends AsyncNotifier<List<CpoActionItemModel>> {
  @override
  Future<List<CpoActionItemModel>> build() async {
    final repo = ref.watch(cpoRepositoryProvider);
    return await repo.getAllActionItems();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(cpoRepositoryProvider).getAllActionItems());
  }

  Future<int> saveActionItem(CpoActionItemModel item) async {
    final repo = ref.read(cpoRepositoryProvider);
    final id = await repo.saveActionItem(item);
    await refresh();
    return id;
  }

  Future<void> updateStatus(int id, String status, {int progress = 0, String? notes, String? completedDate}) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.updateActionItemStatus(id, status, progress: progress, notes: notes, completedDate: completedDate);
    await refresh();
  }

  Future<void> deleteItem(int id) async {
    final repo = ref.read(cpoRepositoryProvider);
    await repo.deleteActionItem(id);
    await refresh();
  }
}

/// Provider คำนวณสรุปสถิติแดชบอร์ด & การประเมินเกณฑ์กฎหมาย คปอ.
final cpoDashboardSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(cpoRepositoryProvider);
  final activeTerm = await ref.watch(cpoActiveTermProvider.future);
  final meetings = await ref.watch(cpoMeetingsProvider.future);
  final actions = await ref.watch(cpoActionItemsProvider.future);
  final companyProfile = ref.watch(companyProfileNotifierProvider).asData?.value;

  final employeeCount = activeTerm?.employeeCount ?? companyProfile?.employeeCount ?? 0;
  final members = activeTerm?.members ?? [];

  final complianceResult = CpoStatutoryEvaluator.evaluateQuota(
    employeeCount: employeeCount,
    members: members,
  );

  final frequencyResult = CpoStatutoryEvaluator.evaluateMeetingFrequency(
    meetingsInYear: meetings,
  );

  final totalActions = actions.length;
  final completedActions = actions.where((a) => a.status.name == 'completed').length;
  final pendingActions = actions.where((a) => a.status.name == 'pending').length;
  final inProgressActions = actions.where((a) => a.status.name == 'inProgress').length;
  final overdueActions = actions.where((a) => a.isOverdue).length;
  final completionRate = totalActions > 0 ? (completedActions / totalActions) * 100.0 : 0.0;

  final monthlySafetyStats = await repo.fetchMonthlySafetyStats(DateTime.now().toIso8601String());

  return {
    'active_term': activeTerm,
    'compliance_result': complianceResult,
    'frequency_result': frequencyResult,
    'total_actions': totalActions,
    'completed_actions': completedActions,
    'pending_actions': pendingActions,
    'in_progress_actions': inProgressActions,
    'overdue_actions': overdueActions,
    'completion_rate': completionRate,
    'monthly_safety_stats': monthlySafetyStats,
  };
});
