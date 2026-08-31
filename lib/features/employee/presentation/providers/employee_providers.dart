import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/employee_repository.dart';
import '../../domain/models/employee_models.dart';

final employeeRepoProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository();
});

// --------------------------------------------------------------------------
// 1. Employees Notifier
// --------------------------------------------------------------------------
class EmployeesNotifier extends AsyncNotifier<List<Employee>> {
  @override
  Future<List<Employee>> build() async {
    final repo = ref.watch(employeeRepoProvider);
    return await repo.getAllEmployees();
  }

  Future<int> saveEmployee(Employee employee, {String? newPhotoPath}) async {
    final repo = ref.read(employeeRepoProvider);
    String? finalPhoto = employee.photoPath;
    if (newPhotoPath != null) {
      finalPhoto = await repo.persistFile(newPhotoPath, prefix: 'emp_photo');
    }
    final toSave = employee.copyWith(photoPath: finalPhoto);
    final id = await repo.saveEmployee(toSave);
    ref.invalidateSelf();
    return id;
  }

  Future<void> deleteEmployee(int id) async {
    final repo = ref.read(employeeRepoProvider);
    await repo.deleteEmployee(id);
    ref.invalidateSelf();
    ref.invalidate(trainingRecordsProvider);
    ref.invalidate(safetyCommitteeProvider);
  }
}

final employeesProvider =
    AsyncNotifierProvider<EmployeesNotifier, List<Employee>>(EmployeesNotifier.new);

// --------------------------------------------------------------------------
// 2. Training Courses Notifier
// --------------------------------------------------------------------------
class TrainingCoursesNotifier extends AsyncNotifier<List<TrainingCourse>> {
  @override
  Future<List<TrainingCourse>> build() async {
    final repo = ref.watch(employeeRepoProvider);
    return await repo.getAllCourses();
  }

  Future<int> saveCourse(TrainingCourse course) async {
    final repo = ref.read(employeeRepoProvider);
    final id = await repo.saveCourse(course);
    ref.invalidateSelf();
    return id;
  }
}

final trainingCoursesProvider =
    AsyncNotifierProvider<TrainingCoursesNotifier, List<TrainingCourse>>(TrainingCoursesNotifier.new);

// --------------------------------------------------------------------------
// 3. Training Records Notifier
// --------------------------------------------------------------------------
class TrainingRecordsNotifier extends AsyncNotifier<List<TrainingRecord>> {
  @override
  Future<List<TrainingRecord>> build() async {
    final repo = ref.watch(employeeRepoProvider);
    return await repo.getAllTrainingRecords();
  }

  Future<int> saveRecord(TrainingRecord record, {String? newCertPath}) async {
    final repo = ref.read(employeeRepoProvider);
    String? finalCert = record.certFilePath;
    if (newCertPath != null) {
      finalCert = await repo.persistFile(newCertPath, prefix: 'emp_cert');
    }
    final toSave = record.copyWith(certFilePath: finalCert);
    final id = await repo.saveTrainingRecord(toSave);
    ref.invalidateSelf();
    ref.invalidate(employeesProvider);
    return id;
  }

  Future<void> deleteRecord(int id) async {
    final repo = ref.read(employeeRepoProvider);
    await repo.deleteTrainingRecord(id);
    ref.invalidateSelf();
    ref.invalidate(employeesProvider);
  }
}

final trainingRecordsProvider =
    AsyncNotifierProvider<TrainingRecordsNotifier, List<TrainingRecord>>(TrainingRecordsNotifier.new);

// --------------------------------------------------------------------------
// 4. Safety Committee Notifier
// --------------------------------------------------------------------------
class SafetyCommitteeNotifier extends AsyncNotifier<List<SafetyCommitteeMember>> {
  @override
  Future<List<SafetyCommitteeMember>> build() async {
    final repo = ref.watch(employeeRepoProvider);
    return await repo.getAllCommitteeMembers();
  }

  Future<int> saveMember(SafetyCommitteeMember member) async {
    final repo = ref.read(employeeRepoProvider);
    final id = await repo.saveCommitteeMember(member);
    ref.invalidateSelf();
    return id;
  }

  Future<void> deleteMember(int id) async {
    final repo = ref.read(employeeRepoProvider);
    await repo.deleteCommitteeMember(id);
    ref.invalidateSelf();
  }
}

final safetyCommitteeProvider =
    AsyncNotifierProvider<SafetyCommitteeNotifier, List<SafetyCommitteeMember>>(SafetyCommitteeNotifier.new);
