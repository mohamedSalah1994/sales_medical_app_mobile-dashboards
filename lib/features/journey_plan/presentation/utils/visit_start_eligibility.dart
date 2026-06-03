import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/journey_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_state.dart';

bool visitPlannedDateIsToday(DateTime planned) {
  final now = DateTime.now();
  return planned.year == now.year &&
      planned.month == now.month &&
      planned.day == now.day;
}

/// Calendar day [instant] inclusive within [plan] start/end (date-only).
bool isDateWithinJourneyPlanPeriod(DateTime instant, JourneyPlan plan) {
  final d = DateTime(instant.year, instant.month, instant.day);
  final s = DateTime(
    plan.startDate.year,
    plan.startDate.month,
    plan.startDate.day,
  );
  final e = DateTime(
    plan.endDate.year,
    plan.endDate.month,
    plan.endDate.day,
  );
  return !d.isBefore(s) && !d.isAfter(e);
}

bool isVisitOnJourneyPlan(Visit visit, JourneyPlan plan) {
  final jid = visit.journeyPlanId?.trim();
  if (jid != null && jid.isNotEmpty) {
    return jid == plan.id;
  }
  for (final s in plan.stops) {
    if (s.visitId == visit.id) return true;
    final v = s.visit;
    if (v != null && v.id == visit.id) return true;
  }
  return false;
}

/// Journey: allow **Start visit** any day the plan runs, not only on the stop's planned day.
/// Else: only on the visit's planned calendar day.
bool showStartVisitButton(JourneyPlanState state, Visit visit) {
  final plan = state.journeyPlan;
  if (plan != null &&
      isVisitOnJourneyPlan(visit, plan) &&
      isDateWithinJourneyPlanPeriod(DateTime.now(), plan)) {
    return true;
  }
  return visitPlannedDateIsToday(visit.plannedDateTime);
}
