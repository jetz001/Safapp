import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/high_risk_type.dart';
import '../../domain/enums/ptw_status.dart';

/// Immutable Filter State for Permit to Work Search & Filtering
class PtwFilterState {
  final String searchQuery;
  final HighRiskType? riskType;
  final PtwStatus? status;
  final String? department;
  final String? startDate; // YYYY-MM-DD
  final String? endDate; // YYYY-MM-DD

  const PtwFilterState({
    this.searchQuery = '',
    this.riskType,
    this.status,
    this.department,
    this.startDate,
    this.endDate,
  });

  /// Check if any active filter criteria is applied
  bool get isFiltered =>
      searchQuery.trim().isNotEmpty ||
      riskType != null ||
      status != null ||
      (department != null && department!.trim().isNotEmpty && department != 'ALL') ||
      (startDate != null && startDate!.isNotEmpty) ||
      (endDate != null && endDate!.isNotEmpty);

  PtwFilterState copyWith({
    String? searchQuery,
    HighRiskType? riskType,
    bool clearRiskType = false,
    PtwStatus? status,
    bool clearStatus = false,
    String? department,
    bool clearDepartment = false,
    String? startDate,
    bool clearStartDate = false,
    String? endDate,
    bool clearEndDate = false,
  }) {
    return PtwFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      riskType: clearRiskType ? null : (riskType ?? this.riskType),
      status: clearStatus ? null : (status ?? this.status),
      department: clearDepartment ? null : (department ?? this.department),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  factory PtwFilterState.initial() => const PtwFilterState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PtwFilterState &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          riskType == other.riskType &&
          status == other.status &&
          department == other.department &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      searchQuery.hashCode ^
      riskType.hashCode ^
      status.hashCode ^
      department.hashCode ^
      startDate.hashCode ^
      endDate.hashCode;

  @override
  String toString() =>
      'PtwFilterState(query: "$searchQuery", risk: ${riskType?.toDbCode()}, status: ${status?.toDbCode()}, dept: $department, date: $startDate to $endDate)';
}

/// Riverpod 3 State Notifier for PTW Filtering
class PtwFilterNotifier extends Notifier<PtwFilterState> {
  @override
  PtwFilterState build() => const PtwFilterState();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setRiskType(HighRiskType? riskType) {
    if (riskType == null) {
      state = state.copyWith(clearRiskType: true);
    } else {
      state = state.copyWith(riskType: riskType);
    }
  }

  void setStatus(PtwStatus? status) {
    if (status == null) {
      state = state.copyWith(clearStatus: true);
    } else {
      state = state.copyWith(status: status);
    }
  }

  void setDepartment(String? department) {
    if (department == null || department == 'ALL' || department.trim().isEmpty) {
      state = state.copyWith(clearDepartment: true);
    } else {
      state = state.copyWith(department: department.trim());
    }
  }

  void setDateRange(String? startDate, String? endDate) {
    state = state.copyWith(
      startDate: startDate,
      clearStartDate: startDate == null || startDate.isEmpty,
      endDate: endDate,
      clearEndDate: endDate == null || endDate.isEmpty,
    );
  }

  void reset() {
    state = const PtwFilterState();
  }
}

/// Riverpod Provider for PTW Filter State
final ptwFilterProvider = NotifierProvider<PtwFilterNotifier, PtwFilterState>(
  PtwFilterNotifier.new,
);
