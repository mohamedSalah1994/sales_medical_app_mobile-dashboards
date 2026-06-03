import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/widgets/app_logo.dart';
import 'package:sales_medical_app_mobile/core/widgets/app_version_label.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';

class MobileDrawer extends StatelessWidget {
  const MobileDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          _DrawerHeader(),
          const Divider(height: 1),
          // Menu Items
          Expanded(
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                final l10n = AppLocalizations.of(context)!;
                final role =
                    authState.loginResponse?.user.role.toLowerCase() ?? '';
                final isSalesRep = role == 'salesrep';
                final isSupervisor = role == 'supervisor';

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    _DrawerMenuItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      title: l10n.home,
                      index: 0,
                      selectedIndex: selectedIndex,
                      onTap: () {
                        onItemTapped(0);
                      },
                    ),
                    _DrawerMenuItem(
                      icon: Icons.route_outlined,
                      activeIcon: Icons.route,
                      title: l10n.journeyPlan,
                      index: 2,
                      selectedIndex: selectedIndex,
                      onTap: () {
                        onItemTapped(2);
                      },
                    ),
                    _DrawerMenuItem(
                      icon: Icons.track_changes_outlined,
                      activeIcon: Icons.track_changes,
                      title: l10n.targets,
                      index: 3,
                      selectedIndex: selectedIndex,
                      onTap: () {
                        onItemTapped(3);
                      },
                    ),
                    _DrawerMenuItem(
                      icon: Icons.person_pin_circle_outlined,
                      activeIcon: Icons.person_pin_circle,
                      title: l10n.standaloneVisit,
                      index: 4,
                      selectedIndex: selectedIndex,
                      onTap: () {
                        onItemTapped(4);
                      },
                    ),
                    if (isSupervisor)
                      _DrawerMenuItem(
                        icon: Icons.map_outlined,
                        activeIcon: Icons.map,
                        title: l10n.teamMapTitle,
                        index: 11,
                        selectedIndex: selectedIndex,
                        onTap: () {
                          onItemTapped(11);
                        },
                      ),
                    if (isSalesRep)
                      _DrawerMenuItem(
                        icon: Icons.business_outlined,
                        activeIcon: Icons.business,
                        title: l10n.customers,
                        index: 5,
                        selectedIndex: selectedIndex,
                        onTap: () {
                          onItemTapped(5);
                        },
                      ),
                    _DrawerMenuItem(
                      icon: Icons.shopping_cart_outlined,
                      activeIcon: Icons.shopping_cart,
                      title: l10n.salesOrder,
                      index: 6,
                      selectedIndex: selectedIndex,
                      onTap: () {
                        onItemTapped(6);
                      },
                    ),
                    _DrawerMenuItem(
                      icon: Icons.local_shipping_outlined,
                      activeIcon: Icons.local_shipping,
                      title: l10n.deliveries,
                      index: 7,
                      selectedIndex: selectedIndex,
                      onTap: () {
                        onItemTapped(7);
                      },
                    ),
                    _DrawerMenuItem(
                      icon: Icons.assignment_return_outlined,
                      activeIcon: Icons.assignment_return,
                      title: l10n.returns,
                      index: 8,
                      selectedIndex: selectedIndex,
                      onTap: () {
                        onItemTapped(8);
                      },
                    ),
                    _DrawerMenuItem(
                      icon: Icons.payments_outlined,
                      activeIcon: Icons.payments,
                      title: 'Incoming payment',
                      index: 12,
                      selectedIndex: selectedIndex,
                      onTap: () {
                        onItemTapped(12);
                      },
                    ),
                    _DrawerMenuItem(
                      icon: Icons.inventory_2_outlined,
                      activeIcon: Icons.inventory_2,
                      title: l10n.inventory,
                      index: 9,
                      selectedIndex: selectedIndex,
                      onTap: () {
                        onItemTapped(9);
                      },
                    ),
                    _DrawerMenuItem(
                      icon: Icons.fact_check_outlined,
                      activeIcon: Icons.fact_check,
                      title: l10n.inventoryCounting,
                      index: 10,
                      selectedIndex: selectedIndex,
                      onTap: () {
                        onItemTapped(10);
                      },
                    ),
                    _DrawerMenuItem(
                      icon: Icons.leaderboard_outlined,
                      activeIcon: Icons.leaderboard,
                      title: 'Dashboard',
                      index: 14,
                      selectedIndex: selectedIndex,
                      onTap: () {
                        onItemTapped(14);
                      },
                    ),
                    _DrawerMenuItem(
                      icon: Icons.assessment_outlined,
                      activeIcon: Icons.assessment,
                      title: 'Reports',
                      index: 13,
                      selectedIndex: selectedIndex,
                      onTap: () {
                        onItemTapped(13);
                      },
                    ),
                    _DrawerMenuItem(
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings,
                      title: l10n.settings,
                      index: 1,
                      selectedIndex: selectedIndex,
                      onTap: () {
                        onItemTapped(1);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          // Footer
          const Divider(height: 1),
          _DrawerFooter(),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const AppLogo(
              height: 44,
              width: 44,
              fallbackIconColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DKT Sales APP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String title;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;

    return ListTile(
      leading: Icon(
        isSelected ? activeIcon : icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      onTap: onTap,
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState.loginResponse?.user;
        final fullName = user?.fullName ?? 'Admin User';
        final email = user?.email ?? 'admin@dkt.com';

        return SafeArea(
          top: false,
          child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await context.read<AuthCubit>().logout();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed('/login');
                        }
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: Text(l10n.logout),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              const AppVersionLabel(),
            ],
          ),
          ),
        );
      },
    );
  }
}
