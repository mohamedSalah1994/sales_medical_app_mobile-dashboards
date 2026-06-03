import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/core/constants/customer_odbc_scope.dart';
import 'package:sales_medical_app_mobile/core/utils/odbc_card_type_label.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/entities/customer.dart';
import 'package:sales_medical_app_mobile/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:sales_medical_app_mobile/features/customers/presentation/pages/customer_detail_page.dart';
import 'package:sales_medical_app_mobile/features/customers/presentation/pages/customers_page.dart';

/// Customers tab content: list of customer cards and FAB to create a new customer.
class CustomersListPage extends StatefulWidget {
  const CustomersListPage({super.key, this.showScaffold = false});

  final bool showScaffold;

  @override
  State<CustomersListPage> createState() => _CustomersListPageState();
}

class _CustomersListPageState extends State<CustomersListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCustomers());
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _loadCustomers();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (!pos.hasViewportDimension || !pos.hasContentDimensions) return;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMoreCustomers();
    }
  }

  /// If the first page fits on screen, there is no scroll — load more until we can scroll or run out.
  void _maybeLoadMoreToFillViewport() {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;
    final cubit = context.read<CustomersCubit>();
    final state = cubit.state;
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final pos = _scrollController.position;
    if (!pos.hasViewportDimension || !pos.hasContentDimensions) return;
    if (pos.maxScrollExtent > 24) return;
    _loadMoreCustomers();
  }

  void _loadCustomers() {
    if (!mounted) return;
    final salesEmployeeCode =
        context.read<AuthCubit>().state.loginResponse?.user.sapSalesEmployeeCode;
    final search = _searchController.text.trim();
    context.read<CustomersCubit>().getCustomers(
          salesEmployeeCode: salesEmployeeCode,
          search: search.isEmpty ? null : search,
          pageNumber: 1,
          pageSize: _pageSize,
          append: false,
          scope: CustomerOdbcScope.all,
        );
  }

  void _loadMoreCustomers() {
    if (!mounted) return;
    final cubit = context.read<CustomersCubit>();
    final state = cubit.state;
    if (state.isLoadingMore || !state.hasMore) return;
    final salesEmployeeCode =
        context.read<AuthCubit>().state.loginResponse?.user.sapSalesEmployeeCode;
    final search = _searchController.text.trim();
    cubit.getCustomers(
      salesEmployeeCode: salesEmployeeCode,
      search: search.isEmpty ? null : search,
      pageNumber: state.currentPage + 1,
      pageSize: _pageSize,
      append: true,
      scope: CustomerOdbcScope.all,
    );
  }

  void _openCreateCustomer() async {
    // Read cubit from current context (has provider) before pushing new route
    final cubit = context.read<CustomersCubit>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: cubit,
          child: const CustomersPage(showScaffold: true),
        ),
      ),
    );
    if (mounted) _loadCustomers();
  }

  void _openCustomerDetail(Customer customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomerDetailPage(customer: customer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final content = BlocConsumer<CustomersCubit, CustomersState>(
      listenWhen: (p, c) =>
          p.customers.length != c.customers.length ||
          p.isLoadingMore != c.isLoadingMore ||
          p.hasMore != c.hasMore ||
          p.isLoading != c.isLoading,
      listener: (context, state) {
        if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _maybeLoadMoreToFillViewport();
        });
      },
      buildWhen: (p, c) =>
          p.customers != c.customers ||
          p.isLoading != c.isLoading ||
          p.isLoadingMore != c.isLoadingMore ||
          p.hasMore != c.hasMore ||
          p.currentPage != c.currentPage ||
          p.error != c.error,
      builder: (context, state) {
        if (state.isLoading && state.customers.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (state.error != null && state.customers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _loadCustomers,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.readyForDeliveryRetry),
                  ),
                ],
              ),
            ),
          );
        }
        if (state.customers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.trim().isEmpty
                        ? l10n.customersNoCustomersYet
                        : l10n.customersNoMatchSearch(_searchController.text),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.customersTapPlusToCreate,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final showLoadMore = state.hasMore || state.isLoadingMore;
        return RefreshIndicator(
          onRefresh: () async => _loadCustomers(),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: state.customers.length + (showLoadMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.customers.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: state.isLoadingMore
                        ? const SizedBox(
                            height: 32,
                            width: 32,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const SizedBox(height: 32),
                  ),
                );
              }
              final customer = state.customers[index];
              return _CustomerCard(
                customer: customer,
                onTap: () => _openCustomerDetail(customer),
              );
            },
          ),
        );
      },
    );

    final searchBar = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: l10n.customersSearchByNameOrCode,
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );

    if (!widget.showScaffold) {
      return Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            searchBar,
            Expanded(child: content),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreateCustomer,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(l10n.customersCreateCustomerTitle),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customersListTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchBar,
          Expanded(child: content),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateCustomer,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.customersCreateCustomerTitle),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.onTap,
  });

  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final displayName = customer.localizedName(lang);
    final secondaryName = customer.secondaryDisplayName(lang);
    final cardTypeLabel = odbcCardTypeKindLabel(customer.cardType);
    final isLead = customer.cardType.trim().toUpperCase() == 'L';
    final locationText = customer.locationDisplayText;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName.isNotEmpty
                              ? displayName
                              : '—',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        if (secondaryName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            secondaryName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          customer.customerCode,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (cardTypeLabel.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _CardTypeBadge(label: cardTypeLabel, isLead: isLead),
                  ],
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
              if (locationText != null ||
                  customer.city.isNotEmpty ||
                  customer.phone.isNotEmpty ||
                  customer.address.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                if (locationText != null)
                  _DetailRow(
                    icon: Icons.pin_drop_outlined,
                    label: locationText,
                  ),
                if (customer.city.isNotEmpty)
                  _DetailRow(
                    icon: Icons.location_city,
                    label: customer.city,
                  ),
                if (customer.phone.isNotEmpty)
                  _DetailRow(
                    icon: Icons.phone,
                    label: customer.phone,
                  ),
                if (customer.address.isNotEmpty)
                  _DetailRow(
                    icon: Icons.place,
                    label: customer.address,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CardTypeBadge extends StatelessWidget {
  const _CardTypeBadge({required this.label, required this.isLead});

  final String label;
  final bool isLead;

  @override
  Widget build(BuildContext context) {
    final color = isLead ? AppColors.warning : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
