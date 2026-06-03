import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/dashboard/presentation/pages/area_manager_home_page.dart';
import 'package:sales_medical_app_mobile/features/dashboard/presentation/pages/sales_employee_home_page.dart';

/// Role-aware mobile home for the new dashboards (additive — does not replace
/// the existing Home tab yet).
class MobileDashboardLandingPage extends StatelessWidget {
  const MobileDashboardLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final role = (state.loginResponse?.user.role ?? '').toLowerCase();
        final fullName = state.loginResponse?.user.fullName ?? '';
        if (role == 'supervisor' || role == 'manager' || role == 'admin') {
          return AreaManagerHomePage(supervisorFullName: fullName);
        }
        return SalesEmployeeHomePage(repName: fullName);
      },
    );
  }
}
