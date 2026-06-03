import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';

/// After an ERP document is created with [visitId] on the request (sales order,
/// delivery, return), reloads the current journey plan so stop cards show updated
/// [Visit.actions].
///
/// Does **not** call `POST /api/Visits/{visitId}/actions`: the backend already
/// attaches the action from the ERP payload. Calling that endpoint as well would
/// duplicate the action.
Future<void> registerVisitActionIfInJourneyContext(
  BuildContext context, {
  required String visitId,
}) async {
  final trimmedVisit = visitId.trim();
  if (trimmedVisit.isEmpty) return;

  JourneyPlanCubit journeyCubit;
  try {
    journeyCubit = context.read<JourneyPlanCubit>();
  } catch (_) {
    return;
  }

  AuthCubit? authCubit;
  try {
    authCubit = context.read<AuthCubit>();
  } catch (_) {}

  if (journeyCubit.state.journeyPlan != null) {
    try {
      await journeyCubit.refreshJourneyPlanFromServer();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('registerVisitActionIfInJourneyContext refresh: $e\n$st');
      }
    }
  }

  // Standalone list uses [JourneyPlanState.visits] with `standaloneOnly: true`; refresh it
  // so new ERP actions appear without a manual pull-to-refresh.
  final uid = authCubit?.state.loginResponse?.user.id;
  if (uid != null && journeyCubit.state.lastVisitsLoadWasStandaloneOnly) {
    await journeyCubit.refreshStandaloneVisitsListUsingStoredTab(uid);
  }
}
