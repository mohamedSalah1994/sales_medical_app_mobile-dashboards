import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/inventory_exceptions.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/inventory_transfer_models.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/pages/inventory_transfer_page.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/widgets/inventory_transfer_readonly_panel.dart';

/// Search bar is always visible; matching transfer is shown on this page.
class InventoryListPage extends StatefulWidget {
  const InventoryListPage({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  State<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends State<InventoryListPage> {
  final _docEntryController = TextEditingController();
  bool _isSearching = false;
  String? _searchError;
  InventoryTransferDocModel? _searchResult;

  @override
  void dispose() {
    _docEntryController.dispose();
    super.dispose();
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
      final doc = await context.read<InventoryCubit>().getTransferByDocEntry(
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
            builder: (_) => BlocProvider.value(
              value: context.read<InventoryCubit>(),
              child: const InventoryTransferPage.create(),
            ),
          ),
        )
        .then((_) {
          if (mounted) context.read<InventoryCubit>().loadWarehouses();
        });
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final listBody = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildSearchRow(l10n)),
        if (_searchResult != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            sliver: SliverToBoxAdapter(
              child: InventoryTransferReadonlyPanel(
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
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: AppColors.textSecondary.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.inventoryListHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    final content = ColoredBox(
      color: AppColors.surface,
      child: listBody,
    );

    if (!widget.showScaffold) {
      return Scaffold(
        body: content,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreate,
          icon: const Icon(Icons.add, size: 20),
          label: Text(
            l10n.inventoryFabCreate,
            style: const TextStyle(fontSize: 13),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inventory)),
      body: content,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          l10n.inventoryFabCreate,
          style: const TextStyle(fontSize: 13),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
