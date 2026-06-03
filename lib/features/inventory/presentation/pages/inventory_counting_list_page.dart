import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/utils/format_date.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/inventory_exceptions.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_counting_models.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/cubit/inventory_state.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/pages/inventory_counting_page.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/widgets/inventory_counting_document_header.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/widgets/inventory_counting_readonly_panel.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/widgets/erp_document_header_widgets.dart';

class InventoryCountingListPage extends StatefulWidget {
  const InventoryCountingListPage({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  State<InventoryCountingListPage> createState() =>
      _InventoryCountingListPageState();
}

class _InventoryCountingListPageState extends State<InventoryCountingListPage> {
  final _docEntryController = TextEditingController();
  bool _isSearching = false;
  String? _searchError;
  InventoryCountingDocModel? _searchResult;
  bool _listFetched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadCountings();
    });
  }

  @override
  void dispose() {
    _docEntryController.dispose();
    super.dispose();
  }

  Future<String?> _resolveDefaultWarehouseCode() async {
    final code =
        context
            .read<AuthCubit>()
            .state
            .loginResponse
            ?.user
            .defaultWarehouseCode
            ?.trim();
    if (code != null && code.isNotEmpty) return code;
    return sl<AuthRepository>().getStoredDefaultWarehouseCode();
  }

  Future<void> _loadCountings() async {
    _listFetched = true;
    final wh = await _resolveDefaultWarehouseCode();
    if (!mounted) return;
    await context.read<InventoryCubit>().loadCountings(
      warehouseCode: wh,
      skip: 0,
      take: 20,
    );
  }

  Future<void> _onSearchByDocEntry() async {
    final l10n = AppLocalizations.of(context)!;
    final raw = _docEntryController.text.trim();
    final docEntry = int.tryParse(raw);
    if (docEntry == null) {
      setState(() {
        _searchError = 'Enter a valid Doc Entry (number)';
        _searchResult = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResult = null;
    });

    try {
      final doc = await context.read<InventoryCubit>().getCountingByDocEntry(
        docEntry,
      );
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchResult = doc;
        _searchError = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is InventoryDocumentNotFoundException) {
        setState(() {
          _isSearching = false;
          _searchResult = null;
          _searchError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.inventoryDocNotFound),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      setState(() {
        _isSearching = false;
        _searchResult = null;
        _searchError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _openCreate() {
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder:
                (_) => BlocProvider.value(
                  value: context.read<InventoryCubit>(),
                  child: const InventoryCountingPage.create(),
                ),
          ),
        )
        .then((_) {
          if (!mounted) return;
          context.read<InventoryCubit>().loadWarehouses();
          _loadCountings();
        });
  }

  void _openCountingCard(InventoryCountingDocModel doc) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder:
            (_) => BlocProvider.value(
              value: context.read<InventoryCubit>(),
              child: InventoryCountingPage.viewExisting(
                docEntry: doc.documentEntry,
                prefetched: doc,
              ),
            ),
      ),
    );
  }

  Widget _buildSearchRow(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _docEntryController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: l10n.inventorySearchByDocEntry,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _onSearchByDocEntry(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Search',
                onPressed: _isSearching ? null : _onSearchByDocEntry,
                icon:
                    _isSearching
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.search),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (_searchError != null) ...[
            const SizedBox(height: 6),
            Text(
              _searchError!,
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListSection(AppLocalizations l10n) {
    return BlocBuilder<InventoryCubit, InventoryState>(
      buildWhen:
          (prev, curr) =>
              prev.countings != curr.countings ||
              prev.isLoadingCountings != curr.isLoadingCountings ||
              prev.countingsError != curr.countingsError,
      builder: (context, state) {
        if (state.isLoadingCountings && state.countings.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.countingsError != null && state.countings.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.countingsError!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _loadCountings,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                  ),
                ),
              ],
            ),
          );
        }
        if (state.countings.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fact_check_outlined,
                  size: 48,
                  color: AppColors.textSecondary.withValues(alpha: 0.45),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.inventoryCountingListHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          child: Column(
            children: [
              for (final doc in state.countings)
                _InventoryCountingCard(
                  doc: doc,
                  onTap: () => _openCountingCard(doc),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AuthCubit, AuthState>(
      listenWhen:
          (prev, curr) =>
              prev.loginResponse?.user.defaultWarehouseCode !=
              curr.loginResponse?.user.defaultWarehouseCode,
      listener: (_, _) {
        if (mounted && _listFetched) _loadCountings();
      },
      child: Builder(
        builder: (context) {
          final listBody = CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildSearchRow(l10n)),
              if (_searchResult != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  sliver: SliverToBoxAdapter(
                    child: InventoryCountingReadonlyPanel(
                      doc: _searchResult!,
                      onClear: () {
                        setState(() {
                          _searchResult = null;
                          _searchError = null;
                        });
                      },
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(child: _buildListSection(l10n)),
            ],
          );

          final content = ColoredBox(color: AppColors.surface, child: listBody);

          final fab = FloatingActionButton.extended(
            onPressed: _openCreate,
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              l10n.inventoryFabCreate,
              style: const TextStyle(fontSize: 13),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          );

          if (!widget.showScaffold) {
            return Scaffold(body: content, floatingActionButton: fab);
          }

          return Scaffold(
            appBar: AppBar(title: Text(l10n.inventoryCounting)),
            body: content,
            floatingActionButton: fab,
          );
        },
      ),
    );
  }
}

class _InventoryCountingCard extends StatelessWidget {
  const _InventoryCountingCard({required this.doc, required this.onTap});

  final InventoryCountingDocModel doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final docBadgeLabel = erpListCardPrimaryDocLabel(
      doc.documentNumber,
      doc.documentEntry,
    );
    final statusLabel = inventoryCountingStatusLabel(doc.documentStatus);
    final whCodes = doc.lines.map((l) => l.warehouseCode).toSet().toList();
    final warehouseLabel =
        whCodes.isEmpty
            ? '—'
            : whCodes.length == 1
            ? whCodes.first
            : whCodes.join(', ');
    final dateLabel = formatIsoDateLocal(doc.countDate);
    final lineCount = doc.lines.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (docBadgeLabel != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              docBadgeLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              warehouseLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ErpListDocumentStatusPill(label: statusLabel),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateLabel.isEmpty ? '—' : dateLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.list_alt_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$lineCount line${lineCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (doc.remarks != null && doc.remarks!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  doc.remarks!.trim(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
