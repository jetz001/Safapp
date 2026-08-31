import '../../../../core/database/database_helper.dart';
import '../../domain/models/risk_assessment_models.dart';

class RiskAssessmentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ----------------------------------------------------
  // COMPANY PROFILE
  // ----------------------------------------------------
  Future<CompanyProfile?> getCompanyProfile() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'company_profiles',
      limit: 1,
      orderBy: 'id DESC',
    );
    if (maps.isEmpty) return null;
    return CompanyProfile.fromMap(maps.first);
  }

  Future<int> saveCompanyProfile(CompanyProfile profile) async {
    final db = await _dbHelper.database;
    final map = profile.toMap();
    if (profile.id != null) {
      await db.update('company_profiles', map, where: 'id = ?', whereArgs: [profile.id]);
      return profile.id!;
    } else {
      final existing = await getCompanyProfile();
      if (existing != null && existing.id != null) {
        await db.update('company_profiles', map, where: 'id = ?', whereArgs: [existing.id]);
        return existing.id!;
      }
      return await db.insert('company_profiles', map);
    }
  }

  // ----------------------------------------------------
  // SESSIONS
  // ----------------------------------------------------
  Future<List<RiskAssessmentSession>> getAllSessions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'risk_assessment_sessions',
      orderBy: 'assessment_date DESC, id DESC',
    );
    return maps.map((m) => RiskAssessmentSession.fromMap(m)).toList();
  }

  Future<RiskAssessmentSession?> getSessionById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'risk_assessment_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return RiskAssessmentSession.fromMap(maps.first);
  }

  Future<int> saveSession(RiskAssessmentSession session) async {
    final db = await _dbHelper.database;
    final map = session.toMap();
    if (session.id != null) {
      map['updated_at'] = DateTime.now().toIso8601String();
      await db.update('risk_assessment_sessions', map, where: 'id = ?', whereArgs: [session.id]);
      return session.id!;
    } else {
      map['created_at'] = DateTime.now().toIso8601String();
      map['updated_at'] = DateTime.now().toIso8601String();
      return await db.insert('risk_assessment_sessions', map);
    }
  }

  Future<void> deleteSession(int id) async {
    final db = await _dbHelper.database;
    await db.delete('risk_assessment_sessions', where: 'id = ?', whereArgs: [id]);
  }

  // ----------------------------------------------------
  // WORKSTATIONS
  // ----------------------------------------------------
  Future<List<WorkStation>> getWorkstationsBySession(int sessionId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'work_stations',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'sort_order ASC, id ASC',
    );
    return maps.map((m) => WorkStation.fromMap(m)).toList();
  }

  Future<int> saveWorkstation(WorkStation station) async {
    final db = await _dbHelper.database;
    final map = station.toMap();
    if (station.id != null) {
      await db.update('work_stations', map, where: 'id = ?', whereArgs: [station.id]);
      return station.id!;
    } else {
      return await db.insert('work_stations', map);
    }
  }

  Future<void> deleteWorkstation(int id) async {
    final db = await _dbHelper.database;
    await db.delete('work_stations', where: 'id = ?', whereArgs: [id]);
  }

  // ----------------------------------------------------
  // WORK STEPS & MACHINERY
  // ----------------------------------------------------
  Future<List<WorkStepItem>> getStepsByWorkstation(int workstationId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'work_step_items',
      where: 'workstation_id = ?',
      whereArgs: [workstationId],
      orderBy: 'step_number ASC, sort_order ASC, id ASC',
    );
    return maps.map((m) => WorkStepItem.fromMap(m)).toList();
  }

  Future<int> saveWorkStep(WorkStepItem step) async {
    final db = await _dbHelper.database;
    final map = step.toMap();
    if (step.id != null) {
      await db.update('work_step_items', map, where: 'id = ?', whereArgs: [step.id]);
      return step.id!;
    } else {
      return await db.insert('work_step_items', map);
    }
  }

  Future<void> deleteWorkStep(int id) async {
    final db = await _dbHelper.database;
    await db.delete('work_step_items', where: 'id = ?', whereArgs: [id]);
  }

  // ----------------------------------------------------
  // HAZARD EVALUATIONS (ปอ. ๑)
  // ----------------------------------------------------
  Future<List<HazardEvaluationPor1>> getHazardsByStep(int stepId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'hazard_evaluations_por1',
      where: 'step_id = ?',
      whereArgs: [stepId],
      orderBy: 'id ASC',
    );
    return maps.map((m) => HazardEvaluationPor1.fromMap(m)).toList();
  }

  Future<int> saveHazardPor1(HazardEvaluationPor1 hazard) async {
    final db = await _dbHelper.database;
    final map = hazard.toMap();
    if (hazard.id != null) {
      await db.update('hazard_evaluations_por1', map, where: 'id = ?', whereArgs: [hazard.id]);
      return hazard.id!;
    } else {
      return await db.insert('hazard_evaluations_por1', map);
    }
  }

  Future<void> deleteHazardPor1(int id) async {
    final db = await _dbHelper.database;
    await db.delete('hazard_evaluations_por1', where: 'id = ?', whereArgs: [id]);
  }

  // ----------------------------------------------------
  // RISK CONTROL PLANS (ปอ. ๒) & ACTION TRACKER SYNC
  // ----------------------------------------------------
  Future<RiskControlPlanPor2?> getPlanByHazard(int hazardId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'risk_control_plans_por2',
      where: 'hazard_id = ?',
      whereArgs: [hazardId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RiskControlPlanPor2.fromMap(maps.first);
  }

  Future<int> savePlanPor2(RiskControlPlanPor2 plan, {String? hazardTitle}) async {
    final db = await _dbHelper.database;
    final map = plan.toMap();

    // 1. Sync / Create Action Tracker item
    int? actionId = plan.actionTrackerId;
    if (actionId == null && plan.controlPlanDescription.isNotEmpty) {
      actionId = await db.insert('action_trackers', {
        'source_module': 'RISK_POR2',
        'source_id': plan.hazardId,
        'action_description': '[ปอ.๒] ${plan.controlPlanDescription} (${hazardTitle ?? ''})',
        'responsible_person': plan.responsiblePerson,
        'due_date': plan.endDate ?? DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10),
        'status': plan.status == 'COMPLETED' ? 'DONE' : 'OPEN',
      });
      map['action_tracker_id'] = actionId;
    } else if (actionId != null) {
      await db.update(
        'action_trackers',
        {
          'action_description': '[ปอ.๒] ${plan.controlPlanDescription} (${hazardTitle ?? ''})',
          'responsible_person': plan.responsiblePerson,
          'due_date': plan.endDate ?? '',
          'status': plan.status == 'COMPLETED' ? 'DONE' : 'OPEN',
        },
        where: 'id = ?',
        whereArgs: [actionId],
      );
    }

    if (plan.id != null) {
      await db.update('risk_control_plans_por2', map, where: 'id = ?', whereArgs: [plan.id]);
      return plan.id!;
    } else {
      return await db.insert('risk_control_plans_por2', map);
    }
  }

  Future<void> deletePlanPor2(int id) async {
    final db = await _dbHelper.database;
    await db.delete('risk_control_plans_por2', where: 'id = ?', whereArgs: [id]);
  }

  // ----------------------------------------------------
  // FULL POR 1 & POR 2 AGGREGATED REPORT ROWS
  // ----------------------------------------------------
  Future<List<PorReportRowData>> getPorReportRows(int sessionId) async {
    final List<PorReportRowData> results = [];

    final stations = await getWorkstationsBySession(sessionId);
    for (final station in stations) {
      final steps = await getStepsByWorkstation(station.id!);
      for (final step in steps) {
        final hazards = await getHazardsByStep(step.id!);
        for (final hazard in hazards) {
          final plan = await getPlanByHazard(hazard.id!);
          results.add(
            PorReportRowData(
              workstation: station,
              stepItem: step,
              hazard: hazard,
              plan: plan,
            ),
          );
        }
      }
    }

    return results;
  }
}
